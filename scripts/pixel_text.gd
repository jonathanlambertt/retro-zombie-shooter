extends Control
## Draws text with a tiny built-in 3x5 pixel font.
##
## Godot's normal Label uses a smooth vector font, which looks blurry and out
## of place at 320x240. Instead, each letter here is a little grid of on/off
## pixels, drawn one square at a time, so no font file is needed.
##
## To use a real pixel font later: replace these nodes with Label nodes and
## give them a pixel .ttf/.fnt font with antialiasing turned off in its
## import settings.

## The text to show. Supports A-Z, 0-9, spaces and > % . : - (lower case is
## upper-cased).
@export var text := "":
	set(value):
		if value == text:
			return
		text = value
		queue_redraw()  # ask Godot to call _draw() again

@export var color := Color(1.0, 0.82, 0.35):
	set(value):
		color = value
		queue_redraw()
## Size of one font pixel, in game pixels. 2 gives 6x10 pixel letters.
@export var pixel_size := 2
## If true, the text ends at the right edge of this Control instead of
## starting at the left edge.
@export var align_right := false

const GLYPH_WIDTH := 3
const GLYPH_HEIGHT := 5

# Each letter is five rows of three characters: "#" = pixel on, "." = off.
const GLYPHS := {
	"A": [".#.", "#.#", "###", "#.#", "#.#"],
	"B": ["##.", "#.#", "##.", "#.#", "##."],
	"C": [".##", "#..", "#..", "#..", ".##"],
	"D": ["##.", "#.#", "#.#", "#.#", "##."],
	"E": ["###", "#..", "##.", "#..", "###"],
	"F": ["###", "#..", "##.", "#..", "#.."],
	"G": [".##", "#..", "#.#", "#.#", ".##"],
	"H": ["#.#", "#.#", "###", "#.#", "#.#"],
	"I": ["###", ".#.", ".#.", ".#.", "###"],
	"J": ["..#", "..#", "..#", "#.#", ".#."],
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"],
	"L": ["#..", "#..", "#..", "#..", "###"],
	"M": ["#.#", "###", "###", "#.#", "#.#"],
	"N": ["##.", "#.#", "#.#", "#.#", "#.#"],
	"O": [".#.", "#.#", "#.#", "#.#", ".#."],
	"P": ["##.", "#.#", "##.", "#..", "#.."],
	"Q": [".#.", "#.#", "#.#", "###", ".##"],
	"R": ["##.", "#.#", "##.", "#.#", "#.#"],
	"S": [".##", "#..", ".#.", "..#", "##."],
	"T": ["###", ".#.", ".#.", ".#.", ".#."],
	"U": ["#.#", "#.#", "#.#", "#.#", "###"],
	"V": ["#.#", "#.#", "#.#", "#.#", ".#."],
	"W": ["#.#", "#.#", "###", "###", "#.#"],
	"X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
	"Y": ["#.#", "#.#", ".#.", ".#.", ".#."],
	"Z": ["###", "..#", ".#.", "#..", "###"],
	"0": ["###", "#.#", "#.#", "#.#", "###"],
	"1": [".#.", "##.", ".#.", ".#.", "###"],
	"2": ["##.", "..#", ".#.", "#..", "###"],
	"3": ["##.", "..#", ".#.", "..#", "##."],
	"4": ["#.#", "#.#", "###", "..#", "..#"],
	"5": ["###", "#..", "##.", "..#", "##."],
	"6": [".##", "#..", "###", "#.#", "###"],
	"7": ["###", "..#", ".#.", ".#.", ".#."],
	"8": ["###", "#.#", "###", "#.#", "###"],
	"9": ["###", "#.#", "###", "..#", "##."],
	">": ["#..", ".#.", "..#", ".#.", "#.."],
	"%": ["#.#", "..#", ".#.", "#..", "#.#"],
	".": ["...", "...", "...", "...", ".#."],
	":": ["...", ".#.", "...", ".#.", "..."],
	"-": ["...", "...", "###", "...", "..."],
}


# Godot calls _draw() whenever this Control needs to be painted.
func _draw() -> void:
	# Each letter takes its width plus one empty column of spacing.
	var advance := (GLYPH_WIDTH + 1) * pixel_size
	var x := 0.0
	if align_right:
		x = size.x - text.length() * advance

	for character in text.to_upper():
		# Draw a black copy one pixel down-right first, as a drop shadow,
		# so the text stays readable over bright walls.
		_draw_glyph(character, Vector2(x + pixel_size, pixel_size), Color.BLACK)
		_draw_glyph(character, Vector2(x, 0.0), color)
		x += advance


func _draw_glyph(character: String, origin: Vector2, glyph_color: Color) -> void:
	if not GLYPHS.has(character):
		return  # spaces and unknown characters are left blank
	var rows: Array = GLYPHS[character]
	var pixel := Vector2(pixel_size, pixel_size)
	for row in GLYPH_HEIGHT:
		for column in GLYPH_WIDTH:
			if rows[row][column] == "#":
				draw_rect(Rect2(origin + Vector2(column, row) * pixel_size, pixel), glyph_color)
