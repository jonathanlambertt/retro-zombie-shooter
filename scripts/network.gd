extends Node
## Multiplayer: hosting a game, joining one, and keeping everyone's copy of
## it in step.
##
## This script is an autoload (Project Settings > Globals > Autoload), so any
## script can reach it by the name "Network", and it lives for the whole run,
## even while main.tscn reloads.
##
## How a game is shared, using Godot's "high-level multiplayer":
##   - One player HOSTS. Their game is the "server" and has peer ID 1. The
##     others JOIN it by its address and are given IDs of their own. The
##     connection is ENet (UDP) on port 7777: on a home network that just
##     works; over the internet the host has to forward that port.
##   - The host runs the world. Only the host's enemies think, chase and
##     bite; everyone else is sent where they are and what they are doing.
##     Crates break and pylons explode on the host, which tells the others.
##   - Each player runs their own body. Your game moves your player and sends
##     its position, aim, crouch and weapon to everyone (the
##     MultiplayerSynchronizer called Sync in scenes/player.tscn).
##   - Whoever fires works out what the shot hit, just as in single player.
##     The thing that was hit then passes the damage on to whoever is in
##     charge of it, its "multiplayer authority" (see take_damage() in
##     scripts/enemy.gd).
##   - The level and the players are created on every computer by the two
##     MultiplayerSpawners made in _ready(). When the host adds a level or a
##     player through one, everyone else gets it too, including players who
##     join later.
##
## Single player is the same game without a connection: Godot then counts
## you as the host of a game that nobody else is in, so every "is this mine
## to do?" check simply says yes.
##
## To try it on one computer, start the game twice from a terminal:
##   Godot_v4.7-stable_win64_console.exe --path . -- --host
##   Godot_v4.7-stable_win64_console.exe --path . -- --join=127.0.0.1

const DEFAULT_PORT := 7777
## Most players in one game, the host included.
const MAX_PLAYERS := 8
const PLAYER_SCENE := preload("res://scenes/player.tscn")
## Armour colours, handed out in the order players join (the host is first).
const PLAYER_COLORS: Array[Color] = [
	Color(0.85, 0.5, 0.22),   # orange
	Color(0.3, 0.55, 0.9),    # blue
	Color(0.4, 0.75, 0.3),    # green
	Color(0.85, 0.25, 0.25),  # red
	Color(0.9, 0.8, 0.25),    # yellow
	Color(0.65, 0.4, 0.85),   # purple
	Color(0.85, 0.85, 0.85),  # white
	Color(0.3, 0.3, 0.33),    # black
]

## What is going on, in words the pixel font can show (the pause menu shows
## it): "HOSTING ON PORT 7777", "THE HOST LEFT"...
var status := "":
	set(value):
		status = value
		status_time = Time.get_ticks_msec()
## When the status last changed, in milliseconds since the game started.
var status_time := 0
## The Main node of scenes/main.tscn. It tells us about itself when it starts.
var main: Node
var level_spawner: MultiplayerSpawner
var player_spawner: MultiplayerSpawner
## Where players start in the current level: the spot where the level's own
## Player node stood (see _make_level).
var spawn_point := Transform3D()
## Peer IDs in the order the players joined, host first. Only the host keeps
## this; it decides the armour colours.
var join_order: Array[int] = []
## The crates and pylons that have been destroyed in this level (their paths
## inside the level), so that players who join later can remove them too.
## Only the host keeps this.
var destroyed := PackedStringArray()
## A list like that, received from the host before our copy of the level
## has arrived. It is applied as soon as the level is in place.
var pending_destroyed := PackedStringArray()


