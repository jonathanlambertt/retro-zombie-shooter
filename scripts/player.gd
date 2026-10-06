extends CharacterBody3D
## First-person player with Quake-style movement.
##
## Node layout (see scenes/player.tscn):
##   Player (CharacterBody3D)  - turns left/right with the mouse, and moves
##     CollisionShape3D        - the capsule that bumps into the world
##     Model                   - the body other players see (player_model.tscn)
##     Sync                  - sends this player's state to the others online
##     Head (Node3D)           - tilts up/down with the mouse
##       Camera3D              - what you see, with the guns in front of it
##       ChaseArm, FrontArm    - the two third-person cameras (F4)
##
## Splitting the turn (body) from the tilt (head) keeps "forward" level with
## the floor, so looking up at the ceiling doesn't make you walk slower.
##
## Your own body is hidden in first person, and the gun in your hands (the
## "viewmodel") is drawn on top of the world, so it never sinks into a wall.
## F4 steps through three views: first person, a chase camera behind you,
## and a camera in front looking back at your face. Those two show the body
## and hide the viewmodel. The body has no collision, so it never gets in
## the way of your own shots.
##
## Multiplayer (see scripts/network.gd): every player in the game is one of
## these. Only yours reads the keyboard and mouse and moves; the others are
## moved by the network (the Sync node) and show their body instead of a
## camera. Who controls a player is its "multiplayer authority", taken from
## its name, which is the controlling peer's ID.
##
## Holding crouch shrinks the collision capsule and lowers the view, so you
## fit under lower things, and slows you down. Crouching in mid-air pulls
## your legs up instead of lowering your head ("crouch-jumping", as in
## Half-Life), which gets your feet onto ledges a normal jump can't reach.
##
## The movement maths is the same idea Quake used:
##   - On the ground, friction slows you down every frame, then acceleration
##     pushes you towards the direction you're holding.
##   - In the air there is no friction, and you can only add a small amount
##     of speed in the direction you're holding. That small nudge is what
##     gives "air control" (and, as a side effect, strafe-jumping).

const PlaceholderSound := preload("res://scripts/placeholder_sound.gd")
## The render layer the viewmodel is drawn on. Cameras have a "cull mask"
## saying which layers they show; the chase camera's leaves this one out.
const VIEWMODEL_LAYER := 2

## The views F4 steps through.
enum View { FIRST_PERSON, BEHIND, FRONT }

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

@export_group("Crouch")
## How tall the collision capsule is while crouching, in metres. (Standing,
## it is the height of the CollisionShape3D's capsule: 1.8.)
@export var crouch_height := 1.2
## Top speed while crouching on the ground, in metres per second.
@export var crouch_speed := 3.0
## How fast the view sinks and rises. 6 = all the way in a sixth of a second.
@export var crouch_transition_speed := 6.0

@export_group("Mouse")
## Radians of turn per pixel of mouse movement.
@export var mouse_sensitivity := 0.0025

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
## True while crouched (the small capsule is in use).
var crouching := false
## How far the view has sunk into the crouch, from 0 (standing) to 1 (fully
## crouched). It eases between the two; the body model reads it too.
var crouch_amount := 0.0
## Which camera you are looking through.
var view := View.FIRST_PERSON
## True if this is the player controlled on this computer. Online, the other
## players are copies that the network moves.
var is_local := true
## True while standing on something. The controlling computer keeps it up to
## date and the network sends it to the others, for the body's animation.
var grounded := true
## The two collision capsules: the one from the scene, and a shorter copy.
## The shapes are swapped rather than resized because every player made
## from player.tscn shares the scene's shape: resizing it would crouch them all.
var stand_shape: CapsuleShape3D
var crouch_shape: CapsuleShape3D
## How high the eyes are when standing (the Head node's height in the scene).
var stand_eye_height := 0.0

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
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var model: Node3D = $Model
@onready var chase_arm: SpringArm3D = $Head/ChaseArm
@onready var chase_camera: Camera3D = $Head/ChaseArm/ChaseCamera
@onready var front_arm: SpringArm3D = $Head/FrontArm
@onready var front_camera: Camera3D = $Head/FrontArm/FrontCamera

