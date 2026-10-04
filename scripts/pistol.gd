extends Node3D
## Hitscan pistol.
##
## "Hitscan" means there is no bullet object flying through the world. When
## you fire, the game instantly traces an invisible line (a ray) from the
## centre of the screen and damages the first thing it touches.
##
## This scene is a child of the player's camera, so the gun model stays in
## the corner of the view wherever you look.

@export var damage := 10
## How far the shot reaches, in metres.
@export var max_range := 100.0
## Minimum time between shots, in seconds.
@export var fire_interval := 0.25
@export var ammo := 50
## SOUND HOOK: drag a .wav or .ogg file here in the Inspector to use your own
## gunshot. If left empty, a short burst of noise is generated as a stand-in.
@export var shoot_sound: AudioStream

## Counts down to zero; the gun can fire again when it gets there.
var cooldown := 0.0

@onready var model: Node3D = $Model
@onready var muzzle_flash: Node3D = $MuzzleFlash
@onready var sound_player: AudioStreamPlayer = $ShootSound


func _ready() -> void:
	if shoot_sound == null:
		shoot_sound = _make_placeholder_sound()
	sound_player.stream = shoot_sound


func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	# Only shoot while the mouse is captured. (The click that grabs the mouse
	# again after pressing Esc should not also fire the gun.)
	if event.is_action_pressed("shoot") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		fire()


func fire() -> void:
	if cooldown > 0.0 or ammo <= 0:
		return
	cooldown = fire_interval
	ammo -= 1

	_trace_shot()
	_play_effects()


## Traces the ray and damages whatever it hits.
func _trace_shot() -> void:
	var camera := get_viewport().get_camera_3d()
	var from := camera.global_position
	# A camera looks along its own negative Z axis.
	var to := from - camera.global_transform.basis.z * max_range

	var query := PhysicsRayQueryParameters3D.create(from, to)
	# "owner" is the root of the scene this pistol was placed in: the player.
	# Exclude it so we can never shoot ourselves.
	if owner is CollisionObject3D:
		query.exclude = [owner.get_rid()]

	# The result is an empty Dictionary if nothing was hit.
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	# Anything with a take_damage() function can be hurt: enemies today,
	# maybe explosive barrels tomorrow.
	if hit.collider.has_method("take_damage"):
		hit.collider.take_damage(damage)


## Muzzle flash, recoil kick and sound.
func _play_effects() -> void:
	sound_player.play()

	# Kick the model back, then ease it home. A Tween animates a property
	# over time without needing any code in _process.
	model.position.z = 0.04
	create_tween().tween_property(model, "position:z", 0.0, 0.12)

	# Show the flash (a bright shape plus a light) for a split second.
	muzzle_flash.rotation.z = randf() * TAU
	muzzle_flash.visible = true
	await get_tree().create_timer(0.05).timeout
	muzzle_flash.visible = false


## Builds a short burst of fading white noise to stand in for a gunshot.
func _make_placeholder_sound() -> AudioStreamWAV:
	var sample_rate := 11025
	var sample_count := int(sample_rate * 0.15)
	var data := PackedByteArray()
	for i in sample_count:
		var fade := 1.0 - float(i) / sample_count
		var sample := randf_range(-1.0, 1.0) * fade * fade
		# 8-bit audio stores each sample as one signed byte (-128 to 127).
		data.append(int(sample * 127.0) & 0xFF)

	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_8_BITS
	sound.mix_rate = sample_rate
	sound.data = data
	return sound
