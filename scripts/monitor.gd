@tool
extends StaticBody3D
## A computer monitor of the 1990s: a deep beige box with a glass tube in its
## front, standing on a small foot. Its origin is at its base and the screen
## faces +Z, like the other lab props.
##
## The case and the foot are ordinary lit boxes, painted the same way as the
## furniture (see scripts/tools/generate_textures.gd). The picture on the
## glass is a separate flat square, a hair in front of the case, whose
## material ignores the room's lights ("unshaded"). That is what makes the
## screen glow in a dark room the way a real one does.
##
## "@tool" makes this script run inside the editor as well as in the game,
## so choosing a Screen in the Inspector shows it straight away instead of
## only when you press Play.

## What the screen shows: one of the monitor_screen_ pictures in
## assets/textures/, or any picture of your own (they are 26 x 22 pixels).
@export var screen: Texture2D = preload("res://assets/textures/monitor_screen_cells.png"):
	set(value):
		screen = value
		_update()

@onready var screen_mesh: MeshInstance3D = $Screen


func _ready() -> void:
	_update()


## Puts the chosen picture on the glass.
func _update() -> void:
	# The setter above also runs while the scene is still being loaded,
	# before the child nodes exist. _ready() calls this again once they do.
	if not is_node_ready():
		return
	# The screen's material is part of the scene, so every monitor in the
	# level shares the same one, and changing its picture would change them
	# all. Give this monitor a copy of its own to change instead.
	var material: StandardMaterial3D = screen_mesh.mesh.surface_get_material(0).duplicate()
	material.albedo_texture = screen
	screen_mesh.material_override = material
