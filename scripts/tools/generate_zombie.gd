extends SceneTree
## The zombie generator. It makes everything the rounded zombie
## (scenes/zombie-rexture-demo.tscn) is drawn with:
##
##   1. The meshes of its body, saved in assets/meshes/ as
##      zombie_body_head.tres, zombie_body_torso.tres and so on. Each part
##      is a stack of rings joined into a skin, like a row of hoops with
##      cloth pulled over them, so it is round where the first zombie's
##      boxes were square.
##   2. Its "looks", saved in assets/textures/ as zombie_look_01.png and up.
##      A look is one picture with every part of the body painted in it: a
##      face, hair, clothes, wounds. Each number rolls its own dice for all of
##      those, so every look is a different zombie.
##
## This is NOT part of the running game. Run it again after changing the
## code below (from the project folder):
##   Godot_v4.7-stable_win64_console.exe --headless --path . --script res://scripts/tools/generate_zombie.gd
## and then, because new or changed pictures have to be imported:
##   Godot_v4.7-stable_win64_console.exe --headless --path . --import
##
## In the game, scripts/zombie_look.gd hands the looks out: every zombie in
## a level gets a different one.
##
## To paint a look by hand instead, save a 128 x 96 picture as the next
## number (zombie_look_25.png if there are 24). The layout it has to follow:
##
##     0               64                      112     128
##   0 +----------------+------------------------+-------+
##     |                |          head          | foot L|
##     |     torso      |                        +-------+ 12
##     |                +------------------------+ foot R|
##     |                |  eyes (two 4 x 3)      +-------+ 24
##  48 +-----+-----+----+-+-----+----------------+-------+
##     | arm | arm | leg  | leg  |                       |
##     |  L  |  R  |  L   |  R   |       (not used)      |
##  96 +-----+-----+------+------+-----------------------+
##     0     24    48     72     96
##
## The head, torso and legs are each "unrolled" like the label off a tin:
## the left and right edges of the piece are the middle of the zombie's
## back, the middle column is its front, and the top row is the top of the
## part. The picture is as you see it standing in front of the zombie, so
## its right side is on the left. The arms and feet are unrolled the other
## way: their edges are the underside (the palm, the sole) and the middle
## column runs along the top, from the shoulder (or heel) in the top row to
## the fingertips (or toes) in the bottom row.

const PixelText := preload("res://scripts/pixel_text.gd")

const MESH_DIR := "res://assets/meshes/"
const LOOK_DIR := "res://assets/textures/"

## How many looks are painted: zombie_look_01.png up to this number. Raise
## it and run the tool again for more. The game counts the files itself, so
## after lowering it, delete the files above the new number by hand.
const LOOK_COUNT := 24

## The size of a look's picture, and where each part's piece of it is.
const LOOK_SIZE := Vector2i(128, 96)
const TORSO := Rect2i(0, 0, 64, 48)
const HEAD := Rect2i(64, 0, 48, 24)
const FOOT_LEFT := Rect2i(112, 0, 16, 12)
const FOOT_RIGHT := Rect2i(112, 12, 16, 12)
## (The zombie's right eye is the one on the left as you face it.)
const EYE_RIGHT := Rect2i(66, 26, 4, 3)
const EYE_LEFT := Rect2i(72, 26, 4, 3)
const ARM_LEFT := Rect2i(0, 48, 24, 48)
const ARM_RIGHT := Rect2i(24, 48, 24, 48)
const LEG_LEFT := Rect2i(48, 48, 24, 48)
const LEG_RIGHT := Rect2i(72, 48, 24, 48)
const SPARE := Rect2i(96, 48, 32, 48)

## The columns of each piece that matter when painting. The head, torso and
## legs start at the back and go round by the zombie's right side.
const TORSO_RIGHT := 16
const TORSO_FRONT := 32
const TORSO_LEFT := 48
const HEAD_FRONT := 24
const LEG_FRONT := 12
## The arms start underneath and go round by the side towards +X: the
## outside of the right arm, the inside (the body's side) of the left arm.
const ARM_TOP := 12
const ARM_RIGHT_INSIDE := 18
const ARM_LEFT_INSIDE := 6


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(MESH_DIR)
	DirAccess.make_dir_recursive_absolute(LOOK_DIR)
	_build_meshes()
	for number in range(1, LOOK_COUNT + 1):
		_save_look(_paint_look(number), number)
	quit()


# --- 1. The body's meshes ------------------------------------------------------
#
# A mesh is a list of corners (vertices) and a list of triangles joining
# them. Every part here is made the same way: a list of rings from one end
# of the part to the other, each with a place along the part, a width and a
# depth. _add_loft() puts a ring of corners at each and joins every ring to
# the next with triangles. A ring with no width at all is a single point,
# which closes the end of the part.
#
# Every corner also says where it is in a look's picture (its "UV"): how far
# round the ring it is picks the column, and the ring's "row" picks the row.
# That is what lets one flat picture wrap right round a leg.
#
# The parts are measured from their joints, because that is where the
# scene's pivot nodes are: the head from the bottom of the neck, the torso
# from the hips, an arm from its shoulder, a leg from its hip. The zombie
# looks along -Z, with +X to its right and +Y up. All sizes are in metres.

## How many corners each ring has. More = rounder (and more to draw).
const HEAD_SIDES := 12
const TORSO_SIDES := 12
const LIMB_SIDES := 8
## How square the torso's rings are. 1 = an oval; lower = flatter in front
## and behind with tighter corners at the sides, like a rib cage.
const TORSO_ROUNDNESS := 0.85
## Corners keep this far (in pixels) inside the edge of their piece of the
## picture, so that rounding never picks up the piece next door.
const EDGE := 0.05

## The rows of the head's two eye-socket rings. The eyes are fitted between
## them (see _add_eye()).
const SOCKET_TOP := 8.5
const SOCKET_BOTTOM := 11.0
## The eye's place in its socket. Across: 0 = at the nose, 1 = at the
## socket's outer corner. Down: 0 = the socket's top, 1 = its bottom.
const EYE_ACROSS := Vector2(0.25, 0.92)
const EYE_DOWN := Vector2(0.14, 0.86)
## How far the eye floats in front of the face, so the two never flicker.
const EYE_LIFT := 0.003

## The mesh being built: its corners, where each one is in the picture (as
## a fraction of the picture's size), and its triangles (three corner
## numbers each).
var corners := PackedVector3Array()
var picture_spots := PackedVector2Array()
var triangles := PackedInt32Array()


func _build_meshes() -> void:
	_add_loft(_head_rings(), HEAD_SIDES, HEAD, true)
	_save_mesh("zombie_body_head")
	_add_loft(_torso_rings(), TORSO_SIDES, TORSO, true, TORSO_ROUNDNESS)
	_save_mesh("zombie_body_torso")
	# The two arms are the same shape, and so are the two legs. Each still
	# gets a mesh of its own, because each has its own piece of the picture.
	_add_loft(_arm_rings(), LIMB_SIDES, ARM_LEFT, false)
	_save_mesh("zombie_body_arm_left")
	_add_loft(_arm_rings(), LIMB_SIDES, ARM_RIGHT, false)
	_save_mesh("zombie_body_arm_right")
	_add_loft(_leg_rings(), LIMB_SIDES, LEG_LEFT, true)
	_add_loft(_foot_rings(), LIMB_SIDES, FOOT_LEFT, false)
	_save_mesh("zombie_body_leg_left")
	_add_loft(_leg_rings(), LIMB_SIDES, LEG_RIGHT, true)
	_add_loft(_foot_rings(), LIMB_SIDES, FOOT_RIGHT, false)
	_save_mesh("zombie_body_leg_right")
	# Side 6 of the head's 12 is the middle of the face, so the right eye's
	# socket is between sides 5 and 6 and the left eye's between 6 and 7.
	_add_eye(5, EYE_RIGHT)
	_add_eye(6, EYE_LEFT)
	_save_mesh("zombie_body_eyes", false)


## One ring of a part.
##   row        - the row of the part's piece of the picture that lies on it
##   at         - where it is along the part: its height for a part that
##                stands up, how far forward (-Z) for one that reaches out
##   half_width - half its size from side to side (X)
##   half_depth - half its size the other way: front to back for a standing
##                part, top to bottom for a reaching one
##   shift      - moves its middle: backwards (+Z) for a standing part, up
##                for a reaching one
##   bumps      - pushes single corners out or in: {6: 1.1} puts corner 6
##                10% further from the middle. This is what gives the face
##                a nose and sockets for its eyes.
func _ring(row: float, at: float, half_width: float, half_depth: float, shift := 0.0, bumps := {}) -> Dictionary:
	return {row = row, at = at, half_width = half_width, half_depth = half_depth, shift = shift, bumps = bumps}


