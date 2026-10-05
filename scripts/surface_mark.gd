extends MeshInstance3D
## A mark stuck onto a wall, floor or crate: a small flat square with a
## see-through texture. Bullet holes (scenes/bullet_hole.tscn) and blood
## stains (scenes/blood_stain.tscn) both use this script.
##
## Godot has a proper Decal node, but it only works in the Forward+ and
## Mobile renderers, not the Compatibility renderer this project uses. A
## textured square placed just in front of the wall is the classic stand-in.
##
## A flat square doesn't bend around corners, so a mark that would stick out
## past the edge of its surface is simply not shown: see _fits_on_surface().
##
## How to use it (see scripts/bullet.gd and scripts/pistol.gd):
##   var hole := BULLET_HOLE_SCENE.instantiate()
##   level.add_child(hole)
##   hole.place(hit.position, hit.normal)

## Which sort of mark this is. Each sort is counted separately, so a room
## full of blood doesn't use up the allowance of bullet holes.
@export var kind := "bullet_hole"
## The most marks of this kind allowed at once. When there are more, the
## oldest one is removed, so a long firefight never slows the game down.
@export var max_marks := 64

## Every mark currently in the level, oldest first, in one list per kind.
## "static" means this is shared by all marks instead of each having its own.
static var marks := {}
## One copy of the material for each colour asked for by tint(), so that a
## hundred red stains can all share the same one.
static var tinted_materials := {}


func _ready() -> void:
	if not marks.has(kind):
		marks[kind] = []
	var list: Array = marks[kind]
	list.append(self)
	if list.size() > max_marks:
		list[0].queue_free()  # _exit_tree below takes it off the list


# Called when this node leaves the game, for any reason (including the whole
# level being reloaded when the player dies).
func _exit_tree() -> void:
	marks[kind].erase(self)


## Sticks the mark onto a surface. "normal" is the direction pointing
## straight out of the surface that was hit, and "size" makes the mark
## bigger (2.0 = twice as wide) or smaller.
##
## Returns false, and removes the mark, if it would hang over an edge.
func place(hit_position: Vector3, normal: Vector3, size := 1.0) -> bool:
	# Sit a hair in front of the wall. If both were at exactly the same
	# depth they would flicker as the graphics card couldn't pick one. The
	# small random extra stops overlapping marks flickering against each other.
	global_position = hit_position + normal * randf_range(0.01, 0.015)

	# look_at points our -Z axis at a target, and the square's visible face
	# is on +Z, so look INTO the wall to make the face point out of it.
	# look_at also needs an "up" hint that isn't parallel to the direction,
	# so use a different one for floors and ceilings.
	var up_hint := Vector3.UP
	if absf(normal.y) > 0.9:
		up_hint = Vector3.FORWARD
	look_at(global_position - normal, up_hint)

	# Spin it by a random amount so no two marks look identical.
	rotate_object_local(Vector3.BACK, randf() * TAU)
	scale = Vector3.ONE * size

	if not _fits_on_surface(normal):
		queue_free()  # removes this node from the game
		return false
	return true


## Recolours the mark. Blood stains use this: the texture is white, and is
## multiplied by the colour of whatever is bleeding.
func tint(color: Color) -> void:
	if not tinted_materials.has(color):
		var material: StandardMaterial3D = mesh.surface_get_material(0).duplicate()
		material.albedo_color = color
		tinted_materials[color] = material
	material_override = tinted_materials[color]


## Checks that all four corners of the square have something to sit on.
##
## Each corner must either have the same flat surface right underneath it,
## or be buried inside something else (where a wall meets the floor, say:
## the buried part can't be seen, so the mark just looks tucked into the
## corner). A corner hanging in thin air means the mark is poking out past
## an edge, such as the side of a doorway or the rim of a crate.
func _fits_on_surface(normal: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var half_size := (mesh as QuadMesh).size / 2.0
	# A point just above the middle of the mark, to look sideways from.
	var above_centre := global_position + normal * 0.03

	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		# Multiplying by global_transform turns a position on the square
		# into a position in the level, allowing for its spin and its size.
		var corner_position := global_transform * Vector3(corner.x * half_size.x, corner.y * half_size.y, 0.0)

		# Is there surface under this corner? Trace a very short ray
		# straight down into it and see whether it hits the same flat face.
		var down := PhysicsRayQueryParameters3D.create(
				corner_position + normal * 0.05, corner_position - normal * 0.05)
		var surface := space.intersect_ray(down)
		if not surface.is_empty() and surface.normal.dot(normal) > 0.95:
			continue

		# If not, is something in the way between the middle and this
		# corner? Then the corner is hidden inside it, which is fine.
		var sideways := PhysicsRayQueryParameters3D.create(
				above_centre, corner_position + normal * 0.03)
		if space.intersect_ray(sideways).is_empty():
			return false
	return true
