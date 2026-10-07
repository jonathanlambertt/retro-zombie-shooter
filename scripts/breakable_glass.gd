@tool
extends StaticBody3D
## A pane of glass that can be shot, or blown, out of its frame.
##
## Every hit cracks it where the shot landed: weapons call bleed() just
## before take_damage() (the same pair of calls that makes enemies bleed),
## and here bleed() leaves a bullet hole with a few cracks running out of it
## instead of blood (assets/textures/glass_crack.png). When its
## health runs out it bursts into falling shards, leaving only a jagged row
## of teeth round the frame, and stops blocking anything: players can climb
## through, shots fly through, and enemies on the far side can see through.
##
## Like a crate (scripts/crate.gd), it is in the "breakable" group, so
## explosions damage it too, and online the host keeps track of its health
## and tells everyone when it breaks.
##
## Its origin is the middle of its bottom edge. "@tool" makes this script run
## in the editor as well, so changing Size resizes the pane straight away.

const PlaceholderSound := preload("res://scripts/placeholder_sound.gd")
## Cracks beyond this many are not drawn (a shotgun blast is a dozen hits).
const MAX_CRACKS := 8

## Width and height of the pane, in metres.
@export var size := Vector2(2.0, 2.3):
	set(value):
		size = value
		_update_size()
## How much damage it takes to break. 20 is two pistol shots.
@export var health := 20
## SOUND HOOK: drag a .wav or .ogg file here in the Inspector to use your own
## shattering sound. If left empty, a burst of noise is generated instead.
@export var break_sound: AudioStream

## True once it has shattered.
var broken := false
## Which way the shards fly when it breaks: the way the last shot was going,
## so they rain down on the far side. Only the host's copy keeps this up to
## date (see _crack()), and the host is the one that breaks it.
var push_direction := Vector3.ZERO
var cracks: Array[MeshInstance3D] = []

@onready var pane: MeshInstance3D = $Pane
@onready var crack_template: MeshInstance3D = $Crack
@onready var edges: MeshInstance3D = $Edges
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var shards: CPUParticles3D = $Shards
@onready var sound_player: AudioStreamPlayer = $BreakSound


func _ready() -> void:
	_update_size()
	if Engine.is_editor_hint():
		return  # the rest is only needed while playing
	if break_sound == null:
		break_sound = PlaceholderSound.make_noise_burst(0.4)
	sound_player.stream = break_sound


## The scene is built as a 1 x 1 m pane. Stretch the glass and its broken
## edges to the size asked for, and make a collision box to match. (A shape
## must not be stretched with scale like a mesh can, so it gets a new one.)
func _update_size() -> void:
	# The setter above also runs while the scene is still being loaded,
	# before the child nodes exist. _ready() calls this again once they do.
	if not is_node_ready():
		return
	var centre := Vector3.UP * size.y / 2.0
	for mesh_instance: MeshInstance3D in [pane, edges]:
		mesh_instance.scale = Vector3(size.x, size.y, 1.0)
		mesh_instance.position = centre
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, size.y, 0.1)
	collision_shape.shape = shape
	collision_shape.position = centre
	shards.position = centre
	shards.emission_box_extents = Vector3(size.x / 2.0, size.y / 2.0, 0.02)
	shards.amount = maxi(int(size.x * size.y * 12.0), 8)


## Called by weapons and explosions just before take_damage(), with the
## point that was hit and the direction back towards whoever fired.
func bleed(at: Vector3, spray_direction: Vector3, _drop_count := 12) -> void:
	# rpc() runs _crack here and on every other computer.
	_crack.rpc(at, spray_direction)


@rpc("any_peer", "call_local", "reliable")
func _crack(at: Vector3, spray_direction: Vector3) -> void:
	if broken:
		return
	# The shot was travelling the opposite way to spray_direction. This RPC
	# reaches the host before the take_damage() that follows it (reliable
	# messages from one computer arrive in order), so a shot that breaks the
	# pane has already set the direction. An explosion passes Vector3.ZERO,
	# which means shards fly every way.
	if is_multiplayer_authority():
		push_direction = -spray_direction
	if cracks.size() >= MAX_CRACKS:
		return
	var crack := crack_template.duplicate() as MeshInstance3D
	add_child(crack)
	# Put the crack where the shot landed, flattened onto the pane and kept
	# inside its frame, turned at random so no two look alike.
	var spot := to_local(at)
	crack.position = Vector3(clampf(spot.x, -size.x / 2.0, size.x / 2.0), clampf(spot.y, 0.0, size.y), 0.0)
	crack.rotation.z = randf() * TAU
	crack.visible = true
	cracks.append(crack)


## Called by weapons and explosions when they hit the glass. The @rpc line
## lets a hit on another computer be sent to the host (see
## scripts/enemy.gd, which works the same way).
@rpc("any_peer", "call_remote", "reliable")
func take_damage(amount: int) -> void:
	if not is_multiplayer_authority():
		take_damage.rpc_id(get_multiplayer_authority(), amount)
		return
	if broken:
		return
	health -= amount
	if health <= 0:
		# So that players who join later don't see it either.
		Network.record_destroyed(self)
		# rpc() runs _break here and on every other computer.
		_break.rpc(push_direction)


@rpc("authority", "call_local", "reliable")
func _break(direction: Vector3) -> void:
	broken = true
	# Take it off every collision layer so players, shots and enemies' eyes
	# pass through where the glass used to be.
	collision_layer = 0
	collision_mask = 0
	pane.visible = false
	edges.visible = true
	for crack in cracks:
		crack.queue_free()
	cracks.clear()
	# The particles' direction is measured in the pane's own space, so turn
	# the world direction into that.
	if direction != Vector3.ZERO:
		shards.direction = global_basis.inverse() * direction
		shards.spread = 50.0
	shards.emitting = true
	sound_player.play()
