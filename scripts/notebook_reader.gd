extends CanvasLayer
## The page you see when you read a notebook (scripts/notebook.gd), and the
## "PRESS E TO READ" prompt that appears when one is in reach.
##
## Like the HUD and the pause menu, this lives inside the low-res
## SubViewport (see scenes/main.tscn), so the paper and its writing are as
## chunky as the rest of the game. The writing is drawn by
## scripts/pixel_text.gd.
##
## Reading freezes the game in single player, the same way the pause menu
## does (see the notes at the top of scripts/pause_menu.gd): this node's
## Process Mode is "Always", so it can still hear the key that closes the
## page. Online the game can't be frozen for everyone, so it carries on
## behind the page, and walking away from the notebook closes it.
##
## Keys: E opens the page while the prompt is showing; E or Esc closes it.

## How many letters fit on one line of the page.
const LINE_LENGTH := 48
## The page's body text starts this far below the top of the paper, and
## each line of it is this tall, in game pixels (both must match the Body
## node in the scene: its position, and a 5-pixel letter plus its Line Gap).
const BODY_TOP := 30
const LINE_HEIGHT := 8

## Colour of the paper.
@export var paper_color := Color(0.87, 0.82, 0.66)
## Colour of the faint lines ruled across it.
@export var rule_color := Color(0.62, 0.70, 0.76)
## Colour of the line down the left margin.
@export var margin_color := Color(0.78, 0.36, 0.32)

## The notebook that is in reach right now (or null).
var nearby: Node
## True if opening the page was what froze the game, so closing it should
## unfreeze it.
var froze_game := false

@onready var prompt: Control = $Prompt
@onready var page: Control = $Page
@onready var paper: Control = $Page/Paper
@onready var title_text: Control = $Page/Paper/Title
@onready var body_text: Control = $Page/Paper/Body


func _ready() -> void:
	prompt.visible = false
	page.visible = false
	# "draw" is the signal a Control sends when it needs painting. Connecting
	# to it lets this script paint the paper without giving the Paper node a
	# script of its own.
	paper.draw.connect(_draw_paper)


func _process(_delta: float) -> void:
	# No prompt while the page is open or the game is paused by the menu.
	prompt.visible = is_instance_valid(nearby) and not page.visible and not get_tree().paused


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if page.visible:
			close()
		elif _can_open():
			open(nearby.title, nearby.text)
		else:
			return
	elif page.visible and event.is_action_pressed("ui_cancel"):
		# Esc closes the page instead of opening the pause menu. This node
		# comes after the pause menu in scenes/main.tscn, and input is handed
		# to the last nodes first, so the menu never sees this key press.
		close()
	else:
		return
	# Mark the input as used, so nothing else reacts to it as well.
	get_viewport().set_input_as_handled()


## Called by a notebook when the player comes within reach of it.
func offer(notebook: Node) -> void:
	nearby = notebook


## Called by a notebook when the player is no longer within reach.
func withdraw(notebook: Node) -> void:
	if nearby != notebook:
		return
	nearby = null
	# Only happens online, where the player can still walk while reading.
	if page.visible:
		close()


## Shows the page with the given heading and paragraph on it.
func open(title: String, text: String) -> void:
	title_text.text = title
	body_text.text = _wrap(text)
	page.visible = true
	if not Network.is_online() and not get_tree().paused:
		get_tree().paused = true
		froze_game = true


func close() -> void:
	page.visible = false
	if froze_game:
		get_tree().paused = false
		froze_game = false


func is_open() -> bool:
	return page.visible


## A notebook can be opened while one is in reach and the player is in
## control: not while the pause menu is up. (The menu frees the mouse, and
## in single player it pauses the game too.)
func _can_open() -> bool:
	return (is_instance_valid(nearby) and not get_tree().paused
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)


## Breaks a paragraph into lines of at most LINE_LENGTH letters, without
## splitting a word, and returns them joined with line breaks.
func _wrap(text: String) -> String:
	var lines: Array[String] = []
	var line := ""
	# split(" ", false) cuts the text at every space and drops empty pieces,
	# so doubled spaces and line breaks in the text don't matter.
	for word in text.replace("\n", " ").split(" ", false):
		if line.is_empty():
			line = word
		elif line.length() + 1 + word.length() <= LINE_LENGTH:
			line += " " + word
		else:
			lines.append(line)
			line = word
	if not line.is_empty():
		lines.append(line)
	return "\n".join(lines)


## Paints the sheet of paper: the page itself, a faint line under every row
## of writing, a red line down the margin and three punched holes.
func _draw_paper() -> void:
	paper.draw_rect(Rect2(Vector2.ZERO, paper.size), paper_color)
	# The first rule sits one pixel under the first row of letters.
	var y := BODY_TOP + 6
	while y < paper.size.y - 14:
		paper.draw_rect(Rect2(0, y, paper.size.x, 1), rule_color)
		y += LINE_HEIGHT
	paper.draw_rect(Rect2(15, 0, 1, paper.size.y), margin_color)
	for hole_y: float in [30.0, paper.size.y / 2.0, paper.size.y - 30.0]:
		paper.draw_rect(Rect2(5, hole_y - 2, 4, 4), Color(0.1, 0.1, 0.1))
