extends CanvasLayer
## Pause menu: Esc freezes the game and shows RESUME, GRAPHICS, MULTIPLAYER
## and QUIT. GRAPHICS opens a page with switches for the retro effects, the
## view bob and fullscreen, and MULTIPLAYER one for hosting or joining a game (see
## scripts/network.gd).
##
## Online, the menu can't freeze the game: the other players carry on. It
## just frees the mouse, and the player ignores the keyboard while it is open.
##
## Pausing: setting get_tree().paused to true stops every node whose Process
## Mode is "Pausable": no _process, no physics, no input. This menu's mode is
## "Always" (see scenes/pause_menu.tscn), so it keeps running and can unpause
## the game again. The ViewportContainer in scenes/main.tscn is "Always" too,
## because it has to keep passing the keyboard and mouse in to this menu; the
## level and the HUD are set back to "Pausable" so they still freeze.
##
## Pages: each page is a Control in the scene holding its own title and a
## "Rows" node with one child per line. Only one page is visible at a time,
## and "rows" below is filled from whichever one that is, so adding a line to
## a page is mostly a matter of adding a node to its Rows in the scene.
##
## The effects are "global shader parameters", listed in Project Settings >
## Globals > Shader Globals. A normal shader setting belongs to one material;
## a global one is shared by every shader that declares it, so a single
## RenderingServer call changes every wall, prop and the post-process at once.
## (See the notes at the top of shaders/retro_surface.gdshader.)
##
## Keys: up/down (or W/S) choose a line, left/right (or A/D) turn a setting
## down or up, Enter presses it. With the mouse, point at a line and click.
## On the JOIN line, the number keys, "." and Backspace edit the address.
## Esc goes back from the other pages, and resumes from the first page.

## The steps VERTEX SNAP and LIGHT BANDS go through. 1 = full strength
## (exactly as set in the shader and the materials), 0 = off.
const STRENGTH_STEPS: Array[float] = [0.0, 0.25, 0.5, 0.75, 1.0]

## Colour of the line the cursor is on.
@export var selected_color := Color(1.0, 0.82, 0.35)
## Colour of the other lines.
@export var normal_color := Color(0.65, 0.55, 0.4)
## Colour of settings that do nothing while RETRO EFFECTS is off.
@export var inactive_color := Color(0.35, 0.35, 0.35)

# The current effect settings. "static" keeps them when the game reloads
# after the player dies (like level_index in scripts/main.gd), so a death
# doesn't put the effects back to their starting values.
static var retro_effects := true
static var snap_strength := 0.25
static var light_band_strength := 0.0
static var color_quantize := true
## Whether the camera bobs up and down as the player walks. This one isn't a
## shader setting: scripts/player.gd reads it every frame.
static var view_bob := true
## The address the JOIN line connects to. Kept between games, like the
## settings above.
static var join_address := "127.0.0.1"

## The lines of the page that is showing, top to bottom.
var rows: Array[Control] = []
## Which of "rows" the cursor is on (0 = the top line).
var selected := 0

@onready var cursor: Control = $Menu/Cursor
@onready var main_page: Control = $Menu/MainPage
@onready var graphics_page: Control = $Menu/GraphicsPage
@onready var multiplayer_page: Control = $Menu/MultiplayerPage

@onready var resume_row: Control = $Menu/MainPage/Rows/Resume
@onready var graphics_row: Control = $Menu/MainPage/Rows/Graphics
@onready var multiplayer_row: Control = $Menu/MainPage/Rows/Multiplayer
@onready var quit_row: Control = $Menu/MainPage/Rows/Quit

@onready var retro_effects_row: Control = $Menu/GraphicsPage/Rows/RetroEffects
@onready var snap_row: Control = $Menu/GraphicsPage/Rows/VertexSnap
@onready var light_bands_row: Control = $Menu/GraphicsPage/Rows/LightBands
@onready var color_quantize_row: Control = $Menu/GraphicsPage/Rows/ColorQuantize
@onready var view_bob_row: Control = $Menu/GraphicsPage/Rows/ViewBob
@onready var fullscreen_row: Control = $Menu/GraphicsPage/Rows/Fullscreen
@onready var back_row: Control = $Menu/GraphicsPage/Rows/Back
@onready var graphics_hint: Control = $Menu/GraphicsPage/Hint

@onready var host_row: Control = $Menu/MultiplayerPage/Rows/Host
@onready var join_row: Control = $Menu/MultiplayerPage/Rows/Join
@onready var leave_row: Control = $Menu/MultiplayerPage/Rows/Leave
@onready var multiplayer_back_row: Control = $Menu/MultiplayerPage/Rows/Back
@onready var status_text: Control = $Menu/MultiplayerPage/Status


# _static_init runs once, when this script is first loaded. It doesn't run
# again when the game reloads after a death, so the player's choices stay.
static func _static_init() -> void:
	# Start from the values in Project Settings. Each shader global is stored
	# there as a small Dictionary holding its "type" and its "value".
	retro_effects = ProjectSettings.get_setting("shader_globals/retro_effects")["value"]
	snap_strength = ProjectSettings.get_setting("shader_globals/retro_snap_strength")["value"]
	light_band_strength = ProjectSettings.get_setting("shader_globals/retro_light_band_strength")["value"]
	color_quantize = ProjectSettings.get_setting("shader_globals/retro_color_quantize")["value"]


