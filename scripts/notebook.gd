extends Node3D
## A notebook lying on a desk. Stand close, look at it and press E (the
## "interact" action) to read it.
##
## This script only works out whether the player is near enough and looking
## the right way. The page itself, and the "PRESS E TO READ" prompt, belong
## to scenes/notebook_reader.tscn, which sits in the low-res viewport with
## the HUD (see scenes/main.tscn). The notebook tells it "you can read me
## now" with offer() and "not any more" with withdraw(), and the reader does
## the rest, including listening for the key.
##
## To add one to a level: drag scenes/notebook.tscn under the level's Props
## and put it on top of a desk (its origin is the underside of the book).
## Give it its own words with Title and Text in the Inspector.

## The heading at the top of the page.
@export var title := "NOTEBOOK"
## What is written on the page: one paragraph, up to about 150 words (more
## would run off the bottom). The pixel font only has capital letters,
## digits and . , : - ' ! ? so anything else is left blank.
@export_multiline var text := "Day 41. The bunker was built to keep the world out, and now it keeps us in. Nine floors of concrete under the hill, sealed the night the sirens stopped. There were thirty of us then. The air tastes of rust and the lights hum all night, but the worst of it is the sound from the lower levels, where the labs are. Whatever they were growing down there got into the vents, and the ones who breathed it stopped being ours. The lift is dead and the blast door needs power we do not have. Mara says there is a service shaft behind the pump room that climbs all the way to the surface. Six of us are going to try it tonight. If you are reading this, we did not come back for it. Keep moving up."
## How close the player's eyes must be to read it, in metres.
@export var reach := 2.2
## How squarely the player must be looking at it: 1 = dead on, 0 = anywhere
## in front of them.
@export_range(0.0, 1.0) var aim := 0.75

## True while the reader has been told this notebook can be read.
var offered := false


func _process(_delta: float) -> void:
	var readable := _player_can_read()
	if readable == offered:
		return
	offered = readable
	# The reader is found by its group, as the HUD finds the player.
	var reader := get_tree().get_first_node_in_group("notebook_reader")
	if reader == null:
		return  # the level was opened without scenes/main.tscn around it
	if readable:
		reader.offer(self)
	else:
		reader.withdraw(self)


func _exit_tree() -> void:
	# The level is being removed (a new level, or the game reloading after a
	# death): make sure the prompt doesn't stay on the screen.
	if offered:
		offered = false
		var reader := get_tree().get_first_node_in_group("notebook_reader")
		if reader:
			reader.withdraw(self)


## True if the player this computer controls is within reach and looking
## at the notebook.
func _player_can_read() -> bool:
	var player := get_tree().get_first_node_in_group("local_player")
	if player == null:
		return false
	var eyes: Camera3D = player.camera
	var to_book := global_position - eyes.global_position
	if to_book.length() > reach:
		return false
	# A camera looks along its -Z axis. The dot product of two directions of
	# length 1 is 1 when they point the same way and 0 when they are square.
	var looking := -eyes.global_transform.basis.z
	return looking.dot(to_book.normalized()) >= aim
