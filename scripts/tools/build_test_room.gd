extends SceneTree
## Builds levels/test_room.tscn: a small two-storey building for trying out
## destruction, weapons and enemies.
##
## This is NOT part of the running game. It writes the level out block by
## block, which is quicker and more exact than painting it by hand. Running
## it again overwrites the level, including any changes made in the editor:
##   Godot_v4.7-stable_win64_console.exe --headless --path . --script res://scripts/tools/build_test_room.gd
##
## Every number below counts blocks (half a metre each), not metres. The
## building is 48 x 32 blocks (24 x 16 m):
##   - Shell: the indestructible foundation, outer walls and lid.
##   - Structure: everything else. A wall layer just inside the shell (so
##     blasts make craters in the outer walls), the ground floor, a hall
##     with six pillars holding up the upper floor, stairs behind a lab wall
##     with a doorway, the upper storey with its own pillars and partition,
##     and a roof under the lid.
## Blow up both pillars of the middle pair (there is a pylon by each) and the
## middle of the upper floor comes down.

const OUTPUT := "res://levels/test_room.tscn"

# Block types, by their position in scripts/blocks.gd.
const CONCRETE := 0
const LAB_WALL := 1
const FLOOR := 2
const CEILING := 3

const WIDTH := 48   # x
const DEPTH := 32   # z
const TOP := 18     # the shell lid's height

var level: Node3D
var shell: GridMap
var structure: GridMap


# _initialize runs once the engine is fully set up. (Scenes are loaded with
# load() in here rather than preload(), because some of their scripts use
# the Network autoload, which doesn't exist yet when this script is first
# read.)
func _initialize() -> void:
	level = Node3D.new()
	level.name = "TestRoom"
	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	environment.environment = load("res://assets/retro_environment.tres")
	_add(environment, level)

	shell = _grid("Shell")
	structure = _grid("Structure")
	structure.set_script(load("res://scripts/structure.gd"))
	structure.shell = shell

	_build_shell()
	_build_structure()
	_add_stair_ramp()
	_add_lights()
	_add_things()

	var scene := PackedScene.new()
	scene.pack(level)
	var error := ResourceSaver.save(scene, OUTPUT)
	if error == OK:
		print("Wrote %s: %d shell blocks, %d structure blocks" % [OUTPUT,
				shell.get_used_cells().size(), structure.get_used_cells().size()])
	else:
		push_error("Could not write %s (error %d)" % [OUTPUT, error])
	level.free()  # it was never in the tree, so nothing else frees it
	quit()


## Adds a node to the level. Its "owner" must be the level's root node, or
## it isn't saved with it.
func _add(node: Node, parent: Node) -> Node:
	parent.add_child(node)
	node.owner = level
	return node


func _grid(grid_name: String) -> GridMap:
	var grid := GridMap.new()
	grid.name = grid_name
	grid.mesh_library = load("res://assets/blocks.tres")
	grid.cell_size = Vector3.ONE * 0.5
	_add(grid, level)
	return grid


## Fills a box of cells, corners included, with one block type.
func _fill(grid: GridMap, from: Vector3i, to: Vector3i, block: int) -> void:
	for x in range(from.x, to.x + 1):
		for y in range(from.y, to.y + 1):
			for z in range(from.z, to.z + 1):
				grid.set_cell_item(Vector3i(x, y, z), block)


func _clear(grid: GridMap, from: Vector3i, to: Vector3i) -> void:
	_fill(grid, from, to, GridMap.INVALID_CELL_ITEM)


func _build_shell() -> void:
	# Foundation (the cell below the floor), outer walls and lid.
	_fill(shell, Vector3i(0, -1, 0), Vector3i(WIDTH - 1, -1, DEPTH - 1), CONCRETE)
	for y in range(0, TOP + 1):
		for x in WIDTH:
			shell.set_cell_item(Vector3i(x, y, 0), CONCRETE)
			shell.set_cell_item(Vector3i(x, y, DEPTH - 1), CONCRETE)
		for z in DEPTH:
			shell.set_cell_item(Vector3i(0, y, z), CONCRETE)
			shell.set_cell_item(Vector3i(WIDTH - 1, y, z), CONCRETE)
	_fill(shell, Vector3i(1, TOP, 1), Vector3i(WIDTH - 2, TOP, DEPTH - 2), CONCRETE)


