@tool
extends Node3D
## A ladder that is climbed the way the ladders in Half-Life are.
##
## There is no "use" key and no climbing animation. Touching the ladder is
## enough to hold on to it: while any part of a player is inside the space
## just in front of it (the "climb volume", which Half-Life's maps call a
## func_ladder), that player stops falling, and the movement keys move them
## over the ladder instead of over the floor. All of that is done by
## scripts/player.gd (see _climb() there). This script only builds the
## ladder to the height asked for and answers one question for the player:
## are you touching me?
##
## The ladder is two rails and a row of rungs. They have no collision: it is
## the wall behind them that stops the player, and that shots mark.
##
## Its origin is the middle of its foot, against the wall, and it is climbed
## from its +Z side (the blue arrow in the editor), so that arrow has to
## point out of the wall. "@tool" makes this script run in the editor as
## well, so changing Height or Width rebuilds the ladder straight away.

## The rails are square posts this thick, in metres.
const RAIL_THICKNESS := 0.05
## How far the middle of the rails and rungs is from the wall, in metres.
const STAND_OFF := 0.075
## A player whose feet are within this far of the top has let go, in
## metres. Without it, somebody standing on the floor at the top with their
## feet a hair's breadth lower than Height would be holding the ladder.
const TOP_SLACK := 0.02

## How far the ladder climbs, in metres: from the floor at its foot to the
## floor it leads up to. The climb volume ends there too, so somebody
## standing at the top is no longer on the ladder.
@export var height := 3.0:
	set(value):
		height = value
		_update()
## How wide the ladder is, in metres, across the outside of its rails.
@export var width := 0.6:
	set(value):
		width = value
		_update()
## The gap from one rung to the next, in metres.
@export var rung_spacing := 0.3:
	set(value):
		rung_spacing = value
		_update()
## How far out from the wall the climb volume reaches, in metres. Further =
## the ladder catches hold of a player from further away.
@export var grab_distance := 0.2

@onready var rail_left: MeshInstance3D = $RailLeft
@onready var rail_right: MeshInstance3D = $RailRight
@onready var rung_template: MeshInstance3D = $Rung
@onready var rungs: Node3D = $Rungs


func _ready() -> void:
	_update()


## The scene holds two rails 1 m tall and one hidden rung 1 m wide. Stretch
## the rails to Height, move them Width apart and put a copy of the rung
## every Rung Spacing up the ladder.
func _update() -> void:
	# The setters above also run while the scene is still being loaded,
	# before the child nodes exist. _ready() calls this again once they do.
	if not is_node_ready():
		return
	var rail_offset := (width - RAIL_THICKNESS) / 2.0
	rail_left.position = Vector3(-rail_offset, height / 2.0, STAND_OFF)
	rail_right.position = Vector3(rail_offset, height / 2.0, STAND_OFF)
	rail_left.scale.y = height
	rail_right.scale.y = height

	# Start again with no rungs. (free() removes a node at once; the usual
	# queue_free() would leave the old rungs in place until the frame ends.)
	for old_rung in rungs.get_children():
		rungs.remove_child(old_rung)
		old_rung.free()
	# The first rung is one gap above the floor, and the last one stops a
	# little short of the top. (Never less than 10 cm apart, or a slip of
	# the finger in the Inspector could ask for thousands of rungs.)
	var gap := maxf(rung_spacing, 0.1)
	var rung_count := int((height - RAIL_THICKNESS) / gap)
	for i in rung_count:
		var rung := rung_template.duplicate() as MeshInstance3D
		rung.visible = true
		rung.scale.x = width - RAIL_THICKNESS * 2.0
		rung.position = Vector3(0.0, gap * (i + 1), STAND_OFF)
		rungs.add_child(rung)


## The direction straight out of the wall, towards whoever is climbing.
func get_facing() -> Vector3:
	return global_basis.z.normalized()


## True if a body is touching the climb volume: the space from the wall out
## to Grab Distance, as wide as the ladder and as tall as Height.
##
## The body is treated as an upright box, with its feet at "feet", reaching
## "radius" to every side and "body_height" tall. Half-Life tests a box
## too, which is why brushing a ladder with your shoulder is enough.
func holds(feet: Vector3, radius: float, body_height: float) -> bool:
	# to_local() turns a place in the level into one measured from this
	# ladder: x across it, y up from its foot, z out from the wall.
	var place := to_local(feet)
	if absf(place.x) > width / 2.0 + radius:
		return false  # off to one side
	if place.z - radius > grab_distance or place.z + radius < 0.0:
		return false  # too far out, or behind the wall
	# Feet below the top, and head above the foot.
	return place.y < height - TOP_SLACK and place.y + body_height > 0.0
