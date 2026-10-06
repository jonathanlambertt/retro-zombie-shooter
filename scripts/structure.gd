extends GridMap
## A destructible building: walls, floors, ceilings, pillars and stairs made
## of half-metre blocks, painted in the editor with Godot's GridMap tool
## (select the Structure node, then pick a block from the palette).
##
## Explosions knock blocks out (blast(), called by scripts/explosion.gd).
## After every change, what is left is checked for support:
##   - a block resting on another block is held up by it,
##   - a block can also hold up its neighbours sideways (or hang one below
##     it), but each sideways step weakens the hold, and a block type's
##     "span" is how many steps it can bridge (6 m for concrete),
##   - the level's Shell holds up anything touching it.
## Whatever is no longer held up falls as one piece, smashes, and leaves a
## heap of rubble, which is made of blocks too and can be blasted again. Blow
## up the pillars under a big floor and the middle of it comes down.
##
## The indestructible outer walls and foundations are a second GridMap,
## "Shell", painted with the same blocks. Nothing damages it, so nobody can
## blast their way out of the level. Make outer walls two blocks thick, shell
## outside and Structure inside, and explosions leave craters in them.
##
## Multiplayer (see scripts/network.gd): the host decides what breaks and
## what falls (blast() passes itself on to the host), then sends the result
## to everyone (_apply), so every game ends up with exactly the same
## building. A player who joins later asks for everything changed so far.
##
## The block types (and how tough each is) are listed in scripts/blocks.gd.

const Blocks := preload("res://scripts/blocks.gd")
const SurfaceMark := preload("res://scripts/surface_mark.gd")
const DEBRIS_SCENE := preload("res://scenes/debris.tscn")