func _build_structure() -> void:
	var inner_min := Vector3i(1, 0, 1)
	var inner_max := Vector3i(WIDTH - 2, 0, DEPTH - 2)

	# Ground floor (its top is 0.5 m above the foundation).
	_fill(structure, inner_min, inner_max, FLOOR)
	# The wall layer inside the shell, all the way up.
	for y in range(1, TOP):
		for x in range(1, WIDTH - 1):
			structure.set_cell_item(Vector3i(x, y, 1), CONCRETE)
			structure.set_cell_item(Vector3i(x, y, DEPTH - 2), CONCRETE)
		for z in range(1, DEPTH - 1):
			structure.set_cell_item(Vector3i(1, y, z), CONCRETE)
			structure.set_cell_item(Vector3i(WIDTH - 2, y, z), CONCRETE)

	# Upper floor: a ceiling layer (y 8) under a floor layer (y 9), and the
	# roof (y 17) under the shell lid.
	_fill(structure, Vector3i(2, 8, 2), Vector3i(WIDTH - 3, 8, DEPTH - 3), CEILING)
	_fill(structure, Vector3i(2, 9, 2), Vector3i(WIDTH - 3, 9, DEPTH - 3), FLOOR)
	_fill(structure, Vector3i(2, 17, 2), Vector3i(WIDTH - 3, 17, DEPTH - 3), CEILING)

	# Pillars, 1 m square, in two rows of three on both storeys.
	for x: int in [11, 23, 35]:
		for z: int in [10, 20]:
			_fill(structure, Vector3i(x, 1, z), Vector3i(x + 1, 7, z + 1), CONCRETE)
			_fill(structure, Vector3i(x, 10, z), Vector3i(x + 1, 16, z + 1), CONCRETE)

	# A lab wall closing off the stairwell on the ground floor, with a
	# doorway 2 m wide and tall. (It is kept clear of the middle pillars:
	# a wall holds up the floor above it too, and the point of the middle
	# pillars is that nothing else does.)
	_fill(structure, Vector3i(40, 1, 2), Vector3i(40, 7, DEPTH - 3), LAB_WALL)
	_clear(structure, Vector3i(40, 1, 14), Vector3i(40, 4, 17))
	# A partition upstairs, with its own doorway.
	_fill(structure, Vector3i(2, 10, 16), Vector3i(24, 16, 16), LAB_WALL)
	_clear(structure, Vector3i(12, 10, 16), Vector3i(15, 13, 16))

	# Stairs against the east wall, rising towards +z: eight steps, each
	# 2 blocks deep and 1 block higher than the last, up to the upper floor.
	_clear(structure, Vector3i(42, 8, 2), Vector3i(45, 9, 19))
	for step in 8:
		var front := 4 + step * 2
		_fill(structure, Vector3i(42, 1, front), Vector3i(45, 1 + step, front + 1), CONCRETE)


## The player can't step up a block yet, so an invisible slope lies over the
## stairs (like the StairRamp in the old levels). It runs from the floor
## (0.5 m up, 1 m in) to the upper floor (5 m up, 10 m in), touching the
## front edge of every step.
func _add_stair_ramp() -> void:
	var start := Vector3(0.0, 0.5, 1.0)
	var end := Vector3(0.0, 5.0, 10.0)
	var slope := end - start
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 0.2, slope.length())
	var ramp := StaticBody3D.new()
	ramp.name = "StairRamp"
	_add(ramp, level)
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	shape.shape = box
	_add(shape, ramp)
	# Tip the box's length along the slope (turning about X by minus the
	# slope's angle), and lower it by half its thickness so its top is the
	# slope.
	var angle := atan2(slope.y, slope.z)
	var up := Vector3(0.0, cos(angle), -sin(angle))
	ramp.rotation.x = -angle
	ramp.position = (start + end) / 2.0 - up * 0.1 + Vector3(22.0, 0.0, 0.0)


func _add_lights() -> void:
	var lights := Node3D.new()
	lights.name = "Lights"
	_add(lights, level)
	for spot: Vector3 in [Vector3(4.5, 3.5, 4.5), Vector3(11.0, 3.5, 12.0), Vector3(19.0, 3.5, 4.5),
			Vector3(19.0, 8.0, 4.5), Vector3(8.0, 8.0, 12.0)]:
		var light := OmniLight3D.new()
		light.name = "Light%d" % (lights.get_child_count() + 1)
		light.light_color = Color(1.0, 0.92, 0.8)
		light.light_energy = 1.4
		light.omni_range = 9.0
		_add(light, lights)
		light.position = spot


## Scenes are instanced with GEN_EDIT_STATE_INSTANCE, as the editor does, so
## the level stores only what differs from each scene (its position), not a
## copy of all its settings.
func _add_things() -> void:
	# The player starts in the south-west corner, facing east (+x).
	var player: Node3D = load("res://scenes/player.tscn").instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	player.name = "Player"
	_add(player, level)
	player.position = Vector3(3.5, 0.6, 7.0)
	player.rotation.y = -PI / 2.0

	var crate_scene: PackedScene = load("res://scenes/crate.tscn")
	var pylon_scene: PackedScene = load("res://scenes/explosive_pylon.tscn")
	var zombie_scene: PackedScene = load("res://scenes/zombie.tscn")
	var props := Node3D.new()
	props.name = "Props"
	_add(props, level)
	for spot: Vector3 in [Vector3(3.0, 0.5, 11.5), Vector3(4.2, 0.5, 11.5), Vector3(3.0, 1.5, 11.5)]:
		var crate: Node3D = crate_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		crate.name = "Crate%d" % (props.get_child_count() + 1)
		_add(crate, props)
		crate.position = spot
	# A pylon beside each of the middle pillars (blocks 23-24).
	for spot: Vector3 in [Vector3(12.0, 0.5, 4.4), Vector3(12.0, 0.5, 11.6)]:
		var pylon: Node3D = pylon_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		pylon.name = "Pylon%d" % (props.get_child_count() + 1)
		_add(pylon, props)
		pylon.position = spot

	var enemies := Node3D.new()
	enemies.name = "Enemies"
	_add(enemies, level)
	for spot: Vector3 in [Vector3(9.0, 5.0, 4.0), Vector3(17.0, 5.0, 12.0), Vector3(19.0, 5.0, 4.0),
			Vector3(19.0, 0.5, 4.0), Vector3(20.0, 0.5, 12.0)]:
		var zombie: Node3D = zombie_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		zombie.name = "Zombie%d" % (enemies.get_child_count() + 1)
		_add(zombie, enemies)
		zombie.position = spot