## The head and neck, from the top of the skull down. Measured from the
## bottom of the neck, where the head turns.
func _head_rings() -> Array[Dictionary]:
	var rings: Array[Dictionary] = [
		_ring(0.0, 0.292, 0.0, 0.0, 0.012),
		_ring(2.0, 0.280, 0.062, 0.074, 0.012),
		_ring(4.5, 0.252, 0.090, 0.104, 0.008),
		# The brow sticks out over the eyes.
		_ring(7.0, 0.215, 0.096, 0.108, 0.004, {5: 1.03, 6: 1.02, 7: 1.03}),
		# The eye sockets: two flat panels either side of the nose's bridge.
		_ring(SOCKET_TOP, 0.192, 0.096, 0.106, 0.002, {5: 0.95, 6: 0.93, 7: 0.95}),
		_ring(SOCKET_BOTTOM, 0.160, 0.096, 0.105, 0.0, {5: 0.95, 6: 0.95, 7: 0.95}),
		# The tip of the nose, and the cheekbones.
		_ring(13.0, 0.135, 0.094, 0.103, -0.002, {4: 1.02, 6: 1.08, 8: 1.02}),
		# Hollow cheeks, either side of the mouth.
		_ring(15.0, 0.108, 0.089, 0.099, -0.004, {4: 0.95, 6: 0.97, 8: 0.95}),
		_ring(17.0, 0.080, 0.083, 0.095, -0.008, {4: 0.94, 6: 0.98, 8: 0.94}),
		# The chin. The back of this ring is pulled in to meet the neck.
		_ring(19.5, 0.045, 0.066, 0.082, -0.014, {0: 0.75, 1: 0.85, 11: 0.85}),
		_ring(21.0, 0.028, 0.048, 0.052, 0.008),
		# The neck carries on down inside the collar, so that nothing shows
		# between them when the head tilts.
		_ring(23.0, -0.045, 0.046, 0.048, 0.010),
		_ring(24.0, -0.050, 0.0, 0.0, 0.010),
	]
	return rings


## The torso, from the stump of the neck down to between the legs. Measured
## from the hips, where the body bends.
func _torso_rings() -> Array[Dictionary]:
	var rings: Array[Dictionary] = [
		# The top is a flat patch under the neck, which shows (as a stump)
		# only when the head has been shot off.
		_ring(0.0, 0.570, 0.0, 0.0, 0.006),
		_ring(1.0, 0.569, 0.036, 0.036, 0.006),
		_ring(3.0, 0.557, 0.060, 0.056, 0.006),
		_ring(6.0, 0.528, 0.105, 0.078, 0.008),
		_ring(10.0, 0.497, 0.156, 0.095, 0.008),
		# The shoulders at their widest: the arms' joints are at this height.
		_ring(13.0, 0.458, 0.172, 0.105, 0.004),
		_ring(20.0, 0.370, 0.168, 0.116, -0.004),
		_ring(28.0, 0.260, 0.148, 0.105, 0.0),
		# A thin waist with the belly sunk in.
		_ring(34.0, 0.170, 0.135, 0.092, 0.004, {6: 0.94}),
		_ring(40.0, 0.060, 0.150, 0.100, 0.004),
		# Level with the legs' joints. From here down the torso is a bowl
		# that the rounded tops of the legs turn inside.
		_ring(43.0, 0.0, 0.160, 0.098, 0.004),
		_ring(46.0, -0.062, 0.140, 0.082, 0.004),
		_ring(47.5, -0.096, 0.075, 0.052, 0.004),
		_ring(48.0, -0.105, 0.0, 0.0, 0.004),
	]
	return rings


## An arm held straight out in front, from behind the shoulder to the
## fingertips. Measured from the shoulder joint. It starts as a ball centred
## on the joint, so the shoulder looks the same however the arm is turned.
func _arm_rings() -> Array[Dictionary]:
	var rings: Array[Dictionary] = [
		_ring(0.0, 0.063, 0.0, 0.0),
		_ring(2.5, 0.044, 0.044, 0.044),
		_ring(6.0, 0.0, 0.062, 0.062),
		_ring(10.0, -0.060, 0.053, 0.055),
		_ring(14.5, -0.140, 0.045, 0.048),
		# The elbow. Past it the arm rises a little, so that it is slightly
		# bent: forwards when it hangs, upwards when it reaches.
		_ring(23.0, -0.280, 0.039, 0.041, 0.004),
		_ring(30.0, -0.390, 0.039, 0.037, 0.020),
		_ring(37.0, -0.500, 0.029, 0.024, 0.045),
		# The hand: wide and flat, palm down.
		_ring(40.5, -0.555, 0.042, 0.016, 0.055),
		_ring(46.0, -0.640, 0.037, 0.011, 0.062),
		_ring(48.0, -0.675, 0.0, 0.0, 0.064),
	]
	return rings


## A leg, from the ball at the top of the thigh down to the ankle. Measured
## from the hip joint, 76 cm above the sole of the foot.
func _leg_rings() -> Array[Dictionary]:
	var rings: Array[Dictionary] = [
		_ring(0.0, 0.073, 0.0, 0.0),
		_ring(2.0, 0.053, 0.049, 0.049),
		_ring(5.0, 0.0, 0.072, 0.072),
		_ring(10.0, -0.090, 0.072, 0.080),
		_ring(17.0, -0.210, 0.063, 0.071, -0.008),
		# The knee, a little in front of the hip and the ankle.
		_ring(23.0, -0.320, 0.053, 0.058, -0.016),
		_ring(25.5, -0.360, 0.050, 0.054, -0.012),
		# The calf, which bulges backwards.
		_ring(31.0, -0.460, 0.050, 0.060, 0.004),
		_ring(38.0, -0.590, 0.039, 0.044, 0.006),
		_ring(43.0, -0.690, 0.034, 0.038, 0.006),
		# The end is hidden inside the foot.
		_ring(47.0, -0.738, 0.030, 0.034, 0.006),
		_ring(48.0, -0.744, 0.0, 0.0, 0.006),
	]
	return rings


## A foot, from the heel forwards to the toes. It is part of the leg's mesh,
## so it too is measured from the hip joint: every ring's lowest point is
## 76 cm below it, which is the floor.
func _foot_rings() -> Array[Dictionary]:
	var rings: Array[Dictionary] = [
		_ring(0.0, 0.066, 0.0, 0.0, -0.730),
		_ring(1.5, 0.054, 0.030, 0.027, -0.733),
		_ring(4.0, 0.012, 0.042, 0.040, -0.720),
		_ring(7.0, -0.050, 0.046, 0.030, -0.730),
		_ring(9.5, -0.108, 0.048, 0.022, -0.738),
		_ring(11.0, -0.155, 0.040, 0.014, -0.746),
		_ring(12.0, -0.174, 0.0, 0.0, -0.748),
	]
	return rings


## Where corner number "side" of a ring is. "standing" is true for a part
## whose rings are stacked up and down (head, torso, leg) and false for one
## whose rings are lined up from back to front (arm, foot).
func _ring_point(ring: Dictionary, sides: int, side: int, standing: bool, roundness: float) -> Vector3:
	# How far round the ring this corner is, as an angle. The last corner
	# is in the same place as the first (see _add_loft()), hence the "%".
	var turn := TAU * (side % sides) / sides
	var bump: float = ring.bumps.get(side % sides, 1.0)
	var across: float = _rounded(sin(turn), roundness) * ring.half_width * bump
	var deep: float = _rounded(cos(turn), roundness) * ring.half_depth * bump
	if standing:
		# Round the Y axis, starting at the back (+Z) and going by +X.
		return Vector3(across, ring.at, ring.shift + deep)
	# Round the Z axis, starting underneath (-Y) and going by +X.
	return Vector3(across, ring.shift - deep, ring.at)


## Raises a number between -1 and 1 to a power, keeping whether it was
## negative. With a power below 1 the numbers in the middle move outwards,
## which turns an oval into something nearer a box with round corners.
func _rounded(value: float, power: float) -> float:
	return signf(value) * pow(absf(value), power)


## Adds a part to the mesh being built: a ring of corners for every entry in
## "rings", joined up into a skin. "piece" is the part's piece of the
## picture.
func _add_loft(rings: Array[Dictionary], sides: int, piece: Rect2i, standing: bool, roundness := 1.0) -> void:
	var first := corners.size()
	for ring in rings:
		# One corner more than the ring has sides: the last is in the same
		# place as the first, but at the other edge of the picture. Without
		# it the last strip of triangles would show the whole picture
		# squeezed in backwards.
		for side in sides + 1:
			corners.append(_ring_point(ring, sides, side, standing, roundness))
			var column := lerpf(piece.position.x + EDGE, piece.end.x - EDGE, float(side) / sides)
			var row: float = clampf(piece.position.y + ring.row, piece.position.y + EDGE, piece.end.y - EDGE)
			picture_spots.append(Vector2(column / LOOK_SIZE.x, row / LOOK_SIZE.y))

	# Join each ring to the next. Between two neighbouring corners of one
	# ring (a, b) and the two below them (c, d) there is a four-sided patch,
	# which is drawn as two triangles.
	for ring_number in rings.size() - 1:
		for side in sides:
			var a := first + ring_number * (sides + 1) + side
			var b := a + 1
			var c := a + sides + 1
			var d := c + 1
			_add_triangle(a, b, c)
			_add_triangle(b, d, c)


## Adds one triangle. The order of its corners matters: Godot only draws the
## side from which they run clockwise, and every triangle here is given in
## the order that makes that side the outside.
func _add_triangle(a: int, b: int, c: int) -> void:
	# Where a ring is a single point, two of the corners are in the same
	# place and the triangle has no area. Leave those out.
	if corners[a].is_equal_approx(corners[b]) or corners[b].is_equal_approx(corners[c]) or corners[c].is_equal_approx(corners[a]):
		return
	triangles.append(a)
	triangles.append(b)
	triangles.append(c)


