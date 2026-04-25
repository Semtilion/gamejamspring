extends CanvasLayer

# ============================================================
#  RECRUITMENT SCREEN — DEFEATED ENEMIES
# ============================================================
#  Shows defeated enemies as banner cards with portraits.
#  Player picks which ones to recruit with their souls.

signal recruitment_done(recruits: Array)

const RECRUIT_BTN_PATH = "res://assets/recruit_button.png"

var recruit_system: Node
var souls := 0
var defeated_enemies = []  # array of defeated enemy data dicts
var recruits = []          # chosen recruits

# UI elements
var panel: Panel
var title_label: Label
var souls_label: Label
var instruction_label: Label
var confirm_button: Button
var card_nodes = []  # array of card container nodes
var selected_indices = []  # which cards are selected

# Portrait paths
var portrait_paths = {
	0: "res://assets/bastet_portrait.png",
	1: "res://assets/nasus_portrait.png",
	2: "res://assets/renekton_portrait.png",
	3: "res://assets/falcon_portrait.png",
}
const BANNER_PATH = "res://assets/banner.png"


func setup(recruit_node: Node, soul_count: int, defeated: Array):
	recruit_system = recruit_node
	souls = soul_count
	defeated_enemies = defeated.duplicate()
	recruits.clear()
	selected_indices.clear()
	_build_ui()


func _build_ui():
	var screen_w = 1460.0
	var cx = screen_w / 2.0

	# Dark background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.03, 0.08, 0.95)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Panel
	panel = Panel.new()
	panel.position = Vector2(80, 20)
	panel.size = Vector2(1300, 630)
	add_child(panel)

	# Title
	title_label = Label.new()
	title_label.text = "RAISE THE DEAD"
	title_label.position = Vector2(cx - 150, 30)
	title_label.size = Vector2(300, 40)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	add_child(title_label)

	# Souls
	souls_label = Label.new()
	souls_label.position = Vector2(cx - 150, 65)
	souls_label.size = Vector2(300, 25)
	souls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	souls_label.add_theme_font_size_override("font_size", 18)
	add_child(souls_label)
	_update_souls_label()

	# Instructions
	instruction_label = Label.new()
	instruction_label.position = Vector2(cx - 250, 92)
	instruction_label.size = Vector2(500, 25)
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.55))
	instruction_label.text = "Select the fallen warriors you wish to resurrect."
	add_child(instruction_label)

	# Defeated enemy cards
	var card_width = 220.0
	var card_height = 440.0
	var banner_height = 385.0
	var max_cards = mini(defeated_enemies.size(), 6)
	var total_width = max_cards * card_width + (max_cards - 1) * 15
	var start_x = cx - total_width / 2.0

	var weapon_names = {0: "Sword", 1: "Axe", 2: "Lance", 3: "Bow"}

	for i in range(max_cards):
		var enemy = defeated_enemies[i]
		var card_x = start_x + i * (card_width + 15)
		var card_y = 120.0

		# Banner as full card background
		var banner_tex = load(BANNER_PATH)
		if banner_tex:
			var banner = TextureRect.new()
			banner.texture = banner_tex
			banner.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			banner.stretch_mode = TextureRect.STRETCH_SCALE
			banner.position = Vector2(card_x, card_y)
			banner.size = Vector2(card_width, banner_height)
			add_child(banner)
		else:
			var card_bg = ColorRect.new()
			card_bg.position = Vector2(card_x, card_y)
			card_bg.size = Vector2(card_width, banner_height)
			card_bg.color = Color(0.15, 0.1, 0.05)
			add_child(card_bg)

		# Portrait centered on upper portion of banner
		var wpn = enemy["weapon"]
		if portrait_paths.has(wpn):
			var portrait_tex = load(portrait_paths[wpn])
			if portrait_tex:
				var portrait = TextureRect.new()
				portrait.texture = portrait_tex
				portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				portrait.stretch_mode = TextureRect.STRETCH_SCALE
				var portrait_x = card_x + 35
				# Nasus/Axe sits slightly left
				if wpn == 1:
					portrait_x = card_x + 20
				portrait.position = Vector2(portrait_x, card_y + 65)
				portrait.size = Vector2(150, 103)
				add_child(portrait)

		# Class name on the banner
		var class_label = Label.new()
		class_label.text = weapon_names.get(wpn, "???")
		class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		class_label.position = Vector2(card_x, card_y + 180)
		class_label.size = Vector2(card_width, 25)
		class_label.add_theme_font_size_override("font_size", 18)
		class_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
		add_child(class_label)

		# Stats on the banner
		var stats_label = Label.new()
		stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_label.position = Vector2(card_x + 20, card_y + 210)
		stats_label.size = Vector2(card_width - 20, 200)
		stats_label.add_theme_font_size_override("font_size", 14)
		stats_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
		stats_label.text = "HP:  %d\nSTR: %d   SKL: %d\nSPD: %d   DEF: %d\nLCK: %d\nMOV: %d" % [
			enemy["max_hp"], enemy["str_"], enemy["skl"],
			enemy["spd"], enemy["def_"], enemy["lck"],
			enemy["move_range"]]
		add_child(stats_label)

		# Selection indicator (hidden bg behind banner, shows when selected)
		var select_bg = ColorRect.new()
		select_bg.position = Vector2(card_x - 4, card_y - 4)
		select_bg.size = Vector2(card_width + 8, banner_height + 8)
		select_bg.color = Color(0.2, 0.6, 0.2, 0.0)  # invisible by default
		select_bg.z_index = -1
		add_child(select_bg)

		# Select button below banner
		var btn = _create_recruit_button("SELECT", Vector2(card_x + 20, card_y + banner_height + 8), Vector2(card_width - 40, 38), 14)
		btn.pressed.connect(_on_card_selected.bind(i, btn, select_bg))
		add_child(btn)
		card_nodes.append({"bg": select_bg, "btn": btn})

	# Done button
	confirm_button = _create_recruit_button("DONE", Vector2(cx - 100, 570), Vector2(200, 50), 18)
	confirm_button.pressed.connect(_on_done)
	add_child(confirm_button)


