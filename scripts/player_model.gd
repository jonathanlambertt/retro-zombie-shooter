extends Node3D
## The player's body, as other players will see it in multiplayer, built
## from boxes like the enemies and animated with code instead of an
## AnimationPlayer.
##
## It sits inside scenes/player.tscn and only reads what the player is doing
## (how fast and which way it moves, whether it is on the floor, how far it
## is crouched, where it is looking and which gun it holds). It never moves
## the player and has no collision, so it can't block your own shots. In
## first person it is hidden (you would only see the inside of your own
## helmet); press F4 for the third-person views to watch it.
##
## Online, everything _read_player() copies arrives over the network for the
## other players (velocity, grounded, crouch_amount, the head's up/down angle
## and the weapon), so their bodies animate just like yours. When they fire,
## show_shot() flashes their gun and plays the bang from where they stand.
##
## Two scenes use this script: scenes/player_model_soldier.tscn, a special
## forces soldier with a backpack (the one scenes/player.tscn uses), and
## scenes/player_model.tscn, a soldier in an armoured hazard suit. The script
## only relies on the node layout below, which both share.
##
## Node layout:
##   Hips                 - moved up and down so the feet stay on the floor
##     Legs               - turned towards the way you are running
##       LegLeft/Right    - hip joints; Knee and Ankle inside each
##     Upper              - the body from the waist up: leans and sways
##       Head             - always looks where you are looking
##       Aim              - the shoulders: points the gun where you look
##         ArmLeft/Right  - shoulder joints, with an Elbow inside each
##         Guns           - one model per weapon; only the one in hand shows
##
## The animations:
##   idle    - breathes, knees slightly bent
##   run     - legs swing and the knees lift, the body bobs and twists a
##             little; the legs turn to face the way you move, so strafing
##             and running backwards look right while the gun stays on target
##   jump    - one knee pulled up, the other leg trailing
##   land    - the knees give a little when you hit the ground
##   crouch  - a low squat, with a waddling walk
##   aim     - the head, arms and gun follow the mouse up and down

## Distances along the leg, in metres: hip to knee, knee to ankle, and the
## ankle's height above the sole of the boot. They match the boxes in the
## scene; together they make the standing hip height (0.9 m).
const THIGH_LENGTH := 0.42
const SHIN_LENGTH := 0.40
const ANKLE_HEIGHT := 0.08
## Shoulder to elbow, and elbow to the middle of the hand.
const UPPER_ARM_LENGTH := 0.28
const FOREARM_LENGTH := 0.29
## Where the hands rest, in the Aim node's space, when there is no gun model
## for the weapon in hand: hanging down by the sides.
const EMPTY_HAND_RIGHT := Vector3(0.27, -0.53, -0.08)
const EMPTY_HAND_LEFT := Vector3(-0.27, -0.53, -0.08)
## How long the knees take to spring back after a landing, in seconds.
const LAND_TIME := 0.3
## How long a muzzle flash stays lit, in seconds.
const FLASH_TIME := 0.05

## The material that armor_color recolours: every box wearing it changes
## colour. It is the armour plates on the armoured model, and the armbands
## and the panel on the backpack on the soldier.
@export var tinted_material: ShaderMaterial
## The colour of everything wearing tinted_material. A multiplayer game
## gives each player a different one to tell them apart. (Only shows when
## the game runs: the editor shows the colour set in the material itself.)
@export var armor_color := Color(0.85, 0.5, 0.22)
## The colour of the glowing visor.
@export var visor_color := Color(0.35, 0.95, 1.0)
## How far the body travels during one full stride (a step with each foot),
## in metres. Lower = quicker, shorter steps; too high and the feet slide.
@export var stride_length := 2.6
## How high the hips are in a full crouch, in metres (0.9 standing).
@export var crouch_hip_height := 0.36
## Seconds between blinks of the lamp on the backpack.
@export var lamp_blink_interval := 1.2

## The player this body belongs to: the node it was placed under.
var player: CharacterBody3D

