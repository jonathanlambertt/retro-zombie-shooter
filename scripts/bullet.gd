extends Node3D
## A bullet fired by the machine gun: a small glowing yellow streak.
##
## It is not a physics body. Each physics step it works out where it will be
## next and traces a ray across that gap. Checking the whole gap (instead of
## just the new position) means a fast bullet can never skip through a thin
## wall or a small enemy between two steps.

const BULLET_HOLE_SCENE := preload("res://scenes/bullet_hole.tscn")

var velocity := Vector3.ZERO
var damage := 6
## Whoever fired the bullet, so it can't hit them on the way out.
var shooter: CollisionObject3D
## Seconds until the bullet removes itself if it hasn't hit anything.
var lifetime := 2.0
## False for a copy of another player's bullet, which is only for show: the
## damage is dealt by the bullet in the game that fired it.
var deals_damage := true


## Called by the gun right after the bullet is added to the level.
func launch(start: Vector3, direction: Vector3, speed: float) -> void:
	global_position = start
	velocity = direction * speed
	# Point the long side of the streak along the flight path.
	look_at(start + direction)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()  # removes this node from the game
		return

	var next_position := global_position + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, next_position)
	if is_instance_valid(shooter):
		query.exclude = [shooter.get_rid()]

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		# Things that bleed spray blood from the spot that was hit.
		if hit.collider.has_method("take_damage"):
			if deals_damage:
				if hit.collider.has_method("bleed"):
					hit.collider.bleed(hit.position, hit.normal)
				hit.collider.take_damage(damage)
		else:
			# Walls, floors and crates get a bullet hole. (Enemies don't:
			# they move, and the hole would be left hanging in the air.)
			var hole := BULLET_HOLE_SCENE.instantiate()
			get_parent().add_child(hole)
			hole.place(hit.position, hit.normal)
		queue_free()
		return

	global_position = next_position
