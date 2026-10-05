extends CanvasLayer
## Pause menu: Esc freezes the game and shows switches for the retro effects.
##
## Pausing: setting get_tree().paused to true stops every node whose Process
## Mode is "Pausable": no _process, no physics, no input. This menu's mode is
## "Always" (see scenes/pause_menu.tscn), so it keeps running and can unpause
## the game again. The ViewportContainer in scenes/main.tscn is "Always" too,
## because it has to keep passing the keyboard and mouse in to this menu; the
## level and the HUD are set back to "Pausable" so they still freeze.
##
## The effects are "global shader parameters", listed in Project Settings >
## Globals > Shader Globals. A normal shader setting belongs to one material;
## a global one is shared by every shader that declares it, so a single
## RenderingServer call changes every wall, prop and the post-process at once.
## (See the notes at the top of shaders/retro_surface.gdshader.)
##
## Keys: up/down (or W/S) choose a line, left/right (or A/D) turn a setting
## down or up, Enter presses it. With the mouse, point at a line and click.

## The rows of the menu, top to bottom. Must match the order of "rows" below.
enum Row { RESUME, RETRO_EFFECTS, VERTEX_SNAP, LIGHT_BANDS, COLOR_QUANTIZE, QUIT }

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
# doesn't switch the effects back on.
static var retro_effects := true
static var snap_strength := 1.0
static var light_band_strength := 1.0
static var color_quantize := true

## Which row the cursor is on (one of the Row values).
var selected: int = Row.RESUME

@onready var cursor: Control = $Menu/Cursor
@onready var row_list: Control = $Menu/Rows
@onready var rows: Array[Control] = [
	$Menu/Rows/Resume,
	$Menu/Rows/RetroEffects,
	$Menu/Rows/VertexSnap,
	$Menu/Rows/LightBands,
	$Menu/Rows/ColorQuantize,
	$Menu/Rows/Quit,
]
@onready var retro_effects_value: Control = $Menu/Rows/RetroEffects/Value
@onready var snap_value: Control = $Menu/Rows/VertexSnap/Value
@onready var light_bands_value: Control = $Menu/Rows/LightBands/Value
@onready var color_quantize_value: Control = $Menu/Rows/ColorQuantize/Value


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


func _unhandled_input(event: InputEvent) -> void:
	# F1 flips colour quantization at any time, paused or not.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		color_quantize = not color_quantize
		_apply_settings()
		_refresh()
		return

	# Esc (the built-in "ui_cancel" action) opens and closes the menu.
	if event.is_action_pressed("ui_cancel"):
		_set_open(not visible)
		get_viewport().set_input_as_handled()
		return

	# Everything below is only for while the menu is open.
	if not visible:
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


## Shows or hides the menu, freezing or unfreezing the game with it.
func _set_open(open: bool) -> void:
	visible = open
	get_tree().paused = open
	# Free the mouse pointer to use the menu, and capture it again to look
	# around once the game carries on.
	if open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_select(Row.RESUME)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Moves the cursor to a row. posmod wraps around, so going up from the top
## row lands on the bottom one.
func _select(row: int) -> void:
	selected = posmod(row, rows.size())
	_refresh()


## Enter or a click: presses RESUME or QUIT, or steps a setting down one
## notch (and from OFF back round to full strength).
func _activate() -> void:
	match selected:
		Row.RESUME:
			_set_open(false)
		Row.QUIT:
			get_tree().quit()
		_:
			_change(-1, true)


## Turns the selected setting down (direction -1) or up (+1). On/off settings
## simply flip. "wrap" decides whether going past the end comes round to the
## other end or stops there.
func _change(direction: int, wrap: bool) -> void:
	match selected:
		Row.RETRO_EFFECTS:
			retro_effects = not retro_effects
		Row.VERTEX_SNAP:
			snap_strength = _step(snap_strength, direction, wrap)
		Row.LIGHT_BANDS:
			light_band_strength = _step(light_band_strength, direction, wrap)
		Row.COLOR_QUANTIZE:
			color_quantize = not color_quantize
		_:
			return  # RESUME and QUIT have nothing to turn up or down
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


## Updates the words, colours and cursor to match the current settings.
func _refresh() -> void:
	retro_effects_value.text = _on_off_text(retro_effects)
	snap_value.text = _strength_text(snap_strength)
	light_bands_value.text = _strength_text(light_band_strength)
	color_quantize_value.text = _on_off_text(color_quantize)

	for i in rows.size():
		var row_color := normal_color
		if i == selected:
			row_color = selected_color
		elif not retro_effects and i in [Row.VERTEX_SNAP, Row.LIGHT_BANDS, Row.COLOR_QUANTIZE]:
			row_color = inactive_color
		rows[i].color = row_color
		# A row's value (ON, 50% ...) is a child node with its own colour.
		if rows[i].has_node("Value"):
			rows[i].get_node("Value").color = row_color

	# Put the cursor level with the selected row, just to the left of it.
	cursor.position.y = row_list.position.y + rows[selected].position.y


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
