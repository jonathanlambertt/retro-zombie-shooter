extends CharacterBody3D
## First-person player with Quake-style movement.
##
## Node layout (see scenes/player.tscn):
##   Player (CharacterBody3D)  - turns left/right with the mouse, and moves
##     CollisionShape3D        - the capsule that bumps into the world
##     Head (Node3D)           - tilts up/down with the mouse
##       Camera3D              - what you see
##
## Splitting the turn (body) from the tilt (head) keeps "forward" level with
## the floor, so looking up at the ceiling doesn't make you walk slower.
##
## The movement maths is the same idea Quake used:
##   - On the ground, friction slows you down every frame, then acceleration
##     pushes you towards the direction you're holding.
##   - In the air there is no friction, and you can only add a small amount
##     of speed in the direction you're holding. That small nudge is what
##     gives "air control" (and, as a side effect, strafe-jumping).

const PlaceholderSound := preload("res://scripts/placeholder_sound.gd")
## The pause menu's script, which keeps the VIEW BOB on/off setting.
const PauseMenu := preload("res://scripts/pause_menu.gd")

@export_group("Movement")
## Top running speed, in metres per second.
@export var max_speed := 7.0
## How quickly you reach top speed on the ground. Higher = snappier.
@export var ground_acceleration := 10.0
## How quickly you slow down on the ground when you let go of the keys.
@export var friction := 6.0
## Below this speed, friction acts as if you were moving this fast, so you
## come to a crisp stop instead of sliding forever.
@export var stop_speed := 2.0

@export_group("Air")
## Downward acceleration, in metres per second squared. (Real life is 9.8;
## shooters use about double so jumps feel snappy.)
@export var gravity := 20.0
## How high a jump reaches, in metres.
@export var jump_height := 1.0
## How quickly you can change direction in mid-air.
@export var air_acceleration := 10.0
## The most speed you can add in a new direction while in mid-air.
## 0 = no air control at all. Higher = more steering while airborne.
@export var air_control_speed := 1.0

@export_group("Mouse")
## Radians of turn per pixel of mouse movement.
@export var mouse_sensitivity := 0.0025

@export_group("View bob")
## How far the camera rises and falls with each step, in metres. 0 = none.
## (The pause menu's VIEW BOB setting switches the whole effect off.)
@export var view_bob_height := 0.035
## How far it sways from side to side, in metres.
@export var view_bob_sway := 0.02
## Steps per metre walked. Higher = quicker, shorter steps.
@export var view_bob_steps_per_meter := 0.35
## How quickly the bob fades in when you set off and out when you stop.
@export var view_bob_fade_speed := 8.0

@export_group("Health")
@export var max_health := 100
## SOUND HOOK: drag a .wav or .ogg file here in the Inspector to use your own
## "ouch". If left empty, a soft grunt is generated as a stand-in.
@export var hurt_sound: AudioStream
## How quickly the red tint fades after being hurt. 2 = gone in half a second.
@export var hurt_fade_speed := 2.0

var health := 0
## How strong the red "you are being hurt" tint is right now, from 0 (none)
## to 1 (full). It jumps to 1 on every hit and then fades. The HUD reads it.
var hurt_flash := 0.0
## How far through the walking cycle the view bob is, in steps.
var bob_phase := 0.0
## How strong the bob is right now, from 0 (standing still) to 1 (running).
var bob_amount := 0.0

@onready var head: Node3D = $Head
## Every weapon the player carries, in the order of the number keys.
@onready var weapons: Array[Node3D] = [
	$Head/Camera3D/Pistol,
	$Head/Camera3D/MachineGun,
	$Head/Camera3D/RocketLauncher,
	$Head/Camera3D/Shotgun,
]
@onready var camera: Camera3D = $Head/Camera3D
@onready var hurt_sound_player: AudioStreamPlayer = $HurtSound

## The weapon currently in hand. The HUD asks it what to show for ammo.
var current_weapon: Node3D
## Where current_weapon is in the weapons list: 0 for the first, and so on.
var weapon_index := 0


func _ready() -> void:
	health = max_health
	_select_weapon(0)
	if hurt_sound == null:
		hurt_sound = PlaceholderSound.make_grunt()
	hurt_sound_player.stream = hurt_sound
	# "Capturing" hides the cursor and locks it to the window, so the mouse
	# can be moved endlessly to look around.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	# (Esc is handled by the pause menu, scripts/pause_menu.gd.)

	# Number keys switch weapon: the action "weapon_1" picks the first one
	# in the list, "weapon_2" the second, and so on.
	for i in weapons.size():
		if event.is_action_pressed("weapon_%d" % (i + 1)):
			_select_weapon(i)
	# The mouse wheel steps through them in order. posmod wraps around, so
	# going past the last weapon comes back to the first (and vice versa).
	if event.is_action_pressed("weapon_next"):
		_select_weapon(posmod(weapon_index + 1, weapons.size()))
	elif event.is_action_pressed("weapon_previous"):
		_select_weapon(posmod(weapon_index - 1, weapons.size()))

	var mouse_is_captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED

	# Clicking in the window grabs the mouse again (if it was lost, for
	# example by switching to another window).
	if event is InputEventMouseButton and event.pressed and not mouse_is_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion and mouse_is_captured:
		# screen_relative is the raw mouse movement in real screen pixels.
		# (The plain "relative" value would shrink as our low-res picture is
		# scaled up, making sensitivity depend on the window size.)
		var motion: Vector2 = event.screen_relative
		# Turn the whole body left/right...
		rotate_y(-motion.x * mouse_sensitivity)
		# ...but tilt only the head up/down, and stop just short of straight
		# up or down so the view can't flip over.
		head.rotation.x = clampf(head.rotation.x - motion.y * mouse_sensitivity, -1.5, 1.5)


