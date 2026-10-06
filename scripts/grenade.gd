extends Node3D
## A grenade fired by the machine gun's launcher. It flies in an arc and
## explodes the moment it touches anything.
##
## Like the bullet (scripts/bullet.gd) it is not a physics body: each physics
## step it traces a ray across the gap it is about to cross, so it can never
## skip through a thin wall.

const EXPLOSION_SCENE := preload("res://scenes/explosion.tscn")

## How hard the grenade is pulled down, in metres per second squared. Lower
## than the player's gravity so it carries further.
@export var gravity := 12.0
## Seconds until it explodes in mid-air if it hasn't hit anything.
@export var lifetime := 5.0

var velocity := Vector3.ZERO
## Whoever fired the grenade, so it can't hit them on the way out.
var shooter: CollisionObject3D
## False for a copy of another player's shot, which explodes only for show:
## the damage is dealt by the one in the game that fired it.
var deals_damage := true


## Called by the gun right after the grenade is added to the level.
func launch(start: Vector3, direction: Vector3, speed: float) -> void:
	global_position = start
	velocity = direction * speed
	look_at(start + direction)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		_explode(global_position, Vector3.ZERO, null)
		return

	velocity.y -= gravity * delta
	var next_position := global_position + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, next_position)
	if is_instance_valid(shooter):
		query.exclude = [shooter.get_rid()]

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_explode(hit.position, hit.normal, hit.collider)
		return

	global_position = next_position
	# Tumble end over end as it flies.
	rotate_object_local(Vector3.RIGHT, 12.0 * delta)


## Swaps the grenade for an explosion. "normal" points straight out of the
## surface that was hit, and "collider" is the thing that was hit (or null).
func _explode(at: Vector3, normal: Vector3, collider: Object) -> void:
	var explosion := EXPLOSION_SCENE.instantiate()
	explosion.deals_damage = deals_damage
	get_parent().add_child(explosion)
	# Start the blast a little way out from the wall, not inside it.
	explosion.global_position = at + normal * 0.2
	# Walls and floors get a scorch mark; enemies don't (they move).
	if collider != null and not collider.has_method("take_damage"):
		explosion.leave_scorch_mark(at, normal)
	explosion.detonate()
	queue_free()  # removes this node from the game
