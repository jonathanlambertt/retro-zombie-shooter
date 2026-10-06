extends SceneTree
## Placeholder texture generator.
##
## This is NOT part of the running game. It is a small tool that paints four
## 64x64 textures with code and saves them as PNG files in assets/textures/.
## The PNGs are committed to git, so you only need to run this again if you
## change the code below.
##
## How to run it (from the project folder):
##   Godot_v4.7-stable_win64_console.exe --headless --path . --script res://scripts/tools/generate_textures.gd
##
## To use your own pixel art instead, just overwrite the PNG files (keep the
## same file names) or point the materials in assets/materials/ at new files.

const SIZE := 64
const OUTPUT_DIR := "res://assets/textures/"

# A fixed seed means the "random" textures come out identical every run.
var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 1996
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	_save(_make_concrete(), "concrete")
	_save(_make_metal(), "metal")
	_save(_make_tile(), "tile")
	_save(_make_crate(), "crate")
	_save(_make_bullet_hole(), "bullet_hole")
	# Wallpaper, carpet and ceiling tiles. New textures go at the end of this list
	# so the random numbers used by the ones above stay the same.
	_save(_make_wallpaper(), "wallpaper")
	_save(_make_carpet(), "carpet")
	_save(_make_ceiling_tile(), "ceiling_tile")
	# The facility test level's textures.
	_save(_make_lab_wall(), "lab_wall")
	_save(_make_hazard(), "hazard")
	_save(_make_blood_stain(), "blood_stain")
	# Brick, lava, and the slime in the Half-Life level.
	_save(_make_brick(), "brick")
	_save(_make_liquid(Color(0.35, 0.05, 0.02), Color(1.0, 0.75, 0.15)), "lava")
	_save(_make_liquid(Color(0.08, 0.25, 0.04), Color(0.6, 1.0, 0.25)), "slime")
	# The explosive pylon (scenes/explosive_pylon.tscn).
	_save(_make_pylon(), "pylon")
	# The player's armour and undersuit (scenes/player_model.tscn).
	_save(_make_armor(), "armor")
	_save(_make_suit(), "suit")
	# The textured zombie's body parts (scenes/zombie_textured.tscn).
	_save(_make_zombie_head(), "zombie_head")
	_save(_make_zombie_torso(), "zombie_torso")
	_save(_make_zombie_arm(), "zombie_arm")
	_save(_make_zombie_leg(), "zombie_leg")
	# The parts of the machine gun (scenes/machine_gun.tscn).
	_save(_make_machine_gun_body(), "machine_gun_body")
	_save(_make_machine_gun_barrel(), "machine_gun_barrel")
	_save(_make_machine_gun_launcher(), "machine_gun_launcher")
	_save(_make_machine_gun_magazine(), "machine_gun_magazine")
	_save(_make_machine_gun_grip(), "machine_gun_grip")
	# The special forces player model (scenes/player_model_soldier.tscn).
	_save(_make_soldier_camo(), "soldier_camo")
	_save(_make_soldier_webbing(), "soldier_webbing")
	_save(_make_soldier_head(), "soldier_head")
	_save(_make_soldier_helmet(), "soldier_helmet")
	_save(_make_soldier_vest(), "soldier_vest")
	_save(_make_soldier_backpack(), "soldier_backpack")
	# The pistol, the shotgun and the rocket launcher, the two stocks that
	# only the player model's guns have, and the things the guns fire.
	_save(_make_pistol_slide(), "pistol_slide")
	_save(_make_pistol_grip(), "pistol_grip")
	_save(_make_shotgun_receiver(), "shotgun_receiver")
	_save(_make_shotgun_barrel(), "shotgun_barrel")
	_save(_make_shotgun_tube(), "shotgun_tube")
	_save(_make_shotgun_pump(), "shotgun_pump")
	_save(_make_shotgun_grip(), "shotgun_grip")
	_save(_make_shotgun_rib(), "shotgun_rib")
	_save(_make_shotgun_stock(), "shotgun_stock")
	_save(_make_machine_gun_stock(), "machine_gun_stock")
	_save(_make_rocket_launcher_tube(), "rocket_launcher_tube")
	_save(_make_rocket_launcher_muzzle(), "rocket_launcher_muzzle")
	_save(_make_rocket_launcher_sight(), "rocket_launcher_sight")
	_save(_make_rocket(), "rocket")
	_save(_make_grenade(), "grenade")
	_save(_make_bullet(), "bullet")
	quit()


func _save(image: Image, texture_name: String) -> void:
	var path := OUTPUT_DIR + texture_name + ".png"
	var error := image.save_png(path)
	if error == OK:
		print("Wrote ", path)
	else:
		push_error("Could not write %s (error %d)" % [path, error])


# --- Helpers -----------------------------------------------------------------

func _new_image() -> Image:
	return Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)


## Returns the colour made brighter (amount > 1) or darker (amount < 1).
func _shade(color: Color, amount: float) -> Color:
	return Color(color.r * amount, color.g * amount, color.b * amount)


## A small grid of random values, used for big soft blotches of dirt.
func _make_blotch_grid(cells: int) -> PackedFloat32Array:
	var grid := PackedFloat32Array()
	for i in cells * cells:
		grid.append(rng.randf())
	return grid


## Reads the blotch grid at pixel (x, y), blending smoothly between cells.
## It wraps around at the edges so the texture tiles without visible seams.
func _blotch(grid: PackedFloat32Array, cells: int, x: int, y: int) -> float:
	var fx := float(x) / SIZE * cells
	var fy := float(y) / SIZE * cells
	var x0 := int(fx) % cells
	var y0 := int(fy) % cells
	var x1 := (x0 + 1) % cells
	var y1 := (y0 + 1) % cells
	var tx := fx - floorf(fx)
	var ty := fy - floorf(fy)
	var top := lerpf(grid[y0 * cells + x0], grid[y0 * cells + x1], tx)
	var bottom := lerpf(grid[y1 * cells + x0], grid[y1 * cells + x1], tx)
	return lerpf(top, bottom, ty)


# --- Textures ----------------------------------------------------------------

## Grey-brown concrete: soft blotches, fine grain, and a poured-slab seam.
func _make_concrete() -> Image:
	var image := _new_image()
	var base := Color(0.42, 0.40, 0.36)
	var blotches := _make_blotch_grid(4)
	for y in SIZE:
		for x in SIZE:
			var brightness := 0.8 + 0.3 * _blotch(blotches, 4, x, y)
			brightness += rng.randf_range(-0.07, 0.07)
			if y == 0 or x == 0:
				brightness *= 0.75  # seam between slabs
			image.set_pixel(x, y, _shade(base, brightness))
	return image


## Blue-grey metal plates with seams, rivets, streaks and patches of rust.
func _make_metal() -> Image:
	var image := _new_image()
	var base := Color(0.33, 0.36, 0.38)
	var rust := Color(0.34, 0.20, 0.11)
	var rust_map := _make_blotch_grid(4)
	# One random value per column gives vertical "brushed" streaks.
	var streaks := PackedFloat32Array()
	for x in SIZE:
		streaks.append(rng.randf_range(-0.06, 0.06))

	for y in SIZE:
		for x in SIZE:
			# Position inside the current 32x32 plate.
			var plate_x := x % 32
			var plate_y := y % 32
			var color := base
			var rust_amount := _blotch(rust_map, 4, x, y)
			if rust_amount > 0.62:
				color = base.lerp(rust, (rust_amount - 0.62) * 2.5)

			var brightness := 0.95 + streaks[x] + rng.randf_range(-0.03, 0.03)
			if plate_x == 0 or plate_y == 0:
				brightness *= 0.5  # dark seam
			elif plate_x == 1 or plate_y == 1:
				brightness *= 1.25  # bright bevel next to the seam
			elif (plate_x == 4 or plate_x == 28) and (plate_y == 4 or plate_y == 28):
				brightness *= 1.5  # rivet
			image.set_pixel(x, y, _shade(color, brightness))
	return image


## Dirty green-grey floor tiles, 16 pixels each, with dark grout.
func _make_tile() -> Image:
	var image := _new_image()
	var base := Color(0.45, 0.47, 0.42)
	var grout := Color(0.16, 0.15, 0.13)
	var dirt := _make_blotch_grid(4)
	# Each of the 4x4 tiles gets its own slightly different brightness.
	var tile_tints := PackedFloat32Array()
	for i in 16:
		tile_tints.append(rng.randf_range(0.85, 1.05))

	for y in SIZE:
		for x in SIZE:
			if x % 16 == 0 or y % 16 == 0:
				image.set_pixel(x, y, _shade(grout, rng.randf_range(0.8, 1.1)))
				continue
			@warning_ignore("integer_division")
			var tile_index := (y / 16) * 4 + (x / 16)
			var brightness := tile_tints[tile_index]
			brightness *= 0.7 + 0.4 * _blotch(dirt, 4, x, y)
			brightness += rng.randf_range(-0.04, 0.04)
			image.set_pixel(x, y, _shade(base, brightness))
	return image


## Wooden crate: vertical planks, a darker frame, and a diagonal brace.
func _make_crate() -> Image:
	var image := _new_image()
	var wood := Color(0.45, 0.31, 0.17)
	var frame_width := 6
	# Wood grain runs up the planks, so use one random value per column.
	var grain := PackedFloat32Array()
	for x in SIZE:
		grain.append(rng.randf_range(-0.08, 0.08))

	for y in SIZE:
		for x in SIZE:
			var brightness := 1.0 + grain[x] + rng.randf_range(-0.04, 0.04)
			var edge_distance := mini(mini(x, y), mini(SIZE - 1 - x, SIZE - 1 - y))
			var on_frame := edge_distance < frame_width
			var on_brace := absi(x - y) < 4

			if on_frame or on_brace:
				brightness *= 0.72
				# Dark outline where the frame meets the planks.
				if edge_distance == 0 or edge_distance == frame_width - 1 or absi(x - y) == 3:
					brightness *= 0.6
			elif x % 13 == 0:
				brightness *= 0.5  # gap between planks
			image.set_pixel(x, y, _shade(wood, brightness))

	# A nail in each corner of the frame.
	for corner in [Vector2i(2, 2), Vector2i(SIZE - 3, 2), Vector2i(2, SIZE - 3), Vector2i(SIZE - 3, SIZE - 3)]:
		image.set_pixel(corner.x, corner.y, Color(0.6, 0.58, 0.52))
	return image


## A tiny 8x8 bullet hole: black centre, dark scorched ring, a few stray
## chips, and see-through everywhere else. (RGBA8 = it has transparency.)
func _make_bullet_hole() -> Image:
	var hole_size := 8
	var image := Image.create_empty(hole_size, hole_size, false, Image.FORMAT_RGBA8)
	var centre := Vector2(3.5, 3.5)
	for y in hole_size:
		for x in hole_size:
			var distance := Vector2(x, y).distance_to(centre)
			var color := Color(0, 0, 0, 0)  # fully transparent
			if distance < 1.2:
				color = Color(0.02, 0.02, 0.02)
			elif distance < 2.6:
				color = _shade(Color(0.13, 0.12, 0.1), rng.randf_range(0.7, 1.2))
			elif distance < 3.6 and rng.randf() < 0.35:
				color = Color(0.1, 0.09, 0.08)
			image.set_pixel(x, y, color)
	return image