func _ready() -> void:
	# Keep working while single player is paused. (Online, nobody pauses.)
	process_mode = Node.PROCESS_MODE_ALWAYS

	# A MultiplayerSpawner with a "spawn function" calls that function on
	# every computer to make the node, from a little data the host sends.
	level_spawner = _add_spawner("LevelSpawner", _make_level)
	level_spawner.spawned.connect(_use_level)
	player_spawner = _add_spawner("PlayerSpawner", _make_player)

	# "multiplayer" is the SceneTree's MultiplayerAPI, which sends the
	# messages and tells us when players come and go.
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_go_offline.bind("COULD NOT CONNECT"))
	multiplayer.server_disconnected.connect(_go_offline.bind("THE HOST LEFT"))

	# Wait for main.tscn to start before acting on --host or --join.
	_read_command_line.call_deferred()


func _add_spawner(spawner_name: String, spawn_function: Callable) -> MultiplayerSpawner:
	var spawner := MultiplayerSpawner.new()
	spawner.name = spawner_name
	spawner.spawn_function = spawn_function
	add_child(spawner)
	return spawner


## Handles "-- --host" and "-- --join=ADDRESS" on the command line. (Godot
## keeps everything after a lone "--" for the game itself.)
func _read_command_line() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--host":
			host()
		elif argument.begins_with("--join="):
			join(argument.trim_prefix("--join="))


## Called by scripts/main.gd when it starts (again).
func register_main(new_main: Node) -> void:
	main = new_main
	# New levels go into the low-res viewport, like the ones main.gd loads.
	level_spawner.spawn_path = level_spawner.get_path_to(main.game_viewport)


## True while connected to (or hosting) a game with other players.
func is_online() -> bool:
	return not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer)


## True when online and someone else is the host.
func is_client() -> bool:
	return is_online() and not multiplayer.is_server()


## The line the HUD shows in its top corner. Empty in single player.
func hud_text() -> String:
	if not is_online():
		# Back in single player, show why for a few seconds ("THE HOST LEFT").
		return status if Time.get_ticks_msec() - status_time < 5000 else ""
	var count := multiplayer.get_peers().size() + 1
	var players := "1 PLAYER" if count == 1 else "%d PLAYERS" % count
	if multiplayer.is_server():
		return "HOST  " + players
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return "CONNECTING"
	return "ONLINE  " + players


# --- Starting and stopping ---------------------------------------------------

## Starts hosting a game that others can join. The level starts again.
func host(port := DEFAULT_PORT) -> void:
	if is_online():
		return
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(port, MAX_PLAYERS - 1) != OK:
		status = "CANNOT HOST ON PORT %d" % port
		return
	multiplayer.multiplayer_peer = peer
	join_order = [1]
	status = "HOSTING ON PORT %d" % port
	# Start the level again, this time as a shared one.
	main.load_level()


## Connects to the game hosted at "address" (like 192.168.1.20).
func join(address: String, port := DEFAULT_PORT) -> void:
	if is_online():
		return
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(address, port) != OK:
		status = "BAD ADDRESS"
		return
	multiplayer.multiplayer_peer = peer
	status = "CONNECTING TO " + address
	# Put our own level away. The host's arrives once we are connected.
	main.clear_level()


## Stops hosting, or leaves the game, and goes back to single player.
func leave() -> void:
	if is_online():
		_go_offline("")


func _on_connected() -> void:
	status = "CONNECTED"


func _go_offline(message: String) -> void:
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	status = message
	join_order.clear()
	# Back to a fresh single-player game. (main.gd remembers the level.)
	get_tree().reload_current_scene()


# --- Players coming and going (on the host) ----------------------------------

func _on_peer_connected(id: int) -> void:
	# With several players, everyone hears about everyone, but only the
	# host acts on it.
	if not multiplayer.is_server():
		return
	join_order.append(id)
	if is_instance_valid(main.level):
		_spawn_player(id)
	# Tell the newcomer which crates and pylons are already gone.
	_remove_destroyed.rpc_id(id, destroyed)


func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	join_order.erase(id)
	# The spawner removes their player from everyone else's game too.
	var player := _find_player(id)
	if player:
		player.queue_free()


# --- Levels ------------------------------------------------------------------

