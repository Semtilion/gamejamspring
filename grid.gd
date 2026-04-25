extends Node2D

# --- Grid Settings ---
const CELL_SIZE := 64
var grid_width := 10
var grid_height := 8

var obstacles = []
var highlighted_cells = []        # blue — movement range
var attack_highlighted_cells = []  # red — attack range
var revive_highlighted_cells = []  # purple — revive targets
var threat_highlighted_cells = []  # orange — enemy threat zone
var occupied_cells = []

# Death markers: array of Vector2i positions
var death_markers = []

# Throne tile (capture objective)
var throne_tile: Vector2i = Vector2i(-1, -1)
var throne_texture: Texture2D

# Bush tiles (terrain bonus)
var bush_tiles = []
var bush_texture: Texture2D

# --- Tile Textures ---
var ground_textures = []
var wall_texture: Texture2D
var death_texture: Texture2D

# Random ground tile map (stores which ground variant per cell)
var tile_map = {}
var tile_map_generated := false

const GROUND_PATHS = [
	"res://assets/tileset/tile_ground_1.png",
	"res://assets/tileset/tile_ground_2.png",
]
const WALL_PATH = "res://assets/tileset/tile_wall.png"
const DEATH_PATH = "res://assets/tileset/tile_death.png"
const THRONE_PATH = "res://assets/tileset/tile_ground_3.png"
const BUSH_PATH = "res://assets/tileset/tile_bush.png"


func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_textures()


func _load_textures():
	for path in GROUND_PATHS:
		var tex = load(path)
		if tex:
			ground_textures.append(tex)

	wall_texture = load(WALL_PATH)
	death_texture = load(DEATH_PATH)
	throne_texture = load(THRONE_PATH)
	bush_texture = load(BUSH_PATH)


func generate_tile_map():
	tile_map.clear()
	if ground_textures.size() == 0:
		return
	for x in range(grid_width):
		for y in range(grid_height):
			tile_map[Vector2i(x, y)] = randi() % ground_textures.size()
	tile_map_generated = true


func _draw():
	# Generate tile map if needed (first draw or after stage change)
	if not tile_map_generated:
		generate_tile_map()

	# 1) Draw tiles
	for x in range(grid_width):
		for y in range(grid_height):
			var cell = Vector2i(x, y)
			var rect = Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)

			if cell in obstacles:
				if wall_texture:
					draw_texture_rect(wall_texture, rect, false)
				else:
					draw_rect(rect, Color(0.25, 0.22, 0.2))
			elif cell == throne_tile and throne_texture:
				draw_texture_rect(throne_texture, rect, false)
			else:
				if ground_textures.size() > 0 and tile_map.has(cell):
					var idx = tile_map[cell]
					draw_texture_rect(ground_textures[idx], rect, false)
				else:
					draw_rect(rect, Color(0.18, 0.35, 0.18))

	# 2) Draw bush tiles (on top of ground)
	for cell in bush_tiles:
		var rect = Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		if bush_texture:
			draw_texture_rect(bush_texture, rect, false)

	# 3) Draw death markers
	for cell in death_markers:
		var rect = Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		if death_texture:
			draw_texture_rect(death_texture, rect, false)
		else:
			var cx = cell.x * CELL_SIZE + CELL_SIZE / 2.0
			var cy = cell.y * CELL_SIZE + CELL_SIZE / 2.0
			var s = 14.0
			draw_line(Vector2(cx - s, cy - s), Vector2(cx + s, cy + s), Color(0.7, 0.1, 0.1, 0.8), 3.0)
			draw_line(Vector2(cx + s, cy - s), Vector2(cx - s, cy + s), Color(0.7, 0.1, 0.1, 0.8), 3.0)

	# 3) Draw enemy threat zone (orange-red)
	for cell in threat_highlighted_cells:
		var rect = Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		draw_rect(rect, Color(0.9, 0.3, 0.1, 0.3))

	# 4) Draw attack range (red)
	for cell in attack_highlighted_cells:
		var rect = Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		draw_rect(rect, Color(1.0, 0.2, 0.2, 0.35))

	# 5) Draw revive range (purple)
	for cell in revive_highlighted_cells:
		var rect = Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		draw_rect(rect, Color(0.6, 0.15, 0.8, 0.4))

	# 6) Draw movement highlights (blue)
	for cell in highlighted_cells:
		var rect = Rect2(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		draw_rect(rect, Color(0.2, 0.5, 1.0, 0.35))

	# 7) Draw grid lines
	var line_color = Color(0.3, 0.25, 0.15, 0.3)
	for x in range(grid_width + 1):
		draw_line(
			Vector2(x * CELL_SIZE, 0),
			Vector2(x * CELL_SIZE, grid_height * CELL_SIZE),
			line_color
		)
	for y in range(grid_height + 1):
		draw_line(
			Vector2(0, y * CELL_SIZE),
			Vector2(grid_width * CELL_SIZE, y * CELL_SIZE),
			line_color
		)


# --- Coordinate Helpers ---

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos = world_pos - position
	return Vector2i(int(local_pos.x / CELL_SIZE), int(local_pos.y / CELL_SIZE))


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	) + position


func is_within_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height


