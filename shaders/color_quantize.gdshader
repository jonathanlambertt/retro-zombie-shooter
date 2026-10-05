// Colour quantization post-process.
//
// This is a 2D ("canvas_item") shader. It is applied to the
// SubViewportContainer in scenes/main.tscn, so it runs over the finished
// low-res picture (3D world and HUD together) just before it is shown.
// It limits how many shades each colour channel can have, like an old
// graphics card with a small colour palette.
shader_type canvas_item;

// On/off switches. These are "global" values shared with every shader that
// declares them (see the note in retro_surface.gdshader). Their starting
// values are in Project Settings > Globals > Shader Globals; in game, F1 and
// the pause menu (scripts/pause_menu.gd) change them.
// This effect's own switch:
global uniform bool retro_color_quantize;
// The master switch for all the retro effects:
global uniform bool retro_effects;
// Shades per colour channel. 32 gives 15-bit colour, like a 3dfx Voodoo card.
// Lower = harsher banding (try 16 or 8). 256 would be the same as off.
uniform float color_levels : hint_range(2.0, 64.0, 1.0) = 32.0;


void fragment() {
	// TEXTURE is whatever this node draws: here, the low-res game picture.
	vec4 color = texture(TEXTURE, UV);
	if (retro_effects && retro_color_quantize) {
		float steps = color_levels - 1.0;
		color.rgb = floor(color.rgb * steps + 0.5) / steps;
	}
	COLOR = color;
}
