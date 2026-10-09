extends Node3D
## Gives a zombie its look, so that the zombies in a level are not all the
## same one.
##
## A "look" is a picture with a whole zombie painted in it: a face, hair,
## clothes and wounds, each in its own piece of the picture. They are the
## files zombie_look_01.png, zombie_look_02.png and so on in
## assets/textures/, painted by scripts/tools/generate_zombie.gd (which
## also explains how the picture is laid out, in case you want to paint one
## yourself). The meshes of the body know which piece of the picture goes
## on which part, so changing the picture changes the whole zombie.
##
## This script is on the Model node of scenes/zombie-rexture-demo.tscn.
## When the zombie appears it chooses a look and puts that picture on every
## mesh of the body. It only does this in the running game: in the editor
## every zombie shows the first look.
##
## Nothing here needs sending between computers in multiplayer. The choice
## is made from things that are the same for everyone (the zombie's place
## in the level, or its name), so every player sees the same zombie.

## The looks' files. The "%02d" is replaced by a look's number, written
## with two digits: 7 becomes zombie_look_07.png.
const LOOK_PATH := "res://assets/textures/zombie_look_%02d.png"
## The materials the scene's meshes are drawn with: one for the body and
## one, which glows in the dark, for the eyes. Each look gets a copy of
## both with its own picture in them.
const BODY_MATERIAL := preload("res://assets/materials/zombie_look.tres")
const EYE_MATERIAL := preload("res://assets/materials/zombie_look_eyes.tres")

## How many look pictures there are, or -1 if they have not been counted
## yet. "static" means all zombies share this one number.
static var look_count := -1
## The materials made so far: for each look's number, its body material and
## its eye material. Zombies with the same look share them.
static var materials := {}

## Which look this zombie wears. 0 lets it choose (see _choose_look());
## any other number is that picture, so 7 is zombie_look_07.png. To set it
## on one zombie in a level, right-click that zombie, turn on Editable
## Children and select its Model node.
@export var look := 0

## The number of the look it ended up with.
var worn_look := 0


func _ready() -> void:
	worn_look = _choose_look()
	if worn_look == 0:
		return  # there are no pictures: keep what the scene has
	var made: Array = _materials_for(worn_look)
	# find_children looks through everything inside this node, however deep.
	for part: MeshInstance3D in find_children("*", "MeshInstance3D"):
		# material_override replaces whatever material the mesh has. A limb
		# keeps it when it is shot off, so the gib still matches the body.
		part.material_override = made[1] if part.name == "Eyes" else made[0]


## Works out which look to wear: a number from 1 to the number of pictures.
func _choose_look() -> int:
	var count := _count_looks()
	if count == 0:
		return 0
	var number := look
	if number <= 0:
		# "owner" is the root of the scene a node was saved in. For this
		# node that is the zombie itself.
		var zombie: Node = owner if owner != null else self
		if zombie.owner != null:
			# The zombie has an owner too, so it was placed in a level by
			# hand. It takes its place in the list of its level's enemies:
			# the first gets look 1, the second look 2... Zombies standing
			# near each other are usually next to each other in that list,
			# and the looks are painted so that neighbours differ most.
			number = zombie.get_index() + 1
		else:
			# It was made while the game was running (see
			# scripts/zombie_rounds.gd), and its place in the list is not
			# the same on every computer. Its name is: "Zombie17" gives 17.
			number = String(zombie.name).to_int() + 1
	# Past the last picture, start again from the first.
	return posmod(number - 1, count) + 1


## Counts the pictures, the first time it is asked: it tries each number in
## turn until there is no file with that number.
static func _count_looks() -> int:
	if look_count < 0:
		look_count = 0
		while ResourceLoader.exists(LOOK_PATH % (look_count + 1)):
			look_count += 1
	return look_count


## Returns the two materials for a look, body first, making them if this is
## the first zombie to wear it.
static func _materials_for(number: int) -> Array:
	if not materials.has(number):
		var picture: Texture2D = load(LOOK_PATH % number)
		# duplicate() makes a copy, so changing the picture in it leaves the
		# original (and every other look's copy) alone.
		var body: ShaderMaterial = BODY_MATERIAL.duplicate()
		body.set_shader_parameter("albedo_texture", picture)
		var eyes: StandardMaterial3D = EYE_MATERIAL.duplicate()
		eyes.albedo_texture = picture
		materials[number] = [body, eyes]
	return materials[number]
