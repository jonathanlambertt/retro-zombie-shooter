extends CharacterBody3D
## A very simple enemy: stands still until it sees the player, then walks
## straight at them and hits them when close. Falls over when killed.
##
## It is a small "state machine": at any moment it is in exactly one state
## (IDLE, CHASE or DEAD) and each state has its own behaviour.
##
## Its animations are made with code instead of an AnimationPlayer. The model
## (see scenes/zombie.tscn) is a handful of boxes hanging off "pivot" nodes
## placed at the hips, waist, neck and shoulders, and _animate() below turns
## those pivots a little every frame:
##   idle    - breathes, looks from side to side, arms hanging down
##   alert   - throws its arms up for a moment when it first notices you
##   walk    - legs and arms swing, body leans forward and bobs
##   attack  - both arms are raised and chopped down
##   pain    - jerks backwards when shot
##   death   - falls onto its back or its face (picked at random)
##
## Two scenes use this script: scenes/zombie.tscn, and its copy with painted
## body parts, scenes/zombie_textured.tscn. Both set Limp and Hunch high,
## which makes the zombie drag one leg, lurch along, stoop, and let one arm
## hang. They also have Loses Limbs switched on: shoot it in an arm, a leg
## or the head often enough and that part comes off (see "Dismemberment"
## further down).
##
## With several players it goes after the nearest one it can see.
##
## Multiplayer (see scripts/network.gd): only the host's copy thinks and
## moves. Its Sync node sends the position, turn, speed, state, attacks and
## lost limbs to everyone else, whose copies just animate to match (the
## setters on those variables below start the matching animation). Shots
## can hit any copy: take_damage() passes the damage on to the host.
##
## Limitation: it walks in a straight line towards the player, so it can get
## stuck behind walls. Proper pathfinding (NavigationAgent3D) is a next step.

enum State { IDLE, CHASE, DEAD }

const BLOOD_SPLASH_SCENE := preload("res://scenes/blood_splash.tscn")
const GIB_SCENE := preload("res://scenes/gib.tscn")

## Arm angles, in radians. 0 = held straight out in front, zombie-style.
const ARMS_DOWN := -1.25
const ARMS_UP := 1.1
## How long each one-off animation lasts, in seconds.
const ALERT_TIME := 0.4
const ATTACK_TIME := 0.3
const PAIN_TIME := 0.25

@export var max_health := 30
@export var move_speed := 3.0
## How far away it can notice the player, in metres.
@export var sight_range := 14.0
## How close it must be to hit the player.
@export var attack_range := 1.6
@export var attack_damage := 10
## Seconds between hits.
@export var attack_interval := 1.0
@export var gravity := 20.0
## How fast the legs swing while walking. Higher = quicker, shorter steps.
@export var step_speed := 9.0
## The colour of the drops that fly off when it is shot.
@export var blood_color := Color(0.7, 0.04, 0.04)

@export_group("Zombie walk")
## How badly it limps. 0 = an even walk. 1 = it drags its right leg, sags
## onto it with every step, moves in surges, tilts its head and lets its
## left arm hang.
@export_range(0.0, 1.0) var limp := 0.0
## How far it stoops forwards all the time, in radians.
@export var hunch := 0.0

@export_group("Dismemberment")
## If true, its arms, legs and head can be shot off.
##   head - it dies at once
##   arm  - its attack does half the damage (a quarter with both gone)
##   leg  - it falls over and drags itself along the floor, much slower
@export var loses_limbs := false
## How much damage one limb can take before it comes off.
@export var limb_health := 12
## The chance that the head really comes off once it has taken that much
## damage. 1 = always, 0 = never. The dice are rolled once: a head that
## stays on then stays on for good, and headshots just do their damage.
@export_range(0.0, 1.0) var head_loss_chance := 0.35
## The same for each leg. Lower = fewer enemies end up crawling.
@export_range(0.0, 1.0) var leg_loss_chance := 0.6
## The same for each arm.
@export_range(0.0, 1.0) var arm_loss_chance := 0.75
## How much of its speed is left once it is crawling.
@export_range(0.0, 1.0) var crawl_speed_factor := 0.4

