extends Node
## Lets the game be started on a level scene and still get the whole game
## around it. That is how the game starts now: the project's main scene
## (Project Settings > Application > Run > Main Scene) is a level,
## levels/start-level-demo.tscn. It is also what makes F6 in the editor
## ("Run Current Scene") work for any other level.
##
## A level is only the 3D world. The low-res picture, the HUD and the pause
## menu all belong to scenes/main.tscn, which normally loads the level inside
## its small viewport. Run a level directly and none of that exists.
##
## This script is an "autoload" (Project Settings > Globals > Autoload): Godot
## creates one copy of it when the game starts, before any scene, and keeps it
## for the whole run. It looks at which scene was started, and if that is a
## level it switches to main.tscn and tells it to open that level.

const Main := preload("res://scripts/main.gd")

## The scene that owns the viewport, HUD and pause menu.
const MAIN_SCENE := "res://scenes/main.tscn"
## Scenes in this folder are treated as levels.
const LEVELS_FOLDER := "res://levels/"


func _ready() -> void:
	# Autoloads are ready before the first scene has been added to the tree,
	# so current_scene is still empty here. call_deferred runs the check at
	# the end of this frame instead, when the scene is in place.
	_wrap_level.call_deferred()


## If the game was started on a level scene, restarts it inside main.tscn.
func _wrap_level() -> void:
	var scene := get_tree().current_scene
	# scene_file_path is the .tscn file a node was loaded from.
	if scene == null or not scene.scene_file_path.begins_with(LEVELS_FOLDER):
		return

	Main.direct_level_path = scene.scene_file_path
	Main.open_direct_level = true
	# Frees the bare level and loads main.tscn in its place.
	get_tree().change_scene_to_file(MAIN_SCENE)
