extends MeshInstance3D
## A bullet hole: a small flat square with a hole texture, stuck onto
## whatever surface a shot hit.
##
## Godot has a proper Decal node, but it only works in the Forward+ and
## Mobile renderers, not the Compatibility renderer this project uses. A
## textured square placed just in front of the wall is the classic stand-in.
##
## How to use it (see scripts/bullet.gd and scripts/pistol.gd):
##   var hole := BULLET_HOLE_SCENE.instantiate()
##   level.add_child(hole)
##   hole.place(hit.position, hit.normal)

## The most bullet holes allowed at once. When there are more, the oldest
## one is removed, so a long firefight never slows the game down.
const MAX_HOLES := 64

## Every bullet hole currently in the level, oldest first. "static" means
## this one list is shared by all bullet holes instead of each having its own.
static var holes: Array[Node3D] = []


func _ready() -> void:
	holes.append(self)
	if holes.size() > MAX_HOLES:
		holes[0].queue_free()  # _exit_tree below takes it off the list


# Called when this node leaves the game, for any reason (including the whole
# level being reloaded when the player dies).
func _exit_tree() -> void:
	holes.erase(self)


## Sticks the hole onto a surface. "normal" is the direction pointing
## straight out of the surface that was hit.
func place(hit_position: Vector3, normal: Vector3) -> void:
	# Sit a hair in front of the wall. If both were at exactly the same
	# depth they would flicker as the graphics card couldn't pick one.
	global_position = hit_position + normal * 0.01

	# look_at points our -Z axis at a target, and the square's visible face
	# is on +Z, so look INTO the wall to make the face point out of it.
	# look_at also needs an "up" hint that isn't parallel to the direction,
	# so use a different one for floors and ceilings.
	var up_hint := Vector3.UP
	if absf(normal.y) > 0.9:
		up_hint = Vector3.FORWARD
	look_at(global_position - normal, up_hint)

	# Spin it by a random amount so no two holes look identical.
	rotate_object_local(Vector3.BACK, randf() * TAU)