## How firmly a block resting on the Shell (or on a column of blocks going
## down to it) is held. Each sideways step costs STABILITY / span, so after
## "span" steps nothing is left.
const STABILITY := 240
## The six directions to a block's neighbours, and the four sideways ones.
const NEIGHBOURS: Array[Vector3i] = [
	Vector3i.UP, Vector3i.DOWN, Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK,
]
const SIDES: Array[Vector3i] = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.FORWARD, Vector3i.BACK]
## The columns a rubble block can tumble into: its own and the four around it.
const SPILL: Array[Vector2i] = [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## "No room for rubble here" (see _rubble_spot).
const NO_SPOT := Vector3i(0, -1000000, 0)
## How much of an explosion gets through each block in its way: a blast on
## one side of a wall barely touches what is on the other side.
const SHIELDING := 0.35

## The indestructible part of the level (see the top of this script).
@export var shell: GridMap
## How much of a fallen piece is left as rubble. The rest smashes to dust.
@export_range(0.0, 1.0) var rubble_left := 0.5
## Damage dealt to anything that a falling piece lands on.
@export var crush_damage := 60
## How fast falling pieces speed up, in metres per second squared (the same
## as the player's gravity).
@export var gravity := 20.0

## Every block in the structure: cell (a Vector3i) -> block type. A copy of
## the GridMap's own cells that is quicker to look things up in.
var blocks := {}
## Every cell of the shell (cell -> true).
var shell_blocks := {}
## The host only: how much damage each damaged block has taken so far.
var damage_taken := {}
## The host only: how firmly each block is held up (cell -> strength, see
## "Holding up" below). Blocks that nothing holds up aren't listed.
var held := {}
## The host only: every cell that has changed since the level started
## (cell -> block type, or -1 if it is now empty), for players who join late.
var changes := {}
## The lowest cell in use. A piece that falls below it has fallen out of the
## world and is simply removed.
var lowest_y := 0
## The cost of one sideways step for each block type (see STABILITY).
var step_costs: Array[int] = []
## A small cube for each block type, for the chunks that fly when it breaks.
var chunk_meshes := {}


func _ready() -> void:
	# Explosions find every structure in the level through this group.
	add_to_group("structure")
	for block: Dictionary in Blocks.TYPES:
		step_costs.append(roundi(float(STABILITY) / block.span))
	for cell in get_used_cells():
		blocks[cell] = get_cell_item(cell)
		lowest_y = mini(lowest_y, cell.y)
	if shell:
		for cell in shell.get_used_cells():
			shell_blocks[cell] = true
			lowest_y = mini(lowest_y, cell.y)

	if is_multiplayer_authority():
		var loose := _hold_all()
		if not loose.is_empty():
			push_warning("%s: %d blocks have nothing holding them up (one is at %s). They stay put, but won't hold anything else up. Add a pillar or a wall under them."
					% [get_path(), loose.size(), loose.keys()[0]])
	elif Network.is_online():
		# Someone else is the host: ask what has been destroyed already.
		_send_changes.rpc_id(get_multiplayer_authority())


## Damages the blocks around "centre" (a position in the level): "damage" at
## the centre, fading to nothing at "radius" metres. Blocks with other blocks
## between them and the centre are partly shielded.
##
## Called by explosions on whichever computer set them off. Like
## take_damage() on enemies, a call anywhere but the host is passed on.
@rpc("any_peer", "call_remote", "reliable")
func blast(centre: Vector3, radius: float, damage: float) -> void:
	if not is_multiplayer_authority():
		blast.rpc_id(get_multiplayer_authority(), centre, radius, damage)
		return

	# Every block within reach, with the point of it nearest the blast.
	var middle := local_to_map(to_local(centre))
	var reach := ceili(radius / cell_size.x)
	var in_range: Array[Dictionary] = []
	for x in range(-reach, reach + 1):
		for y in range(-reach, reach + 1):
			for z in range(-reach, reach + 1):
				var cell := middle + Vector3i(x, y, z)
				if not blocks.has(cell):
					continue
				var nearest := _nearest_point(cell, centre)
				var distance := centre.distance_to(nearest)
				if distance < radius:
					in_range.append({cell = cell, nearest = nearest, distance = distance})
	# Nearest first, so a block this blast destroys no longer shields the
	# ones behind it: the blast punches through what it breaks.
	in_range.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.distance < b.distance)

	var destroyed := {}
	for target: Dictionary in in_range:
		var cell: Vector3i = target.cell
		var distance: float = target.distance
		# Full damage at the centre, none at the edge, a little randomness so
		# holes come out ragged, and less for every block still in the way.
		var hit := damage * (1.0 - distance / radius) * randf_range(0.8, 1.2)
		hit *= pow(SHIELDING, _blocks_between(centre, target.nearest, cell, destroyed))
		damage_taken[cell] = damage_taken.get(cell, 0.0) + hit
		if damage_taken[cell] >= Blocks.TYPES[blocks[cell]].health:
			destroyed[cell] = true
	if destroyed.is_empty():
		return

	var removed := PackedInt32Array()
	for cell: Vector3i in destroyed:
		blocks.erase(cell)
		damage_taken.erase(cell)
		removed.append_array([cell.x, cell.y, cell.z])
	var falls := _collapse(destroyed.keys())
	# Everyone (this computer included, "call_local") makes the changes.
	_apply.rpc(removed, falls)


## The point of block "cell" nearest to "point" (both in the level).
func _nearest_point(cell: Vector3i, point: Vector3) -> Vector3:
	var half := cell_size / 2.0
	var middle := map_to_local(cell)
	# clamp() keeps each coordinate inside the block's box.
	return to_global(to_local(point).clamp(middle - half, middle + half))


## How many other blocks (structure or shell) a straight line from "centre"
## to "point", a point on the surface of "cell", passes through on the way,
## leaving out the ones in "ignored". (Aiming at the surface rather than the
## middle matters for a block in the side of a wall: a line to its middle
## would cut through its neighbours.)
func _blocks_between(centre: Vector3, point: Vector3, cell: Vector3i, ignored: Dictionary) -> int:
	var start := to_local(centre)
	var end := to_local(point)
	# Look every quarter of a block along the line.
	var steps := int(start.distance_to(end) / (cell_size.x * 0.25))
	var counted := {}
	for i in range(1, steps):
		var on_the_way := local_to_map(start.lerp(end, float(i) / steps))
		if on_the_way != cell and not counted.has(on_the_way) and not ignored.has(on_the_way) \
				and (blocks.has(on_the_way) or shell_blocks.has(on_the_way)):
			counted[on_the_way] = true
	return counted.size()


# --- Holding up ----------------------------------------------------------------
#
# How firmly each block is held up works like water flowing out from the
# supports: a block touching the Shell starts full (STABILITY), a block
# resting on top of one passes on its whole hold, a block hanging underneath
# one gets two steps less, and every sideways step loses one step
# (STABILITY / span). A block none of it reaches isn't held up at all.
#
# The host keeps the result in "held". After a blast it only works out again
# the blocks that got their hold through something destroyed, which is much
# quicker than redoing the whole building.

