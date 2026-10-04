extends RefCounted
## Makes stand-in sound effects from code, so the project needs no audio
## files. Weapons use this when no real sound has been assigned to them.
##
## Other scripts load this file with preload() and call the function on it.


## Builds a short burst of fading white noise, which passes for a gunshot.
static func make_noise_burst(duration: float) -> AudioStreamWAV:
	var sample_rate := 11025
	var sample_count := int(sample_rate * duration)
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
