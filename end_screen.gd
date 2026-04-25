extends CanvasLayer

signal restart_game()
signal return_to_menu()

var is_victory := false

const GAME_OVER_BG_PATH = "res://assets/game_over.png"
const BTN_PATH = "res://assets/menu_button.png"
const VICTORY_FRAME_COUNT := 22
const VICTORY_FPS := 10.0

# Victory animation
var victory_frames = []
var victory_rect: TextureRect
var victory_frame_index := 0
var victory_timer := 0.0


func setup_game_over():
	is_victory = false
	_build_ui()


func setup_victory():
	is_victory = true
	_load_victory_frames()
	_build_ui()


func _load_victory_frames():
	for i in range(VICTORY_FRAME_COUNT):
		var tex = load("res://assets/victory_anim/victory_bg_%d.png" % i)
		if tex:
			victory_frames.append(tex)


func _process(delta):
	if not is_victory or victory_frames.size() == 0:
		return
	victory_timer += delta
	if victory_timer >= 1.0 / VICTORY_FPS:
		victory_timer -= 1.0 / VICTORY_FPS
		victory_frame_index = (victory_frame_index + 1) % victory_frames.size()
		victory_rect.texture = victory_frames[victory_frame_index]


func _build_ui():
	var screen_w = 1460.0
	var screen_h = 675.0
	var center_x = screen_w / 2.0

	if is_victory:
		# Animated victory background
		victory_rect = TextureRect.new()
		victory_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		victory_rect.stretch_mode = TextureRect.STRETCH_SCALE
		victory_rect.position = Vector2(0, 0)
		victory_rect.size = Vector2(screen_w, screen_h)
		if victory_frames.size() > 0:
			victory_rect.texture = victory_frames[0]
		add_child(victory_rect)

		# Dark overlay
		var overlay = ColorRect.new()
		overlay.color = Color(0.0, 0.0, 0.0, 0.3)
		overlay.anchor_right = 1.0
		overlay.anchor_bottom = 1.0
		add_child(overlay)

		_build_victory(center_x)
	else:
		# Dark background
		var overlay = ColorRect.new()
		overlay.color = Color(0.0, 0.0, 0.0, 0.6)
		overlay.anchor_right = 1.0
		overlay.anchor_bottom = 1.0
		add_child(overlay)

		# Game over background image
		var bg_tex = load(GAME_OVER_BG_PATH)
		if bg_tex:
			var bg = TextureRect.new()
			bg.texture = bg_tex
			bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			bg.stretch_mode = TextureRect.STRETCH_SCALE
			bg.size = Vector2(900, 520)
			bg.position = Vector2(center_x - 450, 80)
			add_child(bg)

		_build_game_over(center_x)

	# --- Buttons ---
	var btn_w = 250.0
	var btn_h = 50.0
	var btn_y = 470.0

	var restart_btn = _create_button("PLAY AGAIN", Vector2(center_x - btn_w - 20, btn_y), Vector2(btn_w, btn_h))
	restart_btn.pressed.connect(_on_restart)
	add_child(restart_btn)

	var menu_btn = _create_button("MAIN MENU", Vector2(center_x + 20, btn_y), Vector2(btn_w, btn_h))
	menu_btn.pressed.connect(_on_menu)
	add_child(menu_btn)


func _create_button(text: String, pos: Vector2, btn_size: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.size = btn_size
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.55, 0.4, 0.15))
	btn.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	btn.add_theme_constant_override("outline_size", 1)

	var btn_tex = load(BTN_PATH)
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
		pressed_style.modulate_color = Color(0.75, 0.7, 0.6)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		var focus_style = StyleBoxTexture.new()
		focus_style.texture = btn_tex
		focus_style.modulate_color = Color(1.0, 1.0, 1.0)
		btn.add_theme_stylebox_override("focus", focus_style)

	return btn


func _build_game_over(cx: float):
	var title = Label.new()
	title.text = "THE PHARAOH HAS FALLEN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(cx - 400, 140)
	title.size = Vector2(800, 60)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	title.add_theme_constant_override("outline_size", 3)
	add_child(title)

	var story = Label.new()
	story.text = "Without the Pharaoh's magic, the undead army\ncrumbles to dust. The usurper's reign continues\nunchallenged.\n\nThe sands of time bury another forgotten king.\n\nBut death is not the end...\nnot for one who has risen before."
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.position = Vector2(cx - 400, 220)
	story.size = Vector2(800, 200)
	story.add_theme_font_size_override("font_size", 16)
	story.add_theme_color_override("font_color", Color(0.75, 0.55, 0.5))
	story.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	story.add_theme_constant_override("outline_size", 2)
	add_child(story)


func _build_victory(cx: float):
	var title = Label.new()
	title.text = "THE THRONE IS RECLAIMED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(cx - 400, 140)
	title.size = Vector2(800, 60)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	title.add_theme_constant_override("outline_size", 3)
	add_child(title)

	var story = Label.new()
	story.text = "The usurper kneels before the ancient Pharaoh.\nThe throne room trembles as the rightful ruler\nreclaims his seat of power.\n\nThe undead soldiers stand guard once more.\nThe empire is restored. The Pharaoh reigns eternal.\n\nNone shall disturb his kingdom again."
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.position = Vector2(cx - 400, 220)
	story.size = Vector2(800, 200)
	story.add_theme_font_size_override("font_size", 16)
	story.add_theme_color_override("font_color", Color(0.75, 0.7, 0.45))
	story.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	story.add_theme_constant_override("outline_size", 2)
	add_child(story)


func _on_restart():
	_cleanup()
	restart_game.emit()


func _on_menu():
	_cleanup()
	return_to_menu.emit()


func _cleanup():
	for child in get_children():
		child.queue_free()