## Adds one glowing eye: a flat panel just in front of an eye socket. The
## socket is the flat patch of the head between the two socket rings and
## between sides "side" and "side" + 1; the eye is a smaller copy of that
## patch, lifted off it. "piece" is the eye's piece of the picture.
func _add_eye(side: int, piece: Rect2i) -> void:
	var top: Dictionary
	var bottom: Dictionary
	for ring in _head_rings():
		if ring.row == SOCKET_TOP:
			top = ring
		elif ring.row == SOCKET_BOTTOM:
			bottom = ring
	# The socket's four corners, as you see them from in front.
	var top_left := _ring_point(top, HEAD_SIDES, side, true, 1.0)
	var top_right := _ring_point(top, HEAD_SIDES, side + 1, true, 1.0)
	var bottom_left := _ring_point(bottom, HEAD_SIDES, side, true, 1.0)
	var bottom_right := _ring_point(bottom, HEAD_SIDES, side + 1, true, 1.0)
	# Which way the socket faces. (The cross product of two edges of a flat
	# patch is a line sticking straight out of it.)
	var facing := (bottom_left - top_left).cross(top_right - top_left).normalized()

	# The nose is at the right-hand edge of the right eye's socket and at
	# the left-hand edge of the left eye's.
	var across := EYE_ACROSS
	if side < HEAD_SIDES / 2.0:
		across = Vector2(1.0 - EYE_ACROSS.y, 1.0 - EYE_ACROSS.x)

	var first := corners.size()
	for down: float in [EYE_DOWN.x, EYE_DOWN.y]:
		for along: float in [across.x, across.y]:
			# lerp() finds the point part of the way from one place to
			# another: first along the top and bottom edges, then between.
			var on_top := top_left.lerp(top_right, along)
			var on_bottom := bottom_left.lerp(bottom_right, along)
			corners.append(on_top.lerp(on_bottom, down) + facing * EYE_LIFT)
	# The eye shows the whole of its piece of the picture.
	for spot: Vector2 in [
		Vector2(piece.position.x + EDGE, piece.position.y + EDGE),
		Vector2(piece.end.x - EDGE, piece.position.y + EDGE),
		Vector2(piece.position.x + EDGE, piece.end.y - EDGE),
		Vector2(piece.end.x - EDGE, piece.end.y - EDGE),
	]:
		picture_spots.append(Vector2(spot.x / LOOK_SIZE.x, spot.y / LOOK_SIZE.y))
	_add_triangle(first, first + 1, first + 2)
	_add_triangle(first + 1, first + 3, first + 2)


## Turns the corners and triangles gathered so far into a mesh, saves it,
## and empties the lists for the next one. "closed" says whether the mesh
## is a shape with an inside (every part but the eyes, which are flat).
func _save_mesh(mesh_name: String, closed := true) -> void:
	# Each corner needs a "normal": the direction the surface faces there,
	# which is what the lighting goes by. A triangle faces along the cross
	# product of two of its edges. Giving every corner the sum of the
	# triangles that meet at it (instead of each triangle its own) is what
	# makes the surface look rounded instead of faceted.
	var totals := {}
	# The same sum also checks the triangles' order: added up over a closed
	# shape whose triangles all face outwards, this comes out negative.
	var inside_out := 0.0
	for i in range(0, triangles.size(), 3):
		var a := corners[triangles[i]]
		var b := corners[triangles[i + 1]]
		var c := corners[triangles[i + 2]]
		var facing := (c - a).cross(b - a)
		inside_out += a.dot(b.cross(c))
		for corner: Vector3 in [a, b, c]:
			totals[_place(corner)] = totals.get(_place(corner), Vector3.ZERO) + facing
	var normals := PackedVector3Array()
	for corner in corners:
		# Corners in the same place share one normal, so that no seam shows
		# where the two edges of the picture meet.
		var total: Vector3 = totals.get(_place(corner), Vector3.UP)
		normals.append(total.normalized())

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = corners
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = picture_spots
	arrays[Mesh.ARRAY_INDEX] = triangles
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var path := MESH_DIR + mesh_name + ".tres"
	var error := ResourceSaver.save(mesh, path)
	if error == OK:
		@warning_ignore("integer_division")
		print("Wrote ", path, " (", corners.size(), " corners, ", triangles.size() / 3, " triangles)")
	else:
		push_error("Could not write %s (error %d)" % [path, error])
	if closed and inside_out > 0.0:
		push_error("%s is inside out" % path)
	corners = PackedVector3Array()
	picture_spots = PackedVector2Array()
	triangles = PackedInt32Array()


## A corner's position as whole numbers of hundredths of a millimetre, so
## that two corners in the same place always count as the same.
func _place(corner: Vector3) -> Vector3i:
	return Vector3i((corner * 100000.0).round())


# --- 2. The looks ------------------------------------------------------------
#
# A look is painted in layers, each over the one before:
#   skin   - every part, with patches of rot
#   face   - sockets for the eyes, a nose, a mouth, ears
#   hair
#   clothes - one of eight outfits (see Role), with its own dice for colours
#             and details: is the coat open, is there a cap, which number
#   wear   - dirt, blood, torn cloth, wounds
#   stumps - the raw ends that only show once a limb is shot off
#   eyes   - what the two glowing eyes show
#
# Everything "random" comes from the dice below, never from Godot's own
# randf(), and each look sets the dice to a number of its own first. So a
# look comes out the same every time the tool runs, and changing how one
# thing is painted never changes the looks that don't have that thing.

## What the zombie was before. Looks take these in turn, so that the looks
## next to each other in number (which are also the zombies next to each
## other in a level) are never dressed alike.
enum Role { SCIENTIST, GUARD, SUBJECT, OFFICE, WORKER, MEDIC, HAZMAT, PATIENT }
## Short names for them, written in the unused corner of each picture.
const ROLE_NAMES: Array[String] = ["SCI", "GRD", "SUB", "OFF", "WRK", "MED", "HAZ", "PAT"]

enum Hair { BALD, SHORT, BALDING, LONG, TUFTS }

const BLOOD := Color(0.50, 0.05, 0.05)
const OLD_BLOOD := Color(0.26, 0.04, 0.04)
const FLESH := Color(0.66, 0.16, 0.13)
const BONE := Color(0.84, 0.80, 0.64)
const ROT := Color(0.26, 0.29, 0.17)
const MAW := Color(0.10, 0.03, 0.03)
const MUD := Color(0.24, 0.19, 0.12)
const STEEL := Color(0.56, 0.58, 0.60)
const BLACK := Color(0.08, 0.08, 0.09)
const WHITE := Color(0.86, 0.86, 0.82)
const GOLD := Color(0.80, 0.62, 0.14)

## Dead skin, in seven shades. Looks take these in turn as well.
const SKINS: Array[Color] = [
	Color(0.46, 0.56, 0.38),  # sickly green (the first zombie's colour)
	Color(0.58, 0.60, 0.55),  # ash grey
	Color(0.50, 0.60, 0.62),  # drowned blue
	Color(0.68, 0.63, 0.42),  # jaundiced yellow
	Color(0.47, 0.37, 0.28),  # leathery brown
	Color(0.58, 0.47, 0.56),  # bruised purple
	Color(0.72, 0.70, 0.62),  # bloodless pale
]
const HAIR_COLORS: Array[Color] = [
	Color(0.10, 0.09, 0.08),  # black
	Color(0.22, 0.14, 0.08),  # dark brown
	Color(0.36, 0.24, 0.13),  # brown
	Color(0.62, 0.52, 0.28),  # dirty blond
	Color(0.50, 0.20, 0.08),  # red
	Color(0.50, 0.50, 0.48),  # grey
	Color(0.80, 0.80, 0.76),  # white
]

## The picture being painted, and the dice it is painted with.
var picture: Image
var dice := RandomNumberGenerator.new()
## What this look is. Its role comes from its number, and so does "cycle":
## how many times the list of roles has been gone through before it, which
## is 0 for the first eight looks, 1 for the next eight and so on. The rest
## comes from the dice.
var role := Role.SCIENTIST
var cycle := 0
var skin := Color.WHITE
var hair := Hair.BALD
var hair_color := Color.BLACK


func _save_look(look: Image, number: int) -> void:
	var path := LOOK_DIR + "zombie_look_%02d.png" % number
	var error := look.save_png(path)
	if error == OK:
		print("Wrote ", path, " (", ROLE_NAMES[role], ")")
	else:
		push_error("Could not write %s (error %d)" % [path, error])


## Paints look number "number" (from 1 up) and returns its picture.
func _paint_look(number: int) -> Image:
	picture = Image.create_empty(LOOK_SIZE.x, LOOK_SIZE.y, false, Image.FORMAT_RGB8)
	picture.fill(Color(0.16, 0.16, 0.18))
	# The dice start from a number that only this look has.
	dice.seed = 1000 + number * 7919

	var turn := number - 1
	role = (turn % Role.size()) as Role
	@warning_ignore("integer_division")
	cycle = turn / Role.size()
	# Three places along the list of skins each time: with seven skins, the
	# three looks that share a role then all get a different one.
	skin = SKINS[(turn * 3) % SKINS.size()]
	hair = _pick([Hair.SHORT, Hair.SHORT, Hair.LONG, Hair.BALDING, Hair.BALD, Hair.TUFTS])
	hair_color = _pick(HAIR_COLORS)
	if role == Role.SUBJECT:
		hair = Hair.BALD  # test subjects have their heads shaved

	_paint_skin()
	_paint_face()
	_paint_hair()
	match role:
		Role.SCIENTIST:
			_dress_scientist()
		Role.GUARD:
			_dress_guard()
		Role.SUBJECT:
			_dress_subject(number)
		Role.OFFICE:
			_dress_office()
		Role.WORKER:
			_dress_worker()
		Role.MEDIC:
			_dress_medic()
		Role.HAZMAT:
			_dress_hazmat()
		Role.PATIENT:
			_dress_patient()
	_paint_wear()
	_paint_stumps()
	_paint_eyes()
	# The look's number and role, in the corner nothing uses. It is only
	# there to tell the pictures apart when looking through the files.
	_write(SPARE, "%02d %s" % [number, ROLE_NAMES[role]], 2, 2, Color(0.45, 0.45, 0.48))
	return picture


