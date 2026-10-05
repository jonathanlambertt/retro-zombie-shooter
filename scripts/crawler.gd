extends CharacterBody3D
## A small crawling enemy that leaps at the player's head, headcrab-style.
##
## States:
##   IDLE   - sits still until it sees the player
##   CHASE  - scuttles along the ground towards the player
##   CROUCH - a short wind-up before a leap, which also warns the player
##   LEAP   - flying through the air; hurts the player if it touches them
##   DEAD   - flipped on its back
##
## It is weak (two pistol shots) but small, quick and hard to hit mid-leap.
##
## Like scripts/enemy.gd, its animations are made with code: _animate() turns
## the legs, fangs and body a little every frame.
##   idle    - breathes, fangs twitch now and then
##   scuttle - legs paddle in diagonal pairs, body rocks from side to side
##   crouch  - sinks down, rears back and spreads its legs
##   leap    - nose follows its flight path, legs flung out, fangs wide open
##   landing - squashes flat for a moment
##   pain    - jolts sideways when shot
##   death   - flips over, legs curl up and twitch

enum State { IDLE, CHASE, CROUCH, LEAP, DEAD }

const BLOOD_SPLASH_SCENE := preload("res://scenes/blood_splash.tscn")

## How long each one-off animation lasts, in seconds.
const LAND_TIME := 0.2
const PAIN_TIME := 0.2

@export var max_health := 12
@export var crawl_speed := 2.5
## How far away it can notice the player, in metres.
@export var sight_range := 10.0
## It leaps when the player is closer than this.
@export var leap_range := 5.0
## Horizontal speed of a leap, in metres per second.
@export var leap_speed := 9.0
## The height on the player's body it aims for (1.3 is about face height).
@export var leap_target_height := 1.3
@export var leap_damage := 15
## Seconds it waits after landing before it can leap again.
@export var leap_cooldown_time := 1.5
## Seconds it spends crouched before each leap.
@export var crouch_time := 0.25
@export var gravity := 20.0
## How fast the legs paddle while scuttling.
@export var step_speed := 22.0
## The colour of the drops that fly off when it is shot: alien blood is a
## sickly yellow-green.
@export var blood_color := Color(0.78, 0.82, 0.1)

var health := 0
var state := State.IDLE
var leap_cooldown := 0.0
## How long the current crouch has lasted.
var crouch_timer := 0.0
## How long the current leap has lasted.
var leap_time := 0.0
## True once this leap has hurt the player, so one leap = one bite.
var leap_has_hit := false
## Seconds until the next line-of-sight check (see scripts/enemy.gd).
var sight_check_cooldown := 0.5
var player: Node3D

## A clock for the animations that repeat. It starts at a random value so a
## group of crawlers doesn't move in unison.
var anim_time := randf() * 10.0
## How far through the scuttling cycle the legs are.
var walk_phase := 0.0
## Countdown timers for the one-off animations. 0 = not playing.
var land_timer := 0.0
var pain_timer := 0.0
## Which way the pain jolt tips the body: 1 or -1.
var pain_side := 1.0

@onready var model: Node3D = $Model
@onready var fang_left: Node3D = $Model/FangLeft
@onready var fang_right: Node3D = $Model/FangRight
## The four legs. "side" is -1 for left legs and 1 for right legs, and
## "pair" says which diagonal pair the leg steps with.
@onready var legs: Array[Dictionary] = [
	{"node": $Model/LegFrontLeft, "side": -1.0, "pair": 1.0},
	{"node": $Model/LegFrontRight, "side": 1.0, "pair": -1.0},
	{"node": $Model/LegBackLeft, "side": -1.0, "pair": -1.0},
	{"node": $Model/LegBackRight, "side": 1.0, "pair": 1.0},
]

## How far each leg leans outwards when standing normally, in radians.
const LEG_SPLAY := 0.52


func _ready() -> void:
	health = max_health
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if player == null:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta

	match state:
		State.IDLE:
			_idle(delta)
		State.CHASE:
			_chase(delta)
		State.CROUCH:
			_crouch(delta)
		State.LEAP:
			_leap(delta)
		State.DEAD:
			# A corpse just drops to the floor and stays put.
			velocity.x = 0.0
			velocity.z = 0.0

	move_and_slide()

	if state == State.LEAP:
		_check_leap_hit()


