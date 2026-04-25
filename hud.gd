extends CanvasLayer

# ============================================================
#  HUD — Top Info Bar
# ============================================================
#  Modular display. Call update_hud() with a dictionary.
#  Add new fields by adding keys to the dictionary and
#  updating _build_text(). Nothing else needs to change.
#
#  Supported keys:
#    "stage_name"   - String
#    "stage_number" - int
#    "turn"         - int
#    "enemies"      - int
#    "phase"        - String ("Player Turn" / "Enemy Turn" / etc)

signal end_turn_pressed()

var panel: Panel
var info_label: Label
var end_turn_button: Button
var current_data = {}


func _ready():
	_build_ui()


func _build_ui():
	# Background bar across the top
	panel = Panel.new()
	panel.position = Vector2(0, 0)
	panel.size = Vector2(1200, 30)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.08, 0.9)
	style.border_width_bottom = 1
	style.border_color = Color(0.5, 0.4, 0.15)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	# Info text
	info_label = Label.new()
	info_label.position = Vector2(12, 4)
	info_label.size = Vector2(900, 24)
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4))
	add_child(info_label)

	# End Turn button (right side of bar)
	end_turn_button = Button.new()
	end_turn_button.text = "END TURN"
	end_turn_button.position = Vector2(1080, 2)
	end_turn_button.size = Vector2(110, 26)
	end_turn_button.add_theme_font_size_override("font_size", 13)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.08, 0.04)
	btn_style.border_width_bottom = 1
	btn_style.border_width_top = 1
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_color = Color(0.5, 0.4, 0.15)
	btn_style.corner_radius_top_left = 3
	btn_style.corner_radius_top_right = 3
	btn_style.corner_radius_bottom_left = 3
	btn_style.corner_radius_bottom_right = 3
	end_turn_button.add_theme_stylebox_override("normal", btn_style)

	var hover_style = btn_style.duplicate()
	hover_style.bg_color = Color(0.22, 0.15, 0.06)
	hover_style.border_color = Color(0.9, 0.75, 0.2)
	end_turn_button.add_theme_stylebox_override("hover", hover_style)

	end_turn_button.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4))
	end_turn_button.pressed.connect(_on_end_turn)
	end_turn_button.disabled = true
	add_child(end_turn_button)


func update_hud(data: Dictionary):
	current_data.merge(data, true)
	info_label.text = _build_text()

	# Enable End Turn button only during player phase
	if current_data.has("phase"):
		end_turn_button.disabled = current_data["phase"] != "Player Turn"


func _build_text() -> String:
	var parts = []

	if current_data.has("stage_name") and current_data.has("stage_number"):
		parts.append("Stage %d: %s" % [current_data["stage_number"], current_data["stage_name"]])

	if current_data.has("turn"):
		parts.append("Turn %d" % current_data["turn"])

	if current_data.has("enemies"):
		parts.append("Enemies: %d" % current_data["enemies"])

	if current_data.has("phase"):
		parts.append(current_data["phase"])

	return "   |   ".join(parts)


func _on_end_turn():
	end_turn_pressed.emit()


# Convenience: resize bar width if grid changes
func set_width(w: float):
	panel.size.x = w
	info_label.size.x = w - 200
	end_turn_button.position.x = w - 120