func is_walkable(pos: Vector2i) -> bool:
	return is_within_bounds(pos) and pos not in obstacles and pos not in occupied_cells


func grid_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


# --- BFS true distance (respects walls, ignores units) ---

func bfs_distance(from: Vector2i, to: Vector2i) -> int:
	if from == to:
		return 0

	var visited = {}
	var queue = []
	queue.append([from, 0])
	visited[from] = true

	while queue.size() > 0:
		var current = queue.pop_front()
		var pos: Vector2i = current[0]
		var cost: int = current[1]

		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for dir in directions:
			var next_pos: Vector2i = pos + dir
			if next_pos == to:
				return cost + 1
			if is_within_bounds(next_pos) and next_pos not in obstacles and not visited.has(next_pos):
				visited[next_pos] = true
				queue.append([next_pos, cost + 1])

	return -1


# --- Movement Range (BFS) ---

func get_movement_range(origin: Vector2i, move_range: int, bush_cost: int = 1) -> Array:
	var reachable = []
	var visited = {}
	var queue = []

	queue.append([origin, 0])
	visited[origin] = 0

	while queue.size() > 0:
		var current = queue.pop_front()
		var pos: Vector2i = current[0]
		var cost: int = current[1]

		if pos != origin:
			reachable.append(pos)

		if cost >= move_range:
			continue

		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for dir in directions:
			var next_pos: Vector2i = pos + dir
			if is_walkable(next_pos):
				var step_cost = bush_cost if next_pos in bush_tiles else 1
				var new_cost = cost + step_cost
				if not visited.has(next_pos) or new_cost < visited[next_pos]:
					if new_cost <= move_range:
						visited[next_pos] = new_cost
						queue.append([next_pos, new_cost])
						if next_pos not in reachable:
							reachable.append(next_pos)

	return reachable


# --- Pathfinding (BFS with parent tracking) ---

func find_path(origin: Vector2i, destination: Vector2i, move_range: int, bush_cost: int = 1) -> Array:
	var visited = {}
	var parent = {}
	var queue = []

	queue.append([origin, 0])
	visited[origin] = 0
	parent[origin] = null

	while queue.size() > 0:
		var current = queue.pop_front()
		var pos: Vector2i = current[0]
		var cost: int = current[1]

		if pos == destination:
			var path = []
			var step = destination
			while step != null:
				path.push_front(step)
				step = parent[step]
			return path

		if cost >= move_range:
			continue

		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for dir in directions:
			var next_pos: Vector2i = pos + dir
			if is_walkable(next_pos):
				var step_cost = bush_cost if next_pos in bush_tiles else 1
				var new_cost = cost + step_cost
				if new_cost <= move_range and (not visited.has(next_pos) or new_cost < visited[next_pos]):
					visited[next_pos] = new_cost
					parent[next_pos] = pos
					queue.append([next_pos, new_cost])

	return []


# --- Attack Range ---

func get_attack_range(origin: Vector2i, min_range: int, max_range: int) -> Array:
	var cells = []
	for x in range(-max_range, max_range + 1):
		for y in range(-max_range, max_range + 1):
			var dist = absi(x) + absi(y)
			if dist >= min_range and dist <= max_range:
				var cell = origin + Vector2i(x, y)
				if is_within_bounds(cell) and cell != origin:
					cells.append(cell)
	return cells


# --- Highlight Control ---

func show_movement_range(origin: Vector2i, move_range: int, bush_cost: int = 1):
	highlighted_cells = get_movement_range(origin, move_range, bush_cost)
	queue_redraw()


func show_attack_range(origin: Vector2i, min_range: int, max_range: int):
	attack_highlighted_cells = get_attack_range(origin, min_range, max_range)
	queue_redraw()


func show_revive_targets(cells: Array):
	revive_highlighted_cells = cells
	queue_redraw()


# --- Threat Range (movement + attack from every reachable tile) ---

func show_threat_range(origin: Vector2i, move_range: int, min_atk_range: int, max_atk_range: int, bush_cost: int = 1):
	var threat = {}

	var reachable = get_movement_range(origin, move_range, bush_cost)
	reachable.append(origin)

	for cell in reachable:
		threat[cell] = true
		var attack_cells = get_attack_range(cell, min_atk_range, max_atk_range)
		for atk_cell in attack_cells:
			threat[atk_cell] = true

	threat_highlighted_cells = threat.keys()
	queue_redraw()


func clear_highlights():
	highlighted_cells.clear()
	attack_highlighted_cells.clear()
	revive_highlighted_cells.clear()
	threat_highlighted_cells.clear()
	queue_redraw()


# --- Bush Tile Generation ---

func generate_bush_tiles(max_count: int):
	bush_tiles.clear()
	var mid_x = grid_width / 2
	var mid_y = grid_height / 2
	var range_x = 4
	var range_y = 3

	var candidates = []
	for x in range(mid_x - range_x, mid_x + range_x + 1):
		for y in range(mid_y - range_y, mid_y + range_y + 1):
			var cell = Vector2i(x, y)
			if is_within_bounds(cell) and cell not in obstacles and cell != throne_tile:
				candidates.append(cell)

	candidates.shuffle()
	var count = mini(max_count, candidates.size())
	for i in range(count):
		bush_tiles.append(candidates[i])
