extends Node2D

# --- References ---
@onready var grid: Node2D = $Grid
@onready var combat: Node = $Combat
@onready var recruit_system: Node = $Recruit
@onready var stage_manager: Node = $StageManager
@onready var hud: CanvasLayer = $HUD

# --- State Machine ---
enum State { DEPLOYING, IDLE, UNIT_SELECTED, UNIT_MOVED, CHOOSING_TARGET, FORECASTING, CHOOSING_REVIVE, ENEMY_TURN, GAME_OVER, VICTORY }
var current_state: State = State.DEPLOYING
var selected_unit: Node2D = null
var original_pos: Vector2i
var attack_target: Node2D = null
var forecast_ui: CanvasLayer = null
var battle_screen: CanvasLayer = null
var pending_combat_log: String = ""
var pending_combat_attacker: Node2D = null
var pending_combat_target: Node2D = null
var is_animating := false
var previewing_enemy: Node2D = null
const MOVE_SPEED := 0.12  # seconds per tile
var turn_count := 1

var units = []

# Persistent roster (carries between stages)
var roster = []

# Starting soldiers (always available)
var starting_roster = [
	{"unit_name": "Khepri", "weapon": 0, "unit_color": Color(0.3, 0.5, 1.0),
	 "move_range": 5, "max_hp": 22, "str_": 7, "skl": 8, "spd": 9, "def_": 4, "lck": 5},
	{"unit_name": "Montu", "weapon": 2, "unit_color": Color(0.2, 0.4, 0.8),
	 "move_range": 3, "max_hp": 28, "str_": 9, "skl": 4, "spd": 3, "def_": 10, "lck": 2},
]

# Death markers
var dead_units = []
var player_lost_unit := false
var defeated_enemies = []  # stores stats of defeated enemies for recruitment

# UI
var combat_log_label: Label
var deploy_ui: CanvasLayer = null
var recruit_ui: CanvasLayer = null

# Unit info card
var unit_card_container: Control
var unit_card_portrait: TextureRect
var unit_card_name: Label
var unit_card_stats: Label
var unit_card_visible := false

# Sidebar
var sidebar_bg: ColorRect
var sidebar_border_left: TextureRect

const PORTRAIT_PATHS = {
	-1: "res://assets/border_pharaoh.png",
	0:  "res://assets/border_bastet.png",
	1:  "res://assets/border_nasus.png",
	2:  "res://assets/border_renekton.png",
	3:  "res://assets/border_falcon.png",
}
const SIDEBAR_BORDER_PATH = "res://assets/border.png"

# Tutorial
var tutorial_messages = []
var tutorial_index := 0
var is_tutorial := false
var tutorial_ui: CanvasLayer = null

# Capture objective
var is_capture_stage := false
var throne_tile: Vector2i = Vector2i(-1, -1)
var boss_defeated := false

# Debug mode
var debug_mode := false
var debug_kill_mode := false
var debug_infinite_move := false
var debug_label: Label = null

# Music
var music_menu: AudioStreamPlayer
var music_overworld: AudioStreamPlayer
var music_battle: AudioStreamPlayer
var music_recruit: AudioStreamPlayer

const MUSIC_PATHS = {
	"menu": "res://assets/music/main_menu.ogg",
	"overworld": "res://assets/music/overworld.ogg",
	"battle": "res://assets/music/battle.ogg",
	"recruit": "res://assets/music/recruit.ogg",
}


var end_screen: CanvasLayer = null

# Transition overlay
var fade_layer: CanvasLayer
var fade_rect: ColorRect
const FADE_DURATION := 0.3

# Phase banner
var banner_layer: CanvasLayer
var banner_label: Label
var banner_bg: ColorRect


func _ready():
	# Offset grid down to make room for HUD bar
	grid.position.y = 32

	# Connect HUD end turn button
	hud.end_turn_pressed.connect(_on_end_turn)

	# Sidebar background (dark, matching HUD bar)
	sidebar_bg = ColorRect.new()
	sidebar_bg.color = Color(0.06, 0.04, 0.08, 0.95)
	add_child(sidebar_bg)

	# Sidebar left border
	var border_tex = load(SIDEBAR_BORDER_PATH)
	if border_tex:
		sidebar_border_left = TextureRect.new()
		sidebar_border_left.texture = border_tex
		sidebar_border_left.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sidebar_border_left.stretch_mode = TextureRect.STRETCH_TILE
		add_child(sidebar_border_left)

	# Create combat log label (hidden until game starts)
	combat_log_label = Label.new()
	combat_log_label.add_theme_font_size_override("font_size", 13)
	combat_log_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	combat_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(combat_log_label)

	# Unit info card (hidden by default)
	unit_card_container = Control.new()
	unit_card_container.visible = false
	add_child(unit_card_container)

	# Portrait with built-in frame (87x74 scaled ~1.7x)
	unit_card_portrait = TextureRect.new()
	unit_card_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	unit_card_portrait.stretch_mode = TextureRect.STRETCH_SCALE
	unit_card_portrait.size = Vector2(148, 126)
	unit_card_portrait.position = Vector2(0, 0)
	unit_card_container.add_child(unit_card_portrait)

	# Unit name + class (right of portrait)
	unit_card_name = Label.new()
	unit_card_name.position = Vector2(155, 10)
	unit_card_name.size = Vector2(135, 90)
	unit_card_name.add_theme_font_size_override("font_size", 18)
	unit_card_name.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	unit_card_container.add_child(unit_card_name)

	# Unit stats (below portrait, full width)
	unit_card_stats = Label.new()
	unit_card_stats.position = Vector2(14, 134)
	unit_card_stats.size = Vector2(270, 120)
	unit_card_stats.add_theme_font_size_override("font_size", 14)
	unit_card_stats.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	unit_card_container.add_child(unit_card_stats)

	# Debug label (bottom-left)
	debug_label = Label.new()
	debug_label.position = Vector2(8, 650)
	debug_label.add_theme_font_size_override("font_size", 12)
	debug_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))
	debug_label.visible = false
	add_child(debug_label)

	# Music players
	music_menu = AudioStreamPlayer.new()
	music_menu.bus = "Master"
	add_child(music_menu)
	var menu_stream = load(MUSIC_PATHS["menu"])
	if menu_stream:
		menu_stream.set("loop", true)
		menu_stream.set("loop_mode", 1)
		music_menu.stream = menu_stream

	music_overworld = AudioStreamPlayer.new()
	music_overworld.bus = "Master"
	add_child(music_overworld)
	var ow_stream = load(MUSIC_PATHS["overworld"])
	if ow_stream:
		ow_stream.set("loop", true)
		ow_stream.set("loop_mode", 1)
		music_overworld.stream = ow_stream

	music_battle = AudioStreamPlayer.new()
	music_battle.bus = "Master"
	add_child(music_battle)
	var battle_stream = load(MUSIC_PATHS["battle"])
	if battle_stream:
		battle_stream.set("loop", true)
		battle_stream.set("loop_mode", 1)
		music_battle.stream = battle_stream

	music_recruit = AudioStreamPlayer.new()
	music_recruit.bus = "Master"
	add_child(music_recruit)
	var recruit_stream = load(MUSIC_PATHS["recruit"])
	if recruit_stream:
		recruit_stream.set("loop", true)
		recruit_stream.set("loop_mode", 1)
		music_recruit.stream = recruit_stream

	# Fade overlay (always on top)
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)

	# Phase banner (high layer, below fade)
	banner_layer = CanvasLayer.new()
	banner_layer.layer = 90
	banner_layer.visible = false
	add_child(banner_layer)

	banner_bg = ColorRect.new()
	banner_bg.color = Color(0.0, 0.0, 0.0, 0.7)
	banner_bg.anchor_right = 1.0
	banner_bg.position = Vector2(0, 280)
	banner_bg.size = Vector2(1460, 80)
	banner_layer.add_child(banner_bg)

	banner_label = Label.new()
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_label.position = Vector2(0, 280)
	banner_label.size = Vector2(1460, 80)
	banner_label.add_theme_font_size_override("font_size", 32)
	banner_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.2))
	banner_layer.add_child(banner_label)

	_show_main_menu()


