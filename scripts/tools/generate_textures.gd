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
	# Rubble left by collapsing structures (scripts/structure.gd).
	_save(_make_rubble(), "rubble")
	# Lab furniture and wall dressing: test-map-2's control room and the
	# experimentation lab behind its window.
	_save(_make_bookshelf(), "bookshelf")
	_save(_make_server_rack(), "server_rack")
	_save(_make_filing_cabinet(), "filing_cabinet")
	_save(_make_leaves(), "leaves")
	_save(_make_terracotta(), "terracotta")
	_save(_make_poster_biohazard(), "poster_biohazard")
	_save(_make_poster_dna(), "poster_dna")
	_save(_make_poster_periodic(), "poster_periodic")
	_save(_make_poster_safety(), "poster_safety")
	_save(_make_poster_subject(), "poster_subject")
	_save(_make_poster_chart(), "poster_chart")
	_save(_make_whiteboard(), "whiteboard")
	_save(_make_sign_containment(), "sign_containment")
	for cell in range(1, 4):
		_save(_make_sign_cell(cell), "sign_cell_%d" % cell)
	# Desks (scenes/desk.tscn) and the breakable window glass
	# (scenes/breakable_glass.tscn).
	_save(_make_desk_top(), "desk_top")
	_save(_make_desk_steel(), "desk_steel")
	_save(_make_desk_drawers(), "desk_drawers")
	_save(_make_glass_crack(), "glass_crack")
	_save(_make_glass_edge(), "glass_edge")
	# The MP40 (scenes/mp40.tscn), and the stock only the player model's has.
	_save(_make_mp40_body(), "mp40_body")
	_save(_make_mp40_barrel(), "mp40_barrel")
	_save(_make_mp40_rest(), "mp40_rest")
	_save(_make_mp40_magazine(), "mp40_magazine")
	_save(_make_mp40_grip(), "mp40_grip")
	_save(_make_mp40_stock(), "mp40_stock")
	# What stands on and around the control room's desks: the monitors
	# (scenes/monitor.tscn) and what their screens show, the keyboards
	# (scenes/keyboard.tscn), the coffee cup (scenes/cup.tscn) and the water
	# cooler (scenes/water_cooler.tscn). Last, the printout taped up above
	# the infection rate poster.
	_save(_make_monitor(), "monitor")
	_save(_make_monitor_base(), "monitor_base")
	_save(_make_monitor_screen_cells(), "monitor_screen_cells")
	_save(_make_monitor_screen_vitals(), "monitor_screen_vitals")
	_save(_make_monitor_screen_pong(), "monitor_screen_pong")
	_save(_make_monitor_screen_signal(), "monitor_screen_signal")
	_save(_make_monitor_screen_breach(), "monitor_screen_breach")
	_save(_make_keyboard(), "keyboard")
	_save(_make_cup(), "cup")
	_save(_make_cup_handle(), "cup_handle")
	_save(_make_water_cooler(), "water_cooler")
	_save(_make_water_bottle(), "water_bottle")
	_save(_make_poster_chart_printout(), "poster_chart_printout")
	# One more monitor screen: somebody's program, on the two monitors of the
	# console in start-level-demo's control room.
	_save(_make_monitor_screen_code(), "monitor_screen_code")
	# And another: a longer program, too small to read, on the monitors of
	# the left and middle desks in the same room.
	_save(_make_monitor_screen_listing(), "monitor_screen_listing")
	# Three more ways for a pane of glass to break (glass_edge is the first),
	# so that panes side by side are not left with the same teeth.
	for variant in range(2, GLASS_EDGE_VARIANTS + 1):
		_save(_make_glass_edge_variant(variant), "glass_edge_%d" % variant)
	# The open pages of the notebook on the desk (scenes/notebook.tscn).
	_save(_make_notebook_page(), "notebook_page")
	# The Macintosh on the console in start-level-demo's control room
	# (scenes/macintosh.tscn): its case, the foot the case stands on, what its
	# screen shows, its keyboard and its mouse.
	_save(_make_macintosh(), "macintosh")
	_save(_make_macintosh_foot(), "macintosh_foot")
	_save(_make_macintosh_screen(), "macintosh_screen")
	_save(_make_macintosh_keyboard(), "macintosh_keyboard")
	_save(_make_macintosh_mouse(), "macintosh_mouse")
	# More for start-level-demo's control room: the infection rate poster
	# without its line of praise, a whiteboard about computers, and a blue
	# and yellow copy of the program too small to read.
	_save(_make_poster_chart(false), "poster_chart_plain")
	_save(_make_whiteboard_flowchart(), "whiteboard_flowchart")
	_save(_make_monitor_screen_listing(SCREEN_BLUE, SCREEN_YELLOW), "monitor_screen_listing_blue")
	# The control console in the middle of that room
	# (scenes/control_console.tscn): its cabinet, and the three sloping
	# panels of instruments along the back of its top.
	_save(_make_control_console(), "control_console")
	_save(_make_control_console_power(), "control_console_power")
	_save(_make_control_console_cells(), "control_console_cells")
	_save(_make_control_console_pulse(), "control_console_pulse")
	# The fire extinguisher on that room's south wall (its cylinder, and the
	# valve on top of it), and the poster hung along the wall from it.
	_save(_make_fire_extinguisher(), "fire_extinguisher")
	_save(_make_fire_extinguisher_valve(), "fire_extinguisher_valve")
	_save(_make_poster_penguin(), "poster_penguin")
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


## Broken concrete for rubble heaps: lumps of different shades with dark
## cracks between them. Each pixel belongs to the nearest of a handful of
## random points, which carves the image into irregular lumps; where two
## points are almost equally near, the pixel is on a crack. Distances wrap
## around the edges so the texture tiles.
func _make_rubble() -> Image:
	var image := _new_image()
	var base := Color(0.40, 0.38, 0.35)
	var centres: Array[Vector2] = []
	var shades: Array[float] = []
	for i in 18:
		centres.append(Vector2(rng.randf() * SIZE, rng.randf() * SIZE))
		shades.append(rng.randf_range(0.65, 1.15))
	for y in SIZE:
		for x in SIZE:
			var nearest := INF
			var second := INF
			var lump := 0
			for i in centres.size():
				var offset := (Vector2(x, y) - centres[i]).abs()
				# The shorter way round, so the edges join up.
				offset = Vector2(minf(offset.x, SIZE - offset.x), minf(offset.y, SIZE - offset.y))
				var distance := offset.length()
				if distance < nearest:
					second = nearest
					nearest = distance
					lump = i
				elif distance < second:
					second = distance
			var brightness := shades[lump] + rng.randf_range(-0.08, 0.08)
			if second - nearest < 1.5:
				brightness *= 0.35  # crack between two lumps
			elif nearest < 3.0:
				brightness *= 1.1  # a lighter, chipped middle
			image.set_pixel(x, y, _shade(base, brightness))
	return image


# --- Lab furniture -----------------------------------------------------------
#
# The bookshelf, server rack and filing cabinet are single boxes, so like the
# zombie they use BoxMesh atlases: the shelves, drawers and blinking lights
# are painted on the front, the way 1990s games drew bookcases.

const WOOD_DARK := Color(0.30, 0.19, 0.11)
const BOOK_COLORS := [
	Color(0.50, 0.10, 0.09), Color(0.13, 0.20, 0.42), Color(0.16, 0.34, 0.18),
	Color(0.42, 0.30, 0.15), Color(0.32, 0.32, 0.34), Color(0.62, 0.48, 0.14),
	Color(0.08, 0.08, 0.10), Color(0.55, 0.52, 0.45),
]
const PixelText := preload("res://scripts/pixel_text.gd")


## A board of wood "width" x "height" pixels, with grain running down it.
func _make_wood(width: int, height: int, base: Color) -> Image:
	var wood := _speckle(width, height, base, 0.05)
	for x in width:
		var streak := rng.randf_range(0.85, 1.12)
		for y in height:
			wood.set_pixel(x, y, _shade(wood.get_pixel(x, y), streak))
	return wood


## The bookshelf: 1.2 m wide, 2 m tall and 40 cm deep, 40 pixels to the
## metre. The front shows five shelves of books and binders in a wooden
## frame; the other sides are plain wood.
func _make_bookshelf() -> Image:
	var atlas := _new_atlas(48, 80)
	var front := _make_wood(48, 80, Color(0.38, 0.24, 0.14))
	var back_panel := Color(0.12, 0.08, 0.05)
	for shelf in 5:
		var top := 3 + shelf * 15
		var bottom := top + 12  # the row the books stand on
		front.fill_rect(Rect2i(3, top, 42, 13), back_panel)
		front.fill_rect(Rect2i(3, bottom + 1, 42, 2), Color(0.42, 0.27, 0.16))  # the shelf
		var x := 3
		while x < 45:
			var kind := rng.randf()
			if kind < 0.08:
				x += rng.randi_range(2, 5)  # a gap
			elif kind < 0.16 and x < 37:
				# A pile of books lying flat.
				var pile_width := rng.randi_range(6, 8)
				var layers := rng.randi_range(2, 4)
				for layer in layers:
					var color: Color = BOOK_COLORS[rng.randi() % BOOK_COLORS.size()]
					front.fill_rect(Rect2i(x, bottom - layer * 2 - 1, pile_width, 2), _shade(color, rng.randf_range(0.85, 1.15)))
				x += pile_width + 1
			elif kind < 0.28:
				# A ring binder: tall, pale, with a label and a finger hole.
				var color := Color(0.80, 0.80, 0.76) if rng.randf() < 0.6 else Color(0.25, 0.32, 0.55)
				front.fill_rect(Rect2i(x, bottom - 11, 4, 12), color)
				front.fill_rect(Rect2i(x + 1, bottom - 9, 2, 3), Color(0.95, 0.95, 0.90))
				front.set_pixel(x + 1, bottom - 3, _shade(color, 0.4))
				front.set_pixel(x + 2, bottom - 3, _shade(color, 0.4))
				x += 4
			else:
				var book_width := rng.randi_range(2, 3)
				var book_height := rng.randi_range(8, 12)
				var color: Color = BOOK_COLORS[rng.randi() % BOOK_COLORS.size()]
				color = _shade(color, rng.randf_range(0.8, 1.2))
				front.fill_rect(Rect2i(x, bottom - book_height + 1, book_width, book_height), color)
				# A band across the spine near the top, where the title goes.
				front.fill_rect(Rect2i(x, bottom - book_height + 3, book_width, 1), _shade(color, 1.6))
				front.fill_rect(Rect2i(x + book_width - 1, bottom - book_height + 1, 1, book_height), _shade(color, 0.7))
				x += book_width
		# Whatever ran past the frame is painted over by the frame below.
	# The frame: sides, top, and a plinth at the bottom.
	var frame := _make_wood(48, 80, Color(0.44, 0.28, 0.16))
	for rect in [Rect2i(0, 0, 3, 80), Rect2i(45, 0, 3, 80), Rect2i(0, 0, 48, 3), Rect2i(0, 76, 48, 4)]:
		front.blit_rect(frame, rect, rect.position)
	front.fill_rect(Rect2i(0, 79, 48, 1), _shade(WOOD_DARK, 0.6))
	_paint_face(atlas, FACE_FRONT, front)
	var side := _make_wood(16, 80, Color(0.42, 0.27, 0.16))
	_paint_face(atlas, FACE_LEFT, side)
	_paint_face(atlas, FACE_RIGHT, side)
	_paint_face(atlas, FACE_BACK, _make_wood(48, 80, WOOD_DARK))
	_paint_face(atlas, FACE_TOP, _make_wood(48, 16, Color(0.44, 0.28, 0.16)))
	_paint_face(atlas, FACE_BOTTOM, _make_wood(48, 16, WOOD_DARK))
	return atlas


## A dark metal panel with rows of vent slits, for the sides and top of the
## server rack.
func _make_vented_panel(width: int, height: int) -> Image:
	var panel := _speckle(width, height, Color(0.16, 0.17, 0.19), 0.06)
	for y in range(3, height - 3, 3):
		if y > height * 0.25 and y < height * 0.75:
			continue  # vents only near the top and bottom
		panel.fill_rect(Rect2i(3, y, width - 6, 1), Color(0.05, 0.05, 0.06))
	return panel


## The server rack: 60 cm wide, 2 m tall and 80 cm deep. The front is a
## stack of servers of different heights, each with a few status lights.
func _make_server_rack() -> Image:
	var atlas := _new_atlas(32, 80)
	var front := _speckle(24, 80, Color(0.07, 0.07, 0.08), 0.05)
	var lights := [Color(0.25, 1.0, 0.35), Color(0.25, 1.0, 0.35), Color(1.0, 0.72, 0.15), Color(0.35, 0.65, 1.0)]
	var y := 3
	while y < 75:
		var unit := [3, 3, 4, 6, 8][rng.randi() % 5] as int
		unit = mini(unit, 76 - y)
		var face := Color(0.30, 0.31, 0.34) if rng.randf() < 0.6 else Color(0.18, 0.19, 0.21)
		front.fill_rect(Rect2i(2, y, 20, unit - 1), _shade(face, rng.randf_range(0.9, 1.1)))
		front.fill_rect(Rect2i(2, y, 20, 1), _shade(face, 1.3))
		if unit >= 6 and rng.randf() < 0.5:
			# Drive bays.
			for bay in range(4, 20, 4):
				front.fill_rect(Rect2i(bay, y + 2, 3, unit - 4), _shade(face, 0.6))
		elif rng.randf() < 0.3:
			for vent in range(y + 1, y + unit - 1):
				if vent % 2 == 0:
					front.fill_rect(Rect2i(9, vent, 11, 1), _shade(face, 0.5))
		# Status lights down the left.
		for light in rng.randi_range(1, 3):
			front.set_pixel(3 + light * 2, y + 1, lights[rng.randi() % lights.size()])
		y += unit
	front.fill_rect(Rect2i(0, 0, 24, 2), Color(0.12, 0.12, 0.14))
	_paint_face(atlas, FACE_FRONT, front)
	_paint_face(atlas, FACE_LEFT, _make_vented_panel(32, 80))
	_paint_face(atlas, FACE_RIGHT, _make_vented_panel(32, 80))
	_paint_face(atlas, FACE_BACK, _make_vented_panel(24, 80))
	_paint_face(atlas, FACE_TOP, _make_vented_panel(24, 32))
	_paint_face(atlas, FACE_BOTTOM, _speckle(24, 32, Color(0.08, 0.08, 0.09), 0.05))
	return atlas


## The filing cabinet: 50 cm wide, 1.3 m tall and 60 cm deep. Four drawers,
## each with a handle and a little card label.
func _make_filing_cabinet() -> Image:
	var atlas := _new_atlas(24, 52)
	var steel := Color(0.56, 0.57, 0.52)
	var front := _speckle(20, 52, _shade(steel, 0.75), 0.04)
	for drawer in 4:
		var top := 1 + drawer * 12
		front.fill_rect(Rect2i(1, top, 18, 11), _shade(steel, rng.randf_range(0.98, 1.05)))
		front.fill_rect(Rect2i(1, top, 18, 1), _shade(steel, 1.25))
		front.fill_rect(Rect2i(7, top + 2, 6, 3), Color(0.88, 0.86, 0.78))  # label
		front.fill_rect(Rect2i(8, top + 3, 3, 1), Color(0.35, 0.35, 0.40))  # writing
		front.fill_rect(Rect2i(6, top + 6, 8, 1), Color(0.15, 0.15, 0.16))  # handle
		front.fill_rect(Rect2i(6, top + 7, 8, 1), _shade(steel, 0.55))
	front.fill_rect(Rect2i(0, 49, 20, 3), _shade(steel, 0.35))  # base
	_paint_face(atlas, FACE_FRONT, front)
	var side := _speckle(24, 52, steel, 0.04)
	side.fill_rect(Rect2i(0, 49, 24, 3), _shade(steel, 0.35))
	_paint_face(atlas, FACE_LEFT, side)
	_paint_face(atlas, FACE_RIGHT, side)
	_paint_face(atlas, FACE_BACK, _speckle(20, 52, steel, 0.04))
	_paint_face(atlas, FACE_TOP, _speckle(20, 24, _shade(steel, 1.1), 0.04))
	_paint_face(atlas, FACE_BOTTOM, _speckle(20, 24, _shade(steel, 0.3), 0.04))
	return atlas


## Leaves for the potted plants: clumps of different greens with dark gaps,
## made the same way as the rubble (each pixel joins the nearest of a set of
## random points), with distances wrapping round so the texture tiles.
func _make_leaves() -> Image:
	var image := _new_image()
	var centres: Array[Vector2] = []
	var shades: Array[float] = []
	for i in 60:
		centres.append(Vector2(rng.randf() * SIZE, rng.randf() * SIZE))
		shades.append(rng.randf_range(0.6, 1.35))
	var green := Color(0.20, 0.40, 0.14)
	for y in SIZE:
		for x in SIZE:
			var nearest := INF
			var second := INF
			var leaf := 0
			for i in centres.size():
				var offset := (Vector2(x, y) - centres[i]).abs()
				offset = Vector2(minf(offset.x, SIZE - offset.x), minf(offset.y, SIZE - offset.y))
				var distance := offset.length()
				if distance < nearest:
					second = nearest
					nearest = distance
					leaf = i
				elif distance < second:
					second = distance
			var brightness := shades[leaf] - nearest * 0.05
			if second - nearest < 1.0:
				brightness *= 0.4  # the shadow between two leaves
			image.set_pixel(x, y, _shade(green, brightness + rng.randf_range(-0.05, 0.05)))
	return image