## The weapon currently in hand. The HUD asks it what to show for ammo.
var current_weapon: Node3D
## Where current_weapon is in the weapons list: 0 for the first, and so on.
var weapon_index := 0


func _enter_tree() -> void:
	# Online, each player is named after the peer ID of whoever controls it
	# (see _make_player in scripts/network.gd). That peer becomes its
	# "multiplayer authority": the only one who moves it, and the one its
	# Sync node sends from. (In single player the name is "Player", and
	# everything belongs to us anyway.)
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())


func _ready() -> void:
	is_local = is_multiplayer_authority()
	health = max_health
	_select_weapon(0)
	if hurt_sound == null:
		hurt_sound = PlaceholderSound.make_grunt()
	hurt_sound_player.stream = hurt_sound

	stand_shape = collision_shape.shape as CapsuleShape3D
	crouch_shape = stand_shape.duplicate() as CapsuleShape3D
	crouch_shape.height = crouch_height
	stand_eye_height = head.position.y

	_set_up_viewmodel()
	# A SpringArm3D casts towards its end and pulls the camera in front of
	# any wall in the way. It must not stop on our own capsule.
	chase_arm.add_excluded_object(get_rid())
	front_arm.add_excluded_object(get_rid())

	if not is_local:
		# Someone else's player: show the body, hide the guns in front of its
		# camera, and leave the keyboard and mouse alone. A disabled node
		# gets no _process or input calls, which keeps its guns from firing.
		model.visible = true
		camera.visible = false
		camera.process_mode = Node.PROCESS_MODE_DISABLED
		set_physics_process(false)
		set_process_unhandled_input(false)
		return

	# The HUD looks for the player to show the health of in this group.
	add_to_group("local_player")
	_set_view(View.FIRST_PERSON)
	# "Capturing" hides the cursor and locks it to the window, so the mouse
	# can be moved endlessly to look around.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Network.is_online():
		_step_aside.call_deferred()


## Online, players all start near the same spot: move to a free one. The
## level's collision is only built during its first frame, so wait a moment
## before looking.
func _step_aside() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	global_position = Network.find_spawn_position(self)


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

	if event.is_action_pressed("change_view"):
		# The next view in the list, and back to the first after the last.
		_set_view(((view + 1) % View.size()) as View)

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
	if not is_local:
		# Someone else's player: catch up with the weapon and the crouch the
		# network says it has. (Its position, turn and aim arrive directly.)
		if current_weapon != weapons[weapon_index]:
			_select_weapon(weapon_index)
		if crouching != (collision_shape.shape == crouch_shape):
			_use_shape(crouch_shape if crouching else stand_shape)


# _physics_process runs at a fixed rate (60 times a second by default),
# which keeps movement consistent no matter how fast the game is drawing.
func _physics_process(delta: float) -> void:
	# Turn the WASD keys into a direction. get_vector returns x = left/right
	# and y = forward/back, each from -1 to 1. (Not while the mouse is free:
	# online the pause menu doesn't pause, and its keys mustn't walk you.)
	var input := Vector2.ZERO
	if _has_control():
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Rotate it by the way the body is facing to get a world direction.
	var wish_direction := (global_transform.basis * Vector3(input.x, 0.0, input.y)).normalized()

	_update_crouch(delta)

	if is_on_floor():
		_apply_friction(delta)
		var top_speed := crouch_speed if crouching else max_speed
		_accelerate(wish_direction, top_speed, ground_acceleration, delta)
		if Input.is_action_just_pressed("jump") and _has_control():
			# The upward speed needed to reach jump_height under this gravity.
			velocity.y = sqrt(2.0 * gravity * jump_height)
	else:
		velocity.y -= gravity * delta
		_accelerate(wish_direction, air_control_speed, air_acceleration, delta)

	# Moves the body by "velocity", sliding along walls and floors it hits.
	move_and_slide()
	grounded = is_on_floor()