func _idle(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	sight_check_cooldown -= delta
	if sight_check_cooldown <= 0.0:
		sight_check_cooldown = 0.25
		var distance := global_position.distance_to(player.global_position)
		if distance < sight_range and _can_see_player():
			state = State.CHASE


func _chase(delta: float) -> void:
	leap_cooldown = maxf(leap_cooldown - delta, 0.0)

	var to_player := player.global_position - global_position
	var flat := Vector3(to_player.x, 0.0, to_player.z)
	var flat_direction := flat.normalized()
	if flat_direction != Vector3.ZERO:
		look_at(global_position + flat_direction)

	if flat.length() < leap_range and leap_cooldown == 0.0 and is_on_floor():
		state = State.CROUCH
		crouch_timer = 0.0
		return

	velocity.x = flat_direction.x * crawl_speed
	velocity.z = flat_direction.z * crawl_speed


## Holds still for a moment, still turning to face the player, then leaps.
func _crouch(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	var to_player := player.global_position - global_position
	var flat := Vector3(to_player.x, 0.0, to_player.z)
	var flat_direction := flat.normalized()
	if flat_direction != Vector3.ZERO:
		look_at(global_position + flat_direction)

	crouch_timer += delta
	if crouch_timer >= crouch_time:
		_start_leap(flat_direction, flat.length(), to_player.y)


## Launches the crawler so that it arrives at the player's face.
func _start_leap(direction: Vector3, distance: float, height_difference: float) -> void:
	state = State.LEAP
	leap_time = 0.0
	leap_has_hit = false

	# How long the flight will take. Never less than 0.3 seconds, so a leap
	# from point-blank range becomes a short hop instead of a rocket launch.
	var flight_time := maxf(distance / leap_speed, 0.3)
	var horizontal_speed := distance / flight_time
	velocity.x = direction.x * horizontal_speed
	velocity.z = direction.z * horizontal_speed

	# The upward speed needed to rise this much in that time while gravity
	# pulls down:  height = up_speed * t - 0.5 * gravity * t * t
	var rise := height_difference + leap_target_height
	velocity.y = (rise + 0.5 * gravity * flight_time * flight_time) / flight_time


func _leap(delta: float) -> void:
	leap_time += delta
	# Back on the ground (after at least a moment in the air): leap is over.
	if leap_time > 0.1 and is_on_floor():
		state = State.CHASE
		leap_cooldown = leap_cooldown_time
		land_timer = LAND_TIME


## After moving, see whether the crawler bumped into the player.
func _check_leap_hit() -> void:
	if leap_has_hit:
		return
	# move_and_slide() remembers everything the body touched this step.
	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() == player:
			leap_has_hit = true
			player.take_damage(leap_damage)
			# Bounce off instead of sticking to the player.
			velocity.x *= -0.3
			velocity.z *= -0.3
			return


# _process runs once per drawn frame, which is the right place for things
# that are only for show.
func _process(delta: float) -> void:
	if state != State.DEAD:
		_animate(delta)


## Works out the pose the crawler should be in right now, then eases every
## part towards it.
func _animate(delta: float) -> void:
	anim_time += delta
	land_timer = maxf(land_timer - delta, 0.0)
	pain_timer = maxf(pain_timer - delta, 0.0)

	# The pose we are aiming for.
	var height := 0.0       # how far the body is lifted (negative = sunk down)
	var pitch := 0.0        # positive = nose up
	var roll := 0.0         # tipping over to one side
	var leg_swing := 0.0    # legs paddling forwards and back
	var leg_spread := 0.0   # legs pushed further out to the sides
	var fang_open := 0.0    # fangs swung apart

	match state:
		State.IDLE:
			height = sin(anim_time * 2.5) * 0.01
			# sin() is only above 0.9 for a moment in each cycle, which makes
			# a quick twitch with a long rest in between.
			if sin(anim_time * 1.7) > 0.9:
				fang_open = 0.35
		State.CHASE:
			walk_phase += step_speed * delta
			leg_swing = sin(walk_phase) * 0.6
			roll = sin(walk_phase) * 0.08
			height = absf(sin(walk_phase)) * 0.02
			fang_open = 0.15
		State.CROUCH:
			height = -0.07
			pitch = 0.3
			leg_spread = 0.4
			fang_open = 0.5
		State.LEAP:
			# Point the nose along the flight path: up on the way up, down
			# on the way down.
			var forward_speed := Vector2(velocity.x, velocity.z).length()
			pitch = clampf(atan2(velocity.y, forward_speed), -0.9, 0.9)
			leg_spread = 0.7
			fang_open = 0.8

	if land_timer > 0.0:
		height = -0.08
		leg_spread = 0.5
	if pain_timer > 0.0:
		roll = 0.5 * pain_side
		height = 0.08

	# Ease towards the pose instead of jumping to it, so one animation
	# flows into the next. A bigger number here = snappier movement.
	var blend := 1.0 - exp(-20.0 * delta)
	model.position.y = lerpf(model.position.y, height, blend)
	model.rotation.x = lerpf(model.rotation.x, pitch, blend)
	model.rotation.z = lerpf(model.rotation.z, roll, blend)
	fang_left.rotation.y = lerpf(fang_left.rotation.y, fang_open, blend)
	fang_right.rotation.y = lerpf(fang_right.rotation.y, -fang_open, blend)
	for leg in legs:
		var node: Node3D = leg.node
		node.rotation.x = lerpf(node.rotation.x, leg_swing * leg.pair, blend)
		node.rotation.z = lerpf(node.rotation.z, (LEG_SPLAY + leg_spread) * leg.side, blend)


## Called by weapons when a shot hits this enemy.
func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	health -= amount
	pain_timer = PAIN_TIME
	pain_side = 1.0 if randf() < 0.5 else -1.0
	if state == State.IDLE:
		state = State.CHASE
	if health <= 0:
		_die()


## Sprays blood from a wound. Weapons call this with the spot they hit and
## the direction pointing straight out of it. Vector3.ZERO means "no
## particular direction": the blood goes up and lands all around.
func bleed(at: Vector3, spray_direction: Vector3, drop_count := 12) -> void:
	if state == State.DEAD:
		return
	var splash := BLOOD_SPLASH_SCENE.instantiate()
	# Add it to the level rather than to this enemy, so the drops fall
	# where they were shed instead of following the enemy around.
	get_parent().add_child(splash)
	splash.splash(at, spray_direction, blood_color, drop_count)


func _die() -> void:
	# One last, bigger burst. (This has to come before the state changes,
	# because the dead don't bleed.)
	bleed(global_position + Vector3.UP * 0.3, Vector3.ZERO, 30)
	state = State.DEAD
	# Take it off every collision layer so shots and the player pass through
	# the corpse. It keeps its collision MASK, so it still lands on the floor
	# if it was killed in mid-air.
	collision_layer = 0

	# Flip onto its back. set_parallel makes every tween_property below run
	# at once instead of one after another.
	var flip := create_tween().set_parallel()
	flip.tween_property(model, "rotation:z", PI, 0.25)
	flip.tween_property(model, "rotation:x", 0.0, 0.25)
	flip.tween_property(model, "position:y", 0.3, 0.25)

	# Each leg curls in over the belly, kicks a few times, then goes still.
	# A tween without set_parallel plays its steps one after another.
	for leg in legs:
		var node: Node3D = leg.node
		var curled: float = -0.5 * leg.side
		var kicked: float = 0.1 * leg.side
		var twitch := create_tween()
		twitch.tween_property(node, "rotation:z", curled, 0.3)
		for i in 3:
			twitch.tween_property(node, "rotation:z", kicked, randf_range(0.06, 0.12))
			twitch.tween_property(node, "rotation:z", curled, randf_range(0.1, 0.2))


func _can_see_player() -> bool:
	# The crawler's eyes are near the floor; the player's are at 1.4 m.
	var query := PhysicsRayQueryParameters3D.create(
			global_position + Vector3.UP * 0.3, player.global_position + Vector3.UP * 1.4)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == player
