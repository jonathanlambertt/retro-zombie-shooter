extends Node3D
## A grenade's explosion: hurts everything nearby, flashes, and removes
## itself a moment later.
##
## How to use it (see scripts/grenade.gd):
##   var explosion := EXPLOSION_SCENE.instantiate()
##   level.add_child(explosion)
##   explosion.global_position = where
##   explosion.detonate()

const PlaceholderSound := preload("res://scripts/placeholder_sound.gd")
const BULLET_HOLE_SCENE := preload("res://scenes/bullet_hole.tscn")

## Damage dealt to something right at the centre of the blast.
@export var max_damage := 60
## How far the blast reaches, in metres. Damage fades to nothing at this
## distance.
@export var radius := 3.5
## Damage to the blocks of walls and floors (scripts/structure.gd) right at
## the centre. Concrete blocks take 120 to break, lab walls 70.
@export var structure_damage := 180.0
## How far the damage to walls and floors reaches, in metres. Smaller than
## "radius": a blast hurts people further away than it breaks concrete.
@export var structure_radius := 1.75
## SOUND HOOK: drag a .wav or .ogg file here in the Inspector to use your own
## explosion. If left empty, a burst of noise is generated as a stand-in.
@export var explosion_sound: AudioStream

## False for an explosion that is only for show. Online, every game draws
## each explosion, but only one of them (the game that fired the rocket or
## grenade, or the host for a pylon) deals the damage.
var deals_damage := true

@onready var fireball: MeshInstance3D = $Fireball
@onready var flash_light: OmniLight3D = $FlashLight
@onready var sound_player: AudioStreamPlayer = $Sound
@onready var smoke: CPUParticles3D = $Smoke


func detonate() -> void:
	if deals_damage:
		_damage_everything_nearby()

	if explosion_sound == null:
		explosion_sound = PlaceholderSound.make_noise_burst(0.6)
	sound_player.stream = explosion_sound
	sound_player.play()

	# Throw out a cloud of grey and black specks, Quake-style. How many, how
	# fast and how dark is all set on the Smoke node in the Inspector.
	smoke.emitting = true

	# The fireball swells up fast, shrinks away, and the light fades with it.
	# A tween plays its steps one after another unless told otherwise.
	fireball.scale = Vector3.ONE * 0.2
	var tween := create_tween()
	tween.tween_property(fireball, "scale", Vector3.ONE, 0.1)
	tween.tween_property(fireball, "scale", Vector3.ONE * 0.01, 0.25)
	tween.parallel().tween_property(flash_light, "light_energy", 0.0, 0.25)
	tween.tween_callback(fireball.hide)
	# Stay around until the sound and the smoke have finished, then go.
	tween.tween_interval(1.5)
	tween.tween_callback(queue_free)


## Hurts the player, every enemy and every crate or pylon within the blast
## radius. The closer they are, the more it hurts. Yes, that includes
## whoever fired it!
func _damage_everything_nearby() -> void:
	# Walls, floors, ceilings and pillars. (Only the blocks near the blast
	# are looked at, see blast() in scripts/structure.gd.)
	for structure in get_tree().get_nodes_in_group("structure"):
		structure.blast(global_position, structure_radius, structure_damage)

	var targets := get_tree().get_nodes_in_group("enemy")
	targets.append_array(get_tree().get_nodes_in_group("player"))
	targets.append_array(get_tree().get_nodes_in_group("breakable"))

	for target: Node3D in targets:
		# Measure to the middle of the body rather than its feet.
		var target_centre := target.global_position + Vector3.UP * 0.5
		var distance := global_position.distance_to(target_centre)
		if distance >= radius or not _has_clear_path(target, target_centre):
			continue
		# 1.0 at the centre of the blast, fading to 0.0 at its edge.
		var strength := 1.0 - distance / radius
		if target.has_method("bleed"):
			target.bleed(target_centre, Vector3.ZERO)
		target.take_damage(ceili(max_damage * strength))


## True if no wall stands between the explosion and the target, so a blast
## in one room can't hurt something in the next.
func _has_clear_path(target: Node3D, target_centre: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position, target_centre)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	# Being stopped by another enemy doesn't count as cover.
	return hit.is_empty() or hit.collider == target or hit.collider.has_method("take_damage")


## Leaves a blackened patch on the surface the grenade hit: a bullet hole,
## only much bigger.
func leave_scorch_mark(at: Vector3, normal: Vector3) -> void:
	# A mark that would hang over an edge isn't shown (see
	# scripts/surface_mark.gd), so try a big one first and then smaller ones
	# until one fits.
	for size: float in [6.0, 4.0, 2.5]:
		var mark := BULLET_HOLE_SCENE.instantiate()
		get_parent().add_child(mark)
		if mark.place(at, normal, size):
			return
