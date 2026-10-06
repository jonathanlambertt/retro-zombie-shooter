extends Node3D
## A window that zombies climb in through.
##
## Enemies walk in a straight line and can't step up onto anything, so a
## window sill stops them dead. This node does the thinking for them. It
## watches a box of space outside the window (the "yard"), and for every
## enemy in there that is chasing a player it:
##   1. sends it to the spot on the ground just below the window, and
##   2. when it gets there, and nobody else is in the way, hauls it up onto
##      the sill, across it and down the other side, one enemy at a time.
## After that the enemy is inside and carries on chasing as usual.
##
## It also wakes the enemies in the yard as soon as a player comes near the
## window, since they often can't see into the room from where they stand.
##
## The enemy does the moving itself: see head_for() and climb_through() in
## scripts/enemy.gd. Anything in the "enemy" group that has those functions
## will use the window.
##
## Putting one in a level:
##   - Cut the hole in the wall yourself, with a Carve box in the level's
##     World: 1.4 m wide, from 0.9 m to 2.2 m above the floor, through a wall
##     0.5 m thick. (Those are the sizes the frame in this scene is built
##     for. The settings below must match if you change the hole.)
##   - Put this scene on the floor in the middle of that wall, turned so its
##     blue arrow (+Z) points OUT, to where the zombies come from.
##   - Give the zombies somewhere to stand out there, and put them in it.
##
## Limitations: enemies only come in, never back out, and a player who
## crouch-jumps may get out through the hole.
##
## Multiplayer: only the host's copy does anything. The enemies' positions
## and their CLIMB state reach the other players the usual way.

## How high the bottom of the opening is above the floor, in metres.
@export var sill_height := 0.9
## How thick the wall is, in metres.
@export var wall_thickness := 0.5
## How far from the middle of the wall an enemy stands before it climbs,
## and where it lands on the other side, in metres.
@export var stand_off := 0.9
## How fast an enemy moves while climbing, in metres per second.
@export var climb_speed := 1.5
## The size of the yard: the space outside the window that this node
## watches. x = along the wall, y = up, z = out from the wall, in metres.
@export var yard_size := Vector3(7.0, 3.0, 6.0)
## A player this close to the window wakes every enemy in the yard.
@export var alert_distance := 9.0

## The enemy that is climbing through right now (or null).
var climber: Node3D
## Seconds until the next check for a player nearby. A few times a second
## is plenty.
var alert_cooldown := 0.5


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	# to_global turns a position measured from this node into one in the
	# level. +Z is outside, so this is the spot on the ground below the sill.
	var outside := to_global(Vector3(0.0, 0.0, stand_off))
	var busy: bool = is_instance_valid(climber) and climber.is_climbing()

	alert_cooldown -= delta
	var alert := false
	if alert_cooldown <= 0.0:
		alert_cooldown = 0.25
		alert = _player_is_near()

	for enemy: Node3D in get_tree().get_nodes_in_group("enemy"):
		if not enemy.has_method("climb_through") or not _in_yard(enemy.global_position):
			continue
		if alert:
			enemy.notice_player()
		if not enemy.is_chasing():
			continue

		var gap := enemy.global_position - outside
		gap.y = 0.0
		if not busy and gap.length() < 0.4:
			if enemy.climb_through(_path(), climb_speed):
				climber = enemy
				busy = true
		else:
			# Called every frame: the enemy forgets the detour when this stops.
			enemy.head_for(outside)


## The points an enemy passes on its way through, in order: up onto the
## outer edge of the sill, across to the inner edge, and down to the floor
## inside. (-Z is the way in.)
func _path() -> Array[Vector3]:
	var edge := wall_thickness / 2.0 + 0.1
	return [
		to_global(Vector3(0.0, sill_height, edge)),
		to_global(Vector3(0.0, sill_height, -edge)),
		to_global(Vector3(0.0, 0.0, -stand_off)),
	]


## True if a position in the level is inside the yard.
func _in_yard(point: Vector3) -> bool:
	# to_local is the opposite of to_global: it measures the point from this
	# node, so the yard is a simple box however the window is turned.
	var local := to_local(point)
	var near_edge := wall_thickness / 2.0
	return (absf(local.x) <= yard_size.x / 2.0
			and local.z >= near_edge and local.z <= near_edge + yard_size.z
			and local.y >= -0.5 and local.y <= yard_size.y)


func _player_is_near() -> bool:
	for player: Node3D in get_tree().get_nodes_in_group("player"):
		if player.global_position.distance_to(global_position) < alert_distance:
			return true
	return false