var health := 0
## What it is doing. Online the host's copy decides, and the others are sent
## each change; the setter starts the animation that goes with it.
var state := State.IDLE:
	set(value):
		var previous := state
		state = value
		if value == State.CHASE and previous == State.IDLE:
			alert_timer = ALERT_TIME
		elif value == State.DEAD and previous != State.DEAD:
			_play_death()
## Which way it falls when it dies: 1 = onto its back, -1 = onto its face.
## Picked by the host and sent along with the state, so it falls the same
## way for everyone.
var death_direction := 1.0
## How many attacks it has made. The number itself doesn't matter: each time
## it goes up (here or over the network) the attack animation plays.
var attacks := 0:
	set(value):
		attacks = value
		attack_timer = ATTACK_TIME
var attack_cooldown := 0.0
## Seconds until the next line-of-sight check. Looking only a few times a
## second is plenty, and the short initial wait gives the level's collision
## time to be built before the first check (CSG builds it on the first frame).
var sight_check_cooldown := 0.5
## The player it is after (or null). With several players it picks again
## every so often, so it goes for whoever is closest.
var player: Node3D

## A clock for the animations that repeat (breathing, looking around). It
## starts at a random value so a group of enemies doesn't move in unison.
var anim_time := randf() * 10.0
## How far through the walking cycle the legs are.
var walk_phase := 0.0
## Countdown timers for the one-off animations. 0 = not playing.
var alert_timer := 0.0
var attack_timer := 0.0
var pain_timer := 0.0

## The damage each limb has taken so far, for example {"head": 6}.
var limb_damage := {}
## The names of the limbs that have been shot off.
var lost_limbs: Array[String] = []
## The same list, as sent over the network by the host. When it arrives with
## a new limb in it, that limb comes off here too.
var severed := PackedStringArray():
	set(value):
		severed = value
		for limb in value:
			if limb not in lost_limbs:
				_lose_limb(limb)
## The names of the limbs that took enough damage to come off but held on
## (see head_loss_chance). They can't be shot off any more.
var sturdy_limbs: Array[String] = []
## Which limb the latest wound is on: "head", "arm_left", "arm_right",
## "leg_left", "leg_right", "random" (a blast, which could take any of
## them) or "" (the body, or no wound). bleed() sets this from where the
## shot landed, and take_damage() uses it a moment later.
var wounded_limb := ""
## True once it has lost a leg and is dragging itself along the floor.
var crawling := false

@onready var model: Node3D = $Model
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var leg_left: Node3D = $Model/LegLeft
@onready var leg_right: Node3D = $Model/LegRight
@onready var upper: Node3D = $Model/Upper
@onready var head: Node3D = $Model/Upper/Head
@onready var arm_left: Node3D = $Model/Upper/ArmLeft
@onready var arm_right: Node3D = $Model/Upper/ArmRight


func _ready() -> void:
	health = max_health
	# Start with the arms already hanging down.
	arm_left.rotation.x = ARMS_DOWN
	arm_right.rotation.x = ARMS_DOWN
	# A limping enemy holds its head crooked.
	head.rotation.z = 0.35 * limp


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	if not is_multiplayer_authority():
		# Someone else is the host, and sends where this enemy is. Between
		# their updates, keep it moving at the speed it was last sent, so it
		# glides along instead of jumping from spot to spot.
		global_position += Vector3(velocity.x, 0.0, velocity.z) * delta
		return

	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# A few times a second: while idle, look for a player near enough and
	# not hidden behind a wall; while chasing, switch to whichever player is
	# closest now.
	sight_check_cooldown -= delta
	if sight_check_cooldown <= 0.0:
		sight_check_cooldown = 0.25
		if state == State.IDLE:
			var seen := _closest_player(true)
			if seen:
				player = seen
				_wake_up()
		else:
			player = _closest_player(false)
	if not is_instance_valid(player):
		player = null
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()

	velocity.x = 0.0
	velocity.z = 0.0
	if state == State.CHASE:
		# Ignore height so the enemy turns and walks along the ground.
		var flat_direction := Vector3(to_player.x, 0.0, to_player.z).normalized()
		if flat_direction != Vector3.ZERO:
			# look_at points this node's forward (-Z) side at a position.
			look_at(global_position + flat_direction)

		if distance > attack_range:
			var speed := move_speed * _lurch()
			if crawling:
				speed *= crawl_speed_factor
			velocity.x = flat_direction.x * speed
			velocity.z = flat_direction.z * speed
		elif attack_cooldown == 0.0:
			attack_cooldown = attack_interval
			attacks += 1  # plays the attack animation everywhere
			player.take_damage(_attack_strength())

	move_and_slide()


