# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A retro first-person shooter (Quake / early Half-Life look) in **Godot 4.7** with GDScript only (standard build, not .NET). No addons, no build step, no test suite, no linter. `README.md` is the user-facing manual (controls, every tunable setting, known limitations) — update it when adding weapons, enemies, scenes, shader settings or controls.

## Commands

The Godot executable is not on PATH. It lives at `C:\Users\jonat\Documents\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe` (the folder is named like an `.exe`). The commands below use the bare name, as the README does. The user often has the editor open on this project, so expect it to reload files changed on disk.

```
# Run the game
Godot_v4.7-stable_win64_console.exe --path .

# Regenerate the placeholder textures after editing the generator
Godot_v4.7-stable_win64_console.exe --headless --path . --script res://scripts/tools/generate_textures.gd

# Parse-check one script without running the game
Godot_v4.7-stable_win64_console.exe --headless --path . --check-only --script res://scripts/player.gd

# Re-import assets (needed after adding/changing files outside the editor)
Godot_v4.7-stable_win64_console.exe --headless --path . --import
```

## Architecture

### Rendering pipeline (`scenes/main.tscn` + `scripts/main.gd`)

`Main` (a `Control`) is the entry scene and owns the low-res look. The entire game — the level **and** the HUD — lives inside `ViewportContainer/GameViewport`, a `SubViewport` sized by `render_size` (default 320x240). `main.gd` scales the container to the window (4:3, letterboxed, nearest-neighbour) and the container carries `shaders/color_quantize.gdshader` as a post-process over the finished frame.

Consequences to keep in mind:

- Anything that must look chunky (new UI, effects) goes inside `GameViewport`, not under `Main` directly.
- Levels are not baked into `main.tscn`. `Main` has an exported `levels: Array[PackedScene]`; `main.gd` instantiates `levels[level_index]` as the first child of `GameViewport` and the `level_next`/`level_previous` actions (F2/F3) swap it. `level_index` is `static` so it survives the `reload_current_scene` on player death. A new level must be added to that array in `main.tscn`. The levels the user named use hyphens (`half-life-level.tscn`, `quake-level.tscn`, `test-map.tscn`, `test-map-2.tscn`); the rest are snake_case.
- Compatibility lights at most 8 omni/spot lights per mesh, and a level's CSG combiner is one mesh. Keep a level to about 6 `OmniLight3D`s (the muzzle flash is another) and lean on ambient light, as `backrooms.tscn` does.
- Mouse look uses `event.screen_relative`, not `relative`, because the viewport is scaled.
- **Pausing**: `scenes/pause_menu.tscn` (inside `GameViewport`, `PROCESS_MODE_ALWAYS`) owns Esc and F1 and sets `get_tree().paused`. `ViewportContainer` is also `PROCESS_MODE_ALWAYS` so it keeps forwarding input into the SubViewport while paused; that is inherited by everything inside it, so `main.gd` sets each loaded level to `PROCESS_MODE_PAUSABLE` and the HUD instance is pausable too. Anything new added directly under `GameViewport` must be made pausable the same way. Paused nodes miss input (e.g. a button release), so per-input state like the machine gun's `trigger_held` is reset on `NOTIFICATION_PAUSED`.
- The renderer is **Compatibility (GL)**. Forward+/Mobile-only features (`Decal`, etc.) are unavailable — bullet holes are textured quads for this reason. No AA, tonemapping, glow or mipmaps; texture import defaults in `project.godot` disable compression and mipmaps.

### Surfaces

Every 3D surface uses a material in `assets/materials/` built on `shaders/retro_surface.gdshader` (vertex snapping, banded lighting, optional affine warping). The shader **generates its own UVs** by box-mapping from world position (`uv_from_world = true`, for level geometry) or object position (for props), so mesh UVs are ignored. Shader uniform defaults are global; materials override per-surface.

