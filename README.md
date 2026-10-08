# Retro FPS

A small retro first-person shooter made with **Godot 4.7** and GDScript,
aiming for the look of Quake and the early Half-Life alpha: chunky low-res
pixels, blocky levels, muddy textures, banded lighting and dark fog. The
test room is built from half-metre blocks, and explosions tear it apart:
blast holes in walls and floors, knock out pillars and watch what they held
up come down.

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
| Ctrl or C | Crouch (hold). Crouch in mid-air to pull your legs up and reach higher ledges |
| Left mouse button | Shoot (hold for the machine gun and the MP40) |
| Right mouse button | Machine gun and MP40: fire a grenade. Shotgun: double shot |
| 1 / 2 / 3 / 4 / 5 | Switch to pistol / machine gun / rocket launcher / shotgun / MP40 |
| Mouse wheel | Next / previous weapon |
| E | Read a notebook you are standing at and looking at (E or Esc closes it) |
| A / D, left / right arrow, mouse wheel | While reading: turn back / on a page |
| Esc | Pause menu: resume, graphics and audio settings, multiplayer, or quit. Esc again resumes |
| F1 | Toggle the colour quantization post-process (also works while paused) |
| F2 / F3 | Next / previous level (in multiplayer, only the host) |
| F4 | Change view: first person, behind your player, in front looking at your face, and back |

Crouching makes you shorter (1.2 m instead of 1.8 m) and slower. Let go and
you stand up again as soon as there is room above you. Crouching in the air
works like Half-Life's "crouch-jump": instead of lowering your view, it tucks
your legs up, so a jump plus crouch gets you onto ledges a plain jump can't.

When you are hurt you grunt and the screen flashes red. If your health
reaches 0 the game restarts.

Red **explosive pylons** with a blinking lamp stand around every level,
usually next to a group of enemies. Two pistol shots (or a nearby blast) light
the fuse; it hisses and shakes for a moment and then explodes, killing
anything close by, smashing crates and setting off any other pylon within
about 4 metres. It hurts you too, so shoot it from a distance.

## Project layout

```
project.godot        Project settings (renderer, input map, import defaults)
scenes/              Reusable scenes
  main.tscn            Entry point: low-res viewport + HUD + the level
  player.tscn          First-person player (with the guns attached)
  player_model_soldier.tscn  The player's body, as other players see it: a special forces soldier
  player_model.tscn    The earlier body, an armoured hazard suit (kept, not in use)
  pistol.tscn          Hitscan pistol viewmodel
  machine_gun.tscn     Automatic gun that fires bullet.tscn projectiles
  mp40.tscn            The machine gun again, modelled and textured as an MP40
  bullet.tscn          One yellow machine gun bullet
  grenade.tscn         Grenade from the machine gun's launcher
  shotgun.tscn         Pump-action shotgun that fires a cluster of pellets
  rocket_launcher.tscn Slow, powerful launcher that fires rocket.tscn
  rocket.tscn          One rocket, with its smoke trail
  explosion.tscn       The blast a grenade makes when it lands
  debris.tscn          Chunks and dust thrown out when blocks are destroyed
  crate.tscn           Wooden crate that can be shot to pieces
  explosive_pylon.tscn Red canister that explodes when shot
  blood_splash.tscn    Spray of square blood drops when an enemy is hit
  blood_stain.tscn     Stain the blood leaves on walls and floors
  gib.tscn             A limb shot off a zombie, or a piece of a smashed plant pot
  bullet_hole.tscn     Mark left on walls and floors by shots
  zombie.tscn          Thin, limping enemy that chases and hits you (scripts/enemy.gd)
  zombie_textured.tscn The same zombie with a painted face, lab coat and trousers
  zombie_window.tscn   A window that zombies climb in through
  zombie_rounds.tscn   Sends zombies into a level a round at a time
  notebook.tscn        A notebook on a desk that you can read
  notebook_closed.tscn A shut notebook, only for show
  notebook_reader.tscn The paper page a notebook opens, and its "press E" prompt
  poster.tscn          A poster, sign or whiteboard to hang on a wall
  bookshelf.tscn       Bookshelf full of books and binders
  server_rack.tscn     Rack of servers with status lights
  filing_cabinet.tscn  Four-drawer filing cabinet
  potted_plant.tscn    Small tree in a clay pot that can be shot to bits
  office_chair.tscn    Swivel chair
  specimen_tank.tscn   Glowing tank from the experimentation lab, intact or smashed
  desk.tscn            Office desk: wood-effect top, steel frame, a pedestal of drawers
  monitor.tscn         Beige computer monitor with a glowing screen
  keyboard.tscn        Computer keyboard
  macintosh.tscn       A 1984 Macintosh with its keyboard and mouse
  control_console.tscn Control desk: cupboards, sloping instrument panels, buttons
  cup.tscn             Cup of coffee
  pencil_cup.tscn      Pot of pencils and pens
  water_cooler.tscn    Water cooler with its bottle
  breakable_glass.tscn A window pane that cracks when shot and shatters
  hud.tscn             Health / ammo / crosshair, and the round in a level that has rounds
  pause_menu.tscn      Esc menu: pauses the game, graphics and audio settings, multiplayer, quit
levels/
  test_facility.tscn   Half-Life-style research facility: lobby, lab, storage, test chamber
  half-life-level.tscn Office complex full of zombies, with a slime pit
  test-map.tscn        Bigger facility built for zombie waves: a hub with four wings
  test-map-2.tscn      Bigger again: two-storey atrium, warehouse, cramped tunnels
  office.tscn          One office break room, testing a window that zombies climb through
  start-level-demo.tscn Test map 2's control room and labs, copied out on their own
  multiplayer-map-demo.tscn An arena for one player or several, with zombies in rounds
  test_room.tscn       Two-storey block-built building for testing destruction
scripts/             One script per scene, plus:
  level_launcher.gd    Autoload: runs a level started on its own inside main.tscn
  network.gd           Autoload: multiplayer (hosting, joining, sharing the game)
  structure.gd         The destructible part of a level (on its Structure GridMap)
  blocks.gd            The list of block types: name, material, toughness, span
  pixel_text.gd        Tiny built-in 3x5 pixel font for the HUD and menu
  surface_mark.gd      Shared by bullet holes and blood stains
  placeholder_sound.gd Generates stand-in gunshot noise from code
  damage_zone.gd       Area that hurts whatever stands in it (lava, slime)
  tools/generate_textures.gd   Generates the placeholder textures
  tools/generate_blocks.gd     Builds assets/blocks.tres from scripts/blocks.gd
  tools/build_test_room.gd     Builds levels/test_room.tscn
shaders/
  retro_surface.gdshader    Every 3D surface: snapping, banded light, UVs
  color_quantize.gdshader   Post-process: limits the number of colours
assets/
  textures/            64x64 PNG textures, plus one per part of the zombie, soldier, guns and projectiles
  materials/           One material per texture, all using the retro shader
  blocks.tres          The block palette destructible levels are painted with (a MeshLibrary)
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
#@export var render_size := Vector2i(320, 240)
@export var render_size := Vector2i(640, 480)
```

The game was made at 320 x 240 and is set to 640 x 480 for now, for a
sharper picture. The line for 320 x 240 is still there, switched off with
a `#`: to go back, move the `#` to the other line.