## What the player is doing, copied from it at the start of every frame.
var velocity := Vector3.ZERO
var on_floor := true
## 0 = standing, 1 = fully crouched.
var crouch_amount := 0.0
## How far up (positive) or down the player is looking, in radians.
var look_pitch := 0.0
var weapon_name := ""
var max_speed := 7.0

## A clock for the animations that repeat (breathing, the lamp).
var anim_time := randf() * 10.0
## How far through the running cycle the legs are, in radians.
var walk_phase := 0.0
## How much of each animation is playing, from 0 (none) to 1 (fully). They
## fade in and out over a split second, so one animation flows into the next.
var move_blend := 0.0
var air_blend := 0.0
## How far the legs are turned away from the way the body faces, in radians.
var leg_turn := 0.0
## Seconds spent off the floor, so that stepping off a stair doesn't count as
## a jump.
var air_time := 0.0
## Counts down after landing. 0 = not landing.
var land_timer := 0.0
## The name of the weapon the hands are holding. "?" = not set up yet.
var held_weapon := "?"
## How far the gun is kicked back by the last shot, in metres.
var recoil := 0.0

@onready var hips: Node3D = $Hips
@onready var legs: Node3D = $Hips/Legs
@onready var leg_left: Node3D = $Hips/Legs/LegLeft
@onready var knee_left: Node3D = $Hips/Legs/LegLeft/Knee
@onready var ankle_left: Node3D = $Hips/Legs/LegLeft/Knee/Ankle
@onready var leg_right: Node3D = $Hips/Legs/LegRight
@onready var knee_right: Node3D = $Hips/Legs/LegRight/Knee
@onready var ankle_right: Node3D = $Hips/Legs/LegRight/Knee/Ankle
@onready var upper: Node3D = $Hips/Upper
@onready var head: Node3D = $Hips/Upper/Head
@onready var aim: Node3D = $Hips/Upper/Aim
@onready var arm_left: Node3D = $Hips/Upper/Aim/ArmLeft
@onready var elbow_left: Node3D = $Hips/Upper/Aim/ArmLeft/Elbow
@onready var arm_right: Node3D = $Hips/Upper/Aim/ArmRight
@onready var elbow_right: Node3D = $Hips/Upper/Aim/ArmRight/Elbow
@onready var guns: Node3D = $Hips/Upper/Aim/Guns
@onready var visor: MeshInstance3D = $Hips/Upper/Head/Visor
@onready var pack_lamp: MeshInstance3D = $Hips/Upper/PackLamp
@onready var shot_sound: AudioStreamPlayer3D = $Hips/Upper/Aim/ShotSound

## Where the hips and the shoulders sit when nothing is playing.
@onready var standing_hip_height := hips.position.y
@onready var aim_rest_position := aim.position


func _ready() -> void:
	player = get_parent() as CharacterBody3D
	_paint()


## Recolours the armour and the visor. Every copy of this scene shares the
## same materials, so each body gets its own duplicate to change.
func _paint() -> void:
	if tinted_material:
		var armor := tinted_material.duplicate() as ShaderMaterial
		armor.set_shader_parameter("tint", armor_color)
		# find_children("*", "MeshInstance3D") lists every box in the model.
		for mesh: MeshInstance3D in find_children("*", "MeshInstance3D"):
			if mesh.get_active_material(0) == tinted_material:
				# material_override replaces the material for this one node only.
				mesh.material_override = armor

	var glow := visor.get_active_material(0).duplicate() as StandardMaterial3D
	glow.albedo_color = visor_color
	visor.material_override = glow


func _process(delta: float) -> void:
	# A hidden body (your own, in first person) doesn't need animating.
	if is_visible_in_tree():
		_animate(delta)


## Copies everything the animation needs to know from the player.
func _read_player() -> void:
	if player == null:
		return  # not inside a player (the scene opened on its own): stand still
	velocity = player.velocity
	on_floor = player.grounded
	crouch_amount = player.crouch_amount
	look_pitch = player.head.rotation.x
	weapon_name = String(player.current_weapon.name) if player.current_weapon else ""
	max_speed = player.max_speed