# ============================================================
#  MAIN MENU
# ============================================================

func _show_main_menu():
	grid.visible = false
	combat_log_label.visible = false
	unit_card_container.visible = false
	sidebar_bg.visible = false
	if sidebar_border_left:
		sidebar_border_left.visible = false
	hud.visible = false
	_play_menu_music()

	var menu = CanvasLayer.new()
	menu.set_script(preload("res://main_menu.gd"))
	add_child(menu)
	menu.start_game.connect(_on_start_game)


func _on_start_game():
	grid.visible = true
	combat_log_label.visible = true
	unit_card_container.visible = false
	hud.visible = true
	music_menu.stop()
	_reset_game()


func _reset_game():
	# Clear everything for a fresh start
	roster.clear()
	for s in starting_roster:
		roster.append(s.duplicate())

	# Reset recruit name pool
	recruit_system.used_names.clear()

	_start_stage(0)


# ============================================================
#  STAGE FLOW
# ============================================================

func _start_stage(stage_index: int):
	stage_manager.current_stage = stage_index
	var data = stage_manager.get_stage_data(stage_index)

	# Reset everything
	_clear_stage()
	turn_count = 1

	# Configure grid
	grid.grid_width = data["grid_width"]
	grid.grid_height = data["grid_height"]
	grid.obstacles = data["obstacles"].duplicate()

	# Position sidebar elements (offset for HUD bar)
	var grid_edge = grid.grid_width * grid.CELL_SIZE
	var sidebar_x = grid_edge + 40
	var sidebar_h = grid.grid_height * grid.CELL_SIZE + 32

	# Sidebar background
	sidebar_bg.position = Vector2(grid_edge - 5, 0)
	sidebar_bg.size = Vector2(325, sidebar_h)
	sidebar_bg.visible = true

	# Border on left edge of sidebar
	if sidebar_border_left:
		sidebar_border_left.position = Vector2(grid_edge - 10, 0)
		sidebar_border_left.size = Vector2(32, sidebar_h)
		sidebar_border_left.visible = true

	unit_card_container.position = Vector2(sidebar_x, 45)
	combat_log_label.position = Vector2(sidebar_x, 320)
	combat_log_label.size = Vector2(270, 260)

	# Update HUD
	var enemy_count = data["enemies"].size()
	hud.set_width(grid_edge + 320)
	hud.update_hud({
		"stage_name": data["name"],
		"stage_number": stage_index + 1,
		"turn": turn_count,
		"enemies": enemy_count,
		"phase": "Deploying",
	})

	# Spawn enemies
	for e in data["enemies"]:
		var hp: int
		var str_val: int
		var skl: int
		var spd: int
		var def_val: int
		var lck: int

		if e.get("randomize", false):
			# Randomize stats based on weapon class
			var stats = recruit_system.generate_enemy_stats(e["weapon"])
			hp = stats["hp"]
			str_val = stats["str"]
			skl = stats["skl"]
			spd = stats["spd"]
			def_val = stats["def"]
			lck = stats["lck"]
		else:
			# Fixed stats (boss)
			hp = e["hp"]
			str_val = e["str"]
			skl = e["skl"]
			spd = e["spd"]
			def_val = e["def"]
			lck = e["lck"]

		_spawn_unit(e["name"], e["pos"], e["move"], Color(0.9, 0.2, 0.2), "enemy",
			e["weapon"], hp, str_val, skl, spd, def_val, lck)
		# Set special flags on the last spawned unit
		var spawned = units[units.size() - 1]
		if e.has("stationary") and e["stationary"]:
			spawned.stationary = true
		if e.has("is_boss") and e["is_boss"]:
			spawned.is_boss = true

	# Capture stage setup
	is_capture_stage = data.get("is_capture_stage", false)
	boss_defeated = false
	if is_capture_stage and data.has("throne_tile"):
		throne_tile = data["throne_tile"]
		grid.throne_tile = throne_tile
	else:
		throne_tile = Vector2i(-1, -1)
		grid.throne_tile = Vector2i(-1, -1)

	# Tutorial setup
	is_tutorial = data["is_tutorial"]
	tutorial_messages = data["tutorial_messages"]
	tutorial_index = 0

	# Show stage intro then deploy
	_reset_stage_music()
	_play_overworld_music()
	_update_log("--- Stage %d: %s ---\n\n%s" % [stage_index + 1, data["name"], data["description"]])

	# Generate bush tiles (max 2, around middle)
	grid.generate_bush_tiles(2)

	grid.queue_redraw()

	# Start deployment phase
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(_start_deployment.bind(data["deploy_center"]))


func _clear_stage():
	# Remove all units
	for unit in units:
		unit.queue_free()
	units.clear()

	# Clear grid state
	grid.obstacles.clear()
	grid.occupied_cells.clear()
	grid.death_markers.clear()
	grid.bush_tiles.clear()
	grid.throne_tile = Vector2i(-1, -1)
	grid.tile_map_generated = false
	grid.clear_highlights()
	grid.queue_redraw()

	# Clear dead units
	dead_units.clear()
	player_lost_unit = false
	defeated_enemies.clear()
	is_animating = false
	is_capture_stage = false
	boss_defeated = false

	# Clean up any open UIs
	if deploy_ui:
		deploy_ui.queue_free()
		deploy_ui = null
	if recruit_ui:
		recruit_ui.queue_free()
		recruit_ui = null
	if forecast_ui:
		forecast_ui.queue_free()
		forecast_ui = null
	if battle_screen:
		battle_screen.queue_free()
		battle_screen = null
	if tutorial_ui:
		tutorial_ui.queue_free()
		tutorial_ui = null

	_clear_unit_card()
	current_state = State.DEPLOYING


