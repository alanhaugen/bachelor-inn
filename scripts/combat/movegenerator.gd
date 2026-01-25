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
	
	var movement_range : int = unit.state.movement
	if unit.state.is_moved:
		movement_range = 0
	
	while frontier.size() > 0:
		# --- priority queue pop (lowest cost first)
		frontier.sort_custom(func(a : Array, b : Array) -> int: return a[1] < b[1])
		var current : Array = frontier.pop_front()
		var pos : Vector3i = current[0]
		var current_cost : int = current[1]
		
		if current_cost > movement_range:
			continue
		
		if visited.has(pos):
			continue
		visited[pos] = true
		
		if pos != start_pos and not reachable.has(pos):
			reachable.append(pos)
		
		# --- explore neighbors in XZ plane
		var offsets := [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]
		
		for offset: Vector3i in offsets:
			var neighbor_xz : Vector3i = Vector3i(pos.x + offset.x, 0, pos.z + offset.z)
			var candidates := state.get_tiles_at_xz(neighbor_xz.x, neighbor_xz.z)
			if candidates.is_empty():
				continue
			
			# --- pick topmost walkable tile
			var top_walkable : Vector3i = Vector3i() # placeholder
			var found_walkable := false

			for t: Vector3i in candidates:
				if state.is_free(t):
					top_walkable = t
					found_walkable = true
					break

			if not found_walkable:
				continue # no walkable tile

			for t: Vector3i in candidates:
				if state.is_free(t) and t.y > top_walkable.y:
					top_walkable = t

			var neighbor : Vector3i = top_walkable
			
			# --- enemies
			if state.is_enemy(neighbor):
				if not attacks.has(neighbor):
					attacks.append(neighbor)
				# do not continue — allow pathfinding around enemies
			
			# --- vertical movement restriction
			if abs(neighbor.y - pos.y) > 1:
				continue
			
			var tile_cost : int = state.get_tile_cost(neighbor)
			var new_cost : int = current_cost + tile_cost
			
			if new_cost > movement_range:
				continue
			
			if not cost_so_far.has(neighbor) or new_cost < cost_so_far[neighbor]:
				cost_so_far[neighbor] = new_cost
				frontier.append([neighbor, new_cost])
	
	# --- build commands
	if not unit.state.is_moved:
		for tile in reachable:
			commands.append(Move.new(start_pos, tile))
	
	if not unit.state.is_ability_used:
		for tile in attacks:
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
