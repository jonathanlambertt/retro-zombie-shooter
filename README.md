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
| Ctrl or C | Crouch (hold). Crouch in mid-air to pull your legs up and reach higher ledges |
| Left mouse button | Shoot (hold for the machine gun) |
| Right mouse button | Machine gun: fire a grenade. Shotgun: double shot |
| 1 / 2 / 3 / 4 | Switch to pistol / machine gun / rocket launcher / shotgun |
| Mouse wheel | Next / previous weapon |
| Esc | Pause menu: resume, graphics settings (the retro effects), multiplayer, or quit. Esc again resumes |
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
  player_model.tscn    The player's body, as other players will see it
  pistol.tscn          Hitscan pistol viewmodel
  machine_gun.tscn     Automatic gun that fires bullet.tscn projectiles
  bullet.tscn          One yellow machine gun bullet
  grenade.tscn         Grenade from the machine gun's launcher
  shotgun.tscn         Pump-action shotgun that fires a cluster of pellets
  rocket_launcher.tscn Slow, powerful launcher that fires rocket.tscn
  rocket.tscn          One rocket, with its smoke trail
  explosion.tscn       The blast a grenade makes when it lands
  crate.tscn           Wooden crate that can be shot to pieces
  explosive_pylon.tscn Red canister that explodes when shot
  blood_splash.tscn    Spray of square blood drops when an enemy is hit
  blood_stain.tscn     Stain the blood leaves on walls and floors
  gib.tscn             A limb that has been shot off a zombie
  bullet_hole.tscn     Mark left on walls and floors by shots
  enemy.tscn           Walking enemy that chases and hits you
  crawler.tscn         Small crawling enemy that leaps at your head
  zombie.tscn          Thin, limping enemy (shares scripts/enemy.gd)
  hud.tscn             Health / ammo / crosshair
  pause_menu.tscn      Esc menu: pauses the game, retro effect settings, multiplayer, quit
levels/
  test_level.tscn      The greybox level (CSG)
  backrooms.tscn       Backrooms maze: yellow wallpaper, carpet, ceiling lights
  test_facility.tscn   Half-Life-style research facility: lobby, lab, storage, test chamber
  test_room.tscn       Small single room, handy for trying shader settings
  half-life-level.tscn Office complex full of zombies, with a slime pit
  test-map.tscn        Bigger facility built for zombie waves: a hub with four wings
  test-map-2.tscn      Bigger again: two-storey atrium, warehouse, cramped tunnels
  quake-level.tscn     Brick castle hall with a lava channel and an altar
scripts/             One script per scene, plus:
  level_launcher.gd    Autoload: runs a level started on its own inside main.tscn
  network.gd           Autoload: multiplayer (hosting, joining, sharing the game)
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

Press **Esc** while playing to pause the game and open the menu, which has
four lines: **Resume**, **Graphics**, **Multiplayer** (see "Multiplayer"
below) and **Quit**. Graphics opens a second page (Back or Esc returns from
it):

| Line | Starts as | What it does |
| --- | --- | --- |
| Retro Effects | `ON` | Master switch. `OFF` turns off every effect below (and affine warping) without forgetting their settings. |
| Vertex Snap | `25%` | How strong the vertex snapping is: the jittery "wobble" as you move. `100%`, `75%`, `50%`, `25%` or `OFF`. |
| Light Bands | `OFF` | How strong the banded lighting is. Lower = more, subtler bands. `OFF` = smooth lighting. |
| Color Quantize | `ON` | The colour-reducing post-process (the same switch as F1). |

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
(`concrete`, `metal`, `tile`, `crate`, plus `wallpaper`, `carpet` and
`ceiling_tile` for the Backrooms level, `lab_wall` and `hazard` for the
facility level, `pylon` for the explosive pylon, and `armor` and `suit`
for the player model). Overwrite them with your own pixel art
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

  Under **Crouch**: **Crouch Height** (the collision capsule's height while
  crouched; standing it is 1.8), **Crouch Speed** and **Crouch Transition
  Speed** (how fast the view sinks and rises).

  To add another weapon: make its scene, place it under `Head/Camera3D` in
  the player scene, add it to the `weapons` list in `scripts/player.gd`, and
  give it a `weapon_5` input action (Project > Project Settings > Input Map).
  The mouse wheel picks it up automatically. Its script needs a `get_hud_text()`
  function, which returns the words shown in the bottom-right corner. If it
  fires projectiles, start them at `owner.get_projectile_start(muzzle)` rather
  than at the muzzle itself (see "The gun in your hands" below). For the
  player model to hold it, also add a gun model to `scenes/player_model.tscn`
  (see below).
- **Player model** (`scenes/player_model.tscn`): **Armor Color** and **Visor
  Color** (only show when the game runs; give each multiplayer player their
  own), **Stride Length** (metres per stride: lower = quicker steps),
  **Crouch Hip Height** and **Lamp Blink Interval** (the green lamp on the
  backpack).

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
- **Shotgun** (`scenes/shotgun.tscn`): pellets per shell, damage per pellet,
  spread, range, time between shots, time after a double shot, and
  **Shoot Sound**. It never runs out of shells.
