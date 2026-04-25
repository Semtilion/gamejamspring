extends CanvasLayer

signal battle_finished()

var combat_results = []
var attacker_data = {}
var defender_data = {}

var left_hp: int
var left_max_hp: int
var right_hp: int
var right_max_hp: int

var left_name: String
var right_name: String

# UI elements
var bg: TextureRect
var bg_fallback: ColorRect
var left_unit_node: Node  # Sprite2D or ColorRect
var right_unit_node: Node
var left_name_label: Label
var right_name_label: Label
var left_hp_label: Label
var right_hp_label: Label
var left_hp_bar_bg: ColorRect
var left_hp_bar_fill: ColorRect
var right_hp_bar_bg: ColorRect
var right_hp_bar_fill: ColorRect
var bottom_panel: Panel
var left_stats_label: Label
var right_stats_label: Label
var flash_rect: ColorRect

# Combat stats
var left_hit := 0
var left_dmg := 0
var left_crit := 0
var left_avoid := 0
var right_hit := 0
var right_dmg := 0
var right_crit := 0
var right_avoid := 0
var right_can_counter := false

# Animation
var current_step := 0
const ATTACK_PAUSE := 0.5
const FLASH_DURATION := 0.12
const RESULT_PAUSE := 0.7
const END_PAUSE := 0.8

# Splash art paths
const SPLASH_PATHS = {
	-1: "res://assets/pharohsplash-Recovered.png",
	0:  "res://assets/bastetsplash.png",
	1:  "res://assets/nasussplash.png",
	2:  "res://assets/renektonsplash.png",
	3:  "res://assets/falconsplash.png",
}
const BG_PATH = "res://assets/fightbg.png"
const SPLASH_SCALE := 3.0
const SLASH_FRAME_COUNT := 8
const SLASH_FPS := 16.0

# Preloaded slash frames
var slash_frames: SpriteFrames

# Battle animation data: key -> { "frames": [paths], "fps": float }
const BATTLE_ANIM_DATA = {
	-1: {
		"frames": [
			"res://assets/battle_anim/pharaoh_battle_0.png",
			"res://assets/battle_anim/pharaoh_battle_1.png",
			"res://assets/battle_anim/pharaoh_battle_2.png",
			"res://assets/battle_anim/pharaoh_battle_3.png",
			"res://assets/battle_anim/pharaoh_battle_4.png",
			"res://assets/battle_anim/pharaoh_battle_5.png",
			"res://assets/battle_anim/pharaoh_battle_6.png",
			"res://assets/battle_anim/pharaoh_battle_7.png",
			"res://assets/battle_anim/pharaoh_battle_8.png",
			"res://assets/battle_anim/pharaoh_battle_9.png",
			"res://assets/battle_anim/pharaoh_battle_10.png",
			"res://assets/battle_anim/pharaoh_battle_11.png",
		],
		"fps": 10.0,
	},
	0: {
		"frames": [
			"res://assets/battle_anim/bastet_battle_0.png",
			"res://assets/battle_anim/bastet_battle_1.png",
			"res://assets/battle_anim/bastet_battle_2.png",
			"res://assets/battle_anim/bastet_battle_3.png",
			"res://assets/battle_anim/bastet_battle_4.png",
			"res://assets/battle_anim/bastet_battle_5.png",
			"res://assets/battle_anim/bastet_battle_6.png",
			"res://assets/battle_anim/bastet_battle_7.png",
			"res://assets/battle_anim/bastet_battle_8.png",
			"res://assets/battle_anim/bastet_battle_9.png",
			"res://assets/battle_anim/bastet_battle_10.png",
			"res://assets/battle_anim/bastet_battle_11.png",
		],
		"fps": 10.0,
	},
	1: {
		"frames": [
			"res://assets/battle_anim/nasus_battle_0.png",
			"res://assets/battle_anim/nasus_battle_1.png",
			"res://assets/battle_anim/nasus_battle_2.png",
			"res://assets/battle_anim/nasus_battle_3.png",
			"res://assets/battle_anim/nasus_battle_4.png",
			"res://assets/battle_anim/nasus_battle_5.png",
			"res://assets/battle_anim/nasus_battle_6.png",
			"res://assets/battle_anim/nasus_battle_7.png",
			"res://assets/battle_anim/nasus_battle_8.png",
			"res://assets/battle_anim/nasus_battle_9.png",
			"res://assets/battle_anim/nasus_battle_10.png",
			"res://assets/battle_anim/nasus_battle_11.png",
		],
		"fps": 10.0,
	},
	2: {
		"frames": [
			"res://assets/battle_anim/renekton_battle_0.png",
			"res://assets/battle_anim/renekton_battle_1.png",
			"res://assets/battle_anim/renekton_battle_2.png",
			"res://assets/battle_anim/renekton_battle_3.png",
			"res://assets/battle_anim/renekton_battle_4.png",
			"res://assets/battle_anim/renekton_battle_5.png",
			"res://assets/battle_anim/renekton_battle_6.png",
			"res://assets/battle_anim/renekton_battle_7.png",
			"res://assets/battle_anim/renekton_battle_8.png",
			"res://assets/battle_anim/renekton_battle_9.png",
			"res://assets/battle_anim/renekton_battle_10.png",
			"res://assets/battle_anim/renekton_battle_11.png",
		],
		"fps": 10.0,
	},
	3: {
		"frames": [
			"res://assets/battle_anim/falcon_battle_0.png",
			"res://assets/battle_anim/falcon_battle_1.png",
			"res://assets/battle_anim/falcon_battle_2.png",
			"res://assets/battle_anim/falcon_battle_3.png",
			"res://assets/battle_anim/falcon_battle_4.png",
			"res://assets/battle_anim/falcon_battle_5.png",
			"res://assets/battle_anim/falcon_battle_6.png",
			"res://assets/battle_anim/falcon_battle_7.png",
			"res://assets/battle_anim/falcon_battle_8.png",
			"res://assets/battle_anim/falcon_battle_9.png",
			"res://assets/battle_anim/falcon_battle_10.png",
			"res://assets/battle_anim/falcon_battle_11.png",
		],
		"fps": 10.0,
	},
}

