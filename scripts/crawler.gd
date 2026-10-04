extends CharacterBody3D
## A small crawling enemy that leaps at the player's head, headcrab-style.
##
## States:
##   IDLE  - sits still until it sees the player
##   CHASE - scuttles along the ground towards the player
##   LEAP  - flying through the air; hurts the player if it touches them
##   DEAD  - flipped on its back
##
## It is weak (two pistol shots) but small, quick and hard to hit mid-leap.

enum State { IDLE, CHASE, LEAP, DEAD }

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
@export var gravity := 20.0

var health := 0
var state := State.IDLE
var leap_cooldown := 0.0
## How long the current leap has lasted.
var leap_time := 0.0
## True once this leap has hurt the player, so one leap = one bite.
var leap_has_hit := false
## Seconds until the next line-of-sight check (see scripts/enemy.gd).
var sight_check_cooldown := 0.5
var player: Node3D

@onready var model: Node3D = $Model


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
	var flat_distance := flat.length()
	var flat_direction := flat.normalized()
	if flat_direction != Vector3.ZERO:
		look_at(global_position + flat_direction)

	if flat_distance < leap_range and leap_cooldown == 0.0 and is_on_floor():
		_start_leap(flat_direction, flat_distance, to_player.y)
		return

	velocity.x = flat_direction.x * crawl_speed
	velocity.z = flat_direction.z * crawl_speed


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


## Called by weapons when a shot hits this enemy.
func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	health -= amount
	if state == State.IDLE:
		state = State.CHASE
	if health <= 0:
		_die()


func _die() -> void:
	state = State.DEAD
	# Take it off every collision layer so shots and the player pass through
	# the corpse. It keeps its collision MASK, so it still lands on the floor
	# if it was killed in mid-air.
	collision_layer = 0
	# Flip onto its back.
	create_tween().tween_property(model, "rotation:z", PI, 0.25)
	create_tween().tween_property(model, "position:y", 0.3, 0.25)


func _can_see_player() -> bool:
	# The crawler's eyes are near the floor; the player's are at 1.4 m.
	var query := PhysicsRayQueryParameters3D.create(
			global_position + Vector3.UP * 0.3, player.global_position + Vector3.UP * 1.4)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == player