# ============================================================
#  DEPLOYMENT PHASE
# ============================================================

var pending_deploy_center: Vector2i

func _start_deployment(deploy_center: Vector2i):
	# Spawn emperor in center
	_spawn_emperor("Pharaoh", deploy_center, 4, Color(0.85, 0.7, 0.2), 5)
	pending_deploy_center = deploy_center

	# Show tutorial before deployment if this is the tutorial stage
	if is_tutorial:
		_show_tutorial_message()
	else:
		_open_deploy_ui(deploy_center)


func _open_deploy_ui(deploy_center: Vector2i):
	deploy_ui = CanvasLayer.new()
	deploy_ui.set_script(preload("res://deploy_ui.gd"))
	add_child(deploy_ui)
	deploy_ui.setup(grid, deploy_center, roster)
	deploy_ui.deployment_done.connect(_on_deployment_done)

	current_state = State.DEPLOYING
	_update_log("Place your soldiers in the blue zone.\nPharaoh is in the center.")


func _on_deployment_done(placed_units: Array):
	# Spawn placed units
	for p in placed_units:
		var d = p["data"]
		var color = d.get("unit_color", Color(0.3, 0.5, 1.0))
		if not d.has("unit_color"):
			color = recruit_system.class_data[d["weapon"]]["color"]
		_spawn_unit(d["unit_name"], p["pos"], d["move_range"], color, "player",
			d["weapon"], d["max_hp"], d["str_"], d["skl"], d["spd"], d["def_"], d["lck"])

	# Clean up deploy UI
	if deploy_ui:
		deploy_ui.queue_free()
		deploy_ui = null

	current_state = State.IDLE

	hud.update_hud({"phase": "Player Turn"})
	_update_hud_counts()
	_update_log("Battle begins!\nSelect a unit.")


# ============================================================
#  TUTORIAL
# ============================================================

func _show_tutorial_message():
	if not is_tutorial or tutorial_messages.size() == 0:
		is_tutorial = false
		return

	tutorial_ui = CanvasLayer.new()
	tutorial_ui.set_script(preload("res://tutorial_ui.gd"))
	add_child(tutorial_ui)
	tutorial_ui.show_tips(tutorial_messages)
	tutorial_ui.dismissed.connect(_on_tutorial_dismissed)
	is_tutorial = false  # only show once


func _on_tutorial_dismissed():
	if tutorial_ui:
		tutorial_ui.queue_free()
		tutorial_ui = null
	# Open deployment after tutorial
	_open_deploy_ui(pending_deploy_center)


# ============================================================
#  SPAWNING
# ============================================================

func _spawn_emperor(emperor_name: String, pos: Vector2i, move_range: int, color: Color, mana: int):
	var unit = Node2D.new()
	unit.set_script(preload("res://unit.gd"))
	add_child(unit)
	unit.unit_name = emperor_name
	unit.move_range = move_range
	unit.unit_color = color
	unit.grid_pos = pos
	unit.team = "player"
	unit.is_emperor = true
	unit.mana = mana
	unit.max_mana = mana
	unit.weapon = -1
	unit.max_hp = 18
	unit.hp = 18
	unit.str_ = 0
	unit.skl = 0
	unit.spd = 3
	unit.def_ = 3
	unit.lck = 5
	unit.position = grid.grid_to_world(pos)
	units.append(unit)
	grid.occupied_cells.append(pos)


func _spawn_unit(unit_name: String, pos: Vector2i, move_range: int, color: Color,
		team: String, weapon: int, hp: int, str_val: int, skl: int, spd: int, def_val: int, lck: int):
	var unit = Node2D.new()
	unit.set_script(preload("res://unit.gd"))
	add_child(unit)
	unit.unit_name = unit_name
	unit.move_range = move_range
	unit.unit_color = color
	unit.grid_pos = pos
	unit.team = team
	unit.weapon = weapon
	unit.max_hp = hp
	unit.hp = hp
	unit.str_ = str_val
	unit.skl = skl
	unit.spd = spd
	unit.def_ = def_val
	unit.lck = lck
	unit.position = grid.grid_to_world(pos)
	units.append(unit)
	grid.occupied_cells.append(pos)


func _revive_unit(dead_entry: Dictionary):
	var d = dead_entry["data"]
	var pos: Vector2i = dead_entry["pos"]

	var unit = Node2D.new()
	unit.set_script(preload("res://unit.gd"))
	add_child(unit)
	unit.unit_name = d["unit_name"]
	unit.move_range = d["move_range"]
	unit.unit_color = d["unit_color"]
	unit.grid_pos = pos
	unit.team = d["team"]
	unit.weapon = d["weapon"]
	unit.max_hp = d["max_hp"]
	unit.hp = d["max_hp"]
	unit.str_ = d["str_"]
	unit.skl = d["skl"]
	unit.spd = d["spd"]
	unit.def_ = d["def_"]
	unit.lck = d["lck"]
	unit.is_emperor = d["is_emperor"]
	unit.mana = d["mana"]
	unit.max_mana = d["max_mana"]
	unit.has_acted = true
	unit.position = grid.grid_to_world(pos)
	units.append(unit)
	grid.occupied_cells.append(pos)


func _store_dead_unit(unit) -> Dictionary:
	return {
		"pos": unit.grid_pos,
		"data": {
			"unit_name": unit.unit_name,
			"move_range": unit.move_range,
			"unit_color": unit.unit_color,
			"team": unit.team,
			"weapon": unit.weapon,
			"max_hp": unit.max_hp,
			"str_": unit.str_,
			"skl": unit.skl,
			"spd": unit.spd,
			"def_": unit.def_,
			"lck": unit.lck,
			"is_emperor": unit.is_emperor,
			"mana": unit.mana,
			"max_mana": unit.max_mana,
		}
	}


# ============================================================
#  INPUT
# ============================================================