# Evade sprite paths
const EVADE_PATHS = {
	-1: "res://assets/pharaoh_evade.png",
	0:  "res://assets/bastet_evade.png",
	1:  "res://assets/nasus_evade.png",
	2:  "res://assets/renekton_evade.png",
	3:  "res://assets/falcon_evade.png",
}

# Evade sprites (preloaded during setup)
var left_evade_node: Sprite2D
var right_evade_node: Sprite2D


func setup(atk_unit: Node2D, def_unit: Node2D, results: Array, combat_node: Node):
	combat_results = results

	var weapon_names = {-1: "None", 0: "Sword", 1: "Axe", 2: "Lance", 3: "Bow"}

	attacker_data = {
		"name": atk_unit.unit_name,
		"color": atk_unit.unit_color,
		"weapon_name": weapon_names.get(atk_unit.weapon, "???"),
		"weapon": atk_unit.weapon,
		"team": atk_unit.team,
		"is_emperor": atk_unit.is_emperor,
	}
	defender_data = {
		"name": def_unit.unit_name,
		"color": def_unit.unit_color,
		"weapon_name": weapon_names.get(def_unit.weapon, "???"),
		"weapon": def_unit.weapon,
		"team": def_unit.team,
		"is_emperor": def_unit.is_emperor,
	}

	left_name = atk_unit.unit_name
	right_name = def_unit.unit_name

	left_hit = combat_node.calc_hit_rate(atk_unit, def_unit)
	left_dmg = combat_node.calc_damage(atk_unit, def_unit)
	left_crit = combat_node.calc_crit_rate(atk_unit, def_unit)
	left_avoid = (atk_unit.spd * 2) + atk_unit.lck

	right_can_counter = false
	if def_unit.weapon >= 0:
		for entry in results:
			if entry["attacker"] == right_name:
				right_can_counter = true
				break

	if right_can_counter:
		right_hit = combat_node.calc_hit_rate(def_unit, atk_unit)
		right_dmg = combat_node.calc_damage(def_unit, atk_unit)
		right_crit = combat_node.calc_crit_rate(def_unit, atk_unit)
	right_avoid = (def_unit.spd * 2) + def_unit.lck

	if results.size() > 0:
		var first = results[0]
		if first["attacker"] == left_name:
			right_max_hp = first["target_max_hp"]
			right_hp = first["target_hp"] + first["damage"]
			left_max_hp = atk_unit.max_hp
			left_hp = atk_unit.hp
			for entry in results:
				if entry["target"] == left_name and entry["hit"]:
					left_hp = entry["target_hp"] + entry["damage"]
					break
		else:
			left_max_hp = atk_unit.max_hp
			left_hp = atk_unit.hp
			right_max_hp = def_unit.max_hp
			right_hp = def_unit.hp

	# Preload slash animation
	slash_frames = SpriteFrames.new()
	slash_frames.add_animation("slash")
	slash_frames.set_animation_speed("slash", SLASH_FPS)
	slash_frames.set_animation_loop("slash", false)
	for i in range(SLASH_FRAME_COUNT):
		var tex = load("res://assets/slash_anim/slash_%d.png" % i)
		if tex:
			slash_frames.add_frame("slash", tex, 1.0, i)
	if slash_frames.has_animation("default"):
		slash_frames.remove_animation("default")

	_build_ui()

	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(_start_sequence)


