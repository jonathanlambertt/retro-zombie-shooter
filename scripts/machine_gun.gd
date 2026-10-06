extends Node3D
## Machine gun: fully automatic, fires visible yellow bullets, has a grenade
## launcher slung under the barrel, and never runs out of either.
##
## Unlike the pistol (which is "hitscan" and hits instantly), every shot here
## creates a real bullet object (scenes/bullet.tscn) that flies through the
## level and deals its damage when it arrives. Hold the trigger to keep firing.
##
## The second fire button (right mouse) lobs a grenade (scenes/grenade.tscn).
## The only limit on grenades is the wait between them.
##
## Online, the other players' games repeat each bullet and grenade with
## replay_shot(). Their copies fly the same way and leave the same marks,
## but do no damage: only the copy in the game that fired does.

const PlaceholderSound := preload("res://scripts/placeholder_sound.gd")
## preload() loads a scene once, ready to be copied for every shot.
const BULLET_SCENE := preload("res://scenes/bullet.tscn")
const GRENADE_SCENE := preload("res://scenes/grenade.tscn")

@export_group("Bullets")
## Damage per bullet.
@export var damage := 6
## Time between bullets, in seconds. 0.09 is about 11 bullets a second.
@export var fire_interval := 0.09
## Bullet speed in metres per second.
@export var bullet_speed := 45.0
## How much the bullets scatter. 0 = perfectly accurate.
@export var spread_degrees := 1.5
## SOUND HOOK: drag a .wav or .ogg file here in the Inspector to use your own
## gunshot. If left empty, a short burst of noise is generated as a stand-in.
@export var shoot_sound: AudioStream

@export_group("Grenades")
## Minimum time between grenades, in seconds.
@export var grenade_interval := 1.0
## How fast a grenade leaves the launcher, in metres per second.
@export var grenade_speed := 22.0
## How far above the crosshair a grenade is launched, to make up for it
## dropping as it flies. 0 = straight at the crosshair.
@export var grenade_lob_degrees := 4.0
## SOUND HOOK: the launcher's own sound, used the same way as Shoot Sound.
@export var grenade_sound: AudioStream

## Counts down to zero; the gun can fire again when it gets there.
var cooldown := 0.0
## The same, for the grenade launcher.
var grenade_cooldown := 0.0
## True while the fire button is being held down.
var trigger_held := false

@onready var model: Node3D = $Model
@onready var muzzle_flash: Node3D = $MuzzleFlash
@onready var sound_player: AudioStreamPlayer = $ShootSound
@onready var grenade_sound_player: AudioStreamPlayer = $GrenadeSound


func _ready() -> void:
	if shoot_sound == null:
		shoot_sound = PlaceholderSound.make_noise_burst(0.08)
	sound_player.stream = shoot_sound
	if grenade_sound == null:
		grenade_sound = PlaceholderSound.make_noise_burst(0.2)
	grenade_sound_player.stream = grenade_sound


func _unhandled_input(event: InputEvent) -> void:
	# Remember whether the trigger is down. Starting to fire needs the mouse
	# to be captured, so the click that grabs the mouse doesn't shoot.
	var mouse_is_captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("shoot") and mouse_is_captured:
		trigger_held = true
	elif event.is_action_released("shoot"):
		trigger_held = false
	# A weapon that isn't in the player's hand is hidden, and must not fire.
	elif event.is_action_pressed("alt_fire") and mouse_is_captured and visible:
		fire_grenade()


func _notification(what: int) -> void:
	# Godot sends NOTIFICATION_PAUSED when the pause menu freezes the game.
	# A paused node hears no input, so it would miss the button being let go
	# and carry on firing after the game resumes. Let go of the trigger now.
	if what == NOTIFICATION_PAUSED:
		trigger_held = false


func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	grenade_cooldown = maxf(grenade_cooldown - delta, 0.0)
	# Online the pause menu doesn't pause, so let go of the trigger when it
	# frees the mouse (it takes the button release for itself).
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		trigger_held = false
	# A weapon that isn't in the player's hand is hidden, and must not fire.
	if trigger_held and visible:
		fire()


