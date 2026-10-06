## The kinds of block that destructible structures are built from (see
## scripts/structure.gd). Their order is the order of the items in
## assets/blocks.tres, the palette levels are painted with, which
## scripts/tools/generate_blocks.gd builds from this list. Add new types at
## the end, so the blocks already painted in levels keep their meaning.
##
## "health" is how much blast damage a block takes before it is destroyed.
## "span" is how many blocks sideways it can reach out from whatever holds
## it up and still hold (12 blocks = 6 m).

const TYPES: Array[Dictionary] = [
	{name = "Concrete", material = "res://assets/materials/concrete.tres", health = 120.0, span = 12},
	{name = "Lab wall", material = "res://assets/materials/lab_wall.tres", health = 70.0, span = 8},
	{name = "Floor tile", material = "res://assets/materials/tile.tres", health = 110.0, span = 12},
	{name = "Ceiling tile", material = "res://assets/materials/ceiling_tile.tres", health = 90.0, span = 12},
	{name = "Metal", material = "res://assets/materials/metal.tres", health = 260.0, span = 24},
	{name = "Hazard stripes", material = "res://assets/materials/hazard.tres", health = 120.0, span = 12},
	{name = "Dark stone", material = "res://assets/materials/dark_stone.tres", health = 160.0, span = 12},
	{name = "Rubble", material = "res://assets/materials/rubble.tres", health = 40.0, span = 3},
]
## The block type rubble heaps are made of.
const RUBBLE := 7