- **Crate** (`scenes/crate.tscn`): health (20 = two pistol shots) and size.
  Its `Debris` node is the splinters. To add one to a level, drag
  `scenes/crate.tscn` into the level; set **Size** on it for a bigger one.
- **Explosive pylon** (`scenes/explosive_pylon.tscn`): health (15 = two
  pistol shots), fuse time (the hiss before the bang, which is also the
  delay between pylons in a chain reaction), blast damage (100), blast
  radius (5 m), fireball size, how fast the lamp blinks (it speeds up as
  the pylon is damaged) and **Fuse Sound**. Its `Sparks` node is the shower
  from a bullet hit and `Debris` is the scrap metal. To add one to a level,
  drag `scenes/explosive_pylon.tscn` under the level's `Props` node. Two
  pylons closer than about 4 m set each other off; further apart, the blast
  is too weak at that distance.
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
  shots), **Head Loss Chance**, **Leg Loss Chance** and **Arm Loss Chance**
  (how often a limb that has taken that much damage really comes off: 35%,
  60% and 75%) and **Crawl Speed Factor**. Shooting off the head kills it,
  each lost arm halves its attack, and losing a leg makes it crawl. A limb
  that holds on can't be shot off afterwards, so a zombie that keeps its
  head has to be killed the ordinary way. Grenades and rockets take off a
  random limb.
- **Crawler** (`scenes/crawler.tscn`): health, crawl speed, sight range, leap
  range, leap speed, leap damage, time between leaps, crouch time (the
  wind-up before a leap) and step speed.

The enemies' animations (walking, attacking, flinching, dying...) are not made
in Godot's animation editor. They are a few lines of maths in the `_animate`
function of `scripts/enemy.gd` and `scripts/crawler.gd`, which is where to
change how far or how fast a limb moves. The player model is animated the same
way, in `scripts/player_model.gd`.

## The player model

You never see your own body in first person (it would only get in the way of
the view). Press **F4** for a camera behind you, and again for one in front
of you looking back at your face; a third press returns to first person. In
multiplayer this is the body the other players see. It is an armoured
soldier in a hazard suit, built from boxes like the enemies, and it is
animated from what the player is doing:

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

You can also open a level in the editor and press **F6** (Run Current Scene).
A level on its own has no HUD, pause menu or low-res picture, so
`scripts/level_launcher.gd` (an autoload, under **Project Settings > Globals >
Autoload**) notices that a scene from `levels/` was started and restarts it
inside `scenes/main.tscn`. This works for a level that isn't on the list yet
too; it is added to the end of the list for that run.

### The Half-Life level

`levels/half-life-level.tscn` is a security checkpoint, a long hallway with
two offices, a loading bay full of crates, and a core room with a pit of
toxic slime crossed by a catwalk. Its only enemies are zombies, sixteen of
them. Standing in the slime hurts.

### The test map

`levels/test-map.tscn` (the second level, so one press of F2) is a bigger
facility in the style of the Half-Life level, laid out for holding off waves
of zombies. You start in a security checkpoint on the south side, which opens
onto a tall 20 x 20 m hub with four pillars and some crates for cover. The
hub has a wide doorway in each wall: the checkpoint to the south, a loading
bay to the east, a core room with a slime pit to the west, and a long hallway
with two offices to the north. A passage at each end of the hallway leads
down into the bay and the core, so you can run a loop instead of being
cornered.

There is no wave spawner yet: the 27 zombies stand at fixed points under the
level's `Enemies` node, named after the room they are in (`ZombieHub1`,
`ZombieBay3`, ...). They only notice you within 14 m and with a clear line of
sight, so they arrive in groups as you move through the level.

### Test map 2

`levels/test-map-2.tscn` (the third level, so two presses of F2) is larger
than the test map and mixes open rooms with tight ones. You start in a small
checkpoint that opens onto a tall 24 x 24 m atrium. From there:

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
map. Like the stairs in `test_level.tscn`, these are steps with an invisible
`StairRamp` slope over them.

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

- In the view behind you (F4), shots come from your eyes, 30 cm below the
  camera's line, so at close range they land slightly below the crosshair.
- Crouching doesn't hide you from enemies that are already looking your way.
- Multiplayer has no smoothing for bad connections: other players move as
  often as their updates arrive, so over the internet they can look jerky.
  It also has no player names, chat or scoreboard.
- Online, bullet holes, blood and gibs are drawn by each computer for itself,
  so they can land in slightly different places, and someone who joins late
  doesn't see the ones made before they arrived.
- A level only works online if it is in Main's **Levels** list (a level
  started with F6 that isn't on the list can't be shared).
- Enemies head straight for the player and can get stuck on walls. They
  will also walk straight into lava or slime.
- The pylon's warning lamp only glows; it doesn't light up its
  surroundings (a real lamp per pylon would use up the renderer's limit of
  8 lights per object).
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
- **Movement**: proper stair stepping, and holding jump to bunny-hop.
- **Multiplayer**: player names over heads, a scoreboard, chat, a lobby or
  server browser instead of typing an address (with a relay server, nobody
  would need to open a port), smoothing (interpolation)
  for other players' movement, and a switch to turn friendly fire off.