## Unglazed clay for flower pots.
func _make_terracotta() -> Image:
	var image := _new_image()
	var clay := Color(0.62, 0.34, 0.20)
	var blotches := _make_blotch_grid(4)
	for y in SIZE:
		for x in SIZE:
			var brightness := 0.88 + 0.2 * _blotch(blotches, 4, x, y) + rng.randf_range(-0.05, 0.05)
			image.set_pixel(x, y, _shade(clay, brightness))
	return image


# --- Posters and signs -------------------------------------------------------
#
# Posters go on a QuadMesh (scenes/poster.tscn), whose UVs simply stretch the
# whole picture over the quad, so these are ordinary pictures. Their text
# uses the game's own 3x5 pixel font from scripts/pixel_text.gd.

## Writes text in the pixel font with its top-left corner at "at". Each font
## pixel is "scale" pixels across. Characters the font lacks become spaces.
func _draw_text(image: Image, text: String, at: Vector2i, color: Color, scale := 1) -> void:
	var x := at.x
	for character in text:
		if PixelText.GLYPHS.has(character):
			var rows: Array = PixelText.GLYPHS[character]
			for row in rows.size():
				var line: String = rows[row]
				for column in line.length():
					if line[column] == "#":
						image.fill_rect(Rect2i(x + column * scale, at.y + row * scale, scale, scale), color)
		x += 4 * scale


## The same, centred across the image.
func _draw_text_centred(image: Image, text: String, y: int, color: Color, scale := 1) -> void:
	var width := (text.length() * 4 - 1) * scale
	@warning_ignore("integer_division")
	_draw_text(image, text, Vector2i((image.get_width() - width) / 2, y), color, scale)


## A blank sheet of paper of the given colour, with a darker edge.
func _new_poster(width: int, height: int, paper: Color) -> Image:
	var poster := _speckle(width, height, paper, 0.04)
	for x in width:
		poster.set_pixel(x, 0, _shade(paper, 0.7))
		poster.set_pixel(x, height - 1, _shade(paper, 0.7))
	for y in height:
		poster.set_pixel(0, y, _shade(paper, 0.7))
		poster.set_pixel(width - 1, y, _shade(paper, 0.7))
	return poster


## A yellow warning poster with the biohazard symbol: three open rings
## around a small ring in the middle.
func _make_poster_biohazard() -> Image:
	var poster := _new_poster(48, 64, Color(0.86, 0.70, 0.12))
	var black := Color(0.08, 0.08, 0.07)
	poster.fill_rect(Rect2i(3, 3, 42, 9), Color(0.68, 0.10, 0.08))
	_draw_text_centred(poster, "DANGER", 5, Color(0.96, 0.93, 0.85))
	var centre := Vector2(23.5, 31.5)
	for y in range(14, 50):
		for x in range(3, 45):
			var point := Vector2(x, y)
			var offset := point - centre
			var on := false
			for lobe in 3:
				var angle := -PI / 2.0 + lobe * TAU / 3.0
				var direction := Vector2(cos(angle), sin(angle))
				# A ring of radius 8, with a hole pushed outwards so the ring
				# opens at its outer end.
				if point.distance_to(centre + direction * 7.0) < 8.5 \
						and point.distance_to(centre + direction * 10.0) > 5.5:
					on = true
			var radius := offset.length()
			if radius > 4.5 and radius < 6.5:
				on = true  # the small ring in the middle
			if radius < 2.0:
				on = false
			for lobe in 3:
				# Thin gaps where each ring meets the middle.
				var angle := -PI / 2.0 + lobe * TAU / 3.0 + PI
				var direction := Vector2(cos(angle), sin(angle))
				if radius < 8.0 and offset.dot(direction) > 0.0 and absf(offset.cross(direction)) < 0.8:
					on = false
			if on:
				poster.set_pixel(x, y, _shade(black, rng.randf_range(0.9, 1.3)))
	_draw_text_centred(poster, "BIOHAZARD", 54, black)
	return poster


## Dark blue science poster: a turning DNA ladder.
func _make_poster_dna() -> Image:
	var poster := _new_poster(48, 64, Color(0.10, 0.14, 0.30))
	var white := Color(0.92, 0.94, 0.96)
	var blue := Color(0.45, 0.80, 1.0)
	var rungs := [Color(0.85, 0.25, 0.20), Color(0.95, 0.80, 0.25), Color(0.35, 0.80, 0.35), Color(0.45, 0.80, 1.0)]
	_draw_text_centred(poster, "GENETICS", 4, white)
	for y in range(13, 52):
		var phase := (y - 13) * 0.3
		var a := 23.0 + 11.0 * sin(phase)
		var b := 23.0 - 11.0 * sin(phase)
		if (y - 13) % 3 == 1:
			@warning_ignore("integer_division")
			var color: Color = rungs[((y - 13) / 3) % rungs.size()]
			for x in range(int(minf(a, b)) + 2, int(maxf(a, b))):
				poster.set_pixel(x, y, _shade(color, 0.8))
		# The strand in front is brighter than the one behind.
		var a_in_front := cos(phase) > 0.0
		for strand in [[a, white, a_in_front], [b, blue, not a_in_front]]:
			var x := int(strand[0])
			var color: Color = strand[1]
			if not strand[2]:
				color = _shade(color, 0.55)
			poster.set_pixel(x, y, color)
			poster.set_pixel(x + 1, y, color)
	_draw_text_centred(poster, "DIVISION B", 56, _shade(white, 0.8))
	return poster


## The periodic table, in landscape: one coloured dot per element.
func _make_poster_periodic() -> Image:
	var poster := _new_poster(64, 48, Color(0.90, 0.89, 0.84))
	_draw_text_centred(poster, "PERIODIC TABLE", 3, Color(0.15, 0.17, 0.25))
	var alkali := Color(0.85, 0.30, 0.25)
	var earth := Color(0.92, 0.60, 0.25)
	var transition := Color(0.45, 0.58, 0.75)
	var metal := Color(0.60, 0.62, 0.62)
	var metalloid := Color(0.45, 0.70, 0.40)
	var nonmetal := Color(0.90, 0.80, 0.30)
	var halogen := Color(0.35, 0.78, 0.80)
	var noble := Color(0.62, 0.45, 0.78)
	for row in range(1, 8):
		for column in range(1, 19):
			var present := false
			match row:
				1:
					present = column == 1 or column == 18
				2, 3:
					present = column <= 2 or column >= 13
				_:
					present = true
			if not present:
				continue
			var color := transition
			if column == 1:
				color = nonmetal if row == 1 else alkali
			elif column == 2:
				color = earth
			elif column == 17:
				color = halogen
			elif column == 18:
				color = noble
			elif column >= 13:
				# Metals bottom left, non-metals top right, and the staircase
				# of metalloids between them.
				var stair := column - row
				color = metal if stair < 9 else (metalloid if stair == 9 else nonmetal)
			elif column == 3 and row >= 6:
				color = Color(0.85, 0.55, 0.70)  # where the two rows below fit in
			poster.fill_rect(Rect2i(5 + (column - 1) * 3, 10 + (row - 1) * 3, 2, 2), color)
	for row in 2:
		var color := Color(0.85, 0.55, 0.70) if row == 0 else Color(0.75, 0.40, 0.65)
		for column in range(4, 18):
			poster.fill_rect(Rect2i(5 + (column - 1) * 3, 33 + row * 3, 2, 2), color)
	return poster


## A green safety poster asking you to wear your goggles.
func _make_poster_safety() -> Image:
	var poster := _new_poster(48, 64, Color(0.93, 0.93, 0.90))
	var green := Color(0.12, 0.48, 0.25)
	poster.fill_rect(Rect2i(2, 2, 44, 18), green)
	_draw_text_centred(poster, "SAFETY", 4, Color(0.96, 0.96, 0.92))
	_draw_text_centred(poster, "FIRST", 12, Color(0.96, 0.96, 0.92))
	# The goggles: two lenses joined by a bridge, and the strap.
	var frame := Color(0.18, 0.18, 0.20)
	var lens := Color(0.55, 0.80, 0.92)
	poster.fill_rect(Rect2i(3, 31, 42, 2), frame)
	for centre_x in [15.5, 32.5]:
		for y in range(25, 40):
			for x in range(5, 44):
				var offset := Vector2((x - centre_x) / 7.5, (y - 32.0) / 6.0)
				var distance := offset.length()
				if distance < 0.8:
					poster.set_pixel(x, y, _shade(lens, 1.0 + offset.y * 0.3))
				elif distance < 1.05:
					poster.set_pixel(x, y, frame)
	_draw_text_centred(poster, "WEAR YOUR", 47, green)
	_draw_text_centred(poster, "GOGGLES", 54, green)
	return poster


## A clinical chart of "subject 07": a body with the bite marked in red and
## notes running off to the side.
func _make_poster_subject() -> Image:
	var poster := _new_poster(48, 64, Color(0.88, 0.85, 0.74))
	var ink := Color(0.20, 0.20, 0.25)
	var red := Color(0.72, 0.10, 0.08)
	var body := Color(0.55, 0.62, 0.68)
	_draw_text_centred(poster, "SUBJECT 07", 3, red)
	poster.fill_rect(Rect2i(4, 10, 40, 1), ink)
	# Head, neck, torso, arms and legs.
	for y in range(13, 22):
		for x in range(14, 24):
			if Vector2(x - 18.5, y - 17.0).length() < 4.0:
				poster.set_pixel(x, y, body)
	poster.fill_rect(Rect2i(17, 21, 3, 2), body)
	poster.fill_rect(Rect2i(13, 23, 11, 15), body)
	poster.fill_rect(Rect2i(10, 23, 3, 14), body)
	poster.fill_rect(Rect2i(24, 23, 3, 14), body)
	poster.fill_rect(Rect2i(13, 38, 4, 17), body)
	poster.fill_rect(Rect2i(20, 38, 4, 17), body)
	poster.fill_rect(Rect2i(15, 25, 3, 5), Color(0.80, 0.55, 0.55))  # lungs
	poster.fill_rect(Rect2i(19, 25, 3, 5), Color(0.80, 0.55, 0.55))
	poster.fill_rect(Rect2i(18, 27, 2, 2), Color(0.70, 0.15, 0.15))  # heart
	# Circles round the wounds, with lines out to the notes.
	for mark in [Vector2i(20, 22), Vector2i(25, 33), Vector2i(15, 46)]:
		for y in range(mark.y - 3, mark.y + 4):
			for x in range(mark.x - 3, mark.x + 4):
				var distance := Vector2(x - mark.x, y - mark.y).length()
				if distance > 2.0 and distance < 3.2:
					poster.set_pixel(x, y, red)
		poster.fill_rect(Rect2i(mark.x + 3, mark.y, 31 - mark.x, 1), red)
		poster.fill_rect(Rect2i(34, mark.y - 1, 9, 1), ink)
		poster.fill_rect(Rect2i(34, mark.y + 1, 6, 1), ink)
	_draw_text_centred(poster, "STAGE 3", 57, ink)
	return poster


## The red of the marker pen on the infection rate poster and its printout.
const POSTER_CHART_MARKER := Color(0.85, 0.08, 0.10)
## The column of the poster where that marker line (the left of its two
## pixels) runs off the top edge. The printout carries on from here.
const POSTER_CHART_MARKER_TOP := 62


## A line graph that shoots up: the infection rate over the days. It is a
## cheerful poster from personnel, printed when the line was still expected
## to stay on the paper. Since then:
## - a sticky note has been stuck on, pointing at the day it all took off;
## - the printed line reached the top of the grid, so somebody has carried
##   it on in red marker pen, past the title and off the top of the sheet.
##   In the control room it keeps going, up a length of printer paper taped
##   to the wall above (see _make_poster_chart_printout() at the end).
##
## Nothing here may use rng except the paper itself: this poster is made in
## the middle of the list, and drawing a different number of random numbers
## would change every texture made after it.
##
## "praise" is the line personnel had printed under the graph: GREAT JOB
## TEAM!, in green. The copy on the wall of start-level-demo's control room
## (poster_chart_plain, made at the end of the list) is printed without it.
func _make_poster_chart(praise := true) -> Image:
	var poster := _new_poster(64, 48, Color(0.93, 0.93, 0.91))
	var ink := Color(0.20, 0.22, 0.28)
	var grid := Color(0.75, 0.82, 0.90)
	var red := Color(0.78, 0.12, 0.10)
	_draw_text_centred(poster, "INFECTION RATE", 3, ink)
	for x in range(12, 61, 6):
		poster.fill_rect(Rect2i(x, 10, 1, 30), grid)
	for y in range(10, 40, 6):
		poster.fill_rect(Rect2i(7, y, 54, 1), grid)
	poster.fill_rect(Rect2i(6, 9, 1, 32), ink)
	poster.fill_rect(Rect2i(6, 40, 55, 1), ink)
	var previous := 39
	for x in range(7, 60):
		var t := (x - 7) / 52.0
		var y := int(round(39.0 - 29.0 * (exp(4.0 * t) - 1.0) / (exp(4.0) - 1.0)))
		# Fill any gap from the last column so the steep end stays joined.
		for fill in range(mini(y, previous), maxi(y, previous) + 1):
			poster.set_pixel(x, fill, red)
			poster.set_pixel(x, fill + 1, _shade(red, 0.8))
		previous = y

	# The marker pen: two pixels wide, starting where the printed line ends
	# (column 59, row 10) and leaning a little further right as it climbs,
	# so it leaves the top of the sheet at POSTER_CHART_MARKER_TOP.
	for y in range(9, -1, -1):
		@warning_ignore("integer_division")
		var lean := (9 - y) / 4
		poster.fill_rect(Rect2i(POSTER_CHART_MARKER_TOP - 2 + lean, y, 2, 1), POSTER_CHART_MARKER)

	# The sticky note, and a line from it down to the day the graph bends.
	var note := Color(0.98, 0.88, 0.30)
	poster.fill_rect(Rect2i(12, 16, 29, 7), note)
	poster.fill_rect(Rect2i(12, 22, 29, 1), _shade(note, 0.8))  # its bottom edge curling up
	_draw_text(poster, "HUG DAY", Vector2i(13, 17), ink)
	poster.fill_rect(Rect2i(30, 23, 1, 11), ink)
	for barb: Vector2i in [Vector2i(28, 31), Vector2i(32, 31), Vector2i(29, 32), Vector2i(31, 32)]:
		poster.set_pixel(barb.x, barb.y, ink)  # the arrowhead

	if praise:
		_draw_text_centred(poster, "GREAT JOB TEAM!", 42, Color(0.12, 0.48, 0.25))
	return poster


# The colours of the four marker pens that write on the whiteboards.
const MARKER_BLUE := Color(0.15, 0.25, 0.65)
const MARKER_RED := Color(0.75, 0.12, 0.10)
const MARKER_BLACK := Color(0.12, 0.12, 0.14)
const MARKER_GREEN := Color(0.12, 0.48, 0.25)


## A whiteboard with nothing written on it yet, 96 x 48 pixels for a board
## 2.4 m x 1.2 m: white, with the grey ghosts of things wiped off. Write on
## it, then give it its edges with _frame_whiteboard().
func _new_whiteboard() -> Image:
	var board := _speckle(96, 48, Color(0.90, 0.91, 0.90), 0.02)
	var smudges := _make_blotch_grid(6)
	for y in 48:
		for x in 96:
			@warning_ignore("integer_division")
			var smudge := _blotch(smudges, 6, x * 64 / 96, y * 64 / 48)
			if smudge > 0.7:
				board.set_pixel(x, y, _shade(board.get_pixel(x, y), 0.94))
	return board


## Puts the aluminium frame round a whiteboard, and the pen tray along the
## bottom with one pen lying in it for each colour in "pens".
func _frame_whiteboard(board: Image, pens: Array[Color]) -> void:
	for x in 96:
		for y in [0, 1, 45]:
			board.set_pixel(x, y, Color(0.62, 0.64, 0.67))
	for y in 48:
		for x in [0, 1, 94, 95]:
			board.set_pixel(x, y, Color(0.62, 0.64, 0.67))
	board.fill_rect(Rect2i(2, 46, 92, 2), Color(0.48, 0.50, 0.53))
	for pen in pens.size():
		# Each pen is six pixels long, with a gap of two before the next.
		board.fill_rect(Rect2i(30 + pen * 8, 45, 6, 1), pens[pen])


## The whiteboard in test-map-2's control room: notes in marker pen and a
## sketch of a tank.
func _make_whiteboard() -> Image:
	var board := _new_whiteboard()
	var blue := MARKER_BLUE
	var red := MARKER_RED
	var black := MARKER_BLACK
	_draw_text(board, "DAY 31", Vector2i(5, 5), blue)
	_draw_text(board, "DOSE > 40%", Vector2i(5, 13), black)
	_draw_text(board, "SUBJ 07 AWAKE!", Vector2i(5, 21), red)
	_draw_text(board, "KEEP CELL 3 SHUT", Vector2i(5, 29), red)
	board.fill_rect(Rect2i(5, 35, 63, 1), red)  # underlined
	# A sketch of a specimen tank, with an arrow pointing at it.
	board.fill_rect(Rect2i(74, 6, 12, 1), blue)
	board.fill_rect(Rect2i(74, 28, 12, 1), blue)
	board.fill_rect(Rect2i(75, 7, 1, 21), blue)
	board.fill_rect(Rect2i(84, 7, 1, 21), blue)
	for y in range(10, 25):
		board.set_pixel(80 + int(round(sin(y * 0.6))), y, black)  # someone inside
	board.fill_rect(Rect2i(62, 22, 10, 1), black)
	board.set_pixel(70, 21, black)
	board.set_pixel(70, 23, black)
	_draw_text(board, "WHY?", Vector2i(73, 32), red)
	var pens: Array[Color] = [red, blue]
	_frame_whiteboard(board, pens)
	return board


