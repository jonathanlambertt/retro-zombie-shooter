extends CanvasLayer
## The page you see when you read a notebook (scripts/notebook.gd), and the
## "PRESS E TO READ" prompt that appears when one is in reach.
##
## Like the HUD and the pause menu, this lives inside the low-res
## SubViewport (see scenes/main.tscn), so the paper and its writing are as
## chunky as the rest of the game. The writing is drawn by
## scripts/pixel_text.gd.
##
## The page is a page of a diary: the notebook's name small in one corner,
## the day the entry was written in the other, and the entry below in the
## same ink, on ruled paper bound into a book.
##
## Reading freezes the game in single player, the same way the pause menu
## does (see the notes at the top of scripts/pause_menu.gd): this node's
## Process Mode is "Always", so it can still hear the key that closes the
## page. Online the game can't be frozen for everyone, so it carries on
## behind the page, and walking away from the notebook closes it.
##
## Keys: E opens the notebook while the prompt is showing; E or Esc closes
## it. A notebook with more than one page turns to the next with D, the
## right arrow key or a turn of the mouse wheel towards you, and back with
## A, the left arrow key or the wheel the other way.

## How many letters fit on one line of the page.
const LINE_LENGTH := 48
## How many lines of writing fit on the page: one on each ruled line.
const LINES_PER_PAGE := 22
## The page's body text starts this far below the top of the paper, and
## each line of it is this tall, in game pixels (both must match the Body
## node in the scene: its position, and a 5-pixel letter plus its Line Gap).
const BODY_TOP := 30
const LINE_HEIGHT := 8
## The inputs that always turn a page: the arrow keys, and the mouse wheel
## (which changes weapon when no notebook is open).
const NEXT_PAGE_ACTIONS: Array[StringName] = [&"ui_right", &"weapon_next"]
const PREVIOUS_PAGE_ACTIONS: Array[StringName] = [&"ui_left", &"weapon_previous"]

## Colour of the paper.
@export var paper_color := Color(0.87, 0.82, 0.66)
## Colour of the faint lines ruled across it.
@export var rule_color := Color(0.62, 0.70, 0.76)
## Colour of the edges of the pages underneath, which show along the right
## and the bottom of the page.
@export var edge_color := Color(0.68, 0.62, 0.48)

## The notebook that is in reach right now (or null).
var nearby: Node
## True if opening the page was what froze the game, so closing it should
## unfreeze it.
var froze_game := false
## The writing on each page of the open notebook, already broken into
## lines, and which of them is showing (0 is the first page).
var page_texts: Array[String] = []
var page_number := 0
## The date at the top of each of those pages ("Day 31"), or "" for a page
## that doesn't start with one.
var page_dates: Array[String] = []

@onready var prompt: Control = $Prompt
@onready var page: Control = $Page
@onready var paper: Control = $Page/Paper
@onready var title_text: Control = $Page/Paper/Title
@onready var date_text: Control = $Page/Paper/Date
@onready var body_text: Control = $Page/Paper/Body
@onready var page_hint: Control = $Page/Paper/PageHint


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
			open(nearby.title, nearby.pages)
		else:
			return
	elif page.visible and event.is_action_pressed("ui_cancel"):
		# Esc closes the page instead of opening the pause menu. This node
		# comes after the pause menu in scenes/main.tscn, and input is handed
		# to the last nodes first, so the menu never sees this key press.
		close()
	elif page.visible and _page_step(event) != 0:
		# The input is used up even on the last page, where there is nothing
		# further to turn to. Online the game carries on behind the page,
		# and the player must not change weapon with the same turn of the
		# wheel (the player gets input after this node, like the menu).
		_show_page(page_number + _page_step(event))
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


## Opens a notebook at its first page. "title" is the notebook's name and
## "notebook_pages" the paragraph written on each page.
func open(title: String, notebook_pages: Array[String]) -> void:
	title_text.text = title
	page_texts.clear()
	page_dates.clear()
	for text in notebook_pages:
		# A diary entry starts with its date. If this page does ("Day 31.
		# Night shift..."), the date is lifted off its front and written at
		# the top of the page instead, as it is in a diary.
		var date := ""
		var writing := text
		var stop := text.find(". ")
		if text.begins_with("Day ") and stop != -1 and stop <= 10:
			date = text.left(stop)
			writing = text.substr(stop + 2)
		page_dates.append(date)
		var lines := _wrap(writing)
		if lines.size() > LINES_PER_PAGE:
			# Shown in the editor's Debugger while the game runs: this page
			# has too much on it, and its last lines run off the paper.
			push_warning("Notebook \"%s\": page %d is %d lines long, but only %d fit on the paper."
					% [title, page_texts.size() + 1, lines.size(), LINES_PER_PAGE])
		page_texts.append("\n".join(lines))
	if page_texts.is_empty():
		page_texts.append("")  # a notebook with nothing written in it
		page_dates.append("")
	page.visible = true
	if not Network.is_online() and not get_tree().paused:
		get_tree().paused = true
		froze_game = true
	_show_page(0)