# --- Brushes -------------------------------------------------------------------
#
# Each of these paints on one piece of the picture, with x and y counted
# from that piece's top-left corner. A column past either side edge comes
# back in at the other (the two edges meet on the body), so a stain can
# wrap right round an arm. A row off the top or bottom is left out.

## Colours one pixel.
func _dot(piece: Rect2i, x: int, y: int, color: Color) -> void:
	if y < 0 or y >= piece.size.y:
		return
	picture.set_pixel(piece.position.x + posmod(x, piece.size.x), piece.position.y + y, color)


## The colour a pixel has now.
func _peek(piece: Rect2i, x: int, y: int) -> Color:
	var row := clampi(y, 0, piece.size.y - 1)
	return picture.get_pixel(piece.position.x + posmod(x, piece.size.x), piece.position.y + row)


## Returns the colour made brighter (amount > 1) or darker (amount < 1).
func _shade(color: Color, amount: float) -> Color:
	return Color(color.r * amount, color.g * amount, color.b * amount)


## Returns the colour a little brighter or darker, by the roll of the dice.
## Painting with this instead of one flat colour is what gives cloth and
## skin their grain. "grain" is how much it may change.
func _grainy(color: Color, grain: float) -> Color:
	return _shade(color, 1.0 + dice.randf_range(-grain, grain))


## Picks one thing from a list.
func _pick(options: Array) -> Variant:
	return options[dice.randi_range(0, options.size() - 1)]


## Takes the next thing from a list each time the roles go round: the first
## for looks 1 to 8, the second for 9 to 16... Each outfit chooses its main
## colour this way, so that two looks with the same role never match.
func _take(options: Array) -> Variant:
	return options[cycle % options.size()]


## True "odds" of the time: _chance(0.25) is true one time in four.
func _chance(odds: float) -> bool:
	return dice.randf() < odds


## Fills a rectangle.
func _box(piece: Rect2i, x: int, y: int, width: int, height: int, color: Color, grain := 0.05) -> void:
	for row in range(y, y + height):
		for column in range(x, x + width):
			_dot(piece, column, row, _grainy(color, grain))


## Fills whole rows, all the way round the part: rows "from" up to (but not
## including) "to".
func _band(piece: Rect2i, from: int, to: int, color: Color, grain := 0.05) -> void:
	_box(piece, 0, from, piece.size.x, to - from, color, grain)


## Makes what is already painted in a rectangle brighter or darker.
func _tone(piece: Rect2i, x: int, y: int, width: int, height: int, amount: float) -> void:
	for row in range(y, y + height):
		for column in range(x, x + width):
			_dot(piece, column, row, _shade(_peek(piece, column, row), amount))


## Paints a ragged blob: solid in the middle, with more and more gaps
## towards its edge.
func _blob(piece: Rect2i, centre: Vector2, radius: float, color: Color, grain := 0.12) -> void:
	for row in range(floori(centre.y - radius), ceili(centre.y + radius) + 1):
		for column in range(floori(centre.x - radius), ceili(centre.x + radius) + 1):
			if Vector2(column, row).distance_to(centre) <= radius * dice.randf_range(0.55, 1.0):
				_dot(piece, column, row, _grainy(color, grain))


## Soaks a ragged blob of colour into what is already there, so that the
## cloth underneath still shows through. "strength" is how much of the
## colour ends up in each pixel.
func _stain(piece: Rect2i, centre: Vector2, radius: float, color: Color, strength := 0.75) -> void:
	for row in range(floori(centre.y - radius), ceili(centre.y + radius) + 1):
		for column in range(floori(centre.x - radius), ceili(centre.x + radius) + 1):
			if row < 0 or row >= piece.size.y:
				continue
			if Vector2(column, row).distance_to(centre) <= radius * dice.randf_range(0.5, 1.0):
				var soaked := _peek(piece, column, row).lerp(color, strength * dice.randf_range(0.7, 1.0))
				_dot(piece, column, row, soaked)


## Writes in the game's 3 x 5 pixel font, with the top-left corner of the
## first letter at (x, y). Each font pixel is "scale" pixels across.
func _write(piece: Rect2i, text: String, x: int, y: int, color: Color, scale := 1) -> void:
	for character in text:
		if PixelText.GLYPHS.has(character):
			var rows: Array = PixelText.GLYPHS[character]
			for row in rows.size():
				var line: String = rows[row]
				for column in line.length():
					if line[column] == "#":
						_box(piece, x + column * scale, y + row * scale, scale, scale, color, 0.0)
		x += 4 * scale


## Leaves the bottom edge of a piece of clothing in tatters: below row
## "row", each column gets nought to "length" more pixels of the cloth.
func _fray(piece: Rect2i, row: int, color: Color, length := 3) -> void:
	for column in piece.size.x:
		for extra in dice.randi_range(0, length):
			_dot(piece, column, row + extra, _grainy(_shade(color, 0.85), 0.08))


## A wound: a dark soaked patch, wet blood inside it and raw flesh in the
## middle.
func _wound(piece: Rect2i, centre: Vector2, radius: float) -> void:
	_stain(piece, centre, radius + 1.5, OLD_BLOOD, 0.7)
	_blob(piece, centre, radius, BLOOD)
	_blob(piece, centre, radius * 0.55, FLESH)


## A hole torn in the clothes, with the skin showing through and blood
## round its edge.
func _tear(piece: Rect2i, centre: Vector2, radius: float) -> void:
	_stain(piece, centre, radius + 1.0, OLD_BLOOD, 0.6)
	_blob(piece, centre, radius, skin, 0.08)


# --- Skin, face and hair -------------------------------------------------------

func _paint_skin() -> void:
	for piece: Rect2i in [HEAD, TORSO, ARM_LEFT, ARM_RIGHT, LEG_LEFT, LEG_RIGHT, FOOT_LEFT, FOOT_RIGHT]:
		_band(piece, 0, piece.size.y, skin, 0.07)
		# A few patches of rot on every part.
		for patch in dice.randi_range(1, 3):
			var centre := Vector2(dice.randf_range(0.0, piece.size.x), dice.randf_range(2.0, piece.size.y - 2.0))
			_blob(piece, centre, dice.randf_range(1.0, 2.2), skin.lerp(ROT, 0.6))

	# The chest and back, for where the clothes are torn or missing:
	# collarbones, a breastbone, three ribs a side and the line of the spine.
	_tone(TORSO, TORSO_FRONT - 9, 8, 7, 1, 0.8)
	_tone(TORSO, TORSO_FRONT + 2, 8, 7, 1, 0.8)
	_tone(TORSO, TORSO_FRONT, 11, 1, 10, 0.85)
	for row: int in [22, 25, 28]:
		_tone(TORSO, TORSO_FRONT - 10, row, 8, 1, 0.82)
		_tone(TORSO, TORSO_FRONT + 2, row, 8, 1, 0.82)
	_dot(TORSO, TORSO_FRONT, 35, _shade(skin, 0.5))  # navel
	_tone(TORSO, -1, 8, 2, 30, 0.85)

	for arm: Rect2i in [ARM_LEFT, ARM_RIGHT]:
		# The hands are darker, and dark lines part the four fingers: three
		# on the back of the hand and three on the palm.
		_tone(arm, 0, 38, arm.size.x, 10, 0.88)
		for column: int in [9, 12, 15, 21, 0, 3]:
			_tone(arm, column, 42, 1, 6, 0.5)
		# Fingertips worn down to the raw.
		if _chance(0.6):
			_band(arm, 46, 48, _pick([BLOOD, OLD_BLOOD]), 0.2)
	for foot: Rect2i in [FOOT_LEFT, FOOT_RIGHT]:
		# Bare feet: lines between the toes, and a dirty sole.
		for column: int in [5, 7, 9, 11]:
			_tone(foot, column, 10, 1, 2, 0.55)
		_tone(foot, 12, 0, 8, foot.size.y, 0.7)


