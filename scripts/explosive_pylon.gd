extends CharacterBody3D
## An explosive pylon: a red canister of something that really shouldn't be
## shot. Shoot it (or blow it up) and, after a short hiss, it explodes,
## hurting everything nearby: enemies, crates, other pylons and you.
##
## Like the crate (scripts/crate.gd) it is a CharacterBody3D in the
## "breakable" group, so weapons hurt it with take_damage() and explosions
## find it through the group. It also has a bleed() method, which weapons
## call on whatever they hit. Enemies bleed blood; a pylon throws sparks.
##
## Pylons standing close together set each other off one after another.
## That isn't special code: the blast of one simply damages the next, which
## then lights its own fuse.

const PlaceholderSound := preload("res://scripts/placeholder_sound.gd")
const EXPLOSION_SCENE := preload("res://scenes/explosion.tscn")

## How much damage it takes to set off. 15 is two pistol shots, or three
## machine gun bullets.
@export var health := 15
## Seconds between being set off and exploding. The hiss and the shaking
## warn you to get clear, and the delay makes a row of pylons go off one
## after another instead of all at once.
@export var fuse_time := 0.3
## Damage dealt to something right next to the pylon. (A grenade does 60.)
@export var blast_damage := 100
## How far the blast reaches, in metres. Damage fades to nothing at this
## distance.
@export var blast_radius := 5.0
## How much bigger the fireball is than a grenade's.
@export var fireball_size := 1.5
## How often the warning lamp blinks, in blinks per second. It blinks
## faster as the pylon is damaged.
@export var blink_speed := 1.0
@export var gravity := 20.0
## SOUND HOOK: drag a .wav or .ogg file here in the Inspector to use your own
## fuse hiss. If left empty, a burst of noise is generated instead. (The bang
## itself is the explosion's sound, set on scenes/explosion.tscn.)
@export var fuse_sound: AudioStream

## The health it started with, to work out how damaged it is.
var starting_health := 0
## True once it has been set off and the fuse is burning.
var lit := false
## Counts up all the time; the lamp is on for the first half of each second.
var blink_clock := 0.0

@onready var model: Node3D = $Model
@onready var lamp: MeshInstance3D = $Model/Lamp
@onready var sparks: CPUParticles3D = $Sparks
@onready var debris: CPUParticles3D = $Debris
@onready var fuse_sound_player: AudioStreamPlayer = $FuseSound


func _ready() -> void:
	starting_health = health
	# Start each pylon's lamp at a different point in its blink, so a group
	# of them doesn't flash in step.
	blink_clock = randf()
	if fuse_sound == null:
		fuse_sound = PlaceholderSound.make_noise_burst(fuse_time + 0.1)
	fuse_sound_player.stream = fuse_sound


func _process(delta: float) -> void:
	if lit:
		# Once lit, the lamp stays on and the whole pylon rattles in place.
		lamp.visible = true
		model.position = Vector3(randf_range(-0.03, 0.03), 0.0, randf_range(-0.03, 0.03))
		return

	# 1.0 when untouched, down towards 0.0 just before it goes off.
	var health_left := float(health) / maxi(starting_health, 1)
	blink_clock += delta * blink_speed * lerpf(4.0, 1.0, health_left)
	lamp.visible = fmod(blink_clock, 1.0) < 0.5


func _physics_process(delta: float) -> void:
	# Like a crate, a pylon only moves by falling when nothing holds it up.
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	move_and_slide()


## Called by weapons (and explosions) just before take_damage(), with the
## spot that was hit and the direction pointing straight out of the surface
## there. A pylon throws a shower of sparks from the hit.
func bleed(at: Vector3, spray_direction: Vector3, _drop_count := 12) -> void:
	if lit:
		return
	sparks.global_position = at
	# The particles' direction is measured in the pylon's own space, so turn
	# the world direction into that. An explosion passes Vector3.ZERO,
	# meaning "no particular direction": spray upwards instead.
	if spray_direction == Vector3.ZERO:
		spray_direction = Vector3.UP
	sparks.direction = global_basis.inverse() * spray_direction
	sparks.restart()  # start the one-shot burst again from the beginning


## Called by weapons and explosions when they hit this pylon.
func take_damage(amount: int) -> void:
	if lit:
		return
	health -= amount
	if health <= 0:
		_light_fuse()


func _light_fuse() -> void:
	lit = true
	fuse_sound_player.play()
	# "false" makes this timer stop while the game is paused, so a pylon
	# can't go off behind the pause menu.
	await get_tree().create_timer(fuse_time, false).timeout
	_explode()


func _explode() -> void:
	# Take it off every collision layer, so it no longer blocks the blast,
	# shots or the player, and stop it falling.
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	model.visible = false
	debris.emitting = true

	var centre := global_position + Vector3.UP * 0.7
	var explosion := EXPLOSION_SCENE.instantiate()
	# A pylon's blast is bigger than the explosion scene's usual settings,
	# the same way a rocket's is (see scripts/rocket.gd).
	explosion.max_damage = blast_damage
	explosion.radius = blast_radius
	get_parent().add_child(explosion)
	explosion.global_position = centre
	# Scaling the explosion node scales everything drawn under it, which
	# makes the fireball bigger. (Its damage uses the radius above instead.)
	explosion.scale = Vector3.ONE * fireball_size

	# Scorch the floor underneath with a ray straight down.
	var query := PhysicsRayQueryParameters3D.create(centre, centre + Vector3.DOWN * 2.0)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and not hit.collider.has_method("take_damage"):
		explosion.leave_scorch_mark(hit.position, hit.normal)
	explosion.detonate()

	# Wait for the scrap metal to land, then remove the pylon for good.
	await get_tree().create_timer(debris.lifetime, false).timeout
	queue_free()  # removes this node from the game
