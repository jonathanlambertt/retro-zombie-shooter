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