## Wallpaper: stale mustard yellow with thin vertical lines, rows
## of small arrowheads between them, and faint damp stains.
func _make_wallpaper() -> Image:
	var image := _new_image()
	var base := Color(0.80, 0.71, 0.36)
	var stains := _make_blotch_grid(4)
	for y in SIZE:
		for x in SIZE:
			# Position inside the current 16-pixel-wide strip of wallpaper.
			var strip_x := x % 16
			var brightness := 0.92 + 0.12 * _blotch(stains, 4, x, y)
			brightness += rng.randf_range(-0.03, 0.03)
			if strip_x == 0:
				brightness *= 0.86  # line between strips
			elif y % 8 < 3 and absi(strip_x - 8) == y % 8:
				brightness *= 0.9  # arrowhead: one pixel, then two spreading out
			image.set_pixel(x, y, _shade(base, brightness))
	return image


## Office carpet: damp brownish-beige with a rough, speckled pile.
func _make_carpet() -> Image:
	var image := _new_image()
	var base := Color(0.50, 0.43, 0.24)
	var damp := _make_blotch_grid(4)
	for y in SIZE:
		for x in SIZE:
			var brightness := 0.8 + 0.3 * _blotch(damp, 4, x, y)
			brightness += rng.randf_range(-0.12, 0.12)
			image.set_pixel(x, y, _shade(base, brightness))
	return image


## Office ceiling tiles: off-white squares, 32 pixels each, with a dark grid
## between them and the little pockmarks those tiles always have.
func _make_ceiling_tile() -> Image:
	var image := _new_image()
	var base := Color(0.80, 0.78, 0.68)
	for y in SIZE:
		for x in SIZE:
			var brightness := 1.0 + rng.randf_range(-0.03, 0.03)
			if x % 32 == 0 or y % 32 == 0:
				brightness *= 0.6  # metal grid holding the tiles up
			elif rng.randf() < 0.08:
				brightness *= 0.8  # pockmark
			image.set_pixel(x, y, _shade(base, brightness))
	return image


## Research-lab wall: pale grey-green panels, a blue stripe at waist height
## and a dark skirting strip along the bottom.
##
## On a wall the texture is 2 m tall and its bottom row sits on the floor, so
## row 63 is at floor level and row 32 is 1 m up.
func _make_lab_wall() -> Image:
	var image := _new_image()
	var panel := Color(0.62, 0.66, 0.62)
	var stripe := Color(0.22, 0.38, 0.55)
	var grime := _make_blotch_grid(4)
	for y in SIZE:
		for x in SIZE:
			var color := panel
			var brightness := 0.9 + 0.15 * _blotch(grime, 4, x, y)
			brightness += rng.randf_range(-0.03, 0.03)
			if y >= 28 and y < 36:
				color = stripe
			elif y >= 58:
				brightness *= 0.45  # skirting strip
			elif x % 32 == 0 or y == 0:
				brightness *= 0.7  # seam between panels
			image.set_pixel(x, y, _shade(color, brightness))
	return image


## Yellow and black diagonal warning stripes, scuffed with a little dirt.
func _make_hazard() -> Image:
	var image := _new_image()
	var yellow := Color(0.85, 0.68, 0.10)
	var black := Color(0.10, 0.10, 0.09)
	for y in SIZE:
		for x in SIZE:
			# x + y is the same all the way along a diagonal line, so this
			# switches colour every 8 pixels measured across the diagonals.
			var color := yellow if (x + y) % 16 < 8 else black
			image.set_pixel(x, y, _shade(color, rng.randf_range(0.8, 1.05)))
	return image


## A 16x16 splat for blood stains: a ragged blob with a few stray droplets,
## see-through everywhere else. It is white so that the game can tint it the
## colour of whatever bled (see scripts/surface_mark.gd).
func _make_blood_stain() -> Image:
	var stain_size := 16
	var image := Image.create_empty(stain_size, stain_size, false, Image.FORMAT_RGBA8)
	var centre := Vector2(7.5, 7.5)
	# Cut the blob into 8 slices like a pizza and give each a different
	# length, which makes the outline ragged instead of a neat circle.
	var reach := PackedFloat32Array()
	for i in 8:
		reach.append(rng.randf_range(2.5, 6.5))

	for y in stain_size:
		for x in stain_size:
			var offset := Vector2(x, y) - centre
			# angle() runs from -PI to PI; turn that into a slice number 0-7.
			var slice := int((offset.angle() + PI) / TAU * 8.0) % 8
			var color := Color(0, 0, 0, 0)  # fully transparent
			if offset.length() < reach[slice]:
				color = _shade(Color.WHITE, rng.randf_range(0.7, 1.0))
			elif offset.length() < 7.5 and rng.randf() < 0.06:
				color = Color(0.8, 0.8, 0.8)  # stray droplet
			image.set_pixel(x, y, color)
	return image


## Dark brown stone blocks, 32 pixels wide and 16 tall, laid like bricks:
## every other row is shifted along by half a block.
func _make_brick() -> Image:
	var image := _new_image()
	var stone := Color(0.36, 0.26, 0.18)
	var mortar := Color(0.11, 0.09, 0.08)
	var grime := _make_blotch_grid(4)
	# Each of the 2 x 4 blocks gets its own slightly different brightness.
	var block_tints := PackedFloat32Array()
	for i in 8:
		block_tints.append(rng.randf_range(0.75, 1.1))

	for y in SIZE:
		for x in SIZE:
			@warning_ignore("integer_division")
			var row := y / 16
			# Odd rows are slid 16 pixels to the right.
			var shifted_x := (x + (row % 2) * 16) % SIZE
			if shifted_x % 32 == 0 or y % 16 == 0:
				image.set_pixel(x, y, _shade(mortar, rng.randf_range(0.8, 1.1)))
				continue
			@warning_ignore("integer_division")
			var block := row * 2 + shifted_x / 32
			var brightness := block_tints[block]
			brightness *= 0.75 + 0.35 * _blotch(grime, 4, x, y)
			brightness += rng.randf_range(-0.05, 0.05)
			# A darker line under the top edge makes each block look chiselled.
			if y % 16 == 15 or shifted_x % 32 == 31:
				brightness *= 0.7
			image.set_pixel(x, y, _shade(stone, brightness))
	return image


## A glowing liquid such as lava or toxic slime: a dark crust with bright
## veins running through it. "crust" and "glow" are its two colours.
func _make_liquid(crust: Color, glow: Color) -> Image:
	var image := _new_image()
	var flow := _make_blotch_grid(8)
	for y in SIZE:
		for x in SIZE:
			var heat := _blotch(flow, 8, x, y)
			# Push the middle values apart so there are clear bright veins
			# and dark patches rather than one even orange.
			heat = clampf((heat - 0.3) * 2.2, 0.0, 1.0)
			heat += rng.randf_range(-0.06, 0.06)
			image.set_pixel(x, y, crust.lerp(glow, clampf(heat, 0.0, 1.0)))
	return image


## The body of the explosive pylon, from its top (row 0) to its bottom
## (row 63): scuffed red paint between steel rims, a white warning diamond,
## and a band of hazard stripes around the middle.
##
## The pylon is round, and the surface shader's box mapping mirrors the
## picture left to right around its middle (between columns 31 and 32) as
## it wraps around. So anything that must read properly, like the diamond,
## is drawn symmetrical about that line.
func _make_pylon() -> Image:
	var image := _new_image()
	var paint := Color(0.62, 0.13, 0.08)
	var steel := Color(0.22, 0.23, 0.24)
	var yellow := Color(0.85, 0.68, 0.10)
	var black := Color(0.10, 0.10, 0.09)
	var white := Color(0.85, 0.84, 0.78)
	var grime := _make_blotch_grid(4)

	for y in SIZE:
		for x in SIZE:
			var color := paint
			# How far this pixel is from the mirror line, and from the
			# middle of the diamond (rows 6 to 22).
			var across := absf(x - 31.5)
			var diamond := across + absf(y - 14.0)

			if y <= 2 or y >= 60:
				color = steel  # the rims at the top and bottom
			elif y == 26 or y == 27 or y == 40 or y == 41:
				color = _shade(steel, 0.6)  # dark edges of the stripe band
			elif y >= 28 and y <= 39:
				color = yellow if (x + y) % 12 < 6 else black
			elif diamond <= 6.5:
				color = white
				# An exclamation mark: a bar with a dot under it.
				if across < 1.0 and ((y >= 10 and y <= 15) or y == 17 or y == 18):
					color = black
			elif diamond <= 8.0:
				color = black  # the diamond's outline
			elif (y == 45 or y == 56) and int(across) % 8 == 4:
				color = Color(0.85, 0.3, 0.2)  # rivet heads catching the light

			var brightness := 0.85 + 0.3 * _blotch(grime, 4, x, y)
			brightness += rng.randf_range(-0.06, 0.06)
			# Soot creeps up from the bottom, darkest just above the rim.
			if y > 44 and y < 60:
				brightness *= 1.0 - (y - 44) * 0.025
			# Here and there the paint is scratched off down to bare metal.
			if color == paint and rng.randf() < 0.04:
				color = steel.lerp(paint, 0.3)
			image.set_pixel(x, y, _shade(color, brightness))
	return image


## Scuffed armour plating for the player model, painted a pale grey so the
## material can tint it any colour (see armor_color in
## scripts/player_model.gd). Two rows of plates with offset seams, a bolt in
## each corner, and paint chipped away along the edges.
func _make_armor() -> Image:
	var image := _new_image()
	var paint := Color(0.80, 0.78, 0.74)
	var bare := Color(0.42, 0.42, 0.44)
	var grime := _make_blotch_grid(4)

	for y in SIZE:
		for x in SIZE:
			# The top row of plates is 36 pixels tall, the bottom one 28. The
			# bottom row's seams are shifted along, like bricks.
			var row_top := 0 if y < 36 else 36
			var shift := 0 if y < 36 else 16
			var plate_x := (x + shift) % 32
			var plate_y := y - row_top
			var plate_height := 36 if y < 36 else 28
			# How close this pixel is to the nearest edge of its plate.
			var edge := mini(mini(plate_x, 31 - plate_x), mini(plate_y, plate_height - 1 - plate_y))

			var color := paint
			# Paint wears off near the edges first.
			if edge <= 3 and rng.randf() < 0.18 - edge * 0.04:
				color = bare
			var brightness := 0.8 + 0.25 * _blotch(grime, 4, x, y)
			brightness += rng.randf_range(-0.04, 0.04)
			if edge == 0:
				brightness *= 0.35  # the dark seam between plates
			elif edge == 1 and (plate_x == 1 or plate_y == 1):
				brightness *= 1.2  # light catching the top and left bevel
			elif edge == 1:
				brightness *= 0.75  # shadow on the bottom and right bevel
			elif (plate_x == 4 or plate_x == 27) and (plate_y == 4 or plate_y == plate_height - 5):
				color = bare
				brightness *= 1.3  # bolt head
			image.set_pixel(x, y, _shade(color, brightness))
	return image


## The player's dark undersuit: thick rubberised fabric with ribs across it
## every 4 pixels and a stitched seam down the middle.
func _make_suit() -> Image:
	var image := _new_image()
	var fabric := Color(0.30, 0.31, 0.30)
	var wear := _make_blotch_grid(4)
	for y in SIZE:
		for x in SIZE:
			var brightness := 0.85 + 0.2 * _blotch(wear, 4, x, y)
			brightness += rng.randf_range(-0.05, 0.05)
			if y % 4 == 0:
				brightness *= 0.7  # the groove between two ribs
			elif y % 4 == 1:
				brightness *= 1.1  # the top of a rib catching the light
			if x == 31 and y % 3 != 0:
				brightness *= 1.35  # stitches
			image.set_pixel(x, y, _shade(fabric, brightness))
	return image


