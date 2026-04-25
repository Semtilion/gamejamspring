extends Node

# ============================================================
#  SOUL REWARD CALCULATION
# ============================================================

func calculate_souls(player_lost_unit: bool) -> int:
	var base = 1 + (randi() % 2)
	var bonus = 0 if player_lost_unit else 1
	return base + bonus


# ============================================================
#  CLASS DEFINITIONS & STAT WEIGHTS
# ============================================================

var class_data = {
	0: {  # SWORD
		"class_name": "Swordsman",
		"weapon": 0,
		"color": Color(0.3, 0.5, 1.0),
		"move_range": [4, 6],
		"hp":   [16, 20],
		"str_": [4, 6],
		"skl":  [7, 10],
		"spd":  [8, 11],
		"def_": [3, 5],
		"lck":  [4, 7],
	},
	1: {  # AXE
		"class_name": "Axeman",
		"weapon": 1,
		"color": Color(0.7, 0.4, 0.15),
		"move_range": [3, 4],
		"hp":   [26, 32],
		"str_": [8, 11],
		"skl":  [2, 4],
		"spd":  [2, 4],
		"def_": [2, 4],
		"lck":  [1, 3],
	},
	2: {  # LANCE
		"class_name": "Lancer",
		"weapon": 2,
		"color": Color(0.2, 0.4, 0.8),
		"move_range": [3, 5],
		"hp":   [22, 26],
		"str_": [6, 9],
		"skl":  [5, 7],
		"spd":  [4, 6],
		"def_": [7, 10],
		"lck":  [3, 5],
	},
	3: {  # BOW
		"class_name": "Archer",
		"weapon": 3,
		"color": Color(0.2, 0.7, 0.4),
		"move_range": [4, 5],
		"hp":   [18, 22],
		"str_": [5, 8],
		"skl":  [6, 8],
		"spd":  [5, 7],
		"def_": [2, 4],
		"lck":  [3, 6],
	},
}

# Portrait paths for recruitment UI
var portrait_paths = {
	0: "res://assets/bastet_portrait.png",
	1: "res://assets/nasus_portrait.png",
	2: "res://assets/renekton_portrait.png",
	3: "res://assets/falcon_portrait.png",
}

# Egyptian-themed names pool
var name_pool = [
	"Anubis", "Horus", "Sobek", "Thoth", "Amun",
	"Osiris", "Sekhmet", "Bastet", "Khufu", "Imhotep",
	"Nefari", "Sethi", "Ramses", "Merneph", "Amenho",
	"Hathor", "Nefer", "Ptahil", "Akhom", "Djoser",
]

var used_names = []


func get_random_name() -> String:
	var available = []
	for n in name_pool:
		if n not in used_names:
			available.append(n)

	if available.size() == 0:
		return "Soldier_%d" % (randi() % 999)

	var name = available[randi() % available.size()]
	used_names.append(name)
	return name


func _rand_range(min_val: int, max_val: int) -> int:
	return min_val + (randi() % (max_val - min_val + 1))


# ============================================================
#  GENERATE RANDOMIZED ENEMY STATS
# ============================================================
#  Used by game.gd when spawning enemies with "randomize": true

func generate_enemy_stats(weapon_class: int) -> Dictionary:
	var c = class_data[weapon_class]
	return {
		"hp": _rand_range(c["hp"][0], c["hp"][1]),
		"str": _rand_range(c["str_"][0], c["str_"][1]),
		"skl": _rand_range(c["skl"][0], c["skl"][1]),
		"spd": _rand_range(c["spd"][0], c["spd"][1]),
		"def": _rand_range(c["def_"][0], c["def_"][1]),
		"lck": _rand_range(c["lck"][0], c["lck"][1]),
	}


# ============================================================
#  CONVERT DEFEATED ENEMY TO RECRUIT DATA
# ============================================================
#  Takes a defeated enemy's stats and gives them a new name

func convert_to_recruit(defeated: Dictionary) -> Dictionary:
	var weapon = defeated["weapon"]
	var c = class_data.get(weapon, class_data[0])

	return {
		"unit_name": get_random_name(),
		"weapon": weapon,
		"class_name": c["class_name"],
		"unit_color": c["color"],
		"move_range": defeated.get("move_range", _rand_range(c["move_range"][0], c["move_range"][1])),
		"max_hp": defeated["max_hp"],
		"str_": defeated["str_"],
		"skl": defeated["skl"],
		"spd": defeated["spd"],
		"def_": defeated["def_"],
		"lck": defeated["lck"],
	}
