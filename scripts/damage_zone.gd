extends Area3D
## A region that hurts whatever is standing in it: lava, toxic slime and the
## like. An Area3D doesn't block movement; it just knows what is inside it.
##
## The zone has no picture of its own. Levels pair it with a glowing slab
## (see the lava in levels/quake-level.tscn).

## Damage dealt each time the zone "bites".
@export var damage := 10
## Seconds between bites.
@export var interval := 0.5

## Counts down to zero; the zone bites when it gets there.
var cooldown := 0.0


func _physics_process(delta: float) -> void:
	cooldown -= delta
	if cooldown > 0.0:
		return
	cooldown = interval
	# The player and the enemies are all "bodies", and anything with a
	# take_damage() function can be hurt.
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)
