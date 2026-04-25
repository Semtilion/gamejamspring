extends Node2D

# ============================================================
#  UNIT
# ============================================================

@export var unit_name := "Soldier"
@export var unit_color := Color(0.2, 0.5, 1.0)

# Combat stats
var max_hp := 20
var hp := 20
var str_ := 6
var skl := 5
var spd := 5
var def_ := 4
var lck := 3

# Weapon (0=SWORD, 1=AXE, 2=LANCE, 3=BOW, -1=NONE)
var weapon: int = 0

# Movement
@export var move_range := 3

# Grid position
var grid_pos := Vector2i(0, 0)
var is_selected := false

# Team
var team := "player"
var has_acted := false

# Emperor
var is_emperor := false
var mana := 0
var max_mana := 0

# Boss/special
var stationary := false
var is_boss := false

# Sprite
var sprite_node: Node2D = null  # Sprite2D or AnimatedSprite2D
var has_sprite := false
var sprite_initialized := false

# Static sprite paths (fallback if no animation exists)
static var sprite_paths = {
	-1: "res://assets/pharohchibi-Recovered.png",
	0:  "res://assets/bastedchibi-Recovered.png",
	1:  "res://assets/nasuschibi-Recovered.png",
	2:  "res://assets/renektonchibi-Recovered.png",
	3:  "res://assets/falconchibi-Recovered.png",
}

# Animated sprite data: key -> { "frames": [paths], "fps": float }
static var anim_data = {
	-1: {
		"frames": [
			"res://assets/anim/pharaoh_idle_0.png",
			"res://assets/anim/pharaoh_idle_1.png",
			"res://assets/anim/pharaoh_idle_2.png",
			"res://assets/anim/pharaoh_idle_3.png",
			"res://assets/anim/pharaoh_idle_4.png",
			"res://assets/anim/pharaoh_idle_5.png",
			"res://assets/anim/pharaoh_idle_6.png",
			"res://assets/anim/pharaoh_idle_7.png",
		],
		"fps": 10.0,
	},
	0: {
		"frames": [
			"res://assets/anim/bastet_idle_0.png",
			"res://assets/anim/bastet_idle_1.png",
			"res://assets/anim/bastet_idle_2.png",
			"res://assets/anim/bastet_idle_3.png",
			"res://assets/anim/bastet_idle_4.png",
			"res://assets/anim/bastet_idle_5.png",
			"res://assets/anim/bastet_idle_6.png",
			"res://assets/anim/bastet_idle_7.png",
		],
		"fps": 10.0,
	},
	1: {
		"frames": [
			"res://assets/anim/nasus_idle_0.png",
			"res://assets/anim/nasus_idle_1.png",
			"res://assets/anim/nasus_idle_2.png",
			"res://assets/anim/nasus_idle_3.png",
			"res://assets/anim/nasus_idle_4.png",
			"res://assets/anim/nasus_idle_5.png",
			"res://assets/anim/nasus_idle_6.png",
			"res://assets/anim/nasus_idle_7.png",
		],
		"fps": 10.0,
	},
	2: {
		"frames": [
			"res://assets/anim/renekton_idle_0.png",
			"res://assets/anim/renekton_idle_1.png",
			"res://assets/anim/renekton_idle_2.png",
			"res://assets/anim/renekton_idle_3.png",
			"res://assets/anim/renekton_idle_4.png",
			"res://assets/anim/renekton_idle_5.png",
			"res://assets/anim/renekton_idle_6.png",
			"res://assets/anim/renekton_idle_7.png",
		],
		"fps": 10.0,
	},
	3: {
		"frames": [
			"res://assets/anim/falcon_idle_0.png",
			"res://assets/anim/falcon_idle_1.png",
			"res://assets/anim/falcon_idle_2.png",
			"res://assets/anim/falcon_idle_3.png",
			"res://assets/anim/falcon_idle_4.png",
			"res://assets/anim/falcon_idle_5.png",
			"res://assets/anim/falcon_idle_6.png",
			"res://assets/anim/falcon_idle_7.png",
		],
		"fps": 10.0,
	},
}