func _get_splash_key(data: Dictionary) -> int:
	if data["is_emperor"]:
		return -1
	return data["weapon"]


func _create_unit_visual(data: Dictionary, pos: Vector2, flip: bool, is_right_side: bool) -> Node:
	var key = _get_splash_key(data)

	# Try animated battle sprite first
	if BATTLE_ANIM_DATA.has(key):
		var anim_info = BATTLE_ANIM_DATA[key]
		var frames = SpriteFrames.new()
		frames.add_animation("idle")
		frames.set_animation_speed("idle", anim_info["fps"])
		frames.set_animation_loop("idle", true)

		var all_loaded = true
		for i in range(anim_info["frames"].size()):
			var tex = load(anim_info["frames"][i])
			if tex:
				frames.add_frame("idle", tex, 1.0, i)
			else:
				all_loaded = false
				break

		if all_loaded:
			if frames.has_animation("default"):
				frames.remove_animation("default")
			var anim_sprite = AnimatedSprite2D.new()
			anim_sprite.sprite_frames = frames
			anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			anim_sprite.scale = Vector2(-SPLASH_SCALE if flip else SPLASH_SCALE, SPLASH_SCALE)
			anim_sprite.position = pos
			if data["team"] == "enemy":
				anim_sprite.modulate = Color(1.0, 0.6, 0.6)
			add_child(anim_sprite)
			anim_sprite.play("idle")
			return anim_sprite

	# Fall back to static splash
	if SPLASH_PATHS.has(key):
		var tex = load(SPLASH_PATHS[key])
		if tex:
			var sprite = Sprite2D.new()
			sprite.texture = tex
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.scale = Vector2(-SPLASH_SCALE if flip else SPLASH_SCALE, SPLASH_SCALE)
			sprite.position = pos
			if data["team"] == "enemy":
				sprite.modulate = Color(1.0, 0.6, 0.6)
			add_child(sprite)
			return sprite

	# Fallback: colored square
	var rect = ColorRect.new()
	rect.color = data["color"]
	if data["team"] == "enemy":
		rect.color = Color(0.9, 0.3, 0.3)
	rect.size = Vector2(90, 90)
	rect.position = Vector2(pos.x - 45, pos.y - 45)
	add_child(rect)
	return rect