# --- The textured zombie -----------------------------------------------------
#
# Every other texture here is one picture that the surface shader repeats
# over a whole object. A body part needs a different picture on each side (a
# face on the front of the head, hair on the back), so these four are
# "atlases": six small pictures in one file, three across and two down.
#
# That is the layout of the UVs Godot builds into every BoxMesh, and the
# materials turn on the shader's uv_from_mesh so it uses them. Each side of
# the box is stretched to fill its cell, whatever shape the side is. The
# zombie looks along -Z, so the box's -Z side is its front and +X its right:
#
#   +--------+--------+--------+
#   |  back  | right  | front  |
#   +--------+--------+--------+
#   |  left  |  top   | bottom |
#   +--------+--------+--------+
#
# Every picture is drawn as you would see it from outside the box. On the
# top and bottom, the top edge of the picture is the zombie's back.

const FACE_BACK := Vector2i(0, 0)
const FACE_RIGHT := Vector2i(1, 0)
const FACE_FRONT := Vector2i(2, 0)
const FACE_LEFT := Vector2i(0, 1)
const FACE_TOP := Vector2i(1, 1)
const FACE_BOTTOM := Vector2i(2, 1)

const ZOMBIE_SKIN := Color(0.46, 0.56, 0.38)
const ZOMBIE_ROT := Color(0.27, 0.30, 0.18)
const ZOMBIE_BLOOD := Color(0.42, 0.05, 0.05)
const ZOMBIE_FLESH := Color(0.66, 0.16, 0.13)
const ZOMBIE_BONE := Color(0.82, 0.78, 0.62)
const ZOMBIE_HAIR := Color(0.13, 0.11, 0.09)
const ZOMBIE_COAT := Color(0.66, 0.65, 0.56)
const ZOMBIE_SHIRT := Color(0.40, 0.45, 0.50)
const ZOMBIE_TIE := Color(0.12, 0.16, 0.30)
const ZOMBIE_TROUSERS := Color(0.20, 0.22, 0.30)
const ZOMBIE_SHOE := Color(0.12, 0.10, 0.09)


## An empty atlas whose six cells are each cell_width x cell_height pixels.
func _new_atlas(cell_width: int, cell_height: int) -> Image:
	return Image.create_empty(cell_width * 3, cell_height * 2, false, Image.FORMAT_RGB8)


## Copies one side's picture into its cell of the atlas (one of the FACE_
## constants above). The picture may be smaller than the cell: it is
## stretched to fit with no smoothing. That is how a narrow side, such as
## the side of the torso, is drawn with pixels the same size as the front's
## even though both get a cell of the same size.
func _paint_face(atlas: Image, cell: Vector2i, face: Image) -> void:
	@warning_ignore("integer_division")
	var cell_size := Vector2i(atlas.get_width() / 3, atlas.get_height() / 2)
	face.resize(cell_size.x, cell_size.y, Image.INTERPOLATE_NEAREST)
	atlas.blit_rect(face, Rect2i(Vector2i.ZERO, cell_size), cell * cell_size)


## A picture filled with one colour, each pixel a little brighter or darker
## than the last ("noise" is how much). The starting point for every side.
func _speckle(width: int, height: int, base: Color, noise: float) -> Image:
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGB8)
	for y in height:
		for x in width:
			image.set_pixel(x, y, _shade(base, 1.0 + rng.randf_range(-noise, noise)))
	return image


## Paints a ragged blob: solid in the middle, with more and more gaps
## towards the edge. Used for blood stains, wounds and patches of rot.
func _splat(image: Image, centre: Vector2, radius: float, color: Color) -> void:
	for y in image.get_height():
		for x in image.get_width():
			if Vector2(x, y).distance_to(centre) <= radius * rng.randf_range(0.55, 1.0):
				image.set_pixel(x, y, _shade(color, rng.randf_range(0.8, 1.1)))


## Makes the lower rows of a piece of clothing grubbier the further down
## they are, starting at row "from".
func _add_grime(image: Image, from: int) -> void:
	for y in range(from, image.get_height()):
		for x in image.get_width():
			image.set_pixel(x, y, _shade(image.get_pixel(x, y), 1.0 - (y - from) * 0.04))


## The cut end of a limb: raw meat with the bone in the middle and a rim of
## skin or cloth ("rim") around it. These sides are hidden inside a joint
## until the limb is shot off.
func _make_stump(width: int, height: int, rim: Color) -> Image:
	var stump := _speckle(width, height, rim, 0.08)
	var centre := Vector2(width - 1, height - 1) / 2.0
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			var color := ZOMBIE_FLESH if rng.randf() < 0.35 else ZOMBIE_BLOOD
			if Vector2(x, y).distance_to(centre) < minf(width, height) * 0.2:
				color = ZOMBIE_BONE
			stump.set_pixel(x, y, _shade(color, rng.randf_range(0.8, 1.1)))
	return stump


## The zombie's head: a 28 cm cube, 16 pixels to a side.
func _make_zombie_head() -> Image:
	var atlas := _new_atlas(16, 16)

	# The face. The scene's two glowing eyes are separate little boxes that
	# sit over columns 2-5 and 10-13 of rows 5-7, inside the dark sockets.
	var front := _speckle(16, 16, ZOMBIE_SKIN, 0.08)
	_splat(front, Vector2(2, 11), 1.8, ZOMBIE_ROT)
	for x in 16:
		# A ragged fringe, between one and three pixels long.
		for y in rng.randi_range(1, 3):
			front.set_pixel(x, y, _shade(ZOMBIE_HAIR, rng.randf_range(0.8, 1.3)))
	front.fill_rect(Rect2i(1, 4, 6, 5), _shade(ZOMBIE_ROT, 0.45))
	front.fill_rect(Rect2i(9, 4, 6, 5), _shade(ZOMBIE_ROT, 0.45))
	front.fill_rect(Rect2i(7, 9, 2, 1), _shade(ZOMBIE_SKIN, 0.5))  # nostrils
	front.fill_rect(Rect2i(4, 11, 8, 3), Color(0.10, 0.03, 0.03))  # open mouth
	for x in range(4, 12, 2):
		front.set_pixel(x, 11, ZOMBIE_BONE)  # top teeth
		front.set_pixel(x + 1, 13, ZOMBIE_BONE)  # bottom teeth, in the gaps
	# Blood running from the mouth down the chin.
	front.fill_rect(Rect2i(10, 14, 1, 2), ZOMBIE_BLOOD)
	front.set_pixel(5, 14, ZOMBIE_BLOOD)
	_paint_face(atlas, FACE_FRONT, front)

	# The back of the head: hair down to the neck.
	var back := _speckle(16, 16, ZOMBIE_SKIN, 0.08)
	for x in 16:
		for y in rng.randi_range(9, 12):
			back.set_pixel(x, y, _shade(ZOMBIE_HAIR, rng.randf_range(0.8, 1.3)))
	_paint_face(atlas, FACE_BACK, back)

	_paint_face(atlas, FACE_RIGHT, _make_zombie_head_side(true))
	var left := _make_zombie_head_side(false)
	_splat(left, Vector2(4, 11), 2.2, ZOMBIE_FLESH)  # a bite out of the cheek
	_paint_face(atlas, FACE_LEFT, left)

	# The top: thin hair, split open on one side down to the skull.
	var top := _speckle(16, 16, ZOMBIE_HAIR, 0.3)
	_splat(top, Vector2(10, 7), 3.0, ZOMBIE_BLOOD)
	_splat(top, Vector2(10, 7), 1.6, ZOMBIE_FLESH)
	top.set_pixel(10, 7, ZOMBIE_BONE)
	_paint_face(atlas, FACE_TOP, top)

	_paint_face(atlas, FACE_BOTTOM, _make_stump(16, 16, ZOMBIE_SKIN))
	return atlas


## One side of the head, with an ear and hair that hangs lower at the back.
## The zombie's face is at the right edge of the picture on its right side
## and at the left edge on its left side, which is what front_on_right says.
func _make_zombie_head_side(front_on_right: bool) -> Image:
	var side := _speckle(16, 16, ZOMBIE_SKIN, 0.08)
	for x in 16:
		# How many pixels this column is from the back of the head.
		var from_back := x if front_on_right else 15 - x
		var hair_length := rng.randi_range(2, 4)
		if from_back < 6:
			hair_length += 7
		for y in hair_length:
			side.set_pixel(x, y, _shade(ZOMBIE_HAIR, rng.randf_range(0.8, 1.3)))
		if from_back == 7 or from_back == 8:
			for y in range(6, 9):
				side.set_pixel(x, y, _shade(ZOMBIE_SKIN, 0.65))  # the ear
	return side


## The zombie's torso in a filthy lab coat: 40 cm wide, 68 cm tall and 22 cm
## deep. The front and back are 20 x 32 pixels.
func _make_zombie_torso() -> Image:
	var atlas := _new_atlas(20, 32)

	# The front: the coat hangs open in a V at the collar, showing a shirt
	# and tie, and is buttoned below that.
	var front := _speckle(20, 32, ZOMBIE_COAT, 0.06)
	for y in 32:
		for x in 20:
			# How far this pixel is from the line down the middle.
			var across := absf(x - 9.5)
			# Half the width of the V on this row. It closes at row 14.
			var opening := (14 - y) * 0.35
			if across < opening - 1.0:
				var color := ZOMBIE_TIE if across < 1.0 else ZOMBIE_SHIRT
				front.set_pixel(x, y, _shade(color, rng.randf_range(0.85, 1.1)))
			elif across < opening:
				front.set_pixel(x, y, _shade(ZOMBIE_COAT, 0.6))  # edge of the lapel
			elif y >= 14 and x == 10:
				front.set_pixel(x, y, _shade(ZOMBIE_COAT, 0.7))  # where the coat closes
			elif x == 11 and (y == 17 or y == 22 or y == 27):
				front.set_pixel(x, y, _shade(ZOMBIE_COAT, 0.35))  # button
	front.fill_rect(Rect2i(13, 12, 5, 1), _shade(ZOMBIE_COAT, 0.65))  # breast pocket
	_add_grime(front, 24)
	_splat(front, Vector2(14, 7), 2.2, ZOMBIE_BLOOD)
	# A hole torn in the belly, with two ribs showing.
	_splat(front, Vector2(5, 22), 4.0, ZOMBIE_BLOOD)
	_splat(front, Vector2(5, 22), 2.4, ZOMBIE_FLESH)
	front.fill_rect(Rect2i(4, 21, 3, 1), ZOMBIE_BONE)
	front.fill_rect(Rect2i(4, 23, 3, 1), ZOMBIE_BONE)
	_paint_face(atlas, FACE_FRONT, front)

	# The back: a collar, a seam down the middle and three claw marks.
	var back := _speckle(20, 32, ZOMBIE_COAT, 0.06)
	back.fill_rect(Rect2i(0, 0, 20, 2), _shade(ZOMBIE_COAT, 0.7))
	back.fill_rect(Rect2i(10, 2, 1, 30), _shade(ZOMBIE_COAT, 0.8))
	_add_grime(back, 24)
	for claw in 3:
		for step in 9:
			# Each mark slants: one pixel across for every two down.
			@warning_ignore("integer_division")
			var x := 4 + claw * 4 + step / 2
			var color := ZOMBIE_FLESH if step > 2 and step < 6 else ZOMBIE_BLOOD
			back.set_pixel(x, 9 + step, color)
	_paint_face(atlas, FACE_BACK, back)

	_paint_face(atlas, FACE_RIGHT, _make_zombie_torso_side())
	var left := _make_zombie_torso_side()
	_splat(left, Vector2(3, 20), 2.5, ZOMBIE_BLOOD)
	_paint_face(atlas, FACE_LEFT, left)

	# The shoulders, seen from above. The head sits on the patch in the
	# middle, which is the stump of the neck if the head is shot off.
	var top := _speckle(20, 8, ZOMBIE_COAT, 0.06)
	top.blit_rect(_make_stump(6, 4, ZOMBIE_SKIN), Rect2i(0, 0, 6, 4), Vector2i(7, 2))
	_paint_face(atlas, FACE_TOP, top)

	# The underside is hidden by the legs.
	_paint_face(atlas, FACE_BOTTOM, _speckle(20, 8, ZOMBIE_TROUSERS, 0.08))
	return atlas


