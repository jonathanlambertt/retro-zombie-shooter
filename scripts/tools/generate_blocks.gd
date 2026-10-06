extends SceneTree
## Builds assets/blocks.tres, the MeshLibrary of half-metre blocks that
## levels are painted with (see scripts/structure.gd).
##
## This is NOT part of the running game. Run it again after changing
## BLOCK_TYPES in scripts/structure.gd (from the project folder):
##   Godot_v4.7-stable_win64_console.exe --headless --path . --script res://scripts/tools/generate_blocks.gd
##
## The list of blocks is in scripts/blocks.gd.
##
## A MeshLibrary is a numbered list of "items", each a mesh plus collision
## shapes. A GridMap draws item N in every cell painted with N. Here every
## item is a 0.5 m cube with one of the game's retro materials; the
## materials lay their textures out by world position, so neighbouring
## blocks join up seamlessly into one wall.

const Blocks := preload("res://scripts/blocks.gd")
const OUTPUT := "res://assets/blocks.tres"
const BLOCK_SIZE := 0.5


func _init() -> void:
	var library := MeshLibrary.new()
	for i in Blocks.TYPES.size():
		var block: Dictionary = Blocks.TYPES[i]
		var material: ShaderMaterial = load(block.material)

		var cube := BoxMesh.new()
		cube.size = Vector3.ONE * BLOCK_SIZE
		cube.material = material
		var shape := BoxShape3D.new()
		shape.size = Vector3.ONE * BLOCK_SIZE

		library.create_item(i)
		library.set_item_name(i, block.name)
		library.set_item_mesh(i, cube)
		# Shapes are given as pairs: a shape, then where it sits in the cell.
		library.set_item_shapes(i, [shape, Transform3D()])
		library.set_item_preview(i, _preview(material))

	var error := ResourceSaver.save(library, OUTPUT)
	if error == OK:
		print("Wrote ", OUTPUT, " with ", Blocks.TYPES.size(), " blocks")
	else:
		push_error("Could not write %s (error %d)" % [OUTPUT, error])
	quit()


## The picture shown for a block in the editor's GridMap palette: its
## texture, tinted like the material.
func _preview(material: ShaderMaterial) -> Texture2D:
	var texture: Texture2D = material.get_shader_parameter("albedo_texture")
	var image := texture.get_image()
	image.decompress()
	image.resize(32, 32, Image.INTERPOLATE_NEAREST)
	var tint = material.get_shader_parameter("tint")
	if tint is Color:
		for y in image.get_height():
			for x in image.get_width():
				image.set_pixel(x, y, image.get_pixel(x, y) * tint)
	return ImageTexture.create_from_image(image)