func _build_ui():
	# Background image
	var bg_tex = load(BG_PATH)
	if bg_tex:
		bg = TextureRect.new()
		bg.texture = bg_tex
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.position = Vector2(0, 0)
		bg.size = Vector2(1460, 535)
		add_child(bg)
	else:
		bg_fallback = ColorRect.new()
		bg_fallback.color = Color(0.03, 0.02, 0.05)
		bg_fallback.anchor_right = 1.0
		bg_fallback.anchor_bottom = 1.0
		add_child(bg_fallback)

	# --- LEFT NAME (top-left) ---
	left_name_label = Label.new()
	left_name_label.text = "%s  [%s]" % [attacker_data["name"], attacker_data["weapon_name"]]
	left_name_label.position = Vector2(20, 15)
	left_name_label.add_theme_font_size_override("font_size", 22)
	left_name_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	left_name_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	left_name_label.add_theme_constant_override("outline_size", 2)
	add_child(left_name_label)

	left_hp_label = Label.new()
	left_hp_label.position = Vector2(20, 45)
	left_hp_label.add_theme_font_size_override("font_size", 15)
	left_hp_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	left_hp_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	left_hp_label.add_theme_constant_override("outline_size", 2)
	add_child(left_hp_label)

	# Left HP bar (textured)
	# Left HP bar (outline + bg + fill)
	var left_hp_outline = ColorRect.new()
	left_hp_outline.color = Color(0.0, 0.0, 0.0)
	left_hp_outline.position = Vector2(18, 68)
	left_hp_outline.size = Vector2(184, 12)
	add_child(left_hp_outline)

	left_hp_bar_bg = ColorRect.new()
	left_hp_bar_bg.color = Color(0.2, 0.0, 0.0)
	left_hp_bar_bg.position = Vector2(20, 70)
	left_hp_bar_bg.size = Vector2(180, 8)
	add_child(left_hp_bar_bg)

	left_hp_bar_fill = ColorRect.new()
	left_hp_bar_fill.position = Vector2(20, 70)
	left_hp_bar_fill.size = Vector2(180, 8)
	add_child(left_hp_bar_fill)

	# --- RIGHT NAME (top-right) ---
	right_name_label = Label.new()
	right_name_label.text = "[%s]  %s" % [defender_data["weapon_name"], defender_data["name"]]
	right_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_name_label.position = Vector2(1250, 15)
	right_name_label.size = Vector2(190, 30)
	right_name_label.add_theme_font_size_override("font_size", 22)
	right_name_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	right_name_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	right_name_label.add_theme_constant_override("outline_size", 2)
	add_child(right_name_label)

	right_hp_label = Label.new()
	right_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_hp_label.position = Vector2(1250, 45)
	right_hp_label.size = Vector2(190, 20)
	right_hp_label.add_theme_font_size_override("font_size", 15)
	right_hp_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	right_hp_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	right_hp_label.add_theme_constant_override("outline_size", 2)
	add_child(right_hp_label)

	# Right HP bar (outline + bg + fill, right-aligned)
	var right_hp_outline = ColorRect.new()
	right_hp_outline.color = Color(0.0, 0.0, 0.0)
	right_hp_outline.position = Vector2(1258, 68)
	right_hp_outline.size = Vector2(184, 12)
	add_child(right_hp_outline)

	right_hp_bar_bg = ColorRect.new()
	right_hp_bar_bg.color = Color(0.2, 0.0, 0.0)
	right_hp_bar_bg.position = Vector2(1260, 70)
	right_hp_bar_bg.size = Vector2(180, 8)
	add_child(right_hp_bar_bg)

	right_hp_bar_fill = ColorRect.new()
	right_hp_bar_fill.position = Vector2(1260, 70)
	right_hp_bar_fill.size = Vector2(180, 8)
	add_child(right_hp_bar_fill)

	# --- UNIT VISUALS ---
	# Left unit: centered at left area, facing right
	left_unit_node = _create_unit_visual(attacker_data, Vector2(300, 320), false, false)

	# Right unit: centered at right area, flipped to face left
	right_unit_node = _create_unit_visual(defender_data, Vector2(1160, 320), true, true)

	# --- EVADE SPRITES (hidden until miss) ---
	var left_key = _get_splash_key(attacker_data)
	if EVADE_PATHS.has(left_key):
		var tex = load(EVADE_PATHS[left_key])
		if tex:
			left_evade_node = Sprite2D.new()
			left_evade_node.texture = tex
			left_evade_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			left_evade_node.scale = Vector2(SPLASH_SCALE, SPLASH_SCALE)
			left_evade_node.position = Vector2(300, 320)
			if attacker_data["team"] == "enemy":
				left_evade_node.modulate = Color(1.0, 0.6, 0.6)
			left_evade_node.visible = false
			add_child(left_evade_node)

	var right_key = _get_splash_key(defender_data)
	if EVADE_PATHS.has(right_key):
		var tex = load(EVADE_PATHS[right_key])
		if tex:
			right_evade_node = Sprite2D.new()
			right_evade_node.texture = tex
			right_evade_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			right_evade_node.scale = Vector2(-SPLASH_SCALE, SPLASH_SCALE)
			right_evade_node.position = Vector2(1160, 320)
			if defender_data["team"] == "enemy":
				right_evade_node.modulate = Color(1.0, 0.6, 0.6)
			right_evade_node.visible = false
			add_child(right_evade_node)

	# --- BOTTOM PANEL ---
	bottom_panel = Panel.new()
	bottom_panel.position = Vector2(0, 535)
	bottom_panel.size = Vector2(1460, 140)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.04, 0.08, 0.95)
	panel_style.border_width_top = 2
	panel_style.border_color = Color(0.5, 0.4, 0.15)
	bottom_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(bottom_panel)

	# Left stats in bottom panel
	left_stats_label = Label.new()
	left_stats_label.position = Vector2(60, 550)
	left_stats_label.size = Vector2(200, 110)
	left_stats_label.add_theme_font_size_override("font_size", 17)
	left_stats_label.add_theme_color_override("font_color", Color(0.6, 0.75, 1.0))
	left_stats_label.text = "%s\nDMG: %d    HIT: %d%%\nCRT: %d%%    AVO: %d" % [
		attacker_data["name"], left_dmg, left_hit, left_crit, left_avoid]
	add_child(left_stats_label)

	# Right stats in bottom panel
	right_stats_label = Label.new()
	right_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_stats_label.position = Vector2(1200, 550)
	right_stats_label.size = Vector2(200, 110)
	right_stats_label.add_theme_font_size_override("font_size", 17)
	right_stats_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	if right_can_counter:
		right_stats_label.text = "%s\nDMG: %d    HIT: %d%%\nCRT: %d%%    AVO: %d" % [
			defender_data["name"], right_dmg, right_hit, right_crit, right_avoid]
	else:
		right_stats_label.text = "%s\nCannot counter\nAVO: %d" % [
			defender_data["name"], right_avoid]
	add_child(right_stats_label)

	# --- WHITE FLASH ---
	flash_rect = ColorRect.new()
	flash_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	flash_rect.anchor_right = 1.0
	flash_rect.anchor_bottom = 1.0
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_rect)

	_update_hp_display()


