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

## The resolution the game is rendered at. THIS IS THE ONE PLACE TO CHANGE IT.
## Try Vector2i(640, 480) for a sharper, late-90s "high-res mode" look.
## (You can also change it in the Inspector by selecting the Main node.)
@export var render_size := Vector2i(320, 240)

## If true, only scale by whole numbers (2x, 3x, 4x...). Every game pixel is
## then exactly the same size on screen, at the cost of thicker black bars.
## If false, the picture fills as much of the window as possible.
@export var integer_scaling := false

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
