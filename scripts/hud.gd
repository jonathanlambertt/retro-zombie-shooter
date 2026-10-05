extends CanvasLayer
## Heads-up display: health, ammo and a crosshair.
##
## A CanvasLayer draws 2D things on top of the 3D world. Because this HUD is
## placed inside the low-res SubViewport (see scenes/main.tscn), it is drawn
## at 320x240 and scaled up with the rest of the picture, so its pixels are
## exactly as chunky as the game's.

var player: Node

@onready var health_text: Control = $HealthText
@onready var ammo_text: Control = $AmmoText
@onready var damage_tint: ColorRect = $DamageTint

## How see-through the red tint is at its strongest. 0 = invisible,
## 1 = solid red.
@export_range(0.0, 1.0) var damage_tint_strength := 0.45


func _process(_delta: float) -> void:
	# Find the player the first time (and again if the level was reloaded).
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
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
