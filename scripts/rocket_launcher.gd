extends Node3D
## Rocket launcher: slow to fire, but each rocket (scenes/rocket.tscn) flies
## dead straight and explodes with a bigger blast than a grenade. It never
## runs out of rockets; the wait between shots is the only limit.
##
## Careful: the blast hurts you too, so don't fire it at something close.
##
## Online, the other players' games repeat each rocket with replay_shot().
## Their copy flies the same way and explodes for show, but does no damage:
## only the copy in the game that fired does.

const PlaceholderSound := preload("res://scripts/placeholder_sound.gd")
## preload() loads the rocket scene once, ready to be copied for every shot.
const ROCKET_SCENE := preload("res://scenes/rocket.tscn")

## Minimum time between rockets, in seconds.
@export var fire_interval := 1.0
## Rocket speed in metres per second.
@export var rocket_speed := 28.0
## SOUND HOOK: drag a .wav or .ogg file here in the Inspector to use your own
## launch sound. If left empty, a burst of noise is generated as a stand-in.
@export var shoot_sound: AudioStream

## Counts down to zero; the launcher can fire again when it gets there.
var cooldown := 0.0
## True while the fire button is being held down.
var trigger_held := false

@onready var model: Node3D = $Model
@onready var muzzle_flash: Node3D = $MuzzleFlash
@onready var sound_player: AudioStreamPlayer = $ShootSound


func _ready() -> void:
	if shoot_sound == null:
		shoot_sound = PlaceholderSound.make_noise_burst(0.35)
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
	return "ROCKETS UNLIMITED"


func fire() -> void:
	if cooldown > 0.0:
		return
	cooldown = fire_interval

	_spawn_rocket()
	_play_effects()


func _spawn_rocket() -> void:
	# "owner" is the root of the scene this launcher was placed in: the
	# player, who works out where the rocket starts (the barrel may be
	# poking through a wall) and where the crosshair is pointing.
	var start: Vector3 = owner.get_projectile_start(muzzle_flash.global_position)
	var direction: Vector3 = owner.get_aim_direction(start)
	_launch_rocket(start, direction, true)
	owner.share_shot(self, [start, direction])


func _launch_rocket(start: Vector3, direction: Vector3, hurts: bool) -> void:
	var rocket := ROCKET_SCENE.instantiate()
	rocket.deals_damage = hurts
	rocket.shooter = owner as CollisionObject3D
	# Add the rocket to the level (the player's parent), not to the launcher.
	# Otherwise it would swing around with the camera as you turn.
	owner.get_parent().add_child(rocket)
	rocket.launch(start, direction, rocket_speed)


## Repeats a rocket fired on another computer (see the top of this script).
## Returns the sound for the shooter's body to play.
func replay_shot(shot: Array) -> AudioStream:
	_launch_rocket(shot[0], shot[1], false)
	return shoot_sound


## Muzzle flash, a heavy recoil kick and sound.
func _play_effects() -> void:
	sound_player.play()

	# Shove the tube back and tip it up, then ease it home.
	model.position.z = 0.1
	model.rotation.x = 0.15
	var tween := create_tween().set_parallel()
	tween.tween_property(model, "position:z", 0.0, 0.4)
	tween.tween_property(model, "rotation:x", 0.0, 0.4)

	muzzle_flash.rotation.z = randf() * TAU
	muzzle_flash.visible = true
	await get_tree().create_timer(0.08).timeout
	muzzle_flash.visible = false
