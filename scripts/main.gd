extends Control
## Root of the game. Owns the low-resolution rendering pipeline.
##
## How it works:
##   1. The whole game (3D world + HUD) lives inside a SubViewport, which is
##      an off-screen "virtual screen" with a small fixed size (640x480
##      for now: see Render Size below). The HUD and the menus are drawn as
##      if it were 320x240 and stretched to fit it.
##   2. A SubViewportContainer shows that small image in the real window.
##   3. This script scales the container up to fill the window, keeping the
##      4:3 shape. Because the container uses nearest-neighbour filtering,
##      every low-res pixel becomes a sharp square instead of a blurry blob.
##   4. Whatever window area is left over shows the black ColorRect behind
##      it. Those are the letterbox bars.
##   5. The container also has a small shader (shaders/color_quantize.gdshader)
##      that reduces the number of colours in the final picture. F1 and the
##      pause menu (scripts/pause_menu.gd) switch it on and off.
##
## It also loads the level, and starts it again from the beginning when F5
## is pressed (see restart_level() below). It can swap it for the next or
## previous one in its Levels list when F2 or F3 is pressed, but that is
## switched off for now (see Level Switching below). In multiplayer only the
## host does any of that: scripts/network.gd shares the host's level with
## everyone else.

## How tall a picture the HUD, the pause menu and the notebook's page are
## laid out for, in pixels. They were all drawn for the 320 x 240 the game
## was first made at, with their places and sizes given in pixels of that
## picture. _scale_interface() stretches them to fit whatever Render Size
## is, so this only needs changing if they are drawn again for another size.
const INTERFACE_HEIGHT := 240

## The resolution the game is rendered at. THIS IS THE ONE PLACE TO CHANGE IT.
## It is 640 x 480 for now: a sharper, late-90s "high-res mode" look. The
## game was made at 320 x 240, and the line for that is kept below, switched
## off with a "#", to go back to.
## (You can also change it in the Inspector by selecting the Main node.)
##
## The HUD, the pause menu and the notebook's page stay the same size on
## screen whichever you choose (see _scale_interface() below). They keep
## their chunky pixels: at 640 x 480 each of their pixels is drawn 2 x 2.
#@export var render_size := Vector2i(320, 240)
@export var render_size := Vector2i(640, 480)

## If true, only scale by whole numbers (2x, 3x, 4x...). Every game pixel is
## then exactly the same size on screen, at the cost of thicker black bars.
## If false, the picture fills as much of the window as possible.
@export var integer_scaling := false

## Every level in the game, in the order F2 steps through them (while Level
## Switching is on). A game started on this scene opens the first one. But
## the project's main scene is a level, levels/start-level-demo.tscn, and a
## game started on a level opens that level: see direct_level_path below.
## To add a level, add its .tscn file to this list in the Inspector (select
## the Main node in scenes/main.tscn).
@export var levels: Array[PackedScene] = []

## If true, F2 and F3 swap the level for the next or the previous one in
## Levels. It is off for now: the game is one level, the start level demo.
## The other levels are still in the list, and any of them can be played by
## opening it in the editor and pressing F6 (Run Current Scene).
@export var level_switching := false

## Which entry of Levels is being played. "static" keeps the number when the
## whole game is reloaded (after the player dies, or when F5 is pressed), so
## you restart in the level you were in instead of being sent back to the
## first one.
static var level_index := 0

## The file of the level scene the game was started on, or "" if it was
## started on this scene instead. Starting on a level is the usual way now:
## the project's main scene is one, and F6 in the editor runs whichever level
## is open. scripts/level_launcher.gd sets it. It is kept for the whole run,
## because a level that isn't in Levels has to be added again after every
## reload.
static var direct_level_path := ""
## True until the level above has been opened once. After that F2 and F3 are
## free to move away from it (while Level Switching is on).
static var open_direct_level := false

## The level currently loaded inside the low-res viewport.
var level: Node

@onready var viewport_container: SubViewportContainer = $ViewportContainer
@onready var game_viewport: SubViewport = $ViewportContainer/GameViewport


func _ready() -> void:
	# Apply the chosen resolution to the off-screen viewport, and make the
	# container exactly the same size so it shows the image 1:1 before scaling.
	game_viewport.size = render_size
	viewport_container.size = Vector2(render_size)
	_scale_interface()

	# "resized" is emitted whenever this Control changes size, which happens
	# whenever the window does (it is anchored to fill the whole window).
	resized.connect(_fit_to_window)
	_fit_to_window()
	Network.register_main(self)
	_use_direct_level()
	load_level()


