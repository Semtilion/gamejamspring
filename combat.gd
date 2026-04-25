extends Node

# ============================================================
#  WEAPONS
# ============================================================

enum Weapon { SWORD, AXE, LANCE, BOW }

# Weapon data: [might, hit, min_range, max_range]
var weapon_data = {
	Weapon.SWORD: { "name": "Sword", "might": 5, "hit": 90, "min_range": 1, "max_range": 1 },
	Weapon.AXE:   { "name": "Axe",   "might": 8, "hit": 75, "min_range": 1, "max_range": 1 },
	Weapon.LANCE: { "name": "Lance", "might": 7, "hit": 80, "min_range": 1, "max_range": 1 },
	Weapon.BOW:   { "name": "Bow",   "might": 6, "hit": 85, "min_range": 2, "max_range": 2 },
}


# ============================================================
#  WEAPON TRIANGLE
# ============================================================

const TRIANGLE_BONUS_HIT := 15
const TRIANGLE_BONUS_DMG := 1

func get_triangle(attacker_wpn: int, defender_wpn: int) -> int:
	if attacker_wpn == Weapon.BOW or defender_wpn == Weapon.BOW:
		return 0

	# Advantage
	if attacker_wpn == Weapon.SWORD and defender_wpn == Weapon.AXE:
		return 1
	if attacker_wpn == Weapon.AXE and defender_wpn == Weapon.LANCE:
		return 1
	if attacker_wpn == Weapon.LANCE and defender_wpn == Weapon.SWORD:
		return 1

	# Disadvantage
	if attacker_wpn == Weapon.AXE and defender_wpn == Weapon.SWORD:
		return -1
	if attacker_wpn == Weapon.LANCE and defender_wpn == Weapon.AXE:
		return -1
	if attacker_wpn == Weapon.SWORD and defender_wpn == Weapon.LANCE:
		return -1

	return 0


# ============================================================
#  COMBAT MATH
# ============================================================

const DOUBLE_THRESHOLD := 5
const CRIT_MULTIPLIER := 3

func _calc_raw_accuracy(attacker, defender) -> int:
	# Returns the UNCLAMPED accuracy (can go above 100)
	var wpn = weapon_data[attacker.weapon]
	var triangle = get_triangle(attacker.weapon, defender.weapon)

	var hit = (attacker.skl * 2) + attacker.lck + wpn["hit"] + (triangle * TRIANGLE_BONUS_HIT)
	var avoid = (defender.spd * 2) + defender.lck

	return hit - avoid


func calc_hit_rate(attacker, defender) -> int:
	# Clamped 0-100 for the actual hit check
	return clampi(_calc_raw_accuracy(attacker, defender), 0, 100)


func calc_crit_rate(attacker, defender) -> int:
	# Excess hit over 100, minus defender's speed and luck
	var raw_accuracy = _calc_raw_accuracy(attacker, defender)
	var excess = maxi(raw_accuracy - 100, 0)
	var crit = excess - defender.spd - defender.lck
	return clampi(crit, 0, 100)


func calc_damage(attacker, defender) -> int:
	var wpn = weapon_data[attacker.weapon]
	var triangle = get_triangle(attacker.weapon, defender.weapon)

	var dmg = attacker.str_ + wpn["might"] + (triangle * TRIANGLE_BONUS_DMG) - defender.def_
	return maxi(dmg, 0)


func can_double(attacker, defender) -> bool:
	return attacker.spd >= defender.spd + DOUBLE_THRESHOLD


func can_counter(_attacker, defender, distance: int) -> bool:
	# Emperor or unarmed units can't counter
	if defender.weapon < 0:
		return false
	var wpn = weapon_data[defender.weapon]
	return distance >= wpn["min_range"] and distance <= wpn["max_range"]


func is_in_attack_range(attacker, distance: int) -> bool:
	if attacker.weapon < 0:
		return false
	var wpn = weapon_data[attacker.weapon]
	return distance >= wpn["min_range"] and distance <= wpn["max_range"]


# ============================================================
#  COMBAT RESOLUTION
# ============================================================

func resolve_combat(attacker, defender, distance: int) -> Array:
	var results = []

	# --- Attacker strikes ---
	_do_attack(attacker, defender, results)
	if defender.hp <= 0:
		return results

	# --- Defender counters ---
	if can_counter(attacker, defender, distance):
		_do_attack(defender, attacker, results)
		if attacker.hp <= 0:
			return results

	# --- Attacker doubles ---
	if can_double(attacker, defender) and defender.hp > 0:
		_do_attack(attacker, defender, results)
		if defender.hp <= 0:
			return results

	# --- Defender doubles on counter ---
	if can_counter(attacker, defender, distance) and can_double(defender, attacker) and attacker.hp > 0:
		_do_attack(defender, attacker, results)

	return results


func _do_attack(atk, def, results: Array):
	var accuracy = calc_hit_rate(atk, def)
	var damage = calc_damage(atk, def)
	var crit_rate = calc_crit_rate(atk, def)

	# Hit roll
	var hit_roll = randi() % 100
	var hit = hit_roll < accuracy

	# Crit roll (only matters if hit lands)
	var crit = false
	var crit_roll = -1
	if hit and crit_rate > 0:
		crit_roll = randi() % 100
		crit = crit_roll < crit_rate
		if crit:
			damage *= CRIT_MULTIPLIER

	if hit:
		def.hp = maxi(def.hp - damage, 0)

	results.append({
		"attacker": atk.unit_name,
		"target": def.unit_name,
		"hit": hit,
		"crit": crit,
		"roll": hit_roll,
		"accuracy": accuracy,
		"crit_rate": crit_rate,
		"crit_roll": crit_roll,
		"damage": damage if hit else 0,
		"target_hp": def.hp,
		"target_max_hp": def.max_hp,
	})