## True while the keyboard and mouse are steering this player: the mouse is
## captured, so no menu is open and the window has the focus.
func _has_control() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


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


## Crouches while the crouch key is held, and stands back up once it is let
## go and there is room. Then eases the view towards the new height.
func _update_crouch(delta: float) -> void:
	# With no control, carry on as we are.
	var wants_crouch := Input.is_action_pressed("crouch") if _has_control() else crouching
	if wants_crouch:
		if not crouching:
			_crouch()
	elif crouching:
		_try_to_stand()

	crouch_amount = move_toward(crouch_amount, 1.0 if crouching else 0.0, crouch_transition_speed * delta)
	head.position.y = stand_eye_height - _crouch_drop() * crouch_amount


func _crouch() -> void:
	crouching = true
	_use_shape(crouch_shape)
	if not is_on_floor():
		# In mid-air, pull the legs up instead: lift the body by as much as
		# the capsule shrank, so its top (and the view) stays where it was.
		# The smaller capsule fits inside the old one, so this can't put us
		# inside a wall.
		global_position.y += _crouch_drop()
		crouch_amount = 1.0  # no easing, or the view would jump up and sink


func _try_to_stand() -> void:
	var drop := _crouch_drop()
	# test_move asks the physics engine whether moving the body (with its
	# small capsule) by this much would hit anything, without moving it.
	# Sliding the small capsule by the height difference sweeps exactly the
	# space the tall one needs.
	if not is_on_floor() and not test_move(global_transform, Vector3.DOWN * drop):
		# In mid-air with room below: put the legs back down, keeping the
		# view still (the opposite of a crouch-jump).
		global_position.y -= drop
		crouch_amount = 0.0
	elif test_move(global_transform, Vector3.UP * drop):
		return  # something overhead: stay crouched for now
	crouching = false
	_use_shape(stand_shape)


func _use_shape(shape: CapsuleShape3D) -> void:
	collision_shape.shape = shape
	# A capsule is centred on its node, so lift it by half its height to
	# keep its bottom at our feet.
	collision_shape.position.y = shape.height / 2.0


## How much shorter the crouching capsule is than the standing one.
func _crouch_drop() -> float:
	return stand_shape.height - crouch_shape.height


## Switches to one of the three views.
func _set_view(new_view: View) -> void:
	view = new_view
	match view:
		View.FIRST_PERSON:
			camera.make_current()
		View.BEHIND:
			chase_camera.make_current()
		View.FRONT:
			front_camera.make_current()
	# Seen from inside your own head the body only gets in the way, so it is
	# shown only in the third-person views.
	model.visible = view != View.FIRST_PERSON


## The HUD asks this. Looking at your own face, a crosshair means nothing.
func wants_crosshair() -> bool:
	return view != View.FRONT


## Prepares the guns under the camera to be drawn as the viewmodel: in
## front of the world, and only by the first-person camera.
func _set_up_viewmodel() -> void:
	chase_camera.set_cull_mask_value(VIEWMODEL_LAYER, false)
	front_camera.set_cull_mask_value(VIEWMODEL_LAYER, false)
	# Each gun part gets a copy of its material with the viewmodel setting on.
	# Parts that shared a material share the copy too: this remembers which
	# copy belongs to which original.
	var copies := {}
	# find_children(pattern, type, recursive, owned) finds every gun part.
	# owned = false, because the parts belong to the gun scenes, not to this
	# one.
	for part: MeshInstance3D in camera.find_children("*", "MeshInstance3D", true, false):
		# Only on the viewmodel layer, which the chase camera skips.
		part.layers = 0
		part.set_layer_mask_value(VIEWMODEL_LAYER, true)

		var material := part.get_active_material(0)
		if not copies.has(material):
			var copy := material.duplicate() as Material
			if copy is ShaderMaterial:
				# The retro surface shader's trick: see "viewmodel" in
				# shaders/retro_surface.gdshader.
				copy.set_shader_parameter("viewmodel", true)
			elif copy is BaseMaterial3D:
				# A muzzle flash (a plain StandardMaterial3D) can simply skip
				# the depth test. Making it "transparent" draws it after the
				# walls, so it really does end up on top of them.
				copy.no_depth_test = true
				copy.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			copies[material] = copy
		# material_override swaps the material for this one node only.
		part.material_override = copies[material]


