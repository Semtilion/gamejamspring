extends CanvasLayer

# ============================================================
#  TUTORIAL OVERLAY — Multi-page
# ============================================================
#  Shows all tips as pages on the scroll sprite.
#  Player navigates with Back/Next buttons.

signal dismissed()

const SCROLL_PATH = "res://assets/scroll.png"
const FORECAST_BTN_PATH = "res://assets/forecast_button.png"

var pages = []
var current_page := 0

var tip_label: Label
var page_label: Label
var back_button: Button
var next_button: Button


func show_tips(messages: Array):
	pages = messages
	current_page = 0
	_build_ui()
	_update_page()


func _build_ui():
	# Semi-transparent overlay
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.35)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)

	# Scroll background
	var scroll_w = 620.0
	var scroll_h = 300.0
	var scroll_x = 420.0
	var scroll_y = 180.0

	var scroll_tex = load(SCROLL_PATH)
	if scroll_tex:
		var scroll = TextureRect.new()
		scroll.texture = scroll_tex
		scroll.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		scroll.stretch_mode = TextureRect.STRETCH_SCALE
		scroll.position = Vector2(scroll_x, scroll_y)
		scroll.size = Vector2(scroll_w, scroll_h)
		add_child(scroll)

	# Content area
	var cx = scroll_x + 70
	var cy = scroll_y + 45
	var cw = scroll_w - 140

	# Title on top of scroll
	var title = Label.new()
	title.text = "GUIDE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(cx, scroll_y + 50)
	title.size = Vector2(cw, 25)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.45, 0.3, 0.1))
	add_child(title)

	# Tip text
	tip_label = Label.new()
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_label.position = Vector2(cx + 10, cy + 45)
	tip_label.size = Vector2(cw, 120)
	tip_label.add_theme_font_size_override("font_size", 15)
	tip_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1))
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(tip_label)

	# Page indicator
	page_label = Label.new()
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.position = Vector2(cx, scroll_y + scroll_h - 80)
	page_label.size = Vector2(cw, 20)
	page_label.add_theme_font_size_override("font_size", 12)
	page_label.add_theme_color_override("font_color", Color(0.45, 0.35, 0.2))
	add_child(page_label)

	# Back button
	back_button = _create_textured_button("< BACK", Vector2(cx, scroll_y + scroll_h - 75), Vector2(cw / 2 - 10, 28))
	back_button.pressed.connect(_on_back)
	add_child(back_button)

	# Next button
	next_button = _create_textured_button("NEXT >", Vector2(cx + cw / 2 + 10, scroll_y + scroll_h - 75), Vector2(cw / 2 - 10, 28))
	next_button.pressed.connect(_on_next)
	add_child(next_button)

	# Close button
	var close_button = _create_textured_button("CLOSE", Vector2(cx + cw / 4 - 40, scroll_y + scroll_h - 42), Vector2(cw / 2, 28))
	close_button.pressed.connect(_on_close)
	add_child(close_button)


func _create_textured_button(text: String, pos: Vector2, btn_size: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.position = pos
	btn.size = btn_size
	btn.add_theme_font_size_override("font_size", 13)
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


func _update_page():
	tip_label.text = pages[current_page]
	page_label.text = "%d / %d" % [current_page + 1, pages.size()]

	back_button.disabled = current_page == 0
	next_button.disabled = current_page >= pages.size() - 1


func _on_back():
	if current_page > 0:
		current_page -= 1
		_update_page()


func _on_next():
	if current_page < pages.size() - 1:
		current_page += 1
		_update_page()


func _on_close():
	_cleanup()
	dismissed.emit()


func _cleanup():
	for child in get_children():
		child.queue_free()
