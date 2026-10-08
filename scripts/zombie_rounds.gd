extends Node3D
## Rounds of zombies: sends them into a level a round at a time, and starts
## the next round once every one of them is dead.
##
## How a round goes:
##   1. A short wait, counted down on the HUD ("ROUND 1 IN 6").
##   2. The round's zombies appear one at a time, each at one of the gates
##      (see below), and come out of it after the players.
##   3. When the last of them has been killed the round is over, and it is
##      back to step 1 for the next round, which has more zombies in it, a
##      little faster on their feet.
## There is no last round. In single player, dying starts the level again
## (scripts/player.gd), and the rounds with it. Online a player who dies comes
## back, and the round carries on.
##
## Gates: every Marker3D that is a child of this node is a gate, a place
## where zombies appear. Enemies walk in a straight line at the nearest
## player, which is a poor way out of a doorway, so each new zombie is first
## walked out of its gate: straight ahead, the way the marker's blue arrow
## (+Z) points, for Walk Out metres. (That uses head_for() in
## scripts/enemy.gd, the same thing a window uses to fetch zombies from its
## yard.) After that it is on its own.
##
## Putting it in a level:
##   - Drag scenes/zombie_rounds.tscn into the level. The level needs an
##     Enemies node next to it, as every level has: the zombies go in there.
##   - Add a Marker3D under it for each gate, somewhere out of sight, and turn
##     it so its blue arrow points the way a zombie should walk out. A marker
##     up in the air is fine: the zombie drops from there.
##   - Keep the way out of each gate clear of crates and pylons.
##
## The HUD (scripts/hud.gd) finds this node through the "rounds" group and
## shows the two lines get_hud_title() and get_hud_note() give it.
##
## Multiplayer (see scripts/network.gd): only the host's copy runs the rounds.
## Its zombies are made by a MultiplayerSpawner, which makes the same zombie
## on every computer, and hands a player who joins later all the zombies
## there are at that moment. The Sync node sends everyone the four numbers the
## HUD needs. Single player is the same thing with nobody listening.

## How long a body takes to sink into the floor before it is removed, in
## seconds, and how fast it sinks, in metres per second.
const SINK_TIME := 1.5
const SINK_SPEED := 0.4

## The enemy the rounds are made of. It must be in the "enemy" group and run
## scripts/enemy.gd (or have the same functions).
@export var zombie_scene: PackedScene
## The node the zombies are added to.
@export var enemies_path := ^"../Enemies"

@export_group("Rounds")
## Seconds of rest before the first round, and between one round and the next.
@export var break_time := 6.0
## How many zombies the first round has.
@export var first_round_zombies := 6
## How many more each round has than the one before.
@export var extra_zombies_per_round := 3
## How much bigger a round is for each player after the first. 0.5 = half as
## many again for two players, twice as many for three.
@export var extra_zombies_per_player := 0.5
## Seconds between one zombie appearing and the next.
@export var spawn_interval := 1.0
## The most zombies alive at once. The rest of the round waits its turn.
@export var max_zombies_at_once := 14

@export_group("Zombies")
## How much faster the zombies of each round are than those of the first.
## 0.05 = 5% of their usual speed more, every round.
@export var speed_gain_per_round := 0.05
## The most speed they can gain that way. 0.75 = at most 75% faster.
@export var max_speed_gain := 0.75
## Seconds a dead zombie lies there before it is cleared away.
@export var body_time := 12.0

@export_group("Gates")
## How far a new zombie walks straight ahead from its gate's marker before
## it goes after the players, in metres. It should bring it out into the open.
@export var walk_out := 4.0
## No zombie appears at a gate while a player is this close to its marker,
## in metres (measured along the ground), unless there is a player that
## close to every gate.
@export var gate_clearance := 5.0
## A zombie still on its way out of a gate turns on a player who comes this
## close, in metres, instead of walking past them.
@export var fight_distance := 2.5

## The round being fought, or the one that has just been won. 0 before the
## first. The host's copy decides this and the three below; the others are
## sent them.
var round_number := 0
## True while a round is being fought, false during the rest before the next.
var fighting := false
## How many of this round's zombies are still to be killed: the ones walking
## about, plus the ones that haven't appeared yet.
var zombies_left := 0
## Whole seconds until the next round starts.
var seconds_left := 0