func _unhandled_input(event: InputEvent):
	# --- Debug keys ---
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				debug_mode = not debug_mode
				debug_label.visible = debug_mode
				if not debug_mode:
					debug_kill_mode = false
					debug_infinite_move = false
				_update_debug_label()
				return
			KEY_F2:
				if debug_mode:
					# Skip to next stage
					var next = stage_manager.current_stage + 1
					if next < stage_manager.get_total_stages():
						_start_stage(next)
					else:
						_update_log("DEBUG: No more stages.")
					return
			KEY_F3:
				if debug_mode:
					debug_infinite_move = not debug_infinite_move
					_update_debug_label()
					return
			KEY_F4:
				if debug_mode:
					debug_kill_mode = not debug_kill_mode
					_update_debug_label()
					return

	if is_animating:
		return
	if battle_screen:
		return
	if tutorial_ui:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = get_global_mouse_position()
		var cell: Vector2i = grid.world_to_grid(click_pos)

		# Debug kill mode: click any unit to kill it
		if debug_mode and debug_kill_mode:
			var target = _get_unit_at(cell)
			if target:
				target.hp = 0
				_update_log("DEBUG: Killed %s" % target.unit_name)
				_check_dead()
				debug_kill_mode = false
				_update_debug_label()
			return

		match current_state:
			State.DEPLOYING:
				if deploy_ui:
					deploy_ui.handle_grid_click(cell)
			State.IDLE:
				_try_select_unit(cell)
			State.UNIT_SELECTED:
				_try_move_unit(cell)
			State.UNIT_MOVED:
				_handle_post_move(cell)
			State.CHOOSING_TARGET:
				_try_attack_target(cell)
			State.CHOOSING_REVIVE:
				_try_revive_target(cell)


func _update_debug_label():
	if not debug_label:
		return
	var parts = ["DEBUG ON"]
	if debug_infinite_move:
		parts.append("INF MOVE")
	if debug_kill_mode:
		parts.append("KILL MODE (click unit)")
	parts.append("F1:toggle  F2:next stage  F3:inf move  F4:kill")
	debug_label.text = "  |  ".join(parts)


# ============================================================
#  STATE: IDLE
# ============================================================

func _try_select_unit(cell: Vector2i):
	# Clear any previous enemy preview
	_clear_enemy_preview()

	var unit = _get_unit_at(cell)
	if not unit:
		# Clicked empty space, just clear
		_clear_unit_card()
		return

	# Clicked a player unit — select it
	if unit.team == "player" and not unit.has_acted:
		selected_unit = unit
		original_pos = unit.grid_pos
		unit.select()
		current_state = State.UNIT_SELECTED
		var move = unit.move_range
		if debug_mode and debug_infinite_move:
			move = 99
		grid.show_movement_range(unit.grid_pos, move, _get_bush_cost(unit))

		_show_unit_card(unit)
		_update_log("Click blue tile to move.")

		return

	# Clicked an enemy unit — show threat range and stats
	if unit.team == "enemy":
		_show_enemy_preview(unit)


func _show_enemy_preview(enemy: Node2D):
	previewing_enemy = enemy

	# Show threat zone
	if enemy.weapon >= 0:
		var wpn = combat.weapon_data[enemy.weapon]
		grid.show_threat_range(enemy.grid_pos, enemy.move_range, wpn["min_range"], wpn["max_range"], _get_bush_cost(enemy))
	else:
		grid.show_threat_range(enemy.grid_pos, enemy.move_range, 0, 0, _get_bush_cost(enemy))

	# Show stats in card, instruction in log
	_show_unit_card(enemy)
	_update_log("Orange = threat zone.\nClick elsewhere to dismiss.")


func _clear_enemy_preview():
	if previewing_enemy:
		previewing_enemy = null
		grid.threat_highlighted_cells.clear()
		grid.queue_redraw()
		_clear_unit_card()


# ============================================================
#  STATE: UNIT_SELECTED — move
# ============================================================

func _try_move_unit(cell: Vector2i):
	if cell in grid.highlighted_cells:
		# Get tile-by-tile path
		var move = selected_unit.move_range
		if debug_mode and debug_infinite_move:
			move = 99
		var path = grid.find_path(selected_unit.grid_pos, cell, move, _get_bush_cost(selected_unit))
		if path.size() == 0:
			# Fallback: just teleport if path fails
			grid.occupied_cells.erase(selected_unit.grid_pos)
			grid.occupied_cells.append(cell)
			selected_unit.grid_pos = cell
			selected_unit.position = grid.grid_to_world(cell)
			_show_post_move()
			return

		# Animate along path
		grid.occupied_cells.erase(selected_unit.grid_pos)
		grid.occupied_cells.append(cell)
		selected_unit.grid_pos = cell
		grid.clear_highlights()
		_animate_move(selected_unit, path, _show_post_move)
		return

	if cell == selected_unit.grid_pos:
		_show_post_move()
		return

	_deselect()


# --- Tween animation: move unit along a path tile by tile ---

func _animate_move(unit: Node2D, path: Array, callback: Callable):
	is_animating = true
	var tween = create_tween()

	# Skip the first cell (unit is already there)
	for i in range(1, path.size()):
		var target_pos = grid.grid_to_world(path[i])
		tween.tween_property(unit, "position", target_pos, MOVE_SPEED)

	tween.tween_callback(func():
		is_animating = false
		callback.call()
	)


func _show_post_move():
	grid.clear_highlights()

	if selected_unit.is_emperor:
		_show_emperor_options()
	else:
		var wpn = combat.weapon_data[selected_unit.weapon]
		grid.show_attack_range(selected_unit.grid_pos, wpn["min_range"], wpn["max_range"])

		var enemies_in_range = _get_enemies_in_range(selected_unit)
		if enemies_in_range.size() > 0:
			current_state = State.CHOOSING_TARGET
			_update_log("Red tiles = attack range.\nClick an enemy to attack,\nor click your unit to wait.")
		else:
			current_state = State.UNIT_MOVED
			_update_log("No enemies in range.\nClick your unit to wait.")


func _show_emperor_options():
	if selected_unit.mana <= 0:
		current_state = State.UNIT_MOVED
		_update_log("No mana remaining.\nClick the Pharaoh to wait.")
		return

	var revive_targets = _get_adjacent_death_markers(selected_unit.grid_pos)
	if revive_targets.size() > 0:
		var marker_cells = []
		for entry in revive_targets:
			marker_cells.append(entry["pos"])
		grid.show_revive_targets(marker_cells)
		current_state = State.CHOOSING_REVIVE
		_show_unit_card(selected_unit)
		_update_log("Purple tiles = fallen soldiers.\nClick one to revive (1 mana),\nor click Pharaoh to wait.")
	else:
		current_state = State.UNIT_MOVED
		_update_log("No fallen soldiers nearby.\nClick the Pharaoh to wait.")


# ============================================================
#  STATE: UNIT_MOVED
# ============================================================

func _handle_post_move(cell: Vector2i):
	if cell == selected_unit.grid_pos:
		_end_unit_action()
	else:
		_undo_move()


# ============================================================
#  STATE: CHOOSING_TARGET
# ============================================================

func _try_attack_target(cell: Vector2i):
	if cell == selected_unit.grid_pos:
		_end_unit_action()
		return

	if cell not in grid.attack_highlighted_cells:
		_undo_move()
		return

	var target = _get_unit_at(cell)
	if not target or target.team == selected_unit.team:
		return

	# Show forecast instead of attacking immediately
	attack_target = target
	current_state = State.FORECASTING

	forecast_ui = CanvasLayer.new()
	forecast_ui.set_script(preload("res://forecast_ui.gd"))
	add_child(forecast_ui)

	var dist = grid.grid_distance(selected_unit.grid_pos, target.grid_pos)
	_apply_terrain_bonuses(selected_unit)
	_apply_terrain_bonuses(target)
	forecast_ui.setup(combat, selected_unit, target, dist)
	_remove_terrain_bonuses(selected_unit)
	_remove_terrain_bonuses(target)
	forecast_ui.attack_confirmed.connect(_on_forecast_attack)
	forecast_ui.attack_cancelled.connect(_on_forecast_cancel)