## Shows one weapon and hides the rest. A hidden weapon ignores the trigger.
func _select_weapon(index: int) -> void:
	for i in weapons.size():
		weapons[i].visible = i == index
	current_weapon = weapons[index]
	weapon_index = index


## Returns where a projectile fired from "muzzle" (the end of a gun barrel)
## should start. Weapons that fire real projectiles use this.
##
## The barrel sticks out further than the collision capsule, so up against a
## wall it reaches right through it, and a bullet starting there would come
## out on the other side. If anything is between the eyes and the muzzle,
## start just in front of it instead. (Then the shot hits that wall, or that
## enemy in your face.)
func get_projectile_start(muzzle: Vector3) -> Vector3:
	var eye := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(eye, muzzle)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return muzzle
	# Back off 5 cm towards the eyes, so the projectile's first ray starts
	# in the open and finds the wall.
	return hit.position + (eye - muzzle).normalized() * 0.05


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


## Called by enemies (and lava, explosions and other players' shots) when
## they hurt the player.
##
## The @rpc line lets other computers call this function on this one. Only
## the computer that controls a player keeps track of its health, so if the
## hurting happens anywhere else (an enemy on the host, another player's
## shot), the damage is sent there: rpc_id runs this same function on that
## one peer.
@rpc("any_peer", "call_remote", "reliable")
func take_damage(amount: int) -> void:
	if not is_multiplayer_authority():
		take_damage.rpc_id(get_multiplayer_authority(), amount)
		return
	health = maxi(health - amount, 0)
	# Let the player know: a grunt, and the HUD turns the screen red.
	hurt_flash = 1.0
	hurt_sound_player.play()
	if health > 0:
		return
	if Network.is_online():
		# The game carries on for everyone else, so start again at the
		# beginning of the level instead of reloading it.
		_respawn()
	else:
		# Dying simply restarts the whole game. call_deferred waits until
		# the current physics step has finished before swapping scenes.
		get_tree().reload_current_scene.call_deferred()


## Back to full health, standing, at the start of the level.
func _respawn() -> void:
	health = max_health
	velocity = Vector3.ZERO
	if crouching:
		crouching = false
		crouch_amount = 0.0
		_use_shape(stand_shape)
	global_position = Network.find_spawn_position(self)


## Weapons call this each time they fire. "shot" is whatever another
## computer needs to repeat the shot for show (see replay_shot() in each
## weapon): where it started, which way it went... It also flashes the gun in
## this player's hands, for the third-person views.
func share_shot(weapon: Node3D, shot: Array) -> void:
	model.show_shot(null)  # (the weapon has already played its own sound)
	if Network.is_online():
		_replay_shot.rpc(weapons.find(weapon), shot)


## Runs on everyone else's copy of this player: repeats a shot, harmlessly,
## so they see the flash, the bullets and the holes, and hear the bang.
## ("authority" = only the player's own computer may call it.)
@rpc("authority", "call_remote", "reliable")
func _replay_shot(weapon_number: int, shot: Array) -> void:
	var sound: AudioStream = weapons[weapon_number].replay_shot(shot)
	model.show_shot(sound)