func _update_hp_display():
	left_hp_label.text = "HP: %d / %d" % [left_hp, left_max_hp]
	right_hp_label.text = "HP: %d / %d" % [right_hp, right_max_hp]

	var bar_width = 180.0
	var left_ratio = float(left_hp) / float(left_max_hp) if left_max_hp > 0 else 0
	var right_ratio = float(right_hp) / float(right_max_hp) if right_max_hp > 0 else 0

	left_hp_bar_fill.size.x = bar_width * left_ratio
	left_hp_bar_fill.color = _hp_color(left_ratio)

	# Right bar fills from right to left
	var right_fill_w = bar_width * right_ratio
	right_hp_bar_fill.size.x = right_fill_w
	right_hp_bar_fill.position.x = right_hp_bar_bg.position.x + bar_width - right_fill_w
	right_hp_bar_fill.color = _hp_color(right_ratio)


func _hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.0, 0.8, 0.0)
	elif ratio > 0.25:
		return Color(0.9, 0.7, 0.0)
	else:
		return Color(0.9, 0.1, 0.1)


# ============================================================
#  ATTACK SEQUENCE
# ============================================================

func _start_sequence():
	current_step = 0
	_play_next_attack()


func _play_next_attack():
	if current_step >= combat_results.size():
		var timer = get_tree().create_timer(END_PAUSE)
		timer.timeout.connect(_finish)
		return

	var entry = combat_results[current_step]
	var is_left_attacking = (entry["attacker"] == left_name)

	var tween = create_tween()
	tween.tween_interval(ATTACK_PAUSE)
	tween.tween_callback(_show_attack_result.bind(entry, is_left_attacking))
	tween.tween_interval(RESULT_PAUSE)
	tween.tween_callback(func():
		current_step += 1
		_play_next_attack()
	)