Or select the `Main` node in `scenes/main.tscn` and change **Render Size** in
the Inspector. On the same node, **Integer Scaling** scales only by whole
numbers (2x, 3x...), so every pixel is exactly the same size, with thicker
black bars.

The HUD, the pause menu and the notebook's page are the same size on
screen whatever you choose. They are laid out for a picture 240 pixels tall
(320 x 240) and `main.gd` stretches them to fit the real one
(`_scale_interface()`), so at 640 x 480 each of their pixels is drawn 2 x 2
and they keep their chunky look while the level gets sharper. Only the
level is drawn at the full size. Whole multiples of 320 x 240 (640 x 480,
960 x 720) keep the interface's pixels all the same size; in between
(480 x 360) some come out a pixel wider than others.

Keep to the 4:3 shape if you can. At another shape (640 x 360, say) nothing
is squashed and the HUD still sits in the corners, but the notebook's page
has fixed places for a picture 320 wide and ends up left of the middle.

## Changing the shader settings

### Turning the effects down (pause menu)

Press **Esc** while playing to pause the game and open the menu, which has
five lines: **Resume**, **Graphics**, **Audio**, **Multiplayer** (see "Multiplayer"
below) and **Quit**. Graphics opens a second page (Back or Esc returns from
it):

| Line | Starts as | What it does |
| --- | --- | --- |
| Retro Effects | `ON` | Master switch. `OFF` turns off every effect below (and affine warping) without forgetting their settings. |
| Vertex Snap | `25%` | How strong the vertex snapping is: the jittery "wobble" as you move. `100%`, `75%`, `50%`, `25%` or `OFF`. |
| Light Bands | `OFF` | How strong the banded lighting is. Lower = more, subtler bands. `OFF` = smooth lighting. |
| Color Quantize | `ON` | The colour-reducing post-process (the same switch as F1). |
| View Bob | `ON` | The slight rise, fall and sway of the camera as you walk, and the swing of the gun in your hands. Not one of the retro effects, so the master switch leaves it alone. |
| Fullscreen | `OFF` | Fills the whole screen (still 4:3 with black bars) instead of running in a window. Greyed out when the game runs inside the editor's Game tab: untick **Embed Game on Next Play** in that tab's menu to use it. |

Audio opens a page with one setting, **Master Volume**: how loud everything
is, from `100%` down to `OFF` in steps of 10%.

Up/down (or W/S) choose a line, left/right (or A/D) turn it down or up.
Enter or a click steps it down, and from `OFF` back round to `100%`. The
settings are kept when you die, but not when you quit.

`100%` means "exactly as set in the shader and the materials" (the
`snap_resolution` and `light_bands` values below); `50%` makes the snapping
jumps half as big, or the light bands twice as many.

The first four switches are **shader globals**: values shared by every shader
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
| `uv_from_mesh` | `false` | Use the mesh's own UVs instead, so each side of a box gets its own part of the texture (the textured zombie). |
| `tint` | white | Multiplies the texture colour. |
| `viewmodel` | `false` | Draws in front of everything else. Leave it off: the player script switches it on for the guns in your hands (see below). |

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
(`concrete`, `metal`, `tile`, `crate`, `carpet`, `ceiling_tile`, `lab_wall`
and `hazard` for the levels, `rubble` for the heaps a collapse leaves,
`wallpaper`, `brick` and `lava` which no level uses at the moment, `pylon`
for the explosive pylon, and `armor` and `suit`
for the armoured player model, the `soldier_*` textures for the soldier
player model, and `bookshelf`, `server_rack`, `filing_cabinet`, `leaves`,
`terracotta`, the `poster_*` pictures, `whiteboard`, `whiteboard_flowchart`
and the `sign_*` plates for the lab props, `control_console` and the three
`control_console_*` panels for the control console, `fire_extinguisher` and
`fire_extinguisher_valve` for the fire extinguisher, `desk_top`, `desk_steel` and `desk_drawers` for the desks,
`monitor`, `monitor_base`, the `monitor_screen_*` pictures and `keyboard` for
the computers, `macintosh`, `macintosh_foot`, `macintosh_screen`,
`macintosh_keyboard` and `macintosh_mouse` for the Macintosh,
`cup` and `cup_handle` for the coffee cup, `water_cooler` and
`water_bottle` for the water cooler, `poster_chart_printout` for the paper
taped above the infection rate poster,
`notebook_page` for the notebook's open pages,
and `glass_crack`, `glass_edge` and `glass_edge_2` to `glass_edge_4` for breakable glass). Overwrite them with your own pixel art
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
  grunt) and **Hurt Fade Speed** (how fast the red flash clears). Under
  **View Bob**: **Height** and **Sway** (how far the camera moves, in
  metres), **Steps Per Meter**, **Fade Speed**, and **Weapon Bob Sway**
  and **Weapon Bob Drop** (how far the gun in your hands swings and dips
  on top of that; 0 keeps it still on screen). How red
  the flash gets is **Damage Tint Strength** on the `HUD` node in
  `scenes/hud.tscn`.

  Under **Crouch**: **Crouch Height** (the collision capsule's height while
  crouched; standing it is 1.8), **Crouch Speed** and **Crouch Transition
  Speed** (how fast the view sinks and rises).

  Under **Weapons**: **Starting Weapon**, the gun in your hands when a level
  starts (the pistol, unless changed). Every level has a `Player` node of
  its own, so select that node in a level to change it for that level only,
  as `levels/start-level-demo.tscn` does (machine gun); changing it in
  `scenes/player.tscn` changes it for every level that hasn't set its own.
  It works the same in multiplayer: everyone starts a level with the weapon
  its `Player` node says.

  To add another weapon: make its scene, place it under `Head/Camera3D` in
  the player scene, add it to the `weapons` list in `scripts/player.gd` (and
  its name, in the same place, to the list of names on the `starting_weapon`
  line near the top of that script), and
  give it a `weapon_5` input action (Project > Project Settings > Input Map).
  The mouse wheel picks it up automatically. Its script needs a `get_hud_text()`
  function, which returns the words shown in the bottom-right corner. If it
  fires projectiles, start them at `owner.get_projectile_start(muzzle)` rather
  than at the muzzle itself (see "The gun in your hands" below). For the
  player model to hold it, also add a gun model to `scenes/player_model_soldier.tscn`
  (see below).
- **Player model** (`scenes/player_model_soldier.tscn`): **Armor Color** (the
  armbands and the panel on the backpack; a multiplayer game gives each
  player their own) and **Visor Color** (the lens of the night-vision
  goggles); both only show when the game runs. **Stride Length** (metres
  per stride: lower = quicker steps), **Crouch Hip Height** and **Lamp
  Blink Interval** (the red lamp on the backpack). **Tinted Material** is
  the material that Armor Color recolours.

  `scenes/player_model.tscn` is the earlier body, an armoured hazard suit,
  with the same settings (its Armor Color paints the armour plates). To go
  back to it, open `scenes/player.tscn`, delete the `Model` node, drag
  `scenes/player_model.tscn` onto `Player` in its place and name it `Model`.
  Both use `scripts/player_model.gd`, so a new gun model has to be added to
  each.

  Each weapon has a gun model under `Hips/Upper/Aim/Guns`, named exactly like
  the weapon's node in the player scene (`Pistol`, `MachineGun`...); the one
  in hand is shown. Each has two `Marker3D` children, `GripRight` and
  `GripLeft`, and the arms bend themselves so the hands land on them: move a
  marker and the hand follows. A weapon with no gun model of its own leaves
  the arms hanging empty.