## Works out the pose for this frame and puts every joint in it.
func _animate(delta: float) -> void:
	_read_player()
	var crouch := crouch_amount
	anim_time += delta

	if weapon_name != held_weapon:
		_hold(weapon_name)

	# The velocity measured from the body's own point of view: x = to its
	# right, z = backwards. (A basis is a rotation; its inverse undoes it.)
	var local_velocity := global_basis.inverse() * velocity
	# Flattened to the ground: x = right, y = forwards.
	var ground_velocity := Vector2(local_velocity.x, -local_velocity.z)
	var speed := ground_velocity.length()

	# --- How much of each animation to play ----------------------------------
	if on_floor:
		if air_time > 0.2:
			land_timer = LAND_TIME
		air_time = 0.0
	else:
		air_time += delta
	# Leaving the ground counts as a jump at once when going up, but only
	# after a moment when falling (so stepping off a stair isn't a jump).
	var airborne := air_time > 0.12 or (air_time > 0.0 and velocity.y > 1.0)
	var moving := not airborne and speed > 0.5
	# move_toward changes a number towards a target by at most the step.
	move_blend = move_toward(move_blend, 1.0 if moving else 0.0, 6.0 * delta)
	air_blend = move_toward(air_blend, 1.0 if airborne else 0.0, 7.0 * delta)
	land_timer = maxf(land_timer - delta, 0.0)

	# --- Which way the legs face, and the stride ------------------------------
	var target_leg_turn := 0.0
	if moving:
		# atan2 gives the angle of the movement: 0 = straight ahead, PI/2 =
		# right, -PI/2 = left, PI = straight back.
		var direction := atan2(ground_velocity.x, ground_velocity.y)
		var stepping := 1.0
		if absf(direction) > PI / 2.0 + 0.1:
			# Going backwards: keep the legs facing forwards (turned by the
			# leftover angle) and run the stride in reverse.
			direction = wrapf(direction + PI, -PI, PI)
			stepping = -1.0
		# Turning the legs to the right is a negative turn around Y.
		target_leg_turn = -clampf(direction, -1.1, 1.1)
		# One stride (a full turn of the cycle, TAU radians) per
		# stride_length metres. Crouched steps are shorter.
		var stride := stride_length * lerpf(1.0, 0.5, crouch)
		walk_phase += stepping * TAU * speed / stride * delta
	# lerp_angle eases between two angles. (1 - exp(-k * delta) is the share
	# of the way to go this frame that gives the same speed at any frame rate.)
	leg_turn = lerp_angle(leg_turn, target_leg_turn, 1.0 - exp(-10.0 * delta))

	# --- Legs -------------------------------------------------------------------
	# Running: the thighs swing back and forth like pendulums (sin) and each
	# foot lifts while its leg is swinging forwards (cos > 0 for the left).
	var stride_size := clampf(speed / max_speed, 0.3, 1.0)
	var swing := sin(walk_phase) * lerpf(0.3, 0.7, stride_size) * move_blend
	var thigh_left := swing
	var thigh_right := -swing
	var lift_left := maxf(cos(walk_phase), 0.0) * 0.2 * move_blend
	var lift_right := maxf(-cos(walk_phase), 0.0) * 0.2 * move_blend
	# The hips sink as the legs spread, so the foot underneath stays on the
	# floor. That is what makes the body bob up and down. (The -0.02 bends
	# the knees a touch when standing, which looks more alert.)
	var hip_height := THIGH_LENGTH * cos(swing) + SHIN_LENGTH + ANKLE_HEIGHT - 0.02

	# Jumping: one knee pulled up and the other leg trailing, tucked in more
	# while going up than while coming down.
	var rising := clampf(velocity.y / 5.0, 0.0, 1.0)
	thigh_left = lerpf(thigh_left, lerpf(0.25, 0.65, rising), air_blend)
	thigh_right = lerpf(thigh_right, lerpf(-0.1, -0.25, rising), air_blend)
	lift_left = lerpf(lift_left, lerpf(0.12, 0.3, rising), air_blend)
	lift_right = lerpf(lift_right, lerpf(0.06, 0.22, rising), air_blend)
	hip_height = lerpf(hip_height, standing_hip_height, air_blend)

	# Crouching: thighs well forward (one more than the other, which looks
	# less stiff) and the hips low, with a small waddle when moving.
	var crouch_swing := sin(walk_phase) * 0.25 * move_blend
	thigh_left = lerpf(thigh_left, 1.4 + crouch_swing, crouch)
	thigh_right = lerpf(thigh_right, 1.1 - crouch_swing, crouch)
	lift_left *= 1.0 - 0.6 * crouch
	lift_right *= 1.0 - 0.6 * crouch
	hip_height = lerpf(hip_height, crouch_hip_height, crouch)

	# Landing: the knees give and spring back. sin() over half a turn goes
	# 0 -> 1 -> 0, a smooth dip.
	hip_height -= sin(land_timer / LAND_TIME * PI) * 0.12 * (1.0 - crouch)

	hips.position.y = hip_height
	legs.rotation.y = leg_turn
	# Feet stay flat on the ground, but dangle a little in the air.
	var flat_feet := 1.0 - 0.6 * air_blend
	_place_leg(leg_left, knee_left, ankle_left, thigh_left, -0.05, lift_left, hip_height, flat_feet)
	_place_leg(leg_right, knee_right, ankle_right, thigh_right, 0.05, lift_right, hip_height, flat_feet)

	# --- Body ---------------------------------------------------------------------
	var forwards := clampf(ground_velocity.y / max_speed, -1.0, 1.0) * move_blend
	var sideways := clampf(ground_velocity.x / max_speed, -1.0, 1.0) * move_blend
	# Lean into the run, and slowly breathe. (Negative = leaning forwards.)
	var lean := -0.12 * forwards + sin(anim_time * 2.0) * 0.02
	lean += 0.1 * rising * air_blend  # arch back a little on the way up
	lean -= 0.45 * crouch             # hunch over in a crouch
	# Lean into strafes, and twist the shoulders against the stride.
	var roll := -0.1 * sideways
	var twist := sin(walk_phase) * 0.1 * move_blend
	upper.rotation = Vector3(lean, twist, roll)

	# --- Aim ------------------------------------------------------------------------
	# The gun and the head point exactly where the player looks, however the
	# body is leaning. Setting global_basis (this node's rotation in the
	# world) instead of rotation cancels out the lean, sway and twist above.
	# Basis(axis, angle) is a rotation around that axis. RIGHT is the X axis:
	# turning around it tips the view up and down.
	aim.global_basis = global_basis * Basis(Vector3.RIGHT, look_pitch)
	head.global_basis = global_basis * Basis(Vector3.RIGHT, clampf(look_pitch, -0.8, 0.8))
	# The gun bobs a little with every step, and kicks back when fired.
	recoil = move_toward(recoil, 0.0, 0.5 * delta)
	aim.position = aim_rest_position + Vector3(0.0, sin(walk_phase * 2.0) * 0.012, 0.0) * move_blend
	aim.position.z += recoil

	# The backpack lamp flashes briefly once every lamp_blink_interval.
	pack_lamp.visible = fmod(anim_time, lamp_blink_interval) < 0.12