func _on_forecast_attack():
	if forecast_ui:
		forecast_ui.queue_free()
		forecast_ui = null

	var target = attack_target
	attack_target = null

	var distance = grid.grid_distance(selected_unit.grid_pos, target.grid_pos)
	_apply_terrain_bonuses(selected_unit)
	_apply_terrain_bonuses(target)
	var results = combat.resolve_combat(selected_unit, target, distance)
	_remove_terrain_bonuses(selected_unit)
	_remove_terrain_bonuses(target)

	# Build log text for after battle screen closes
	pending_combat_log = "--- COMBAT ---\n"
	for entry in results:
		if entry["hit"]:
			var crit_text = " CRITICAL!" if entry["crit"] else ""
			pending_combat_log += "%s hits %s for %d dmg!%s (roll %d < %d)\n" % [
				entry["attacker"], entry["target"], entry["damage"],
				crit_text, entry["roll"], entry["accuracy"]]
			if entry["crit_rate"] > 0:
				pending_combat_log += "  Crit: %d%% (roll %d)\n" % [entry["crit_rate"], entry["crit_roll"]]
			pending_combat_log += "  %s HP: %d/%d\n" % [entry["target"], entry["target_hp"], entry["target_max_hp"]]
		else:
			pending_combat_log += "%s misses %s! (roll %d >= %d)\n" % [
				entry["attacker"], entry["target"],
				entry["roll"], entry["accuracy"]]

	# Store references for after battle screen
	pending_combat_attacker = selected_unit
	pending_combat_target = target

	# Show battle screen
	_show_battle_screen(selected_unit, target, results, _on_player_battle_done)


func _on_player_battle_done():
	_update_log(pending_combat_log)
	_check_dead()

	if current_state == State.GAME_OVER or current_state == State.VICTORY:
		return

	if pending_combat_attacker and pending_combat_attacker.is_alive():
		pending_combat_attacker.queue_redraw()
	if pending_combat_target and pending_combat_target.is_alive():
		pending_combat_target.queue_redraw()

	pending_combat_attacker = null
	pending_combat_target = null

	_end_unit_action()


func _on_forecast_cancel():
	if forecast_ui:
		forecast_ui.queue_free()
		forecast_ui = null

	attack_target = null
	_undo_move()


# ============================================================
#  STATE: CHOOSING_REVIVE
# ============================================================

func _try_revive_target(cell: Vector2i):
	if cell == selected_unit.grid_pos:
		_end_unit_action()
		return

	if cell not in grid.revive_highlighted_cells:
		_undo_move()
		return

	var dead_entry = null
	for entry in dead_units:
		if entry["pos"] == cell and entry["data"]["team"] == "player":
			dead_entry = entry
			break

	if not dead_entry:
		return

	selected_unit.mana -= 1
	_revive_unit(dead_entry)
	dead_units.erase(dead_entry)
	grid.death_markers.erase(cell)

	_update_log("The Pharaoh revives %s!\nMana: %d/%d" % [
		dead_entry["data"]["unit_name"],
		selected_unit.mana,
		selected_unit.max_mana])

	selected_unit.queue_redraw()
	grid.queue_redraw()
	_end_unit_action()


# ============================================================
#  ACTION / TURN MANAGEMENT
# ============================================================

func _end_unit_action():
	selected_unit.has_acted = true
	selected_unit.deselect()
	selected_unit.queue_redraw()
	selected_unit = null
	grid.clear_highlights()
	_clear_unit_card()
	current_state = State.IDLE

	# Check win condition
	if is_capture_stage:
		# Capture stage: boss must be dead AND player unit on throne
		if boss_defeated:
			var throne_captured = false
			for unit in units:
				if unit.team == "player" and unit.is_alive() and unit.grid_pos == throne_tile:
					throne_captured = true
					break
			if throne_captured:
				_on_stage_victory()
				return
			else:
				_update_log("The Usurper has fallen!\nMove a unit onto the throne\nto claim victory.")
	else:
		# Normal stage: all enemies dead
		var enemies_alive = false
		for unit in units:
			if unit.team == "enemy" and unit.is_alive():
				enemies_alive = true
				break

		if not enemies_alive:
			_on_stage_victory()
			return

	# Check if all player units have acted
	var all_acted = true
	for unit in units:
		if unit.team == "player" and unit.is_alive() and not unit.has_acted:
			all_acted = false
			break

	if all_acted:
		_start_enemy_turn()


func _on_end_turn():
	# Only works during player phase when not mid-action
	if current_state != State.IDLE:
		return
	if is_animating:
		return

	# Clear any enemy preview
	_clear_enemy_preview()

	# Mark all remaining player units as acted
	for unit in units:
		if unit.team == "player" and unit.is_alive() and not unit.has_acted:
			unit.has_acted = true
			unit.queue_redraw()

	_update_log("Turn ended early.\n")
	_start_enemy_turn()


func _on_stage_victory():
	var stage = stage_manager.current_stage

	if stage >= stage_manager.get_total_stages() - 1:
		# Final stage — GAME WON!
		current_state = State.VICTORY
		_update_log("=== VICTORY ===\n\nThe Pharaoh has reclaimed\nhis throne!")

		var timer = get_tree().create_timer(2.5)
		timer.timeout.connect(_show_end_screen.bind(true))
		return

	# Calculate souls
	var soul_count = recruit_system.calculate_souls(player_lost_unit)
	var bonus_text = ""
	if not player_lost_unit:
		bonus_text = " (+1 no losses bonus!)"
	_update_log("STAGE CLEAR!\n\nSouls earned: %d%s\n\nOpening recruitment..." % [soul_count, bonus_text])
	current_state = State.GAME_OVER

	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(_show_recruitment.bind(soul_count))


func _undo_move():
	grid.occupied_cells.erase(selected_unit.grid_pos)
	grid.occupied_cells.append(original_pos)
	selected_unit.grid_pos = original_pos
	selected_unit.position = grid.grid_to_world(original_pos)
	_deselect()


func _deselect():
	if selected_unit:
		selected_unit.deselect()
		selected_unit = null
	grid.clear_highlights()
	_clear_unit_card()
	current_state = State.IDLE


# ============================================================
#  DEATH AND REVIVE LOGIC
# ============================================================