- **Pistol** (`scenes/pistol.tscn`): damage, range, fire interval, ammo, and
  **Shoot Sound** (drag in a `.wav`/`.ogg` to replace the placeholder noise).
- **Machine gun** (`scenes/machine_gun.tscn`): damage per bullet, fire
  interval, bullet speed, spread, and **Shoot Sound**. Its bullets and
  grenades never run out. Under **Grenades**: time between them, launch
  speed, how far above the crosshair they are lobbed, and **Grenade Sound**.
  Each of its five boxes has its own texture (`machine_gun_body.png`,
  `_barrel`, `_launcher`, `_magazine` and `_grip` in `assets/textures/`),
  laid out as six small pictures like the textured zombie's, so you can
  paint over them.
- **MP40** (`scenes/mp40.tscn`, key 5): the machine gun again, looking like
  the wartime German submachine gun. It runs the machine gun's script, so
  it has the same settings (with its own values: change one gun and the
  other stays as it was) and the same right-mouse grenades. Its boxes are
  textured by `mp40_body`, `_barrel`, `_rest` (the bar under the barrel),
  `_magazine` and `_grip`; `mp40_stock` is only on the player model's.
- **Gun and projectile textures**: the other guns are textured the same
  way, one PNG per box: `pistol_slide` and `pistol_grip`; `shotgun_receiver`,
  `_barrel`, `_tube`, `_pump`, `_grip` and `_rib` (the sighting rib on top,
  the node called `Stock`); `rocket_launcher_tube`, `_muzzle` and `_sight`
  (its grip uses the machine gun's). `shotgun_stock` and
  `machine_gun_stock` are only on the guns the player model carries. The
  things the guns fire have one each too: `bullet`, `grenade` and `rocket`.
  Those three are drawn without lighting, so they show up in the dark.
- **Shotgun** (`scenes/shotgun.tscn`): pellets per shell, damage per pellet,
  spread, range, time between shots, time after a double shot, and
  **Shoot Sound**. It never runs out of shells.
- **Breakable glass** (`scenes/breakable_glass.tscn`): **Size** (width and
  height, in metres), health (20 = two pistol shots) and **Break Sound**.
  Each hit leaves a bullet hole where it lands, with a few cracks running
  out of it (`glass_crack.png`, turned a different way each time); its
  `Shards` node is the burst of glass when it breaks. What a broken pane
  leaves in its frame is one of four pictures (`glass_edge.png` and
  `glass_edge_2.png` to `glass_edge_4.png`): a sliver all round, shards of
  every size and sometimes a bigger piece in a corner. Panes placed one
  after another in a level each get a different one, so a row of windows
  doesn't break into the same teeth four times.
- **Crate** (`scenes/crate.tscn`): health (20 = two pistol shots) and size.
  Its `Debris` node is the splinters. To add one to a level, drag
  `scenes/crate.tscn` into the level; set **Size** on it for a bigger one.
- **Potted plant** (`scenes/potted_plant.tscn`): health (20 = two pistol
  shots or four machine gun bullets), **Throw Speed**
  (how hard its pieces are flung when it breaks, 3.5 m/s) and **Break
  Sound**. A hit on the tree throws up leaves (the `LeafSpray` node) and a
  hit on the pot throws chips of clay (`PotChips`). When it breaks, the
  stem and the four clumps of leaves (under `Tree`) and five pieces of the
  pot (under `Shards`) fly off as gibs, in a burst of leaves and soil
  (`LeafBurst`, `DirtBurst`). They are the same gibs as a zombie's limbs,
  so they bounce, lie where they land for 20 seconds and count towards the
  same limit of 24. What stays is under `Remains`: the bottom of the pot, a
  heap of soil and the stump. Every potted plant does this, in any level.
- **Explosive pylon** (`scenes/explosive_pylon.tscn`): health (15 = two
  pistol shots), fuse time (the hiss before the bang, which is also the
  delay between pylons in a chain reaction), blast damage (100), blast
  radius (5 m), fireball size, how fast the lamp blinks (it speeds up as
  the pylon is damaged), **Structure Damage** and **Structure Radius** (320
  and 3 m: enough to cut through a pillar) and **Fuse Sound**. Its `Sparks` node is the shower
  from a bullet hit and `Debris` is the scrap metal. To add one to a level,
  drag `scenes/explosive_pylon.tscn` under the level's `Props` node. Two
  pylons closer than about 4 m set each other off; further apart, the blast
  is too weak at that distance.
- **Lava and slime** (the `Hazards` node in a level): damage per bite and
  seconds between bites.
- **Rocket launcher** (`scenes/rocket_launcher.tscn`): time between rockets,
  rocket speed and **Shoot Sound**. **Rocket** (`scenes/rocket.tscn`): blast
  damage, blast radius, **Structure Damage** and **Structure Radius** (how
  hard and how far it smashes walls; see "Destruction" below) and fuse
  time; its `Trail` node is the smoke.
- **Grenade** (`scenes/grenade.tscn`): gravity and fuse time. **Fireball**
  and **Flash** are both off, so a grenade goes off with only smoke and the
  bang: tick them to give it back the orange ball of fire or the orange
  light it throws on the room (rockets and pylons always have both).
  **Explosion** (`scenes/explosion.tscn`): damage, blast radius,
  **Structure Damage** and **Structure Radius** (a grenade's: 180 and
  1.75 m) and **Explosion Sound**. A blast hurts you too if you stand too
  close. Its `Smoke` node is the cloud of grey and black specks: change **Amount**,
  **Lifetime**, the velocities or the colours under **Color Initial Ramp**.
- **Blood** (`scenes/blood_splash.tscn`): how fast, how far and how long the
  drops fly. Each enemy scene has its own **Blood Color** (dark red for the
  zombies). Also here: **Stain Range** (how far blood
  can fly and still leave a stain), **Drops Per Stain** (lower = more
  stains) and **Stain Darkness**.
- **Bullet holes and blood stains** (`scenes/bullet_hole.tscn`,
  `scenes/blood_stain.tscn`): **Max Marks** is how many of each can exist
  before the oldest is removed (64 holes, 96 stains).
- **Sound volume**: every sound is an `AudioStreamPlayer` node in its scene
  (`ShootSound`, `GrenadeSound`, the explosion's `Sound`). Lower its
  **Volume dB** to make it quieter; each -6 roughly halves the loudness.
- **Zombie** (`scenes/zombie.tscn`), the only kind of enemy: health, speed,
  sight range, attack damage, and step speed (how fast its legs swing), plus
  **Limp** (0 = walks normally, 1 = drags a leg and lurches) and **Hunch**
  (how far it stoops).
  Under **Dismemberment**: **Loses Limbs** (on for the zombie), **Limb
  Health** (damage a limb takes before it comes off; 12 is two pistol
  shots), **Head Loss Chance**, **Leg Loss Chance** and **Arm Loss Chance**
  (how often a limb that has taken that much damage really comes off: 35%,
  60% and 75%) and **Crawl Speed Factor**. Shooting off the head kills it,
  each lost arm halves its attack, and losing a leg makes it crawl. A limb
  that holds on can't be shot off afterwards, so a zombie that keeps its
  head has to be killed the ordinary way. Grenades and rockets take off a
  random limb.
- **Textured zombie** (`scenes/zombie_textured.tscn`): a copy of the zombie
  with the same settings, but a texture for each body part instead of one
  flat green: `zombie_head.png`, `zombie_torso.png`, `zombie_arm.png` and
  `zombie_leg.png` in `assets/textures/`. Each is six small pictures in one
  file, one for each side of the box (the layout is drawn at the top of the
  zombie section in `scripts/tools/generate_textures.gd`), so you can paint
  over them in any pixel-art program. Every zombie in the levels is this
  one; the plain green `zombie.tscn` is kept but no level uses it. To add
  one to a level, drag the scene under the level's `Enemies` node.

The enemies' animations (walking, attacking, flinching, dying...) are not made
in Godot's animation editor. They are a few lines of maths in the `_animate`
function of `scripts/enemy.gd`, which is where to
change how far or how fast a limb moves. The player model is animated the same
way, in `scripts/player_model.gd`.

## The player model

You never see your own body in first person (it would only get in the way of
the view). Press **F4** for a camera behind you, and again for one in front
of you looking back at your face; a third press returns to first person. In
multiplayer this is the body the other players see. It is a special forces
soldier in camouflage, with a helmet and night-vision goggles, a vest of
magazine pouches and a backpack with a bedroll and a radio aerial. It is
built from boxes like the enemies, and it is animated from what the player
is doing:

- **Running**: the legs swing and the knees lift, and the body bobs and
  leans into the run. The legs turn to face the way you are moving, so
  strafing and running backwards look right while the gun stays on target.
- **Jumping and landing**: one knee pulled up in the air, and the knees give
  when you land.
- **Crouching**: a low squat, with a waddle when you move.
- **Aiming**: the head, arms and gun follow the mouse up and down, and the
  gun in its hands is the one you are holding.
- **Firing**: the gun kicks back and its muzzle flashes, and other players
  hear the shot from where you stand.

It has no collision of its own, so it never blocks your own shots, and the
third-person cameras never show the first-person gun. Shots always come from
your eyes, whichever view you are using; the crosshair is hidden in the
front view.

### The gun in your hands

The gun in front of the first-person camera (the "viewmodel") sticks out
further than the player's collision capsule, so it used to sink into walls
you stood against. `scripts/player.gd` now gives every gun part under the
camera a copy of its material with the shader's `viewmodel` setting on, which
draws it in front of everything else (Quake did the same). It also puts them
on render layer 2, which the third-person cameras don't show.

For the same reason, a bullet, grenade or rocket fired from a barrel that is
poking through a wall would have started on the far side of the wall. Now it
starts just in front of the wall instead, and hits it.

## Multiplayer

Up to 8 players can play a level together, fighting the same zombies.

**To host**: press Esc, choose **Multiplayer**, then **Host Game**. The level
you are in starts again, shared. The HUD's top corner shows `HOST` and the
number of players.

**To join**: press Esc, choose **Multiplayer**, select the **Join** line and
type the host's IP address (number keys and `.`; Backspace deletes), then
press Enter. Your own level is put away and the host's arrives. **Leave Game**
goes back to single player, as does the host quitting.

**Playing on the same home network** just works: join with the host's local
address, like `192.168.1.20`.

**Playing over the internet**: the host's router has to let UDP port **7777**
through to the host's computer. Hosting asks the router to do that itself
(UPnP), and the Multiplayer page's status line, and the HUD's top corner,
say how it went:

| Status | Meaning |
| --- | --- |
| `PORT OPEN - FRIENDS JOIN 203.0.113.45` | Done. Friends join that address (the host's public IP). |
| `NO UPNP ROUTER - FORWARD UDP PORT 7777` | No router answered. UPnP is probably switched off in the router's settings: turn it on, or forward the port by hand. |
| `ROUTER SAID NO - FORWARD UDP PORT 7777` | The router answered but refused. Forward the port by hand. |
| `BEHIND ISP NAT - TRY TAILSCALE OR ZEROTIER` | Your internet provider shares one address between customers (carrier-grade NAT), so no forwarding on your router can help. |

To forward the port by hand, open the router's settings page (often
`192.168.1.1`), find "port forwarding", and send UDP port 7777 to the host
computer's local address. Friends then join the host's public IP (shown by
any "what is my IP" website).

If neither works, a virtual network such as **Tailscale** or **ZeroTier**
needs no ports at all: everyone installs it and joins the same network, and
friends join the host's address on it (like `100.101.102.103`).

The game closes the port again when you stop hosting or quit. (If it
crashes, the router keeps forwarding the port to a game that isn't running,
which is harmless; restarting the router clears it.)

To try it on one computer, start the game twice from a terminal (`--no-upnp`
leaves the router alone):

```
Godot_v4.7-stable_win64_console.exe --path . -- --host --no-upnp
Godot_v4.7-stable_win64_console.exe --path . -- --join=127.0.0.1
```

How it plays:

- Each player gets their own armour colour: orange for the host, then
  blue, green, red, yellow, purple, white and black.
- The host chooses the level: F2 and F3 only work for the host, and change
  it for everyone. Everyone starts where the level's `Player` node stands.
- Dying respawns you at the start with full health; the game carries on.
- In a level with rounds of zombies (the multiplayer map demo), everyone
  fights the same round, and a round is bigger the more players there are
  when it starts.
- Esc doesn't pause the game online (the others are still playing). It
  only opens the menu and stops your player from moving.
- Players can hurt each other: shots and explosions hit everyone, just as
  your own rockets always hurt you.
- Someone joining a game in progress sees it as it is: dead zombies stay
  dead (with any limbs they lost), and broken crates and exploded pylons
  are gone.

How it works, in short (`scripts/network.gd` explains it in full):

- The host's game runs the world. Enemies only think and move on the host,
  and crates and pylons break and explode there. Everyone else is sent the
  result: each enemy's `Sync` node (a `MultiplayerSynchronizer`) sends its
  position, state, attacks and lost limbs, and the others animate to match.
- Each player's own game moves their player and sends its position, aim,
  crouch and weapon (the `Sync` node in `scenes/player.tscn`).
- Whoever fires works out what the shot hit, and the damage is sent to
  whoever looks after that thing: the host for enemies, crates and pylons,
  the player's own computer for a player. Every other game repeats the shot
  for show, so everyone sees the tracers, holes and explosions.
- The level and the players are made on every computer by two
  `MultiplayerSpawner`s, which also catch up anyone who joins late.
- Rounds of zombies are run by the host. Its `ZombieRounds` node makes each
  zombie through a `MultiplayerSpawner` of its own, so it appears in
  everyone's game, and sends everyone the round and the number left for
  their HUD.

## Destruction

Rockets, grenades and exploding pylons smash the blocks that destructible
levels are built from. For now that is only the test room (the last level);
the CSG levels don't break. Bullets and pellets only leave holes in the
surface.

- **Blasts**: each explosion damages the blocks around it, hardest at the
  centre and fading to nothing at its **Structure Radius**. A block with
  other blocks between it and the blast gets much less, so a blast on one
  side of a wall barely touches the other side, but it does punch through
  whatever it destroys. Damage adds up: a wall that survives one rocket
  breaks under the next. A rocket opens a hole about 2.4 m across in
  concrete.
- **Collapse**: blocks need holding up. A block resting on another is held
  by it, and a block can hold up its neighbours sideways (or one hanging
  underneath it) for a limited distance: its type's **span**, 6 m for
  concrete and 12 m for metal. So a floor between walls stays up, a wide hall
  needs its pillars, and a hole in a wall doesn't bring down the wall above
  it. Whatever is no longer held up falls as one piece, smashes, hurts
  anyone underneath, and leaves a heap of rubble, which can itself be blasted
  away.
- **The shell**: every block-built level has an indestructible outer layer (the
  `Shell` GridMap): its foundation and outer walls. Outer walls are two
  blocks thick, shell outside and ordinary blocks inside, so explosions leave
  craters in them but nobody can blast their way out.

The block types, how tough each one is (**health**: the blast damage it
takes to break) and how far it reaches (**span**, in blocks) are listed in
`scripts/blocks.gd`. On the level's `Structure` node: **Rubble Left** (how
much of a fallen piece stays as rubble), **Crush Damage** (to anything a
falling piece lands on) and **Gravity** (how fast pieces fall).

Online, the host decides what breaks and what falls, and sends the result to
everyone, so every game has exactly the same building, and players who join
later get it as it is. Only the chunks and dust are drawn by each computer
for itself.

## Editing the level

Every level is carved out of one solid block (`levels/test_facility.tscn` is
the simplest to read). Under the `World` node, the `Carve...` boxes are set
to **Subtraction** and cut rooms out of `Solid`; floors, ledges and steps
are then added back. Children are
applied top to bottom, so keep carves above the pieces added afterwards.
Crates live under `Props` and enemies under `Enemies`.

## Building destructible levels

A destructible level is painted from half-metre blocks with Godot's **GridMap** tool,
using the palette in `assets/blocks.tres`. Each level has two GridMaps:

- `Shell` (a plain GridMap): what can never be destroyed. The foundation
  under the floors and the outer skin of the outer walls (and a lid on top,
  unless the roof is meant to be blasted open to the sky).
- `Structure` (with `scripts/structure.gd`, its **Shell** set to the Shell
  node): everything else. Floors, walls, ceilings, pillars, stairs.

Select one, pick a block in the palette at the bottom of the editor, and
paint. Both use cells of 0.5 m. Things to keep in mind:

- A level that has blocks nothing holds up prints a warning when it starts
  (in the Output panel), saying where. Those blocks stay put but hold
  nothing up. Put a wall or a pillar under them, or use metal (which
  reaches twice as far) for wide floors.
- Doors need to be at least 2 blocks wide and 4 tall (1 x 2 m).
- The player can't yet step up a block, so stairs need an invisible ramp
  over them (see `StairRamp` in the test room).
- A lamp can only light 8 "objects", and a GridMap draws in chunks of
  8 x 8 x 8 cells, so several lamps in a level are fine.
- To add a block type: add it to the end of `scripts/blocks.gd` and run
  `scripts/tools/generate_blocks.gd`:

  ```
  Godot_v4.7-stable_win64_console.exe --headless --path . --script res://scripts/tools/generate_blocks.gd
  ```

Props go under `Props`, enemies under `Enemies`, and the level's `Player`
node marks where players start.

## Choosing which level to play

Press **F2** in the game for the next level and **F3** for the previous one.
If you die, you restart in the level you were playing.

The levels are listed on the `Main` node in `scenes/main.tscn`, under
**Levels** in the Inspector. The game starts in the first one on the list
(currently `levels/start-level-demo.tscn`), so drag a different level to the
top to start there instead. A new level has to be added to this list before
F2 will reach it.

You can also open a level in the editor and press **F6** (Run Current Scene).
A level on its own has no HUD, pause menu or low-res picture, so
`scripts/level_launcher.gd` (an autoload, under **Project Settings > Globals >
Autoload**) notices that a scene from `levels/` was started and restarts it
inside `scenes/main.tscn`. This works for a level that isn't on the list yet
too; it is added to the end of the list for that run.

### The start level demo

`levels/start-level-demo.tscn` is the first level, so it is the one the game
starts in. It is four pieces of test map 2 copied out on their own: the
control room, the experimentation lab it looks down into, the lab below the
control room, and the torn-out containment door that joins those two labs.
Everything in those rooms is where it is in test map 2 (see "The control
room and the experimentation lab" below), with the same notebook (but for
one sentence) and eleven of its zombies: six in the experimentation lab and
five in the lab below.

The control room is dressed differently from test map 2's, though, and one
other thing is different. You start with the machine gun
in your hands instead of the pistol: that is **Starting Weapon** on the
level's `Player` node, and the other guns are still on their number keys.
Three of the monitors show a program too small to read. On the left and
middle desks by the window it is green lines on black
(`monitor_screen_listing.png`), instead of the cells' status and subject
7's heart. On the left of the console in front of you it is yellow lines on
blue (`monitor_screen_listing_blue.png`), instead of the alarm. The right
desk still has the abandoned game. And the monitor on the right of the
console, the one with the dead camera on it, is gone. In its place is a
1984 Macintosh (`scenes/macintosh.tscn`, see "Lab props" below) with its
keyboard and its mouse, still showing the smiling face it started up with.
It stands 30 cm nearer the middle of the console than the monitor did, to
keep its mouse clear of the buttons.

The console itself is a proper control desk here
(`scenes/control_console.tscn`), where test map 2 has a plain steel block
with four buttons on it. It has cupboards underneath and three sloping
panels of instruments along the back of its top, with the two computers
standing between them. The left panel has gauges for the power. The middle
one has a lamp for each holding cell: 1 and 2 green and SHUT, 3 red and
OPEN. The right one has a small screen with subject 7's pulse on it, a flat
line. On the flat of the desk are an emergency STOP button, the MAINS
switch, the intercom, and four lit buttons marked VENT, LIFT, LOCK and BELL
for the things the notebook's writer did: sealed the vents, cut the lift,
locked the room.

Two things on the walls are different too. The infection rate poster by
the water cooler has lost the green GREAT JOB TEAM! under its graph
(`poster_chart_plain.tres`; the copy down in the experimentation lab still
has it). And the whiteboard is about computers (`whiteboard_flowchart.tres`):
a flowchart headed DEBUGGING, in which BUG? leads to SHIP IT! if the answer
is no and round through COFFEE if it is yes, beside a tally of twelve cups.
One sentence of the notebook's second page changed to match the poster: it
"still has its hug day note" where in test map 2 it "still says great job
team".

The south wall, behind you as you start, has two more. The fire
extinguisher is painted (`fire_extinguisher.tres` on its cylinder and
`fire_extinguisher_valve.tres` on the valve on top), where test map 2's is
plain red: a label with a flame and the letters A, B and C, a hose down its
side, the strap that holds it to the wall, a rubber foot and a pressure
gauge. And between it and the water cooler hangs a poster that test map 2
has not (`poster_penguin.tres`): a penguin dangling from a branch high
above the clouds, over the words HANG IN THERE!

The left desk also has a second notebook, shut, with a pot of pencils and
pens behind it. That one is only there to be looked at: there is nothing
to read in it, and no prompt appears.

The rest of test map 2 is not there. Where the control room's corridor and
the lower lab's three exits (to the atrium, the warehouse and the tunnels)
used to be, there is plain wall. So the only way down from the control room
is the observation window: shoot out a pane, jump onto the sill and drop
into the lab. From there the hole in the south wall leads into the lab
below, which is a dead end.

It is a copy, not a link: changing one of the two levels does not change
the other.

### The multiplayer map demo

`levels/multiplayer-map-demo.tscn` (the second level, so one press of F2) is
a small arena for one player or several, where the zombies come in
**rounds**. It is one brick hall, 20 x 20 m and 6 m high, with four concrete
pillars and a few crates for cover. In the middle of each wall is a gate: a
dark tunnel with a red lamp, hazard stripes across its floor and a
biohazard sign above it. You start in the middle of the hall, holding the
machine gun.

The top right corner of the screen says what is going on. After a
six-second count (**GET READY**, **ROUND 1 IN 6**) the first round starts:
six zombies, one a second, each dropping out of a shaft in the roof at the
back of one of the tunnels and walking out into the hall after you. The
corner then shows the round and how many zombies are still to be killed
(**ROUND 1**, **6 ZOMBIES LEFT**). Kill the last one and the round is over
(**ROUND 1 CLEAR**, **ROUND 2 IN 6**). Each round has three more zombies
than the one before, and they are 5% faster each time (up to 75% faster,
from round 16 on). There is no last round. In single player, dying starts
the level again from round 1.

A red pylon stands beside each gate, about 3 m from where the zombies come
out: set it off as a group passes and it takes them with it. The pylons and
crates do not come back between rounds. No zombie appears at a gate while
somebody is standing in its tunnel, so a tunnel is a place to make a stand
with your back to the wall: the zombies from the other three gates have to
come in through its mouth.

In a multiplayer game (see "Multiplayer" above) everyone fights the same
rounds, and each round is half as big again for every player after the
first: two players get 9 zombies in round 1, three get 12. Someone who dies
comes back in the middle of the hall and the round carries on. The level
has no notebook.

The rounds are run by the `ZombieRounds` node at the bottom of the level,
and its four `Marker3D` children are the gates: see "Rounds of zombies"
below for its settings, and for adding rounds to another level.

### The Half-Life level

`levels/half-life-level.tscn` (the third level, so two presses of F2) is a
security checkpoint, a long hallway with two offices, a loading bay full of
crates, and a core room with a pit of toxic slime crossed by a catwalk. Its
only enemies are zombies, sixteen of them. Standing in the slime hurts.

### The test map

`levels/test-map.tscn` (the fourth level, so three presses of F2) is a bigger
facility in the style of the Half-Life level, laid out for holding off waves
of zombies. You start in a security checkpoint on the south side, which opens
onto a tall 20 x 20 m hub with four pillars and some crates for cover. The
hub has a wide doorway in each wall: the checkpoint to the south, a loading
bay to the east, a core room with a slime pit to the west, and a long hallway
with two offices to the north. A passage at each end of the hallway leads
down into the bay and the core, so you can run a loop instead of being
cornered.

It has no rounds of zombies yet (see "Rounds of zombies" below; only the
multiplayer map demo has them): the 27 zombies stand at fixed points under the
level's `Enemies` node, named after the room they are in (`ZombieHub1`,
`ZombieBay3`, ...). They only notice you within 14 m and with a clear line of
sight, so they arrive in groups as you move through the level.

