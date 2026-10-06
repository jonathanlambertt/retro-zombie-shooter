// Retro surface shader: used by every wall, floor, ceiling and prop.
//
// A shader is a small program that runs on the graphics card. This one has
// three parts, which Godot calls at different moments:
//   vertex()   - runs once per corner (vertex) of every triangle
//   fragment() - runs once per pixel the triangle covers
//   light()    - runs once per pixel, per light that touches it
//
// The default values below are shared by every material that uses this
// shader, so changing a default here changes the whole game. A material can
// still override any of them for itself in the Inspector.
//
// On top of that, three "global" settings at the end of the uniforms below
// turn the retro effects down or off for every material at once. The pause
// menu (Esc) changes them while playing.
shader_type spatial;

// No shiny highlights: surfaces in Quake-era games were completely matte.
render_mode specular_disabled;

group_uniforms Texture;
// filter_nearest = no blurring between texels (chunky pixels up close).
// repeat_enable  = the texture tiles forever instead of stretching.
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;
uniform vec3 tint : source_color = vec3(1.0);
// If true, the texture is laid out using world position, so every wall gets
// the same pixel density no matter how big it is and textures line up between
// neighbouring blocks. If false, it uses the object's own space instead, so
// the texture moves and rotates with the object (good for crates and props).
uniform bool uv_from_world = true;
// How many metres one copy of the texture covers.
uniform float texture_size_meters = 2.0;
// If true, skip all of the above and use the UVs stored in the mesh. A
// BoxMesh's UVs give each of its six sides its own piece of the texture, so
// a head can have a face on the front and hair on the back (see the zombie
// textures in scripts/tools/generate_textures.gd).
uniform bool uv_from_mesh = false;

group_uniforms Retro;
// Vertex snapping grid, in cells across and down the screen. Smaller numbers
// = coarser grid = more wobble. Set to (0, 0) to turn snapping off.
uniform vec2 snap_resolution = vec2(160.0, 120.0);
// 0 = normal perspective-correct textures (what Quake and Half-Life did).
// 1 = fully "affine" textures that swim and warp like a PlayStation 1.
uniform float affine_amount : hint_range(0.0, 1.0) = 0.0;
// Number of brightness steps a light is chopped into. 0 = smooth lighting.
uniform float light_bands : hint_range(0.0, 16.0, 1.0) = 6.0;
group_uniforms;

// Draw in front of everything else. Only for the gun in your hands:
// scripts/player.gd gives it a copy of its material with this switched on,
// so it never disappears into a wall you are standing against.
uniform bool viewmodel = false;

// "global uniform" values don't belong to any one material. They are
// defined once in Project Settings > Globals > Shader Globals (saved in
// project.godot), every shader that declares them reads the same value, and
// scripts/pause_menu.gd changes them with RenderingServer while playing.
// The editor draws with the Project Settings values, so lowering them there
// also calms the wobble in the 3D editor.
//
// Master switch: false turns off snapping, affine warping and light bands.
global uniform bool retro_effects;
// Scales the vertex snapping. 1 = the grid set by snap_resolution,
// 0.5 = jumps half as big, 0 = off.
global uniform float retro_snap_strength;
// Scales the light bands the same way. 0.5 = twice as many (so subtler)
// steps, 0 = smooth lighting.
global uniform float retro_light_band_strength;

// "Varyings" carry values from vertex() to fragment(). The graphics card
// blends them smoothly across each triangle.
varying vec2 surface_uv;
// xy = UV multiplied by depth, z = depth. See the affine note in vertex().
varying vec3 affine_uv;


void vertex() {
	// --- 1. Work out texture coordinates (UVs) from position ---------------
	// "Box mapping": look at which way the surface faces and project the
	// texture straight onto it along that axis.
	vec3 position = VERTEX;
	vec3 facing = abs(NORMAL);
	if (uv_from_world) {
		position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		facing = abs(normalize(MODEL_NORMAL_MATRIX * NORMAL));
	} else {
		// Shift by half a tile so a 1 m box centred on its origin shows
		// exactly one whole texture per face.
		position += vec3(0.5 * texture_size_meters);
	}

	if (facing.y > facing.x && facing.y > facing.z) {
		surface_uv = position.xz;                 // floors and ceilings
	} else if (facing.x > facing.z) {
		surface_uv = vec2(position.z, -position.y); // walls facing east/west
	} else {
		surface_uv = vec2(position.x, -position.y); // walls facing north/south
	}
	surface_uv /= texture_size_meters;
	if (uv_from_mesh) {
		surface_uv = UV;
	}

	// --- 2. Vertex snapping -------------------------------------------------
	// Project the vertex to "clip space" ourselves. After dividing by w, x and
	// y run from -1 to +1 across the screen.
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	float snap_strength = retro_effects ? retro_snap_strength : 0.0;
	if (snap_resolution.x > 0.0 && snap_resolution.y > 0.0 && snap_strength > 0.0 && clip_position.w > 0.0) {
		// Dividing by a strength below 1 makes the grid finer, so each jump
		// is smaller. (At 1 the grid is exactly snap_resolution.)
		vec2 grid = snap_resolution / snap_strength * 0.5;
		vec2 screen_position = clip_position.xy / clip_position.w;
		// Round to the nearest grid cell. Old hardware had no sub-pixel
		// precision, which is what made early 3D geometry jitter.
		screen_position = floor(screen_position * grid + 0.5) / grid;
		clip_position.xy = screen_position * clip_position.w;
	}
	if (viewmodel) {
		// Quake's trick for the gun in your hands: lie about its depth. A
		// point "distance" metres in front of the camera is given the depth
		// of a point between 6 and 11 cm away instead (anything closer would
		// be cut off by the camera's near plane at 5 cm). Further parts are
		// still deeper, so the gun's parts hide each other correctly, but
		// it is now "closer" than any wall, so a long barrel poking through
		// the wall in front of you stays visible. Only the depth changes:
		// the gun appears in the same place on screen. (Asking
		// PROJECTION_MATRIX for the depth, instead of writing a number,
		// works whichever way round the renderer stores depth.)
		float distance = -(MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z;
		vec4 fake = PROJECTION_MATRIX * vec4(0.0, 0.0, -(0.06 + 0.05 * distance), 1.0);
		clip_position.z = fake.z / fake.w * clip_position.w;
	}
	// Writing POSITION tells Godot to use our value as the final position.
	POSITION = clip_position;

	// --- 3. Affine texture warping (optional) -------------------------------
	// Godot always blends varyings in a perspective-correct way and has no
	// switch to turn that off. The trick: multiply by depth (w) here and
	// divide by the blended depth in fragment(), which cancels it out.
	affine_uv = vec3(surface_uv * clip_position.w, clip_position.w);
}


void fragment() {
	vec2 warped_uv = affine_uv.xy / affine_uv.z;
	vec2 uv = mix(surface_uv, warped_uv, retro_effects ? affine_amount : 0.0);
	ALBEDO = texture(albedo_texture, uv).rgb * tint;
}


void light() {
	// Simple diffuse lighting: brightest when the surface faces the light.
	// ATTENUATION is how much the light has faded over distance.
	float amount = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	float band_strength = retro_effects ? retro_light_band_strength : 0.0;
	if (light_bands > 0.0 && band_strength > 0.0) {
		// Round the brightness to a few fixed steps to get visible bands.
		// A weaker strength means more steps, which look smoother.
		float bands = light_bands / band_strength;
		amount = floor(amount * bands + 0.5) / bands;
	}
	DIFFUSE_LIGHT += amount * LIGHT_COLOR / PI;
}