## The whiteboard in start-level-demo's control room, where whoever looked
## after the computers has drawn their job as a flowchart. Is there a bug?
## If not, ship it. If there is, have a coffee and look again. Beside it is
## a sketch of the cup and a count of the cups so far, in fives.
##
## A flowchart is the first thing a programmer is taught to draw, so the
## board says "computers" from across the room, before the words on it can
## be read.
func _make_whiteboard_flowchart() -> Image:
	var board := _new_whiteboard()
	_draw_text(board, "DEBUGGING", Vector2i(5, 4), MARKER_BLUE)
	board.fill_rect(Rect2i(5, 10, 35, 1), MARKER_BLUE)  # underlined

	# The question, and the arrow from it to the answer everyone wants.
	_draw_flowchart_box(board, "BUG?", Vector2i(12, 14), MARKER_BLACK)
	board.fill_rect(Rect2i(33, 18, 19, 1), MARKER_BLACK)
	_draw_arrowhead(board, Vector2i(51, 18), Vector2i.RIGHT, MARKER_BLACK)
	_draw_text(board, "NO", Vector2i(39, 12), MARKER_GREEN)
	_draw_flowchart_box(board, "SHIP IT!", Vector2i(53, 14), MARKER_GREEN)

	# The other answer: down to the coffee, and back up to ask again.
	board.fill_rect(Rect2i(19, 23, 1, 9), MARKER_BLACK)
	_draw_arrowhead(board, Vector2i(19, 31), Vector2i.DOWN, MARKER_BLACK)
	_draw_text(board, "YES", Vector2i(5, 25), MARKER_RED)
	_draw_flowchart_box(board, "COFFEE", Vector2i(8, 33), MARKER_BLACK)
	board.fill_rect(Rect2i(28, 23, 1, 10), MARKER_BLACK)
	_draw_arrowhead(board, Vector2i(28, 23), Vector2i.UP, MARKER_BLACK)

	# The cup: its rim, its two sides, its base and its handle, with two
	# wisps of steam above it.
	board.fill_rect(Rect2i(43, 33, 8, 1), MARKER_BLUE)
	board.fill_rect(Rect2i(43, 34, 1, 6), MARKER_BLUE)
	board.fill_rect(Rect2i(50, 34, 1, 6), MARKER_BLUE)
	board.fill_rect(Rect2i(44, 40, 6, 1), MARKER_BLUE)
	for handle: Vector2i in [Vector2i(51, 35), Vector2i(52, 36), Vector2i(52, 37), Vector2i(51, 38)]:
		board.set_pixelv(handle, MARKER_BLUE)
	for wisp: int in [45, 48]:
		for step in 4:
			# Each wisp wavers one pixel from side to side on its way up.
			board.set_pixel(wisp + step % 2, 31 - step, MARKER_BLUE)

	# The count: two full fives (four strokes with a fifth across them) and
	# two strokes of the next. Each stroke is a pixel wide and seven tall.
	_draw_text(board, "CUPS:", Vector2i(58, 27), MARKER_RED)
	for five in 2:
		var left := 58 + five * 12
		for stroke in 4:
			board.fill_rect(Rect2i(left + stroke * 2, 34, 1, 7), MARKER_RED)
		for step in 9:
			# The fifth stroke climbs one pixel for every two it goes along.
			@warning_ignore("integer_division")
			board.set_pixel(left - 1 + step, 39 - step / 2, MARKER_RED)
	for stroke in 2:
		board.fill_rect(Rect2i(82 + stroke * 2, 34, 1, 7), MARKER_RED)

	var pens: Array[Color] = [MARKER_RED, MARKER_BLUE, MARKER_GREEN, MARKER_BLACK]
	_frame_whiteboard(board, pens)
	return board


## Draws a box of a flowchart with its top-left corner at "at": the text,
## with two clear pixels all round it inside a line one pixel thick. That
## makes every box nine pixels tall.
func _draw_flowchart_box(image: Image, text: String, at: Vector2i, color: Color) -> void:
	var size := Vector2i(text.length() * 4 - 1 + 6, 9)
	image.fill_rect(Rect2i(at.x, at.y, size.x, 1), color)
	image.fill_rect(Rect2i(at.x, at.y + size.y - 1, size.x, 1), color)
	image.fill_rect(Rect2i(at.x, at.y, 1, size.y), color)
	image.fill_rect(Rect2i(at.x + size.x - 1, at.y, 1, size.y), color)
	_draw_text(image, text, at + Vector2i(3, 2), color)


## Draws the head of an arrow whose point is the pixel at "tip", for a line
## that arrives there travelling in "direction" (Vector2i.RIGHT, DOWN or
## UP): two pixels either side of the line, sloping back from the point.
func _draw_arrowhead(image: Image, tip: Vector2i, direction: Vector2i, color: Color) -> void:
	# Swapping x and y turns the direction a quarter of the way round, which
	# gives the way across the line.
	var across := Vector2i(direction.y, direction.x)
	for step in range(1, 3):
		image.set_pixelv(tip - direction * step + across * step, color)
		image.set_pixelv(tip - direction * step - across * step, color)
	image.set_pixelv(tip, color)


## The stencilled sign over the specimen tanks: yellow on black, 4 m x 0.5 m.
func _make_sign_containment() -> Image:
	var sign := _speckle(128, 16, Color(0.12, 0.12, 0.13), 0.05)
	var yellow := Color(0.86, 0.70, 0.12)
	sign.fill_rect(Rect2i(1, 1, 126, 1), yellow)
	sign.fill_rect(Rect2i(1, 14, 126, 1), yellow)
	_draw_text_centred(sign, "CONTAINMENT LAB", 3, yellow, 2)
	return sign


## The number plate over a holding cell: "CELL 1" in yellow on black,
## 80 cm x 25 cm.
func _make_sign_cell(number: int) -> Image:
	var sign := _speckle(32, 10, Color(0.12, 0.12, 0.13), 0.05)
	_draw_text_centred(sign, "CELL %d" % number, 3, Color(0.86, 0.70, 0.12))
	return sign


# --- Desks -------------------------------------------------------------------

const DESK_STEEL := Color(0.47, 0.50, 0.46)


## Wood-effect laminate for desk tops: pale streaks running the length of
## the desk, with darker lines of grain waving gently across them.
func _make_desk_top() -> Image:
	var image := _new_image()
	var wood := Color(0.56, 0.40, 0.24)
	var blotches := _make_blotch_grid(4)
	var streaks := PackedFloat32Array()
	for y in SIZE:
		streaks.append(rng.randf_range(0.9, 1.08))
	for y in SIZE:
		for x in SIZE:
			var brightness := streaks[y] * (0.92 + 0.12 * _blotch(blotches, 4, x, y))
			brightness += rng.randf_range(-0.03, 0.03)
			# The wave repeats twice across the texture so its edges still
			# meet when it tiles.
			var wave := int(round(sin(x * TAU / 32.0 + y * 0.7) * 1.5))
			if posmod(y + wave, 8) == 0:
				brightness *= 0.72
			image.set_pixel(x, y, _shade(wood, brightness))
	return image


## Painted sheet steel for desk frames, consoles and benches: the grey-green
## of old office furniture, with a few pale scuffs.
func _make_desk_steel() -> Image:
	var image := _new_image()
	var blotches := _make_blotch_grid(4)
	for y in SIZE:
		for x in SIZE:
			var brightness := 0.95 + 0.08 * _blotch(blotches, 4, x, y) + rng.randf_range(-0.025, 0.025)
			image.set_pixel(x, y, _shade(DESK_STEEL, brightness))
	for scuff in 6:
		var start := Vector2i(rng.randi() % SIZE, rng.randi() % SIZE)
		for step in rng.randi_range(3, 7):
			image.set_pixel((start.x + step) % SIZE, start.y, _shade(DESK_STEEL, 1.25))
	return image


## The drawer pedestal under one end of a desk: 45 cm wide, 75 cm tall and
## 92 cm deep, 40 pixels to the metre. The front has a shallow drawer above
## two deep file drawers, each with a handle.
func _make_desk_drawers() -> Image:
	var atlas := _new_atlas(36, 30)
	var front := _speckle(18, 30, _shade(DESK_STEEL, 0.7), 0.03)
	for drawer: Vector2i in [Vector2i(1, 6), Vector2i(8, 10), Vector2i(19, 10)]:
		var top := drawer.x
		var height := drawer.y
		front.fill_rect(Rect2i(1, top, 16, height), _shade(DESK_STEEL, rng.randf_range(0.98, 1.04)))
		front.fill_rect(Rect2i(1, top, 16, 1), _shade(DESK_STEEL, 1.2))  # light on the top edge
		var handle := top + (2 if height < 8 else 3)
		front.fill_rect(Rect2i(5, handle, 8, 1), Color(0.12, 0.12, 0.13))
		front.fill_rect(Rect2i(5, handle + 1, 8, 1), _shade(DESK_STEEL, 1.35))
		if height >= 8:
			front.fill_rect(Rect2i(7, top + 6, 4, 2), Color(0.86, 0.84, 0.76))  # card label
	front.fill_rect(Rect2i(0, 29, 18, 1), _shade(DESK_STEEL, 0.4))  # kick plate
	_paint_face(atlas, FACE_FRONT, front)
	var side := _speckle(36, 30, DESK_STEEL, 0.03)
	side.fill_rect(Rect2i(0, 29, 36, 1), _shade(DESK_STEEL, 0.4))
	_paint_face(atlas, FACE_LEFT, side)
	_paint_face(atlas, FACE_RIGHT, side)
	_paint_face(atlas, FACE_BACK, _speckle(18, 30, DESK_STEEL, 0.03))
	_paint_face(atlas, FACE_TOP, _speckle(18, 36, DESK_STEEL, 0.03))
	_paint_face(atlas, FACE_BOTTOM, _speckle(18, 36, _shade(DESK_STEEL, 0.4), 0.03))
	return atlas


# --- Breakable glass ---------------------------------------------------------
#
# Both are white on a see-through background: the glass's materials tint
# them and make them partly transparent.

## How many numbers the first version of the crack below (a spider's web)
## took from rng. See _make_glass_crack() for why that still matters.
const GLASS_CRACK_OLD_DRAWS := 612


## Marks one pixel of a crack, if it is inside the image. "strength" is how
## solid it is, from 0 (not there) to 1; a pixel is never made fainter.
func _crack_pixel(image: Image, point: Vector2, strength: float) -> void:
	var x := floori(point.x)
	var y := floori(point.y)
	if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
		if image.get_pixel(x, y).a < strength:
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, strength))


## Draws one straight piece of a crack from "from" to "to", fading from one
## strength to the other along the way.
func _crack_run(image: Image, from: Vector2, to: Vector2, strength_from: float, strength_to: float) -> void:
	# Two samples per pixel of length, so no pixel on the way is skipped.
	var steps := ceili(from.distance_to(to) * 2.0) + 1
	for step in steps + 1:
		var t := float(step) / steps
		_crack_pixel(image, from.lerp(to, t), lerpf(strength_from, strength_to, t))


## A bullet's mark in a pane of glass: a small hole punched through it, in a
## patch of crushed white glass, with five splits running out from it. The
## splits are straight with a sharp bend or two, of very different lengths
## and unevenly spaced, and the long ones fork. Nothing joins one split to
## the next: rings round the hole are what made the first version of this
## picture look like a spider's web.
func _make_glass_crack() -> Image:
	# Every texture made after this one is drawn with whatever numbers rng
	# gives next, so they all depend on how many this one takes. The first
	# version took 612. Take the same 612 here and throw them away, and draw
	# the crack with a generator of its own instead. That way the crack can be
	# redrawn (as it has been once already) without the MP40, the monitors
	# and everything else further down the list coming out different.
	for i in GLASS_CRACK_OLD_DRAWS:
		rng.randf()
	var dice := RandomNumberGenerator.new()
	dice.seed = 9  # another number here draws another crack

	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)  # all see-through
	var centre := Vector2(32.0, 32.0)

	# How long each split is, in pixels: two long, one middling, two short, in
	# a shuffled order so the long ones are not always side by side.
	var lengths: Array[float] = [28.0, 21.0, 14.0, 9.0, 6.0]
	for i in range(lengths.size() - 1, 0, -1):
		var j := dice.randi_range(0, i)
		var kept := lengths[i]
		lengths[i] = lengths[j]
		lengths[j] = kept
	# Which way each one runs: unevenly spaced round the circle. Each gap is
	# between half and one and a half times the average, then all are scaled
	# so that together they go once round.
	var gaps: Array[float] = []
	var total := 0.0
	for i in lengths.size():
		gaps.append(dice.randf_range(0.5, 1.5))
		total += gaps[i]
	var angles: Array[float] = [dice.randf() * TAU]
	for i in lengths.size() - 1:
		angles.append(angles[i] + gaps[i] / total * TAU)

	# Flakes: the glass between two neighbouring splits has chipped away near
	# the hole, leaving a faint wedge. Not between every pair.
	for i in lengths.size():
		if dice.randf() < 0.5:
			continue
		var from := angles[i]
		var to := angles[(i + 1) % angles.size()] + (TAU if i == angles.size() - 1 else 0.0)
		var reach := dice.randf_range(5.0, 8.0)
		for y in SIZE:
			for x in SIZE:
				var offset := Vector2(x + 0.5, y + 0.5) - centre
				# How far round from the first split this pixel is, 0 to TAU.
				var turn := fposmod(offset.angle() - from, TAU)
				if offset.length() < reach and turn < to - from:
					_crack_pixel(image, Vector2(x, y), 0.4)

	for i in lengths.size():
		var angle := angles[i]
		var length := lengths[i] * dice.randf_range(0.9, 1.1)
		var point := centre + Vector2.from_angle(angle) * 2.0
		var travelled := 0.0
		var side := 1.0 if dice.randf() < 0.5 else -1.0
		var forked := length < 18.0  # only the long ones fork
		while travelled < length:
			# A straight run, then a sharp bend back across the split's line.
			# (A short split is one run, with no bend.)
			var run := length - travelled
			if length > 12.0:
				run = minf(length * dice.randf_range(0.4, 0.6), run)
			var heading := angle + side * dice.randf_range(0.08, 0.3)
			side = -side
			var end := point + Vector2.from_angle(heading) * run
			# Solid at the hole, fading to a little over half at the tip.
			var strength_from := lerpf(1.0, 0.6, travelled / length)
			var strength_to := lerpf(1.0, 0.6, (travelled + run) / length)
			_crack_run(image, point, end, strength_from, strength_to)
			if travelled < length * 0.35 and length > 12.0:
				# Wider where it leaves the hole: a second line alongside.
				var across := Vector2.from_angle(heading + PI / 2.0)
				_crack_run(image, point + across, end + across, strength_from, strength_to)
			travelled += run
			point = end
			if not forked and travelled > length * 0.4:
				# A shorter split leaves the bend, heading off to one side.
				forked = true
				var fork_heading := angle - side * dice.randf_range(0.45, 0.8)
				var fork_end := point + Vector2.from_angle(fork_heading) * dice.randf_range(6.0, 10.0)
				_crack_run(image, point, fork_end, strength_to, 0.5)

	# The middle: crushed glass, solid white close in and thinning to loose
	# flecks, round the hole the bullet made.
	for y in SIZE:
		for x in SIZE:
			var distance := Vector2(x + 0.5, y + 0.5).distance_to(centre)
			if distance < 3.0:
				image.set_pixel(x, y, Color.WHITE)
			elif distance < 6.5 and dice.randf() < 0.45 * (1.0 - (distance - 3.0) / 3.5):
				_crack_pixel(image, Vector2(x, y), dice.randf_range(0.7, 1.0))
	for y in range(30, 34):
		for x in range(30, 34):
			if Vector2(x + 0.5, y + 0.5).distance_to(centre) < 1.5:
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, 0.0))  # the hole itself
	return image


## How many numbers the first version of the picture below (one row of
## saw teeth, the same for every pane) took from rng, and how many different
## pictures there are now.
const GLASS_EDGE_OLD_DRAWS := 88
const GLASS_EDGE_VARIANTS := 4


## What is left in the frame once a pane has shattered. This is the first of
## several different breaks: see _make_glass_edge_variant(). Like the crack
## above, it throws away the numbers its first version took from rng, so
## that the textures made after it come out the same as they always have.
func _make_glass_edge() -> Image:
	for i in GLASS_EDGE_OLD_DRAWS:
		rng.randf()
	return _make_glass_edge_variant(1)