func _paint_face() -> void:
	# The colour of the hollows of the face: skin gone almost black.
	var hollow := skin.lerp(Color(0.12, 0.05, 0.10), 0.75)
	# The brow's shadow, and under it the two eye sockets. The glowing eyes
	# are separate panels that float just in front of rows 9 and 10.
	_tone(HEAD, 19, 8, 4, 1, 0.7)
	_tone(HEAD, 25, 8, 4, 1, 0.7)
	_box(HEAD, 19, 9, 4, 2, hollow, 0.1)
	_box(HEAD, 25, 9, 4, 2, hollow, 0.1)
	# The nose: a paler ridge with two nostrils at its foot.
	_tone(HEAD, 23, 9, 2, 4, 1.1)
	_dot(HEAD, 22, 13, _shade(skin, 0.45))
	_dot(HEAD, 25, 13, _shade(skin, 0.45))
	# Sunken cheeks.
	_tone(HEAD, 16, 12, 3, 4, 0.86)
	_tone(HEAD, 29, 12, 3, 4, 0.86)
	# The ears, a quarter of the way round on each side.
	for column: int in [11, 35]:
		_tone(HEAD, column, 9, 2, 4, 0.78)
	_dot(HEAD, 12, 10, hollow)
	_dot(HEAD, 35, 10, hollow)
	# The neck is in the chin's shadow.
	_tone(HEAD, 0, 20, HEAD.size.x, 3, 0.8)

	match dice.randi_range(0, 3):
		0:
			# Hanging open, with teeth top and bottom.
			_box(HEAD, 20, 15, 8, 3, MAW, 0.15)
			for column in range(21, 27, 2):
				_dot(HEAD, column, 15, BONE)
				_dot(HEAD, column + 1, 17, BONE)
		1:
			# Lips drawn back off clenched teeth.
			_box(HEAD, 20, 15, 8, 1, _shade(skin, 0.55), 0.1)
			for column in range(20, 28):
				_dot(HEAD, column, 16, BONE if column % 2 == 0 else MAW)
		2:
			# Slack, with one tooth showing.
			_box(HEAD, 21, 16, 6, 2, MAW, 0.15)
			_dot(HEAD, 23, 16, BONE)
		3:
			# A cheek torn away: the mouth carries on round to the zombie's left.
			_box(HEAD, 20, 15, 12, 2, MAW, 0.15)
			for column in range(21, 32, 2):
				_dot(HEAD, column, 16, BONE)
			_stain(HEAD, Vector2(30.0, 15.5), 2.5, BLOOD, 0.6)
	# Blood down the chin.
	for drip in dice.randi_range(0, 3):
		var column := dice.randi_range(20, 27)
		_box(HEAD, column, 17, 1, dice.randi_range(2, 4), BLOOD, 0.15)


func _paint_hair() -> void:
	if hair == Hair.BALD:
		return
	for column in HEAD.size.x:
		# How far round from the nose this column is: 0 = the middle of the
		# face, 1 = the middle of the back of the head.
		var way_round := absf(column + 0.5 - HEAD_FRONT) / HEAD_FRONT
		# The hair covers this column from row "from" down to row "to".
		var from := 0
		var to := 0
		match hair:
			Hair.SHORT, Hair.TUFTS:
				if way_round < 0.36:
					to = 5 + dice.randi_range(0, 1)  # a fringe
				elif way_round < 0.62:
					to = 8 + dice.randi_range(0, 1)  # cut above the ear
				else:
					to = 12 + dice.randi_range(0, 2)  # down the back of the head
				if hair == Hair.TUFTS and _chance(0.4):
					to = 0  # fallen out in clumps
			Hair.BALDING:
				# Nothing on top: a band round the sides and back.
				if way_round >= 0.42:
					from = 5 + dice.randi_range(0, 1)
					to = (9 if way_round < 0.62 else 13) + dice.randi_range(0, 1)
			Hair.LONG:
				if way_round < 0.05:
					to = 3  # the parting
				elif way_round < 0.30:
					to = 5 + dice.randi_range(0, 1)
				elif way_round < 0.40:
					to = 10 + dice.randi_range(0, 3)  # strands by the temples
				elif way_round < 0.62:
					to = 17 + dice.randi_range(0, 2)  # over the ears
				else:
					to = 20 + dice.randi_range(0, 2)  # down the neck
		for row in range(from, to):
			_dot(HEAD, column, row, _shade(hair_color, dice.randf_range(0.8, 1.25)))


# --- Clothes: the pieces the outfits are made from --------------------------------

## A top on the torso, from the collar (row 3) down to row "to". Row 39 is
## where a belt goes; 48 is the bottom of the torso.
func _top(color: Color, to := 39) -> void:
	_band(TORSO, 3, to, color)


## Sleeves on both arms, from the shoulder down to row "to": 15 is a short
## sleeve, 23 the elbow, 37 the wrist. A sleeve that is "torn" ends in
## tatters instead of a cuff.
func _sleeves(color: Color, to: int, torn := false) -> void:
	for arm: Rect2i in [ARM_LEFT, ARM_RIGHT]:
		_sleeve(arm, color, to, torn)


func _sleeve(arm: Rect2i, color: Color, to: int, torn := false) -> void:
	_band(arm, 0, to, color)
	if torn:
		_fray(arm, to, color)
	else:
		_tone(arm, 0, to - 1, arm.size.x, 1, 0.75)


## Trousers: the bottom of the torso, and both legs down to row "to" (44 is
## the ankle, 20 above the knee).
func _trousers(color: Color, to := 44) -> void:
	_band(TORSO, 41, 48, color)
	_tone(TORSO, TORSO_FRONT, 41, 1, 7, 0.8)  # the fly
	for leg: Rect2i in [LEG_LEFT, LEG_RIGHT]:
		_band(leg, 0, to, color)
		_tone(leg, 0, to - 1, leg.size.x, 1, 0.75)  # the hem
		_tone(leg, LEG_FRONT, 6, 1, to - 8, 1.12)  # a crease down the front


## A belt with a buckle.
func _belt(color: Color, buckle: Color) -> void:
	_band(TORSO, 39, 41, color, 0.04)
	_box(TORSO, TORSO_FRONT - 1, 39, 2, 2, buckle, 0.03)


## Shoes on both feet.
func _shoes(color: Color, sole: Color) -> void:
	for foot: Rect2i in [FOOT_LEFT, FOOT_RIGHT]:
		_shoe(foot, color, sole)


func _shoe(foot: Rect2i, color: Color, sole: Color) -> void:
	_band(foot, 0, foot.size.y, color, 0.06)
	# The sole is the quarter of the piece either side of its edges.
	_box(foot, 12, 0, 8, foot.size.y, sole, 0.08)
	_tone(foot, 4, 9, 9, 3, 0.8)  # the toe cap


## Boots: shoes, with the leg covered from row "top" down as well.
func _boots(color: Color, sole: Color, top := 37) -> void:
	_shoes(color, sole)
	for leg: Rect2i in [LEG_LEFT, LEG_RIGHT]:
		_band(leg, top, leg.size.y, color, 0.06)
		_tone(leg, 0, top, leg.size.x, 1, 0.7)


## Gloves on both hands, with the lines between the fingers put back.
func _gloves(color: Color) -> void:
	for arm: Rect2i in [ARM_LEFT, ARM_RIGHT]:
		_band(arm, 37, 48, color, 0.06)
		for column: int in [9, 12, 15, 21, 0, 3]:
			_tone(arm, column, 42, 1, 6, 0.55)


## Something worn on top of the head, covering it down to row 5: a cap, a
## hard hat. "edge" is the colour of the row below, which is a hat's brim.
func _hat(color: Color, edge: Color) -> void:
	_band(HEAD, 0, 6, color, 0.04)
	_band(HEAD, 6, 7, edge, 0.04)


## Spectacles: a rim above and below each eye socket, joined over the nose,
## with a side piece back to each ear.
func _glasses() -> void:
	var frame: Color = _pick([BLACK, STEEL, GOLD, Color(0.35, 0.20, 0.10)])
	_box(HEAD, 18, 8, 12, 1, frame, 0.0)
	_box(HEAD, 18, 11, 5, 1, frame, 0.0)
	_box(HEAD, 25, 11, 5, 1, frame, 0.0)
	_box(HEAD, 18, 9, 1, 2, frame, 0.0)
	_box(HEAD, 29, 9, 1, 2, frame, 0.0)
	_box(HEAD, 13, 9, 5, 1, frame, 0.0)
	_box(HEAD, 30, 9, 5, 1, frame, 0.0)


# --- Clothes: the eight outfits -----------------------------------------------------

## A lab coat down to the knees over a shirt, a tie and trousers.
func _dress_scientist() -> void:
	var coat: Color = _take([Color(0.82, 0.81, 0.74), Color(0.86, 0.87, 0.86), Color(0.72, 0.70, 0.58)])
	var shirt: Color = _pick([Color(0.62, 0.70, 0.80), Color(0.80, 0.62, 0.62), Color(0.55, 0.57, 0.60), Color(0.62, 0.76, 0.66)])
	var tie: Color = _pick([Color(0.12, 0.16, 0.30), Color(0.45, 0.08, 0.08), BLACK, Color(0.12, 0.30, 0.16)])
	var trousers: Color = _pick([Color(0.20, 0.21, 0.24), Color(0.30, 0.22, 0.15), Color(0.15, 0.18, 0.28), Color(0.52, 0.47, 0.33)])
	# Either buttoned up below the chest, or hanging open all the way down.
	var open := _chance(0.4)

	_trousers(trousers)
	_belt(BLACK, STEEL)
	_shoes(_pick([BLACK, Color(0.25, 0.15, 0.08)]), BLACK)
	# What shows where the coat is open: the shirt, with the tie down it.
	_box(TORSO, TORSO_FRONT - 6, 3, 12, 36, shirt)
	_box(TORSO, TORSO_FRONT - 1, 4, 2, 21, tie)
	_dot(TORSO, TORSO_FRONT - 2, 4, tie)
	_dot(TORSO, TORSO_FRONT + 1, 4, tie)

	# The coat goes on a pixel at a time, leaving the opening unpainted.
	for row in range(4, 48):
		# Half the width of the opening on this row: a V that closes at row
		# 20, or one that narrows to a gap and stays open.
		var gap := (20 - row) * 0.33
		if open:
			gap = maxf(gap, 2.5)
		if row >= 38:
			# Below the waist the two sides always fall apart.
			gap = maxf(gap, 2.0 + (row - 38) * 0.9)
		for column in TORSO.size.x:
			var from_middle := absf(column + 0.5 - TORSO_FRONT)
			if from_middle >= gap:
				_dot(TORSO, column, row, _grainy(coat, 0.05))
			elif from_middle >= gap - 1.0:
				_dot(TORSO, column, row, _shade(coat, 0.7))  # the lapel's edge
	if not open:
		_tone(TORSO, TORSO_FRONT, 20, 1, 18, 0.8)  # where the coat closes
		for row: int in [24, 30, 36]:
			_dot(TORSO, TORSO_FRONT + 1, row, _shade(coat, 0.4))  # buttons
	# The coat's skirt hangs to the knees, round the outside and the back of
	# each thigh. A leg's columns start at the back and go round by the
	# zombie's right, so the left leg's outside is the second half of them
	# and the right leg's is the first half.
	for row in 22:
		for column in range(15, 28):
			_dot(LEG_LEFT, column, row, _grainy(coat, 0.05))
		for column in range(-3, 10):
			_dot(LEG_RIGHT, column, row, _grainy(coat, 0.05))
	for column in range(15, 28):
		for extra in dice.randi_range(0, 2):
			_dot(LEG_LEFT, column, 22 + extra, _shade(coat, 0.85))
	for column in range(-3, 10):
		for extra in dice.randi_range(0, 2):
			_dot(LEG_RIGHT, column, 22 + extra, _shade(coat, 0.85))
	_sleeves(coat, 37)

	# A breast pocket with pens in it, two hip pockets, a seam and a
	# half-belt at the back.
	_tone(TORSO, 38, 18, 6, 1, 0.75)
	_dot(TORSO, 39, 17, Color(0.70, 0.10, 0.10))
	_dot(TORSO, 41, 17, Color(0.10, 0.20, 0.60))
	_tone(TORSO, 19, 34, 7, 1, 0.78)
	_tone(TORSO, 38, 34, 7, 1, 0.78)
	_tone(TORSO, 0, 6, 1, 42, 0.85)
	_tone(TORSO, -5, 32, 10, 2, 0.85)
	# An identity card clipped to the other side of the chest.
	if _chance(0.7):
		_box(TORSO, 22, 19, 3, 4, WHITE, 0.03)
		_dot(TORSO, 23, 20, skin)
	if _chance(0.6):
		_glasses()