func _create_recruit_button(text: String, pos: Vector2, btn_size: Vector2, font_size: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.size = btn_size
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	btn.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	btn.add_theme_constant_override("outline_size", 1)

	var btn_tex = load(RECRUIT_BTN_PATH)
	if btn_tex:
		var normal_style = StyleBoxTexture.new()
		normal_style.texture = btn_tex
		normal_style.modulate_color = Color(1.0, 1.0, 1.0)
		btn.add_theme_stylebox_override("normal", normal_style)

		var hover_style = StyleBoxTexture.new()
		hover_style.texture = btn_tex
		hover_style.modulate_color = Color(1.15, 1.1, 0.95)
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style = StyleBoxTexture.new()
		pressed_style.texture = btn_tex
		pressed_style.modulate_color = Color(0.7, 0.65, 0.55)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		var focus_style = StyleBoxTexture.new()
		focus_style.texture = btn_tex
		focus_style.modulate_color = Color(1.0, 1.0, 1.0)
		btn.add_theme_stylebox_override("focus", focus_style)

	return btn


func _on_card_selected(index: int, btn: Button, select_bg: ColorRect):
	if index in selected_indices:
		# Deselect
		selected_indices.erase(index)
		select_bg.color = Color(0.2, 0.6, 0.2, 0.0)
		btn.text = "SELECT"
		souls += 1
	else:
		# Check if we have souls
		if souls <= 0:
			return
		# Select
		selected_indices.append(index)
		select_bg.color = Color(0.2, 0.6, 0.2, 0.5)
		btn.text = "SELECTED"
		souls -= 1

	_update_souls_label()


func _on_done():
	# Convert selected defeated enemies to recruits
	for index in selected_indices:
		var enemy = defeated_enemies[index]
		var recruit = recruit_system.convert_to_recruit(enemy)
		recruits.append(recruit)

	_cleanup()
	recruitment_done.emit(recruits)


func _update_souls_label():
	souls_label.text = "Souls remaining: %d" % souls


func _cleanup():
	for child in get_children():
		child.queue_free()