## How hard it hits right now. Every arm it has lost halves the damage; with
## none left, all it can do is bite.
func _attack_strength() -> int:
	var arms_lost := lost_limbs.count("arm_left") + lost_limbs.count("arm_right")
	var strength: float = [1.0, 0.5, 0.25][arms_lost]
	return maxi(roundi(attack_damage * strength), 1)


## How much of its full speed the enemy has at this point in its stride:
## always 1.0 for an even walker. A limper slows right down while its weight
## is on the bad leg and surges forward as it pushes off the good one.
func _lurch() -> float:
	return 1.0 - limp * 0.5 * (0.5 + 0.5 * sin(walk_phase))


# _process runs once per drawn frame, which is the right place for things
# that are only for show.
func _process(delta: float) -> void:
	if state != State.DEAD:
		_animate(delta)


## Works out the pose the enemy should be in right now, then eases every
## joint towards it.
func _animate(delta: float) -> void:
	anim_time += delta
	alert_timer = maxf(alert_timer - delta, 0.0)
	attack_timer = maxf(attack_timer - delta, 0.0)
	pain_timer = maxf(pain_timer - delta, 0.0)

	# The pose we are aiming for. Each animation below overrides the parts
	# it cares about, and later ones win over earlier ones.
	var leg_swing := 0.0   # left leg forwards, right leg back (and vice versa)
	var leg_drag := 0.0    # the right leg trailing behind (limping only)
	var roll := 0.0        # the body sagging over to one side (limping only)
	var arm_angle := ARMS_DOWN
	var arm_swing := 0.0
	var lean := 0.0        # negative = leaning forwards
	var head_turn := 0.0
	var bob := 0.0         # how far the whole body is lifted
	var dangle := limp     # how much the left arm just hangs (limping only)

	if state == State.IDLE:
		# Breathe slowly and look from side to side.
		bob = sin(anim_time * 2.0) * 0.015
		head_turn = sin(anim_time * 0.8) * 0.6
	else:
		arm_angle = 0.0
		lean = -0.15
		var speed := Vector2(velocity.x, velocity.z).length()
		if speed > 0.1:
			# sin() swings smoothly between -1 and 1, like a pendulum.
			walk_phase += step_speed * delta
			leg_swing = sin(walk_phase) * 0.7
			arm_swing = sin(walk_phase) * 0.25
			# abs() makes it bounce once for each foot that lands.
			bob = absf(sin(walk_phase)) * 0.05
			if limp > 0.0:
				# 1 while the weight is on the bad (right) leg, 0 otherwise.
				var on_bad_leg := maxf(sin(walk_phase), 0.0)
				leg_drag = 0.3 * limp
				roll = -0.22 * limp * on_bad_leg
				bob -= 0.07 * limp * on_bad_leg

	lean -= hunch

	if alert_timer > 0.0:
		arm_angle = ARMS_UP
		lean = 0.2
	if attack_timer > 0.0:
		# "progress" runs from 0 to 1 over the swing: arms start high and
		# chop down past straight-ahead.
		var progress := 1.0 - attack_timer / ATTACK_TIME
		arm_angle = lerpf(ARMS_UP, -0.9, progress)
		arm_swing = 0.0
		lean = -0.4
	if crawling:
		# Flat on its front with the hips just off the floor, hauling itself
		# along with both arms. The arms are angled back up by as much as
		# the body is tipped forward, so they reach along the ground.
		lean = -1.35
		bob = 0.2 - upper.position.y
		roll = sin(walk_phase) * 0.1
		dangle = 0.0
		if attack_timer == 0.0:
			arm_angle = 1.35
			arm_swing = sin(walk_phase) * 0.5

	if pain_timer > 0.0:
		lean = 0.45 if not crawling else -1.0
		head_turn = 0.5

	# Ease towards the pose instead of jumping to it, so one animation
	# flows into the next. A bigger number here = snappier movement.
	var blend := 1.0 - exp(-18.0 * delta)
	var left_leg := leg_swing
	# A bad leg takes much shorter steps and never swings out in front.
	var right_leg := -leg_swing * (1.0 - 0.75 * limp) - leg_drag
	if crawling:
		# Whatever legs are left trail out behind.
		left_leg = -1.4
		right_leg = -1.4
	leg_left.rotation.x = lerpf(leg_left.rotation.x, left_leg, blend)
	leg_right.rotation.x = lerpf(leg_right.rotation.x, right_leg, blend)
	# The more it limps, the more its left arm just dangles and sways
	# instead of joining in. (lerpf with 0 gives the first value, with 1
	# the second, and in between a mix of the two.)
	var dangling := ARMS_DOWN + sin(anim_time * 3.0) * 0.12
	var left_arm := lerpf(arm_angle - arm_swing, dangling, dangle)
	arm_left.rotation.x = lerpf(arm_left.rotation.x, left_arm, blend)
	arm_right.rotation.x = lerpf(arm_right.rotation.x, arm_angle + arm_swing, blend)
	upper.rotation.x = lerpf(upper.rotation.x, lean, blend)
	upper.rotation.z = lerpf(upper.rotation.z, roll, blend)
	head.rotation.y = lerpf(head.rotation.y, head_turn, blend)
	model.position.y = lerpf(model.position.y, bob, blend)