## Called by main.gd on the host: puts level number "index" in place on every
## computer, with a player in it for everyone.
func spawn_level(index: int) -> void:
	destroyed.clear()
	# spawn() calls _make_level here, and on every other computer too.
	_use_level(level_spawner.spawn(index))
	for id in join_order:
		_spawn_player(id)


## The level spawner's spawn function. Runs on every computer.
func _make_level(index: int) -> Node:
	var level: Node = main.levels[index].instantiate()
	# The level's own Player only marks where to start: online, everyone gets
	# a player of their own instead (see _make_player).
	var placeholder := level.get_node_or_null("Player") as Node3D
	if placeholder:
		spawn_point = placeholder.transform
		level.remove_child(placeholder)
		placeholder.free()
	return level


## Hands a new level (made by the spawner) to main.gd.
func _use_level(level: Node) -> void:
	main.adopt_level(level)
	# Players are spawned inside the level, so they go when it goes.
	player_spawner.spawn_path = player_spawner.get_path_to(level)
	_apply_destroyed()


## Called by crates and pylons on the host when they are destroyed.
func record_destroyed(node: Node) -> void:
	if is_online() and multiplayer.is_server() and is_instance_valid(main.level):
		destroyed.append(String(main.level.get_path_to(node)))


@rpc("authority", "call_remote", "reliable")
func _remove_destroyed(paths: PackedStringArray) -> void:
	pending_destroyed = paths
	_apply_destroyed()


func _apply_destroyed() -> void:
	if not is_instance_valid(main.level):
		return  # not here yet: _use_level() calls this again when it is
	for path in pending_destroyed:
		var node: Node = main.level.get_node_or_null(path)
		if node:
			node.queue_free()
	pending_destroyed.clear()


# --- Players -----------------------------------------------------------------

func _spawn_player(id: int) -> void:
	# The data must be something that can be sent over the network: plain
	# numbers, vectors, strings, and arrays and dictionaries of those.
	var number := join_order.find(id)
	# Stand them in a row, alternating sides: 0, right, left, 2 right... Each
	# player then finds a free spot of their own (see player.gd).
	var steps := ceili(number / 2.0) * (1.0 if number % 2 == 1 else -1.0)
	var side := spawn_point.basis.x * steps * 0.9
	player_spawner.spawn({id = id, color = number, position = spawn_point.origin + side})


## The player spawner's spawn function. Runs on every computer.
func _make_player(data: Dictionary) -> Node:
	var player := PLAYER_SCENE.instantiate()
	# The name is the peer ID of whoever controls this player. player.gd
	# reads it in _enter_tree() to know whose it is.
	player.name = str(data.id)
	player.transform = Transform3D(spawn_point.basis, data.position)
	player.get_node("Model").armor_color = PLAYER_COLORS[data.color % PLAYER_COLORS.size()]
	return player


func _find_player(id: int) -> Node:
	if not is_instance_valid(main.level):
		return null
	return main.level.get_node_or_null(str(id))


## Finds a place near the level's start where "player" fits without being
## inside a wall or another player. Used when a player appears or respawns.
func find_spawn_position(player: CollisionObject3D) -> Vector3:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.exclude = [player.get_rid()]
	var space := player.get_world_3d().direct_space_state

	# Try the start itself, then spots a step to either side, then a step
	# forwards and to either side of that.
	var right := spawn_point.basis.x
	var forward := -spawn_point.basis.z
	for offset: Vector3 in [Vector3.ZERO, right, -right, right * 2.0, -right * 2.0,
			forward, forward + right, forward - right, forward * 2.0]:
		var spot := spawn_point.origin + offset
		# The capsule's middle, lifted 5 cm so it isn't touching the floor.
		query.transform = Transform3D(Basis(), spot + Vector3.UP * 0.95)
		# intersect_shape lists whatever overlaps the shape (at most 1 here).
		if space.intersect_shape(query, 1).is_empty():
			return spot
	return spawn_point.origin