## The hold a block gets from the Shell itself, if it touches it.
func _shell_hold(cell: Vector3i) -> int:
	if shell_blocks.has(cell + Vector3i.DOWN):
		return STABILITY
	var step: int = step_costs[blocks[cell]]
	for side in SIDES:
		if shell_blocks.has(cell + side):
			return STABILITY - step
	if shell_blocks.has(cell + Vector3i.UP):
		return STABILITY - step * 2
	return 0


## The hold a block with hold "strength" passes on to "neighbour", the block
## next to it in "direction".
func _passed_on(strength: int, direction: Vector3i, neighbour: Vector3i) -> int:
	var step: int = step_costs[blocks[neighbour]]
	if direction == Vector3i.UP:
		return strength  # resting on top
	if direction == Vector3i.DOWN:
		return strength - step * 2  # hanging underneath
	return strength - step  # sideways


## Raises the holds in "held" to the starting holds in "seeds" (cell ->
## strength), and passes them on to the neighbours, and theirs... If "only"
## (cell -> true) isn't empty, only those blocks are changed.
##
## A "bucket queue" deals with the strongest holds first, so each block is
## settled once: buckets[s] lists the blocks found to have hold s.
func _spread(seeds: Dictionary, only: Dictionary = {}) -> void:
	var buckets: Array[Array] = []
	for i in STABILITY + 1:
		buckets.append([])
	for cell: Vector3i in seeds:
		var strength: int = seeds[cell]
		if strength > held.get(cell, 0):
			held[cell] = strength
			buckets[strength].append(cell)

	for strength in range(STABILITY, 0, -1):
		var bucket := buckets[strength]
		# (Not "for cell in bucket": resting blocks add to this same bucket.)
		var i := 0
		while i < bucket.size():
			var cell: Vector3i = bucket[i]
			i += 1
			if held[cell] != strength:
				continue  # it was listed again later with a better hold
			for direction in NEIGHBOURS:
				var neighbour := cell + direction
				if not blocks.has(neighbour) or (not only.is_empty() and not only.has(neighbour)):
					continue
				var passed := _passed_on(strength, direction, neighbour)
				if passed > held.get(neighbour, 0):
					held[neighbour] = passed
					buckets[passed].append(neighbour)


## Works out every block's hold from scratch, when the level starts. Returns
## the blocks nothing holds up (cell -> true).
func _hold_all() -> Dictionary:
	held = {}
	var seeds := {}
	for cell: Vector3i in blocks:
		var strength := _shell_hold(cell)
		if strength > 0:
			seeds[cell] = strength
	_spread(seeds)
	var loose := {}
	for cell: Vector3i in blocks:
		if not held.has(cell):
			loose[cell] = true
	return loose


## Called once the "removed" blocks are out of "blocks". Finds every block
## that got its hold through one of them (directly, or through other blocks
## that did), works out their holds again, and returns the ones nothing holds
## up any more (cell -> true).
func _rehold(removed: Array) -> Dictionary:
	# 1. Follow the hold outwards from each removed block.
	# (All the removed blocks are taken out of "held" before following any,
	# so none of them is mistaken for a block still standing.)
	var lost := {}
	var to_check: Array[Vector3i] = []
	var removed_holds := {}
	for cell: Vector3i in removed:
		if held.has(cell):
			removed_holds[cell] = held[cell]
			held.erase(cell)
	for cell: Vector3i in removed_holds:
		_find_dependents(cell, removed_holds[cell], lost, to_check)
	while not to_check.is_empty():
		var cell: Vector3i = to_check.pop_back()
		_find_dependents(cell, held[cell], lost, to_check)

	# 2. Forget their holds, and work them out again from the shell and the
	# blocks around them that kept theirs.
	for cell: Vector3i in lost:
		held.erase(cell)
	var seeds := {}
	for cell: Vector3i in lost:
		var best := _shell_hold(cell)
		for direction in NEIGHBOURS:
			var from := cell - direction
			if held.has(from):
				best = maxi(best, _passed_on(held[from], direction, cell))
		if best > 0:
			seeds[cell] = best
	_spread(seeds, lost)

	var loose := {}
	for cell: Vector3i in lost:
		if not held.has(cell):
			loose[cell] = true
	return loose