## Broken glass still held in a frame: a sliver all the way round, shards of
## every size sticking in from it (the longest hang from the top), and here
## and there a bigger piece wedged in a corner. The middle is see-through.
## "variant" is which break to draw, from 1 up: each number gives a
## different one, and scripts/breakable_glass.gd shares them out among the
## panes of a level. Each has a generator of its own, like the crack.
func _make_glass_edge_variant(variant: int) -> Image:
	var dice := RandomNumberGenerator.new()
	dice.seed = variant
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)  # all see-through
	for side in 4:
		# The four edges in turn: top, bottom, left and right. The longest
		# shards hang from the top of the frame; the ones left standing along
		# the bottom and down the sides are shorter.
		var tallest: float = [18.0, 15.0, 11.0, 11.0][side]
		# How far the glass still reaches in from each pixel along this edge.
		# There is always a sliver left in the frame's groove.
		var depth: Array[float] = []
		depth.resize(SIZE)
		depth.fill(1.0)
		var along := dice.randf_range(-4.0, 0.0)
		while along < SIZE:
			# One shard: a triangle this wide at the frame, with its point
			# nearer one end than the other. Most are stubs; two in five are
			# long.
			var width := dice.randf_range(4.0, 12.0)
			var height := dice.randf_range(2.0, 6.0)
			if dice.randf() < 0.4:
				height = dice.randf_range(tallest * 0.5, tallest)
			var tip := along + width * dice.randf_range(0.2, 0.8)
			for x in range(maxi(floori(along), 0), mini(ceili(along + width), SIZE)):
				# How far up the shard its edge is at this pixel: 0 at either
				# end of its foot, 1 at the tip.
				var middle := x + 0.5
				var rise := (middle - along) / (tip - along)
				if middle > tip:
					rise = (along + width - middle) / (along + width - tip)
				depth[x] = maxf(depth[x], height * clampf(rise, 0.0, 1.0))
			# The next one starts where this one ends, give or take, and now
			# and then after a gap where the glass broke off clean.
			along += width * dice.randf_range(0.7, 1.1)
			if dice.randf() < 0.2:
				along += dice.randf_range(3.0, 8.0)
		for x in SIZE:
			for inward in roundi(depth[x]):
				var pixel := Vector2i(x, inward)
				match side:
					1:
						pixel = Vector2i(x, SIZE - 1 - inward)
					2:
						pixel = Vector2i(inward, x)
					3:
						pixel = Vector2i(SIZE - 1 - inward, x)
				image.set_pixel(pixel.x, pixel.y, Color.WHITE)

	# A bigger piece is often left wedged in a corner: a triangle with one
	# side along each edge of the frame.
	for corner in 4:
		if dice.randf() < 0.5:
			continue
		var across := dice.randf_range(8.0, 20.0)
		var down := dice.randf_range(8.0, 20.0)
		for y in ceili(down):
			for x in ceili(across):
				if (x + 0.5) / across + (y + 0.5) / down < 1.0:
					# Corners in the order top left, top right, bottom left,
					# bottom right.
					var pixel := Vector2i(x if corner % 2 == 0 else SIZE - 1 - x, y if corner < 2 else SIZE - 1 - y)
					image.set_pixelv(pixel, Color.WHITE)

	# A broken edge catches the light. The pixels along it stay solid white;
	# the glass behind them is made dimmer and a little more see-through.
	var solid: Image = image.duplicate()
	for y in SIZE:
		for x in SIZE:
			if solid.get_pixel(x, y).a == 0.0:
				continue
			var on_edge := false
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var beside := Vector2i(x, y) + step
				# (Past the edge of the picture is the frame, not a broken edge.)
				if beside.x >= 0 and beside.y >= 0 and beside.x < SIZE and beside.y < SIZE:
					if solid.get_pixelv(beside).a == 0.0:
						on_edge = true
			if not on_edge:
				image.set_pixel(x, y, Color(0.8, 0.8, 0.8, 0.8))
	return image


# --- The MP40 ------------------------------------------------------------------
#
# The MP40 (scenes/mp40.tscn) is the machine gun in a different skin: the
# German submachine gun of the Second World War. It is a tube of dark blued
# steel on a lower half of red-brown bakelite (an early plastic), with a
# long straight magazine hanging from a ribbed housing in front of the
# trigger, and a bar under the barrel for resting the gun on the edge of a
# vehicle. Its boxes are painted the same way as the machine gun's.

const MP40_BAKELITE := Color(0.30, 0.14, 0.07)


## The body of the gun: 5 cm wide, 8 cm tall and 34 cm long. From the back:
## the end cap of the tube (4 pixels), the receiver over its bakelite lower
## half, the ribbed magazine housing, and the collar the barrel screws
## into. The sides are 48 x 12 pixels.
func _make_mp40_body() -> Image:
	var atlas := _new_atlas(48, 48)
	_paint_gun_strip(atlas, FACE_RIGHT, _make_mp40_body_side(true))
	_paint_gun_strip(atlas, FACE_LEFT, _make_mp40_body_side(false))

	# The top, which is most of what you see of the gun in your hands: 8
	# pixels across, the back at the top. The receiver is a round tube, so
	# light runs along its middle and its edges fall into shadow.
	var top := _speckle(8, 48, GUN_BLUED, 0.07)
	for y in 48:
		for x: int in [3, 4]:
			top.set_pixel(x, y, _shade(top.get_pixel(x, y), 1.5))
		for x: int in [0, 7]:
			top.set_pixel(x, y, _shade(top.get_pixel(x, y), 0.6))
	top.fill_rect(Rect2i(0, 3, 8, 1), _shade(GUN_BLUED, 0.5))  # end cap seam
	# The rear sight: two posts with a notch between them.
	top.fill_rect(Rect2i(1, 8, 6, 2), GUN_WORN)
	top.fill_rect(Rect2i(3, 8, 2, 2), GUN_BLACK)
	top.fill_rect(Rect2i(0, 30, 8, 1), _shade(GUN_BLUED, 0.5))  # seam
	for y in range(32, 40, 2):
		top.fill_rect(Rect2i(1, y, 6, 1), _shade(GUN_BLUED, 0.55))  # housing rib
	top.fill_rect(Rect2i(0, 41, 8, 1), _shade(GUN_BLUED, 0.5))  # seam
	top.fill_rect(Rect2i(0, 44, 8, 1), _shade(GUN_WORN, 0.8))  # barrel collar
	_paint_face(atlas, FACE_TOP, top)

	# The underside: bakelite between the end cap and the magazine housing.
	var bottom := _speckle(8, 48, _shade(GUN_BLUED, 0.7), 0.07)
	bottom.blit_rect(_speckle(8, 27, _shade(MP40_BAKELITE, 0.8), 0.1), Rect2i(0, 0, 8, 27), Vector2i(0, 4))
	_paint_face(atlas, FACE_BOTTOM, bottom)

	# The back: the round cap on the end of the tube, over the bakelite.
	var back := _speckle(8, 12, GUN_BLUED, 0.07)
	back.fill_rect(Rect2i(2, 1, 4, 5), _shade(GUN_BLUED, 1.5))
	back.fill_rect(Rect2i(3, 2, 2, 3), GUN_BLUED)
	back.blit_rect(_speckle(8, 5, MP40_BAKELITE, 0.1), Rect2i(0, 0, 8, 5), Vector2i(0, 7))
	_paint_face(atlas, FACE_BACK, back)
	# The barrel covers most of the front.
	_paint_face(atlas, FACE_FRONT, _speckle(8, 12, GUN_BLUED, 0.07))
	return atlas


## One side of the body. Spent cartridges are thrown out of the right side,
## so that one has the opening for them (ejection_port); the left side has
## the long slot the cocking handle slides in instead.
func _make_mp40_body_side(ejection_port: bool) -> Image:
	var side := _make_gun_strip(48, 12, GUN_BLUED)
	for x in 48:
		# A band of light along the upper curve of the tube.
		side.set_pixel(x, 2, _shade(side.get_pixel(x, 2), 1.4))
	side.fill_rect(Rect2i(3, 0, 1, 12), _shade(GUN_BLUED, 0.5))  # end cap seam
	# The bakelite lower half, from the end cap to the magazine housing.
	side.blit_rect(_speckle(27, 5, MP40_BAKELITE, 0.1), Rect2i(0, 0, 27, 5), Vector2i(4, 7))
	side.fill_rect(Rect2i(4, 6, 27, 1), _shade(GUN_BLUED, 0.5))  # where it meets the tube
	side.fill_rect(Rect2i(4, 11, 27, 1), _shade(MP40_BAKELITE, 0.6))  # underside in shadow
	side.fill_rect(Rect2i(5, 8, 2, 2), GUN_WORN)  # the pivot the stock folds on
	for screw: Vector2i in [Vector2i(13, 9), Vector2i(27, 9)]:
		side.set_pixel(screw.x, screw.y, _shade(GUN_WORN, 0.8))
	# The magazine housing: pressed steel with ribs down it.
	side.fill_rect(Rect2i(31, 3, 1, 9), _shade(GUN_BLUED, 0.5))  # seam
	for x in range(33, 40, 2):
		side.fill_rect(Rect2i(x, 5, 1, 6), _shade(GUN_BLUED, 0.55))  # rib
	side.fill_rect(Rect2i(41, 0, 1, 12), _shade(GUN_BLUED, 0.5))  # seam
	side.fill_rect(Rect2i(44, 0, 1, 12), _shade(GUN_WORN, 0.8))  # barrel collar
	if ejection_port:
		side.fill_rect(Rect2i(23, 1, 7, 4), GUN_BLACK)
		side.fill_rect(Rect2i(23, 5, 7, 1), GUN_WORN)  # its worn lower lip
	else:
		side.fill_rect(Rect2i(13, 3, 23, 1), GUN_BLACK)  # cocking slot
		side.fill_rect(Rect2i(29, 2, 2, 3), GUN_WORN)  # the cocking handle in it
	return side


## The barrel: 2.5 cm square and 20 cm long. Thin and bare, with a nut at
## each end and the block that carries the front sight just behind the
## muzzle. Its sides are 28 x 4 pixels.
func _make_mp40_barrel() -> Image:
	var atlas := _new_atlas(28, 28)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var side := _make_gun_strip(28, 4, _shade(GUN_BLUED, 0.9))
		side.fill_rect(Rect2i(0, 0, 2, 4), _shade(GUN_WORN, 0.7))  # barrel nut
		side.fill_rect(Rect2i(20, 0, 3, 4), GUN_POLYMER)  # front sight block
		if cell == FACE_TOP:
			side.fill_rect(Rect2i(21, 1, 1, 2), GUN_WORN)  # the sight's blade
		side.fill_rect(Rect2i(26, 0, 2, 4), _shade(GUN_WORN, 0.8))  # muzzle nut
		_paint_gun_strip(atlas, cell, side)

	# The muzzle: a ring of steel around the black bore.
	var muzzle := _speckle(4, 4, _shade(GUN_WORN, 0.8), 0.07)
	muzzle.fill_rect(Rect2i(1, 1, 2, 2), GUN_BLACK)
	_paint_face(atlas, FACE_FRONT, muzzle)
	_paint_face(atlas, FACE_BACK, _speckle(4, 4, GUN_BLUED, 0.07))
	return atlas


## The resting bar under the barrel: 2 cm wide, 3 cm tall and 12 cm long.
## Bakelite, with a steel hook at the front that catches on whatever the
## gun is rested on. Its sides are 16 x 4 pixels.
func _make_mp40_rest() -> Image:
	var atlas := _new_atlas(16, 16)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var side := _make_gun_strip(16, 4, MP40_BAKELITE)
		side.fill_rect(Rect2i(13, 0, 3, 4), GUN_BLUED)  # hook
		side.fill_rect(Rect2i(12, 0, 1, 4), _shade(MP40_BAKELITE, 0.5))  # seam
		_paint_gun_strip(atlas, cell, side)
	_paint_face(atlas, FACE_FRONT, _speckle(4, 4, GUN_BLUED, 0.07))
	_paint_face(atlas, FACE_BACK, _speckle(4, 4, MP40_BAKELITE, 0.1))
	return atlas


## The magazine: 3 cm wide, 20 cm tall and 4.5 cm deep. Long and perfectly
## straight, with a groove pressed down each side to stiffen it and a dark
## base plate. Each side is 6 x 28 pixels.
func _make_mp40_magazine() -> Image:
	var atlas := _new_atlas(6, 28)
	for cell: Vector2i in [FACE_FRONT, FACE_BACK, FACE_RIGHT, FACE_LEFT]:
		var side := _speckle(6, 28, GUN_BLUED, 0.07)
		side.fill_rect(Rect2i(0, 0, 1, 28), _shade(GUN_BLUED, 1.4))  # worn edges
		side.fill_rect(Rect2i(5, 0, 1, 28), _shade(GUN_BLUED, 0.7))
		side.fill_rect(Rect2i(2, 3, 2, 20), _shade(GUN_BLUED, 0.55))  # groove
		side.fill_rect(Rect2i(0, 25, 6, 3), GUN_POLYMER)  # base plate
		side.fill_rect(Rect2i(0, 25, 6, 1), GUN_WORN)  # its top edge
		_paint_face(atlas, cell, side)
	# The top is inside the gun; the bottom is the underside of the base plate.
	_paint_face(atlas, FACE_TOP, _speckle(6, 6, GUN_POLYMER, 0.1))
	_paint_face(atlas, FACE_BOTTOM, _speckle(6, 6, GUN_POLYMER, 0.1))
	return atlas


## The pistol grip: 4.5 cm wide, 10 cm tall and 5 cm deep. A steel frame
## with a smooth bakelite panel screwed to each side. Each side is 6 x 14.
func _make_mp40_grip() -> Image:
	var atlas := _new_atlas(6, 14)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT]:
		var side := _speckle(6, 14, MP40_BAKELITE, 0.12)
		side.fill_rect(Rect2i(0, 0, 1, 14), GUN_BLUED)  # the frame, front and back
		side.fill_rect(Rect2i(5, 0, 1, 14), GUN_BLUED)
		side.set_pixel(3, 6, GUN_WORN)  # screw
		side.fill_rect(Rect2i(0, 13, 6, 1), _shade(GUN_BLUED, 1.4))  # end cap
		_paint_face(atlas, cell, side)
	for cell: Vector2i in [FACE_FRONT, FACE_BACK]:
		_paint_face(atlas, cell, _speckle(6, 14, GUN_BLUED, 0.07))
	_paint_face(atlas, FACE_TOP, _speckle(6, 7, GUN_BLUED, 0.07))
	_paint_face(atlas, FACE_BOTTOM, _speckle(6, 7, GUN_BLUED, 0.07))
	return atlas


## The shoulder stock of the MP40 the player model carries: the same size as
## the machine gun's, but two thin steel bars with nothing between them and
## a steel plate for the shoulder.
func _make_mp40_stock() -> Image:
	var atlas := _new_atlas(24, 24)
	for cell: Vector2i in [FACE_RIGHT, FACE_LEFT, FACE_TOP, FACE_BOTTOM]:
		var upright := cell == FACE_RIGHT or cell == FACE_LEFT
		var side := _make_gun_strip(24, 12 if upright else 8, GUN_BLUED)
		if upright:
			side.fill_rect(Rect2i(3, 3, 21, 6), GUN_BLACK)  # the gap between the bars
		side.fill_rect(Rect2i(0, 0, 3, side.get_height()), _shade(GUN_BLUED, 0.7))  # plate
		_paint_gun_strip(atlas, cell, side)
	_paint_face(atlas, FACE_BACK, _speckle(8, 12, _shade(GUN_BLUED, 0.7), 0.07))
	_paint_face(atlas, FACE_FRONT, _speckle(8, 12, GUN_BLUED, 0.07))
	return atlas


# --- Office equipment --------------------------------------------------------
#
# What stands on the control room's desks. Each box is painted on a BoxMesh
# atlas like the furniture above, but these are small things seen from close
# to, so they are drawn finer: 80 pixels to the metre, the same as the
# posters. A letter of the pixel font is then the same size on a monitor's
# screen as on a poster, and can be read from the chair in front of it.

const PLASTIC_BEIGE := Color(0.74, 0.71, 0.61)
const SCREEN_DARK := Color(0.02, 0.06, 0.04)
const SCREEN_GREEN := Color(0.30, 1.0, 0.45)
const SCREEN_RED := Color(1.0, 0.22, 0.15)
const SCREEN_WHITE := Color(0.92, 0.94, 0.90)
const SCREEN_BLUE := Color(0.0, 0.0, 0.66)
const SCREEN_YELLOW := Color(1.0, 1.0, 0.33)
const SCREEN_BLACK := Color(0.0, 0.0, 0.0)
const CUP_WHITE := Color(0.90, 0.89, 0.84)
const CUP_COFFEE := Color(0.20, 0.11, 0.05)
const COOLER_WHITE := Color(0.84, 0.86, 0.85)
const COOLER_WATER := Color(0.35, 0.62, 0.95)


