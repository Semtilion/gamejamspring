extends CanvasLayer

signal attack_confirmed()
signal attack_cancelled()

const FORECAST_BTN_PATH = "res://assets/forecast_button.png"

var combat_node: Node
var attacker: Node2D
var defender: Node2D
var distance: int

var attacker_label: Label
var defender_label: Label
var vs_label: Label
var triangle_label: Label
var attack_button: Button
var cancel_button: Button

const SCROLL_PATH = "res://assets/scroll.png"


func setup(combat_ref: Node, atk: Node2D, def: Node2D, dist: int):
	combat_node = combat_ref
	attacker = atk
	defender = def
	distance = dist
	_build_ui()


func _build_ui():
	# Semi-transparent background overlay
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.5)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Scroll background
	var scroll_w = 700.0
	var scroll_h = 460.0
	var scroll_x = 380.0
	var scroll_y = 80.0

	var scroll_tex = load(SCROLL_PATH)
	if scroll_tex:
		var scroll = TextureRect.new()
		scroll.texture = scroll_tex
		scroll.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		scroll.stretch_mode = TextureRect.STRETCH_SCALE
		scroll.position = Vector2(scroll_x, scroll_y)
		scroll.size = Vector2(scroll_w, scroll_h)
		add_child(scroll)

	# Usable content area inside scroll
	var pad_x = 130.0
	var pad_top = 75.0
	var cx = scroll_x + pad_x
	var cy = scroll_y + pad_top
	var cw = scroll_w - pad_x * 2
	var ch = scroll_h - pad_top - 60

	# --- Title (top center) ---
	var title = Label.new()
	title.text = "COMBAT FORECAST"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(cx, cy + 30)
	title.size = Vector2(cw, 25)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.55, 0.35, 0.1))
	add_child(title)

	# Calculate combat stats
	var atk_accuracy = combat_node.calc_hit_rate(attacker, defender)
	var atk_damage = combat_node.calc_damage(attacker, defender)
	var atk_crit = combat_node.calc_crit_rate(attacker, defender)
	var atk_doubles = combat_node.can_double(attacker, defender)
	var atk_wpn = combat_node.weapon_data[attacker.weapon]

	var can_counter = combat_node.can_counter(attacker, defender, distance)

	var def_accuracy = 0
	var def_damage = 0
	var def_crit = 0
	var def_doubles = false
	var def_wpn_name = "---"

	if can_counter:
		def_accuracy = combat_node.calc_hit_rate(defender, attacker)
		def_damage = combat_node.calc_damage(defender, attacker)
		def_crit = combat_node.calc_crit_rate(defender, attacker)
		def_doubles = combat_node.can_double(defender, attacker)
		def_wpn_name = combat_node.weapon_data[defender.weapon]["name"]
	elif defender.weapon >= 0:
		def_wpn_name = combat_node.weapon_data[defender.weapon]["name"]

	# Weapon triangle
	var triangle = 0
	if attacker.weapon >= 0 and defender.weapon >= 0:
		triangle = combat_node.get_triangle(attacker.weapon, defender.weapon)
	var triangle_text = ""
	if triangle == 1:
		triangle_text = "ADVANTAGE"
	elif triangle == -1:
		triangle_text = "DISADVANTAGE"
	else:
		triangle_text = "NEUTRAL"

	# Triangle label (below title)
	triangle_label = Label.new()
	triangle_label.text = triangle_text
	triangle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	triangle_label.position = Vector2(cx, cy + 50)
	triangle_label.size = Vector2(cw, 20)
	triangle_label.add_theme_font_size_override("font_size", 14)
	if triangle == 1:
		triangle_label.add_theme_color_override("font_color", Color(0.15, 0.5, 0.15))
	elif triangle == -1:
		triangle_label.add_theme_color_override("font_color", Color(0.6, 0.15, 0.15))
	else:
		triangle_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3))
	add_child(triangle_label)

	# --- Stat blocks ---
	var block_y = cy + 55
	var block_w = cw / 2 - 30
	var block_h = ch - 60

	# Attacker (left block)
	attacker_label = Label.new()
	attacker_label.position = Vector2(cx + 105, block_y + 20)
	attacker_label.size = Vector2(block_w, block_h)
	attacker_label.add_theme_font_size_override("font_size", 15)
	attacker_label.add_theme_color_override("font_color", Color(0.15, 0.3, 0.55))

	var atk_double_text = " x2" if atk_doubles else ""
	attacker_label.text = "%s\n[%s]\n\nHP:  %d/%d\nDMG: %d%s\nHIT: %d%%\nCRT: %d%%" % [
		attacker.unit_name, atk_wpn["name"],
		attacker.hp, attacker.max_hp,
		atk_damage, atk_double_text,
		atk_accuracy,
		atk_crit]
	add_child(attacker_label)

	# VS (centered between blocks)
	vs_label = Label.new()
	vs_label.text = "VS"
	vs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_label.position = Vector2(cx + block_w, block_y + block_h / 2 - 40)
	vs_label.size = Vector2(60, 30)
	vs_label.add_theme_font_size_override("font_size", 22)
	vs_label.add_theme_color_override("font_color", Color(0.55, 0.35, 0.1))
	add_child(vs_label)

	# Defender (right block)
	defender_label = Label.new()
	defender_label.position = Vector2(cx + block_w + 70, block_y + 20)
	defender_label.size = Vector2(block_w, block_h)
	defender_label.add_theme_font_size_override("font_size", 15)
	defender_label.add_theme_color_override("font_color", Color(0.55, 0.2, 0.15))

	if can_counter:
		var def_double_text = " x2" if def_doubles else ""
		defender_label.text = "%s\n[%s]\n\nHP:  %d/%d\nDMG: %d%s\nHIT: %d%%\nCRT: %d%%" % [
			defender.unit_name, def_wpn_name,
			defender.hp, defender.max_hp,
			def_damage, def_double_text,
			def_accuracy,
			def_crit]
	else:
		defender_label.text = "%s\n[%s]\n\nHP:  %d/%d\n\nCannot counter" % [
			defender.unit_name, def_wpn_name,
			defender.hp, defender.max_hp]
	add_child(defender_label)

	# --- Buttons BELOW scroll ---
	var btn_y = scroll_y + scroll_h + 15
	var btn_w = 160.0

	attack_button = _create_textured_button("ATTACK", Vector2(scroll_x + scroll_w / 2 - btn_w - 15, btn_y), Vector2(btn_w, 40))
	attack_button.pressed.connect(_on_attack)
	add_child(attack_button)

	cancel_button = _create_textured_button("CANCEL", Vector2(scroll_x + scroll_w / 2 + 15, btn_y), Vector2(btn_w, 40))
	cancel_button.pressed.connect(_on_cancel)
	add_child(cancel_button)


func _create_textured_button(text: String, pos: Vector2, btn_size: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.size = btn_size
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.45, 0.3, 0.1))
	btn.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	btn.add_theme_constant_override("outline_size", 1)

	var btn_tex = load(FORECAST_BTN_PATH)
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


func _on_attack():
	_cleanup()
	attack_confirmed.emit()


func _on_cancel():
	_cleanup()
	attack_cancelled.emit()


func _cleanup():
	for child in get_children():
		child.queue_free()
