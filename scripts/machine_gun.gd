extends Node3D
## Machine gun: fully automatic, and fires visible yellow bullets.
##
## Unlike the pistol (which is "hitscan" and hits instantly), every shot here
## creates a real bullet object (scenes/bullet.tscn) that flies through the
## level and deals its damage when it arrives. Hold the trigger to keep firing.

const PlaceholderSound := preload("res://scripts/placeholder_sound.gd")
## preload() loads the bullet scene once, ready to be copied for every shot.
const BULLET_SCENE := preload("res://scenes/bullet.tscn")

## Damage per bullet.
@export var damage := 6
## Time between bullets, in seconds. 0.09 is about 11 bullets a second.
@export var fire_interval := 0.09
@export var ammo := 150
## Bullet speed in metres per second.
@export var bullet_speed := 45.0
## How much the bullets scatter. 0 = perfectly accurate.
@export var spread_degrees := 1.5
## SOUND HOOK: drag a .wav or .ogg file here in the Inspector to use your own
## gunshot. If left empty, a short burst of noise is generated as a stand-in.
@export var shoot_sound: AudioStream

## Counts down to zero; the gun can fire again when it gets there.
var cooldown := 0.0
## True while the fire button is being held down.
var trigger_held := false

@onready var model: Node3D = $Model
@onready var muzzle_flash: Node3D = $MuzzleFlash
@onready var sound_player: AudioStreamPlayer = $ShootSound


func _ready() -> void:
	if shoot_sound == null:
		shoot_sound = PlaceholderSound.make_noise_burst(0.08)
	sound_player.stream = shoot_sound


func _unhandled_input(event: InputEvent) -> void:
	# Remember whether the trigger is down. Starting to fire needs the mouse
	# to be captured, so the click that grabs the mouse doesn't shoot.
	if event.is_action_pressed("shoot") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		trigger_held = true
	elif event.is_action_released("shoot"):
		trigger_held = false


func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	# A weapon that isn't in the player's hand is hidden, and must not fire.
	if trigger_held and visible:
		fire()


func fire() -> void:
	if cooldown > 0.0 or ammo <= 0:
		return
	cooldown = fire_interval
	ammo -= 1

	_spawn_bullet()
	_play_effects()


func _spawn_bullet() -> void:
	var camera := get_viewport().get_camera_3d()
	var eye := camera.global_position
	# A camera looks along its own negative Z axis.
	var forward := -camera.global_transform.basis.z

	# The gun sits to the right of the camera, so a bullet flying straight
	# out of the barrel would land beside the crosshair. Instead, find the
	# point the crosshair is on and send the bullet from the barrel to there.
	var aim_point := eye + forward * 100.0
	var query := PhysicsRayQueryParameters3D.create(eye, aim_point)
	# "owner" is the root of the scene this gun was placed in: the player.
	if owner is CollisionObject3D:
		query.exclude = [owner.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		aim_point = hit.position

	var start := muzzle_flash.global_position
	var direction := forward
	# (When the target is right in front of your face, just shoot forwards.)
	if eye.distance_to(aim_point) > 1.0:
		direction = (aim_point - start).normalized()

	# Nudge the direction by a small random amount for a bit of scatter.
	var spread := tan(deg_to_rad(spread_degrees))
	direction += Vector3(randf_range(-spread, spread), randf_range(-spread, spread), randf_range(-spread, spread))
	direction = direction.normalized()

	var bullet := BULLET_SCENE.instantiate()
	bullet.damage = damage
	bullet.shooter = owner as CollisionObject3D
	# Add the bullet to the level (the player's parent), not to the gun.
	# Otherwise it would swing around with the camera as you turn.
	owner.get_parent().add_child(bullet)
	bullet.launch(start, direction, bullet_speed)


## Muzzle flash, recoil kick and sound.
func _play_effects() -> void:
	sound_player.play()

	model.position.z = 0.02
	create_tween().tween_property(model, "position:z", 0.0, 0.06)

	muzzle_flash.rotation.z = randf() * TAU
	muzzle_flash.visible = true
	await get_tree().create_timer(0.04).timeout
	muzzle_flash.visible = false