### Test map 2

`levels/test-map-2.tscn` (the fifth level, so four presses of F2) is larger
than the test map and mixes open rooms with tight ones. A small checkpoint
opens onto a tall 24 x 24 m atrium. From there:

- **Upstairs**: stairs along the atrium's east wall climb 4 m to an L-shaped
  balcony round the north and west sides. A narrow corridor leads off it to a
  control room above the lab. There are no railings, so you (and the zombies)
  can drop off the balcony.
- **Open**: a door in the east wall leads to a 22 x 36 m warehouse with
  shipping containers, pillars and crates.
- **Tight**: two openings under the west balcony lead into maintenance
  tunnels 1.6 m wide with a 2.4 m ceiling. They pass a small pump room with a
  slime pit and come out in the lab north of the atrium. Another narrow
  passage joins the lab to the warehouse, so every area is on a loop.

Forty zombies stand at fixed points, named after their room as in the test
map. The stairs are steps with an invisible `StairRamp` slope over them,
because the player can't step up a ledge.

**The control room and the experimentation lab.** For now you start upstairs
in the control room (the level's `Player` node), facing three desks and a
long observation window. Its sill is low, so you can step into a gap between
the desks and look straight down into the experimentation lab behind it:
this is where the zombies came from. Five specimen tanks stand along the far
wall under a CONTAINMENT LAB sign. Two still have something floating in
them; the other three are smashed, with glass round their rims and their
liquid across the floor. Three barred holding cells line the west wall, and
cell 3, the one the whiteboard says to keep shut, has been torn open. There
is an operating table with a broken strap, benches of equipment, chemical
drums and a trail of blood leading to the south wall. There, the containment
door has been ripped out into the lab below the control room, which is one
way in (back down to the atrium and through the lab). Six zombies wait in
there, one of them still locked in cell 2. The quicker way in is through the
window: it is four panes of breakable glass, and two pistol shots (or one
from the shotgun, or a grenade) shatter one. Then jump onto the sill and
drop the 4.5 m into the lab. While the glass is whole the zombies down
there can't see you through it, but once a pane is gone they can, and any
that do come and gather under the window.

The control room itself has bookshelves, server racks, filing cabinets, a
plant (which can be shot to bits), chairs, a water cooler and the
whiteboard. Each desk has a monitor
and a keyboard, and so does the console in the middle of the room; every
screen shows something different (the cells' status, subject 7's heart, an
abandoned game, a dead camera and the alarm), one desk has a cup of
coffee, and the middle desk has the room's notebook (see "Notebooks"
below). The one poster left is the infection rate: its line ran out of
graph, so somebody carried it on in marker pen up a printout taped to the
wall, all the way to the ceiling. The room's zombies
moved into the lab when the start moved here; to start in the checkpoint
again, move `Player` back to (0, 0.1, 27).

