# Retro FPS

A small retro first-person shooter made with **Godot 4.7** and GDScript,
aiming for the look of Quake and the early Half-Life alpha: chunky low-res
pixels, blocky levels, muddy textures, banded lighting and dark fog.

## How to run

1. Install Godot 4.7 (the standard build, not the .NET one).
2. Open Godot, choose **Import**, and select `project.godot` in this folder.
3. Press **F5**.

From a terminal:

```
Godot_v4.7-stable_win64_console.exe --path .
```

### Controls

| Input | Action |
| --- | --- |
| W A S D | Move |
| Mouse | Look |
| Space | Jump |
| Left mouse button | Shoot (hold for the machine gun) |
| 1 / 2 | Switch to pistol / machine gun |
| Esc | Release the mouse (click the window to grab it again) |
| F1 | Toggle the colour quantization post-process |

If your health reaches 0 the game restarts.

## Project layout

```
project.godot        Project settings (renderer, input map, import defaults)
scenes/              Reusable scenes
  main.tscn            Entry point: low-res viewport + HUD + the level
  player.tscn          First-person player (with the pistol attached)
  pistol.tscn          Hitscan pistol viewmodel
  machine_gun.tscn     Automatic gun that fires bullet.tscn projectiles
  bullet.tscn          One yellow machine gun bullet
  enemy.tscn           Walking enemy that chases and hits you
  crawler.tscn         Small crawling enemy that leaps at your head
  hud.tscn             Health / ammo / crosshair
levels/
  test_level.tscn      The greybox level (CSG)
  test_room.tscn       Small single room, handy for trying shader settings
scripts/             One script per scene, plus:
  pixel_text.gd        Tiny built-in 3x5 pixel font for the HUD
  placeholder_sound.gd Generates stand-in gunshot noise from code
  tools/generate_textures.gd   Generates the placeholder textures
shaders/
  retro_surface.gdshader    Every 3D surface: snapping, banded light, UVs
  color_quantize.gdshader   Post-process: limits the number of colours
assets/
  textures/            64x64 PNG textures
  materials/           One material per texture, all using the retro shader
  retro_environment.tres    Fog, ambient light and background colour
```

## How the low-res look works

The whole game is drawn into a small off-screen screen (a `SubViewport`) and
then stretched up to the window with no smoothing, keeping a 4:3 shape with
black bars. The project uses the **Compatibility** renderer with all
anti-aliasing off, plain SDR output, and no tonemapping, glow or other
post effects.

## Changing the resolution

Open `scripts/main.gd` and edit one line:

```gdscript
@export var render_size := Vector2i(320, 240)   # try Vector2i(640, 480)
```

Or select the `Main` node in `scenes/main.tscn` and change **Render Size** in
the Inspector. On the same node:

- **Integer Scaling**: scale only by whole numbers (2x, 3x...), so every
  pixel is exactly the same size, with thicker black bars.
- **Color Quantize**: whether the colour-reducing effect starts on.

The HUD is anchored to the corners, so it adapts to the new size.

## Changing the shader settings

### Surface shader (`shaders/retro_surface.gdshader`)

Change a default value at the top of the file to affect the whole game, or
open one material in `assets/materials/` and override it there for just that
material.

| Setting | Default | What it does |
| --- | --- | --- |
| `snap_resolution` | `(160, 120)` | Vertex snapping grid. Smaller = more wobble. `(0, 0)` = off. |
| `affine_amount` | `0.0` | `1.0` = PS1-style warping textures. `0.0` = correct perspective, as in Quake. |
| `light_bands` | `6` | Brightness steps per light. `0` = smooth lighting. |
| `texture_size_meters` | `2.0` | How many metres one copy of the texture covers. |
| `uv_from_world` | `true` | Lay textures out by world position (walls) or by object (crates, props). |
| `tint` | white | Multiplies the texture colour. |

### Colour quantization (`shaders/color_quantize.gdshader`)