## Switches from standing around to chasing the player. (Setting the state
## plays the "alert" animation, see the setter on "state".)
func _wake_up() -> void:
	if state != State.IDLE:
		return
	state = State.CHASE
	if player == null:
		player = _closest_player(false)


## Called by weapons when a shot hits this enemy.
##
## The @rpc line lets other computers call this function on this one. Only
## the host's copy keeps track of health, so a hit on any other copy (from
## a player who joined the host's game) is sent to the host: rpc_id runs
## this same function there. (In single player we are the host.)
@rpc("any_peer", "call_remote", "reliable")
func take_damage(amount: int) -> void:
	if not is_multiplayer_authority():
		take_damage.rpc_id(get_multiplayer_authority(), amount)
		return
	if state == State.DEAD:
		return
	health -= amount
	pain_timer = PAIN_TIME
	# Being shot always gets its attention, even from behind.
	_wake_up()
	if loses_limbs:
		_damage_limb(wounded_limb, amount)
	wounded_limb = ""
	if health <= 0:
		_die()


## Sprays blood from a wound. Weapons call this with the spot they hit and
## the direction pointing straight out of it. Vector3.ZERO means "no
## particular direction": the blood goes up and lands all around.
##
## Blood is for everyone to see, so this sends the wound to every computer
## (rpc() runs _bleed here and on all the others). The host's copy also
## notes which limb was hit; the damage that follows arrives after this.
func bleed(at: Vector3, spray_direction: Vector3, drop_count := 12) -> void:
	_bleed.rpc(at, spray_direction, drop_count)


