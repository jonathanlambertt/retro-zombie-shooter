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


func _process(_delta: float) -> void:
	# Find the player the first time (and again if the level was reloaded).
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if player == null:
			return

	# Simply read the numbers every frame. This is the easiest approach; for
	# a bigger game you would use signals to update only when they change.
	health_text.text = "HEALTH %d" % player.health
	ammo_text.text = "AMMO %d" % player.pistol.ammo