# Everything from here down is only used by the host.
## Seconds of rest left.
var break_left := 0.0
## How many of this round's zombies haven't appeared yet.
var to_spawn := 0
## Seconds until the next one may appear.
var spawn_cooldown := 0.0
## How many zombies have been made since the level started. Each is named
## after its number.
var zombies_made := 0
## The zombies that are alive.
var horde: Array[Node3D] = []
## The zombies that are still on their way out of a gate, and the gate each
## one came from.
var emerging := {}
## The dead zombies that haven't been cleared away yet, and how many seconds
## longer each one stays.
var bodies := {}

var gates: Array[Marker3D] = []
var enemies: Node3D
var spawner: MultiplayerSpawner


func _ready() -> void:
	enemies = get_node(enemies_path)
	for child in get_children():
		if child is Marker3D:
			gates.append(child)
	if gates.is_empty():
		# Shown in the editor's Debugger while the game runs.
		push_warning("%s has no gates: give it Marker3D children for the zombies to appear at." % name)

	# A MultiplayerSpawner with a "spawn function" calls that function on
	# every computer to make the node, from a little data the host sends (see
	# _ready() in scripts/network.gd, which makes the levels and the players
	# the same way). It is made here, on every computer, with the same name,
	# so the host's messages find it.
	spawner = MultiplayerSpawner.new()
	spawner.name = "Spawner"
	spawner.spawn_function = _make_zombie
	add_child(spawner)
	spawner.spawn_path = spawner.get_path_to(enemies)

	# Only the host counts down to the first round. Everyone else leaves the
	# numbers at zero until the host's arrive (see get_hud_title()).
	if is_multiplayer_authority():
		break_left = break_time
		seconds_left = ceili(break_left)


func _physics_process(delta: float) -> void:
	# Only the host runs the rounds. (In single player, that is us.)
	if not is_multiplayer_authority() or gates.is_empty():
		return
	_clear_away(delta)
	_lead_out()
	if fighting:
		_fight(delta)
	else:
		_rest(delta)


## The first line the HUD shows: which round it is.
func get_hud_title() -> String:
	if fighting:
		return "ROUND %d" % round_number
	# A player who has only just joined hasn't been told anything yet. Show
	# nothing rather than a guess.
	if seconds_left == 0:
		return ""
	if round_number == 0:
		return "GET READY"
	return "ROUND %d CLEAR" % round_number


## The second, smaller line: how many zombies are left, or how long until
## the next round.
func get_hud_note() -> String:
	if fighting:
		return "1 ZOMBIE LEFT" if zombies_left == 1 else "%d ZOMBIES LEFT" % zombies_left
	if seconds_left == 0:
		return ""
	return "ROUND %d IN %d" % [round_number + 1, seconds_left]


## One physics step of the rest between rounds.
func _rest(delta: float) -> void:
	break_left -= delta
	# ceili rounds up, so the count reads 6, 5, ... 1 and never shows a 0.
	seconds_left = maxi(ceili(break_left), 0)
	if break_left <= 0.0:
		_start_round()


func _start_round() -> void:
	round_number += 1
	var zombies := first_round_zombies + extra_zombies_per_round * (round_number - 1)
	# More players, more zombies. (Every player is in the "player" group.)
	var players := maxi(get_tree().get_nodes_in_group("player").size(), 1)
	to_spawn = maxi(roundi(zombies * (1.0 + extra_zombies_per_player * (players - 1))), 1)
	zombies_left = to_spawn
	spawn_cooldown = 0.0
	fighting = true


## One physics step of a round: lets the next zombie in when it is due, and
## ends the round when there are none left.
func _fight(delta: float) -> void:
	spawn_cooldown -= delta
	if to_spawn > 0 and spawn_cooldown <= 0.0 and horde.size() < max_zombies_at_once:
		var gate := _pick_gate()
		# With no gate free, try again on the next step.
		if gate:
			_spawn_zombie(gate)
			to_spawn -= 1
			spawn_cooldown = spawn_interval

	zombies_left = to_spawn + horde.size()
	if zombies_left == 0:
		fighting = false
		break_left = break_time
		seconds_left = ceili(break_left)


