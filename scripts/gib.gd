extends Node3D
## A body part that has been shot off an enemy, or a piece of something that
## has been smashed. It tumbles through the air, bounces off walls, comes to
## rest on the floor and is cleared away later.
##
## The gib has no picture of its own. Whoever makes it moves the severed
## limb (a piece of the enemy's model) inside it: see _sever() in
## scripts/enemy.gd. A potted plant does the same with its stem, its leaves
## and the pieces of its pot: see _throw() in scripts/potted_plant.gd.
##
## Like the bullet (scripts/bullet.gd) it is not a physics body: each physics
## step it traces a ray across the gap it is about to cross.

## The most gibs allowed at once. When there are more, the oldest one is
## removed.
const MAX_GIBS := 24

## Every gib currently in the level, oldest first. "static" means this one
## list is shared by all gibs instead of each having its own.
static var gibs: Array[Node3D] = []

@export var gravity := 16.0
## Seconds until the gib is cleared away.
@export var lifetime := 20.0

var velocity := Vector3.ZERO
## How fast it tumbles around each axis, in radians per second.
var spin := Vector3.ZERO
## True once it has landed and stopped moving.
var resting := false


func _ready() -> void:
	gibs.append(self)
	if gibs.size() > MAX_GIBS:
		gibs[0].queue_free()  # _exit_tree below takes it off the list


# Called when this node leaves the game, for any reason (including the whole
# level being reloaded when the player dies).
func _exit_tree() -> void:
	gibs.erase(self)


## Called right after the gib is added to the level, to send it flying.
func launch(start_velocity: Vector3) -> void:
	velocity = start_velocity
	spin = Vector3(randf_range(-9.0, 9.0), randf_range(-9.0, 9.0), randf_range(-9.0, 9.0))


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()  # removes this node from the game
		return
	if resting:
		return

	velocity.y -= gravity * delta
	var next_position := global_position + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, next_position)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)

	# Bodies (enemies, the player, crates) are ignored: a gib only stops for
	# the level itself.
	if hit.is_empty() or hit.collider.has_method("take_damage"):
		global_position = next_position
		rotation += spin * delta
	elif hit.normal.y > 0.7:
		# Landed on a floor. Sit just above it and stop.
		global_position = hit.position + Vector3.UP * 0.08
		resting = true
	else:
		# Hit a wall or ceiling: bounce off, losing most of the speed.
		velocity = velocity.bounce(hit.normal) * 0.3
