extends Node3D
## A rocket fired by the rocket launcher. It flies in a dead straight line,
## leaving a trail of smoke, and explodes the moment it touches anything.
##
## Like the bullet (scripts/bullet.gd) it is not a physics body: each physics
## step it traces a ray across the gap it is about to cross, so it can never
## skip through a thin wall.

const EXPLOSION_SCENE := preload("res://scenes/explosion.tscn")

## Damage dealt to something right at the centre of the blast.
@export var blast_damage := 90
## How far the blast reaches, in metres.
@export var blast_radius := 4.5
## Seconds until it explodes in mid-air if it hasn't hit anything.
@export var lifetime := 5.0

var velocity := Vector3.ZERO
## Whoever fired the rocket, so it can't hit them on the way out.
var shooter: CollisionObject3D


## Called by the launcher right after the rocket is added to the level.
func launch(start: Vector3, direction: Vector3, speed: float) -> void:
	global_position = start
	velocity = direction * speed
	# Point the nose along the flight path.
	look_at(start + direction)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		_explode(global_position, Vector3.ZERO, null)
		return

	var next_position := global_position + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, next_position)
	if is_instance_valid(shooter):
		query.exclude = [shooter.get_rid()]

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_explode(hit.position, hit.normal, hit.collider)
		return

	global_position = next_position


## Swaps the rocket for an explosion. "normal" points straight out of the
## surface that was hit, and "collider" is the thing that was hit (or null).
func _explode(at: Vector3, normal: Vector3, collider: Object) -> void:
	var explosion := EXPLOSION_SCENE.instantiate()
	# A rocket's blast is bigger than the explosion scene's usual settings.
	explosion.max_damage = blast_damage
	explosion.radius = blast_radius
	get_parent().add_child(explosion)
	# Start the blast a little way out from the wall, not inside it.
	explosion.global_position = at + normal * 0.2
	# Walls and floors get a scorch mark; enemies don't (they move).
	if collider != null and not collider.has_method("take_damage"):
		explosion.leave_scorch_mark(at, normal)
	explosion.detonate()
	queue_free()  # removes this node from the game
