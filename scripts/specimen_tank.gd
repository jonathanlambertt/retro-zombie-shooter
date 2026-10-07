@tool
extends StaticBody3D
## A specimen tank from the experimentation lab: a column of glowing liquid
## between a metal base and cap, held up by three rods, with a feed pipe
## running up to the ceiling.
##
## An intact tank can hold a specimen, a copy of the zombie's boxes floating
## limp in the liquid. A broken tank has lost its glass and liquid: shards
## stand round the rim and the liquid has spilled across the floor in front
## of it (the +Z side, the blue arrow in the editor).
##
## "@tool" makes this script run inside the editor as well as in the game,
## so ticking Broken or Occupied in the Inspector shows the result straight
## away instead of only when you press Play.

## Where the cap's top is, in metres above the base. The pipe starts here.
const CAP_TOP := 3.2

## True for a smashed tank: no glass or liquid, shards and a puddle instead.
@export var broken := false:
	set(value):
		broken = value
		_update()
## True if a specimen floats in the tank. Only seen while the tank is intact.
@export var occupied := true:
	set(value):
		occupied = value
		_update()
## How far the feed pipe reaches up from the top of the tank, in metres. Set
## it so the pipe meets the ceiling, or to 0 for no pipe.
@export var pipe_length := 4.8:
	set(value):
		pipe_length = value
		_update()

@onready var liquid: MeshInstance3D = $Liquid
@onready var specimen: Node3D = $Specimen
@onready var shards: Node3D = $Shards
@onready var puddle: MeshInstance3D = $Puddle
@onready var pipe: MeshInstance3D = $Pipe
@onready var glass_shape: CollisionShape3D = $GlassShape


func _ready() -> void:
	_update()


## Shows and hides the parts that differ between an intact and a broken
## tank. The glass's collision shape is switched off too, so shots and
## bodies pass through the gap where it used to be.
func _update() -> void:
	# The setters above also run while the scene is still being loaded,
	# before the child nodes exist. _ready() calls this again once they do.
	if not is_node_ready():
		return
	liquid.visible = not broken
	specimen.visible = occupied and not broken
	shards.visible = broken
	puddle.visible = broken
	glass_shape.disabled = broken
	# The pipe mesh is 1 m long, so stretching it by pipe_length makes it
	# that long. Its material lays the texture out in world space, so the
	# stretch doesn't smear the texture.
	pipe.visible = pipe_length > 0.0
	pipe.scale.y = maxf(pipe_length, 0.01)
	pipe.position.y = CAP_TOP + pipe_length / 2.0
