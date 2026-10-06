extends Node3D
## Pump-action combat shotgun, in the style of the SPAS-12.
##
## Like the pistol it is "hitscan" (see scripts/pistol.gd), but each shell
## fires a whole cluster of pellets, and every pellet is its own ray pointed
## in a slightly different direction. Up close they all land on one enemy;
## far away they scatter and most of them miss.
##
## The fire button shoots one shell. The second fire button (right mouse)
## shoots two at once, for double the pellets and a longer wait afterwards.
## It never runs out of shells.
##
## Online, the other players' games repeat each shot with replay_shot(): the
## same pellets leave the same holes, but do no damage there.

const PlaceholderSound := preload("res://scripts/placeholder_sound.gd")
const BULLET_HOLE_SCENE := preload("res://scenes/bullet_hole.tscn")

## How many pellets are in one shell.
@export var pellets := 8
## Damage per pellet. A full shell does this times the number of pellets.
@export var damage := 5
## How far the pellets scatter, in degrees. 0 = they all hit the same spot.
@export var spread_degrees := 5.0
## How far the shot reaches, in metres.
@export var max_range := 40.0
## Time between single shots, in seconds (this is how long the pump takes).
@export var fire_interval := 0.8
## Time to wait after a double shot.
@export var double_fire_interval := 1.3
## SOUND HOOK: drag a .wav or .ogg file here in the Inspector to use your own
## gunshot. If left empty, a short burst of noise is generated as a stand-in.
@export var shoot_sound: AudioStream

## Counts down to zero; the gun can fire again when it gets there.
var cooldown := 0.0

@onready var model: Node3D = $Model
@onready var pump: Node3D = $Model/Pump
@onready var muzzle_flash: Node3D = $MuzzleFlash
@onready var sound_player: AudioStreamPlayer = $ShootSound


func _ready() -> void:
	if shoot_sound == null:
		shoot_sound = PlaceholderSound.make_noise_burst(0.3)
	sound_player.stream = shoot_sound


func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	# A weapon that isn't in the player's hand is hidden, and must not fire.
	if not visible:
		return
	# Only shoot while the mouse is captured. (The click that grabs the mouse
	# again, after switching windows, should not also fire the gun.)
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed("shoot"):
		fire(1)
	elif event.is_action_pressed("alt_fire"):
		fire(2)


## The words the HUD shows in the bottom-right corner while this weapon is
## in hand.
func get_hud_text() -> String:
	return "SHELLS UNLIMITED"


## Fires "shells" shells at once: 1 for a normal shot, 2 for a double.
func fire(shells: int) -> void:
	if cooldown > 0.0:
		return
	cooldown = fire_interval if shells == 1 else double_fire_interval

	# The pellets fly from the player's eyes. ("owner" is the player; its
	# camera is the first-person one, whichever view is showing.)
	var camera: Camera3D = owner.camera
	var from := camera.global_position
	# Where each pellet's ray ends. A PackedVector3Array is a compact list
	# of Vector3s, which is cheap to send over the network.
	var ends := PackedVector3Array()
	for i in pellets * shells:
		# Start with straight ahead (a camera looks along its own negative Z
		# axis), then push it off-centre by a random amount up/down and
		# left/right. "aim.x" and "aim.y" are the camera's right and up.
		var aim := camera.global_transform.basis
		var spread := tan(deg_to_rad(spread_degrees))
		var direction := -aim.z
		direction += aim.x * randf_range(-spread, spread)
		direction += aim.y * randf_range(-spread, spread)
		ends.append(from + direction.normalized() * max_range)

	for to in ends:
		_trace_pellet(from, to, true)
	_play_effects(shells)
	# Let the other players see it too.
	owner.share_shot(self, [from, ends])


## Repeats a shot fired on another computer (see the top of this script).
## Returns the sound for the shooter's body to play.
func replay_shot(shot: Array) -> AudioStream:
	for to: Vector3 in shot[1]:
		_trace_pellet(shot[0], to, false)
	return shoot_sound


## Traces one pellet's ray, and damages whatever it hits if "hurts" is true.
func _trace_pellet(from: Vector3, to: Vector3, hurts: bool) -> void:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	# "owner" is the root of the scene this gun was placed in: the player.
	# Exclude it so we can never shoot ourselves.
	if owner is CollisionObject3D:
		query.exclude = [owner.get_rid()]

	# The result is an empty Dictionary if nothing was hit.
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	# Things that bleed spray blood from the spot that was hit.
	if hit.collider.has_method("take_damage"):
		if hurts:
			if hit.collider.has_method("bleed"):
				hit.collider.bleed(hit.position, hit.normal, 4)
			hit.collider.take_damage(damage)
	else:
		# Walls and floors get a bullet hole for every pellet.
		var hole := BULLET_HOLE_SCENE.instantiate()
		owner.get_parent().add_child(hole)
		hole.place(hit.position, hit.normal, 0.6)


## Muzzle flash, recoil kick, sound, and then working the pump.
func _play_effects(shells: int) -> void:
	sound_player.play()

	# Kick the gun back and up (harder for a double shot), then ease it home.
	model.position.z = 0.06 * shells
	model.rotation.x = 0.1 * shells
	var kick := create_tween().set_parallel()
	kick.tween_property(model, "position:z", 0.0, 0.25)
	kick.tween_property(model, "rotation:x", 0.0, 0.25)

	# Slide the pump grip back along the barrel and forward again. A tween
	# without set_parallel plays its steps one after another.
	var slide := create_tween()
	slide.tween_interval(0.25)
	slide.tween_property(pump, "position:z", 0.09, 0.12)
	slide.tween_property(pump, "position:z", 0.0, 0.12)

	muzzle_flash.rotation.z = randf() * TAU
	muzzle_flash.visible = true
	await get_tree().create_timer(0.06).timeout
	muzzle_flash.visible = false