func _ready() -> void:
	visible = false
	_apply_settings()
	_show_page(main_page)


func _unhandled_input(event: InputEvent) -> void:
	# F1 flips colour quantization at any time, paused or not.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		color_quantize = not color_quantize
		_apply_settings()
		_refresh()
		return

	# Esc (the built-in "ui_cancel" action) opens the menu, steps back from
	# the graphics page to the first page, and closes the menu from there.
	if event.is_action_pressed("ui_cancel"):
		if visible and graphics_page.visible:
			_show_page(main_page, graphics_row)
		elif visible and multiplayer_page.visible:
			_show_page(main_page, multiplayer_row)
		else:
			_set_open(not visible)
		get_viewport().set_input_as_handled()
		return

	# Everything below is only for while the menu is open.
	if not visible:
		return

	if rows[selected] == join_row and _edit_address(event):
		get_viewport().set_input_as_handled()
		return

	# The "true" lets a held key repeat, so holding down scrolls the cursor.
	if event.is_action_pressed("ui_up", true) or event.is_action_pressed("move_forward", true):
		_select(selected - 1)
	elif event.is_action_pressed("ui_down", true) or event.is_action_pressed("move_back", true):
		_select(selected + 1)
	elif event.is_action_pressed("ui_left", true) or event.is_action_pressed("move_left", true):
		_change(-1, false)
	elif event.is_action_pressed("ui_right", true) or event.is_action_pressed("move_right", true):
		_change(1, false)
	elif event.is_action_pressed("ui_accept"):
		_activate()
	elif event is InputEventMouseMotion:
		# Hovering over a line moves the cursor to it.
		var row := _row_at(event.position)
		if row != -1 and row != selected:
			_select(row)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var row := _row_at(event.position)
		if row != -1:
			_select(row)
			_activate()
	else:
		return

	# Mark the input as used, so nothing else reacts to it as well.
	get_viewport().set_input_as_handled()


## Shows or hides the menu, freezing or unfreezing the game with it (but
## online the game can't be frozen: everyone else is still playing).
func _set_open(open: bool) -> void:
	visible = open
	get_tree().paused = open and not Network.is_online()
	# Free the mouse pointer to use the menu, and capture it again to look
	# around once the game carries on.
	if open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_show_page(main_page)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Switches to a page and puts the cursor on "start_row", or on the page's
## top line if none is given.
func _show_page(page: Control, start_row: Control = null) -> void:
	main_page.visible = page == main_page
	graphics_page.visible = page == graphics_page
	multiplayer_page.visible = page == multiplayer_page
	# assign() copies the children across, checking that each one really is a
	# Control (get_children() only promises plain Nodes).
	rows.assign(page.get_node("Rows").get_children())
	# find() gives -1 if the row isn't on this page; max() turns that into 0.
	_select(maxi(rows.find(start_row), 0))


## Moves the cursor to a row. posmod wraps around, so going up from the top
## row lands on the bottom one.
func _select(row: int) -> void:
	selected = posmod(row, rows.size())
	_refresh()


## Enter or a click: presses a button line (RESUME, GRAPHICS, BACK, QUIT), or
## steps a setting down one notch (and from OFF back round to full strength).
func _activate() -> void:
	var row := rows[selected]
	if row == resume_row:
		_set_open(false)
	elif row == graphics_row:
		_show_page(graphics_page)
	elif row == back_row:
		_show_page(main_page, graphics_row)
	elif row == multiplayer_row:
		_show_page(multiplayer_page)
	elif row == multiplayer_back_row:
		_show_page(main_page, multiplayer_row)
	elif row == host_row and not Network.is_online():
		_set_open(false)
		Network.host()
	elif row == join_row and not Network.is_online():
		_set_open(false)
		Network.join(join_address)
	elif row == leave_row and Network.is_online():
		_set_open(false)
		Network.leave()
	elif row == quit_row:
		get_tree().quit()
	else:
		_change(-1, true)


## Turns the selected setting down (direction -1) or up (+1). On/off settings
## simply flip. "wrap" decides whether going past the end comes round to the
## other end or stops there.
func _change(direction: int, wrap: bool) -> void:
	var row := rows[selected]
	if row == retro_effects_row:
		retro_effects = not retro_effects
	elif row == snap_row:
		snap_strength = _step(snap_strength, direction, wrap)
	elif row == light_bands_row:
		light_band_strength = _step(light_band_strength, direction, wrap)
	elif row == color_quantize_row:
		color_quantize = not color_quantize
	elif row == view_bob_row:
		view_bob = not view_bob
	elif row == fullscreen_row:
		_set_fullscreen(not _is_fullscreen())
	else:
		return  # the button lines have nothing to turn up or down
	_apply_settings()
	_refresh()