## Adds the neighbours of "cell" whose hold came through it (their hold is
## exactly what it passes on) to "lost" and to "to_check".
func _find_dependents(cell: Vector3i, strength: int, lost: Dictionary, to_check: Array[Vector3i]) -> void:
	for direction in NEIGHBOURS:
		var neighbour := cell + direction
		if lost.has(neighbour) or not held.has(neighbour):
			continue
		if held[neighbour] == _passed_on(strength, direction, neighbour):
			lost[neighbour] = true
			to_check.append(neighbour)


## Works out the holds of new blocks (rubble that has landed), and what they
## pass on to their neighbours.
func _hold_new(cells: Array[Vector3i]) -> void:
	var seeds := {}
	for cell in cells:
		var best := _shell_hold(cell)
		for direction in NEIGHBOURS:
			var from := cell - direction
			if held.has(from):
				best = maxi(best, _passed_on(held[from], direction, cell))
		if best > 0:
			seeds[cell] = best
	_spread(seeds)


## Called after the "removed" blocks are taken out. Finds every block that
## is no longer held up, groups them into pieces (blocks touching each other
## fall together), and works out where each piece lands and the rubble it
## leaves. Takes them out of "blocks" straight away; the rubble is added when
## the piece lands (see _land).
##
## Returns a list of falls, each a Dictionary: "cells" (the falling blocks),
## "drop" (how many cells down it falls, or -1 for out of the world) and
## "rubble" (what is left where it lands). Cell lists are PackedInt32Arrays
## of x, y, z, block type, ready to send over the network.
func _collapse(removed: Array) -> Array:
	var loose := _rehold(removed)
	var pieces: Array[Array] = []
	while not loose.is_empty():
		# Gather everything touching this loose block, then everything
		# touching those, and so on (a "flood fill").
		var first: Vector3i = loose.keys()[0]
		loose.erase(first)
		var piece: Array[Vector3i] = [first]
		var i := 0
		while i < piece.size():
			for direction in NEIGHBOURS:
				var neighbour := piece[i] + direction
				if loose.has(neighbour):
					loose.erase(neighbour)
					piece.append(neighbour)
			i += 1
		pieces.append(piece)
	# The lowest pieces land first, so higher ones can land on their rubble.
	pieces.sort_custom(func(a: Array, b: Array) -> bool: return _bottom(a) < _bottom(b))

	var falls := []
	var landed := {}  # rubble from pieces already worked out in this collapse
	for piece in pieces:
		for cell: Vector3i in piece:
			blocks.erase(cell)
			damage_taken.erase(cell)
		falls.append(_fall(piece, landed))
	return falls


func _bottom(piece: Array) -> int:
	var lowest: int = piece[0].y
	for cell: Vector3i in piece:
		lowest = mini(lowest, cell.y)
	return lowest


## Works out how far one loose piece drops and the rubble it leaves.
func _fall(piece: Array, landed: Dictionary) -> Dictionary:
	var cells := PackedInt32Array()
	# The lowest block of the piece in each column (x, z).
	var column_bottoms := {}
	for cell: Vector3i in piece:
		cells.append_array([cell.x, cell.y, cell.z, get_cell_item(cell)])
		var column := Vector2i(cell.x, cell.z)
		column_bottoms[column] = mini(column_bottoms.get(column, cell.y), cell.y)

	# It falls as one, until its first column hits something.
	var drop := -1
	for column: Vector2i in column_bottoms:
		var gap := _gap_below(Vector3i(column.x, column_bottoms[column], column.y), landed)
		if gap >= 0 and (drop == -1 or gap < drop):
			drop = gap
	if drop == -1:
		return {cells = cells, drop = -1, rubble = PackedInt32Array()}

	# It smashes on landing: only some blocks are left, and each of those
	# tumbles into the lowest spot among its own column and the four around
	# it, so the rubble spreads into a heap instead of standing in a stack.
	var rubble := PackedInt32Array()
	var tops := {}  # column -> the next free cell on top of its rubble
	for cell: Vector3i in piece:
		if randf() >= rubble_left:
			continue
		var column := Vector2i(cell.x, cell.z)
		var start: int = column_bottoms[column] - drop
		var best := NO_SPOT
		for offset in SPILL:
			var spot := _rubble_spot(column + offset, start, landed, tops)
			if spot != NO_SPOT and (best == NO_SPOT or spot.y < best.y):
				best = spot
		if best == NO_SPOT:
			continue
		landed[best] = true
		tops[Vector2i(best.x, best.z)] = best + Vector3i.UP
		rubble.append_array([best.x, best.y, best.z, Blocks.RUBBLE])
	return {cells = cells, drop = drop, rubble = rubble}


