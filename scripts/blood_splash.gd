extends CPUParticles3D
## A spray of blood: a handful of square drops that burst out of a wound and
## fall to the floor, as in Quake and Half-Life. It also leaves lasting
## stains (scenes/blood_stain.tscn) on the walls and floor nearby.
##
## A CPUParticles3D node draws lots of small copies of one shape (here a flat
## square that always faces the camera) and moves them all for us. The speed,
## spread and gravity of the drops are set on this node in the Inspector
## (see scenes/blood_splash.tscn); this script only aims it and sets it off.
##
## How to use it (see bleed() in scripts/enemy.gd):
##   var splash := BLOOD_SPLASH_SCENE.instantiate()
##   level.add_child(splash)
##   splash.splash(where, direction, Color.RED, 12)

const BLOOD_STAIN_SCENE := preload("res://scenes/blood_stain.tscn")

## How far blood can fly from the wound and still leave a stain, in metres.
@export var stain_range := 2.5
## One stain is left for every this many drops. A splash with fewer drops
## than this only sometimes leaves one.
@export var drops_per_stain := 12
## Stains are this much darker than the drops in the air, like blood that
## has soaked in. 1 = the same colour.
@export var stain_darkness := 0.6


## The way the shot that caused this was travelling, or Vector3.ZERO if the
## blood has no particular direction (a death, or a grenade blast).
var shot_direction := Vector3.ZERO


## Sprays "drop_count" drops of the given colour from a point. "spray_direction"
## is the way they fly: usually straight out of the surface that was hit.
## Pass Vector3.ZERO to send them straight up and stain the floor all around.
func splash(at: Vector3, spray_direction: Vector3, blood_color: Color, drop_count: int) -> void:
	global_position = at
	if spray_direction != Vector3.ZERO:
		direction = spray_direction
		# The drops spray back out of the wound, towards the shooter.
		shot_direction = -spray_direction.normalized()
	# Each drop gets this colour in a randomly lighter or darker shade
	# (that is what Color Initial Ramp on this node does).
	color = blood_color
	amount = drop_count
	emitting = true

	# 30 drops at 12 drops per stain is 2.5 stains: leave 2, plus a third
	# half of the time.
	var stains := float(drop_count) / drops_per_stain
	var stain_count := int(stains)
	if randf() < stains - stain_count:
		stain_count += 1
	for i in stain_count:
		_leave_stain(blood_color)

	# "finished" is announced once the last drop has disappeared.
	await finished
	queue_free()  # removes this node from the game


## Throws one invisible blob of blood and stains whatever it lands on.
##
## The drops you can see are only for show and pass through walls, so the
## stains are worked out separately, with a ray.
func _leave_stain(blood_color: Color) -> void:
	# A shot carries on through the body and out of the back, so the blob
	# flies the way the shot was going, drooping towards the floor, and
	# scattered sideways in a random compass direction so the stains don't
	# all land in one spot. With no shot direction, it only goes sideways
	# and down, which rings the body with stains instead of hiding them
	# underneath it.
	var sideways := Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
	var throw := shot_direction
	if shot_direction == Vector3.ZERO:
		throw = sideways
	throw += sideways * randf_range(0.0, 0.6)
	throw += Vector3.DOWN * randf_range(0.2, 1.2)
	var query := PhysicsRayQueryParameters3D.create(
			global_position, global_position + throw.normalized() * stain_range)

	# The ray starts on a body, and may pass others. Skip over anything that
	# can be hurt (stains on something that walks off would hang in the
	# air) until it reaches a wall or floor, or runs out of range.
	var space := get_world_3d().direct_space_state
	var skipped: Array[RID] = []
	var hit := space.intersect_ray(query)
	while not hit.is_empty() and hit.collider.has_method("take_damage"):
		skipped.append(hit.rid)
		query.exclude = skipped
		hit = space.intersect_ray(query)
	if hit.is_empty():
		return

	var stain := BLOOD_STAIN_SCENE.instantiate()
	get_parent().add_child(stain)
	stain.tint(blood_color.darkened(1.0 - stain_darkness))
	stain.place(hit.position, hit.normal, randf_range(0.6, 1.4))