func _process(delta: float) -> void:
	hurt_flash = maxf(hurt_flash - hurt_fade_speed * delta, 0.0)
	_bob_view(delta)


## Nudges the camera up, down and sideways in time with the player's steps.
## The weapons are children of the camera, so they ride along with it.
func _bob_view(delta: float) -> void:
	var speed := Vector3(velocity.x, 0.0, velocity.z).length()
	# Bob only while walking on the ground, and less when moving slowly.
	var wanted := 0.0
	if PauseMenu.view_bob and is_on_floor():
		wanted = clampf(speed / max_speed, 0.0, 1.0)
	# move_toward steps a number towards a target without overshooting it.
	bob_amount = move_toward(bob_amount, wanted, view_bob_fade_speed * delta)

	# Advance by distance covered rather than by time, so the steps keep
	# pace with the feet. TAU is a full circle (2 x PI): one step.
	bob_phase += speed * delta * view_bob_steps_per_meter
	var angle := bob_phase * TAU
	# Down and up once per step; left and right once per pair of steps.
	camera.position.y = sin(angle) * view_bob_height * bob_amount
	camera.position.x = sin(angle * 0.5) * view_bob_sway * bob_amount


# _physics_process runs at a fixed rate (60 times a second by default),
# which keeps movement consistent no matter how fast the game is drawing.
func _physics_process(delta: float) -> void:
	# Turn the WASD keys into a direction. get_vector returns x = left/right
	# and y = forward/back, each from -1 to 1.
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Rotate it by the way the body is facing to get a world direction.
	var wish_direction := (global_transform.basis * Vector3(input.x, 0.0, input.y)).normalized()

	if is_on_floor():
		_apply_friction(delta)
		_accelerate(wish_direction, max_speed, ground_acceleration, delta)
		if Input.is_action_just_pressed("jump"):
			# The upward speed needed to reach jump_height under this gravity.
			velocity.y = sqrt(2.0 * gravity * jump_height)
	else:
		velocity.y -= gravity * delta
		_accelerate(wish_direction, air_control_speed, air_acceleration, delta)

	# Moves the body by "velocity", sliding along walls and floors it hits.
	move_and_slide()


## Slows horizontal movement, like shoes gripping the floor.
func _apply_friction(delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var speed := horizontal.length()
	if speed < 0.01:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var drop := maxf(speed, stop_speed) * friction * delta
	var new_speed := maxf(speed - drop, 0.0)
	velocity.x *= new_speed / speed
	velocity.z *= new_speed / speed


## Speeds up towards wish_direction, but never past wish_speed in that
## direction. Speed you already have in other directions is left alone.
func _accelerate(wish_direction: Vector3, wish_speed: float, acceleration: float, delta: float) -> void:
	# How fast we are already going in the wished direction.
	var current_speed := velocity.dot(wish_direction)
	var speed_to_add := wish_speed - current_speed
	if speed_to_add <= 0.0:
		return
	var acceleration_step := minf(acceleration * max_speed * delta, speed_to_add)
	velocity += wish_direction * acceleration_step


## Shows one weapon and hides the rest. A hidden weapon ignores the trigger.
func _select_weapon(index: int) -> void:
	for i in weapons.size():
		weapons[i].visible = i == index
	current_weapon = weapons[index]
	weapon_index = index


## Returns the direction from "from" (the end of a gun barrel) to whatever
## the crosshair is on. Weapons that fire real projectiles use this.
##
## The gun sits to the right of the camera, so a shot flying straight out of
## the barrel would land beside the crosshair. Instead, find the point the
## crosshair is on and aim the barrel at that.
func get_aim_direction(from: Vector3) -> Vector3:
	var eye := camera.global_position
	# A camera looks along its own negative Z axis.
	var forward := -camera.global_transform.basis.z

	var aim_point := eye + forward * 100.0
	var query := PhysicsRayQueryParameters3D.create(eye, aim_point)
	# Leave ourselves out, so the ray can't stop on our own body.
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		aim_point = hit.position

	# (When the target is right in front of your face, just shoot forwards.)
	if eye.distance_to(aim_point) <= 1.0:
		return forward
	return (aim_point - from).normalized()


## Called by enemies (and lava, and your own explosions) when they hurt the
## player.
func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	# Let the player know: a grunt, and the HUD turns the screen red.
	hurt_flash = 1.0
	hurt_sound_player.play()
	if health == 0:
		# Dying simply restarts the whole game. call_deferred waits until
		# the current physics step has finished before swapping scenes.
		get_tree().reload_current_scene.call_deferred()
