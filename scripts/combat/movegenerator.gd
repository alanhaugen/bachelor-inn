extends RefCounted
class_name MoveGenerator


#region methods
static func generate(unit : Character, state : GameState) -> Array[Command]:
	var moves : Array[Command] = dijkstra(unit, state);
	return moves;


static func dijkstra(unit : Character, state : GameState) -> Array[Command]:
	var start_pos : Vector3i = unit.state.grid_position
	
	var frontier : Array = [] # acts as priority queue: [pos, cost]
	var cost_so_far : Dictionary = {}
	var visited : Dictionary = {}
	
	var reachable : Array[Vector3i] = []
	var attacks : Array[Vector3i] = []
	var commands : Array[Command] = []
	
	frontier.append([start_pos, 0])
	cost_so_far[start_pos] = 0
	
	while frontier.is_empty() == false:
		# --- priority queue pop (lowest cost first)
		frontier.sort_custom(func(a : Array, b : Array) -> int: return a[1] < b[1])
		var current : Array = frontier.pop_front();
		var pos : Vector3i = current[0]
		var current_cost : int = current[1]
		
		if current_cost > unit.state.movement:
			continue
		
		if visited.has(pos):
			continue
		visited[pos] = true
		
		if pos != start_pos and not reachable.has(pos):
			reachable.append(pos)
		
		var directions := [
			Vector3i(pos.x, 0, pos.z - 1),
			Vector3i(pos.x, 0, pos.z + 1),
			Vector3i(pos.x + 1, 0, pos.z),
			Vector3i(pos.x - 1, 0, pos.z)
		]
		
		for dir : Vector3i in directions:
			if not state.is_inside_map(dir):
				continue
			
			if state.is_enemy(dir):
				if not attacks.has(dir):
					attacks.append(dir)
				continue
			
			if not state.is_free(dir):
				continue
			
			var tile_cost : int = state.get_tile_cost(dir)
			var new_cost : int = current_cost + tile_cost
			
			if new_cost > unit.state.movement:
				continue
			
			if not cost_so_far.has(dir) or new_cost < cost_so_far[dir]:
				cost_so_far[dir] = new_cost
				frontier.append([dir, new_cost])
	
	# --- build commands
	for tile : Vector3i in reachable:
		commands.append(Move.new(start_pos, tile))
	
	for tile : Vector3i in attacks:
		var neighbour := start_pos
		if not is_neighbour(start_pos, tile):
			neighbour = get_valid_neighbour(tile, reachable)
		commands.append(Attack.new(start_pos, tile, neighbour))
	
	commands.append(Wait.new(start_pos))
	
	return commands


static func is_neighbour(pos : Vector3i, end_pos : Vector3i) -> bool:
	var directions := [
			Vector3i(pos.x, 0, pos.z - 1),
			Vector3i(pos.x, 0, pos.z + 1),
			Vector3i(pos.x + 1, 0, pos.z),
			Vector3i(pos.x - 1, 0, pos.z)
		]
	
	if end_pos in directions:
		return true
	
	return false


static func get_valid_neighbour(pos : Vector3i, reachable : Array[Vector3i]) -> Vector3i:
	var directions := [
			Vector3i(pos.x, 0, pos.z - 1),
			Vector3i(pos.x, 0, pos.z + 1),
			Vector3i(pos.x + 1, 0, pos.z),
			Vector3i(pos.x - 1, 0, pos.z)
		]
	
	for tile in reachable:
		if tile in directions:
			return tile
	
	return Vector3i(-1, -1, -1)


static func get_valid_neighbours(pos : Vector3i, reachable : Array[Vector3i]) -> Array[Vector3i]:
	var directions := [
			Vector3i(pos.x, 0, pos.z - 1),
			Vector3i(pos.x, 0, pos.z + 1),
			Vector3i(pos.x + 1, 0, pos.z),
			Vector3i(pos.x - 1, 0, pos.z)
		]
	
	var valid : Array[Vector3i] = []
	
	for tile in reachable:
		if tile in directions:
			valid.append(tile)
	
	return valid
#endregion
