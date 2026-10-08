extends StaticBody3D
## A small tree in a clay pot that can be shot, or blown, to bits.
##
## Every hit knocks something off it: weapons call bleed() just before
## take_damage() (the same pair of calls that makes enemies bleed), and here
## bleed() throws up leaves if the tree was hit and chips of clay if the pot
## was. When its health runs out the pot bursts. The stem, the four clumps
## of leaves and five pieces of the pot are thrown across the room as gibs
## (scenes/gib.tscn, the same thing a zombie's arm becomes when it is shot
## off): they tumble, bounce off the walls, lie where they land and are
## cleared away a little later. What stays behind is the bottom of the pot
## under a heap of soil, which nothing collides with.
##
## Like a crate (scripts/crate.gd) it is in the "breakable" group, so
## explosions damage it too, and online the host keeps track of its health
## and tells everyone when it breaks. Each computer then throws the pieces
## for itself, so they don't land in the same places for everybody: they are
## only for show, and nothing in the game depends on where they are.

const PlaceholderSound := preload("res://scripts/placeholder_sound.gd")
const GIB_SCENE := preload("res://scenes/gib.tscn")

## How much damage it takes to break. 20 is two pistol shots.
@export var health := 20
## How hard the pieces are thrown when it breaks, in metres per second. Each
## piece gets a random share of this sideways and another upwards.
@export var throw_speed := 3.5
## SOUND HOOK: drag a .wav or .ogg file here in the Inspector to use your own
## smashing sound. If left empty, a burst of noise is generated instead.
@export var break_sound: AudioStream

## True once it has been smashed.
var broken := false
## Which way the pieces are pushed when it breaks: the way the last shot was
## going. Only the host's copy keeps this up to date (see _spray()), and the
## host is the one that breaks it.
var push_direction := Vector3.ZERO

@onready var pot: MeshInstance3D = $Pot
@onready var rim: MeshInstance3D = $Rim
@onready var soil: MeshInstance3D = $Soil
## The stem and the clumps of leaves. They are thrown when the pot breaks.
@onready var tree: Node3D = $Tree
## The pieces the pot breaks into, hidden inside it until then.
@onready var shards: Node3D = $Shards
## What is left standing afterwards, hidden until then.
@onready var remains: Node3D = $Remains
@onready var leaf_spray: CPUParticles3D = $LeafSpray
@onready var pot_chips: CPUParticles3D = $PotChips
@onready var leaf_burst: CPUParticles3D = $LeafBurst
@onready var dirt_burst: CPUParticles3D = $DirtBurst
@onready var sound_player: AudioStreamPlayer = $BreakSound


func _ready() -> void:
	if break_sound == null:
		break_sound = PlaceholderSound.make_noise_burst(0.3)
	sound_player.stream = break_sound


## Called by weapons and explosions just before take_damage(), with the
## spot that was hit and the direction pointing straight out of the surface
## there, back towards whoever fired.
func bleed(at: Vector3, spray_direction: Vector3, _drop_count := 12) -> void:
	# rpc() runs _spray here and on every other computer.
	_spray.rpc(at, spray_direction)


@rpc("any_peer", "call_local", "reliable")
func _spray(at: Vector3, spray_direction: Vector3) -> void:
	if broken:
		return
	# The shot was travelling the opposite way to spray_direction. This RPC
	# reaches the host before the take_damage() that follows it (reliable
	# messages from one computer arrive in order), so a shot that breaks the
	# pot has already set the direction. An explosion passes Vector3.ZERO,
	# which means the pieces fly every way.
	if is_multiplayer_authority():
		push_direction = -spray_direction

	# to_local turns a position in the level into one measured from the
	# bottom of the pot. Below the top of the soil, the shot hit the pot.
	var hit_pot := to_local(at).y < soil.position.y
	var burst := pot_chips if hit_pot else leaf_spray
	burst.global_position = at
	# The particles' direction is measured in the plant's own space, so turn
	# the world direction into that. With no particular direction, they go
	# straight up.
	if spray_direction == Vector3.ZERO:
		spray_direction = Vector3.UP
	burst.direction = global_basis.inverse() * spray_direction
	burst.restart()  # start the one-shot burst again from the beginning


## Called by weapons and explosions when they hit the plant. The @rpc line
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
	# pass through where the tree used to be.
	collision_layer = 0
	collision_mask = 0

	pot.visible = false
	rim.visible = false
	soil.visible = false
	remains.visible = true
	# get_children() hands back a list of its own, so it is safe to move the
	# pieces out of Tree and Shards while going through it.
	for piece: Node3D in tree.get_children() + shards.get_children():
		_throw(piece, direction)

	leaf_burst.restart()
	dirt_burst.restart()
	sound_player.play()


## Turns one piece of the plant into a gib and sends it flying: outwards
## from the middle of the pot, upwards, and along with the shot that broke
## it ("push", which is Vector3.ZERO after an explosion).
func _throw(piece: Node3D, push: Vector3) -> void:
	var start := piece.global_position
	var gib := GIB_SCENE.instantiate()
	# Add it to the level rather than to this plant, as a zombie's limb is
	# (see _sever() in scripts/enemy.gd).
	get_parent().add_child(gib)
	gib.global_position = start
	# reparent moves a node to a new parent without changing where it is.
	# The pieces of the pot were hidden only because their parent was, so
	# under the gib they can be seen.
	piece.reparent(gib)

	# Which way is "outwards" for this piece, seen from above. The stem
	# stands right on the middle, so it is sent a random way instead.
	var outwards := start - global_position
	outwards.y = 0.0
	if outwards.length() < 0.05:
		outwards = Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
	var velocity := outwards.normalized() * randf_range(0.3, 1.0) * throw_speed
	velocity += push * throw_speed * 0.5
	velocity.y = randf_range(0.6, 1.2) * throw_speed
	gib.launch(velocity)