### The facility test level

`levels/test_facility.tscn` (the sixth level, so five presses of
F2) is a lobby, a corridor, a lab, a storage room and a tall test chamber
carved out of one block, with six zombies in it. The glowing
lamps, screens and the green sample under `Details` are only for show; the
six lamps under `Lights` do the lighting. Keep it to six: this renderer lets
at most 8 lamps shine on one object, and a level's walls are one object.

### The office

`levels/office.tscn` (the seventh level: six presses of F2, or two of F3
from the first level) is a single room: an office break room, built
as a test of a window that zombies climb through. You start facing the
window. Five zombies wait in a brick yard on the other side of that wall;
they come to the window, haul themselves over the sill one at a time and
drop in. There is no way out of the room, so it is a short fight.

### The test room

`levels/test_room.tscn` (the eighth and last level: one press of F3 from the
first level) is a two-storey building, 24 x 16 m. The ground
floor is a hall with six pillars holding up the upper floor, with stairs
behind a lab wall at the east end. Upstairs there are pillars too, and a
partition wall. There is a pylon beside each of the two middle pillars: set
them off and the middle of the upper floor comes down. Five zombies wait on
the two floors.

It is built by `scripts/tools/build_test_room.gd` rather than painted by
hand. Running that again rebuilds it, losing any changes made in the editor:

```
Godot_v4.7-stable_win64_console.exe --headless --path . --script res://scripts/tools/build_test_room.gd
```

### Notebooks

Every level except the multiplayer map demo and the test room has a
notebook lying open on a desk, near
where you start (in the office it is on the table). Stand next to it, look
at it, and **PRESS E TO READ** appears; E opens it at a page of a diary,
and E or Esc closes it again. The page is ruled paper bound into a book,
with the notebook's name small in one top corner, the day the entry was
written large and underlined in the other, and the entry below in the
same blue ink. Reading pauses the
game in single player. Online the game carries on behind the page, and
walking away closes it.

A notebook can have several pages. The foot of the paper then says which
one you are on (**PAGE 2 OF 3**), with an arrow at each side that has a page
to turn to. **D**, the **right arrow key** or the **mouse wheel** rolled
towards you turns to the next page; **A**, the **left arrow key** or the
wheel rolled away goes back. It always opens at the first page. (Online, A
and D still walk you about, so there only the arrow keys and the wheel turn
pages, and the wheel leaves your weapon alone while a page is open.)

Test map 2 has two. The one on the middle desk of the control room, where
you start, is the **control room log**: three pages kept by the night shift
operator who locked themselves in there when the lab below broke open. The
other, still on the desk in the checkpoint from before the start moved, is
the single page every other level has: a survivor's note about the bunker
the story is set in.