On top of the per-material uniforms, the effects are scaled by **shader globals** (`global uniform`, declared in `project.godot` under `[shader_globals]`): `retro_effects` (master switch, also read by `color_quantize.gdshader`), `retro_snap_strength`, `retro_light_band_strength` and `retro_color_quantize`. `pause_menu.gd` keeps the current values in static vars (initialised from `ProjectSettings` in `_static_init`) and pushes them with `RenderingServer.global_shader_parameter_set`; `global_shader_parameter_get` does not work at runtime. A new shader that declares a global needs that global to exist in `project.godot`, or it fails to compile. The editor only reads `project.godot` at startup, so after editing that section on disk the editor needs Project > Reload Current Project (and saving Project Settings from a stale editor would drop the section).

Textures in `assets/textures/` are generated by `scripts/tools/generate_textures.gd` (an `extends SceneTree` tool script with a fixed seed, not part of the game) and committed as PNGs.

### Gameplay conventions

There are no signal buses or base classes, and the only autoload is `LevelLauncher` (`scripts/level_launcher.gd`): when a scene under `levels/` is run directly (F6), it sets `direct_level_path`/`open_direct_level` (statics in `main.gd`) and changes scene to `main.tscn`, so the level gets the viewport, HUD and pause menu. Scripts are wired together by a few duck-typed conventions:

- **Damage**: anything with a `take_damage(amount: int)` method can be hurt. Weapons call it on whatever a ray hits; if the collider lacks it, they spawn a bullet hole instead. Enemies call `player.take_damage()`.
- **Blood**: things that bleed implement `bleed(at, spray_direction, drop_count := 12)`; weapons and explosions call it (if present) just before `take_damage`. Enemies spawn `blood_splash.tscn` tinted by their exported `blood_color`.
- **Surface marks**: bullet holes, grenade scorch marks and blood stains are alpha-scissored quads sharing `surface_mark.gd` (`bullet_hole.tscn`, `blood_stain.tscn`), capped per `kind`. `place(position, normal, size)` returns false and frees the mark if any corner would hang in the air (per-corner raycasts), so callers must not use the node after a failed `place`. `blood_splash.gd` leaves the stains by raycasting from the wound, skipping anything with `take_damage`.
- **Dismemberment** (`enemy.gd`, enabled per scene by `loses_limbs`; on for the zombie): `bleed()` records which limb the wound is on from the hit's height and side in the enemy's local space (`"random"` for a `Vector3.ZERO` blast), and the following `take_damage()` adds the damage to that limb. So weapons must keep calling `bleed` immediately before `take_damage`. When a limb reaches `limb_health` it rolls once against `head_loss_chance`/`leg_loss_chance`/`arm_loss_chance`; a limb that survives the roll goes in `sturdy_limbs` and can never be severed. A severed limb node is reparented into a `gib.tscn` in the level, and the script's limb variable is repointed at an empty stand-in `Node3D` so animation and death tweens keep working.
- **View bob**: `player.gd`'s `_bob_view()` (from `_process`) offsets `Head/Camera3D`'s local position by distance walked; the weapons are camera children so they move with it. It is switched by the static `view_bob` in `pause_menu.gd` (the VIEW BOB row on the Graphics page), which `player.gd` reads through a `preload` of that script.
- **Hurt feedback**: `player.take_damage` sets `hurt_flash` to 1 (it decays in `_process`) and plays `HurtSound`; the HUD polls `hurt_flash` to set the alpha of its full-screen `DamageTint`.
- **Particles** (blood, explosion smoke) are one-shot `CPUParticles3D` with unshaded, particle-billboarded square quads, configured in the `.tscn` rather than in code.
- **Crates** are `crate.tscn` instances (a `CharacterBody3D` in the `"breakable"` group with `take_damage`, origin at the base, falls when unsupported), not CSG boxes. Because they have `take_damage`, shots leave no marks on them and explosions and blood-stain rays treat them like bodies.
- **Hazards**: `damage_zone.gd` on an `Area3D` calls `take_damage` on overlapping bodies every `interval` seconds; the visible lava/slime is a separate unshaded triplanar slab under the level's `Details` node, and the pit is a CSG subtraction placed after the floor slabs.
- **Finding the player**: `player.tscn` is in the `"player"` group; enemies and the HUD use `get_tree().get_first_node_in_group("player")`.- **Weapons** are children of `Head/Camera3D` in `player.tscn` and are listed in the `weapons` array in `player.gd`. The active weapon is the `visible` one — each weapon reads the `shoot` action itself and must ignore it while hidden or while the mouse isn't captured. A weapon must implement `get_hud_text() -> String` (the HUD shows `player.current_weapon.get_hud_text()` every frame; the pixel font only has A–Z, 0–9, space, `>` and `%`). Adding one also needs a `weapon_N` input action in `project.godot`; `player.gd` maps `weapon_N` to list position N-1 and the `weapon_next`/`weapon_previous` (mouse wheel) actions cycle the list. Projectile weapons aim with `owner.get_aim_direction(muzzle_position)` on the player.
- **Weapons use `owner`** (the player, as scene root) to exclude the shooter from raycasts, and `owner.get_parent()` (the level) as the parent for spawned bullets and bullet holes so they don't move with the camera.
- **Two shot models**: the pistol and shotgun (one ray per pellet; `alt_fire` fires two shells) are hitscan from the camera; the machine gun spawns `bullet.tscn`, which is a plain `Node3D` that raycasts across each physics step's travel (not a physics body), aimed from the muzzle at the point under the crosshair. The machine gun has unlimited bullets and an unlimited `alt_fire` (right mouse) grenade launcher; the rocket launcher fires `rocket.tscn` (straight flight, overrides the explosion's `max_damage`/`radius` before adding it to the tree): `grenade.tscn` is swept the same way with gravity and spawns `explosion.tscn`, which damages every node in the `"enemy"`, `"player"` and `"breakable"` groups within its radius that it has a clear ray to (so enemy scenes must stay in the `"enemy"` group).
- `zombie.tscn` is a second model driven by `enemy.gd` (its `limp`/`hunch` exports change the walk), so `enemy.gd`'s node paths (`Model/LegLeft`, `Model/Upper/Head`, ...) must exist in both scenes.
- **Enemies** (`enemy.gd`, `crawler.gd`) are `CharacterBody3D` state machines using an `enum State` and straight-line pursuit with throttled line-of-sight raycasts (no navigation). The first sight check is delayed because CSG collision is built on the first frame. They are animated procedurally, not with `AnimationPlayer`: each model is boxes under pivot `Node3D`s at the joints, `_animate()` (called from `_process`) computes a target pose from the state plus short one-off timers (alert, attack, pain, landing) and eases every joint towards it, and `_die()` hands over to tweens.
- **Death** of the player calls `reload_current_scene`; code holding static or cross-scene state must survive that (see `surface_mark.gd`'s static lists cleaned up in `_exit_tree`).
- **HUD** and pause menu text is drawn by `pixel_text.gd`, a built-in 3x5 font supporting only A–Z, 0–9, space, `>` and `%` (add glyphs to its `GLYPHS` table).
- **Sound**: weapons export a `shoot_sound`; if empty, `placeholder_sound.gd` synthesises a noise burst (it also synthesises the player's grunt). There are no audio files in the repo.

### Levels

`levels/test_level.tscn` is CSG: under `World`, `Carve...` boxes set to Subtraction cut rooms out of `Solid`, then floors/ledges/steps are added back. CSG children apply top to bottom, so carves must stay above pieces added afterwards. Props go under `Props`, enemies under `Enemies`. The player can't step up ledges; stairs rely on an invisible `StairRamp`.

## Code style

- Scripts are written for a reader learning Godot: a `##` doc comment header explaining the idea, `##` on every exported variable, and plain-language comments explaining *why* and what engine calls do. Match this density in new code.
- Gameplay tunables are `@export` variables (edited in the Inspector), not constants.
- Statically typed GDScript throughout (`:=`, typed parameters and return types).
- One script per scene, same base name (`scenes/foo.tscn` ↔ `scripts/foo.gd`).

## Repo notes

- Commit `*.uid` and `*.import` files; `.godot/` is ignored cache.
- `.tscn`/`.tres` files are hand-editable text, but the editor rewrites them on save (e.g. reordering sections in `project.godot`), so expect incidental diffs.