func _show_attack_result(entry: Dictionary, is_left_attacking: bool):
	var defender_node = right_unit_node if is_left_attacking else left_unit_node

	# Slash visual plays on every attack
	_do_slash(defender_node, is_left_attacking)

	if entry["hit"]:
		_do_flash()
		_do_shake(defender_node)
		SFX.play("hit")

		if is_left_attacking:
			right_hp = entry["target_hp"]
		else:
			left_hp = entry["target_hp"]
		_update_hp_display()

		if entry["target_hp"] <= 0:
			_do_defeat(defender_node)
	else:
		_do_evade(defender_node, is_left_attacking)
		_do_miss_text(defender_node)
		SFX.play("miss")


func _do_flash():
	flash_rect.color = Color(1.0, 1.0, 1.0, 0.7)
	var tween = create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, FLASH_DURATION)


func _do_shake(node: Node):
	# Works for both Sprite2D (position) and ColorRect (position)
	var orig_x = node.position.x
	var tween = create_tween()
	tween.tween_property(node, "position:x", orig_x + 12, 0.04)
	tween.tween_property(node, "position:x", orig_x - 12, 0.04)
	tween.tween_property(node, "position:x", orig_x + 8, 0.04)
	tween.tween_property(node, "position:x", orig_x - 8, 0.04)
	tween.tween_property(node, "position:x", orig_x, 0.04)


func _do_defeat(node: Node):
	var tween = create_tween()
	tween.tween_property(node, "modulate:a", 0.0, 0.5)


func _do_slash(defender_node: Node, is_left_attacking: bool):
	if not slash_frames:
		return
	var slash = AnimatedSprite2D.new()
	slash.sprite_frames = slash_frames
	slash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Flip horizontally when right side attacks left
	# Flip horizontally when right side attacks left
	slash.scale = Vector2(4.0 if is_left_attacking else -4.0, 4.0)
	# Offset slash toward the attacker
	var offset_x = -80 if is_left_attacking else 80
	slash.position = Vector2(defender_node.position.x + offset_x, defender_node.position.y)
	slash.z_index = 10
	add_child(slash)
	slash.play("slash")
	slash.animation_finished.connect(slash.queue_free)


func _do_evade(defender_node: Node, is_left_attacking: bool):
	var evade_node = right_evade_node if is_left_attacking else left_evade_node
	if not evade_node:
		return

	var orig_x = defender_node.position.x
	# Backstep direction: away from attacker
	var backstep = 60 if is_left_attacking else -60

	# Swap to evade sprite
	defender_node.visible = false
	evade_node.position = defender_node.position
	evade_node.visible = true

	# Backstep then return
	var tween = create_tween()
	tween.tween_property(evade_node, "position:x", orig_x + backstep, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(0.15)
	tween.tween_property(evade_node, "position:x", orig_x, 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		evade_node.visible = false
		defender_node.visible = true
	)


func _do_miss_text(defender_node: Node):
	var miss = Label.new()
	miss.text = "MISS"
	miss.add_theme_font_size_override("font_size", 28)
	miss.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	miss.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	miss.add_theme_constant_override("outline_size", 4)
	miss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	miss.size = Vector2(120, 40)
	miss.position = Vector2(defender_node.position.x - 60, defender_node.position.y - 110)
	add_child(miss)

	var tween = create_tween()
	# Bounce up
	tween.tween_property(miss, "position:y", miss.position.y - 40, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Fall back slightly
	tween.tween_property(miss, "position:y", miss.position.y - 25, 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BOUNCE)
	# Fade out
	tween.tween_property(miss, "modulate:a", 0.0, 0.3)
	tween.tween_callback(miss.queue_free)


func _finish():
	battle_finished.emit()


func _cleanup():
	for child in get_children():
		child.queue_free()