## Where a rubble block tumbling into "column" from height "start" would come
## to rest, or NO_SPOT if it can't go there (a wall is in the way, or there
## is nothing underneath at all).
func _rubble_spot(column: Vector2i, start: int, landed: Dictionary, tops: Dictionary) -> Vector3i:
	if tops.has(column):
		return tops[column]
	var cell := Vector3i(column.x, start, column.y)
	if blocks.has(cell) or shell_blocks.has(cell) or landed.has(cell):
		return NO_SPOT
	var gap := _gap_below(cell, landed)
	if gap < 0:
		return NO_SPOT
	var spot := cell + Vector3i.DOWN * gap
	tops[column] = spot
	return spot


## How many empty cells there are straight below "cell" before something
## solid. -1 if there is nothing below at all.
func _gap_below(cell: Vector3i, landed: Dictionary) -> int:
	var below := cell + Vector3i.DOWN
	var gap := 0
	while below.y >= lowest_y - 1:
		if blocks.has(below) or shell_blocks.has(below) or landed.has(below):
			return gap
		gap += 1
		below += Vector3i.DOWN
	return -1


# --- Making the changes (on every computer) ---------------------------------

## Removes the destroyed blocks and starts the falls. Sent by the host to
## everyone, so every game changes the same way.
@rpc("authority", "call_local", "reliable")
func _apply(removed: PackedInt32Array, falls: Array) -> void:
	var gone := {}
	var by_type := {}  # block type -> positions, for the flying chunks
	for i in range(0, removed.size(), 3):
		var cell := Vector3i(removed[i], removed[i + 1], removed[i + 2])
		var block := get_cell_item(cell)
		if block == INVALID_CELL_ITEM:
			continue
		if not by_type.has(block):
			by_type[block] = PackedVector3Array()
		by_type[block].append(to_global(map_to_local(cell)))
		_set_block(cell, INVALID_CELL_ITEM)
		gone[cell] = true
	for block: int in by_type:
		_burst(by_type[block], block, false)

	for fall: Dictionary in falls:
		_start_fall(fall, gone)
	_remove_marks(gone)


## Changes one cell everywhere it is kept track of.
func _set_block(cell: Vector3i, block: int) -> void:
	set_cell_item(cell, block)
	if block == INVALID_CELL_ITEM:
		blocks.erase(cell)
	else:
		blocks[cell] = block
	changes[cell] = block


## Takes a loose piece out of the grid and drops a copy of it instead, which
## turns into rubble when it lands.
func _start_fall(fall: Dictionary, gone: Dictionary) -> void:
	var cells: PackedInt32Array = fall.cells
	# One MultiMeshInstance3D per block type draws all the falling blocks of
	# that type in one go.
	var piece := Node3D.new()
	add_child(piece)
	var transforms_by_type := {}
	for i in range(0, cells.size(), 4):
		var cell := Vector3i(cells[i], cells[i + 1], cells[i + 2])
		var block := cells[i + 3]
		if not transforms_by_type.has(block):
			transforms_by_type[block] = []
		transforms_by_type[block].append(Transform3D(Basis(), map_to_local(cell)))
		_set_block(cell, INVALID_CELL_ITEM)
		gone[cell] = true
	for block: int in transforms_by_type:
		var transforms: Array = transforms_by_type[block]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh_library.get_item_mesh(block)
		multimesh.instance_count = transforms.size()
		for i in transforms.size():
			multimesh.set_instance_transform(i, transforms[i])
		var drawer := MultiMeshInstance3D.new()
		drawer.multimesh = multimesh
		piece.add_child(drawer)

	# Out of the world: fall a long way and vanish.
	var drop: int = fall.drop
	var height := (drop if drop >= 0 else 40) * cell_size.y
	# How long falling that far takes: height = gravity * time^2 / 2.
	var time := sqrt(2.0 * height / gravity)
	var tween := create_tween()
	# EASE_IN with TRANS_QUAD starts slowly and speeds up, like falling.
	tween.tween_property(piece, "position:y", -height, time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_land.bind(fall, piece))