## One side of the torso. It is only 22 cm deep, so it is drawn 10 pixels
## wide and stretched to the cell's 20.
func _make_zombie_torso_side() -> Image:
	var side := _speckle(10, 32, ZOMBIE_COAT, 0.06)
	side.fill_rect(Rect2i(5, 0, 1, 32), _shade(ZOMBIE_COAT, 0.8))  # seam
	side.fill_rect(Rect2i(2, 0, 6, 5), _shade(ZOMBIE_COAT, 0.55))  # armhole
	_add_grime(side, 24)
	return side


## One of the zombie's arms, which it holds straight out in front: a box
## 10 cm square and 55 cm long. The long sides are drawn as a strip 30
## pixels long and 6 wide, then turned to suit each side of the box.
func _make_zombie_arm() -> Image:
	var atlas := _new_atlas(30, 30)

	# Seen from the zombie's right the shoulder is on the left, which is how
	# the strip is drawn. From its left the hand is on the left instead.
	_paint_face(atlas, FACE_RIGHT, _make_zombie_arm_strip())
	var left := _make_zombie_arm_strip()
	left.flip_x()
	_paint_face(atlas, FACE_LEFT, left)

	# On the top and bottom the arm runs down the picture, shoulder first.
	# A quarter turn clockwise moves the strip's left end to the top.
	var top := _make_zombie_arm_strip()
	top.rotate_90(CLOCKWISE)
	_splat(top, Vector2(2.5, 20), 1.8, ZOMBIE_FLESH)  # a bite on the forearm
	# Dark lines between the fingers.
	top.fill_rect(Rect2i(1, 25, 1, 5), _shade(ZOMBIE_ROT, 0.5))
	top.fill_rect(Rect2i(4, 25, 1, 5), _shade(ZOMBIE_ROT, 0.5))
	_paint_face(atlas, FACE_TOP, top)
	var bottom := _make_zombie_arm_strip()
	bottom.rotate_90(CLOCKWISE)
	_paint_face(atlas, FACE_BOTTOM, bottom)

	# The two ends: bloody fingertips at the front and the coat's shoulder
	# at the back. (The arm hangs beside the torso, not inside it, so its
	# back end can be seen from behind and is not drawn as a stump.)
	var fingertips := _speckle(6, 6, ZOMBIE_BLOOD, 0.2)
	fingertips.fill_rect(Rect2i(1, 0, 1, 6), _shade(ZOMBIE_ROT, 0.5))
	fingertips.fill_rect(Rect2i(4, 0, 1, 6), _shade(ZOMBIE_ROT, 0.5))
	_paint_face(atlas, FACE_FRONT, fingertips)
	_paint_face(atlas, FACE_BACK, _speckle(6, 6, ZOMBIE_COAT, 0.06))
	return atlas


## One long side of an arm, 30 x 6 pixels, from the shoulder (left) to the
## fingers (right): a torn coat sleeve, a rotting forearm and a bloody hand.
func _make_zombie_arm_strip() -> Image:
	var strip := Image.create_empty(30, 6, false, Image.FORMAT_RGB8)
	for y in 6:
		# The sleeve is torn off at a different length on every row.
		var sleeve_end := rng.randi_range(14, 18)
		for x in 30:
			var color := ZOMBIE_SKIN
			if x < sleeve_end - 1:
				color = ZOMBIE_COAT
			elif x < sleeve_end:
				color = _shade(ZOMBIE_COAT, 0.55)  # the frayed edge
			elif x >= 27:
				color = ZOMBIE_BLOOD  # fingers
			elif x >= 23:
				color = _shade(ZOMBIE_SKIN, 0.8)  # the hand
			elif rng.randf() < 0.15:
				color = ZOMBIE_ROT
			strip.set_pixel(x, y, _shade(color, rng.randf_range(0.9, 1.08)))
	return strip


## One of the zombie's legs: 14 cm wide, 62 cm tall and 18 cm deep. Each
## side is 8 x 32 pixels. Both legs use this texture.
func _make_zombie_leg() -> Image:
	var atlas := _new_atlas(8, 32)

	# The front has a crease down the trousers and a hole at the knee.
	var front := _make_zombie_leg_side()
	front.fill_rect(Rect2i(4, 0, 1, 12), _shade(ZOMBIE_TROUSERS, 1.3))
	_splat(front, Vector2(3.5, 14), 2.6, ZOMBIE_SKIN)
	front.set_pixel(3, 14, ZOMBIE_BLOOD)
	front.set_pixel(4, 15, ZOMBIE_BLOOD)
	_paint_face(atlas, FACE_FRONT, front)

	_paint_face(atlas, FACE_BACK, _make_zombie_leg_side())
	_paint_face(atlas, FACE_RIGHT, _make_zombie_leg_side())
	_paint_face(atlas, FACE_LEFT, _make_zombie_leg_side())

	# The hip, which shows once the leg is shot off, and the sole of the shoe.
	_paint_face(atlas, FACE_TOP, _make_stump(8, 8, ZOMBIE_TROUSERS))
	var sole := _speckle(8, 8, ZOMBIE_SHOE, 0.1)
	for y in range(1, 8, 2):
		sole.fill_rect(Rect2i(1, y, 6, 1), _shade(ZOMBIE_SHOE, 0.5))  # tread
	_paint_face(atlas, FACE_BOTTOM, sole)
	return atlas


## One side of a leg: trousers with mud up the shin, a frayed hem, and a shoe.
func _make_zombie_leg_side() -> Image:
	var side := _speckle(8, 32, ZOMBIE_TROUSERS, 0.1)
	for y in range(18, 27):
		for x in 8:
			# More splashes of mud the nearer the ground.
			if rng.randf() < (y - 17) * 0.05:
				side.set_pixel(x, y, _shade(ZOMBIE_ROT, 0.7))
	for x in 8:
		# The hem ends one row higher on some columns, showing the ankle.
		if rng.randf() < 0.5:
			side.set_pixel(x, 26, _shade(ZOMBIE_SKIN, 0.8))
	side.fill_rect(Rect2i(0, 27, 8, 5), ZOMBIE_SHOE)
	side.fill_rect(Rect2i(0, 31, 8, 1), _shade(ZOMBIE_SHOE, 1.8))  # edge of the sole
	return side


# --- The machine gun ---------------------------------------------------------
#
# The machine gun's five boxes (scenes/machine_gun.tscn) each get an atlas
# laid out like the zombie's above. The gun points along -Z, the way the
# zombie looks, so the "front" cell is the muzzle end of a part and "back"
# is the end nearest the player's face.
#
# A gun part is a long, thin box, like the zombie's arm. Its long sides are
# drawn as strips with the back of the gun at the left and the muzzle at the
# right, and _paint_gun_strip turns each one to suit its side of the box.

const GUN_STEEL := Color(0.25, 0.27, 0.30)
const GUN_POLYMER := Color(0.14, 0.14, 0.15)
const GUN_WORN := Color(0.50, 0.52, 0.54)
const GUN_BLACK := Color(0.03, 0.03, 0.035)
const GUN_YELLOW := Color(0.80, 0.62, 0.10)
const GUN_RED := Color(0.75, 0.12, 0.08)


## A plain strip of metal "length" pixels long and "girth" pixels wide, with
## light catching its top edge and its bottom edge in shadow.
func _make_gun_strip(length: int, girth: int, base: Color) -> Image:
	var strip := _speckle(length, girth, base, 0.07)
	for x in length:
		strip.set_pixel(x, 0, _shade(strip.get_pixel(x, 0), 1.5))
		strip.set_pixel(x, girth - 1, _shade(strip.get_pixel(x, girth - 1), 0.6))
	return strip


## Paints a strip onto one of the four long sides of a part. Seen from the
## right of the gun the strip is already the right way round. From the left
## the muzzle is on the left, so the strip is mirrored. On the top and
## bottom the gun runs down the picture, back first: a quarter turn
## clockwise moves the left end of the strip to the top.
func _paint_gun_strip(atlas: Image, cell: Vector2i, strip: Image) -> void:
	if cell == FACE_LEFT:
		strip.flip_x()
	elif cell == FACE_TOP or cell == FACE_BOTTOM:
		strip.rotate_90(CLOCKWISE)
	_paint_face(atlas, cell, strip)


## The body of the gun: 6 cm wide, 8 cm tall and 34 cm long. From the back:
## a butt plate (4 pixels), the steel receiver, and a handguard with cooling
## slots (the last 13 pixels). The sides are 48 x 12 pixels.
func _make_machine_gun_body() -> Image:
	var atlas := _new_atlas(48, 48)
	_paint_gun_strip(atlas, FACE_RIGHT, _make_machine_gun_body_side(true))
	_paint_gun_strip(atlas, FACE_LEFT, _make_machine_gun_body_side(false))

	# The top, which is most of what you see of the gun in your hands. It is
	# drawn the way the cell wants it: 8 pixels across, the back at the top.
	var top := _speckle(8, 48, GUN_STEEL, 0.07)
	top.fill_rect(Rect2i(0, 0, 1, 48), _shade(GUN_STEEL, 1.4))  # worn edges
	top.fill_rect(Rect2i(7, 0, 1, 48), _shade(GUN_STEEL, 1.4))
	top.fill_rect(Rect2i(0, 0, 8, 4), GUN_POLYMER)  # butt plate
	# The rear sight: two posts with a notch between them.
	top.fill_rect(Rect2i(1, 6, 6, 2), GUN_WORN)
	top.fill_rect(Rect2i(3, 6, 2, 2), GUN_BLACK)
	# A rail for a scope: a raised strip with a groove across every third row.
	for y in range(11, 33):
		var rail := GUN_BLACK if y % 3 == 0 else _shade(GUN_STEEL, 1.4)
		top.fill_rect(Rect2i(2, y, 4, 1), rail)
	top.fill_rect(Rect2i(0, 34, 8, 1), _shade(GUN_STEEL, 0.5))  # seam
	top.fill_rect(Rect2i(1, 35, 6, 13), GUN_POLYMER)  # handguard
	top.fill_rect(Rect2i(3, 44, 2, 2), GUN_WORN)  # front sight
	_paint_face(atlas, FACE_TOP, top)

	# The underside is darker, and mostly hidden by the magazine and grip.
	var bottom := _speckle(8, 48, _shade(GUN_STEEL, 0.7), 0.07)
	bottom.fill_rect(Rect2i(0, 0, 8, 4), GUN_POLYMER)
	bottom.fill_rect(Rect2i(1, 35, 6, 13), GUN_POLYMER)
	_paint_face(atlas, FACE_BOTTOM, bottom)

	# The back is the ribbed butt plate; the barrel covers most of the front.
	var back := _speckle(8, 12, GUN_POLYMER, 0.1)
	for y in range(3, 10, 3):
		back.fill_rect(Rect2i(1, y, 6, 1), GUN_BLACK)
	_paint_face(atlas, FACE_BACK, back)
	_paint_face(atlas, FACE_FRONT, _speckle(8, 12, GUN_POLYMER, 0.1))
	return atlas


