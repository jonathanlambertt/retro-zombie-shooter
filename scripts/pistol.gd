extends Node3D
## Hitscan pistol.
##
## "Hitscan" means there is no bullet object flying through the world. When
## you fire, the game instantly traces an invisible line (a ray) from the
## centre of the screen and damages the first thing it touches.
##
## This scene is a child of the player's camera, so the gun model stays in
## the corner of the view wherever you look.

const PlaceholderSound := preload("res://scripts/placeholder_sound.gd")
const BULLET_HOLE_SCENE := preload("res://scenes/bullet_hole.tscn")

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
		shoot_sound = PlaceholderSound.make_noise_burst(0.15)
	sound_player.stream = shoot_sound


func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	# A weapon that isn't in the player's hand is hidden, and must not fire.
	if not visible:
		return
	# Only shoot while the mouse is captured. (The click that grabs the mouse
	# again after pressing Esc should not also fire the gun.)
	if event.is_action_pressed("shoot") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		fire()


## The words the HUD shows in the bottom-right corner while this weapon is
## in hand.
func get_hud_text() -> String:
	return "AMMO %d" % ammo


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
	# Things that bleed spray blood from the spot that was hit.
	if hit.collider.has_method("bleed"):
		hit.collider.bleed(hit.position, hit.normal)
	# Anything with a take_damage() function can be hurt: enemies today,
	# maybe explosive barrels tomorrow.
	if hit.collider.has_method("take_damage"):
		hit.collider.take_damage(damage)
	else:
		# Walls, floors and crates get a bullet hole. It is added to the
		# level (the player's parent) so it stays put on the wall.
		var hole := BULLET_HOLE_SCENE.instantiate()
		owner.get_parent().add_child(hole)
		hole.place(hit.position, hit.normal)


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