func _check_dead():
	for unit in units.duplicate():
		if not unit.is_alive():
			if unit.team == "player" and not unit.is_emperor:
				player_lost_unit = true

			if unit.is_emperor:
				if unit.mana >= 4:
					unit.mana -= 4
					unit.hp = unit.max_hp
					unit.queue_redraw()
					_update_log(combat_log_label.text + "\n\nThe Pharaoh spends 4 mana\nto defy death!\nMana: %d/%d" % [unit.mana, unit.max_mana])
					continue
				else:
					_update_log("The Pharaoh has fallen\nwith no mana to revive!\n\n--- GAME OVER ---")
					current_state = State.GAME_OVER
					grid.occupied_cells.erase(unit.grid_pos)
					unit.queue_free()
					units.erase(unit)

					var timer = get_tree().create_timer(2.5)
					timer.timeout.connect(_show_end_screen.bind(false))
					return

			var dead_entry = _store_dead_unit(unit)
			dead_units.append(dead_entry)

			# Check if boss was defeated
			if unit.is_boss:
				boss_defeated = true

			# Track defeated enemies for recruitment (non-boss only)
			if unit.team == "enemy" and not unit.is_boss:
				defeated_enemies.append({
					"weapon": unit.weapon,
					"max_hp": unit.max_hp,
					"str_": unit.str_,
					"skl": unit.skl,
					"spd": unit.spd,
					"def_": unit.def_,
					"lck": unit.lck,
					"move_range": unit.move_range,
				})

			if unit.team == "player":
				grid.death_markers.append(unit.grid_pos)

			grid.occupied_cells.erase(unit.grid_pos)
			unit.queue_free()
			units.erase(unit)

	grid.queue_redraw()
	_update_hud_counts()


# ============================================================
#  BATTLE SCREEN
# ============================================================

func _show_battle_screen(atk: Node2D, def: Node2D, results: Array, callback: Callable):
	# Fade out overworld music in sync with visual fade
	var music_out = create_tween()
	music_out.tween_property(music_overworld, "volume_db", -40.0, FADE_DURATION)

	_fade_to_black(func():
		# Screen is black — swap music instantly
		music_overworld.stream_paused = true
		music_overworld.volume_db = 0.0
		music_battle.volume_db = -40.0
		music_battle.stream_paused = false
		if not music_battle.playing:
			music_battle.play()

		# Show battle screen behind black
		battle_screen = CanvasLayer.new()
		battle_screen.set_script(preload("res://battle_screen.gd"))
		add_child(battle_screen)
		battle_screen.setup(atk, def, results, combat)
		battle_screen.battle_finished.connect(func():
			# Fade out battle music in sync with visual fade
			var music_out2 = create_tween()
			music_out2.tween_property(music_battle, "volume_db", -40.0, FADE_DURATION)

			_fade_to_black(func():
				# Screen is black — swap music instantly
				music_battle.stream_paused = true
				music_battle.volume_db = 0.0
				music_overworld.volume_db = -40.0
				music_overworld.stream_paused = false

				if battle_screen:
					battle_screen.queue_free()
					battle_screen = null

				# Fade in overworld music in sync with visual fade
				var music_in2 = create_tween()
				music_in2.tween_property(music_overworld, "volume_db", 0.0, FADE_DURATION)
				_fade_from_black()
				callback.call()
			)
		)

		# Fade in battle music in sync with visual fade
		var music_in = create_tween()
		music_in.tween_property(music_battle, "volume_db", 0.0, FADE_DURATION)
		_fade_from_black()
	)


# ============================================================
#  RECRUITMENT
# ============================================================

func _show_recruitment(soul_count: int):
	_play_recruit_music()
	recruit_ui = CanvasLayer.new()
	recruit_ui.set_script(preload("res://recruit_ui.gd"))
	add_child(recruit_ui)
	recruit_ui.setup(recruit_system, soul_count, defeated_enemies)
	recruit_ui.recruitment_done.connect(_on_recruitment_done)


func _on_recruitment_done(new_recruits: Array):
	_stop_recruit_resume_overworld()
	for r in new_recruits:
		roster.append(r)

	if recruit_ui:
		recruit_ui.queue_free()
		recruit_ui = null

	# Advance to next stage
	var next_stage = stage_manager.current_stage + 1
	_update_log("Recruitment complete!\n%d new soldiers.\nRoster: %d total\n\nAdvancing to next stage..." % [
		new_recruits.size(), roster.size()])

	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(_start_stage.bind(next_stage))


# ============================================================
#  END SCREENS (Game Over / Victory)
# ============================================================

func _show_end_screen(is_victory: bool):
	_stop_all_music()
	end_screen = CanvasLayer.new()
	end_screen.set_script(preload("res://end_screen.gd"))
	add_child(end_screen)

	if is_victory:
		end_screen.setup_victory()
	else:
		end_screen.setup_game_over()

	end_screen.restart_game.connect(_on_restart)
	end_screen.return_to_menu.connect(_on_return_to_menu)


func _on_restart():
	if end_screen:
		end_screen.queue_free()
		end_screen = null
	_reset_game()


func _on_return_to_menu():
	if end_screen:
		end_screen.queue_free()
		end_screen = null
	_clear_stage()
	_show_main_menu()


# ============================================================
#  ENEMY AI (animated, one at a time)
# ============================================================

var enemy_queue = []

func _start_enemy_turn():
	current_state = State.ENEMY_TURN
	_update_log("--- ENEMY TURN ---")
	hud.update_hud({"phase": "Enemy Turn"})

	# Throne HP regen at start of enemy turn
	_apply_terrain_healing()

	enemy_queue.clear()
	for unit in units:
		if unit.team == "enemy" and unit.is_alive():
			enemy_queue.append(unit)

	_show_phase_banner("ENEMY TURN", _process_next_enemy)


