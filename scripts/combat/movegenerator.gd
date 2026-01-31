extends RefCounted
class_name MoveGenerator


#region methods
static func generate(unit : Character, state : GameState) -> Array[Command]:
	var moves : Array[Command] = dijkstra(unit, state);
	return moves;



static func dijkstra(unit : Character, state : GameState) -> Array[Command]:
	var start_pos: Vector3i = unit.state.grid_position

	# Priority queue: [pos, cost]
	var frontier: Array = []
	var cost_so_far: Dictionary = {}
	var visited: Dictionary = {}

	var reachable: Array[Vector3i] = []
	var commands: Array[Command] = []

	frontier.append([start_pos, 0])
	cost_so_far[start_pos] = 0

	var movement_range: int = unit.state.movement
	if unit.state.is_moved:
		movement_range = 0

	# -------------------------
	# 1) Dijkstra for reachables
	# -------------------------
	while frontier.size() > 0:
		# lowest cost first
		frontier.sort_custom(func(a: Array, b: Array) -> bool: return a[1] < b[1])
		var current: Array = frontier.pop_front()
		var pos: Vector3i = current[0]
		var current_cost: int = current[1]

		if current_cost > movement_range:
			continue

		if visited.has(pos):
			continue
		visited[pos] = true

		if pos != start_pos and not reachable.has(pos):
			reachable.append(pos)

		# Explore neighbors in XZ plane (keep your elevation logic)
		var offsets := [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]

		for offset: Vector3i in offsets:
			var neighbor_xz: Vector3i = Vector3i(pos.x + offset.x, 0, pos.z + offset.z)
			var candidates: Array[Vector3i] = state.get_tiles_at_xz(neighbor_xz.x, neighbor_xz.z)
			if candidates.is_empty():
				continue

			# Find topmost WALKABLE tile at this XZ
			var best_walkable: Vector3i = Vector3i()
			var has_walkable := false
			for t: Vector3i in candidates:
				if state.is_free(t):
					if not has_walkable or t.y > best_walkable.y:
						best_walkable = t
						has_walkable = true

			if not has_walkable:
				continue

			var neighbor: Vector3i = best_walkable

			# Vertical step limit
			if abs(neighbor.y - pos.y) > 1:
				continue

			var tile_cost: int = state.get_tile_cost(neighbor)
			var new_cost: int = current_cost + tile_cost

			if new_cost > movement_range:
				continue

			if not cost_so_far.has(neighbor) or new_cost < int(cost_so_far[neighbor]):
				cost_so_far[neighbor] = new_cost
				frontier.append([neighbor, new_cost])

	# -------------------------
	# 2) Build MOVE commands
	# -------------------------
	if not unit.state.is_moved:
		for tile: Vector3i in reachable:
			commands.append(Move.new(start_pos, tile))

	# -------------------------
	# 3) Build ALL ATTACK commands
	#    (Temporary rule: weapon range == movement_range)
	#    (Temporary rule: enemy must be on same y as origin)
	# -------------------------
	if not unit.state.is_ability_used:
		# Include "attack from current position"
		var attack_origins: Array[Vector3i] = [start_pos]
		for r: Vector3i in reachable:
			attack_origins.append(r)

		var min_r := unit.state.weapon.min_range
		var max_r := unit.state.weapon.max_range

		# de-dupe origin->target pairs
		var seen_pairs: Dictionary = {}

		for origin: Vector3i in attack_origins:
			for dx in range(-max_r, max_r + 1):
				for dz in range(-max_r, max_r + 1):
					var dist : int = abs(dx) + abs(dz)
					if dist < min_r or dist > max_r:
						continue

					var x := origin.x + dx
					var z := origin.z + dz

					# Check all tiles at this XZ and pick enemies that match origin height (y)
					var tiles_here: Array[Vector3i] = state.get_tiles_at_xz(x, z)
					if tiles_here.is_empty():
						continue

					for t: Vector3i in tiles_here:
						if t.y != origin.y:
							continue
						if not state.is_enemy(t):
							continue

						# De-dupe by origin and target (XZ+Y as chosen)
						var key := str(origin.x)+","+str(origin.y)+","+str(origin.z)+"->"+str(t.x)+","+str(t.y)+","+str(t.z)
						if seen_pairs.has(key):
							continue
						seen_pairs[key] = true

						commands.append(Attack.new(start_pos, t, origin))

	# -------------------------
	# 4) Always allow WAIT
	# -------------------------
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


static func get_attack_origins(unit: Character, state: GameState, start_pos: Vector3i, reachable: Array[Vector3i]) -> Array[Vector3i]:
	# Include "attack from current position"
	var origins: Array[Vector3i] = [start_pos]
	for r in reachable:
		origins.append(r)

	# Temporary rule: enemy must share same height as origin
	# Weapon range from registry
	var w: Weapon = WeaponRegistry.get_weapon(unit.data.weapon_id)
	var min_r: int = w.min_range
	var max_r: int = w.max_range

	var valid: Array[Vector3i] = []
	var seen: Dictionary = {} # de-dupe by position

	for origin in origins:
		var origin_key := str(origin.x) + "," + str(origin.y) + "," + str(origin.z)
		if seen.has(origin_key):
			continue
		seen[origin_key] = true

		if _has_enemy_in_range_from_origin(origin, min_r, max_r, unit, state):
			valid.append(origin)

	return valid


static func _has_enemy_in_range_from_origin(
	origin: Vector3i,
	min_r: int,
	max_r: int,
	unit: Character,
	state: GameState
) -> bool:
	# Manhattan distance in XZ, height must match (for now)
	for dx in range(-max_r, max_r + 1):
		for dz in range(-max_r, max_r + 1):
			var dist : int = abs(dx) + abs(dz)
			if dist < min_r or dist > max_r:
				continue

			var x := origin.x + dx
			var z := origin.z + dz
			var tiles_here: Array[Vector3i] = state.get_tiles_at_xz(x, z)
			if tiles_here.is_empty():
				continue

			for t in tiles_here:
				if t.y != origin.y:
					continue
				if state.is_enemy(t):
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