## One side of the body. Spent cartridges are thrown out of the right side,
## so that one has the opening for them (ejection_port); the left side has
## the fire selector instead.
func _make_machine_gun_body_side(ejection_port: bool) -> Image:
	var side := _make_gun_strip(48, 12, GUN_STEEL)
	side.fill_rect(Rect2i(0, 0, 4, 12), GUN_POLYMER)  # butt plate
	side.fill_rect(Rect2i(4, 0, 1, 12), _shade(GUN_STEEL, 0.5))  # seam
	side.fill_rect(Rect2i(34, 0, 1, 12), _shade(GUN_STEEL, 0.5))  # seam
	side.fill_rect(Rect2i(35, 1, 13, 10), GUN_POLYMER)  # handguard
	for x: int in [37, 41, 45]:
		side.fill_rect(Rect2i(x, 3, 2, 6), GUN_BLACK)  # cooling slot
	for rivet: Vector2i in [Vector2i(7, 2), Vector2i(31, 2), Vector2i(7, 9), Vector2i(31, 9)]:
		side.set_pixel(rivet.x, rivet.y, GUN_WORN)
	if ejection_port:
		side.fill_rect(Rect2i(15, 3, 9, 4), GUN_BLACK)
		side.fill_rect(Rect2i(15, 7, 9, 1), GUN_WORN)  # its worn lower lip
	else:
		side.fill_rect(Rect2i(16, 4, 14, 1), _shade(GUN_STEEL, 0.6))  # groove
		side.fill_rect(Rect2i(11, 6, 3, 1), GUN_WORN)  # selector lever...
		side.set_pixel(10, 6, GUN_RED)  # ...pointing at the red "fire" dot
		for x: int in [20, 22, 24]:
			side.set_pixel(x, 8, _shade(GUN_WORN, 0.8))  # stamped lettering
	return side


## The barrel: 3 cm square and 20 cm long, with a pale gas block near the
## back and a slotted flash hider at the muzzle. Its sides are 28 x 4 pixels.
func _make_machine_gun_barrel() -> Image:
	var atlas := _new_atlas(28, 28)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var side := _make_gun_strip(28, 4, _shade(GUN_STEEL, 0.8))
		side.fill_rect(Rect2i(8, 0, 2, 4), _shade(GUN_WORN, 0.8))  # gas block
		side.fill_rect(Rect2i(21, 0, 1, 4), GUN_WORN)  # start of the flash hider
		side.fill_rect(Rect2i(23, 1, 1, 2), GUN_BLACK)  # its two slots
		side.fill_rect(Rect2i(25, 1, 1, 2), GUN_BLACK)
		_paint_gun_strip(atlas, cell, side)

	# The muzzle: a ring of steel around the black bore.
	var muzzle := _speckle(4, 4, _shade(GUN_WORN, 0.8), 0.07)
	muzzle.fill_rect(Rect2i(1, 1, 2, 2), GUN_BLACK)
	_paint_face(atlas, FACE_FRONT, muzzle)
	_paint_face(atlas, FACE_BACK, _speckle(4, 4, GUN_POLYMER, 0.1))
	return atlas


## The grenade launcher under the barrel: 5 cm square and 20 cm long. A fat
## tube with a ribbed section to hold, a yellow warning band and a wide
## mouth. Its sides are 28 x 7 pixels.
func _make_machine_gun_launcher() -> Image:
	var atlas := _new_atlas(28, 28)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var side := _make_gun_strip(28, 7, GUN_STEEL)
		side.fill_rect(Rect2i(5, 0, 1, 7), _shade(GUN_STEEL, 0.5))  # breech seam
		for x in range(9, 18, 2):
			side.fill_rect(Rect2i(x, 1, 1, 5), GUN_POLYMER)  # rib
		side.fill_rect(Rect2i(21, 0, 2, 7), GUN_YELLOW)
		side.fill_rect(Rect2i(26, 0, 2, 7), GUN_WORN)  # rim of the mouth
		_paint_gun_strip(atlas, cell, side)

	# The mouth: a round black hole, far wider than the bore of the barrel.
	var mouth := _speckle(7, 7, _shade(GUN_WORN, 0.8), 0.07)
	for y in 7:
		for x in 7:
			if Vector2(x, y).distance_to(Vector2(3, 3)) < 2.6:
				mouth.set_pixel(x, y, GUN_BLACK)
	_paint_face(atlas, FACE_FRONT, mouth)
	_paint_face(atlas, FACE_BACK, _speckle(7, 7, GUN_POLYMER, 0.1))
	return atlas


## The magazine: 4 cm wide, 14 cm tall and 5 cm deep. Pale pressed steel
## with stiffening ribs and a dark base plate. Each side is 6 x 20 pixels.
func _make_machine_gun_magazine() -> Image:
	var atlas := _new_atlas(6, 20)
	var pressed_steel := _shade(GUN_STEEL, 1.2)
	for cell: Vector2i in [FACE_FRONT, FACE_BACK, FACE_RIGHT, FACE_LEFT]:
		var side := _speckle(6, 20, pressed_steel, 0.07)
		side.fill_rect(Rect2i(0, 0, 1, 20), _shade(pressed_steel, 0.7))  # folded edges
		side.fill_rect(Rect2i(5, 0, 1, 20), _shade(pressed_steel, 0.7))
		for y in range(3, 16, 4):
			side.fill_rect(Rect2i(1, y, 4, 1), _shade(pressed_steel, 0.55))  # rib
		side.fill_rect(Rect2i(0, 17, 6, 3), GUN_POLYMER)  # base plate
		side.fill_rect(Rect2i(0, 17, 6, 1), GUN_WORN)  # its top edge
		_paint_face(atlas, cell, side)
	# The top is inside the gun; the bottom is the underside of the base plate.
	_paint_face(atlas, FACE_TOP, _speckle(6, 5, GUN_POLYMER, 0.1))
	_paint_face(atlas, FACE_BOTTOM, _speckle(6, 5, GUN_POLYMER, 0.1))
	return atlas


## The pistol grip: 4.5 cm wide, 10 cm tall and 5 cm deep. Black polymer
## with a chequered pattern to stop the hand slipping. Each side is 6 x 14.
func _make_machine_gun_grip() -> Image:
	var atlas := _new_atlas(6, 14)
	for cell: Vector2i in [FACE_FRONT, FACE_BACK, FACE_RIGHT, FACE_LEFT]:
		var side := _speckle(6, 14, GUN_POLYMER, 0.1)
		for y in range(2, 12):
			for x in 6:
				# Every other pixel, like the squares of one colour on a chessboard.
				if (x + y) % 2 == 0:
					side.set_pixel(x, y, _shade(GUN_POLYMER, 1.7))
		side.fill_rect(Rect2i(0, 13, 6, 1), _shade(GUN_POLYMER, 2.0))  # end cap
		_paint_face(atlas, cell, side)
	_paint_face(atlas, FACE_TOP, _speckle(6, 7, GUN_POLYMER, 0.1))
	_paint_face(atlas, FACE_BOTTOM, _speckle(6, 7, GUN_POLYMER, 0.1))
	return atlas


# --- The soldier ---------------------------------------------------------------
#
# The special forces player model (scenes/player_model_soldier.tscn). Its
# limbs wear two ordinary repeating textures, camouflage cloth and nylon
# webbing. The four parts that need a different picture on each side (the
# masked head, the helmet, the vest and the backpack) get atlases like the
# zombie's, and like the zombie the soldier looks along -Z.

const SOLDIER_OLIVE := Color(0.33, 0.37, 0.22)
const SOLDIER_GREEN := Color(0.16, 0.23, 0.12)
const SOLDIER_BROWN := Color(0.33, 0.25, 0.15)
const SOLDIER_MASK := Color(0.11, 0.11, 0.12)
const SOLDIER_SKIN := Color(0.72, 0.52, 0.40)
const SOLDIER_NYLON := Color(0.23, 0.25, 0.18)
const SOLDIER_PACK := Color(0.45, 0.38, 0.25)
const SOLDIER_BUCKLE := Color(0.55, 0.56, 0.55)


## Woodland camouflage that tiles: an olive cloth with patches of dark
## green, brown and near-black. Each colour has its own grid of blotches,
## and a pixel takes the colour wherever that grid is high enough.
func _make_soldier_camo() -> Image:
	var image := _new_image()
	var green := _make_blotch_grid(8)
	var brown := _make_blotch_grid(8)
	var dark := _make_blotch_grid(8)
	for y in SIZE:
		for x in SIZE:
			var color := SOLDIER_OLIVE
			if _blotch(dark, 8, x, y) > 0.72:
				color = _shade(SOLDIER_GREEN, 0.5)
			elif _blotch(green, 8, x, y) > 0.58:
				color = SOLDIER_GREEN
			elif _blotch(brown, 8, x, y) > 0.62:
				color = SOLDIER_BROWN
			image.set_pixel(x, y, _shade(color, 1.0 + rng.randf_range(-0.06, 0.06)))
	return image


## Nylon webbing that tiles: straps 8 pixels wide, sewn down every 8 pixels.
## It is painted pale grey so that materials can tint it: olive for
## pouches, nearly black for boots and gloves, and each player's own colour
## for the armbands (see tinted_material in scripts/player_model.gd).
func _make_soldier_webbing() -> Image:
	var image := _new_image()
	var nylon := Color(0.78, 0.78, 0.76)
	for y in SIZE:
		for x in SIZE:
			var brightness := 1.0 + rng.randf_range(-0.06, 0.06)
			if y % 8 == 0:
				brightness *= 0.6  # the gap between two straps
			elif y % 8 == 1:
				brightness *= 1.12  # light on the top edge of a strap
			elif x % 8 == 0 and y % 8 >= 3 and y % 8 <= 5:
				brightness *= 0.7  # stitching
			image.set_pixel(x, y, _shade(nylon, brightness))
	return image


## A small piece of the camouflage for one side of an atlas: olive with a
## few blobs of the other colours at random places.
func _make_camo_patch(width: int, height: int) -> Image:
	var patch := _speckle(width, height, SOLDIER_OLIVE, 0.06)
	for color: Color in [SOLDIER_GREEN, SOLDIER_BROWN, SOLDIER_GREEN, _shade(SOLDIER_GREEN, 0.5)]:
		var centre := Vector2(rng.randf_range(0.0, width), rng.randf_range(0.0, height))
		_splat(patch, centre, rng.randf_range(2.0, 3.5), color)
	return patch


