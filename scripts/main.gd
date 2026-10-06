extends Control
## Root of the game. Owns the low-resolution rendering pipeline.
##
## How it works:
##   1. The whole game (3D world + HUD) lives inside a SubViewport, which is
##      an off-screen "virtual screen" with a small fixed size (320x240).
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
## It also loads the level, and swaps it for the next or previous one in its
## Levels list when F2 or F3 is pressed.

## The resolution the game is rendered at. THIS IS THE ONE PLACE TO CHANGE IT.
## Try Vector2i(640, 480) for a sharper, late-90s "high-res mode" look.
## (You can also change it in the Inspector by selecting the Main node.)
@export var render_size := Vector2i(320, 240)

## If true, only scale by whole numbers (2x, 3x, 4x...). Every game pixel is
## then exactly the same size on screen, at the cost of thicker black bars.
## If false, the picture fills as much of the window as possible.
@export var integer_scaling := false

## Every level in the game, in the order F2 steps through them. The game
## starts in the first one. To add a level, add its .tscn file to this list
## in the Inspector (select the Main node in scenes/main.tscn).
@export var levels: Array[PackedScene] = []

## Which entry of Levels is being played. "static" keeps the number when the
## whole game is reloaded after the player dies, so you restart in the level
## you died in instead of being sent back to the first one.
static var level_index := 0

## The file of a level scene that was run on its own (F6 in the editor)
## rather than through this scene, or "" if the game was started normally.
## scripts/level_launcher.gd sets it. It is kept for the whole run, because a
## level that isn't in Levels has to be added again after every reload.
static var direct_level_path := ""
## True until the level above has been opened once. After that F2 and F3 are
## free to move away from it.
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

	# "resized" is emitted whenever this Control changes size, which happens
	# whenever the window does (it is anchored to fill the whole window).
	resized.connect(_fit_to_window)
	_fit_to_window()
	_use_direct_level()
	_load_level()


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
	# F2 and F3 step forwards and backwards through the levels. posmod wraps
	# around, so going past the last level comes back to the first.
	if event.is_action_pressed("level_next"):
		level_index = posmod(level_index + 1, levels.size())
		_load_level()
	elif event.is_action_pressed("level_previous"):
		level_index = posmod(level_index - 1, levels.size())
		_load_level()


## Removes the level being played (if any) and puts levels[level_index] in
## its place.
func _load_level() -> void:
	if is_instance_valid(level):
		game_viewport.remove_child(level)
		level.queue_free()  # removes the old level and everything in it

	level = levels[level_index].instantiate()
	# The ViewportContainer is set to keep running while the game is paused
	# (so the pause menu still gets the keyboard and mouse), and everything
	# inside it copies that. Make the level freeze with the pause instead.
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
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
