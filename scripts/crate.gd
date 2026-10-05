extends CharacterBody3D
## A wooden crate that can be shot, or blown, to pieces.
##
## It is a CharacterBody3D rather than a plain static block so that it can
## fall: break the bottom crate of a stack and the ones above drop down.
##
## Weapons hurt it the same way they hurt enemies, by calling take_damage().
## Explosions find it through the "breakable" group (see scripts/explosion.gd).

const PlaceholderSound := preload("res://scripts/placeholder_sound.gd")

## How much damage it takes to break. 20 is two pistol shots.
@export var health := 20
## Length of each side, in metres.
@export var size := 1.0
@export var gravity := 20.0
## SOUND HOOK: drag a .wav or .ogg file here in the Inspector to use your own
## splintering sound. If left empty, a burst of noise is generated instead.
@export var break_sound: AudioStream

## True once it has been smashed and is only waiting for the bits to settle.
var broken := false

@onready var mesh_instance: MeshInstance3D = $Mesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var debris: CPUParticles3D = $Debris
@onready var sound_player: AudioStreamPlayer = $BreakSound


func _ready() -> void:
	if break_sound == null:
		break_sound = PlaceholderSound.make_noise_burst(0.25)
	sound_player.stream = break_sound

	# The scene is built as a 1 m crate standing on its origin. For any other
	# size, stretch the picture, make a collision box to match, and throw
	# out more splinters.
	if size != 1.0:
		var centre := Vector3.UP * size / 2.0
		mesh_instance.scale = Vector3.ONE * size
		mesh_instance.position = centre
		var shape := BoxShape3D.new()
		shape.size = Vector3.ONE * size
		collision_shape.shape = shape
		collision_shape.position = centre
		debris.position = centre
		debris.emission_box_extents = Vector3.ONE * size * 0.4
		debris.amount = int(debris.amount * size * size)


func _physics_process(delta: float) -> void:
	# Crates never move sideways; they only drop when nothing holds them up.
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	move_and_slide()


## Called by weapons and explosions when they hit this crate.
func take_damage(amount: int) -> void:
	if broken:
		return
	health -= amount
	if health <= 0:
		_break()


func _break() -> void:
	broken = true
	# Take it off every collision layer so shots and the player pass through
	# where it used to be, and stop it falling.
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)

	mesh_instance.visible = false
	debris.emitting = true
	sound_player.play()

	# Wait for the splinters to finish flying, then remove the crate for good.
	await get_tree().create_timer(debris.lifetime).timeout
	queue_free()  # removes this node from the game