| Setting | Default | What it does |
| --- | --- | --- |
| `color_levels` | `32` | Shades per colour channel. Try `16` or `8` for harsher banding. |
| `enabled` | on | Controlled by **Color Quantize** on the `Main` node, and F1 in game. |

### Fog and ambient light (`assets/retro_environment.tres`)

Double-click the file in Godot and edit it in the Inspector:

- **Fog > Light Color**: the fog colour. Keep **Background > Color** the same
  so distant walls fade into the sky.
- **Fog > Depth Begin / Depth End**: where fog starts and where it is solid.
- **Ambient Light > Color**: how bright unlit areas are.

## Using your own textures

The placeholder textures are plain PNG files in `assets/textures/`
(`concrete`, `metal`, `tile`, `crate`). Overwrite them with your own pixel art
using the same file names and every surface updates. Any power-of-two size
works (64x64 or 128x128 suit the look).

To add a new texture: drop the PNG into `assets/textures/`, duplicate one of
the `.tres` files in `assets/materials/`, and drag your texture onto
**Albedo Texture**. New textures are imported without compression or mipmaps
(set under `[importer_defaults]` in `project.godot`) so pixels stay sharp.

To regenerate the placeholders after editing the generator:

```
Godot_v4.7-stable_win64_console.exe --headless --path . --script res://scripts/tools/generate_textures.gd
```

## Tuning gameplay

Select a node and use the Inspector; every value is an exported variable.

- **Player** (`scenes/player.tscn`): speed, acceleration, friction, gravity,
  jump height, air control, mouse sensitivity, health.

  To add another weapon: make its scene, place it under `Head/Camera3D` in
  the player scene, add it to the `weapons` list in `scripts/player.gd`, and
  give it a `weapon_3` input action.
- **Pistol** (`scenes/pistol.tscn`): damage, range, fire interval, ammo, and
  **Shoot Sound** (drag in a `.wav`/`.ogg` to replace the placeholder noise).
- **Machine gun** (`scenes/machine_gun.tscn`): damage per bullet, fire
  interval, ammo, bullet speed, spread, and **Shoot Sound**.
- **Enemy** (`scenes/enemy.tscn`): health, speed, sight range, attack damage.
- **Crawler** (`scenes/crawler.tscn`): health, crawl speed, sight range, leap
  range, leap speed, leap damage, time between leaps.

## Editing the level

`levels/test_level.tscn` is carved out of one solid block. Under the `World`
node, the `Carve...` boxes are set to **Subtraction** and cut rooms out of
`Solid`; floors, the ledge and the steps are then added back. Children are
applied top to bottom, so keep carves above the pieces added afterwards.
Crates live under `Props` and enemies under `Enemies`.

## Known limitations

- Enemies head straight for the player and can get stuck on walls.
- Lights cast no shadows, so a light with a large range shines through walls.
- The player cannot step up ledges; the stairs use an invisible ramp
  (`StairRamp` in the level).
- No mipmaps, so fine texture detail shimmers in the distance (as it did in
  1996).

## Suggested next steps

- **More weapons**: a shotgun (several rays with spread), ammo pickups,
  bullet impact marks, and weapons you find in the level instead of start with.
- **Level tools**: build levels in TrenchBroom and import the `.map` files
  with an addon such as func_godot, instead of CSG.
- **Audio**: real gunshot, footstep and enemy sounds; `AudioStreamPlayer3D`
  for positional sound; ambient loops per room.
- **Enemy AI**: pathfinding with `NavigationRegion3D` / `NavigationAgent3D`,
  a ranged attack, pain and death animations, hit feedback.
- **Save/load**: write player position, health, ammo and dead enemies to a
  file with `FileAccess` or a custom `Resource`.
- **Game flow**: a death screen instead of an instant restart, a menu, health
  pickups, and a level exit.
- **Look**: baked lightmaps (`LightmapGI`) for Quake-style static shadows, a
  sky texture, ordered dithering in the colour quantize shader, and a real
  pixel font and sprite-based weapon.
- **Movement**: proper stair stepping, crouching, and holding jump to
  bunny-hop.
