extends CanvasLayer

signal start_game()

const MENU_BTN_PATH = "res://assets/menu_button.png"
const BG_FRAME_COUNT := 10
const BG_FPS := 7.7

# Background animation
var bg_frames = []
var bg_rect: TextureRect
var bg_frame_index := 0
var bg_timer := 0.0

# Settings panel
var settings_panel: Control
var volume_slider: HSlider
var volume_label: Label
var settings_visible := false


func _ready():
	for i in range(BG_FRAME_COUNT):
		var tex = load("res://assets/menu_anim/menu_bg_%d.png" % i)
		if tex:
			bg_frames.append(tex)
	_build_ui()


func _process(delta):
	if bg_frames.size() == 0:
		return
	bg_timer += delta
	if bg_timer >= 1.0 / BG_FPS:
		bg_timer -= 1.0 / BG_FPS
		bg_frame_index = (bg_frame_index + 1) % bg_frames.size()
		bg_rect.texture = bg_frames[bg_frame_index]


func _build_ui():
	var screen_w = 1460.0
	var screen_h = 675.0
	var center_x = screen_w / 2.0

	# Animated background
	bg_rect = TextureRect.new()
	bg_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	bg_rect.position = Vector2(0, 0)
	bg_rect.size = Vector2(screen_w, screen_h)
	if bg_frames.size() > 0:
		bg_rect.texture = bg_frames[0]
	add_child(bg_rect)

	# Dark overlay for readability
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.35)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)

	# Game title
	var title = Label.new()
	title.text = "RISE OF THE PHARAOH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(center_x - 400, 80)
	title.size = Vector2(800, 60)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	title.add_theme_constant_override("outline_size", 4)
	add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "A Tactical RPG"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(center_x - 400, 135)
	subtitle.size = Vector2(800, 30)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	subtitle.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	subtitle.add_theme_constant_override("outline_size", 2)
	add_child(subtitle)

	# Story text
	var story = Label.new()
	story.text = "An ancient Pharaoh awakens from his eternal slumber\nto find his empire conquered by a false emperor.\n\nFueled by vengeance, he calls upon forbidden magic\nto raise his fallen soldiers from the dead.\n\nReclaim the throne. Command the undead.\nLet none stand in your way."
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.position = Vector2(center_x - 400, 190)
	story.size = Vector2(800, 180)
	story.add_theme_font_size_override("font_size", 16)
	story.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	story.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	story.add_theme_constant_override("outline_size", 2)
	add_child(story)

	# --- Buttons ---
	var btn_w = 300.0
	var btn_h = 50.0
	var btn_x = center_x - btn_w / 2.0
	var btn_start_y = 410.0
	var btn_gap = 58.0

	var start_btn = _create_button("BEGIN YOUR CONQUEST", Vector2(btn_x, btn_start_y), Vector2(btn_w, btn_h), 20)
	start_btn.pressed.connect(_on_start)
	add_child(start_btn)

	var settings_btn = _create_button("SETTINGS", Vector2(btn_x, btn_start_y + btn_gap), Vector2(btn_w, btn_h), 18)
	settings_btn.pressed.connect(_on_settings)
	add_child(settings_btn)

	var quit_btn = _create_button("QUIT", Vector2(btn_x, btn_start_y + btn_gap * 2), Vector2(btn_w, btn_h), 18)
	quit_btn.pressed.connect(_on_quit)
	add_child(quit_btn)

	_build_settings_panel(center_x)


func _create_button(text: String, pos: Vector2, btn_size: Vector2, font_size: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.size = btn_size
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", Color(0.55, 0.4, 0.15))
	btn.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	btn.add_theme_constant_override("outline_size", 1)

	var btn_tex = load(MENU_BTN_PATH)
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


func _build_settings_panel(cx: float):
	settings_panel = Control.new()
	settings_panel.visible = false
	add_child(settings_panel)

	var backdrop = ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.7)
	backdrop.position = Vector2(cx - 200, 250)
	backdrop.size = Vector2(400, 180)
	settings_panel.add_child(backdrop)

	var border = ColorRect.new()
	border.color = Color(0.7, 0.55, 0.15)
	border.position = Vector2(cx - 202, 248)
	border.size = Vector2(404, 184)
	border.z_index = -1
	settings_panel.add_child(border)

	var title = Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(cx - 150, 260)
	title.size = Vector2(300, 30)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
	settings_panel.add_child(title)

	volume_label = Label.new()
	volume_label.text = "Volume: 100%"
	volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	volume_label.position = Vector2(cx - 150, 300)
	volume_label.size = Vector2(300, 25)
	volume_label.add_theme_font_size_override("font_size", 16)
	volume_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	settings_panel.add_child(volume_label)

	volume_slider = HSlider.new()
	volume_slider.position = Vector2(cx - 140, 330)
	volume_slider.size = Vector2(280, 30)
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	volume_slider.value_changed.connect(_on_volume_changed)
	settings_panel.add_child(volume_slider)

	var close_btn = _create_button("CLOSE", Vector2(cx - 75, 375), Vector2(150, 40), 16)
	close_btn.pressed.connect(_on_settings_close)
	settings_panel.add_child(close_btn)


func _on_volume_changed(value: float):
	if value <= 0.01:
		AudioServer.set_bus_volume_db(0, -80)
	else:
		AudioServer.set_bus_volume_db(0, linear_to_db(value))
	volume_label.text = "Volume: %d%%" % int(value * 100)


func _on_start():
	start_game.emit()
	queue_free()


func _on_settings():
	settings_visible = not settings_visible
	settings_panel.visible = settings_visible


func _on_settings_close():
	settings_visible = false
	settings_panel.visible = false


func _on_quit():
	get_tree().quit()
