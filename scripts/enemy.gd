extends CharacterBody3D
## A very simple enemy: stands still until it sees the player, then walks
## straight at them and hits them when close. Falls over when killed.
##
## It is a small "state machine": at any moment it is in exactly one state
## (IDLE, CHASE or DEAD) and each state has its own behaviour.
##
## Limitation: it walks in a straight line towards the player, so it can get
## stuck behind walls. Proper pathfinding (NavigationAgent3D) is a next step.

enum State { IDLE, CHASE, DEAD }

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

var health := 0
var state := State.IDLE
var attack_cooldown := 0.0
## Seconds until the next line-of-sight check. Looking only a few times a
## second is plenty, and the short initial wait gives the level's collision
## time to be built before the first check (CSG builds it on the first frame).
var sight_check_cooldown := 0.5
var player: Node3D

@onready var model: Node3D = $Model
@onready var collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	health = max_health
	# The player scene is in the "player" group, which lets us find it
	# without knowing where it sits in the scene tree.
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if state == State.DEAD or player == null:
		return

	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	if not is_on_floor():
		velocity.y -= gravity * delta

	var to_player := player.global_position - global_position
	var distance := to_player.length()

	# Wake up when the player is near enough and not hidden behind a wall.
	sight_check_cooldown -= delta
	if state == State.IDLE and sight_check_cooldown <= 0.0:
		sight_check_cooldown = 0.25
		if distance < sight_range and _can_see_player():
			state = State.CHASE

	velocity.x = 0.0
	velocity.z = 0.0
	if state == State.CHASE:
		# Ignore height so the enemy turns and walks along the ground.
		var flat_direction := Vector3(to_player.x, 0.0, to_player.z).normalized()
		if flat_direction != Vector3.ZERO:
			# look_at points this node's forward (-Z) side at a position.
			look_at(global_position + flat_direction)

		if distance > attack_range:
			velocity.x = flat_direction.x * move_speed
			velocity.z = flat_direction.z * move_speed
		elif attack_cooldown == 0.0:
			attack_cooldown = attack_interval
			player.take_damage(attack_damage)

	move_and_slide()


## Called by the pistol when a shot hits this enemy.
func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	health -= amount
	# Being shot always gets its attention, even from behind.
	state = State.CHASE
	if health <= 0:
		_die()


func _die() -> void:
	state = State.DEAD
	# Turn collision off so the body no longer blocks movement or bullets.
	# set_deferred waits until the physics engine is ready for the change.
	collision_shape.set_deferred("disabled", true)
	# Tip the model over onto its back and leave it there as a corpse.
	var tween := create_tween()
	tween.tween_property(model, "rotation:x", PI / 2.0, 0.3)
	tween.parallel().tween_property(model, "position:y", 0.2, 0.3)


## Traces a ray from the enemy's eyes to the player's. If the first thing it
## touches is the player (or nothing at all), the view is clear.
func _can_see_player() -> bool:
	var eye_height := Vector3.UP * 1.4
	var query := PhysicsRayQueryParameters3D.create(
			global_position + eye_height, player.global_position + eye_height)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == player