## The monitor's case: a box 40 cm wide, 35 cm tall and 40 cm deep. Every
## side is drawn 32 x 32, so no picture has to be stretched to fit its cell
## (the pixels on the front and sides are just a little shorter than they
## are wide). The front is a thick frame round the glass, with a chin for
## the maker's badge, two buttons and the power light.
##
## The glass is painted dark here. What the screen shows is one of the
## monitor_screen_ pictures below, on a flat square of its own that the
## scene lays over columns 3-28 of rows 3-24.
func _make_monitor() -> Image:
	var atlas := _new_atlas(32, 32)
	var slit := _shade(PLASTIC_BEIGE, 0.35)

	var front := _speckle(32, 32, PLASTIC_BEIGE, 0.03)
	front.fill_rect(Rect2i(0, 0, 32, 1), _shade(PLASTIC_BEIGE, 1.15))  # light on the top edge
	front.fill_rect(Rect2i(0, 31, 32, 1), _shade(PLASTIC_BEIGE, 0.7))
	front.fill_rect(Rect2i(2, 2, 28, 24), _shade(PLASTIC_BEIGE, 0.6))  # the step down to the glass
	front.fill_rect(Rect2i(3, 3, 26, 22), Color(0.04, 0.05, 0.05))  # the glass
	front.fill_rect(Rect2i(3, 28, 6, 2), Color(0.25, 0.27, 0.32))  # badge
	front.fill_rect(Rect2i(19, 28, 2, 2), _shade(PLASTIC_BEIGE, 0.55))  # buttons
	front.fill_rect(Rect2i(22, 28, 2, 2), _shade(PLASTIC_BEIGE, 0.55))
	front.set_pixel(27, 28, Color(0.30, 1.0, 0.40))  # power light
	_paint_face(atlas, FACE_FRONT, front)

	_paint_face(atlas, FACE_RIGHT, _make_monitor_side(true))
	_paint_face(atlas, FACE_LEFT, _make_monitor_side(false))

	# The back: a raised panel over the end of the tube, with cooling slits,
	# the maker's label and the sockets for the two leads.
	var back := _speckle(32, 32, _shade(PLASTIC_BEIGE, 0.9), 0.03)
	back.fill_rect(Rect2i(5, 3, 22, 20), _shade(PLASTIC_BEIGE, 0.78))
	for y in range(5, 12, 2):
		back.fill_rect(Rect2i(8, y, 16, 1), slit)
	back.fill_rect(Rect2i(12, 14, 8, 5), Color(0.86, 0.86, 0.80))  # label
	back.fill_rect(Rect2i(13, 15, 5, 1), Color(0.30, 0.30, 0.35))  # writing
	back.fill_rect(Rect2i(13, 17, 3, 1), Color(0.30, 0.30, 0.35))
	back.fill_rect(Rect2i(6, 26, 4, 3), Color(0.07, 0.07, 0.08))  # power lead
	back.fill_rect(Rect2i(21, 26, 5, 3), Color(0.15, 0.22, 0.55))  # the video lead's blue plug
	_paint_face(atlas, FACE_BACK, back)

	# The top, with the monitor's back at the top of the picture: more
	# slits, over the hot end of the tube.
	var top := _speckle(32, 32, _shade(PLASTIC_BEIGE, 1.05), 0.03)
	for y in range(4, 13, 2):
		top.fill_rect(Rect2i(6, y, 20, 1), slit)
	_paint_face(atlas, FACE_TOP, top)
	_paint_face(atlas, FACE_BOTTOM, _speckle(32, 32, _shade(PLASTIC_BEIGE, 0.5), 0.03))
	return atlas


## One side of the monitor's case: plain, with a block of slits near the
## back and the seam where the front frame is clipped on. As on the zombie's
## head, the front is at the right edge of the picture on the right side and
## at the left edge on the left side, which is what front_on_right says.
func _make_monitor_side(front_on_right: bool) -> Image:
	var side := _speckle(32, 32, _shade(PLASTIC_BEIGE, 0.95), 0.03)
	side.fill_rect(Rect2i(0, 31, 32, 1), _shade(PLASTIC_BEIGE, 0.7))
	for y in range(6, 15, 2):
		side.fill_rect(Rect2i(4 if front_on_right else 16, y, 12, 1), _shade(PLASTIC_BEIGE, 0.35))
	side.fill_rect(Rect2i(26 if front_on_right else 5, 0, 1, 32), _shade(PLASTIC_BEIGE, 0.7))
	return side


## The foot the monitor's case stands on: 25 cm square and 5 cm tall, a
## darker beige. Its sides are thin strips 20 x 4, in the shadow of the case
## overhanging them.
func _make_monitor_base() -> Image:
	var atlas := _new_atlas(20, 20)
	var plastic := _shade(PLASTIC_BEIGE, 0.8)
	for cell: Vector2i in [FACE_FRONT, FACE_BACK, FACE_LEFT, FACE_RIGHT]:
		var side := _speckle(20, 4, plastic, 0.03)
		side.fill_rect(Rect2i(0, 0, 20, 1), _shade(plastic, 0.55))
		_paint_face(atlas, cell, side)
	_paint_face(atlas, FACE_TOP, _speckle(20, 20, plastic, 0.03))
	_paint_face(atlas, FACE_BOTTOM, _speckle(20, 20, _shade(plastic, 0.5), 0.03))
	return atlas


## A blank monitor screen, 26 x 22 pixels: the size of the glass in the
## monitor's frame, so a pixel on the screen is the same size as one on the
## case around it. That leaves room for three lines of six letters.
func _new_screen(background: Color) -> Image:
	var screen := Image.create_empty(26, 22, false, Image.FORMAT_RGB8)
	screen.fill(background)
	return screen


## The holding cells' status screen: cells 1 and 2 are green, and cell 3
## (the one the whiteboard says to keep shut) is red.
func _make_monitor_screen_cells() -> Image:
	var screen := _new_screen(SCREEN_DARK)
	_draw_text_centred(screen, "CELLS", 1, SCREEN_GREEN)
	for cell in 3:
		var color := SCREEN_RED if cell == 2 else SCREEN_GREEN
		screen.fill_rect(Rect2i(3 + cell * 8, 8, 5, 7), color)
		# The cell's number, cut out of its block in the screen's own dark.
		_draw_text(screen, str(cell + 1), Vector2i(4 + cell * 8, 9), SCREEN_DARK)
	_draw_text_centred(screen, "3 OPEN", 16, SCREEN_RED)
	return screen


## Subject 7's heart monitor: two beats, then a flat line. (The whiteboard
## says subject 7 is awake.)
func _make_monitor_screen_vitals() -> Image:
	var screen := _new_screen(SCREEN_DARK)
	_draw_text_centred(screen, "SUBJ 7", 1, SCREEN_GREEN)
	# The row the trace is on in each of a beat's four columns: a small
	# rise, the spike, the dip after it, and level again. Level is row 12.
	var beat := [11, 8, 14, 12]
	var previous := 12
	for x in range(1, 25):
		var y := 12
		if x >= 3 and x < 7:
			y = beat[x - 3]
		elif x >= 9 and x < 13:
			y = beat[x - 9]
		# Draw each column from just past the last column's row to its own,
		# so the spike is one joined line.
		var from := y if y == previous else previous + signi(y - previous)
		for fill in range(mini(y, from), maxi(y, from) + 1):
			screen.set_pixel(x, fill, SCREEN_GREEN)
		previous = y
	_draw_text_centred(screen, "0 BPM", 16, SCREEN_RED)
	return screen


## Somebody's game of bat and ball, left running. They were losing 0 - 9,
## and the ball is about to get past them again.
func _make_monitor_screen_pong() -> Image:
	var screen := _new_screen(Color(0.02, 0.02, 0.03))
	for y in range(0, 22, 2):
		screen.set_pixel(13, y, _shade(SCREEN_WHITE, 0.5))  # the net
	_draw_text(screen, "0", Vector2i(7, 1), SCREEN_WHITE)
	_draw_text(screen, "9", Vector2i(17, 1), SCREEN_WHITE)
	screen.fill_rect(Rect2i(1, 12, 1, 5), SCREEN_WHITE)  # the two bats
	screen.fill_rect(Rect2i(24, 6, 1, 5), SCREEN_WHITE)
	screen.set_pixel(5, 17, SCREEN_WHITE)  # the ball
	return screen


## A camera whose picture has gone: white letters on blue.
func _make_monitor_screen_signal() -> Image:
	var screen := _new_screen(Color(0.06, 0.10, 0.55))
	_draw_text_centred(screen, "NO", 5, SCREEN_WHITE)
	_draw_text_centred(screen, "SIGNAL", 12, SCREEN_WHITE)
	return screen


## The alarm: a yellow warning triangle over the word BREACH, on red.
func _make_monitor_screen_breach() -> Image:
	var screen := _new_screen(Color(0.30, 0.02, 0.02))
	var yellow := Color(1.0, 0.85, 0.10)
	var dark := Color(0.12, 0.02, 0.02)
	for row in 11:
		# Half the triangle's width on this row: 1 at the tip, 7 at the foot.
		@warning_ignore("integer_division")
		var half := row * 3 / 5 + 1
		screen.fill_rect(Rect2i(13 - half, 1 + row, half * 2, 1), yellow)
	screen.fill_rect(Rect2i(12, 4, 2, 5), dark)  # the exclamation mark
	screen.fill_rect(Rect2i(12, 10, 2, 1), dark)
	_draw_text_centred(screen, "BREACH", 15, yellow)
	return screen


## Somebody's program, in an editor of the time: yellow writing on blue. It
## is three lines of Pascal, the middle one a letter in from the left as a
## programmer would set it out:
##   BEGIN
##    X:=1;
##   END.
func _make_monitor_screen_code() -> Image:
	var screen := _new_screen(SCREEN_BLUE)
	var lines := ["BEGIN", " X:=1;", "END."]
	for line in lines.size():
		# A letter is 5 pixels tall, so 7 from one line to the next leaves 2
		# clear between them. Starting 2 in from the top left corner, six
		# letters (23 pixels) and three lines (19) just fit the 26 x 22 glass.
		_draw_text(screen, lines[line], Vector2i(2, 2 + line * 7), SCREEN_YELLOW)
	return screen


## A screen full of somebody's program, too far down the page to read: green
## lines on black. Each row of the picture below is one line of the program
## and each run of # is one of its words, so a line is a row of dashes that
## starts further in from the left the deeper it is inside the program (the
## way programmers set their lines out). Every # is one pixel of "ink" on a
## screen of "paper": green on black unless you ask for other colours, as
## monitor_screen_listing_blue does (yellow on blue, the colours of the
## editor in _make_monitor_screen_code).
func _make_monitor_screen_listing(paper := SCREEN_BLACK, ink := SCREEN_GREEN) -> Image:
	var screen := _new_screen(paper)
	var lines := [
		"### #####",
		"  ## #### # ##",
		"    ###### ###",
		"  ### # ## #####",
		"    #### ## ######",
		"    ##### #######",
		"  ###### ####",
	]
	for line in lines.size():
		var words: String = lines[line]
		for column in words.length():
			if words[column] == "#":
				# 3 from one line to the next leaves two clear rows between
				# them, so they stay apart when the monitor is seen from across
				# the room. Starting 2 in from the top left corner, the seven
				# lines end one row above the bottom of the 26 x 22 glass.
				screen.set_pixel(2 + column, 2 + line * 3, ink)
	return screen


# --- The notebook --------------------------------------------------------------

const NOTEBOOK_PAPER := Color(0.87, 0.82, 0.66)
const NOTEBOOK_INK := Color(0.16, 0.17, 0.36)


## One of the two blocks of pages in the open notebook on the desk
## (scenes/notebook.tscn): 15.5 cm wide, 2 cm thick and 21 cm deep, drawn
## like everything else on the desks at 80 pixels to the metre, which makes
## its top 12 x 16. The top is a page of handwriting too small to read. Each
## row of the picture below is a line of it and each run of # is a word, in
## ink; the last line stops short, as the last line of a paragraph does.
##
## A box shows its top picture with the picture's top row along its +Z
## edge, which is the edge nearest whoever sits at the desk, so to them the
## left-hand block's page is this picture upside down. That suits it: the
## short line comes first and over on the right, like the date at the top
## of a diary entry. The right-hand block is the same block turned half way
## round, so its page is the right way up and ends with the short line.
## That way the two pages don't look alike, with one picture between them.
func _make_notebook_page() -> Image:
	var atlas := _new_atlas(12, 16)
	var page := Image.create_empty(12, 16, false, Image.FORMAT_RGB8)
	page.fill(NOTEBOOK_PAPER)
	var lines := [
		"### ## ###",
		"## #### ##",
		"#### # ###",
		"# ### ####",
		"### ### ##",
		"## # #####",
		"####",
	]
	for line in lines.size():
		var words: String = lines[line]
		for column in words.length():
			if words[column] == "#":
				# One pixel in from the left, and every other row from the
				# third down, which leaves a clear row between the lines.
				page.set_pixel(1 + column, 2 + line * 2, NOTEBOOK_INK)
	_paint_face(atlas, FACE_TOP, page)

	# The four sides are the edges of the pages underneath: paper, in the
	# shadow of the page on top, darker towards the cover they lie on.
	for cell: Vector2i in [FACE_FRONT, FACE_BACK, FACE_LEFT, FACE_RIGHT]:
		var edge := Image.create_empty(12, 2, false, Image.FORMAT_RGB8)
		edge.fill_rect(Rect2i(0, 0, 12, 1), _shade(NOTEBOOK_PAPER, 0.9))
		edge.fill_rect(Rect2i(0, 1, 12, 1), _shade(NOTEBOOK_PAPER, 0.7))
		_paint_face(atlas, cell, edge)
	var underside := Image.create_empty(12, 16, false, Image.FORMAT_RGB8)
	underside.fill(_shade(NOTEBOOK_PAPER, 0.7))
	_paint_face(atlas, FACE_BOTTOM, underside)
	return atlas


## The keyboard: 47.5 cm wide, 3 cm tall and 17.5 cm deep. Its top is 38 x 14
## pixels, drawn as the typist sees it. The keys are two pixels square and
## stand in two dark wells: nine columns on the left, with the long space
## bar in the bottom row, and three columns of number keys on the right,
## under the status lights. The keys round the edge are grey.
func _make_keyboard() -> Image:
	var atlas := _new_atlas(38, 14)
	var pale := Color(0.90, 0.88, 0.80)
	var grey := Color(0.62, 0.61, 0.56)

	var top := _speckle(38, 14, PLASTIC_BEIGE, 0.03)
	top.fill_rect(Rect2i(0, 0, 38, 1), _shade(PLASTIC_BEIGE, 1.15))  # light on the far edge
	top.fill_rect(Rect2i(1, 2, 26, 11), _shade(PLASTIC_BEIGE, 0.5))  # the two wells
	top.fill_rect(Rect2i(29, 2, 8, 11), _shade(PLASTIC_BEIGE, 0.5))
	top.set_pixel(30, 1, Color(0.30, 1.0, 0.40))  # one status light on, two off
	top.set_pixel(33, 1, Color(0.15, 0.30, 0.15))
	top.set_pixel(36, 1, Color(0.15, 0.30, 0.15))
	for row in 4:
		for column in 12:
			if row == 3 and column > 2 and column < 7:
				continue  # under the space bar, which starts at column 2
			# Keys are three pixels apart. The number keys (columns 9-11)
			# start one pixel further over, after the gap between the wells.
			var x := 1 + column * 3 + (1 if column >= 9 else 0)
			var y := 2 + row * 3
			var color := pale
			if column == 0 or column == 8 or column == 11 or (row == 3 and (column == 1 or column == 7)):
				color = grey
			color = _shade(color, rng.randf_range(0.95, 1.05))
			var width := 14 if row == 3 and column == 2 else 2
			top.fill_rect(Rect2i(x, y, width, 1), color)
			top.fill_rect(Rect2i(x, y + 1, width, 1), _shade(color, 0.85))  # the key's front slope
	_paint_face(atlas, FACE_TOP, top)

	# All four edges are the same thin strip: the case above, the base in
	# shadow below.
	var edge := _speckle(38, 14, _shade(PLASTIC_BEIGE, 0.9), 0.03)
	edge.fill_rect(Rect2i(0, 9, 38, 5), _shade(PLASTIC_BEIGE, 0.6))
	for cell: Vector2i in [FACE_FRONT, FACE_BACK, FACE_LEFT, FACE_RIGHT]:
		_paint_face(atlas, cell, edge)
	_paint_face(atlas, FACE_BOTTOM, _speckle(38, 14, _shade(PLASTIC_BEIGE, 0.4), 0.03))
	return atlas


# The coffee cup and the cooler's bottle are cylinders, and a CylinderMesh
# lays its texture out differently from a box. The top half of the picture
# wraps once round the side. Its two ends meet in a seam, which the scenes
# turn to the back, so the middle of the picture is the front. The bottom
# half holds two discs side by side: the top of the cylinder on the left
# and its underside on the right.

