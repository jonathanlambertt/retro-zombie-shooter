extends RefCounted
## Makes stand-in sound effects from code, so the project needs no audio
## files. Weapons use this when no real sound has been assigned to them.
##
## Other scripts load this file with preload() and call the functions on it.

## How many samples (individual loudness values) make up one second of sound.
## 11025 is low, which gives the crunchy quality of mid-90s game audio.
const SAMPLE_RATE := 11025


## Builds a short burst of fading white noise, which passes for a gunshot.
static func make_noise_burst(duration: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	for i in sample_count:
		var fade := 1.0 - float(i) / sample_count
		samples.append(randf_range(-1.0, 1.0) * fade * fade)
	return _make_sound(samples)


## Builds a short, low "ugh": the sound the player makes when hurt.
##
## A voice is roughly a buzz at one pitch, so this adds together a low hum
## and a quieter one an octave above it, lets the pitch sink (as a grunt
## does), and mixes in a little noise to make it breathy.
static func make_grunt(duration := 0.22) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	# How far through its current wave the hum is, from 0 to 1.
	var phase := 0.0
	for i in sample_count:
		var progress := float(i) / sample_count
		# The pitch falls from 150 to 90 waves per second.
		phase += lerpf(150.0, 90.0, progress) / SAMPLE_RATE
		var sample := 0.6 * sin(phase * TAU) + 0.25 * sin(phase * TAU * 2.0)
		sample += randf_range(-0.12, 0.12)
		# Swell up quickly at the start, then die away.
		var loudness := minf(progress * 10.0, 1.0) * (1.0 - progress)
		samples.append(sample * loudness)
	return _make_sound(samples)


## Packs a list of samples (each from -1.0 to 1.0) into a playable sound.
static func _make_sound(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	for sample in samples:
		# 8-bit audio stores each sample as one signed byte (-128 to 127).
		data.append(int(clampf(sample, -1.0, 1.0) * 127.0) & 0xFF)

	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_8_BITS
	sound.mix_rate = SAMPLE_RATE
	sound.data = data
	return sound