## Keeps the HUD, the pause menu and the notebook's page the same size on
## screen whatever Render Size is.
##
## Everything flat that is drawn inside the viewport (its "2D" contents, as
## opposed to the 3D level) is placed in pixels, counted from the top left
## corner: the notebook's page starts 50 across and 8 down, for one. Those
## numbers were chosen for a picture 320 x 240. On a bigger picture they
## would leave everything too small, and the page up in the corner.
##
## A viewport can be told that its 2D contents are a different size from the
## picture it really makes, and to stretch the one to fit the other. So the
## 2D size is always INTERFACE_HEIGHT (240) tall, and as wide as that makes
## it for the picture's shape: 320 for 4:3. The 3D level is not touched by
## this, and is drawn at the full Render Size.
##
## The mouse is converted the same way: a click reaches the pause menu as a
## place in the 320 x 240 picture, which is where its rows think they are.
func _scale_interface() -> void:
	# How many real pixels one pixel of the interface covers: 2 at 640 x 480.
	var pixel_size := float(render_size.y) / INTERFACE_HEIGHT
	game_viewport.size_2d_override = Vector2i(roundi(render_size.x / pixel_size), INTERFACE_HEIGHT)
	game_viewport.size_2d_override_stretch = true


## Handles a level scene that was run on its own: makes sure it is in Levels
## and, the first time, starts the game in it.
func _use_direct_level() -> void:
	if direct_level_path.is_empty():
		return

	# Look for the level in the list. resource_path is the file a resource
	# was loaded from.
	var index := -1
	for i in levels.size():
		if levels[i].resource_path == direct_level_path:
			index = i
	# A level that hasn't been added to Levels yet goes on the end, so it can
	# be played (and reached with F2 and F3) anyway.
	if index == -1:
		levels.append(load(direct_level_path))
		index = levels.size() - 1

	if open_direct_level:
		level_index = index
		open_direct_level = false


func _unhandled_input(event: InputEvent) -> void:
	# F5 starts the level again. (This one works whether Level Switching is
	# on or not. It doesn't work while the game is paused, by the menu or by
	# a notebook's page: a paused node, as this one then is, gets no input.)
	if event.is_action_pressed("level_restart"):
		restart_level()
		return

	# Changing level is switched off for now (see Level Switching above).
	if not level_switching:
		return
	# In multiplayer the host picks the level for everyone.
	if Network.is_client():
		return
	# F2 and F3 step forwards and backwards through the levels. posmod wraps
	# around, so going past the last level comes back to the first.
	if event.is_action_pressed("level_next"):
		level_index = posmod(level_index + 1, levels.size())
		load_level()
	elif event.is_action_pressed("level_previous"):
		level_index = posmod(level_index - 1, levels.size())
		load_level()


## Starts the level being played again from the beginning: every enemy back
## on its feet where it first stood, every crate and window whole, and the
## player at the start with full health. F5 (the "level_restart" action)
## calls it.
func restart_level() -> void:
	# In multiplayer the host's level is everyone's, so only the host may.
	if Network.is_client():
		return
	if Network.is_online():
		# Hosting: a fresh copy of the level for everyone, each with a new
		# player in it, just as when the host changes level.
		load_level()
	else:
		# On your own, do what dying does: load the whole game (this scene)
		# again. level_index is static, so it comes back in the same level.
		get_tree().reload_current_scene()


## Removes the level being played (if any) and puts levels[level_index] in
## its place. When hosting, everyone else gets the new level too.
func load_level() -> void:
	clear_level()
	if Network.is_online():
		if multiplayer.is_server():
			# The network's level spawner makes the level on every computer
			# and hands it back through adopt_level().
			Network.spawn_level(level_index)
		return
	adopt_level(levels[level_index].instantiate())


## Removes the level being played, and everything in it.
func clear_level() -> void:
	if is_instance_valid(level):
		game_viewport.remove_child(level)
		level.queue_free()
	level = null


## Makes "new_level" the level being played, adding it to the viewport if it
## isn't there yet. (The network's spawner adds the levels it makes itself.)
func adopt_level(new_level: Node) -> void:
	level = new_level
	# The ViewportContainer is set to keep running while the game is paused
	# (so the pause menu still gets the keyboard and mouse), and everything
	# inside it copies that. Make the level freeze with the pause instead.
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	if not level.is_inside_tree():
		game_viewport.add_child(level)
	# Keep the level first in the list, so the HUD is drawn on top of it.
	game_viewport.move_child(level, 0)


## Scales and centres the low-res image inside the window.
func _fit_to_window() -> void:
	var window_size := size
	var image_size := Vector2(render_size)

	# The largest scale at which the image still fits both across and down.
	var fit_scale := minf(window_size.x / image_size.x, window_size.y / image_size.y)
	if integer_scaling:
		fit_scale = maxf(1.0, floorf(fit_scale))

	viewport_container.scale = Vector2(fit_scale, fit_scale)
	# Centre it. floor() keeps it on a whole pixel so the edges stay crisp.
	viewport_container.position = ((window_size - image_size * fit_scale) / 2.0).floor()