## The soldier's head in a black balaclava: 22 cm wide and tall, 24 cm deep,
## 12 pixels to a side. Only the eyes show, and the night-vision goggles
## cover most of those. A grey goggle strap runs round the sides and back.
func _make_soldier_head() -> Image:
	var atlas := _new_atlas(12, 12)

	var front := _speckle(12, 12, SOLDIER_MASK, 0.1)
	front.fill_rect(Rect2i(2, 3, 8, 6), SOLDIER_SKIN)  # the opening for the eyes
	front.fill_rect(Rect2i(2, 3, 8, 1), _shade(SOLDIER_SKIN, 0.7))  # brow in shadow
	front.set_pixel(3, 5, Color(0.9, 0.9, 0.88))  # the whites of the eyes...
	front.set_pixel(8, 5, Color(0.9, 0.9, 0.88))
	front.set_pixel(4, 5, SOLDIER_MASK)  # ...and the pupils
	front.set_pixel(7, 5, SOLDIER_MASK)
	front.fill_rect(Rect2i(5, 9, 2, 1), _shade(SOLDIER_MASK, 1.8))  # the nose
	front.fill_rect(Rect2i(5, 10, 2, 1), _shade(SOLDIER_MASK, 0.5))  # the mouth
	_paint_face(atlas, FACE_FRONT, front)

	for cell: Vector2i in [FACE_BACK, FACE_RIGHT, FACE_LEFT]:
		var side := _speckle(12, 12, SOLDIER_MASK, 0.1)
		side.fill_rect(Rect2i(0, 5, 12, 1), _shade(SOLDIER_MASK, 2.2))  # strap
		_paint_face(atlas, cell, side)
	# The top is inside the helmet and the bottom sits on the neck.
	_paint_face(atlas, FACE_TOP, _speckle(12, 12, SOLDIER_MASK, 0.1))
	_paint_face(atlas, FACE_BOTTOM, _speckle(12, 12, SOLDIER_MASK, 0.1))
	return atlas


## The helmet in its camouflage cover: 27 cm wide, 14 cm tall and 29 cm
## deep. The front, back and sides are 16 x 8 pixels, the top 16 x 16.
func _make_soldier_helmet() -> Image:
	var atlas := _new_atlas(16, 16)

	# The front has the black plate the night-vision goggles hang from.
	var front := _make_soldier_helmet_side()
	front.fill_rect(Rect2i(6, 3, 4, 4), SOLDIER_MASK)
	front.set_pixel(7, 4, SOLDIER_BUCKLE)
	_paint_face(atlas, FACE_FRONT, front)

	# Each side has a rail for clipping on a torch or a headset.
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT]:
		var side := _make_soldier_helmet_side()
		side.fill_rect(Rect2i(4, 4, 9, 2), SOLDIER_MASK)
		side.set_pixel(5, 4, SOLDIER_BUCKLE)
		side.set_pixel(11, 4, SOLDIER_BUCKLE)
		_paint_face(atlas, cell, side)

	# The back has a cloth patch stuck on.
	var back := _make_soldier_helmet_side()
	back.fill_rect(Rect2i(5, 2, 6, 3), SOLDIER_PACK)
	back.fill_rect(Rect2i(6, 3, 4, 1), _shade(SOLDIER_PACK, 0.5))
	_paint_face(atlas, FACE_BACK, back)

	# The top has two air vents.
	var top := _make_camo_patch(16, 16)
	top.fill_rect(Rect2i(6, 5, 1, 4), SOLDIER_MASK)
	top.fill_rect(Rect2i(9, 5, 1, 4), SOLDIER_MASK)
	_paint_face(atlas, FACE_TOP, top)
	_paint_face(atlas, FACE_BOTTOM, _speckle(16, 16, SOLDIER_MASK, 0.1))
	return atlas


## One upright side of the helmet: camouflage with a dark rim at the bottom.
func _make_soldier_helmet_side() -> Image:
	var side := _make_camo_patch(16, 8)
	side.fill_rect(Rect2i(0, 7, 16, 1), _shade(SOLDIER_GREEN, 0.4))
	return side


## The vest (a "plate carrier"): 42 cm wide, 40 cm tall and 28 cm deep. The
## front and back are 24 x 22 pixels; the sides are drawn 12 pixels wide and
## the top 11 pixels deep, and stretched to fit the cell.
func _make_soldier_vest() -> Image:
	var atlas := _new_atlas(24, 22)
	var strap := _shade(SOLDIER_NYLON, 1.35)

	# The front: shoulder straps, a flag patch and a name tape on the chest,
	# and three magazine pouches along the bottom.
	var front := _make_soldier_vest_panel(24, 22)
	front.fill_rect(Rect2i(3, 0, 5, 4), strap)
	front.fill_rect(Rect2i(16, 0, 5, 4), strap)
	front.fill_rect(Rect2i(4, 5, 4, 3), SOLDIER_GREEN)  # flag patch
	front.fill_rect(Rect2i(4, 6, 4, 1), _shade(SOLDIER_OLIVE, 1.3))
	front.fill_rect(Rect2i(13, 5, 7, 2), SOLDIER_PACK)  # name tape
	for pouch in 3:
		var left := 2 + pouch * 7
		front.fill_rect(Rect2i(left, 11, 6, 10), _shade(SOLDIER_NYLON, 1.25))
		front.fill_rect(Rect2i(left + 5, 14, 1, 7), _shade(SOLDIER_NYLON, 0.8))  # its shaded side
		front.fill_rect(Rect2i(left, 11, 6, 3), _shade(SOLDIER_NYLON, 0.65))  # the flap
		front.fill_rect(Rect2i(left + 2, 13, 2, 1), SOLDIER_BUCKLE)  # press stud
	front.fill_rect(Rect2i(0, 21, 24, 1), _shade(SOLDIER_NYLON, 0.5))
	_paint_face(atlas, FACE_FRONT, front)

	# The back is mostly behind the backpack: a handle for dragging a
	# wounded soldier, and more webbing.
	var back := _make_soldier_vest_panel(24, 22)
	back.fill_rect(Rect2i(9, 1, 6, 2), strap)
	_paint_face(atlas, FACE_BACK, back)

	# The sides: three wide elastic bands that hold front and back together.
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT]:
		var side := _make_soldier_vest_panel(12, 22)
		for y in range(8, 21, 5):
			side.fill_rect(Rect2i(0, y, 12, 3), strap)
			side.fill_rect(Rect2i(5, y + 1, 2, 1), SOLDIER_MASK)  # buckle
		_paint_face(atlas, cell, side)

	# The top: the two shoulder straps, either side of the hole for the neck.
	var top := _speckle(24, 11, SOLDIER_NYLON, 0.07)
	top.fill_rect(Rect2i(3, 0, 5, 11), strap)
	top.fill_rect(Rect2i(16, 0, 5, 11), strap)
	top.fill_rect(Rect2i(9, 2, 6, 7), SOLDIER_MASK)
	_paint_face(atlas, FACE_TOP, top)
	_paint_face(atlas, FACE_BOTTOM, _speckle(24, 11, _shade(SOLDIER_NYLON, 0.6), 0.07))
	return atlas


## A piece of the vest's cloth, covered in rows of webbing for clipping
## pouches to: a dark gap every 4 rows, sewn down every 4 pixels.
func _make_soldier_vest_panel(width: int, height: int) -> Image:
	var panel := _speckle(width, height, SOLDIER_NYLON, 0.07)
	for y in range(2, height, 4):
		panel.fill_rect(Rect2i(0, y, width, 1), _shade(SOLDIER_NYLON, 0.6))
		for x in range(0, width, 4):
			panel.set_pixel(x, y - 1, _shade(SOLDIER_NYLON, 0.75))  # stitch
	return panel


## The backpack: 34 cm wide, 44 cm tall and 18 cm deep, in sand-coloured
## canvas. Its back (the side facing away from the soldier, which is what
## you see when following someone) is 18 x 24 pixels; the sides are drawn 9
## pixels wide and the top 12 deep, and stretched to fit the cell.
func _make_soldier_backpack() -> Image:
	var atlas := _new_atlas(18, 24)
	var seam := _shade(SOLDIER_PACK, 0.55)

	# The back: a lid held down by two straps with buckles, and a zipped
	# pocket below it.
	var back := _speckle(18, 24, SOLDIER_PACK, 0.07)
	back.fill_rect(Rect2i(0, 0, 18, 8), _shade(SOLDIER_PACK, 1.12))  # lid
	back.fill_rect(Rect2i(0, 8, 18, 1), seam)  # shadow under the lid
	for x: int in [4, 12]:
		back.fill_rect(Rect2i(x, 0, 2, 13), seam)  # strap
		back.fill_rect(Rect2i(x, 10, 2, 2), SOLDIER_BUCKLE)
	# The pocket: its outline, then the zip as a dotted line.
	back.fill_rect(Rect2i(3, 14, 12, 1), seam)
	back.fill_rect(Rect2i(3, 21, 12, 1), seam)
	back.fill_rect(Rect2i(3, 14, 1, 8), seam)
	back.fill_rect(Rect2i(14, 14, 1, 8), seam)
	for x in range(5, 13, 2):
		back.set_pixel(x, 16, SOLDIER_BUCKLE)
	back.fill_rect(Rect2i(0, 22, 18, 2), _shade(SOLDIER_PACK, 0.75))  # scuffed base
	_paint_face(atlas, FACE_BACK, back)

	# The sides: two straps that pull the load tight, and a bottle pocket.
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT]:
		var side := _speckle(9, 24, SOLDIER_PACK, 0.07)
		for y: int in [5, 12]:
			side.fill_rect(Rect2i(0, y, 9, 1), seam)
			side.set_pixel(4, y, SOLDIER_BUCKLE)
		side.fill_rect(Rect2i(1, 17, 7, 7), _shade(SOLDIER_PACK, 0.85))
		side.fill_rect(Rect2i(1, 17, 7, 1), seam)
		_paint_face(atlas, cell, side)

	# The top of the lid, with a handle to carry the pack by.
	var top := _speckle(18, 12, _shade(SOLDIER_PACK, 1.12), 0.07)
	top.fill_rect(Rect2i(6, 5, 6, 2), seam)
	_paint_face(atlas, FACE_TOP, top)
	# The front lies against the soldier's back; the bottom is the base.
	_paint_face(atlas, FACE_FRONT, _speckle(18, 24, _shade(SOLDIER_PACK, 0.7), 0.07))
	_paint_face(atlas, FACE_BOTTOM, _speckle(18, 12, _shade(SOLDIER_PACK, 0.7), 0.07))
	return atlas


# --- The other guns, and what the guns fire ---------------------------------
#
# The pistol, the shotgun and the rocket launcher, textured part by part
# like the machine gun above, then the rocket, the grenade and the bullet.
# Everything here points along -Z too, so "front" is the muzzle or the nose.
#
# In a strip, the length must divide exactly by the girth (32 by 8, 60 by
# 5...). Both the long sides and the top are stretched to fill the same
# square cell, and that only comes out in whole pixels if it does.

const GUN_BLUED := Color(0.21, 0.23, 0.26)
const GUN_WOOD := Color(0.36, 0.22, 0.11)
const GUN_OLIVE := Color(0.27, 0.31, 0.19)
const GUN_BRASS := Color(0.72, 0.55, 0.20)


## A strip of wood with the grain running along it: every row of pixels is
## a slightly different brown from end to end.
func _make_wood_strip(length: int, girth: int) -> Image:
	var strip := Image.create_empty(length, girth, false, Image.FORMAT_RGB8)
	for y in girth:
		var grain := rng.randf_range(-0.14, 0.14)
		for x in length:
			strip.set_pixel(x, y, _shade(GUN_WOOD, 1.0 + grain + rng.randf_range(-0.04, 0.04)))
	return strip