func _process_next_enemy():
	while enemy_queue.size() > 0 and not enemy_queue[0].is_alive():
		enemy_queue.pop_front()

	if enemy_queue.size() == 0:
		_end_enemy_turn()
		return

	if current_state == State.GAME_OVER:
		return

	var unit = enemy_queue.pop_front()

	# Stationary enemies don't move, just attack in range
	if unit.stationary:
		_enemy_try_attack(unit)
		return

	# Find the best target using real pathfinding distance
	var target = _find_best_target(unit)
	if not target:
		_process_next_enemy()
		return

	# Find the best cell to move to (closest to target by BFS distance)
	var move_cells = grid.get_movement_range(unit.grid_pos, unit.move_range, _get_bush_cost(unit))
	var best_cell = unit.grid_pos
	var best_dist = grid.bfs_distance(unit.grid_pos, target.grid_pos)

	# If already unreachable from current position, just stay put
	if best_dist < 0:
		best_dist = 999

	for cell in move_cells:
		var dist = grid.bfs_distance(cell, target.grid_pos)
		if dist >= 0 and dist < best_dist:
			best_dist = dist
			best_cell = cell

	# Check if we can attack from the best cell
	var can_attack_from_best = false
	if unit.weapon >= 0:
		var wpn = combat.weapon_data[unit.weapon]
		var atk_dist = grid.grid_distance(best_cell, target.grid_pos)
		can_attack_from_best = atk_dist >= wpn["min_range"] and atk_dist <= wpn["max_range"]

	# If can't attack this turn, prefer bush tiles within 2 tiles of optimal distance
	if not can_attack_from_best:
		for cell in move_cells:
			if cell in grid.bush_tiles and cell not in grid.occupied_cells:
				var dist = grid.bfs_distance(cell, target.grid_pos)
				if dist >= 0 and dist <= best_dist + 2:
					best_cell = cell
					break

	if best_cell == unit.grid_pos:
		# Can't move closer, try to attack anyone in range
		_enemy_try_attack(unit)
		return

	# Get path BEFORE updating occupied cells
	var path = grid.find_path(unit.grid_pos, best_cell, unit.move_range, _get_bush_cost(unit))
	if path.size() <= 1:
		_enemy_try_attack(unit)
		return

	grid.occupied_cells.erase(unit.grid_pos)
	grid.occupied_cells.append(best_cell)
	unit.grid_pos = best_cell

	_animate_move(unit, path, func():
		_enemy_try_attack(unit)
	)


var pending_enemy_unit: Node2D = null

func _enemy_try_attack(unit: Node2D):
	if not unit.is_alive():
		_process_next_enemy()
		return

	# Find the best attackable target from current position
	var target = _find_attackable_target(unit)
	if not target:
		# No one to attack, move on
		var timer = get_tree().create_timer(0.7)
		timer.timeout.connect(_process_next_enemy)
		return

	var distance = grid.grid_distance(unit.grid_pos, target.grid_pos)
	_apply_terrain_bonuses(unit)
	_apply_terrain_bonuses(target)
	var results = combat.resolve_combat(unit, target, distance)
	_remove_terrain_bonuses(unit)
	_remove_terrain_bonuses(target)

	# Build log text
	pending_combat_log = combat_log_label.text + "\n"
	for entry in results:
		if entry["hit"]:
			var crit_text = " CRITICAL!" if entry["crit"] else ""
			pending_combat_log += "%s hits %s for %d dmg!%s\n" % [entry["attacker"], entry["target"], entry["damage"], crit_text]
		else:
			pending_combat_log += "%s misses %s!\n" % [entry["attacker"], entry["target"]]

	pending_enemy_unit = unit
	pending_combat_target = target

	_show_battle_screen(unit, target, results, _on_enemy_battle_done)


func _on_enemy_battle_done():
	_update_log(pending_combat_log)
	_check_dead()

	if current_state == State.GAME_OVER:
		pending_enemy_unit = null
		pending_combat_target = null
		return

	if pending_enemy_unit and pending_enemy_unit.is_alive():
		pending_enemy_unit.queue_redraw()
	if pending_combat_target and pending_combat_target.is_alive():
		pending_combat_target.queue_redraw()

	pending_enemy_unit = null
	pending_combat_target = null

	# Small delay before next enemy acts
	var timer = get_tree().create_timer(0.7)
	timer.timeout.connect(_process_next_enemy)


# Find best target to attack from current position
# Prioritizes emperor > lowest HP > first found
func _find_attackable_target(enemy: Node2D) -> Node2D:
	if enemy.weapon < 0:
		return null

	var wpn = combat.weapon_data[enemy.weapon]
	var best_target = null

	for unit in units:
		if unit.team == "player" and unit.is_alive():
			var dist = grid.grid_distance(enemy.grid_pos, unit.grid_pos)
			if dist >= wpn["min_range"] and dist <= wpn["max_range"]:
				# Always prefer the emperor
				if unit.is_emperor:
					return unit
				# Otherwise prefer lowest HP target
				if best_target == null or unit.hp < best_target.hp:
					best_target = unit

	return best_target


func _end_enemy_turn():
	for unit in units:
		if unit.is_alive():
			unit.has_acted = false
			unit.queue_redraw()

	# Throne HP regen at start of player turn
	_apply_terrain_healing()

	turn_count += 1
	hud.update_hud({"phase": "Player Turn"})
	_update_hud_counts()

	_show_phase_banner("YOUR TURN", func():
		current_state = State.IDLE
		_update_log("--- YOUR TURN ---\nSelect a unit.")
	)


# ============================================================
#  HELPERS
# ============================================================

func _get_unit_at(cell: Vector2i):
	for unit in units:
		if unit.grid_pos == cell and unit.is_alive():
			return unit
	return null


func _get_enemies_in_range(attacker) -> Array:
	var wpn = combat.weapon_data[attacker.weapon]
	var result = []
	for unit in units:
		if unit.team != attacker.team and unit.is_alive():
			var dist = grid.grid_distance(attacker.grid_pos, unit.grid_pos)
			if dist >= wpn["min_range"] and dist <= wpn["max_range"]:
				result.append(unit)
	return result


func _get_adjacent_death_markers(pos: Vector2i) -> Array:
	var result = []
	for entry in dead_units:
		if entry["data"]["team"] == "player":
			var dist = grid.grid_distance(pos, entry["pos"])
			if dist == 1:
				result.append(entry)
	return result


func _find_best_target(enemy) -> Node2D:
	var emperor = null
	var emperor_dist = -1
	var nearest = null
	var nearest_dist = 999

	for unit in units:
		if unit.team == "player" and unit.is_alive():
			# Use real pathfinding distance (ignores units, respects walls)
			var dist = grid.bfs_distance(enemy.grid_pos, unit.grid_pos)

			# Skip unreachable targets (behind walls with no path)
			if dist < 0:
				continue

			if unit.is_emperor:
				emperor = unit
				emperor_dist = dist

			if dist < nearest_dist:
				nearest_dist = dist
				nearest = unit

	# Prefer emperor if reachable and not too much farther than nearest
	if emperor and emperor_dist >= 0 and emperor_dist <= nearest_dist + 3:
		return emperor

	return nearest


# ============================================================
#  TERRAIN BONUSES
# ============================================================

const BUSH_DEF_BONUS := 1
const BUSH_AVOID_BONUS := 10
const THRONE_AVOID_BONUS := 20
const THRONE_REGEN := 5

func _get_bush_cost(unit) -> int:
	# Heavy units (Axe, Lance) pay 2 to enter bush, light units pay 1
	if unit.weapon == 1 or unit.weapon == 2:
		return 2
	return 1


func _is_on_bush(unit) -> bool:
	return unit.grid_pos in grid.bush_tiles


func _is_on_throne(unit) -> bool:
	return unit.grid_pos == grid.throne_tile


