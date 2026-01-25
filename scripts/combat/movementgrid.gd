extends Grid
class_name MovementGrid

#region constants
const DIRECTIONS := [
	Vector3i(1, 0, 0),
	Vector3i(-1, 0, 0),
	Vector3i(0, 0, 1),
	Vector3i(0, 0, -1)
]
#endregion

#region State variables
var cost_map : Dictionary = {} # Vector3i -> int
var used_cells : Dictionary = {} # Vector3i -> bool
#endregion


#region methods
func _init(movement_overlay : GridMap) -> void:
	grid = movement_overlay
	grid.clear();


func get_cost(pos : Vector3i) -> int:
	return cost_map.get(pos, 1)


func is_blocked(pos : Vector3i) -> bool:
	return not is_walkable(pos)


func clear() -> void:
	grid.clear()
	cost_map.clear()
	used_cells.clear()


func fill(tiles : Array[GridTile]) -> void:
	clear()
	
	for tile : GridTile in tiles:
		set_tile(tile)


func fill_from_commands(commands : Array[Command], state : GameState) -> void:
	clear()
	
	for command : Command in commands:
		var tile : GridTile
		var weight := state.get_tile_cost(command.end_pos)
		
		if command is Attack:
			tile = GridTile.new(command.attack_pos, GridTile.Type.ATTACK, 9999999)
		
		elif command is Move:
			tile = GridTile.new(command.end_pos, GridTile.Type.MOVE, weight)
		
		if tile:
			set_tile(tile)


func set_tile(tile : GridTile) -> void:
	cost_map[tile.pos] = tile.weight
	used_cells[tile.pos] = true
	grid.set_cell_item(tile.pos, tile.type)


func set_move_tile(pos : Vector3i) -> void:
	grid.set_cell_item(pos, GridTile.Type.MOVE)


func set_attack_tile(pos : Vector3i) -> void:
	grid.set_cell_item(pos, GridTile.Type.ATTACK)


# Heuristic: Manhattan distance for grid
func heuristic(a: Vector3i, b: Vector3i) -> float:
	return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)


# Reconstruct path from came_from dictionary
func reconstruct_path(came_from: Dictionary, current: Vector3i) -> Array[Vector3i]:
	var total_path:Array[Vector3i] = [current]
	while came_from.has(current):
		current = came_from[current]
		total_path.insert(0, current)
	return total_path


func get_path(start : Vector3i, goal : Vector3i) -> Array[Vector3i]:
	var open_set := [start]
	var came_from := {}
	var g_score := {start: 0.0}
	var f_score := {start: heuristic(start, goal)}

	while open_set.size() > 0:
		# Find the node in open_set with the lowest f_score
		var current: Vector3i = open_set[0]
		var lowest_f: float = f_score.get(current, INF)
		for node: Vector3i in open_set:
			if f_score.get(node, INF) < lowest_f:
				current = node
				lowest_f = f_score[node]

		# Check if we reached the goal
		if current == goal:
			return reconstruct_path(came_from, current)

		open_set.erase(current)

		# Check neighbors
		for dir: Vector3i in DIRECTIONS:
			var neighbor := current + dir
			if not is_walkable(neighbor, current):
				continue

			var tentative_g: float = g_score[current] + get_cost(neighbor)

			if not g_score.has(neighbor) or tentative_g < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + heuristic(neighbor, goal)
				if not open_set.has(neighbor):
					open_set.append(neighbor)

	# No path found
	return []
#endregion