## Returns the strength one notch up or down STRENGTH_STEPS from "value".
func _step(value: float, direction: int, wrap: bool) -> float:
	# Start from whichever step is closest, since Project Settings may hold a
	# value in between the steps.
	var index := 0
	for i in STRENGTH_STEPS.size():
		if absf(STRENGTH_STEPS[i] - value) < absf(STRENGTH_STEPS[index] - value):
			index = i

	index += direction
	if wrap:
		index = posmod(index, STRENGTH_STEPS.size())
	else:
		index = clampi(index, 0, STRENGTH_STEPS.size() - 1)
	return STRENGTH_STEPS[index]


## Sends the settings to the shaders. Every material in the game picks up the
## new values from the next frame on.
func _apply_settings() -> void:
	RenderingServer.global_shader_parameter_set(&"retro_effects", retro_effects)
	RenderingServer.global_shader_parameter_set(&"retro_snap_strength", snap_strength)
	RenderingServer.global_shader_parameter_set(&"retro_light_band_strength", light_band_strength)
	RenderingServer.global_shader_parameter_set(&"retro_color_quantize", color_quantize)


## True if the game fills the whole screen. This asks the window itself
## instead of keeping a copy of the setting here: the window isn't rebuilt
## when the game reloads after a death, so it remembers on its own.
func _is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


## True when the game is running inside the editor's own window (the Game
## tab at the top of the editor, which is where Play puts it unless "Embed
## Game on Next Play" is unticked in that tab's menu). The game is then a
## panel of the editor rather than a window of its own, and Godot ignores
## requests to make it fullscreen.
func _is_embedded() -> bool:
	return Engine.is_embedded_in_editor()


## Switches between filling the screen and an ordinary window. Either way
## scripts/main.gd notices the new size and rescales the picture to fit.
func _set_fullscreen(on: bool) -> void:
	if _is_embedded():
		return
	if on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


## Typing on the JOIN line: digits and "." add to the address, Backspace
## takes the last character off. Returns true if the key was used.
func _edit_address(event: InputEvent) -> bool:
	if not (event is InputEventKey and event.pressed):
		return false
	if event.keycode == KEY_BACKSPACE:
		join_address = join_address.left(-1)  # everything but the last one
	elif event.unicode == 0:
		return false  # unicode is the character a key types; 0 for keys like Enter
	else:
		var character := char(event.unicode)
		if not (character.is_valid_int() or character == ".") or join_address.length() >= 21:
			return false
		join_address += character
	_refresh()
	return true


# The multiplayer status can change while the menu is open (CONNECTING...),
# so keep it up to date. This menu runs even while the game is paused.
func _process(_delta: float) -> void:
	if visible and multiplayer_page.visible:
		status_text.text = Network.status


## Updates the words, colours and cursor to match the current settings.
func _refresh() -> void:
	# A setting's value (ON, 50% ...) is a child node called Value.
	retro_effects_row.get_node("Value").text = _on_off_text(retro_effects)
	snap_row.get_node("Value").text = _strength_text(snap_strength)
	light_bands_row.get_node("Value").text = _strength_text(light_band_strength)
	color_quantize_row.get_node("Value").text = _on_off_text(color_quantize)
	view_bob_row.get_node("Value").text = _on_off_text(view_bob)
	fullscreen_row.get_node("Value").text = _on_off_text(_is_fullscreen())
	join_row.get_node("Value").text = join_address
	status_text.text = Network.status
	# Hosting and joining only make sense in single player, leaving online.
	var online := Network.is_online()
	var unavailable: Array[Control] = [leave_row]
	if online:
		unavailable = [host_row, join_row]
	if _is_embedded():
		unavailable.append(fullscreen_row)
	# Say why FULLSCREEN does nothing, in place of the usual hint.
	if _is_embedded() and rows[selected] == fullscreen_row:
		graphics_hint.text = "NOT INSIDE THE EDITOR WINDOW"
	else:
		graphics_hint.text = "LEFT RIGHT OR CLICK TO CHANGE"

	for i in rows.size():
		var row := rows[i]
		var row_color := normal_color
		if i == selected:
			row_color = selected_color
		elif not retro_effects and row in [snap_row, light_bands_row, color_quantize_row]:
			row_color = inactive_color
		elif row in unavailable:
			row_color = inactive_color
		row.color = row_color
		# The Value child has its own colour.
		if row.has_node("Value"):
			row.get_node("Value").color = row_color

	# Put the cursor level with the selected row, just to the left of it.
	# (Each page fills the menu, so only its Rows node is offset.)
	cursor.position.y = rows[selected].get_parent().position.y + rows[selected].position.y


## Which row is under a point on the screen, or -1 if none is.
func _row_at(point: Vector2) -> int:
	for i in rows.size():
		if rows[i].get_global_rect().has_point(point):
			return i
	return -1


func _on_off_text(on: bool) -> String:
	return "ON" if on else "OFF"


func _strength_text(strength: float) -> String:
	if strength <= 0.0:
		return "OFF"
	return "%d%%" % roundi(strength * 100.0)