@rpc("any_peer", "call_local", "reliable")
func _bleed(at: Vector3, spray_direction: Vector3, drop_count: int) -> void:
	if state == State.DEAD:
		return
	# Remember which limb this wound is on, for take_damage().
	wounded_limb = _limb_at(at) if spray_direction != Vector3.ZERO else "random"
	pain_timer = PAIN_TIME
	_spray_blood(at, spray_direction, drop_count)


func _spray_blood(at: Vector3, spray_direction: Vector3, drop_count: int) -> void:
	var splash := BLOOD_SPLASH_SCENE.instantiate()
	# Add it to the level rather than to this enemy, so the drops fall
	# where they were shed instead of following the enemy around.
	get_parent().add_child(splash)
	splash.splash(at, spray_direction, blood_color, drop_count)


## Runs on the host. Setting the state sends it to everyone, and its
## setter plays the death below on every computer.
func _die() -> void:
	death_direction = 1.0 if randf() < 0.5 else -1.0
	state = State.DEAD


func _play_death() -> void:
	# One last, bigger burst from the chest.
	_spray_blood(global_position + Vector3.UP * 1.0, Vector3.ZERO, 40)
	# Turn collision off so the body no longer blocks movement or bullets.
	# set_deferred waits until the physics engine is ready for the change.
	collision_shape.set_deferred("disabled", true)

	# Tip the model over and leave it there as a corpse.
	var direction := death_direction
	# A Tween animates properties over time. set_parallel makes every
	# tween_property below run at once instead of one after another.
	var tween := create_tween().set_parallel()
	tween.tween_property(model, "rotation:x", direction * PI / 2.0, 0.35)
	tween.tween_property(model, "position:y", 0.2, 0.35)
	# Go limp: arms flung out past the head, legs apart, head lolling.
	tween.tween_property(upper, "rotation:x", 0.0, 0.2)
	tween.tween_property(upper, "rotation:z", 0.0, 0.2)
	tween.tween_property(arm_left, "rotation:x", direction * 1.4, 0.25)
	tween.tween_property(arm_right, "rotation:x", direction * 1.0, 0.35)
	tween.tween_property(leg_left, "rotation:x", direction * 0.3, 0.3)
	tween.tween_property(leg_right, "rotation:x", direction * -0.15, 0.3)
	tween.tween_property(leg_left, "rotation:z", -0.2, 0.3)
	tween.tween_property(leg_right, "rotation:z", 0.25, 0.3)
	tween.tween_property(head, "rotation:y", 0.7, 0.3)


# --- Dismemberment -----------------------------------------------------------

## Works out which limb a point on the body belongs to, from how high up it
## is and how far out to the side. Returns "" for the chest and belly.
func _limb_at(at: Vector3) -> String:
	# to_local turns a position in the level into one measured from this
	# enemy's own feet: x = to its right, y = up.
	var local := to_local(at)
	var side := "left" if local.x < 0.0 else "right"
	var radius := (collision_shape.shape as CapsuleShape3D).radius
	var out_to_the_side := absf(local.x) > radius * 0.5

	if crawling:
		# Lying down, the only parts that can still be picked out are the arms.
		return "arm_" + side if out_to_the_side else ""
	# The hips and the neck are where the model's pivots are.
	var hip_height := upper.position.y
	var neck_height := hip_height + head.position.y
	if local.y > neck_height:
		return "head"
	if local.y < hip_height:
		return "leg_" + side
	return "arm_" + side if out_to_the_side else ""


## Adds damage to one limb, and takes it off if that was the last straw.
func _damage_limb(limb: String, amount: int) -> void:
	if limb == "random":
		# A blast picks any limb that is still attached (but spares the head).
		var attached: Array[String] = []
		for candidate: String in ["arm_left", "arm_right", "leg_left", "leg_right"]:
			if candidate not in lost_limbs and candidate not in sturdy_limbs:
				attached.append(candidate)
		if attached.is_empty():
			return
		limb = attached.pick_random()
	if limb == "" or limb in lost_limbs or limb in sturdy_limbs:
		return

	limb_damage[limb] = limb_damage.get(limb, 0) + amount
	if limb_damage[limb] >= limb_health:
		# randf() gives a random number from 0 to 1, so this is true
		# "chance" of the time.
		if randf() < _loss_chance(limb):
			_lose_limb(limb)
			# Send the new list to everyone else (see "severed").
			severed = PackedStringArray(lost_limbs)
		else:
			sturdy_limbs.append(limb)