## Bends one leg so its foot ends up on the floor (or "lift" metres above
## it) with the thigh at the given angle.
##
## Knowing the hip height and the thigh's angle, the height left for the
## shin to cover is known too, and cos() of the shin's angle is that height
## divided by its length. acos() turns it back into the angle.
func _place_leg(leg: Node3D, knee: Node3D, ankle: Node3D, thigh_angle: float,
		splay: float, lift: float, hip_height: float, flat_foot: float) -> void:
	# Positive rotation.x swings a leg forwards; splay (rotation.z) sets the
	# feet a little apart.
	leg.rotation = Vector3(thigh_angle, 0.0, splay)
	var drop := hip_height - ANKLE_HEIGHT - lift - THIGH_LENGTH * cos(thigh_angle)
	# The shin points down and backwards, so its angle is negative.
	var shin_angle := -acos(clampf(drop / SHIN_LENGTH, -1.0, 1.0))
	# The knee's own angle is the difference. Knees only bend one way, so it
	# can't be positive (if it would have to be, the foot simply lifts).
	var knee_angle := minf(shin_angle - thigh_angle, 0.0)
	knee.rotation.x = knee_angle
	# Turn the boot back by the whole leg's angle to keep the sole level.
	ankle.rotation.x = -(thigh_angle + knee_angle) * flat_foot