func close() -> void:
	page.visible = false
	if froze_game:
		get_tree().paused = false
		froze_game = false


func is_open() -> bool:
	return page.visible


## Turns to page "number" (0 is the first), stopping at the first and last
## pages, and writes the line at the foot of the paper that says which page
## this is and how to turn it.
func _show_page(number: int) -> void:
	page_number = clampi(number, 0, page_texts.size() - 1)
	body_text.text = page_texts[page_number]
	date_text.text = page_dates[page_number]
	# The line under the date is part of the paper's drawing, and is as long
	# as the date: have the paper painted again.
	paper.queue_redraw()
	# A notebook with a single page has nothing to turn.
	page_hint.visible = page_texts.size() > 1
	# An arrow at each end, with its key beside it where that key works (see
	# _page_step() below). An end with no further page to turn to is left
	# blank, with spaces, so the words in the middle stay where they are.
	var back := "< A" if froze_game else "<  "
	var forward := "D >" if froze_game else "  >"
	if page_number == 0:
		back = "   "
	if page_number == page_texts.size() - 1:
		forward = "   "
	page_hint.text = "%s   PAGE %d OF %d   %s" % [back, page_number + 1, page_texts.size(), forward]


## Which way an input turns the page: 1 forwards, -1 back, or 0 if it is not
## a page-turning input at all.
func _page_step(event: InputEvent) -> int:
	for action in NEXT_PAGE_ACTIONS:
		if event.is_action_pressed(action):
			return 1
	for action in PREVIOUS_PAGE_ACTIONS:
		if event.is_action_pressed(action):
			return -1
	# A and D turn pages too, but only while the page has frozen the game.
	# Online the game carries on, so those keys still walk the player, and a
	# step sideways would be a step away from the notebook.
	if froze_game:
		if event.is_action_pressed("move_right"):
			return 1
		if event.is_action_pressed("move_left"):
			return -1
	return 0


## A notebook can be opened while one is in reach and the player is in
## control: not while the pause menu is up. (The menu frees the mouse, and
## in single player it pauses the game too.)
func _can_open() -> bool:
	return (is_instance_valid(nearby) and not get_tree().paused
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)


## Breaks a paragraph into lines of at most LINE_LENGTH letters, without
## splitting a word.
func _wrap(text: String) -> Array[String]:
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
	return lines


## Paints the page of the diary: the paper itself, a faint line under every
## row of writing, the shadow where the page curves down into the book's
## spine on the left, the edges of the pages underneath, and the line drawn
## under the date.
func _draw_paper() -> void:
	paper.draw_rect(Rect2(Vector2.ZERO, paper.size), paper_color)
	# Each rule sits one pixel under its row of letters.
	for line in LINES_PER_PAGE:
		paper.draw_rect(Rect2(0, BODY_TOP + 6 + line * LINE_HEIGHT, paper.size.x, 1), rule_color)
	# The spine: three strips of shadow, each fainter than the one before.
	for strip in 3:
		paper.draw_rect(Rect2(strip * 3, 0, 3, paper.size.y), Color(0.0, 0.0, 0.0, 0.3 - strip * 0.1))
	paper.draw_rect(Rect2(paper.size.x - 2, 0, 2, paper.size.y), edge_color)
	paper.draw_rect(Rect2(0, paper.size.y - 2, paper.size.x, 2), edge_color)
	# The date is underlined in its own ink. Each of its letters is 4 font
	# pixels wide with its gap, and the date ends at the Date node's right
	# edge, so that is where the line is measured back from.
	var date_width: float = date_text.text.length() * 4.0 * date_text.pixel_size
	if date_width > 0.0:
		var right: float = date_text.position.x + date_text.size.x
		paper.draw_rect(Rect2(right - date_width - 2.0, date_text.position.y + 12.0, date_width + 2.0, 1.0), date_text.color)