Each notebook can have its own words. Select a `Notebook` node in a level
and change **Title** and **Pages** in the Inspector: Pages is a list with
one entry for each page, so add an entry to add a page. A page is one
paragraph of at most 150 words (it has 22 lines of 48 letters; the game
prints a warning if a page runs off the bottom), and the pixel font only
has capital letters, digits and `. , : ; = - ' ! ?`. Start a page with its day
and a full stop (`Day 31. Night shift...`) and that is taken off the front
and written at the top of the page as the entry's date; a page that starts
any other way has no date. **Reach** is how close you
must be, and **Aim** how squarely you must look at it.

To add another, drag `scenes/notebook.tscn` under a level's `Props` and set
it on top of a desk. The page itself (the paper's colours and layout) is
`scenes/notebook_reader.tscn`. The open pages of the notebook on the desk
are covered in lines of handwriting too small to read
(`notebook_page.png`, a different page on each side).

### Windows that zombies climb through

Enemies walk in straight lines and can't step up onto anything, so on their
own a window sill stops them. `scenes/zombie_window.tscn` does the thinking
for them: it watches a box of space outside the window (the yard), sends
every chasing enemy in it to the spot below the sill, and takes them
through one at a time. It also wakes the enemies in the yard when a player
comes near, since they usually can't see into the room.

To put one in a level:

1. Cut the hole with a `Carve...` box in the level's `World`: 1.4 m wide,
   from 0.9 m to 2.2 m above the floor, through a wall 0.5 m thick.
2. Drag `scenes/zombie_window.tscn` under `Props`, on the floor in the middle
   of that wall, and turn it so its blue arrow points **out**, to where the
   zombies come from.
3. Make a room or yard out there and put zombies in it.

Its settings: **Sill Height**, **Wall Thickness**, **Stand Off** (how far
from the wall a zombie stands before climbing, and lands after), **Climb
Speed**, **Yard Size** (the space it watches: along the wall, up, and out
from the wall) and **Alert Distance** (how close a player must come to wake
the yard).

### Rounds of zombies

`scenes/zombie_rounds.tscn` sends zombies into a level a round at a time,
and starts the next round once every one of them is dead. So far only the
multiplayer map demo has one. To give a level rounds:

1. Drag `scenes/zombie_rounds.tscn` into the level, next to its `Enemies`
   node (the zombies it makes go in there).
2. Add a `Marker3D` under it for each **gate**, a place where zombies
   appear: somewhere players can't see, with its blue arrow pointing the way
   a zombie should walk out. A marker up in the air is fine: the zombie
   drops from there, which is how the demo hides them in its roof.
3. Keep the way out of each gate clear of crates and pylons.

A new zombie is walked straight out of its gate before it goes after the
players, because enemies head straight for the nearest player, and that is
a poor way out of a tunnel.

Its settings, under **Rounds**: **Break Time** (seconds of rest before the
first round and between rounds, 6), **First Round Zombies** (6), **Extra
Zombies Per Round** (3), **Extra Zombies Per Player** (0.5: half as many
again for each player after the first), **Spawn Interval** (seconds between
one zombie appearing and the next, 1) and **Max Zombies At Once** (14: the
rest of a big round waits its turn). Under **Zombies**: **Speed Gain Per
Round** (0.05 = 5%), **Max Speed Gain** (0.75) and **Body Time** (a dead
zombie sinks into the floor and is removed after 12 seconds, or a long game
would fill the level with bodies). Under **Gates**: **Walk Out** (how far a
zombie walks straight ahead from its marker: far enough to bring it into
the open, 7.25 m in the demo), **Gate Clearance** (no zombie appears at a
gate while a player is this close to its marker, unless there is a player
that close to every gate; 6 m in the demo, which covers a whole tunnel)
and **Fight Distance** (a zombie still on its way out turns on a player who
comes this close). **Zombie Scene** is the enemy the rounds are made of.

The words in the corner of the screen are the `RoundText` and `RoundNote`
nodes in `scenes/hud.tscn`. They show nothing in a level without rounds.

### Lab props

The control room and the experimentation lab are dressed with props you can
drag into any level (put them under the level's `Props` node). Each one's
origin is at its base, and its front faces **+Z**, the blue arrow in the
editor, so turn that arrow to face into the room.

- **Poster** (`scenes/poster.tscn`): a 60 x 80 cm sheet. To pick the
  picture, set **Material Override** to one of the `poster_*.tres`,
  `whiteboard*.tres` or `sign_*.tres` materials in `assets/materials/`
  (`poster_chart_plain` is the infection rate poster without GREAT JOB
  TEAM!, `poster_penguin` is a penguin told to HANG IN THERE!, and
  `whiteboard_flowchart` is the whiteboard about debugging). Scale
  it for other sizes (the landscape posters, the whiteboard and the signs
  are scaled copies). Hang it a centimetre off the wall.
  `poster_chart_printout.tres` is the strip of printer paper that carries on
  the infection rate poster's line: scale it to 37.5 cm x 1.05 m (0.625 and
  1.3125) and stand it on the poster's top edge with its left edge 50 cm in
  from the poster's left, as `PosterChartPrintout` is in test map 2.
- **Bookshelf**, **server rack**, **filing cabinet** and **office chair**:
  solid furniture with nothing to set. The books, drawers and blinking
  lights are painted on (see `generate_textures.gd`).
- **Potted plant** (`scenes/potted_plant.tscn`): solid like the furniture
  until it is shot or blown to bits, which takes two pistol shots. Then you
  can walk and shoot through where it stood, over the broken pot and the
  soil it leaves. See "Tuning gameplay" for its health and its pieces.
- **Desk** (`scenes/desk.tscn`): 2.2 m wide, 0.8 m tall and 1 m deep,
  with the drawers and the knee space on its +Z side, where the chair goes.
  Its top is 0.8 m above its origin: that is the height to put the next
  three at.
- **Monitor** (`scenes/monitor.tscn`): a 40 cm beige box on a foot, solid
  like the furniture. **Screen** is the picture on the glass: drag one of
  the `monitor_screen_*.png` textures onto it (`cells`, `vitals`, `pong`,
  `signal`, `breach`, `code`: three lines of a program in yellow on blue,
  `listing`: a screen of green lines on black, like a program too small
  to read, and `listing_blue`: the same in yellow on blue), or a 26 x 22
  pixel picture of your own. The screen glows: the room's lights don't
  change it.
- **Keyboard** (`scenes/keyboard.tscn`) and **cup** (`scenes/cup.tscn`): only
  for show, so shots pass through them and you can walk over them if you
  jump onto the desk. The keyboard's space bar and the cup's heart face +Z.
- **Macintosh** (`scenes/macintosh.tscn`): the first Apple Macintosh, of
  1984, at its real size: a beige box 25 cm wide and 35 cm tall whose face
  overhangs its foot, with a small black and white screen, a disk slot
  under it and a rainbow badge. Its short keyboard, its one-button mouse
  and their two leads are part of the same scene, so there is one thing to
  place and the leads always reach. Put its origin where the computer
  stands: the keyboard then reaches 47 cm in front of that (+Z) and the
  mouse 28 cm to the right, and the mouse's lead wanders round behind. The
  computer is solid like the monitor; the keyboard, the mouse and the leads
  are only for show. The leads lie in loose curves, each made of a row of
  short pieces under the scene's `Leads` node: hide or delete `Leads` for a
  Macintosh with no wires. There is nothing else to set: the screen always
  shows `macintosh_screen.png` (14 x 10 pixels), and like the monitor's it
  glows.
- **Control console** (`scenes/control_console.tscn`): a control desk 4 m
  long, 0.9 m tall and 1 m deep, to stand at. Its origin is on the floor
  under its middle and the operator's side faces +Z. All of it is solid,
  sloping panels included, so shots leave marks on it. The panels along the
  back of the top leave two bays 70 to 75 cm wide for a monitor and a
  Macintosh, which are not part of the scene (nor is anything else you
  stand on it): its top is 0.9 m above its origin. The four lit buttons and
  the red emergency stop are part of it, and stand on plates painted on the
  top, so they can't be moved without repainting it (see
  `_make_control_console` in `generate_textures.gd`). There is nothing to
  set.
