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
| Right mouse button | Machine gun: fire a grenade. Shotgun: double shot |
| 1 / 2 / 3 / 4 | Switch to pistol / machine gun / rocket launcher / shotgun |
| Mouse wheel | Next / previous weapon |
| Esc | Pause menu: turn the retro effects down or off, or quit. Esc again resumes |
| F1 | Toggle the colour quantization post-process (also works while paused) |
| F2 / F3 | Next / previous level |

When you are hurt you grunt and the screen flashes red. If your health
reaches 0 the game restarts.

## Project layout

```
project.godot        Project settings (renderer, input map, import defaults)
scenes/              Reusable scenes
  main.tscn            Entry point: low-res viewport + HUD + the level
  player.tscn          First-person player (with the pistol attached)
  pistol.tscn          Hitscan pistol viewmodel
  machine_gun.tscn     Automatic gun that fires bullet.tscn projectiles
  bullet.tscn          One yellow machine gun bullet
  grenade.tscn         Grenade from the machine gun's launcher
  shotgun.tscn         Pump-action shotgun that fires a cluster of pellets
  rocket_launcher.tscn Slow, powerful launcher that fires rocket.tscn
  rocket.tscn          One rocket, with its smoke trail
  explosion.tscn       The blast a grenade makes when it lands
  crate.tscn           Wooden crate that can be shot to pieces
  blood_splash.tscn    Spray of square blood drops when an enemy is hit
  blood_stain.tscn     Stain the blood leaves on walls and floors
  gib.tscn             A limb that has been shot off a zombie
  bullet_hole.tscn     Mark left on walls and floors by shots
  enemy.tscn           Walking enemy that chases and hits you
  crawler.tscn         Small crawling enemy that leaps at your head
  zombie.tscn          Thin, limping enemy (shares scripts/enemy.gd)
  hud.tscn             Health / ammo / crosshair
  pause_menu.tscn      Esc menu: pauses the game, retro effect settings, quit
levels/
  test_level.tscn      The greybox level (CSG)
  backrooms.tscn       Backrooms maze: yellow wallpaper, carpet, ceiling lights
  test_facility.tscn   Half-Life-style research facility: lobby, lab, storage, test chamber
  test_room.tscn       Small single room, handy for trying shader settings
  half-life-level.tscn Office complex full of zombies, with a slime pit
  quake-level.tscn     Brick castle hall with a lava channel and an altar
scripts/             One script per scene, plus:
  pixel_text.gd        Tiny built-in 3x5 pixel font for the HUD and menu
  surface_mark.gd      Shared by bullet holes and blood stains
  placeholder_sound.gd Generates stand-in gunshot noise from code
  damage_zone.gd       Area that hurts whatever stands in it (lava, slime)
  tools/generate_textures.gd   Generates the placeholder textures
shaders/
  retro_surface.gdshader    Every 3D surface: snapping, banded light, UVs
  color_quantize.gdshader   Post-process: limits the number of colours
assets/
  textures/            64x64 PNG textures
  materials/           One material per texture, all using the retro shader
  retro_environment.tres    Fog, ambient light and background colour
  backrooms_environment.tres   The same, tuned yellow for the Backrooms level
  quake_environment.tres       The same, dark and brown for the Quake level
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
the Inspector. On the same node, **Integer Scaling** scales only by whole
numbers (2x, 3x...), so every pixel is exactly the same size, with thicker
black bars.

The HUD is anchored to the corners, so it adapts to the new size.

## Changing the shader settings

### Turning the effects down (pause menu)

Press **Esc** while playing to pause the game and open the menu:

| Line | What it does |
| --- | --- |
| Retro Effects | Master switch. `OFF` turns off every effect below (and affine warping) without forgetting their settings. |
| Vertex Snap | How strong the vertex snapping is: the jittery "wobble" as you move. `100%`, `75%`, `50%`, `25%` or `OFF`. |
| Light Bands | How strong the banded lighting is. Lower = more, subtler bands. `OFF` = smooth lighting. |
| Color Quantize | The colour-reducing post-process (the same switch as F1). |

Up/down (or W/S) choose a line, left/right (or A/D) turn it down or up.
Enter or a click steps it down, and from `OFF` back round to `100%`. The
settings are kept when you die, but not when you quit.

`100%` means "exactly as set in the shader and the materials" (the
`snap_resolution` and `light_bands` values below); `50%` makes the snapping
jumps half as big, or the light bands twice as many.

These four switches are **shader globals**: values shared by every shader
in the project, found under **Project Settings > Globals > Shader Globals**
as `retro_effects`, `retro_snap_strength`, `retro_light_band_strength` and
`retro_color_quantize`. The game starts with the values set there. The editor
draws with them too, so setting `retro_snap_strength` to `0` there also stops
the wobble while you work in the 3D editor.

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
| `retro_color_quantize` | on | Shader global (see above): starts as set in Project Settings, F1 or the pause menu in game. |

### Fog and ambient light (`assets/retro_environment.tres`)

Double-click the file in Godot and edit it in the Inspector:

- **Fog > Light Color**: the fog colour. Keep **Background > Color** the same
  so distant walls fade into the sky.
- **Fog > Depth Begin / Depth End**: where fog starts and where it is solid.
- **Ambient Light > Color**: how bright unlit areas are.

## Using your own textures

The placeholder textures are plain PNG files in `assets/textures/`
(`concrete`, `metal`, `tile`, `crate`, plus `wallpaper`, `carpet` and
`ceiling_tile` for the Backrooms level, and `lab_wall` and `hazard` for the
facility level). Overwrite them with your own pixel art
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
  jump height, air control, mouse sensitivity, health, **Hurt Sound** (the
  grunt) and **Hurt Fade Speed** (how fast the red flash clears). How red
  the flash gets is **Damage Tint Strength** on the `HUD` node in
  `scenes/hud.tscn`.

  To add another weapon: make its scene, place it under `Head/Camera3D` in
  the player scene, add it to the `weapons` list in `scripts/player.gd`, and
  give it a `weapon_5` input action (Project > Project Settings > Input Map).
  The mouse wheel picks it up automatically. Its script needs a `get_hud_text()`
  function, which returns the words shown in the bottom-right corner.
- **Pistol** (`scenes/pistol.tscn`): damage, range, fire interval, ammo, and
  **Shoot Sound** (drag in a `.wav`/`.ogg` to replace the placeholder noise).
- **Machine gun** (`scenes/machine_gun.tscn`): damage per bullet, fire
  interval, bullet speed, spread, and **Shoot Sound**. Its bullets and
  grenades never run out. Under **Grenades**: time between them, launch
  speed, how far above the crosshair they are lobbed, and **Grenade Sound**.
- **Shotgun** (`scenes/shotgun.tscn`): pellets per shell, damage per pellet,
  spread, range, time between shots, time after a double shot, and
  **Shoot Sound**. It never runs out of shells.
- **Crate** (`scenes/crate.tscn`): health (20 = two pistol shots) and size.
  Its `Debris` node is the splinters. To add one to a level, drag
  `scenes/crate.tscn` into the level; set **Size** on it for a bigger one.
- **Lava and slime** (the `Hazards` node in a level): damage per bite and
  seconds between bites.
- **Rocket launcher** (`scenes/rocket_launcher.tscn`): time between rockets,
  rocket speed and **Shoot Sound**. **Rocket** (`scenes/rocket.tscn`): blast
  damage, blast radius and fuse time; its `Trail` node is the smoke.
- **Grenade** (`scenes/grenade.tscn`): gravity and fuse time.
  **Explosion** (`scenes/explosion.tscn`): damage, blast radius and
  **Explosion Sound**. A blast hurts you too if you stand too close. Its
  `Smoke` node is the cloud of grey and black specks: change **Amount**,
  **Lifetime**, the velocities or the colours under **Color Initial Ramp**.
- **Blood** (`scenes/blood_splash.tscn`): how fast, how far and how long the
  drops fly. Each enemy has its own **Blood Color** (red for the enemy,
  yellow-green for the crawler). Also here: **Stain Range** (how far blood
  can fly and still leave a stain), **Drops Per Stain** (lower = more
  stains) and **Stain Darkness**.
- **Bullet holes and blood stains** (`scenes/bullet_hole.tscn`,
  `scenes/blood_stain.tscn`): **Max Marks** is how many of each can exist
  before the oldest is removed (64 holes, 96 stains).
- **Sound volume**: every sound is an `AudioStreamPlayer` node in its scene
  (`ShootSound`, `GrenadeSound`, the explosion's `Sound`). Lower its
  **Volume dB** to make it quieter; each -6 roughly halves the loudness.
- **Enemy** (`scenes/enemy.tscn`): health, speed, sight range, attack damage,
  and step speed (how fast its legs swing).
- **Zombie** (`scenes/zombie.tscn`): the same settings as the enemy, plus
  **Limp** (0 = walks normally, 1 = drags a leg and lurches) and **Hunch**
  (how far it stoops). Turn those up on the ordinary enemy and it limps too.
  Under **Dismemberment**: **Loses Limbs** (on for the zombie), **Limb
  Health** (damage a limb takes before it comes off; 12 is two pistol
  shots) and **Crawl Speed Factor**. Shooting off the head kills it, each
  lost arm halves its attack, and losing a leg makes it crawl. Grenades and
  rockets take off a random limb.
- **Crawler** (`scenes/crawler.tscn`): health, crawl speed, sight range, leap
  range, leap speed, leap damage, time between leaps, crouch time (the
  wind-up before a leap) and step speed.

The enemies' animations (walking, attacking, flinching, dying...) are not made
in Godot's animation editor. They are a few lines of maths in the `_animate`
function of `scripts/enemy.gd` and `scripts/crawler.gd`, which is where to
change how far or how fast a limb moves.

## Editing the level

`levels/test_level.tscn` is carved out of one solid block. Under the `World`
node, the `Carve...` boxes are set to **Subtraction** and cut rooms out of
`Solid`; floors, the ledge and the steps are then added back. Children are
applied top to bottom, so keep carves above the pieces added afterwards.
Crates live under `Props` and enemies under `Enemies`.

## Choosing which level to play

Press **F2** in the game for the next level and **F3** for the previous one.
If you die, you restart in the level you were playing.

The levels are listed on the `Main` node in `scenes/main.tscn`, under
**Levels** in the Inspector. The game starts in the first one on the list
(currently `levels/half-life-level.tscn`), so drag a different level to the
top to start there instead. A new level has to be added to this list before
F2 will reach it.

### The Half-Life level

`levels/half-life-level.tscn` is a security checkpoint, a long hallway with
two offices, a loading bay full of crates, and a core room with a pit of
toxic slime crossed by a catwalk. Its only enemies are zombies, sixteen of
them. Standing in the slime hurts.

### The Quake level

`levels/quake-level.tscn` is a brick start room and corridor leading to a
tall hall. A channel of lava cuts the hall in two, with one stone bridge
across; fall in and it burns until you jump out. Beyond it is an altar on
two steps (jump up them), and there is a crypt and an alcove off the sides.
All three kinds of enemy live here.

### The Backrooms level

`levels/backrooms.tscn` is one 40 x 40 m room cut out of a solid block, with
the `Wall...` boxes under `World` added back to make the maze. Move, resize,
duplicate or delete them freely. The wall colour comes from
`assets/textures/wallpaper.png`.

The glowing panels under `LightPanels` are only pictures of lights. The real
light comes from the bright ambient colour in
`assets/backrooms_environment.tres`, a faint `FaceShading` light that makes
walls facing different ways slightly different shades, and six `PanelLight`
lamps. Keep it to six: this renderer lets at most 8 lamps shine on one
object, and the whole maze is one object.

### The facility test level

`levels/test_facility.tscn` is built the same way as `test_level.tscn`: a
lobby, a corridor, a lab, a storage room and a tall test chamber are carved
out of one block. The glowing lamps, screens and the green sample under
`Details` are only for show; the six lamps under `Lights` do the lighting.

## Known limitations

- Enemies head straight for the player and can get stuck on walls. They
  will also walk straight into lava or slime.
- Shots leave no bullet holes on crates, since the crate may not be there
  for long.
- Lights cast no shadows, so a light with a large range shines through walls.
- The player cannot step up ledges; the stairs use an invisible ramp
  (`StairRamp` in the level).
- Bullet holes, scorch marks and blood stains are flat squares, not true
  decals (Godot's `Decal` node needs the Forward+ or Mobile renderer), so
  they can't wrap around a corner. One that would hang over an edge is not
  shown at all, which means shots very close to an edge leave no mark.
- No mipmaps, so fine texture detail shimmers in the distance (as it did in
  1996).

## Suggested next steps

- **More weapons**: a shotgun (several rays with spread), ammo pickups,
  and weapons you find in the level instead of starting with.
- **Level tools**: build levels in TrenchBroom and import the `.map` files
  with an addon such as func_godot, instead of CSG.
- **Audio**: real gunshot, footstep and enemy sounds; `AudioStreamPlayer3D`
  for positional sound; ambient loops per room.
- **Enemy AI**: pathfinding with `NavigationRegion3D` / `NavigationAgent3D`,
  a ranged attack, pain and death animations, hit feedback.
- **Save/load**: write player position, health, ammo and dead enemies to a
  file with `FileAccess` or a custom `Resource`.
- **Game flow**: a death screen instead of an instant restart, a main menu,
  health pickups, and a level exit.
- **Look**: baked lightmaps (`LightmapGI`) for Quake-style static shadows, a
  sky texture, ordered dithering in the colour quantize shader, and a real
  pixel font and sprite-based weapon.
- **Movement**: proper stair stepping, crouching, and holding jump to
  bunny-hop.
