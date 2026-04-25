extends CanvasLayer

# ============================================================
#  DEPLOYMENT PHASE
# ============================================================
#  Shows the grid with a 3x3 deployment zone.
#  Emperor is auto-placed in the center.
#  Player picks units from roster and places them.
#  Click a placed unit on the grid to take it back.

signal deployment_done(placed_units: Array)

var grid: Node2D
var deploy_center: Vector2i
var roster = []
var placed = []  # { "data": dict, "pos": Vector2i, "roster_index": int }
var max_slots := 8

var deploy_cells = []
var selected_roster_index := -1

# Preview sprites on the grid
var preview_sprites = {}  # cell (Vector2i) -> Node2D

# UI elements
var sidebar: Panel
var title_label: Label
var roster_buttons = []
var info_label: Label
var confirm_button: Button
var instruction_label: Label

# Reference to parent scene for spawning preview sprites
var game_node: Node2D


func setup(grid_ref: Node2D, center: Vector2i, available_roster: Array):
	grid = grid_ref
	deploy_center = center
	roster = available_roster.duplicate()
	placed.clear()
	preview_sprites.clear()
	selected_roster_index = -1
	game_node = grid.get_parent()

	# Calculate 3x3 zone cells (excluding center where emperor goes)
	deploy_cells.clear()
	for x in range(-1, 2):
		for y in range(-1, 2):
			var cell = center + Vector2i(x, y)
			if cell != center and grid.is_within_bounds(cell) and cell not in grid.obstacles:
				deploy_cells.append(cell)

	# Highlight deploy zone on grid
	grid.highlighted_cells = deploy_cells
	grid.queue_redraw()

	_build_ui()


func _build_ui():
	# Sidebar panel on the right
	sidebar = Panel.new()
	sidebar.position = Vector2(grid.grid_width * grid.CELL_SIZE + 8, 32)
	sidebar.size = Vector2(320, grid.grid_height * grid.CELL_SIZE)
	add_child(sidebar)

	# Title
	title_label = Label.new()
	title_label.text = "DEPLOY YOUR ARMY"
	title_label.position = Vector2(grid.grid_width * grid.CELL_SIZE + 20, 42)
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	add_child(title_label)

	# Instructions
	instruction_label = Label.new()
	instruction_label.position = Vector2(grid.grid_width * grid.CELL_SIZE + 20, 72)
	instruction_label.size = Vector2(280, 50)
	instruction_label.add_theme_font_size_override("font_size", 12)
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	instruction_label.text = "Select a soldier, then click a blue tile.\nClick a placed unit to take it back.\nPharaoh is already in the center."
	add_child(instruction_label)

	# Roster buttons
	var y_offset = 125
	var weapon_names = {0: "Sword", 1: "Axe", 2: "Lance", 3: "Bow"}

	for i in range(roster.size()):
		var r = roster[i]
		var btn = Button.new()
		btn.text = "%s [%s] HP:%d" % [r["unit_name"], weapon_names[r["weapon"]], r["max_hp"]]
		btn.position = Vector2(grid.grid_width * grid.CELL_SIZE + 20, y_offset + i * 36)
		btn.size = Vector2(280, 32)
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(_on_roster_select.bind(i))
		add_child(btn)
		roster_buttons.append(btn)

	# Info label for selected unit preview
	info_label = Label.new()
	info_label.position = Vector2(grid.grid_width * grid.CELL_SIZE + 20, y_offset + roster.size() * 36 + 10)
	info_label.size = Vector2(280, 120)
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(info_label)

	# Confirm button
	confirm_button = Button.new()
	confirm_button.text = "START BATTLE"
	confirm_button.position = Vector2(grid.grid_width * grid.CELL_SIZE + 20, grid.grid_height * grid.CELL_SIZE + 32 - 55)
	confirm_button.size = Vector2(280, 45)
	confirm_button.add_theme_font_size_override("font_size", 16)
	confirm_button.pressed.connect(_on_confirm)
	add_child(confirm_button)


func _on_roster_select(index: int):
	# Check if this unit is already placed
	for p in placed:
		if p["roster_index"] == index:
			info_label.text = "Already placed! Click them on\nthe grid to take them back."
			return

	selected_roster_index = index
	var r = roster[index]
	var weapon_names = {0: "Sword", 1: "Axe", 2: "Lance", 3: "Bow"}
	info_label.text = "Selected: %s [%s]\nHP:%d STR:%d SKL:%d\nSPD:%d DEF:%d LCK:%d\n\nClick a blue tile to place." % [
		r["unit_name"], weapon_names[r["weapon"]],
		r["max_hp"], r["str_"], r["skl"],
		r["spd"], r["def_"], r["lck"]]


func handle_grid_click(cell: Vector2i):
	# Check if clicking on an already-placed unit to remove it
	for p in placed.duplicate():
		if p["pos"] == cell:
			_remove_placed_unit(p)
			return

	# Need a selected roster unit to place
	if selected_roster_index < 0:
		return

	# Must be a deploy cell
	if cell not in deploy_cells:
		return

	# Check slot limit
	if placed.size() >= max_slots:
		info_label.text = "All slots filled!"
		return

	# Place the unit
	_place_unit(cell, selected_roster_index)


func _place_unit(cell: Vector2i, roster_index: int):
	var data = roster[roster_index]

	placed.append({
		"data": data,
		"pos": cell,
		"roster_index": roster_index,
	})

	# Dim the roster button
	roster_buttons[roster_index].disabled = true

	# Spawn a preview sprite on the grid
	var preview = Node2D.new()
	preview.set_script(preload("res://unit.gd"))
	preview.position = grid.grid_to_world(cell)
	preview.unit_color = data.get("unit_color", Color(0.3, 0.5, 1.0))
	preview.unit_name = data["unit_name"]
	preview.weapon = data["weapon"]
	preview.team = "player"
	game_node.add_child(preview)
	preview_sprites[cell] = preview

	info_label.text = "%s placed!\nSelect another or START BATTLE.\nClick a placed unit to take back." % data["unit_name"]
	selected_roster_index = -1


func _remove_placed_unit(entry: Dictionary):
	var cell = entry["pos"]
	var roster_index = entry["roster_index"]

	# Remove from placed list
	placed.erase(entry)

	# Re-enable roster button
	roster_buttons[roster_index].disabled = false

	# Remove preview sprite
	if preview_sprites.has(cell):
		preview_sprites[cell].queue_free()
		preview_sprites.erase(cell)

	info_label.text = "%s returned to roster.\nSelect a soldier to place." % entry["data"]["unit_name"]
	selected_roster_index = -1


func _on_confirm():
	if placed.size() == 0:
		info_label.text = "Place at least 1 soldier!"
		return

	grid.highlighted_cells.clear()
	grid.queue_redraw()

	# Remove all preview sprites (real units will be spawned by game.gd)
	for cell in preview_sprites:
		preview_sprites[cell].queue_free()
	preview_sprites.clear()

	_cleanup()
	deployment_done.emit(placed)


func _cleanup():
	for child in get_children():
		child.queue_free()
