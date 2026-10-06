extends Node3D
## Chunks (and, when something collapses, dust) thrown out where blocks of a
## structure are destroyed (see scripts/structure.gd). It plays once and then
## removes itself.
##
## How far and how fast the chunks fly, how long they last and what the dust
## looks like are all set on the Chunks and Dust nodes in scenes/debris.tscn.

const PlaceholderSound := preload("res://scripts/placeholder_sound.gd")

## SOUND HOOK: drag a .wav or .ogg file here in the Inspector to use your own
## crumbling sound. If left empty, a burst of noise is generated instead.
@export var crumble_sound: AudioStream
## Chunks per destroyed block (up to Max Chunks in all).
@export var chunks_per_block := 3
@export var max_chunks := 160

@onready var chunks: CPUParticles3D = $Chunks
@onready var dust: CPUParticles3D = $Dust
@onready var sound_player: AudioStreamPlayer3D = $Sound


## Throws chunks shaped like "chunk_mesh" from every point listed (positions
## in the level), and dust as well if "dusty" is true.
func burst(points: PackedVector3Array, chunk_mesh: Mesh, dusty: bool) -> void:
	global_position = points[0]
	# The particles are set to start from a list of points (Emission Shape:
	# Points), measured from this node.
	var local_points := PackedVector3Array()
	for point in points:
		local_points.append(point - global_position)

	chunks.mesh = chunk_mesh
	chunks.emission_points = local_points
	chunks.amount = clampi(points.size() * chunks_per_block, 4, max_chunks)
	# restart() starts the one-shot burst from the beginning.
	chunks.restart()
	if dusty:
		dust.emission_points = local_points
		dust.amount = clampi(points.size() * 2, 8, 120)
		dust.restart()

	if crumble_sound == null:
		crumble_sound = PlaceholderSound.make_noise_burst(0.5)
	sound_player.stream = crumble_sound
	sound_player.pitch_scale = randf_range(0.35, 0.6)
	sound_player.play()

	# "false" makes the timer stop while the game is paused.
	await get_tree().create_timer(maxf(chunks.lifetime, dust.lifetime) + 0.5, false).timeout
	queue_free()