## A falling piece hits the ground: it vanishes in a cloud of chunks and
## dust, leaves its rubble, and hurts whatever it landed on.
func _land(fall: Dictionary, piece: Node3D) -> void:
	piece.queue_free()
	var drop: int = fall.drop
	if drop < 0:
		return
	var cells: PackedInt32Array = fall.cells
	var landing_points := PackedVector3Array()
	var footprint := {}
	var top := cells[1]
	var bottom := cells[1] - drop
	for i in range(0, cells.size(), 4):
		var cell := Vector3i(cells[i], cells[i + 1] - drop, cells[i + 2])
		landing_points.append(to_global(map_to_local(cell)))
		footprint[Vector2i(cell.x, cell.z)] = true
		top = maxi(top, cells[i + 1])
		bottom = mini(bottom, cell.y)
	_burst(landing_points, cells[3], true)

	var rubble: PackedInt32Array = fall.rubble
	var new_blocks: Array[Vector3i] = []
	for i in range(0, rubble.size(), 4):
		var cell := Vector3i(rubble[i], rubble[i + 1], rubble[i + 2])
		_set_block(cell, rubble[i + 3])
		new_blocks.append(cell)

	if is_multiplayer_authority():
		_hold_new(new_blocks)
		_crush(footprint, bottom, top)


## Hurts every player, enemy, crate and pylon in the space a piece fell
## through: in one of its columns, between where it started and where it
## landed (cell heights "bottom" to "top").
func _crush(footprint: Dictionary, bottom: int, top: int) -> void:
	var victims := get_tree().get_nodes_in_group("player")
	victims.append_array(get_tree().get_nodes_in_group("enemy"))
	victims.append_array(get_tree().get_nodes_in_group("breakable"))
	for victim: Node3D in victims:
		# A point a little above their feet, as a cell of this grid.
		var cell := local_to_map(to_local(victim.global_position + Vector3.UP * 0.3))
		if footprint.has(Vector2i(cell.x, cell.z)) and cell.y >= bottom - 1 and cell.y <= top:
			victim.take_damage(crush_damage)


## Throws chunks of block type "block" (and dust) from every point listed.
func _burst(points: PackedVector3Array, block: int, dusty: bool) -> void:
	if not chunk_meshes.has(block):
		var chunk := BoxMesh.new()
		chunk.size = Vector3.ONE * 0.14
		chunk.material = mesh_library.get_item_mesh(block).surface_get_material(0)
		chunk_meshes[block] = chunk
	var debris := DEBRIS_SCENE.instantiate()
	# Add it to the level, not to this GridMap, so it isn't hidden or moved
	# with it.
	get_parent().add_child(debris)
	debris.burst(points, chunk_meshes[block], dusty)


## Bullet holes, scorch marks and blood stains are flat squares stuck to the
## blocks (scripts/surface_mark.gd). Removes the ones whose block has gone.
func _remove_marks(gone: Dictionary) -> void:
	for kind: String in SurfaceMark.marks:
		for mark: Node3D in SurfaceMark.marks[kind].duplicate():
			# The square faces out of its surface along its Z axis, so the
			# block it sits on is just behind it.
			var behind := mark.global_position - mark.global_basis.z.normalized() * 0.05
			if gone.has(local_to_map(to_local(behind))):
				mark.queue_free()


# --- Players who join later -----------------------------------------------------

## Runs on the host, asked by a player who has just joined.
@rpc("any_peer", "call_remote", "reliable")
func _send_changes() -> void:
	var cells := PackedInt32Array()
	for cell: Vector3i in changes:
		cells.append_array([cell.x, cell.y, cell.z, changes[cell]])
	# get_remote_sender_id() is the peer that called this RPC.
	_load_changes.rpc_id(multiplayer.get_remote_sender_id(), cells)


## Runs on the player who joined: makes the same changes, without effects.
@rpc("authority", "call_remote", "reliable")
func _load_changes(cells: PackedInt32Array) -> void:
	for i in range(0, cells.size(), 4):
		_set_block(Vector3i(cells[i], cells[i + 1], cells[i + 2]), cells[i + 3])