## A security guard: uniform, boots, and usually a vest and a cap.
func _dress_guard() -> void:
	var uniform: Color = _take([Color(0.14, 0.17, 0.28), Color(0.26, 0.30, 0.36), Color(0.12, 0.12, 0.14), Color(0.30, 0.26, 0.18)])
	var vest := _shade(uniform, 0.5)

	_trousers(_shade(uniform, 0.8))
	_top(uniform)
	_belt(BLACK, STEEL)
	_boots(BLACK, BLACK)
	_sleeves(uniform, 15 if _chance(0.5) else 37)
	# A patch on the outside of each shoulder.
	_box(ARM_RIGHT, 5, 11, 3, 3, GOLD, 0.05)
	_box(ARM_LEFT, 17, 11, 3, 3, GOLD, 0.05)
	# A badge over the heart and a name strip on the other side.
	_box(TORSO, 39, 14, 2, 3, GOLD, 0.05)
	_box(TORSO, 22, 15, 5, 1, WHITE, 0.03)

	if _chance(0.7):
		# A stab vest: a panel in front and one behind, with straps over the
		# shoulders, pouches along the bottom and GUARD across the back.
		_box(TORSO, TORSO_FRONT - 11, 9, 22, 28, vest)
		_box(TORSO, -11, 9, 22, 28, vest)
		for column: int in [TORSO_FRONT - 9, TORSO_FRONT + 6, -9, 6]:
			_box(TORSO, column, 4, 3, 5, vest)
		for column: int in [TORSO_FRONT - 10, TORSO_FRONT - 3, TORSO_FRONT + 4]:
			_box(TORSO, column, 29, 6, 6, _shade(vest, 1.6))
			_tone(TORSO, column, 30, 6, 1, 0.6)
		_write(TORSO, "GUARD", -10, 14, Color(0.75, 0.76, 0.72))
		# A radio on the left shoulder strap, with its light on.
		_box(TORSO, TORSO_FRONT + 6, 9, 3, 4, BLACK, 0.03)
		_dot(TORSO, TORSO_FRONT + 7, 9, Color(0.2, 0.9, 0.3))
	if _chance(0.5):
		# A peaked cap with a badge on the front.
		_hat(uniform, _shade(uniform, 0.7))
		_box(HEAD, HEAD_FRONT - 7, 6, 14, 1, BLACK, 0.03)
		_box(HEAD, HEAD_FRONT - 1, 3, 2, 2, GOLD, 0.05)
	if _chance(0.25):
		_gloves(BLACK)


## A test subject: a jumpsuit with a number on it, a shaved head with a
## bar code on the back, and bare feet.
func _dress_subject(number: int) -> void:
	var suit: Color = _take([Color(0.86, 0.40, 0.08), Color(0.80, 0.80, 0.76), Color(0.50, 0.51, 0.53), Color(0.78, 0.68, 0.20)])
	var ink := BLACK
	# Every subject's number is different.
	var label := "%02d" % ((number * 37 + 11) % 100)

	_top(suit, 48)
	_tone(TORSO, 0, 39, TORSO.size.x, 2, 0.82)  # the waistband
	_tone(TORSO, TORSO_FRONT, 4, 1, 37, 0.55)  # the zip
	for leg: Rect2i in [LEG_LEFT, LEG_RIGHT]:
		_band(leg, 0, 44, suit)
		_tone(leg, 0, 43, leg.size.x, 1, 0.75)
	# One sleeve is sometimes torn off at the shoulder.
	_sleeve(ARM_RIGHT, suit, 37)
	if _chance(0.4):
		_sleeve(ARM_LEFT, suit, dice.randi_range(11, 18), true)
	else:
		_sleeve(ARM_LEFT, suit, 37)
	# The number: small over the heart, and large across the back.
	_write(TORSO, label, 36, 13, ink)
	_write(TORSO, label, -7, 15, ink, 2)
	# A steel cuff on each wrist.
	if _chance(0.5):
		for arm: Rect2i in [ARM_LEFT, ARM_RIGHT]:
			_band(arm, 35, 37, STEEL, 0.04)
	if _chance(0.3):
		_shoes(WHITE, _shade(WHITE, 0.7))  # paper slippers
	# The bar code, at the back of the skull.
	for column: int in [-4, -2, -1, 1, 3]:
		_box(HEAD, column, 12, 1, 3, ink, 0.0)


## An office worker: shirt, tie, trousers and shoes.
func _dress_office() -> void:
	var shirt: Color = _take([Color(0.84, 0.84, 0.82), Color(0.62, 0.72, 0.84), Color(0.84, 0.66, 0.68), Color(0.72, 0.68, 0.84), Color(0.80, 0.78, 0.56)])
	var trousers: Color = _pick([Color(0.32, 0.33, 0.36), Color(0.30, 0.22, 0.15), Color(0.10, 0.10, 0.12), Color(0.55, 0.50, 0.36)])
	var leather: Color = _pick([BLACK, Color(0.28, 0.16, 0.08)])

	_trousers(trousers)
	_top(shirt)
	_belt(leather, GOLD)
	_shoes(leather, BLACK)
	# Sleeves rolled to the elbow, or down to a buttoned cuff.
	_sleeves(shirt, 23 if _chance(0.5) else 37)
	# The collar: two points either side of the neck.
	_tone(TORSO, TORSO_FRONT - 5, 3, 4, 2, 1.12)
	_tone(TORSO, TORSO_FRONT + 1, 3, 4, 2, 1.12)
	_tone(TORSO, TORSO_FRONT, 5, 1, 34, 0.85)  # the buttons' edge
	if _chance(0.7):
		# A tie, pulled loose, with a stripe every third row.
		var tie: Color = _pick([Color(0.55, 0.08, 0.08), Color(0.12, 0.16, 0.34), Color(0.12, 0.34, 0.18), Color(0.70, 0.55, 0.10)])
		_box(TORSO, TORSO_FRONT - 1, 5, 2, 23, tie)
		_box(TORSO, TORSO_FRONT - 2, 5, 4, 2, tie)
		for row in range(8, 28, 3):
			_tone(TORSO, TORSO_FRONT - 1, row, 2, 1, 1.5)
	# A breast pocket, and a name badge on the other side.
	_tone(TORSO, 38, 17, 5, 1, 0.8)
	_box(TORSO, 22, 16, 5, 3, WHITE, 0.03)
	_box(TORSO, 23, 17, 3, 1, BLACK, 0.0)
	if _chance(0.4):
		# The shirt has come untucked on one side.
		var side := TORSO_RIGHT if _chance(0.5) else TORSO_LEFT
		_box(TORSO, side - 8, 39, 16, 3, shirt)
		_fray(TORSO, 42, shirt, 2)
	if _chance(0.3):
		# A sleeveless pullover over the shirt, cut in a V at the neck.
		var wool: Color = _pick([Color(0.42, 0.12, 0.14), Color(0.16, 0.32, 0.22), Color(0.36, 0.36, 0.40), Color(0.20, 0.24, 0.42)])
		for row in range(6, 39):
			for column in TORSO.size.x:
				if absf(column + 0.5 - TORSO_FRONT) >= (16 - row) * 0.5:
					_dot(TORSO, column, row, _grainy(wool, 0.07))
		_tone(TORSO, 0, 37, TORSO.size.x, 2, 0.8)
	# A wristwatch.
	_band(ARM_LEFT, 35, 36, BLACK, 0.03)
	_dot(ARM_LEFT, ARM_TOP, 35, GOLD)
	if _chance(0.35):
		_glasses()


