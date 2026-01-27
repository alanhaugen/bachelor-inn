extends RefCounted
class_name MoveGenerator


#region methods
static func generate(unit : Character, state : GameState) -> Array[Command]:
	var moves : Array[Command] = dijkstra(unit, state);
	return moves;


static func dijkstra(unit : Character, state : GameState) -> Array[Command]:
	#var start_pos : Vector3i = unit.state.grid_position
	var start_pos : Vector3i = Vector3i(unit.state.grid_position.x, 0, unit.state.grid_position.z)

	var frontier : Array = [] # acts as priority queue: [pos, cost]
	var cost_so_far : Dictionary = {} # should be finetuned to find cheapest attack move
	var visited : Dictionary = {}
	
	var reachable : Array[Vector3i] = []
	var attacks : Array[Vector3i] = []
	var commands : Array[Command] = []
	
	frontier.append([start_pos, 0])
	cost_so_far[start_pos] = 0
	
	while frontier.is_empty() == false:
		# --- priority queue pop (lowest cost first)
		frontier.sort_custom(func(a : Array, b : Array) -> bool: return a[1] < b[1])
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
			
			## new attack append further down
			if state.is_enemy(dir):
			#	if not attacks.has(dir):
			#		attacks.append(dir)
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
	
	# --- attack range
	var w := unit.get_weapon()
	var min_attack_range : int = 1
	var max_attack_range : int = 1
	if w != null:
		min_attack_range = w.min_range
		max_attack_range = w.max_range
		
	# --- where we can attack from
	var attack_origins: Array[Vector3i] = [start_pos]
	for r in reachable:
		attack_origins.append(r)
	
# --- build ALL attack options (origin -> enemy target)
# Track pairs to avoid duplicates: key = "ox,oz->tx,tz"
	var seen_pairs: Dictionary = {}

	for origin: Vector3i in attack_origins:
		var origin0 := Vector3i(origin.x, 0, origin.z)

		for target: Vector3i in tiles_in_range(origin0, min_attack_range, max_attack_range, state):
			# target is on unit/occupancy layer (likely y=1)
			if not state.is_enemy(target):
				continue

			# de-dupe by XZ (y differences shouldn't create separate attacks)
			var key := str(origin0.x) + "," + str(origin0.z) + "->" + str(target.x) + "," + str(target.z)
			if seen_pairs.has(key):
				continue
			seen_pairs[key] = true

			# start_pos should be y=0 for movement/pathing consistency
			var start0 := Vector3i(start_pos.x, 0, start_pos.z)

			commands.append(Attack.new(start0, target, origin0))
			
		## UI friendly y values
		#var t0 := Vector3i(target.x, 0, target.z)           # target pos with y = 0
		#var o  := item["origin"] as Vector3i                # origin
		#var o0 := Vector3i(o.x, 0, o.z)                     # origin pos with y = 0
		#var s0 := Vector3i(start_pos.x, 0, start_pos.z)     # start pos with y = 0

		#commands.append(Attack.new(s0, t0, o0))

	## this is melee only
	#for tile : Vector3i in attacks:
	#	var neighbour := start_pos
	#	if not is_neighbour(start_pos, tile):
	#		neighbour = get_valid_neighbour(tile, reachable)
	#		
	#	if neighbour.x != -1:
	#		commands.append(Attack.new(start_pos, tile, neighbour))
	
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


static func tiles_in_range(origin: Vector3i, min_r: int, max_r: int, state: GameState) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for dx in range(-max_r, max_r + 1):
		for dz in range(-max_r, max_r + 1):
			var d : int = abs(dx) + abs(dz)
			
			if d < min_r or d > max_r:
				continue
				
			var p := Vector3i(origin.x + dx, 1, origin.z + dz) # y = 1 because we need it to work for now
			
			if state.is_inside_map(p):
				result.append(p)
				
	return result

#endregion