## The end of a tube, seen head on: a square of "rim" colour with a round
## black hole "radius" pixels across in the middle.
func _make_bore(size: int, rim: Color, radius: float) -> Image:
	var end := _speckle(size, size, rim, 0.07)
	var centre := Vector2(size - 1, size - 1) / 2.0
	for y in size:
		for x in size:
			if Vector2(x, y).distance_to(centre) < radius:
				end.set_pixel(x, y, GUN_BLACK)
	return end


## The top half of the pistol: 5 cm wide, 6 cm tall and 22 cm long. The
## steel slide is the upper part and the black frame the lower. The sides
## are 32 x 8 pixels.
func _make_pistol_slide() -> Image:
	var atlas := _new_atlas(32, 32)
	_paint_gun_strip(atlas, FACE_RIGHT, _make_pistol_slide_side(true))
	_paint_gun_strip(atlas, FACE_LEFT, _make_pistol_slide_side(false))

	# The top, seen from above with the back at the top of the picture.
	var top := _speckle(8, 32, GUN_STEEL, 0.07)
	top.fill_rect(Rect2i(0, 0, 1, 32), _shade(GUN_STEEL, 1.4))  # worn edges
	top.fill_rect(Rect2i(7, 0, 1, 32), _shade(GUN_STEEL, 1.4))
	top.fill_rect(Rect2i(1, 1, 6, 2), GUN_WORN)  # rear sight...
	top.fill_rect(Rect2i(3, 1, 2, 2), GUN_BLACK)  # ...and its notch
	top.fill_rect(Rect2i(3, 5, 2, 22), _shade(GUN_STEEL, 1.2))  # flat rib
	top.fill_rect(Rect2i(3, 29, 2, 2), GUN_RED)  # front sight
	_paint_face(atlas, FACE_TOP, top)
	_paint_face(atlas, FACE_BOTTOM, _speckle(8, 32, GUN_POLYMER, 0.1))

	# The back, which faces you: the slide with the hammer, over the frame.
	var back := _speckle(8, 8, GUN_STEEL, 0.07)
	back.fill_rect(Rect2i(3, 1, 2, 3), GUN_BLACK)
	back.fill_rect(Rect2i(0, 5, 8, 3), GUN_POLYMER)
	_paint_face(atlas, FACE_BACK, back)

	# The front: the bore, and the tip of the spring guide under it.
	var front := _speckle(8, 8, GUN_STEEL, 0.07)
	front.fill_rect(Rect2i(3, 1, 2, 2), GUN_BLACK)
	front.fill_rect(Rect2i(3, 4, 2, 1), GUN_WORN)
	front.fill_rect(Rect2i(0, 6, 8, 2), GUN_POLYMER)
	_paint_face(atlas, FACE_FRONT, front)
	return atlas


## One side of the pistol's slide and frame. The right side has the port
## that spent cartridges fly out of; the left has the slide stop and safety.
func _make_pistol_slide_side(ejection_port: bool) -> Image:
	var side := _make_gun_strip(32, 8, GUN_STEEL)
	side.fill_rect(Rect2i(0, 5, 32, 1), GUN_BLACK)  # gap between slide and frame
	side.fill_rect(Rect2i(0, 6, 32, 2), GUN_POLYMER)  # the frame
	for x in range(2, 9, 2):
		side.fill_rect(Rect2i(x, 1, 1, 4), _shade(GUN_STEEL, 0.5))  # grooves to grip
	side.fill_rect(Rect2i(30, 0, 2, 5), GUN_WORN)  # bare metal at the muzzle
	if ejection_port:
		side.fill_rect(Rect2i(14, 1, 7, 3), GUN_BLACK)
		side.fill_rect(Rect2i(14, 4, 7, 1), GUN_WORN)
	else:
		side.fill_rect(Rect2i(13, 6, 4, 1), GUN_WORN)  # slide stop
		side.set_pixel(5, 6, GUN_RED)  # safety catch
	return side


## The pistol's grip: 4.5 cm wide, 11 cm tall and 6 cm deep. Black polymer,
## chequered on the sides and grooved front and back, with the steel base
## of the magazine showing at the bottom. Each side is 8 x 16 pixels.
func _make_pistol_grip() -> Image:
	var atlas := _new_atlas(8, 16)
	for cell: Vector2i in [FACE_FRONT, FACE_BACK, FACE_RIGHT, FACE_LEFT]:
		var side := _speckle(8, 16, GUN_POLYMER, 0.1)
		if cell == FACE_RIGHT or cell == FACE_LEFT:
			for y in range(2, 12):
				for x in range(1, 7):
					if (x + y) % 2 == 0:
						side.set_pixel(x, y, _shade(GUN_POLYMER, 1.7))
		else:
			for y in range(2, 12, 2):
				side.fill_rect(Rect2i(1, y, 6, 1), GUN_BLACK)
		side.fill_rect(Rect2i(0, 13, 8, 1), GUN_BLACK)
		side.fill_rect(Rect2i(0, 14, 8, 2), _shade(GUN_STEEL, 1.1))  # magazine base
		_paint_face(atlas, cell, side)
	_paint_face(atlas, FACE_TOP, _speckle(8, 8, GUN_POLYMER, 0.1))
	_paint_face(atlas, FACE_BOTTOM, _speckle(8, 8, _shade(GUN_STEEL, 1.1), 0.07))
	return atlas


## The shotgun's receiver, the steel box the working parts are in: 6 cm
## wide, 9 cm tall and 26 cm long. The sides are 36 x 12 pixels.
func _make_shotgun_receiver() -> Image:
	var atlas := _new_atlas(36, 36)
	_paint_gun_strip(atlas, FACE_RIGHT, _make_shotgun_receiver_side(true))
	_paint_gun_strip(atlas, FACE_LEFT, _make_shotgun_receiver_side(false))

	var top := _speckle(9, 36, GUN_BLUED, 0.07)
	top.fill_rect(Rect2i(0, 0, 1, 36), _shade(GUN_BLUED, 1.4))  # worn edges
	top.fill_rect(Rect2i(8, 0, 1, 36), _shade(GUN_BLUED, 1.4))
	_paint_face(atlas, FACE_TOP, top)

	# Underneath is the opening the shells are pushed into.
	var bottom := _speckle(9, 36, _shade(GUN_BLUED, 0.7), 0.07)
	bottom.fill_rect(Rect2i(2, 12, 5, 14), GUN_BLACK)
	_paint_face(atlas, FACE_BOTTOM, bottom)

	# The back, which faces you, has the end of the bolt in the middle.
	var back := _speckle(9, 12, GUN_BLUED, 0.07)
	back.fill_rect(Rect2i(3, 4, 3, 4), GUN_WORN)
	back.fill_rect(Rect2i(4, 5, 1, 2), GUN_BLACK)
	_paint_face(atlas, FACE_BACK, back)
	_paint_face(atlas, FACE_FRONT, _speckle(9, 12, _shade(GUN_BLUED, 0.7), 0.07))
	return atlas


## One side of the shotgun's receiver. The right side has the port the
## empty shells are thrown from; the left has the maker's plate and the
## safety button.
func _make_shotgun_receiver_side(ejection_port: bool) -> Image:
	var side := _make_gun_strip(36, 12, GUN_BLUED)
	side.fill_rect(Rect2i(4, 7, 29, 1), _shade(GUN_BLUED, 0.55))  # groove
	side.fill_rect(Rect2i(10, 10, 16, 1), GUN_BLACK)  # edge of the loading port
	for screw: Vector2i in [Vector2i(5, 3), Vector2i(31, 3), Vector2i(5, 9)]:
		side.set_pixel(screw.x, screw.y, GUN_WORN)
	if ejection_port:
		side.fill_rect(Rect2i(15, 2, 11, 4), GUN_BLACK)
		side.fill_rect(Rect2i(15, 6, 11, 1), GUN_WORN)
	else:
		side.fill_rect(Rect2i(14, 3, 10, 2), _shade(GUN_BLUED, 1.3))  # maker's plate
		side.set_pixel(8, 5, GUN_RED)  # safety button
	return side


## The shotgun's barrel: 3.5 cm square and 42 cm long. Dark steel with a
## bright band where it is clamped to the tube below, and a brass bead to
## aim with on top near the muzzle. Its sides are 60 x 5 pixels.
func _make_shotgun_barrel() -> Image:
	var atlas := _new_atlas(60, 60)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var side := _make_gun_strip(60, 5, _shade(GUN_BLUED, 0.9))
		side.fill_rect(Rect2i(40, 0, 2, 5), GUN_WORN)  # clamp
		side.fill_rect(Rect2i(58, 0, 2, 5), _shade(GUN_WORN, 0.8))  # bare muzzle
		if cell == FACE_TOP:
			side.set_pixel(56, 2, GUN_BRASS)  # bead
		_paint_gun_strip(atlas, cell, side)
	_paint_face(atlas, FACE_FRONT, _make_bore(5, _shade(GUN_WORN, 0.8), 1.6))
	_paint_face(atlas, FACE_BACK, _speckle(5, 5, _shade(GUN_BLUED, 0.7), 0.07))
	return atlas


## The tube under the shotgun's barrel that holds the shells: 4 cm square
## and 36 cm long, with the same clamp round it and a knurled cap on the
## end. Its sides are 48 x 6 pixels.
func _make_shotgun_tube() -> Image:
	var atlas := _new_atlas(48, 48)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var side := _make_gun_strip(48, 6, GUN_BLUED)
		side.fill_rect(Rect2i(37, 0, 2, 6), GUN_WORN)  # clamp
		for x in range(44, 48, 2):
			side.fill_rect(Rect2i(x, 0, 1, 6), GUN_WORN)  # ridges on the cap
		_paint_gun_strip(atlas, cell, side)
	var cap := _speckle(6, 6, _shade(GUN_WORN, 0.8), 0.07)
	cap.fill_rect(Rect2i(2, 2, 2, 2), _shade(GUN_BLUED, 0.5))
	_paint_face(atlas, FACE_FRONT, cap)
	_paint_face(atlas, FACE_BACK, _speckle(6, 6, _shade(GUN_BLUED, 0.7), 0.07))
	return atlas


## The shotgun's pump, the wooden handle that slides back and forth: 7 cm
## wide, 6 cm tall and 14 cm long, with grooves cut across it for grip. Its
## sides are 24 x 8 pixels.
func _make_shotgun_pump() -> Image:
	var atlas := _new_atlas(24, 24)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var side := _make_wood_strip(24, 8)
		for x in range(3, 22, 3):
			side.fill_rect(Rect2i(x, 1, 1, 6), _shade(GUN_WOOD, 0.5))
		_paint_gun_strip(atlas, cell, side)
	# The ends are plain: the tube runs through the middle of them.
	for cell: Vector2i in [FACE_FRONT, FACE_BACK]:
		var end := _speckle(8, 8, _shade(GUN_WOOD, 0.7), 0.1)
		_paint_face(atlas, cell, end)
	return atlas