func _apply_terrain_bonuses(unit):
	if _is_on_bush(unit):
		unit.def_ += BUSH_DEF_BONUS
		unit.lck += BUSH_AVOID_BONUS
	if _is_on_throne(unit):
		unit.lck += THRONE_AVOID_BONUS


func _remove_terrain_bonuses(unit):
	if _is_on_bush(unit):
		unit.def_ -= BUSH_DEF_BONUS
		unit.lck -= BUSH_AVOID_BONUS
	if _is_on_throne(unit):
		unit.lck -= THRONE_AVOID_BONUS


func _apply_terrain_healing():
	for unit in units:
		if unit.is_alive() and _is_on_throne(unit):
			var old_hp = unit.hp
			unit.hp = mini(unit.hp + THRONE_REGEN, unit.max_hp)
			if unit.hp > old_hp:
				unit.queue_redraw()


func _unit_info(unit) -> String:
	var wpn_might = 0
	var wpn_hit = 0
	var atk_range = "0"
	if unit.weapon >= 0:
		var wpn = combat.weapon_data[unit.weapon]
		wpn_might = wpn["might"]
		wpn_hit = wpn["hit"]
		if wpn["min_range"] == wpn["max_range"]:
			atk_range = str(wpn["min_range"])
		else:
			atk_range = "%d-%d" % [wpn["min_range"], wpn["max_range"]]

	var text = "HP:  %d/%d\n" % [unit.hp, unit.max_hp]
	text += "STR: %d   SKL: %d\n" % [unit.str_, unit.skl]
	text += "SPD: %d   DEF: %d\n" % [unit.spd, unit.def_]
	text += "LCK: %d\n" % unit.lck
	text += "ATK: %d  HIT: %d\n" % [unit.str_ + wpn_might, wpn_hit]
	text += "Range: %s  MOV: %d" % [atk_range, unit.move_range]
	if _is_on_bush(unit):
		text += "\n[Bush: DEF+1 AVO+10]"
	if _is_on_throne(unit):
		text += "\n[Throne: AVO+20 HP+5/turn]"
	return text


func _emperor_info(unit) -> String:
	var text = "HP:%d/%d Mana:%d/%d\nSPD:%d DEF:%d LCK:%d\nCannot attack. Can revive." % [
		unit.hp, unit.max_hp, unit.mana, unit.max_mana,
		unit.spd, unit.def_, unit.lck]
	if _is_on_bush(unit):
		text += "\n[Bush: DEF+1 AVO+10]"
	if _is_on_throne(unit):
		text += "\n[Throne: AVO+20 HP+5/turn]"
	return text


func _enemy_preview_info(unit) -> String:
	var wpn_might = 0
	var wpn_hit = 0
	var atk_range = "0"
	if unit.weapon >= 0:
		var wpn = combat.weapon_data[unit.weapon]
		wpn_might = wpn["might"]
		wpn_hit = wpn["hit"]
		if wpn["min_range"] == wpn["max_range"]:
			atk_range = str(wpn["min_range"])
		else:
			atk_range = "%d-%d" % [wpn["min_range"], wpn["max_range"]]

	var text = "HP:  %d/%d\n" % [unit.hp, unit.max_hp]
	text += "STR: %d   SKL: %d\n" % [unit.str_, unit.skl]
	text += "SPD: %d   DEF: %d\n" % [unit.spd, unit.def_]
	text += "LCK: %d\n" % unit.lck
	text += "ATK: %d  HIT: %d\n" % [unit.str_ + wpn_might, wpn_hit]
	text += "Range: %s  MOV: %d" % [atk_range, unit.move_range]
	return text


func _get_portrait_key(unit) -> int:
	if unit.is_emperor:
		return -1
	return unit.weapon


func _show_unit_card(unit):
	var key = _get_portrait_key(unit)

	# Set portrait
	if PORTRAIT_PATHS.has(key):
		var tex = load(PORTRAIT_PATHS[key])
		if tex:
			unit_card_portrait.texture = tex
			unit_card_portrait.visible = true
		else:
			unit_card_portrait.visible = false
	else:
		unit_card_portrait.visible = false

	# Set name with class
	var wpn_class = ""
	if unit.is_emperor:
		wpn_class = "Emperor"
	elif unit.weapon >= 0:
		wpn_class = combat.weapon_data[unit.weapon]["name"]
	unit_card_name.text = "%s\n[%s]" % [unit.unit_name, wpn_class]

	# Set color based on team
	if unit.team == "enemy":
		unit_card_name.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	else:
		unit_card_name.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))

	# Set stats
	if unit.is_emperor:
		unit_card_stats.text = _emperor_info(unit)
	else:
		unit_card_stats.text = _unit_info(unit)

	unit_card_container.visible = true
	unit_card_visible = true


func _clear_unit_card():
	unit_card_container.visible = false
	unit_card_visible = false


func _update_log(text: String):
	combat_log_label.text = text


func _update_hud_counts():
	var enemy_count = 0
	for unit in units:
		if unit.team == "enemy" and unit.is_alive():
			enemy_count += 1
	hud.update_hud({"enemies": enemy_count, "turn": turn_count})


# ============================================================
#  MUSIC
# ============================================================

func _stop_all_music():
	music_menu.stop()
	music_overworld.stop()
	music_battle.stop()
	music_recruit.stop()


func _play_menu_music():
	_stop_all_music()
	music_menu.volume_db = 0.0
	music_menu.play()


func _play_overworld_music():
	# Start fresh from beginning
	music_battle.stop()
	music_recruit.stop()
	music_overworld.volume_db = 0.0
	music_overworld.stream_paused = false
	if not music_overworld.playing:
		music_overworld.play()


func _play_recruit_music():
	music_overworld.stream_paused = true
	music_battle.stop()
	music_recruit.volume_db = 0.0
	music_recruit.play()


func _stop_recruit_resume_overworld():
	music_recruit.stop()
	music_overworld.volume_db = 0.0
	music_overworld.stream_paused = false


func _reset_stage_music():
	music_overworld.stop()
	music_battle.stop()
	music_recruit.stop()
	music_overworld.volume_db = 0.0
	music_battle.volume_db = 0.0


# ============================================================
#  TRANSITIONS
# ============================================================

func _fade_to_black(callback: Callable):
	fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, FADE_DURATION)
	tween.tween_callback(callback)


func _fade_from_black():
	fade_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, FADE_DURATION)


func _show_phase_banner(text: String, callback: Callable):
	banner_label.text = text
	banner_layer.visible = true
	banner_bg.modulate = Color(1, 1, 1, 0)
	banner_label.modulate = Color(1, 1, 1, 0)

	var tween = create_tween()
	# Fade in
	tween.tween_property(banner_bg, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(banner_label, "modulate:a", 1.0, 0.25)
	# Hold
	tween.tween_interval(1.0)
	# Fade out
	tween.tween_property(banner_bg, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(banner_label, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func():
		banner_layer.visible = false
		callback.call()
	)