## Called by the player each time it fires: kicks the gun back, flashes its
## muzzle, and plays "sound" (if given) from where the body stands.
func show_shot(sound: AudioStream) -> void:
	recoil = 0.06
	if sound:
		# An AudioStreamPlayer3D is louder the closer the listener (the
		# camera) is, and comes from the left or right speaker to match.
		shot_sound.stream = sound
		shot_sound.play()
	var gun := guns.get_node_or_null(held_weapon)
	if gun == null or not gun.has_node("Flash"):
		return
	var flash := gun.get_node("Flash") as Node3D
	flash.visible = true
	await get_tree().create_timer(FLASH_TIME).timeout
	flash.visible = false


## Shows the gun model with the same name as the weapon in hand (if there is
## one) and puts the hands on its GripRight and GripLeft markers.
func _hold(gun_name: String) -> void:
	held_weapon = gun_name
	var right_hand := EMPTY_HAND_RIGHT
	var left_hand := EMPTY_HAND_LEFT
	for gun: Node3D in guns.get_children():
		gun.visible = gun.name == gun_name
		if gun.visible:
			# to_local turns a position in the world into one measured from
			# the Aim node, which is where the shoulders are.
			right_hand = aim.to_local((gun.get_node("GripRight") as Node3D).global_position)
			left_hand = aim.to_local((gun.get_node("GripLeft") as Node3D).global_position)
	# The arms and the gun are both inside Aim, so this pose never needs
	# working out again until the weapon changes.
	_reach(arm_right, elbow_right, right_hand, Vector3(0.5, -1.0, 0.0))
	_reach(arm_left, elbow_left, left_hand, Vector3(-0.5, -1.0, 0.0))


## Turns the shoulder and bends the elbow so the hand lands on "target" (a
## position in the Aim node's space). This is "inverse kinematics": working
## out the joint angles from where the hand has to be. "elbow_towards" is
## the direction the elbow should stick out in.
func _reach(shoulder: Node3D, elbow: Node3D, target: Vector3, elbow_towards: Vector3) -> void:
	var to_target := target - shoulder.position
	# A hand out of reach just gets as close as it can, with the arm straight.
	var distance := clampf(to_target.length(), 0.05, UPPER_ARM_LENGTH + FOREARM_LENGTH - 0.001)
	var direction := to_target.normalized()

	# The shoulder, elbow and hand make a triangle with three known sides, so
	# the "law of cosines" gives the angle at the shoulder between the upper
	# arm and the straight line to the hand.
	var cos_shoulder := (UPPER_ARM_LENGTH * UPPER_ARM_LENGTH + distance * distance
			- FOREARM_LENGTH * FOREARM_LENGTH) / (2.0 * UPPER_ARM_LENGTH * distance)
	var shoulder_angle := acos(clampf(cos_shoulder, -1.0, 1.0))

	# Swing the upper arm away from that line, towards the elbow direction
	# (only its part that is square to the line counts).
	var out := (elbow_towards - direction * elbow_towards.dot(direction)).normalized()
	var upper_arm := direction * cos(shoulder_angle) + out * sin(shoulder_angle)
	var elbow_position := shoulder.position + upper_arm * UPPER_ARM_LENGTH
	var forearm := (shoulder.position + direction * distance - elbow_position).normalized()

	# The boxes hang down from each joint, along its -Y axis, and the elbow
	# bends around its X axis towards -Z. So: -Y along the upper arm, -Z
	# towards the forearm, and X square to both. A Basis made from three
	# axes is the rotation that puts the joint's axes there.
	var bend := forearm - upper_arm * forearm.dot(upper_arm)
	if bend.length() < 0.001:
		bend = out  # arm dead straight: any square direction will do
	var y_axis := -upper_arm
	var z_axis := -bend.normalized()
	shoulder.basis = Basis(y_axis.cross(z_axis), y_axis, z_axis)
	elbow.rotation = Vector3(acos(clampf(upper_arm.dot(forearm), -1.0, 1.0)), 0.0, 0.0)