## The coffee cup: 9 cm across and 10 cm tall. Its side is 32 x 12 pixels of
## white china with a blue line under the rim and another round the foot, a
## red heart on the front, and a dribble of coffee down from the rim on the
## left. The top disc is the coffee, inside the rim.
func _make_cup() -> Image:
	var cup := _speckle(32, 24, CUP_WHITE, 0.02)
	var blue := Color(0.15, 0.22, 0.50)
	var red := Color(0.80, 0.12, 0.12)
	var stain := Color(0.36, 0.22, 0.10)
	cup.fill_rect(Rect2i(0, 0, 32, 1), _shade(CUP_WHITE, 1.08))  # light on the rim
	cup.fill_rect(Rect2i(0, 1, 32, 1), blue)
	cup.fill_rect(Rect2i(0, 10, 32, 1), blue)
	cup.fill_rect(Rect2i(0, 11, 32, 1), _shade(CUP_WHITE, 0.8))  # the foot, in shadow
	var heart := [".##.##.", "#######", "#######", ".#####.", "..###..", "...#..."]
	for row in heart.size():
		var line: String = heart[row]
		for column in line.length():
			if line[column] == "#":
				cup.set_pixel(13 + column, 3 + row, red)
	cup.fill_rect(Rect2i(7, 0, 1, 7), stain)  # the dribble, and the drop it ends in
	cup.fill_rect(Rect2i(8, 5, 1, 2), stain)

	for y in 12:
		for x in 16:
			# How far this pixel is from the middle of its disc: 1 at the rim.
			var distance := Vector2((x + 0.5 - 8.0) / 8.0, (y + 0.5 - 6.0) / 6.0).length()
			if distance < 0.75:
				# A curve of the ceiling light on the coffee.
				var shine := distance > 0.45 and x < 7 and y < 5
				cup.set_pixel(x, 12 + y, _shade(CUP_COFFEE, 1.8 if shine else 1.0))
			# The underside: an unglazed ring round a shallow hollow.
			cup.set_pixel(16 + x, 12 + y, _shade(CUP_WHITE, 0.7 if distance < 0.6 else 0.85))
	return cup


## The cup's handle, a slab of the same china 3 cm long, 5.5 cm tall and
## 1.4 cm thick. It is too small for more than light on top and shadow
## underneath.
func _make_cup_handle() -> Image:
	var atlas := _new_atlas(4, 6)
	for cell: Vector2i in [FACE_FRONT, FACE_BACK, FACE_LEFT, FACE_RIGHT]:
		_paint_face(atlas, cell, _speckle(4, 6, CUP_WHITE, 0.02))
	_paint_face(atlas, FACE_TOP, _speckle(4, 6, _shade(CUP_WHITE, 1.08), 0.02))
	_paint_face(atlas, FACE_BOTTOM, _speckle(4, 6, _shade(CUP_WHITE, 0.7), 0.02))
	return atlas


## The water cooler's cabinet: 40 cm square and 1 m tall, at the furniture's
## 40 pixels to the metre, so the front is 16 x 40. Near the top is the dark
## alcove where a cup goes, with the cold tap (blue) and the hot tap (red)
## hanging in it over a drip tray. Below is a door with the maker's blue
## plate and slits for the cooling fan, and a dark kick plate along the
## floor.
func _make_water_cooler() -> Image:
	var atlas := _new_atlas(16, 40)
	var recess := Color(0.17, 0.19, 0.21)
	var steel := Color(0.62, 0.64, 0.65)
	var slit := _shade(COOLER_WHITE, 0.4)
	var kick := _shade(COOLER_WHITE, 0.3)

	var front := _speckle(16, 40, COOLER_WHITE, 0.03)
	front.fill_rect(Rect2i(0, 0, 16, 1), _shade(COOLER_WHITE, 1.12))  # light on the top edge
	front.fill_rect(Rect2i(3, 3, 10, 11), recess)
	front.fill_rect(Rect2i(3, 3, 10, 1), _shade(recess, 0.6))  # darkest under the overhang
	for tap in 2:
		var x := 5 + tap * 4
		var handle := Color(0.20, 0.42, 0.92) if tap == 0 else Color(0.88, 0.16, 0.12)
		front.fill_rect(Rect2i(x, 4, 2, 2), handle)
		front.fill_rect(Rect2i(x, 6, 2, 1), steel)  # the spout
	front.fill_rect(Rect2i(3, 12, 10, 1), steel)  # the drip tray, and the bars of its grille
	for x in range(3, 13, 2):
		front.set_pixel(x, 13, steel)
	front.fill_rect(Rect2i(1, 15, 14, 22), _shade(COOLER_WHITE, 0.93))  # the door
	front.fill_rect(Rect2i(1, 15, 14, 1), _shade(COOLER_WHITE, 0.7))  # the gap above it
	front.fill_rect(Rect2i(5, 18, 6, 3), Color(0.20, 0.45, 0.80))  # maker's plate
	front.fill_rect(Rect2i(7, 19, 2, 1), Color(0.90, 0.95, 1.0))
	for y in range(28, 35, 2):
		front.fill_rect(Rect2i(4, y, 8, 1), slit)
	front.fill_rect(Rect2i(0, 37, 16, 3), kick)
	_paint_face(atlas, FACE_FRONT, front)

	# Both sides are the same, so one picture does for the two of them.
	var side := _speckle(16, 40, _shade(COOLER_WHITE, 0.95), 0.03)
	side.fill_rect(Rect2i(0, 0, 16, 1), _shade(COOLER_WHITE, 1.12))
	for y in range(26, 35, 2):
		side.fill_rect(Rect2i(3, y, 10, 1), slit)
	side.fill_rect(Rect2i(0, 37, 16, 3), kick)
	_paint_face(atlas, FACE_LEFT, side)
	_paint_face(atlas, FACE_RIGHT, side)

	# The back: the black grid of pipes that gets rid of the heat.
	var back := _speckle(16, 40, _shade(COOLER_WHITE, 0.8), 0.03)
	back.fill_rect(Rect2i(2, 8, 12, 24), Color(0.10, 0.10, 0.11))
	for y in range(9, 31, 2):
		back.fill_rect(Rect2i(3, y, 10, 1), Color(0.26, 0.26, 0.28))
	back.fill_rect(Rect2i(0, 37, 16, 3), kick)
	_paint_face(atlas, FACE_BACK, back)

	# The top is square but its cell is 16 x 40, so it is drawn 16 x 20 and
	# stretched to exactly twice as tall. The blue ring is the collar the
	# bottle's neck goes into: 15 cm across, so wider than tall in pixels
	# that are 2.5 cm by 2 cm.
	var top := _speckle(16, 20, COOLER_WHITE, 0.03)
	for y in 20:
		for x in 16:
			if Vector2((x + 0.5 - 8.0) / 3.0, (y + 0.5 - 10.0) / 3.75).length() < 1.0:
				top.set_pixel(x, y, Color(0.25, 0.35, 0.60))
	_paint_face(atlas, FACE_TOP, top)
	_paint_face(atlas, FACE_BOTTOM, _speckle(16, 40, kick, 0.03))
	return atlas


## The bottle standing on its neck on top of the cooler: 27 cm across and
## 30 cm tall. This picture is partly see-through (the fourth number of each
## colour is how solid it is), so the wall shows through the water. The side
## is 32 x 12: air at the top, the bright line of the water's surface, two
## grip rings moulded into the plastic, streaks of light running down it and
## a few bubbles. The disc is the bottle's flat end.
func _make_water_bottle() -> Image:
	var bottle := Image.create_empty(32, 24, false, Image.FORMAT_RGBA8)
	var water := Color(COOLER_WATER, 0.55)
	var air := Color(0.75, 0.88, 1.0, 0.3)
	var shine := Color(1.0, 1.0, 1.0, 0.8)
	bottle.fill(water)
	for y in 12:
		for x in 32:
			var color := water
			if y < 2:
				color = air
			elif y == 2:
				color = Color(0.88, 0.96, 1.0, 0.8)  # the surface
			elif y == 5 or y == 8:
				color = Color(0.24, 0.48, 0.85, 0.65)  # a grip ring
			# lerp() mixes two colours: 0.5 is half of each.
			if x == 12 or x == 13:
				color = color.lerp(shine, 0.5)
			elif x == 21:
				color = color.lerp(shine, 0.25)
			bottle.set_pixel(x, y, color)
	for bubble in 6:
		bottle.set_pixel(rng.randi_range(6, 25), rng.randi_range(3, 10), water.lerp(shine, 0.4))
	for y in 12:
		for x in 16:
			var distance := Vector2((x + 0.5 - 8.0) / 8.0, (y + 0.5 - 6.0) / 6.0).length()
			# The flat end has air under it, and a thicker ring to stand on.
			bottle.set_pixel(x, 12 + y, air.lerp(shine, 0.3) if distance > 0.6 and distance < 0.85 else air)
	return bottle


## How many pixels in from the poster's left edge the printout's left edge
## is. Its bottom edge lies along the poster's top edge.
const POSTER_CHART_PRINTOUT_LEFT := 40


## The length of printer paper taped to the wall above the infection rate
## poster, so that the marker line could keep going up: 30 x 84 pixels,
## which at the poster's 80 pixels to the metre is 37.5 cm wide and 1.05 m
## tall. It is the fanfold paper of old printers: pale green bars, a row of
## holes down each edge for the printer's sprockets, and a fold every 21
## rows where one sheet tears off from the next.
func _make_poster_chart_printout() -> Image:
	var sheet := _speckle(30, 84, Color(0.94, 0.94, 0.90), 0.03)
	var bar := Color(0.78, 0.90, 0.78)
	var hole := Color(0.42, 0.43, 0.40)
	var ink := Color(0.12, 0.14, 0.35)
	for y in 84:
		@warning_ignore("integer_division")
		var band := y / 3
		if band % 2 == 0:
			for x in range(3, 27):
				sheet.set_pixel(x, y, _shade(bar, rng.randf_range(0.97, 1.03)))
		if y % 3 == 1:
			sheet.set_pixel(1, y, hole)
			sheet.set_pixel(28, y, hole)
		if y % 21 == 0 and y > 0:
			# A fold: a dotted line of shadow.
			for x in range(0, 30, 2):
				sheet.set_pixel(x, y, _shade(sheet.get_pixel(x, y), 0.75))
	# A piece of sticky tape over each corner.
	for corner: Vector2i in [Vector2i(0, 0), Vector2i(25, 0), Vector2i(0, 81), Vector2i(25, 81)]:
		sheet.fill_rect(Rect2i(corner, Vector2i(5, 3)), Color(0.86, 0.80, 0.55))
	# Whoever kept the graph going wrote on it as they went. Like the line,
	# it reads from the bottom up.
	_draw_text(sheet, "500%", Vector2i(4, 71), ink)
	_draw_text(sheet, "999%", Vector2i(4, 50), ink)
	_draw_text(sheet, "OH NO", Vector2i(2, 29), ink)
	_draw_text(sheet, "HELP", Vector2i(4, 8), ink)
	# The marker line, starting in the column where the poster's left off.
	for y in 84:
		# 0 at the bottom of the paper, 1 at the top.
		var climbed := (83 - y) / 83.0
		# It drifts two pixels to the right on the way up and wobbles a
		# little, because it was drawn by hand, the top of it from a chair.
		var drift := int(round(climbed * (2.0 + 0.8 * sin(y * 0.4))))
		sheet.fill_rect(Rect2i(POSTER_CHART_MARKER_TOP - POSTER_CHART_PRINTOUT_LEFT + drift, y, 2, 1), POSTER_CHART_MARKER)
	return sheet


# --- The Macintosh -----------------------------------------------------------
#
# One computer in the control room (scenes/macintosh.tscn) is made to look
# like the first Apple Macintosh, of 1984: a small upright box with a black
# and white screen in its face and a slot for disks under it, which came
# with a short keyboard and a mouse (hardly any other computer had a mouse
# then). It is painted at the same 80 pixels to the metre as the rest of the
# desk equipment and in the same beige, which is close to the real one's.

const MACINTOSH_KEY := Color(0.66, 0.61, 0.50)
const MACINTOSH_SOCKET := Color(0.07, 0.07, 0.08)
const MACINTOSH_LEAD := Color(0.42, 0.40, 0.35)


## The Macintosh's case, without the foot it stands on: a box 25 cm wide,
## 28.75 cm tall and 27.5 cm deep. Every side is drawn 20 x 23. That makes a
## pixel of the front exactly 1.25 cm square, the same as a pixel of the
## screen that lies over it (on the sides and the top they come out a
## little wider or shorter).
##
## The screen is high up in the front, in a deep frame. Below it are the two
## things the machine is known by: the slot of the disk drive on the right,
## and the maker's badge in the six colours of the rainbow at the bottom
## left.
##
## The glass is painted dark here. What the screen shows is the
## macintosh_screen picture below, on a flat square of its own that the
## scene lays over columns 3-16 of rows 3-12. That is one pixel smaller all
## round than the glass, because the real tube's picture stopped short of
## the frame and left a border of dark glass (the monitor's fills its frame).
func _make_macintosh() -> Image:
	var atlas := _new_atlas(20, 23)
	var slit := _shade(PLASTIC_BEIGE, 0.35)

	var front := _speckle(20, 23, PLASTIC_BEIGE, 0.03)
	front.fill_rect(Rect2i(0, 0, 20, 1), _shade(PLASTIC_BEIGE, 1.15))  # light on the top edge
	front.fill_rect(Rect2i(2, 2, 16, 12), Color(0.04, 0.05, 0.05))  # the glass
	front.fill_rect(Rect2i(9, 17, 9, 1), MACINTOSH_SOCKET)  # the disk slot
	front.fill_rect(Rect2i(12, 18, 3, 1), _shade(PLASTIC_BEIGE, 0.6))  # the dent for the thumb that pulls a disk out
	# The badge: two pixels wide and three tall, one colour of the rainbow
	# each, from green at the top left to blue at the bottom right.
	var rainbow := [
		Color(0.38, 0.73, 0.28), Color(0.99, 0.72, 0.15),
		Color(0.96, 0.51, 0.12), Color(0.88, 0.23, 0.24),
		Color(0.59, 0.24, 0.59), Color(0.0, 0.62, 0.86),
	]
	for stripe in rainbow.size():
		@warning_ignore("integer_division")
		front.set_pixel(2 + stripe % 2, 18 + stripe / 2, rainbow[stripe])
	front.fill_rect(Rect2i(0, 22, 20, 1), _shade(PLASTIC_BEIGE, 0.7))  # the lip over the foot
	_paint_face(atlas, FACE_FRONT, front)

	_paint_face(atlas, FACE_RIGHT, _make_macintosh_side(true))
	_paint_face(atlas, FACE_LEFT, _make_macintosh_side(false))

	# The back: a raised panel over the end of the tube, with cooling slits
	# and the maker's label, and the little door the clock's battery is
	# behind.
	var back := _speckle(20, 23, _shade(PLASTIC_BEIGE, 0.9), 0.03)
	back.fill_rect(Rect2i(3, 2, 14, 13), _shade(PLASTIC_BEIGE, 0.78))
	for y in range(4, 9, 2):
		back.fill_rect(Rect2i(6, y, 8, 1), slit)
	back.fill_rect(Rect2i(7, 10, 6, 3), Color(0.86, 0.86, 0.80))  # label
	back.fill_rect(Rect2i(8, 11, 4, 1), Color(0.30, 0.30, 0.35))  # writing
	back.fill_rect(Rect2i(14, 17, 4, 4), _shade(PLASTIC_BEIGE, 0.75))  # battery door
	_paint_face(atlas, FACE_BACK, back)

	# The top, with the back of the machine at the top of the picture. Near
	# the back is the hollow you put your fingers in to carry it, with slits
	# on either side of it: it had no fan, so the heat went out of the top.
	# The line near the front is the seam where the front of the case is
	# fitted to the back (the sides have it too).
	var top := _speckle(20, 23, _shade(PLASTIC_BEIGE, 1.05), 0.03)
	top.fill_rect(Rect2i(5, 2, 10, 5), _shade(PLASTIC_BEIGE, 0.4))
	top.fill_rect(Rect2i(5, 2, 10, 1), _shade(PLASTIC_BEIGE, 0.25))  # the shadow under the hollow's back edge
	for y in range(2, 7, 2):
		top.fill_rect(Rect2i(1, y, 3, 1), slit)
		top.fill_rect(Rect2i(16, y, 3, 1), slit)
	top.fill_rect(Rect2i(0, 19, 20, 1), _shade(PLASTIC_BEIGE, 0.8))
	_paint_face(atlas, FACE_TOP, top)
	_paint_face(atlas, FACE_BOTTOM, _speckle(20, 23, _shade(PLASTIC_BEIGE, 0.5), 0.03))
	return atlas


## One side of the Macintosh's case: plain, with the seam near the front and
## a row of upright slits near the top at the back. front_on_right means
## what it does in _make_monitor_side.
func _make_macintosh_side(front_on_right: bool) -> Image:
	var side := _speckle(20, 23, _shade(PLASTIC_BEIGE, 0.95), 0.03)
	for slit in 5:
		# Every other column, counted from three pixels in from the back.
		var x := 3 + slit * 2
		side.fill_rect(Rect2i(x if front_on_right else 19 - x, 2, 1, 4), _shade(PLASTIC_BEIGE, 0.35))
	side.fill_rect(Rect2i(16 if front_on_right else 3, 0, 1, 23), _shade(PLASTIC_BEIGE, 0.7))
	return side


