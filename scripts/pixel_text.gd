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

## The text to show. Supports A-Z, 0-9, spaces and > % . , : - ' ! ? (lower case
## is upper-cased). A line break in the text starts a new line below.
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
## If true, a black copy is drawn behind the text, one pixel down and to the
## right. That keeps it readable over the game; turn it off for dark writing
## on a plain light background, where it would only smudge the letters.
@export var shadow := true
## The empty rows between one line of text and the next, in font pixels.
@export var line_gap := 2

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
	",": ["...", "...", "...", ".#.", "#.."],
	"'": [".#.", ".#.", "...", "...", "..."],
	"!": [".#.", ".#.", ".#.", "...", ".#."],
	"?": ["##.", "..#", ".#.", "...", ".#."],
}


# Godot calls _draw() whenever this Control needs to be painted.
func _draw() -> void:
	# Each letter takes its width plus one empty column of spacing.
	var advance := (GLYPH_WIDTH + 1) * pixel_size
	var x := 0.0
	var y := 0.0
	# (Right-aligning measures the whole text, so it is for single lines.)
	if align_right:
		x = size.x - text.length() * advance
	var line_start := x

	for character in text.to_upper():
		if character == "\n":
			# A line break: back to the left edge, one line further down.
			x = line_start
			y += (GLYPH_HEIGHT + line_gap) * pixel_size
			continue
		if shadow:
			# Draw a black copy one pixel down-right first, as a drop shadow,
			# so the text stays readable over bright walls.
			_draw_glyph(character, Vector2(x + pixel_size, y + pixel_size), Color.BLACK)
		_draw_glyph(character, Vector2(x, y), color)
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