## The shotgun's wooden grip: 4.5 cm wide, 11 cm tall and 5 cm deep. The
## grain runs down it, the sides are chequered and the bottom has a steel
## cap. Each side is 8 x 16 pixels.
func _make_shotgun_grip() -> Image:
	var atlas := _new_atlas(8, 16)
	for cell: Vector2i in [FACE_FRONT, FACE_BACK, FACE_RIGHT, FACE_LEFT]:
		# A strip with the grain along it, stood on end.
		var side := _make_wood_strip(16, 8)
		side.rotate_90(CLOCKWISE)
		if cell == FACE_RIGHT or cell == FACE_LEFT:
			for y in range(3, 11):
				for x in range(2, 6):
					if (x + y) % 2 == 0:
						side.set_pixel(x, y, _shade(GUN_WOOD, 0.55))
		side.fill_rect(Rect2i(0, 14, 8, 2), GUN_BLUED)
		_paint_face(atlas, cell, side)
	_paint_face(atlas, FACE_TOP, _speckle(8, 8, GUN_WOOD, 0.1))
	_paint_face(atlas, FACE_BOTTOM, _speckle(8, 8, GUN_BLUED, 0.07))
	return atlas


## The rib along the top of the shotgun that you sight down (the node
## called Stock in scenes/shotgun.tscn): 3 cm square and 22 cm long. Dull
## steel with fine grooves to stop it glinting, and a rear sight. Its sides
## are 32 x 4 pixels.
func _make_shotgun_rib() -> Image:
	var atlas := _new_atlas(32, 32)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var side := _make_gun_strip(32, 4, _shade(GUN_BLUED, 0.8))
		for x in range(4, 30, 2):
			side.fill_rect(Rect2i(x, 1, 1, 2), _shade(GUN_BLUED, 0.5))
		side.fill_rect(Rect2i(1, 0, 2, 4), GUN_WORN)  # rear sight
		_paint_gun_strip(atlas, cell, side)
	_paint_face(atlas, FACE_FRONT, _speckle(4, 4, _shade(GUN_BLUED, 0.8), 0.07))
	_paint_face(atlas, FACE_BACK, _speckle(4, 4, _shade(GUN_BLUED, 0.8), 0.07))
	return atlas


## The shoulder stock of the shotgun the player model carries (the gun in
## your hands has none): 6 cm wide, 10 cm tall and 16 cm long. Wood, with a
## black rubber pad on the end. Its sides are 24 x 12 pixels.
func _make_shotgun_stock() -> Image:
	var atlas := _new_atlas(24, 24)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var upright := cell == FACE_RIGHT or cell == FACE_LEFT
		var side := _make_wood_strip(24, 12 if upright else 8)
		side.fill_rect(Rect2i(0, 0, 3, side.get_height()), GUN_BLACK)  # pad
		_paint_gun_strip(atlas, cell, side)
	_paint_face(atlas, FACE_BACK, _make_butt_pad())
	_paint_face(atlas, FACE_FRONT, _speckle(8, 12, _shade(GUN_WOOD, 0.7), 0.1))
	return atlas


## The shoulder stock of the machine gun the player model carries: the same
## size as the shotgun's, but a black polymer frame with a hole through it.
func _make_machine_gun_stock() -> Image:
	var atlas := _new_atlas(24, 24)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var upright := cell == FACE_RIGHT or cell == FACE_LEFT
		var side := _make_gun_strip(24, 12 if upright else 8, GUN_POLYMER)
		side.fill_rect(Rect2i(0, 0, 3, side.get_height()), GUN_BLACK)  # pad
		if upright:
			side.fill_rect(Rect2i(8, 3, 11, 6), GUN_BLACK)  # the hole
		_paint_gun_strip(atlas, cell, side)
	_paint_face(atlas, FACE_BACK, _make_butt_pad())
	_paint_face(atlas, FACE_FRONT, _speckle(8, 12, GUN_POLYMER, 0.1))
	return atlas


## The end of a stock that goes against the shoulder: ribbed black rubber.
func _make_butt_pad() -> Image:
	var pad := _speckle(8, 12, GUN_POLYMER, 0.1)
	for y in range(2, 11, 2):
		pad.fill_rect(Rect2i(1, y, 6, 1), GUN_BLACK)
	return pad


## The rocket launcher's tube: 10 cm square and 60 cm long. Olive paint
## with a steel collar at the back, hazard stripes, seams, a yellow band
## and some stencilled lettering. Its sides are 60 x 10 pixels.
func _make_rocket_launcher_tube() -> Image:
	var atlas := _new_atlas(60, 60)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var side := _make_gun_strip(60, 10, GUN_OLIVE)
		side.fill_rect(Rect2i(0, 0, 4, 10), GUN_BLUED)  # collar
		for y in 10:
			for x in range(6, 12):
				# Diagonal stripes, as on the hazard texture.
				side.set_pixel(x, y, GUN_YELLOW if (x + y) % 4 < 2 else GUN_BLACK)
		side.fill_rect(Rect2i(20, 0, 1, 10), _shade(GUN_OLIVE, 0.55))  # seams
		side.fill_rect(Rect2i(40, 0, 1, 10), _shade(GUN_OLIVE, 0.55))
		for x in range(24, 36, 2):
			side.set_pixel(x, 4, GUN_YELLOW)  # two lines of lettering
		for x in range(24, 32, 2):
			side.set_pixel(x, 6, GUN_YELLOW)
		side.fill_rect(Rect2i(46, 0, 2, 10), GUN_YELLOW)  # band
		_paint_gun_strip(atlas, cell, side)
	_paint_face(atlas, FACE_FRONT, _make_bore(10, GUN_BLUED, 3.8))
	_paint_face(atlas, FACE_BACK, _make_bore(10, GUN_BLUED, 3.8))
	return atlas


## The flared steel ring on the end of the rocket launcher: 13 cm square
## and 8 cm long, with worn edges. Only the front shows the hole: the back
## is against the tube. (The player model turns a second one round to make
## the exhaust at the other end.) Its sides are 6 x 12 pixels.
func _make_rocket_launcher_muzzle() -> Image:
	var atlas := _new_atlas(12, 12)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var side := _make_gun_strip(6, 12, GUN_BLUED)
		side.fill_rect(Rect2i(0, 0, 1, 12), GUN_WORN)
		side.fill_rect(Rect2i(5, 0, 1, 12), GUN_WORN)
		_paint_gun_strip(atlas, cell, side)
	_paint_face(atlas, FACE_FRONT, _make_bore(12, GUN_BLUED, 4.3))
	_paint_face(atlas, FACE_BACK, _speckle(12, 12, GUN_BLUED, 0.07))
	return atlas


## The sight on top of the rocket launcher: 2 cm wide, 5 cm tall and 6 cm
## long. A steel housing with a pale blue lens at each end.
func _make_rocket_launcher_sight() -> Image:
	var atlas := _new_atlas(6, 10)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT]:
		var side := _speckle(6, 5, GUN_BLUED, 0.07)
		side.fill_rect(Rect2i(1, 1, 4, 3), GUN_POLYMER)
		_paint_face(atlas, cell, side)
	for cell: Vector2i in [FACE_FRONT, FACE_BACK]:
		var lens := _speckle(2, 5, GUN_POLYMER, 0.1)
		lens.fill_rect(Rect2i(0, 1, 2, 3), Color(0.35, 0.6, 0.7))
		_paint_face(atlas, cell, lens)
	_paint_face(atlas, FACE_TOP, _speckle(2, 5, GUN_BLUED, 0.07))
	_paint_face(atlas, FACE_BOTTOM, _speckle(2, 5, GUN_BLUED, 0.07))
	return atlas


## The rocket in flight (scenes/rocket.tscn): 10 cm square and 40 cm long.
## From the back: steel tail with dark fins, olive body with lettering and
## a yellow band, and a darker warhead with a red tip. It is drawn without
## lighting, so these colours are exactly what you see. Its sides are
## 40 x 10 pixels.
func _make_rocket() -> Image:
	var atlas := _new_atlas(40, 40)
	var paint := Color(0.36, 0.40, 0.26)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var side := _speckle(40, 10, paint, 0.06)
		side.fill_rect(Rect2i(0, 0, 6, 10), _shade(GUN_STEEL, 1.3))  # tail
		side.fill_rect(Rect2i(0, 0, 6, 2), GUN_POLYMER)  # fins
		side.fill_rect(Rect2i(0, 8, 6, 2), GUN_POLYMER)
		for x in range(9, 19, 2):
			side.set_pixel(x, 4, Color(0.85, 0.85, 0.8))  # lettering
		side.fill_rect(Rect2i(22, 0, 2, 10), GUN_YELLOW)
		side.fill_rect(Rect2i(29, 0, 1, 10), GUN_BLACK)
		side.fill_rect(Rect2i(30, 0, 7, 10), _shade(paint, 0.7))  # warhead
		side.fill_rect(Rect2i(37, 0, 3, 10), GUN_RED)  # tip
		_paint_gun_strip(atlas, cell, side)
	_paint_face(atlas, FACE_FRONT, _speckle(10, 10, GUN_RED, 0.1))
	_paint_face(atlas, FACE_BACK, _make_bore(10, _shade(GUN_STEEL, 1.3), 3.5))
	return atlas


## The machine gun's grenade in flight (scenes/grenade.tscn): 9 cm square
## and 18 cm long. A brass cartridge at the back, an olive body, and a
## brass-coloured nose. Drawn without lighting. Its sides are 18 x 9 pixels.
func _make_grenade() -> Image:
	var atlas := _new_atlas(18, 18)
	var paint := Color(0.30, 0.36, 0.20)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var side := _speckle(18, 9, paint, 0.06)
		side.fill_rect(Rect2i(0, 0, 6, 9), GUN_BRASS)  # cartridge
		side.fill_rect(Rect2i(0, 0, 1, 9), _shade(GUN_BRASS, 0.6))  # its rim
		side.fill_rect(Rect2i(12, 0, 1, 9), GUN_BLACK)
		side.fill_rect(Rect2i(13, 0, 5, 9), _shade(GUN_BRASS, 1.2))  # nose
		for x in 18:
			side.set_pixel(x, 1, _shade(side.get_pixel(x, 1), 1.25))  # a line of shine
		_paint_gun_strip(atlas, cell, side)
	_paint_face(atlas, FACE_FRONT, _speckle(9, 9, _shade(GUN_BRASS, 1.2), 0.07))
	var base := _speckle(9, 9, GUN_BRASS, 0.07)
	base.fill_rect(Rect2i(3, 3, 3, 3), _shade(GUN_BRASS, 0.5))  # primer
	_paint_face(atlas, FACE_BACK, base)
	return atlas


## The machine gun's bullet in flight (scenes/bullet.tscn): a glowing streak
## 3 cm square and 22 cm long, white-hot at the nose and cooling through
## yellow to orange at the tail. Drawn without lighting. Its sides are
## 24 x 3 pixels.
func _make_bullet() -> Image:
	var atlas := _new_atlas(24, 24)
	var tail := Color(1.0, 0.45, 0.1)
	var nose := Color(1.0, 1.0, 0.8)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var side := Image.create_empty(24, 3, false, Image.FORMAT_RGB8)
		for x in 24:
			# lerp blends two colours: 0 gives the first, 1 the second.
			var color := tail.lerp(Color(1.0, 0.92, 0.3), x / 23.0)
			if x >= 20:
				color = nose
			side.set_pixel(x, 0, _shade(color, 0.85))
			side.set_pixel(x, 1, color)
			side.set_pixel(x, 2, _shade(color, 0.85))
		_paint_gun_strip(atlas, cell, side)
	_paint_face(atlas, FACE_FRONT, _speckle(3, 3, nose, 0.0))
	_paint_face(atlas, FACE_BACK, _speckle(3, 3, tail, 0.0))
	return atlas