## The foot the Macintosh's case stands on: as wide as the case, 6.25 cm
## tall and 25 cm deep, so its sides are 20 x 5. The scene sets its back
## level with the case's, which leaves the case's face sticking out 2.5 cm
## over it at the front, as the real one's does. The keyboard's socket is in
## the front, in the shadow under there. The other sockets are in a row
## along the back, and the first of them, as you look at the back, has the
## mouse's plug in it: that is where the scene brings the mouse's lead.
func _make_macintosh_foot() -> Image:
	var atlas := _new_atlas(20, 5)
	var front := _speckle(20, 5, _shade(PLASTIC_BEIGE, 0.8), 0.03)
	front.fill_rect(Rect2i(0, 0, 20, 1), _shade(PLASTIC_BEIGE, 0.5))  # the shadow of the case above
	front.fill_rect(Rect2i(13, 3, 2, 2), MACINTOSH_SOCKET)  # the keyboard's socket
	_paint_face(atlas, FACE_FRONT, front)

	var back := _speckle(20, 5, _shade(PLASTIC_BEIGE, 0.9), 0.03)
	back.fill_rect(Rect2i(0, 4, 20, 1), _shade(PLASTIC_BEIGE, 0.7))
	back.fill_rect(Rect2i(2, 3, 3, 2), MACINTOSH_LEAD)  # the mouse's plug
	back.fill_rect(Rect2i(6, 2, 3, 1), MACINTOSH_SOCKET)  # disk drive, printer, telephone, sound
	back.fill_rect(Rect2i(10, 2, 2, 1), MACINTOSH_SOCKET)
	back.fill_rect(Rect2i(13, 2, 2, 1), MACINTOSH_SOCKET)
	back.fill_rect(Rect2i(16, 2, 1, 1), MACINTOSH_SOCKET)
	_paint_face(atlas, FACE_BACK, back)

	# The sides carry on down from the sides of the case, so they are the
	# same shade, with a line of shadow where they meet the desk.
	for cell: Vector2i in [FACE_LEFT, FACE_RIGHT]:
		var side := _speckle(20, 5, _shade(PLASTIC_BEIGE, 0.95), 0.03)
		side.fill_rect(Rect2i(0, 4, 20, 1), _shade(PLASTIC_BEIGE, 0.7))
		_paint_face(atlas, cell, side)
	# The top is hidden under the case and the bottom is on the desk.
	_paint_face(atlas, FACE_TOP, _speckle(20, 5, _shade(PLASTIC_BEIGE, 0.5), 0.03))
	_paint_face(atlas, FACE_BOTTOM, _speckle(20, 5, _shade(PLASTIC_BEIGE, 0.5), 0.03))
	return atlas


## What the Macintosh's screen shows, 14 x 10 pixels: the picture it greeted
## you with every time it was switched on, a little Macintosh with a smile
## on its screen, in the middle of an empty grey desktop. This one has been
## smiling at an empty room for days.
##
## In the picture below each "." is a white pixel of the little computer and
## each "#" a black one: its two eyes, its smile, and its disk slot at the
## bottom right. The real screen's black and white were as sharp as paper,
## which no screen of green or yellow letters was. The four corner pixels
## are black because the real one drew its desktop with rounded corners;
## against the dark glass the case has round the picture, they round it off.
func _make_macintosh_screen() -> Image:
	var screen := Image.create_empty(14, 10, false, Image.FORMAT_RGB8)
	screen.fill(_shade(SCREEN_WHITE, 0.6))
	var computer := [
		"........",
		"..#..#..",
		"........",
		".#....#.",
		"..####..",
		"........",
		".....##.",
		"........",
	]
	for row in computer.size():
		var line: String = computer[row]
		for column in line.length():
			# Eight pixels wide in a screen of fourteen leaves three clear on
			# either side, and eight tall in ten leaves one above and below.
			screen.set_pixel(3 + column, 1 + row, SCREEN_BLACK if line[column] == "#" else SCREEN_WHITE)
	for corner: Vector2i in [Vector2i(0, 0), Vector2i(13, 0), Vector2i(0, 9), Vector2i(13, 9)]:
		screen.set_pixelv(corner, SCREEN_BLACK)
	return screen


## The Macintosh's keyboard: 33.75 cm wide, 3 cm tall and 16.25 cm deep. It
## is a good deal shorter than the other keyboard (_make_keyboard) because
## it has no number keys at the side and no arrow keys: the mouse was to do
## their work. Its top is 27 x 13 pixels, drawn as the typist sees it: four
## rows of eight keys in one dark well, all of one colour, with the long
## space bar in the row nearest the typist.
func _make_macintosh_keyboard() -> Image:
	var atlas := _new_atlas(27, 13)
	var top := _speckle(27, 13, PLASTIC_BEIGE, 0.03)
	top.fill_rect(Rect2i(0, 0, 27, 1), _shade(PLASTIC_BEIGE, 1.15))  # light on the far edge
	top.fill_rect(Rect2i(1, 1, 25, 11), _shade(PLASTIC_BEIGE, 0.5))  # the well
	for row in 4:
		for column in 8:
			if row == 3 and column > 2 and column < 6:
				continue  # under the space bar, which starts at column 2
			# Keys are two pixels square and three pixels apart, like the
			# other keyboard's. The space bar is as long as four of them.
			var color := _shade(MACINTOSH_KEY, rng.randf_range(0.95, 1.05))
			var width := 11 if row == 3 and column == 2 else 2
			top.fill_rect(Rect2i(2 + column * 3, 1 + row * 3, width, 1), color)
			top.fill_rect(Rect2i(2 + column * 3, 2 + row * 3, width, 1), _shade(color, 0.85))  # the key's front slope
	_paint_face(atlas, FACE_TOP, top)

	# All four edges are the same thin strip: the case above, the base in
	# shadow below.
	var edge := _speckle(27, 13, _shade(PLASTIC_BEIGE, 0.9), 0.03)
	edge.fill_rect(Rect2i(0, 8, 27, 5), _shade(PLASTIC_BEIGE, 0.6))
	for cell: Vector2i in [FACE_FRONT, FACE_BACK, FACE_LEFT, FACE_RIGHT]:
		_paint_face(atlas, cell, edge)
	_paint_face(atlas, FACE_BOTTOM, _speckle(27, 13, _shade(PLASTIC_BEIGE, 0.4), 0.03))
	return atlas


## The mouse: a box 6.25 cm wide, 3.75 cm tall and 10 cm long, with a single
## wide button (the real one had only one) across the end its lead comes out
## of. Its top is 5 x 8 pixels, seen from above with that end at the top of
## the picture. The button is the colour of the keyboard's keys.
func _make_macintosh_mouse() -> Image:
	var atlas := _new_atlas(5, 8)
	var top := _speckle(5, 8, PLASTIC_BEIGE, 0.03)
	top.fill_rect(Rect2i(0, 0, 5, 1), _shade(PLASTIC_BEIGE, 1.15))  # light on the far edge
	top.fill_rect(Rect2i(1, 1, 3, 1), MACINTOSH_KEY)
	top.fill_rect(Rect2i(1, 2, 3, 1), _shade(MACINTOSH_KEY, 0.85))  # the button's front slope
	_paint_face(atlas, FACE_TOP, top)

	# The four sides, like the keyboard's edges: the case above, the base in
	# shadow below.
	var edge := _speckle(5, 8, _shade(PLASTIC_BEIGE, 0.9), 0.03)
	edge.fill_rect(Rect2i(0, 6, 5, 2), _shade(PLASTIC_BEIGE, 0.6))
	for cell: Vector2i in [FACE_FRONT, FACE_BACK, FACE_LEFT, FACE_RIGHT]:
		_paint_face(atlas, cell, edge)
	_paint_face(atlas, FACE_BOTTOM, _speckle(5, 8, _shade(PLASTIC_BEIGE, 0.4), 0.03))
	return atlas


# --- The control console -------------------------------------------------------
#
# The long desk in the middle of start-level-demo's control room
# (scenes/control_console.tscn): a steel cabinet 4 m long, 0.9 m tall and 1 m
# deep that the room's operator stands at, facing the observation window.
# Along the back of its top are three sloping panels of instruments. In
# front of them the top is a desk, with a plate of controls let into it at
# either end and a third for the intercom.
#
# Like the equipment that stands on it, it is painted at 80 pixels to the
# metre, so the letters engraved on it are the size of a poster's and can be
# read by somebody standing at it.

const CONSOLE_PLATE := Color(0.09, 0.10, 0.11)
const CONSOLE_WHITE := Color(0.86, 0.87, 0.82)
const CONSOLE_BEZEL := Color(0.30, 0.31, 0.33)
const CONSOLE_CHROME := Color(0.55, 0.57, 0.58)
const CONSOLE_YELLOW := Color(0.92, 0.76, 0.10)
const CONSOLE_RED := Color(0.95, 0.16, 0.10)
const CONSOLE_GREEN := Color(0.20, 0.90, 0.30)
const CONSOLE_AMBER := Color(1.0, 0.68, 0.10)

# The sloping panels are PrismMeshes, which lay their atlas out in the same
# three cells by two as a BoxMesh but have only five sides. The two ends are
# triangles (each uses half of its cell). A prism's "left" and "right" are
# the two sides that lean together: the scene stands the left one upright as
# the panel's back, which makes the right one the slope the instruments are
# on. The picture in a cell has the top of the prism along its top edge.
const PRISM_FRONT := Vector2i(0, 0)
const PRISM_RIGHT := Vector2i(1, 0)
const PRISM_BACK := Vector2i(2, 0)
const PRISM_LEFT := Vector2i(0, 1)
const PRISM_BOTTOM := Vector2i(2, 1)


## The console's cabinet. Its top is 320 x 80 pixels, so each of the other
## sides is drawn 80 tall as well, for 0.9 m: their pixels are a little
## shorter than they are wide. The two ends are drawn 80 wide and stretched
## to four times that.
##
## The top is drawn as the operator sees it. Its far edge, where the sloping
## panels stand, is the top of the picture, so a pixel (u, v) of it is the
## spot u / 80 - 2 metres along the console and v / 80 - 0.5 metres towards
## the operator from the console's middle. The scene's buttons are placed by
## that sum: move a plate here and its buttons have to move with it.
func _make_control_console() -> Image:
	var atlas := _new_atlas(320, 80)
	var seam := _shade(DESK_STEEL, 0.6)
	var slit := _shade(DESK_STEEL, 0.4)
	var dark := Color(0.12, 0.12, 0.13)

	# The operator's side: four cupboards, each with a pair of doors that
	# open from the middle. Every other cupboard has slits low down, to let
	# air in to what is inside.
	var front := _speckle(320, 80, seam, 0.03)
	for door in 8:
		var left := door * 40
		front.fill_rect(Rect2i(left, 6, 39, 62), _shade(DESK_STEEL, rng.randf_range(0.97, 1.03)))
		front.fill_rect(Rect2i(left, 6, 39, 1), _shade(DESK_STEEL, 1.2))  # light on the top edge
		var handle := left + 34 if door % 2 == 0 else left + 3
		front.fill_rect(Rect2i(handle, 30, 1, 8), dark)
		front.fill_rect(Rect2i(handle + 1, 30, 1, 8), _shade(DESK_STEEL, 1.35))
		@warning_ignore("integer_division")
		if door / 2 % 2 == 1:
			for y in range(50, 63, 3):
				front.fill_rect(Rect2i(left + 8, y, 23, 1), slit)
	front.fill_rect(Rect2i(168, 12, 27, 9), CONSOLE_YELLOW)  # a warning label
	_draw_text(front, "DANGER", Vector2i(170, 14), dark)
	front.fill_rect(Rect2i(52, 12, 10, 5), Color(0.86, 0.84, 0.76))  # a stores label
	front.fill_rect(Rect2i(54, 14, 6, 1), Color(0.35, 0.35, 0.40))  # writing
	_trim_console_side(front)
	_paint_face(atlas, FACE_FRONT, front)

	# The side towards the window: four panels that unscrew, one for each
	# cupboard, with slits.
	var back := _speckle(320, 80, seam, 0.03)
	for panel in 4:
		var left := panel * 80
		back.fill_rect(Rect2i(left, 6, 79, 62), _shade(DESK_STEEL, rng.randf_range(0.9, 0.96)))
		back.fill_rect(Rect2i(left, 6, 79, 1), _shade(DESK_STEEL, 1.15))
		for screw: Vector2i in [Vector2i(2, 9), Vector2i(76, 9), Vector2i(2, 65), Vector2i(76, 65)]:
			back.set_pixelv(Vector2i(left, 0) + screw, dark)
		for y in range(16, 32, 3):
			back.fill_rect(Rect2i(left + 14, y, 51, 1), slit)
	_trim_console_side(back)
	_paint_face(atlas, FACE_BACK, back)

	for cell: Vector2i in [FACE_LEFT, FACE_RIGHT]:
		var end := _speckle(80, 80, seam, 0.03)
		end.fill_rect(Rect2i(1, 6, 78, 62), _shade(DESK_STEEL, 0.93))
		end.fill_rect(Rect2i(1, 6, 78, 1), _shade(DESK_STEEL, 1.15))
		for y in range(16, 32, 3):
			end.fill_rect(Rect2i(14, y, 52, 1), slit)
		_trim_console_side(end)
		_paint_face(atlas, cell, end)

	# The top: bare steel in four lengths, with a line where each joins the
	# next.
	var top := _speckle(320, 80, DESK_STEEL, 0.03)
	top.fill_rect(Rect2i(0, 0, 320, 1), _shade(DESK_STEEL, 1.15))  # light on the far edge
	for joint: int in [80, 160, 240]:
		top.fill_rect(Rect2i(joint, 0, 1, 80), _shade(DESK_STEEL, 0.75))

	# The plate at the left end. On its left is the emergency stop: a yellow
	# square for the scene's red StopButton to stand in the middle of. On its
	# right is the mains switch, a knob with a white line that turns from 0
	# round to 1. It is at 1. A line down the plate keeps the two apart, so
	# that their names don't read as one order.
	_paint_console_plate(top, Rect2i(6, 38, 47, 33))
	_draw_text(top, "STOP", Vector2i(10, 41), CONSOLE_WHITE)
	top.fill_rect(Rect2i(9, 49, 16, 16), CONSOLE_YELLOW)
	top.fill_rect(Rect2i(27, 40, 1, 29), CONSOLE_BEZEL)
	_draw_text(top, "MAINS", Vector2i(30, 41), CONSOLE_WHITE)
	for y in range(52, 63):
		for x in range(34, 45):
			var distance := Vector2(x - 39, y - 57).length()
			if distance < 5.3:
				top.set_pixel(x, y, CONSOLE_CHROME if distance > 3.3 else CONSOLE_BEZEL)
	for step in range(1, 4):
		top.set_pixel(39 + step, 57 - step, CONSOLE_WHITE)
	_draw_text(top, "0", Vector2i(29, 55), CONSOLE_WHITE)
	_draw_text(top, "1", Vector2i(47, 55), CONSOLE_WHITE)

	# The intercom, between the keyboard and the papers: a grille with the
	# loudspeaker behind it.
	_paint_console_plate(top, Rect2i(112, 50, 25, 21))
	_draw_text(top, "CALL", Vector2i(117, 53), CONSOLE_WHITE)
	top.fill_rect(Rect2i(116, 60, 17, 7), CONSOLE_BEZEL)
	for y in range(61, 66, 2):
		for x in range(117, 132, 2):
			top.set_pixel(x, y, Color(0.03, 0.03, 0.04))

	# The plate at the right end, with the four things the manual tells the
	# operator to do when something gets out: seal the vents, cut the lift,
	# lock the room and ring the bell. Each has its name over a collar for
	# one of the scene's lit buttons. They are 18 pixels (22.5 cm) apart,
	# which leaves three clear pixels between one name and the next.
	_paint_console_plate(top, Rect2i(240, 50, 75, 21))
	var names := ["VENT", "LIFT", "LOCK", "BELL"]
	for button in names.size():
		var middle := 250 + button * 18
		_draw_text(top, names[button], Vector2i(middle - 7, 53), CONSOLE_WHITE)
		top.fill_rect(Rect2i(middle - 4, 60, 8, 8), CONSOLE_BEZEL)
	_paint_face(atlas, FACE_TOP, top)
	_paint_face(atlas, FACE_BOTTOM, _speckle(320, 80, _shade(DESK_STEEL, 0.3), 0.03))
	return atlas


## Finishes one of the console's four upright sides: the edge of its top
## along the top, with the shadow under it, and the dark plinth it stands on
## along the floor, set back so that feet fit under the doors.
func _trim_console_side(side: Image) -> void:
	var width := side.get_width()
	side.fill_rect(Rect2i(0, 0, width, 3), _shade(DESK_STEEL, 1.15))
	side.fill_rect(Rect2i(0, 3, width, 1), _shade(DESK_STEEL, 0.45))
	side.fill_rect(Rect2i(0, 70, width, 10), _shade(DESK_STEEL, 0.3))


## Paints a control plate on a picture: black, the kind that has white
## letters engraved in it, with light along its far edge and a screw in each
## corner.
func _paint_console_plate(image: Image, plate: Rect2i) -> void:
	var metal := _speckle(plate.size.x, plate.size.y, CONSOLE_PLATE, 0.06)
	# blit_rect copies one picture (here, all of it) into another.
	image.blit_rect(metal, Rect2i(Vector2i.ZERO, plate.size), plate.position)
	image.fill_rect(Rect2i(plate.position, Vector2i(plate.size.x, 1)), _shade(CONSOLE_PLATE, 2.2))
	var last := plate.size - Vector2i(2, 2)
	for corner: Vector2i in [Vector2i(1, 1), Vector2i(last.x, 1), Vector2i(1, last.y), last]:
		image.set_pixelv(plate.position + corner, CONSOLE_CHROME)


