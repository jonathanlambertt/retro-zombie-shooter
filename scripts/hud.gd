extends CanvasLayer
## Heads-up display: health, ammo, a crosshair, the multiplayer status in the
## top left corner and, in a level with rounds of zombies, the round in the
## top right.
##
## A CanvasLayer draws 2D things on top of the 3D world. Because this HUD is
## placed inside the low-res SubViewport (see scenes/main.tscn), it is drawn
## at 320x240 and scaled up with the rest of the picture, so its pixels are
## exactly as chunky as the game's.

var player: Node

@onready var health_text: Control = $HealthText
@onready var ammo_text: Control = $AmmoText
@onready var damage_tint: ColorRect = $DamageTint
# The crosshair is a plus sign built from three white rectangles (one bar
# across, plus the pieces above and below it, so none overlap), with the
# same three in black under "Shadow", moved one pixel down and right.
# The arms are one pixel thick, and a 320x240 picture has no middle pixel,
# so the plus sits on the pixel just down and right of the exact centre.
# One pixel is also the smallest distance the shadow can be moved, which is
# a lot next to arms one pixel thick, so the shadow is kept faint instead
# (the alpha of its three rectangles).
@onready var crosshair: Control = $Crosshair
@onready var network_text: Control = $NetworkText
@onready var round_text: Control = $RoundText
@onready var round_note: Control = $RoundNote

## How see-through the red tint is at its strongest. 0 = invisible,
## 1 = solid red.
@export_range(0.0, 1.0) var damage_tint_strength := 0.45


func _process(_delta: float) -> void:
	# "HOST  2 PLAYERS", "CONNECTING"... (empty in single player).
	network_text.text = Network.hud_text()

	# A level with rounds of zombies has a node in the "rounds" group (see
	# scripts/zombie_rounds.gd), which says what to show: "ROUND 3" and, in
	# smaller letters under it, "8 ZOMBIES LEFT". Other levels show nothing.
	var rounds := get_tree().get_first_node_in_group("rounds")
	round_text.text = rounds.get_hud_title() if rounds else ""
	round_note.text = rounds.get_hud_note() if rounds else ""

	# Find the player the first time (and again if the level was reloaded).
	# Online there are several players: ours is the one in "local_player".
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("local_player")
		if player == null:
			return

	# Simply read the numbers every frame. This is the easiest approach; for
	# a bigger game you would use signals to update only when they change.
	health_text.text = "HEALTH %d" % player.health
	# Each weapon decides what to show here (see get_hud_text in its script).
	ammo_text.text = player.current_weapon.get_hud_text()

	# The red tint is a rectangle covering the whole screen. "a" (alpha) is
	# how solid it is: the player sets hurt_flash to 1 when hurt and lets it
	# fade back to 0, and the tint simply follows it.
	damage_tint.color.a = player.hurt_flash * damage_tint_strength
	crosshair.visible = player.wants_crosshair()
