// Colour quantization post-process.
//
// This is a 2D ("canvas_item") shader. It is applied to the
// SubViewportContainer in scenes/main.tscn, so it runs over the finished
// low-res picture (3D world and HUD together) just before it is shown.
// It limits how many shades each colour channel can have, like an old
// graphics card with a small colour palette.
shader_type canvas_item;

// On/off switch. Toggled from scripts/main.gd (F1 in game).
uniform bool enabled = true;
// Shades per colour channel. 16 gives 16 x 16 x 16 = 4096 possible colours.
// Lower = harsher banding. 256 would be the same as turning it off.
uniform float color_levels : hint_range(2.0, 64.0, 1.0) = 16.0;


void fragment() {
	// TEXTURE is whatever this node draws: here, the low-res game picture.
	vec4 color = texture(TEXTURE, UV);
	if (enabled) {
		float steps = color_levels - 1.0;
		color.rgb = floor(color.rgb * steps + 0.5) / steps;
	}
	COLOR = color;
}