## The words the HUD shows in the bottom-right corner while this weapon is
## in hand.
func get_hud_text() -> String:
	return "AMMO UNLIMITED"


func fire() -> void:
	if cooldown > 0.0:
		return
	cooldown = fire_interval

	_spawn_bullet()
	_play_effects()


func fire_grenade() -> void:
	if grenade_cooldown > 0.0:
		return
	grenade_cooldown = grenade_interval

	_spawn_grenade()
	_play_grenade_effects()


func _spawn_bullet() -> void:
	# "owner" is the root of the scene this gun was placed in: the player,
	# who works out where the bullet starts (the barrel may be poking
	# through a wall) and where the crosshair is pointing (see
	# scripts/player.gd).
	var start: Vector3 = owner.get_projectile_start(muzzle_flash.global_position)
	var direction: Vector3 = owner.get_aim_direction(start)
	# Nudge the direction by a small random amount for a bit of scatter.
	var spread := tan(deg_to_rad(spread_degrees))
	direction += Vector3(randf_range(-spread, spread), randf_range(-spread, spread), randf_range(-spread, spread))
	direction = direction.normalized()

	_launch_bullet(start, direction, true)
	owner.share_shot(self, ["bullet", start, direction])


func _launch_bullet(start: Vector3, direction: Vector3, hurts: bool) -> void:
	var bullet := BULLET_SCENE.instantiate()
	bullet.damage = damage
	bullet.deals_damage = hurts
	bullet.shooter = owner as CollisionObject3D
	# Add the bullet to the level (the player's parent), not to the gun.
	# Otherwise it would swing around with the camera as you turn.
	owner.get_parent().add_child(bullet)
	bullet.launch(start, direction, bullet_speed)


func _spawn_grenade() -> void:
	# Tilt the aim upwards a little. "basis.x" is the camera's right-hand
	# side, and turning around that axis tips the direction up or down.
	var camera: Camera3D = owner.camera
	var right := camera.global_transform.basis.x.normalized()
	var start: Vector3 = owner.get_projectile_start(muzzle_flash.global_position)
	var direction: Vector3 = owner.get_aim_direction(start)
	direction = direction.rotated(right, deg_to_rad(grenade_lob_degrees))

	_launch_grenade(start, direction, true)
	owner.share_shot(self, ["grenade", start, direction])


func _launch_grenade(start: Vector3, direction: Vector3, hurts: bool) -> void:
	var grenade := GRENADE_SCENE.instantiate()
	grenade.deals_damage = hurts
	grenade.shooter = owner as CollisionObject3D
	owner.get_parent().add_child(grenade)
	grenade.launch(start, direction, grenade_speed)


## Repeats a bullet or grenade fired on another computer (see the top of
## this script). Returns the sound for the shooter's body to play.
func replay_shot(shot: Array) -> AudioStream:
	if shot[0] == "grenade":
		_launch_grenade(shot[1], shot[2], false)
		return grenade_sound
	_launch_bullet(shot[1], shot[2], false)
	return shoot_sound


## Muzzle flash, recoil kick and sound.
func _play_effects() -> void:
	sound_player.play()

	model.position.z = 0.02
	create_tween().tween_property(model, "position:z", 0.0, 0.06)

	muzzle_flash.rotation.z = randf() * TAU
	muzzle_flash.visible = true
	await get_tree().create_timer(0.04).timeout
	muzzle_flash.visible = false


## A heavier kick than a bullet gives, and the launcher's own "thunk".
func _play_grenade_effects() -> void:
	grenade_sound_player.play()

	model.position.z = 0.08
	model.rotation.x = 0.12
	var tween := create_tween().set_parallel()
	tween.tween_property(model, "position:z", 0.0, 0.25)
	tween.tween_property(model, "rotation:x", 0.0, 0.25)