## How likely a limb is to come off once it has taken limb_health damage.
func _loss_chance(limb: String) -> float:
	if limb == "head":
		return head_loss_chance
	if limb.begins_with("leg"):
		return leg_loss_chance
	return arm_loss_chance


func _lose_limb(limb: String) -> void:
	lost_limbs.append(limb)
	match limb:
		"head":
			head = _sever(head)
			health = 0  # nothing walks away from that
		"arm_left":
			arm_left = _sever(arm_left)
		"arm_right":
			arm_right = _sever(arm_right)
		"leg_left":
			leg_left = _sever(leg_left)
			_start_crawling()
		"leg_right":
			leg_right = _sever(leg_right)
			_start_crawling()


## Detaches one piece of the model and sends it flying as a gib
## (scenes/gib.tscn), with a spurt of blood from the stump.
##
## Returns an empty, invisible stand-in left in the limb's place. The caller
## stores it in the same variable the limb was in, so the animation code can
## carry on turning "the arm" without needing to know it has gone.
func _sever(limb: Node3D) -> Node3D:
	var stand_in := Node3D.new()
	limb.get_parent().add_child(stand_in)
	stand_in.transform = limb.transform

	var stump := limb.global_position
	var gib := GIB_SCENE.instantiate()
	# Add it to the level rather than to this enemy, so it stays where it
	# lands instead of following the enemy around.
	get_parent().add_child(gib)
	gib.global_position = stump
	# reparent moves a node to a new parent without changing where it is.
	limb.reparent(gib)

	# Throw it up and away from the middle of the body.
	var away := stump - (global_position + Vector3.UP * upper.position.y)
	away.y = 0.0
	gib.launch(away.normalized() * randf_range(1.0, 3.0) + Vector3.UP * randf_range(2.5, 4.5))

	_spray_blood(stump, Vector3.UP, 24)
	return stand_in


## Called when a leg comes off: from now on it drags itself along the floor.
func _start_crawling() -> void:
	if crawling:
		return
	crawling = true
	# Swap the tall collision capsule for one as low as the body now is, so
	# shots that pass over it miss. (A new shape is made rather than changing
	# the old one, because every copy of this enemy shares the old one.)
	var old_shape := collision_shape.shape as CapsuleShape3D
	var low_shape := CapsuleShape3D.new()
	low_shape.radius = old_shape.radius
	low_shape.height = old_shape.radius * 2.0 + 0.1
	# set_deferred waits until the physics engine is ready for the change.
	collision_shape.set_deferred("shape", low_shape)
	collision_shape.set_deferred("position", Vector3.UP * low_shape.height / 2.0)


## The nearest player, or null if there are none. With "must_see" true,
## only players within sight range and in clear view count.
func _closest_player(must_see: bool) -> Node3D:
	var closest: Node3D = null
	var closest_distance := sight_range if must_see else INF
	# Every player is in the "player" group, ours and everyone else's.
	for candidate: Node3D in get_tree().get_nodes_in_group("player"):
		var distance := global_position.distance_to(candidate.global_position)
		if distance < closest_distance and (not must_see or _can_see(candidate)):
			closest = candidate
			closest_distance = distance
	return closest


## Traces a ray from the enemy's eyes to a player's. If the first thing it
## touches is that player (or nothing at all), the view is clear.
func _can_see(target: Node3D) -> bool:
	# (Player and enemy eyes are both about 1.4 m up, unless it is crawling.)
	var eye_height := Vector3.UP * (1.4 if not crawling else 0.4)
	var query := PhysicsRayQueryParameters3D.create(
			global_position + eye_height, target.global_position + eye_height)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == target