## A maintenance worker: overalls and boots, and usually a bright vest with
## reflecting stripes and a hard hat.
func _dress_worker() -> void:
	var overalls: Color = _take([Color(0.24, 0.32, 0.45), Color(0.36, 0.27, 0.18), Color(0.20, 0.32, 0.22), Color(0.38, 0.39, 0.40)])
	var bright: Color = _pick([Color(0.95, 0.48, 0.08), Color(0.78, 0.86, 0.16)])
	var tape := Color(0.80, 0.82, 0.80)
	var leather := Color(0.42, 0.30, 0.16)

	_top(overalls, 48)
	for leg: Rect2i in [LEG_LEFT, LEG_RIGHT]:
		_band(leg, 0, 44, overalls)
		# A pad sewn on over each knee.
		_box(leg, LEG_FRONT - 3, 20, 6, 6, _shade(overalls, 0.65))
	_sleeves(overalls, 23 if _chance(0.4) else 37)
	_tone(TORSO, TORSO_FRONT, 4, 1, 36, 0.6)  # the zip
	# A vest shows at the neck. On the chest, a pocket with a flap on one
	# side and a name patch on the other.
	_box(TORSO, TORSO_FRONT - 3, 3, 6, 2, _pick([WHITE, Color(0.55, 0.12, 0.10), Color(0.30, 0.30, 0.32)]))
	_tone(TORSO, 36, 15, 7, 1, 0.65)
	_tone(TORSO, 36, 16, 7, 5, 0.88)
	_box(TORSO, 22, 15, 6, 2, WHITE, 0.03)

	if _chance(0.75):
		# The vest: everything from the collarbones to the waist except a
		# gap down the front, with two bands of tape round it and one over
		# each shoulder.
		_box(TORSO, TORSO_FRONT + 2, 5, 60, 29, bright)
		_box(TORSO, TORSO_FRONT + 2, 17, 60, 2, tape, 0.03)
		_box(TORSO, TORSO_FRONT + 2, 28, 60, 2, tape, 0.03)
		for column: int in [TORSO_FRONT - 9, TORSO_FRONT + 7, -9, 7]:
			_box(TORSO, column, 5, 2, 12, tape, 0.03)
	# A tool belt with a pouch on each hip.
	_band(TORSO, 39, 41, leather, 0.06)
	_box(TORSO, TORSO_RIGHT - 3, 41, 6, 4, _shade(leather, 0.8))
	_box(TORSO, TORSO_LEFT - 3, 41, 6, 4, _shade(leather, 0.8))
	_boots(leather, BLACK)
	if _chance(0.4):
		_gloves(Color(0.60, 0.52, 0.36))
	if _chance(0.6):
		# A hard hat, with a ridge over the top from front to back.
		var hat: Color = _pick([Color(0.92, 0.78, 0.10), Color(0.88, 0.88, 0.85), Color(0.92, 0.45, 0.08)])
		_hat(hat, _shade(hat, 0.6))
		_tone(HEAD, HEAD_FRONT - 1, 0, 2, 6, 1.15)
		_tone(HEAD, -1, 0, 2, 6, 1.15)


## A doctor or nurse in scrubs, often with a surgical mask.
func _dress_medic() -> void:
	var scrubs: Color = _take([Color(0.24, 0.55, 0.52), Color(0.30, 0.45, 0.72), Color(0.72, 0.42, 0.56), Color(0.34, 0.60, 0.40)])

	_trousers(_shade(scrubs, 0.9))
	# The top hangs loose over the trousers.
	_top(scrubs, 44)
	_tone(TORSO, 0, 43, TORSO.size.x, 1, 0.75)
	_sleeves(scrubs, 15)
	# A V at the neck, showing the skin under it.
	for row in range(3, 9):
		var half := (9 - row) * 0.6
		for column in TORSO.size.x:
			var from_middle := absf(column + 0.5 - TORSO_FRONT)
			if from_middle < half:
				_dot(TORSO, column, row, _grainy(skin, 0.07))
			elif from_middle < half + 1.0:
				_dot(TORSO, column, row, _shade(scrubs, 0.7))
	# A breast pocket with a pen, and the two ends of the trousers' cord.
	_tone(TORSO, 37, 17, 6, 1, 0.75)
	_tone(TORSO, 37, 18, 1, 5, 0.85)
	_tone(TORSO, 42, 18, 1, 5, 0.85)
	_dot(TORSO, 39, 16, Color(0.10, 0.20, 0.60))
	_dot(TORSO, TORSO_FRONT - 1, 45, WHITE)
	_dot(TORSO, TORSO_FRONT + 1, 46, WHITE)
	_shoes(_pick([WHITE, Color(0.30, 0.55, 0.40), Color(0.25, 0.30, 0.50)]), _shade(WHITE, 0.6))

	if _chance(0.3):
		# A stethoscope round the neck.
		_box(TORSO, TORSO_FRONT - 5, 4, 1, 10, BLACK, 0.0)
		_box(TORSO, TORSO_FRONT + 4, 4, 1, 10, BLACK, 0.0)
		_box(TORSO, TORSO_FRONT - 4, 14, 8, 1, BLACK, 0.0)
		_box(TORSO, TORSO_FRONT, 15, 1, 4, BLACK, 0.0)
		_box(TORSO, TORSO_FRONT - 1, 19, 2, 2, STEEL, 0.03)
	if _chance(0.5):
		_gloves(Color(0.62, 0.78, 0.86))  # thin rubber gloves
	if _chance(0.35):
		_hat(scrubs, _shade(scrubs, 0.8))  # a theatre cap
	if _chance(0.55):
		# A mask over the nose and mouth, with a loop to each ear.
		var mask := Color(0.66, 0.80, 0.86)
		_box(HEAD, 17, 12, 14, 7, mask)
		_tone(HEAD, 17, 14, 14, 1, 0.86)
		_tone(HEAD, 17, 16, 14, 1, 0.86)
		_box(HEAD, 12, 13, 5, 1, _shade(mask, 0.9), 0.03)
		_box(HEAD, 31, 13, 5, 1, _shade(mask, 0.9), 0.03)
		if _chance(0.6):
			_stain(HEAD, Vector2(dice.randf_range(21.0, 27.0), 16.0), 2.5, BLOOD, 0.8)


## Someone in a sealed suit with a hood, which only shows the face.
func _dress_hazmat() -> void:
	var suit: Color = _take([Color(0.86, 0.76, 0.14), Color(0.84, 0.85, 0.82), Color(0.88, 0.45, 0.10), Color(0.34, 0.50, 0.66)])
	var rubber: Color = _pick([BLACK, Color(0.10, 0.25, 0.45), Color(0.12, 0.34, 0.20)])
	var tape := Color(0.60, 0.62, 0.62)

	_top(suit, 48)
	_tone(TORSO, TORSO_FRONT - 1, 3, 3, 40, 0.85)  # the flap over the zip
	for leg: Rect2i in [LEG_LEFT, LEG_RIGHT]:
		_band(leg, 0, 44, suit)
	_sleeves(suit, 37)
	_gloves(rubber)
	_boots(rubber, BLACK, 40)
	# The cuffs are taped shut.
	for arm: Rect2i in [ARM_LEFT, ARM_RIGHT]:
		_band(arm, 35, 37, tape, 0.04)
	for leg: Rect2i in [LEG_LEFT, LEG_RIGHT]:
		_band(leg, 38, 40, tape, 0.04)

	# The hood: the whole head and neck except a window over the face,
	# with a dark rim.
	for row in HEAD.size.y - 1:
		for column in HEAD.size.x:
			var inside := column >= 17 and column < 31 and row >= 6 and row < 19
			var rim := column >= 16 and column < 32 and row >= 5 and row < 20
			if not rim:
				_dot(HEAD, column, row, _grainy(suit, 0.05))
			elif not inside:
				_dot(HEAD, column, row, BLACK)
	if _chance(0.5):
		# A breathing mask inside it, with a filter on each side.
		_box(HEAD, 20, 14, 8, 5, STEEL)
		_box(HEAD, 18, 15, 3, 3, BLACK, 0.05)
		_box(HEAD, 27, 15, 3, 3, BLACK, 0.05)

	# A warning sign over the heart: three dots round one, on black.
	_box(TORSO, 37, 13, 7, 7, BLACK, 0.03)
	for spot: Vector2i in [Vector2i(40, 16), Vector2i(40, 14), Vector2i(38, 17), Vector2i(42, 17)]:
		_dot(TORSO, spot.x, spot.y, suit)
	if _chance(0.5):
		# An air bottle on the back, with a strap over each shoulder.
		_box(TORSO, -4, 10, 8, 22, STEEL)
		_tone(TORSO, -4, 10, 1, 22, 0.7)
		_tone(TORSO, 3, 10, 1, 22, 0.7)
		_box(TORSO, -1, 8, 2, 2, BLACK, 0.03)
		for column: int in [TORSO_FRONT - 10, TORSO_FRONT + 8, -10, 8]:
			_box(TORSO, column, 4, 2, 9, BLACK, 0.05)