## Makes one zombie at a gate, on every computer, and sets it on the players.
func _spawn_zombie(gate: Marker3D) -> void:
	zombies_made += 1
	# Which way is out, kept level in case the marker is tilted.
	var out := gate.global_basis.z
	out.y = 0.0
	# Basis.looking_at makes a turn that faces something's front (-Z) along a
	# direction. Together with the marker's position that is where the zombie
	# starts, which is then measured from the Enemies node it will be under.
	var start := Transform3D(Basis.looking_at(out.normalized()), gate.global_position)
	var speed_up := 1.0 + minf(speed_gain_per_round * (round_number - 1), max_speed_gain)

	# spawn() calls _make_zombie here, and on every other computer too. The
	# data must be something that can be sent over the network: plain
	# numbers, vectors, transforms, and arrays and dictionaries of those.
	var zombie: Node3D = spawner.spawn({
		number = zombies_made,
		start = enemies.global_transform.affine_inverse() * start,
		speed_up = speed_up,
	})
	# It can't see anybody from inside its gate, so tell it they are there.
	zombie.notice_player()
	horde.append(zombie)
	emerging[zombie] = gate


## The spawner's spawn function. Runs on every computer.
func _make_zombie(data: Dictionary) -> Node:
	var zombie: Node3D = zombie_scene.instantiate()
	# A name of its own, the same on every computer: a hit on a zombie is
	# sent to the host's copy of it, which is found by its name.
	zombie.name = "Zombie%d" % data.number
	zombie.transform = data.start
	zombie.move_speed *= data.speed_up
	# Quicker steps to match, or its feet would slide.
	zombie.step_speed *= data.speed_up
	return zombie


## Picks the gate for the next zombie: at random from the ones with no player
## close enough to see it appear (or to be landed on). If there is a player at
## every gate, it is the gate whose nearest player is furthest away, so that
## standing guard at all of them can't hold a round up for ever. Returns null
## if a zombie is still standing in every gate, which soon passes.
func _pick_gate() -> Marker3D:
	var clear: Array[Marker3D] = []
	var furthest: Marker3D = null
	var furthest_distance := -1.0
	for gate in gates:
		if _zombie_in_gate(gate):
			continue
		var distance := _nearest_player_distance(gate.global_position)
		if distance >= gate_clearance:
			clear.append(gate)
		if distance > furthest_distance:
			furthest = gate
			furthest_distance = distance
	if clear.is_empty():
		return furthest
	return clear.pick_random()


## True while the last zombie to appear at this gate is still in the way of
## the next one.
func _zombie_in_gate(gate: Marker3D) -> bool:
	for zombie in horde:
		if _ground_distance(zombie.global_position, gate.global_position) < 1.0:
			return true
	return false


## Walks the newest zombies out of their gates: each one keeps being sent
## straight ahead until it has gone Walk Out metres from its gate's marker.
func _lead_out() -> void:
	# keys() is a copy of the list, so entries can be removed along the way.
	for zombie: Node3D in emerging.keys():
		var gate: Marker3D = emerging[zombie]
		# to_local measures a position from the marker, so z is simply how far
		# along the way out the zombie has got, however the marker is turned.
		if gate.to_local(zombie.global_position).z >= walk_out:
			emerging.erase(zombie)
		elif not _player_within(zombie.global_position, fight_distance):
			# Aim a little past the end, so it doesn't slow to a stop there.
			# Called every step: the zombie forgets the detour when this stops
			# (and an enemy on a detour doesn't attack, which is why a player
			# standing in its way is left to it instead).
			zombie.head_for(gate.to_global(Vector3(0.0, 0.0, walk_out + 1.0)))


## Takes the zombies that have died off the list of the living, and removes
## each body once it has lain there for Body Time.
func _clear_away(delta: float) -> void:
	# duplicate() makes a copy of the list to go through, because the list
	# itself changes along the way.
	for zombie in horde.duplicate():
		if zombie.is_dead():
			horde.erase(zombie)
			emerging.erase(zombie)
			bodies[zombie] = body_time

	for body: Node3D in bodies.keys():
		bodies[body] -= delta
		if bodies[body] <= 0.0:
			bodies.erase(body)
			# The spawner notices, and removes it on every other computer too.
			body.queue_free()
		elif bodies[body] < SINK_TIME:
			# Its last moments: it sinks out of sight instead of blinking out.
			# (Everyone sees this: an enemy's position is always sent.)
			body.position.y -= SINK_SPEED * delta


## True if any player is within "distance" metres of "point", measured along
## the ground.
func _player_within(point: Vector3, distance: float) -> bool:
	return _nearest_player_distance(point) < distance


## How far the nearest player is from "point", in metres along the ground.
## INF (further than anything) if there are no players.
func _nearest_player_distance(point: Vector3) -> float:
	var nearest := INF
	for player: Node3D in get_tree().get_nodes_in_group("player"):
		nearest = minf(nearest, _ground_distance(player.global_position, point))
	return nearest


## The distance between two points, ignoring their heights.
func _ground_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
