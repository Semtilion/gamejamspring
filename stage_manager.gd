extends Node

# ============================================================
#  STAGE DEFINITIONS
# ============================================================
#  Enemies now only define class (weapon), position, and move.
#  Stats are randomized by recruit.gd at stage start.
#  Boss keeps fixed stats.

var current_stage := 0

func get_stage_data(stage: int) -> Dictionary:
	match stage:
		0:
			return _stage_tutorial()
		1:
			return _stage_normal()
		2:
			return _stage_boss()
		_:
			return {}


func get_total_stages() -> int:
	return 3


# ============================================================
#  STAGE 1: TUTORIAL (18x10)
# ============================================================

func _stage_tutorial() -> Dictionary:
	return {
		"name": "The Awakening",
		"description": "The Pharaoh rises from his tomb.\nDestroy the grave robbers.",
		"grid_width": 18,
		"grid_height": 10,
		"deploy_center": Vector2i(1, 4),
		"obstacles": [
			Vector2i(4, 2), Vector2i(4, 3),
			Vector2i(4, 6), Vector2i(4, 7),
			Vector2i(8, 0), Vector2i(8, 1),
			Vector2i(8, 4), Vector2i(8, 5),
			Vector2i(8, 8), Vector2i(8, 9),
			Vector2i(12, 3), Vector2i(12, 4),
			Vector2i(13, 6),
		],
		"enemies": [
			{"name": "Robber",  "pos": Vector2i(14, 2), "weapon": 0, "move": 3, "randomize": true},
			{"name": "Thief",   "pos": Vector2i(15, 7), "weapon": 1, "move": 3, "randomize": true},
			{"name": "Bandit",  "pos": Vector2i(16, 4), "weapon": 2, "move": 3, "randomize": true},
		],
		"is_tutorial": true,
		"tutorial_messages": [
			"Raise from your death, Pharaoh.\nYour empire has been stolen.\nIt is time to reclaim\nwhat is rightfully yours.",
			"First, you must deploy your army.\nSelect a soldier from the roster\non the right, then click a blue\ntile to place them on the field.",
			"You can click a placed soldier\nto take them back and reposition.\nWhen ready, click START BATTLE.",
			"Click a unit to select it.\nBlue tiles show where they can move.\nClick a blue tile to move there.",
			"After moving, red tiles show\nattack range. Click an enemy to\nopen the combat forecast, then\nconfirm or cancel the attack.",
			"To finish a unit's turn without\nattacking, click on the unit itself\nafter moving. They will wait in place.",
			"To end your entire team's turn\nearly, click the END TURN button\nin the top right corner.",
			"Your Pharaoh cannot fight, but can\nrevive fallen soldiers. Move him next\nto a death marker and spend 1 mana.",
			"If the Pharaoh falls with less than\n4 mana, the game is over.\nProtect him at all costs!",
		],
	}


# ============================================================
#  STAGE 2: NORMAL FIGHT (18x10)
# ============================================================

func _stage_normal() -> Dictionary:
	return {
		"name": "March of the Dead",
		"description": "The undead army advances toward\nthe usurper's outer garrison.",
		"grid_width": 18,
		"grid_height": 10,
		"deploy_center": Vector2i(1, 4),
		"obstacles": [
			Vector2i(4, 0), Vector2i(4, 1), Vector2i(4, 2),
			Vector2i(4, 7), Vector2i(4, 8), Vector2i(4, 9),
			Vector2i(8, 3), Vector2i(8, 4),
			Vector2i(9, 3), Vector2i(9, 4),
			Vector2i(8, 6), Vector2i(8, 7),
			Vector2i(9, 6), Vector2i(9, 7),
			Vector2i(13, 1), Vector2i(13, 2),
			Vector2i(14, 1),
			Vector2i(13, 8), Vector2i(14, 8),
			Vector2i(16, 4), Vector2i(16, 5),
		],
		"enemies": [
			{"name": "Guard A",   "pos": Vector2i(12, 0),  "weapon": 2, "move": 4, "randomize": true},
			{"name": "Guard B",   "pos": Vector2i(15, 3),  "weapon": 1, "move": 3, "randomize": true},
			{"name": "Archer C",  "pos": Vector2i(16, 7),  "weapon": 3, "move": 3, "randomize": true},
			{"name": "Soldier D", "pos": Vector2i(12, 9),  "weapon": 0, "move": 4, "randomize": true},
		],
		"is_tutorial": false,
		"tutorial_messages": [],
	}


# ============================================================
#  STAGE 3: BOSS (18x10)
# ============================================================

func _stage_boss() -> Dictionary:
	return {
		"name": "The Usurper's Throne",
		"description": "Defeat the Usurper and capture\nhis throne to reclaim your empire.",
		"grid_width": 18,
		"grid_height": 10,
		"deploy_center": Vector2i(1, 4),
		"obstacles": [
			Vector2i(4, 0), Vector2i(4, 1),
			Vector2i(4, 8), Vector2i(4, 9),
			Vector2i(7, 2), Vector2i(7, 3),
			Vector2i(7, 6), Vector2i(7, 7),
			Vector2i(10, 1), Vector2i(10, 8),
			Vector2i(12, 1), Vector2i(12, 8),
			Vector2i(14, 3), Vector2i(14, 6),
			Vector2i(15, 3), Vector2i(15, 6),
			Vector2i(16, 3), Vector2i(16, 4),
			Vector2i(16, 5), Vector2i(16, 6),
		],
		"enemies": [
			# Boss: fixed stats, stationary
			{"name": "Usurper", "pos": Vector2i(15, 4), "weapon": 0, "move": 0,
			 "hp": 35, "str": 10, "skl": 10, "spd": 11, "def": 8, "lck": 7,
			 "stationary": true, "is_boss": true, "randomize": false},
			# Bodyguards: randomized
			{"name": "Elite A", "pos": Vector2i(11, 3), "weapon": 2, "move": 4, "randomize": true},
			{"name": "Elite B", "pos": Vector2i(11, 6), "weapon": 1, "move": 3, "randomize": true},
			{"name": "Sniper",  "pos": Vector2i(13, 8), "weapon": 3, "move": 3, "randomize": true},
		],
		"is_tutorial": false,
		"tutorial_messages": [],
		"throne_tile": Vector2i(15, 4),
		"is_capture_stage": true,
	}