## A patient in a hospital gown, tied at the back, with bare legs.
func _dress_patient() -> void:
	var gown: Color = _take([Color(0.66, 0.80, 0.74), Color(0.76, 0.74, 0.84), Color(0.84, 0.83, 0.74), Color(0.70, 0.78, 0.86)])

	_top(gown, 48)
	# A pattern of small dots.
	for row in range(5, 48, 3):
		for column in range(row % 2 * 2, TORSO.size.x, 4):
			_dot(TORSO, column, row, _shade(gown, 0.78))
	# The gown is open down the back, and held shut by two ties.
	_box(TORSO, -2, 4, 4, 44, skin, 0.07)
	_box(TORSO, -2, 8, 4, 1, _shade(gown, 0.8))
	_box(TORSO, -2, 22, 4, 1, _shade(gown, 0.8))
	# It comes down to the middle of the thighs.
	for leg: Rect2i in [LEG_LEFT, LEG_RIGHT]:
		_band(leg, 0, 16, gown)
		_fray(leg, 16, gown, 3)
	_sleeves(gown, 13)

	# A name band on one wrist, and a drip's dressing inside the other elbow.
	_band(ARM_RIGHT, 35, 36, WHITE, 0.03)
	_box(ARM_LEFT, ARM_LEFT_INSIDE - 1, 21, 3, 2, WHITE, 0.03)
	_dot(ARM_LEFT, ARM_LEFT_INSIDE, 22, BLOOD)
	if _chance(0.4):
		# Socks. Sometimes only the one.
		var sock := _shade(WHITE, 0.9)
		_band(FOOT_RIGHT, 0, 12, sock, 0.06)
		_band(LEG_RIGHT, 38, 48, sock, 0.06)
		if _chance(0.5):
			_band(FOOT_LEFT, 0, 12, sock, 0.06)
			_band(LEG_LEFT, 38, 48, sock, 0.06)
	if _chance(0.4):
		# A bandage round the head, bled through.
		_band(HEAD, 3, 6, WHITE, 0.06)
		_stain(HEAD, Vector2(dice.randf_range(0.0, 48.0), 4.5), 2.2, BLOOD, 0.8)


# --- Wear, stumps and eyes -------------------------------------------------------

## What being a zombie has done to it: dirt, blood and wounds, in different
## places and amounts on every look.
func _paint_wear() -> void:
	# Dirt, thicker the nearer the ground: the bottom of the torso, and the
	# legs from the knee down.
	for row in range(40, 48):
		_tone(TORSO, 0, row, TORSO.size.x, 1, 1.0 - (row - 40) * 0.03)
	for leg: Rect2i in [LEG_LEFT, LEG_RIGHT]:
		for row in range(26, 48):
			_tone(leg, 0, row, leg.size.x, 1, 1.0 - (row - 26) * 0.012)
		for splash in dice.randi_range(0, 3):
			_stain(leg, Vector2(dice.randf_range(0.0, 24.0), dice.randf_range(30.0, 44.0)), dice.randf_range(1.0, 2.5), MUD, 0.7)

	# Blood down the front, most of it its own.
	for splash in dice.randi_range(1, 4):
		var centre := Vector2(TORSO_FRONT + dice.randf_range(-13.0, 13.0), dice.randf_range(6.0, 38.0))
		_stain(TORSO, centre, dice.randf_range(1.5, 4.0), _pick([BLOOD, OLD_BLOOD]))
	if _chance(0.5):
		# What it last ate, down its chin and chest.
		_stain(TORSO, Vector2(TORSO_FRONT + dice.randf_range(-2.0, 2.0), 7.0), 3.0, BLOOD)
		_box(TORSO, TORSO_FRONT + dice.randi_range(-2, 1), 8, 1, dice.randi_range(4, 10), BLOOD, 0.15)

	# One big wound, somewhere different each time.
	match dice.randi_range(0, 4):
		0:
			# The belly torn open, with two ribs showing.
			var centre := Vector2(TORSO_FRONT + dice.randf_range(-8.0, 8.0), dice.randf_range(24.0, 32.0))
			_stain(TORSO, centre, 5.5, OLD_BLOOD, 0.8)
			_blob(TORSO, centre, 3.4, _shade(FLESH, 0.6))
			for rib in 3:
				_box(TORSO, roundi(centre.x) - 2 + rib % 2, roundi(centre.y) - 2 + rib * 2, 4, 1, _shade(BONE, 0.75), 0.15)
		1:
			# Three claw marks across the back.
			var left := dice.randi_range(-10, 0)
			for claw in 3:
				for step in 9:
					@warning_ignore("integer_division")
					var column := left + claw * 4 + step / 2
					_dot(TORSO, column, 12 + step, FLESH if step > 2 and step < 6 else BLOOD)
		2:
			# A bite out of one shoulder.
			var column := TORSO_FRONT + (9 if _chance(0.5) else -9) + dice.randi_range(-2, 2)
			_wound(TORSO, Vector2(column, 7.0), 2.5)
		3:
			# A gash in one side.
			var column := (TORSO_RIGHT if _chance(0.5) else TORSO_LEFT) + dice.randi_range(-3, 3)
			_wound(TORSO, Vector2(column, dice.randf_range(20.0, 32.0)), 2.8)
		4:
			pass  # this one has kept its insides in

	# Bitten arms, skinned knees and a split scalp.
	for arm: Rect2i in [ARM_LEFT, ARM_RIGHT]:
		if _chance(0.4):
			_wound(arm, Vector2(ARM_TOP + dice.randf_range(-4.0, 4.0), dice.randf_range(18.0, 34.0)), 1.8)
	for leg: Rect2i in [LEG_LEFT, LEG_RIGHT]:
		if _chance(0.4):
			_tear(leg, Vector2(LEG_FRONT + dice.randf_range(-1.0, 1.0), 23.5), 2.4)
			_dot(leg, LEG_FRONT, 23, BLOOD)
	if _chance(0.35):
		var centre := Vector2(dice.randf_range(0.0, 48.0), dice.randf_range(1.5, 5.0))
		_wound(HEAD, centre, 1.6)
		_dot(HEAD, roundi(centre.x), roundi(centre.y), BONE)


## The raw ends that are hidden inside a joint until a limb is shot off:
## the cut end of the limb itself, and the socket it leaves in the torso.
## They are painted last so that no clothes or dirt cover them.
func _paint_stumps() -> void:
	# The bottom of the neck, and the patch on the torso that it stands on.
	_stump_rows(HEAD, 23, 24)
	_stump_rows(TORSO, 0, 1)
	# The top of the ball each leg ends in. Only the top: the leg swings,
	# and the rest of the ball comes out from under the torso as it does.
	for leg: Rect2i in [LEG_LEFT, LEG_RIGHT]:
		_stump_rows(leg, 0, 2)
		_band(leg, 2, 3, OLD_BLOOD, 0.15)
	# The inside of each shoulder, where the arm's ball sits in the torso.
	# These are centred on the line the arm turns about (column 6 or 18,
	# row 6), so they stay inside the torso however the arm is turned.
	_stump_patch(ARM_LEFT, ARM_LEFT_INSIDE - 2, 4, 4, 4)
	_stump_patch(ARM_RIGHT, ARM_RIGHT_INSIDE - 2, 4, 4, 4)
	# The sockets the arms leave in the torso's sides, at the height of the
	# shoulders.
	_stump_patch(TORSO, TORSO_RIGHT - 2, 11, 4, 5)
	_stump_patch(TORSO, TORSO_LEFT - 2, 11, 4, 5)
	# (The legs leave no such socket. A leg's ball turns inside the bottom
	# of the torso without touching it, and every bit of the torso's
	# underside comes into view as the leg swings.)


## Rows of raw meat all the way round a part, with bits of bone in it.
func _stump_rows(piece: Rect2i, from: int, to: int) -> void:
	for row in range(from, to):
		for column in piece.size.x:
			var color: Color = _pick([FLESH, FLESH, FLESH, BLOOD, BONE])
			_dot(piece, column, row, _grainy(color, 0.12))


## A patch of raw meat with dark corners and a piece of bone in the middle.
func _stump_patch(piece: Rect2i, x: int, y: int, width: int, height: int) -> void:
	_box(piece, x, y, width, height, FLESH, 0.15)
	for corner: Vector2i in [Vector2i(0, 0), Vector2i(width - 1, 0), Vector2i(0, height - 1), Vector2i(width - 1, height - 1)]:
		_dot(piece, x + corner.x, y + corner.y, _grainy(OLD_BLOOD, 0.15))
	@warning_ignore("integer_division")
	_box(piece, x + width / 2 - 1, y + height / 2 - 1, 2, 2, BONE, 0.05)


## The two glowing eyes. One zombie in six has lost one.
func _paint_eyes() -> void:
	var glow: Color = _pick([Color(0.95, 0.16, 0.08), Color(1.0, 0.30, 0.08), Color(0.92, 0.08, 0.10)])
	var lost := dice.randi_range(0, 1) if _chance(0.16) else -1
	var eyes: Array[Rect2i] = [EYE_RIGHT, EYE_LEFT]
	for index in eyes.size():
		var eye := eyes[index]
		if index == lost:
			# An empty socket, and what ran out of it.
			_box(eye, 0, 0, 4, 3, Color(0.04, 0.01, 0.01), 0.0)
			var column := 20 if index == 0 else 26
			_stain(HEAD, Vector2(column + 0.5, 11.0), 1.8, BLOOD, 0.8)
			_box(HEAD, column, 11, 1, dice.randi_range(3, 5), BLOOD, 0.15)
			continue
		# Darker at the two ends and brightest in the middle.
		_box(eye, 0, 0, 4, 3, _shade(glow, 0.75), 0.0)
		_box(eye, 1, 0, 2, 3, glow, 0.0)
		_box(eye, 1, 1, 2, 1, glow.lerp(Color(1.0, 0.9, 0.7), 0.45), 0.0)