## The atlas for one of the console's sloping panels, "width" pixels long
## (80 to the metre), with "slope" as the picture on its sloping side. The
## slope is 40 cm from top to bottom, so every picture is 32 tall. The
## panel's ends are plain steel and its upright back has slits in it.
func _make_console_panel(slope: Image) -> Image:
	var width := slope.get_width()
	var atlas := _new_atlas(width, 32)
	for cell: Vector2i in [PRISM_FRONT, PRISM_BACK, PRISM_BOTTOM]:
		_paint_face(atlas, cell, _speckle(width, 32, _shade(DESK_STEEL, 0.93), 0.03))
	var back := _speckle(width, 32, _shade(DESK_STEEL, 0.9), 0.03)
	back.fill_rect(Rect2i(0, 0, width, 1), _shade(DESK_STEEL, 1.15))
	for y in range(8, 24, 4):
		back.fill_rect(Rect2i(6, y, width - 12, 1), _shade(DESK_STEEL, 0.4))
	_paint_face(atlas, PRISM_LEFT, back)
	_paint_face(atlas, PRISM_RIGHT, slope)
	return atlas


## The face of a sloping panel with no instruments on it yet: a black plate
## with a rim of the console's steel showing round it.
func _new_console_slope(width: int) -> Image:
	var slope := _speckle(width, 32, DESK_STEEL, 0.03)
	_paint_console_plate(slope, Rect2i(1, 1, width - 2, 30))
	return slope


## The left-hand panel, 60 cm long: the power coming in. Two round gauges,
## for the volts and the amps, under three small lamps.
func _make_control_console_power() -> Image:
	var slope := _new_console_slope(48)
	_draw_text(slope, "POWER", Vector2i(4, 3), CONSOLE_WHITE)
	slope.fill_rect(Rect2i(32, 4, 2, 2), CONSOLE_GREEN)
	slope.fill_rect(Rect2i(36, 4, 2, 2), CONSOLE_GREEN)
	slope.fill_rect(Rect2i(40, 4, 2, 2), CONSOLE_AMBER)
	_draw_dial(slope, Vector2i(13, 17), 6, 0.55)
	_draw_text(slope, "VOLT", Vector2i(6, 25), CONSOLE_WHITE)
	_draw_dial(slope, Vector2i(34, 17), 6, 0.2)
	_draw_text(slope, "AMP", Vector2i(29, 25), CONSOLE_WHITE)
	return _make_console_panel(slope)


## Paints a round gauge: a pale face in a chrome rim, with the top end of
## its scale marked in red, and a needle. "reading" is where the needle
## points: 0 is low on the left, 0.5 straight up and 1 low on the right.
func _draw_dial(image: Image, centre: Vector2i, radius: int, reading: float) -> void:
	for y in range(centre.y - radius, centre.y + radius + 1):
		for x in range(centre.x - radius, centre.x + radius + 1):
			var offset := Vector2(x - centre.x, y - centre.y)
			var distance := offset.length()
			if distance > radius + 0.3:
				continue  # outside the gauge: leave the corner of the square alone
			if distance > radius - 0.7:
				image.set_pixel(x, y, CONSOLE_CHROME)
			elif distance > radius - 2.7 and offset.x > 0.0 and offset.y < 0.0:
				image.set_pixel(x, y, CONSOLE_RED)  # the upper right of the scale
			else:
				image.set_pixel(x, y, Color(0.88, 0.86, 0.76))
	# The needle swings through a third of a circle, from 150 degrees round
	# to 30 (measured the usual way, anticlockwise from "three o'clock").
	var angle := lerpf(PI * 5.0 / 6.0, PI / 6.0, reading)
	# Up the picture is towards smaller y, hence the minus.
	var reach := Vector2(cos(angle), -sin(angle)) * (radius - 2)
	for step in radius * 2 + 1:
		var point := Vector2(centre) + reach * (step / (radius * 2.0))
		image.set_pixel(roundi(point.x), roundi(point.y), Color(0.10, 0.10, 0.12))


## The middle panel, 1 m long: the three holding cells. Each has a long lamp
## with its number cut out of the light, and a word under it. Cells 1 and 2
## are green and SHUT. Cell 3, the one with the bars torn out of it, is red
## and OPEN.
func _make_control_console_cells() -> Image:
	var slope := _new_console_slope(80)
	_draw_text(slope, "HOLDING CELLS", Vector2i(4, 3), CONSOLE_WHITE)
	for cell in 3:
		var left := 4 + cell * 25
		var open := cell == 2
		slope.fill_rect(Rect2i(left, 10, 23, 9), CONSOLE_BEZEL)
		slope.fill_rect(Rect2i(left + 1, 11, 21, 7), CONSOLE_RED if open else CONSOLE_GREEN)
		_draw_text(slope, str(cell + 1), Vector2i(left + 10, 12), CONSOLE_PLATE)
		_draw_text(slope, "OPEN" if open else "SHUT", Vector2i(left + 4, 22), CONSOLE_WHITE)
	return _make_console_panel(slope)


## The right-hand panel, 85 cm long. On the left is a small round-cornered
## screen with a green line being drawn across it: subject 7's pulse, which
## is flat (the notebook on the desk says so too, and that subject 7 is
## walking about all the same). On the right are three rows of lamps over a
## row of switches, two of them down.
func _make_control_console_pulse() -> Image:
	var slope := _new_console_slope(68)
	slope.fill_rect(Rect2i(4, 4, 34, 17), CONSOLE_BEZEL)
	slope.fill_rect(Rect2i(5, 5, 32, 15), SCREEN_DARK)
	for y in range(8, 20, 4):
		for x in range(8, 37, 4):
			slope.set_pixel(x, y, _shade(SCREEN_GREEN, 0.3))  # the grid, a dot at each crossing
	slope.fill_rect(Rect2i(6, 13, 29, 1), SCREEN_GREEN)
	slope.set_pixel(35, 13, Color(0.85, 1.0, 0.88))  # the bright spot that draws the line
	for corner: Vector2i in [Vector2i(5, 5), Vector2i(36, 5), Vector2i(5, 19), Vector2i(36, 19)]:
		slope.set_pixelv(corner, CONSOLE_BEZEL)
	_draw_text(slope, "SUBJ 7", Vector2i(4, 24), CONSOLE_WHITE)

	# One letter for each lamp: Green, Amber, Red.
	var lamps := ["GGAG", "GRGG", "AGGR"]
	for row in lamps.size():
		var line: String = lamps[row]
		for column in line.length():
			var color := CONSOLE_GREEN
			if line[column] == "A":
				color = CONSOLE_AMBER
			elif line[column] == "R":
				color = CONSOLE_RED
			slope.fill_rect(Rect2i(43 + column * 6, 4 + row * 5, 3, 3), color)
	for toggle in 4:
		# A switch is a dark slot seven pixels tall with a chrome lever in
		# the top or the bottom of it.
		var down := toggle == 1 or toggle == 3
		slope.fill_rect(Rect2i(43 + toggle * 6, 21, 3, 7), Color(0.02, 0.02, 0.03))
		slope.fill_rect(Rect2i(43 + toggle * 6, 25 if down else 21, 3, 3), CONSOLE_CHROME)
	return _make_console_panel(slope)


# --- The fire extinguisher -----------------------------------------------------
#
# The extinguisher hanging on the south wall of start-level-demo's control
# room is two meshes in the level itself (Details/Extinguisher and
# Details/ExtinguisherNozzle): a cylinder with a small box on top of it for
# the valve. These are their two pictures, at the desk equipment's 80 pixels
# to the metre.

const EXTINGUISHER_RED := Color(0.78, 0.10, 0.08)
const EXTINGUISHER_BLACK := Color(0.08, 0.08, 0.09)
const EXTINGUISHER_STEEL := Color(0.58, 0.60, 0.61)
const EXTINGUISHER_LABEL := Color(0.93, 0.92, 0.86)


## The extinguisher's cylinder: 16 cm across and 45 cm tall. A cylinder
## lays its picture out as the coffee cup's does (see _make_cup): the top
## half, 40 x 36 here, wraps once round the side, and the bottom half holds
## the two ends as discs side by side.
##
## The two edges of the top half meet at the back, against the wall, so its
## middle is the front. Only the middle third or so of the picture can be
## seen properly from in front (the rest is turning away round the sides),
## so the label is kept to twelve pixels: a flame, two lines of
## instructions too small to read, and the letters of the three kinds of
## fire it puts out, each on its own colour. Just to the right of the label
## the black hose hangs down from the valve to its nozzle, and just to the
## left is a streak of light on the paint. Round the cylinder go a cream
## band near the top (the colour says what is inside), the steel strap that
## holds it to the wall, and the black rubber foot it stands on when it is
## taken down.
func _make_fire_extinguisher() -> Image:
	var picture := _speckle(40, 72, EXTINGUISHER_RED, 0.04)
	var ink := Color(0.16, 0.16, 0.20)

	picture.fill_rect(Rect2i(11, 2, 2, 31), _shade(EXTINGUISHER_RED, 1.35))  # the streak of light
	picture.fill_rect(Rect2i(0, 0, 40, 2), EXTINGUISHER_STEEL)  # the collar the valve screws into
	picture.fill_rect(Rect2i(0, 2, 40, 1), _shade(EXTINGUISHER_RED, 1.2))  # light on the shoulder
	picture.fill_rect(Rect2i(0, 4, 40, 2), Color(0.90, 0.84, 0.62))  # the cream band

	picture.fill_rect(Rect2i(14, 7, 12, 21), EXTINGUISHER_LABEL)
	# The flame: "R" is its orange-red and "Y" the yellow at its heart.
	var flame := [
		"..R...",
		"..RR..",
		".RRR..",
		".RRRR.",
		"RRYRRR",
		"RYYYRR",
		"RYYYRR",
		".RYYR.",
	]
	var flame_colors := {"R": Color(0.90, 0.30, 0.08), "Y": Color(1.0, 0.80, 0.15)}
	for row in flame.size():
		var line: String = flame[row]
		for column in line.length():
			if flame_colors.has(line[column]):
				picture.set_pixel(17 + column, 8 + row, flame_colors[line[column]])
	picture.fill_rect(Rect2i(15, 17, 10, 1), ink)
	picture.fill_rect(Rect2i(15, 19, 7, 1), ink)
	var kinds := [Color(0.15, 0.55, 0.25), Color(0.80, 0.14, 0.12), Color(0.15, 0.30, 0.70)]
	for kind in 3:
		# A patch four pixels wide across the foot of the label, with A, B
		# or C on it in white. Three of them are exactly as wide as the
		# label, and four pixels is also what the font allows a letter.
		picture.fill_rect(Rect2i(14 + kind * 4, 21, 4, 7), kinds[kind])
		_draw_text(picture, "ABC"[kind], Vector2i(14 + kind * 4, 22), EXTINGUISHER_LABEL)

	picture.fill_rect(Rect2i(0, 29, 40, 2), EXTINGUISHER_STEEL)  # the strap
	picture.fill_rect(Rect2i(19, 29, 2, 2), _shade(EXTINGUISHER_STEEL, 0.55))  # its buckle
	picture.fill_rect(Rect2i(0, 31, 40, 1), _shade(EXTINGUISHER_RED, 0.6))  # the strap's shadow
	picture.fill_rect(Rect2i(0, 33, 40, 3), EXTINGUISHER_BLACK)  # the rubber foot
	picture.fill_rect(Rect2i(28, 0, 2, 22), EXTINGUISHER_BLACK)  # the hose
	picture.fill_rect(Rect2i(27, 22, 4, 5), EXTINGUISHER_BLACK)  # its nozzle
	picture.fill_rect(Rect2i(27, 26, 4, 1), _shade(EXTINGUISHER_STEEL, 0.55))  # the nozzle's open end

	for y in 36:
		for x in 20:
			# How far this pixel is from the middle of its disc: 1 at the rim.
			var distance := Vector2((x + 0.5 - 10.0) / 10.0, (y + 0.5 - 18.0) / 18.0).length()
			# The top: red, with the steel neck the valve stands on in the
			# middle. The underside: all rubber.
			picture.set_pixel(x, 36 + y, EXTINGUISHER_STEEL if distance < 0.45 else _shade(EXTINGUISHER_RED, 1.1))
			picture.set_pixel(20 + x, 36 + y, EXTINGUISHER_BLACK)
	return picture


## The valve on top of the extinguisher: a black box 6 cm square and 8 cm
## tall, each side drawn 5 x 6. On the side that faces the room is the
## pressure gauge, a white dial with a green mark at the top (where the
## needle should be) and the needle's black middle. The steel lever you
## squeeze runs across the top from front to back, and the yellow ring of
## the safety pin shows on each side.
func _make_fire_extinguisher_valve() -> Image:
	var atlas := _new_atlas(5, 6)
	var body := Color(0.13, 0.13, 0.14)
	var front := _speckle(5, 6, body, 0.05)
	front.fill_rect(Rect2i(1, 1, 3, 3), Color(0.92, 0.92, 0.88))
	front.set_pixel(2, 1, Color(0.20, 0.75, 0.30))
	front.set_pixel(2, 2, EXTINGUISHER_BLACK)
	_paint_face(atlas, FACE_FRONT, front)
	_paint_face(atlas, FACE_BACK, _speckle(5, 6, body, 0.05))
	for cell: Vector2i in [FACE_LEFT, FACE_RIGHT]:
		var side := _speckle(5, 6, body, 0.05)
		side.fill_rect(Rect2i(0, 0, 5, 1), EXTINGUISHER_STEEL)  # the edge of the lever
		side.set_pixel(2, 2, Color(0.92, 0.76, 0.10))
		_paint_face(atlas, cell, side)
	var top := _speckle(5, 6, body, 0.05)
	top.fill_rect(Rect2i(1, 0, 3, 6), EXTINGUISHER_STEEL)
	_paint_face(atlas, FACE_TOP, top)
	_paint_face(atlas, FACE_BOTTOM, _speckle(5, 6, body, 0.05))
	return atlas


## A poster to keep the staff's spirits up, 60 x 80 cm. It is the well-known
## one of a kitten clinging to a branch by its front paws over the words
## HANG IN THERE, except that this is a penguin: a bird that cannot fly, a
## long way up, above the clouds, and sweating.
##
## In the picture of the penguin below, "#" is black, "W" is white and "O"
## is the orange of its beak and feet. Its two flippers are the long black
## bars at the sides. Their ends are hooked over the branch, which is three
## rows thick and passes behind the second to fourth rows.
func _make_poster_penguin() -> Image:
	var poster := _new_poster(48, 64, Color(0.93, 0.93, 0.91))
	var sky := Color(0.50, 0.75, 0.93)
	var cloud := Color(0.95, 0.97, 1.0)
	var bark := Color(0.42, 0.27, 0.13)
	var leaf := Color(0.25, 0.55, 0.20)
	var black := Color(0.10, 0.11, 0.14)
	var white := Color(0.96, 0.96, 0.94)
	var orange := Color(0.95, 0.55, 0.10)

	# The photograph, with a white margin round it: sky, two clouds a long
	# way below and a small one further off.
	poster.fill_rect(Rect2i(3, 3, 42, 43), sky)
	for puff: Rect2i in [
		Rect2i(5, 42, 13, 4), Rect2i(8, 41, 7, 1),
		Rect2i(27, 43, 15, 3), Rect2i(31, 42, 8, 1),
		Rect2i(6, 21, 7, 2), Rect2i(8, 20, 3, 1),
	]:
		poster.fill_rect(puff, cloud)

	# The branch, lit from above, with a twig and two leaves near its end.
	poster.fill_rect(Rect2i(3, 9, 42, 3), bark)
	poster.fill_rect(Rect2i(3, 9, 42, 1), _shade(bark, 1.3))
	poster.fill_rect(Rect2i(3, 11, 42, 1), _shade(bark, 0.7))
	poster.set_pixel(38, 8, bark)
	poster.set_pixel(39, 7, bark)
	poster.fill_rect(Rect2i(40, 5, 3, 2), leaf)
	poster.fill_rect(Rect2i(35, 6, 3, 2), leaf)

	var penguin := [
		"##..........##",
		"##..........##",
		"##..........##",
		"##..........##",
		"##..........##",
		"##..........##",
		"##...####...##",
		"##..######..##",
		"##.########.##",
		"##.#WW##WW#.##",
		"##.#W#OO#W#.##",
		"##.###OO###.##",
		"##..######..##",
		"##############",
		"..###WWWW###..",
		"..##WWWWWW##..",
		"..##WWWWWW##..",
		".###WWWWWW###.",
		".##WWWWWWWW##.",
		".##WWWWWWWW##.",
		".##WWWWWWWW##.",
		".##WWWWWWWW##.",
		".##WWWWWWWW##.",
		".###WWWWWW###.",
		"..##########..",
		"...OOO..OOO...",
		"...OOO..OOO...",
	]
	var colors := {"#": black, "W": white, "O": orange}
	for row in penguin.size():
		var line: String = penguin[row]
		for column in line.length():
			if colors.has(line[column]):
				# 14 pixels wide in a poster of 48 leaves 17 on either side.
				poster.set_pixel(17 + column, 8 + row, colors[line[column]])
	# Two drops of sweat flying off its head.
	poster.fill_rect(Rect2i(33, 13, 1, 2), Color(0.20, 0.45, 0.85))
	poster.fill_rect(Rect2i(35, 16, 1, 2), Color(0.20, 0.45, 0.85))

	var ink := Color(0.12, 0.18, 0.40)
	_draw_text_centred(poster, "HANG IN", 49, ink)
	_draw_text_centred(poster, "THERE!", 56, ink)
	return poster