const SPRITE_SCALE := 3.0


func _setup_sprite():
	if sprite_initialized:
		return
	sprite_initialized = true

	var key = -1 if is_emperor else weapon

	# Try animated sprite first
	if anim_data.has(key):
		var data = anim_data[key]
		var frames = SpriteFrames.new()
		frames.add_animation("idle")
		frames.set_animation_speed("idle", data["fps"])
		frames.set_animation_loop("idle", true)

		var all_loaded = true
		for i in range(data["frames"].size()):
			var tex = load(data["frames"][i])
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
			anim_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
			anim_sprite.play("idle")
			add_child(anim_sprite)
			sprite_node = anim_sprite
			has_sprite = true

			if team == "enemy":
				anim_sprite.modulate = Color(1.0, 0.55, 0.55)
			return

	# Fall back to static sprite
	if sprite_paths.has(key):
		var tex = load(sprite_paths[key])
		if tex:
			var sprite = Sprite2D.new()
			sprite.texture = tex
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
			add_child(sprite)
			sprite_node = sprite
			has_sprite = true

			if team == "enemy":
				sprite.modulate = Color(1.0, 0.55, 0.55)
			return

	has_sprite = false


func _draw():
	if not sprite_initialized:
		_setup_sprite()

	var size := 48.0
	var offset := -size / 2.0
	var rect := Rect2(offset, offset, size, size)

	if not has_sprite:
		# Fallback colored square
		var color = unit_color
		if has_acted:
			color = color.darkened(0.5)
		if team == "enemy":
			color = Color(0.9, 0.2, 0.2)
		draw_rect(rect, color)
	else:
		# Dim sprite when acted
		if has_acted:
			sprite_node.modulate = Color(0.5, 0.5, 0.5) if team != "enemy" else Color(0.5, 0.3, 0.3)
		else:
			sprite_node.modulate = Color(1.0, 1.0, 1.0) if team != "enemy" else Color(1.0, 0.55, 0.55)

	# Emperor diamond (on top of sprite)
	if is_emperor and not has_sprite:
		var center = Vector2.ZERO
		var diamond_size = 12.0
		var points = PackedVector2Array([
			center + Vector2(0, -diamond_size),
			center + Vector2(diamond_size, 0),
			center + Vector2(0, diamond_size),
			center + Vector2(-diamond_size, 0),
		])
		draw_colored_polygon(points, Color(1.0, 0.85, 0.2))

	# Selected border
	if is_selected:
		draw_rect(rect, Color.WHITE, false, 3.0)

	# HP bar
	var bar_width := 44.0
	var bar_height := 5.0
	var bar_x := -bar_width / 2.0
	var bar_y := offset + size + 2.0
	draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color(0.2, 0.0, 0.0))

	var fill_ratio = float(hp) / float(max_hp)
	var bar_color = Color(0.0, 0.8, 0.0) if fill_ratio > 0.5 else Color(0.9, 0.7, 0.0) if fill_ratio > 0.25 else Color(0.9, 0.1, 0.1)
	draw_rect(Rect2(bar_x, bar_y, bar_width * fill_ratio, bar_height), bar_color)

	# Mana bar (emperor only)
	if is_emperor and max_mana > 0:
		var mana_y = bar_y + bar_height + 2.0
		draw_rect(Rect2(bar_x, mana_y, bar_width, bar_height), Color(0.1, 0.0, 0.2))
		var mana_ratio = float(mana) / float(max_mana)
		draw_rect(Rect2(bar_x, mana_y, bar_width * mana_ratio, bar_height), Color(0.4, 0.2, 0.9))


func select():
	is_selected = true
	queue_redraw()


func deselect():
	is_selected = false
	queue_redraw()


func is_alive() -> bool:
	return hp > 0