- **Water cooler** (`scenes/water_cooler.tscn`): the cabinet is solid, the
  bottle on top is not. The taps face +Z, so stand its back against a wall.
- **Closed notebook** (`scenes/notebook_closed.tscn`) and **pencil pot**
  (`scenes/pencil_cup.tscn`): only for show too, like the keyboard and the
  cup, so shots pass through them. The notebook is shut, with an elastic
  band round it and the end of its ribbon poking out, and it has no script,
  so it can't be read (the one you can read is `scenes/notebook.tscn`). Its
  spine is on its -X side. The pot holds two pencils and two pens. Their
  colours are plain tinted materials: `pencil.tres` and `pen_blue.tres` are
  new, the rest are shared with other props.
- **Breakable glass** (`scenes/breakable_glass.tscn`): set **Size** to fill
  the opening; its origin is the middle of its bottom edge. See "Tuning
  gameplay" for its health.
- **Specimen tank** (`scenes/specimen_tank.tscn`): **Broken** swaps the
  glowing liquid for shards round the rim and a puddle in front, and lets
  shots through where the glass was. **Occupied** puts a body in an intact
  tank. **Pipe Length** is how far the feed pipe reaches up from the top of
  the tank (4.8 m meets an 8 m ceiling; 0 for none). The editor shows the
  changes straight away.

## Known limitations

- The notebook's page is laid out for a 4:3 picture: at any other shape of
  **Render Size** it sits left of the middle (see "Changing the
  resolution").
- Zombies only climb in through a window, never back out, and a crouch-jump
  may get you out through it. The window has only been tested in single
  player, not online.
- In the view behind you (F4), shots come from your eyes, 30 cm below the
  camera's line, so at close range they land slightly below the crosshair.
- Crouching doesn't hide you from enemies that are already looking your way.
- Multiplayer has no smoothing for bad connections: other players move as
  often as their updates arrive, so over the internet they can look jerky.
  It also has no player names, chat or scoreboard.
- Online, bullet holes, blood, gibs and cracks in glass are drawn by each
  computer for itself, so they can land in slightly different places, and
  someone who joins late doesn't see the ones made before they arrived (nor
  the jagged edges of a pane broken before they joined, nor the broken pot
  and soil of a plant smashed before they joined: for them the corner is
  simply empty).
- A level only works online if it is in Main's **Levels** list (a level
  started with F6 that isn't on the list can't be shared).
- Enemies head straight for the player and can get stuck on walls. They
  will also walk straight into lava or slime.
- A round of zombies only ends when every one of them is dead, so a zombie
  stuck behind a pillar or a crate has to be gone and found. The rounds
  keep no score, and pylons and crates don't come back between them.
- Someone who joins in the middle of a round sees that round's dead zombies
  fall over again (and lose again any limbs they had lost) as they arrive.
- The pylon's warning lamp only glows; it doesn't light up its
  surroundings (a real lamp per pylon would use up the renderer's limit of
  8 lights per object).
- Shots leave no bullet holes on crates, since the crate may not be there
  for long.
- Lights cast no shadows, so a light with a large range shines through walls.
- The player and the enemies can't step up a ledge or a block, so a heap of
  rubble has to be jumped onto (and stops enemies), and stairs need an
  invisible ramp (`StairRamp` in the level) that doesn't break with them.
- Destruction is simple physics: falling pieces drop straight down without
  tipping, and nothing is heavy: a pillar holds up any amount of floor
  within reach. Pieces that fall at the same moment as another blast can
  land a little oddly.
- Props, lamps and enemies standing on a block that is destroyed simply
  drop; lamps don't fall or break yet.
- Only the block-built test room can be destroyed; the CSG levels can't.
- Bullet holes, scorch marks and blood stains are flat squares, not true
  decals (Godot's `Decal` node needs the Forward+ or Mobile renderer), so
  they can't wrap around a corner. One that would hang over an edge is not
  shown at all, which means shots very close to an edge leave no mark.
- No mipmaps, so fine texture detail shimmers in the distance (as it did in
  1996).

## Suggested next steps

- **More weapons**: a shotgun (several rays with spread), ammo pickups,
  and weapons you find in the level instead of starting with.
- **Campaign**: the story levels (escape the facility, then go back down
  and destroy it), exits that need every player, objectives on the HUD.
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
- **Movement**: stepping up a ledge or a block (for stairs and rubble,
  players and enemies), and holding jump to bunny-hop.
- **Multiplayer**: player names over heads, a scoreboard, chat, a lobby or
  server browser instead of typing an address (with a relay server, nobody
  would need to open a port), smoothing (interpolation)
  for other players' movement, and a switch to turn friendly fire off.
