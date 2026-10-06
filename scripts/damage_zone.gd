extends Area3D
## A region that hurts whatever is standing in it: lava, toxic slime and the
## like. An Area3D doesn't block movement; it just knows what is inside it.
##
## The zone has no picture of its own. Levels pair it with a glowing slab
## (see the slime in levels/half-life-level.tscn).

## Damage dealt each time the zone "bites".
@export var damage := 10
## Seconds between bites.
@export var interval := 0.5

## Counts down to zero; the zone bites when it gets there.
var cooldown := 0.0


func _physics_process(delta: float) -> void:
	# Online, only the host bites, or everyone standing in it would be
	# bitten once by every computer in the game. (A player's damage is then
	# passed on to that player's own computer, see scripts/player.gd.)
	if not multiplayer.is_server():
		return
	cooldown -= delta
	if cooldown > 0.0:
		return
	cooldown = interval
	# The player and the enemies are all "bodies", and anything with a
	# take_damage() function can be hurt.
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)
