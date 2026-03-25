extends RefCounted
class_name MoveGenerator

#region methods
static func generate(unit : Character, state : GameState, exclude_attacks : bool = false, exclude_move : bool = false) -> Array[Command]:
	var moves : Array[Command] = dijkstra(unit, state, exclude_attacks, exclude_move);
	return moves;



static func dijkstra(unit : Character, state : GameState, exclude_attacks : bool = false, exclude_move : bool = false) -> Array[Command]:
	var start_pos: Vector3i = unit.state.grid_position

	# Priority queue: [pos, cost]
	var frontier: Array = []
	var cost_so_far: Dictionary = {}
	var visited: Dictionary = {}

	var reachable: Array[Vector3i] = []
	var commands: Array[Command] = []

	frontier.append([start_pos, 0])
	cost_so_far[start_pos] = 0

	#var movement_range: int = unit.state.movement
	var movement_range: int = unit.state.get_effective_movement() 
	## TODO: Spells/Abilities - add an effect checker for buffs/debuffs
	## This TODO is kind of done.
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
	if !exclude_move:
		if not unit.state.is_moved:
			for tile: Vector3i in reachable:
				commands.append(Move.new(start_pos, tile))

	# -------------------------
	# 3) Build ALL ATTACK commands
	#    (Temporary rule: weapon range == movement_range)
	#    (Temporary rule: enemy must be on same y as origin)
	# -------------------------
	if !exclude_attacks:
		## TODO: Get attack origins per selected enemy, not all enemies.
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

## returns array of Attack
static func generate_attack(unit : Character, game_state : GameState) -> Array[Command]:
	var moves : Array[Command]
	if unit == null:
		return moves
	if unit.state.is_ability_used:
		return moves
	
	var targets : Array[Vector3i]
	
	var start : Vector3i = unit.state.grid_position
	var max_depth : int = unit.state.weapon.max_range
	var min_depth : int = unit.state.weapon.min_range
	
	var consider_terrain_cost : bool = false
	var include_start_in_output : bool = false
	var go_through_heroes : bool = true
	var go_through_monsters : bool = true
	
	var go_through_empty_tiles : bool = true
	var include_empty_tiles_in_output : bool = false
	
	match unit.state.faction:
		CharacterState.Faction.PLAYER:
			
			var include_hero_tiles_in_output : bool = false
			var include_monster_tiles_in_output : bool = true
			
			targets = basic_dijkstra(game_state, start, max_depth, min_depth,
				consider_terrain_cost, include_start_in_output,
				go_through_heroes, go_through_monsters,
				include_hero_tiles_in_output, include_monster_tiles_in_output,
				go_through_empty_tiles, include_empty_tiles_in_output)
			
		CharacterState.Faction.ENEMY:
			
			var include_hero_tiles_in_output : bool = true
			var include_monster_tiles_in_output : bool = false
			
			targets = basic_dijkstra(game_state, start, max_depth, min_depth,
				consider_terrain_cost, include_start_in_output,
				go_through_heroes, go_through_monsters,
				include_hero_tiles_in_output, include_monster_tiles_in_output,
				go_through_empty_tiles, include_empty_tiles_in_output)
			
		_:
			return moves
	
	for target : Vector3i in targets:
		moves.append(Attack.new(start, target, start))
	
	return moves;

## returns an array of Move
static func generate_move(unit : Character, game_state : GameState, store_path : bool = false) -> Array[Command]:
	var moves : Array[Command]
	if unit == null:
		return moves
	if unit.state.is_moved:
		return moves
	
	var targets : Array[Vector3i]
	
	var start : Vector3i = unit.state.grid_position
	var max_depth : int = unit.state.movement
	var min_depth : int = 0
	
	match unit.state.faction:
		CharacterState.Faction.PLAYER:
			
			var consider_terrain_cost : bool = true
			var include_start_in_output : bool = true
			var go_through_heroes : bool = true
			var go_through_monsters : bool = false
			var include_hero_tiles_in_output : bool = false
			var include_monster_tiles_in_output : bool = false
			var go_through_empty_tiles : bool = true
			var include_empty_tiles_in_output : bool = true
			
			targets = basic_dijkstra(game_state, start, max_depth, min_depth,
				consider_terrain_cost, include_start_in_output,
				go_through_heroes, go_through_monsters,
				include_hero_tiles_in_output, include_monster_tiles_in_output,
				go_through_empty_tiles, include_empty_tiles_in_output,
				store_path)
			
		CharacterState.Faction.ENEMY:
			
			var consider_terrain_cost : bool = true
			var include_start_in_output : bool = true
			var go_through_heroes : bool = false
			var go_through_monsters : bool = true
			var include_hero_tiles_in_output : bool = false
			var include_monster_tiles_in_output : bool = false
			var go_through_empty_tiles : bool = true
			var include_empty_tiles_in_output : bool = true
			
			targets = basic_dijkstra(game_state, start, max_depth, min_depth,
				consider_terrain_cost, include_start_in_output,
				go_through_heroes, go_through_monsters,
				include_hero_tiles_in_output, include_monster_tiles_in_output,
				go_through_empty_tiles, include_empty_tiles_in_output)
			
		_:
			return moves
	
	for target : Vector3i in targets:
		moves.append(Move.new(start, target))
	
	return moves;

## a dictionary of positions, where the value is the previous position to get to a position.
## The initial position has itself as parent
static var movement_path : Dictionary[Vector3i, Vector3i] = {}

## returns an array of positiond. order is from to_pos to root node.
## array is empty if no path was found
static func get_movement_path_array(to_pos : Vector3i) -> Array[Vector3i]:
	var path : Array[Vector3i] = []
	if !movement_path.has(to_pos):
		return path
	var visited : Dictionary[Vector3i, bool] = {}
	var current : Vector3i = to_pos
	
	while true:
		if visited.has(current):
			break
		visited[current] = true
		path.append(current)
		current = movement_path[current]
	return path

static func basic_dijkstra
(
	game_state : GameState, start : Vector3i,
	max_depth : int, min_depth : int = 0,
	consider_terrain_cost : bool = false, include_start_in_output : bool = false,
	go_through_heroes : bool = false, go_through_monsters : bool = false,
	include_hero_tiles_in_output : bool = false, include_monster_tiles_in_output : bool = false,
	go_through_empty_tiles : bool = true, include_empty_tiles_in_output : bool = true,
	store_path : bool = false
) -> Array[Vector3i]:
	var level : Level = Main.level
	# Priority queue: [pos, cost]
	var frontier: Array = []
	var cost_so_far: Dictionary = {}
	var visited: Dictionary = {}

	var reachable: Array[Vector3i] = []

	frontier.append([start, 0])
	cost_so_far[start] = 0
	
	if store_path:
		movement_path.clear()
		movement_path[start] = start
	
	if include_start_in_output:
		reachable.append(start)
	
	while frontier.size() > 0:
		# lowest cost first
		frontier.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
		var current: Array = frontier.pop_back()
		var pos: Vector3i = current[0]
		var current_cost: int = current[1]

		if current_cost > max_depth:
			continue

		if visited.has(pos):
			continue
		visited[pos] = true

		if pos != start && not reachable.has(pos):
			var unit : Character = game_state.get_unit(pos)
			var add_to_reachable : bool = true
			if(unit != null):
				match unit.state.faction:
					CharacterState.Faction.PLAYER:
						if !include_hero_tiles_in_output:
							add_to_reachable = false
					CharacterState.Faction.ENEMY:
						if !include_monster_tiles_in_output:
							add_to_reachable = false
					_:
						add_to_reachable = false
			else:
				if(!include_empty_tiles_in_output):
					add_to_reachable = false
			if current_cost < min_depth:
				add_to_reachable = false
			if add_to_reachable:
				reachable.append(pos)

		# Explore neighbors in XZ plane (keep your elevation logic)
		var offsets : Array[Vector3i] = [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,0,1), Vector3i(0,0,-1)]

		for offset: Vector3i in offsets:
			var neighbor_xz: Vector3i = Vector3i(pos.x + offset.x, 0, pos.z + offset.z)
			var found : bool = false
			var neighbor : Vector3i
			
			if level.movement_weights_map.get_cell_item(neighbor_xz + Vector3i(0, 1, 0)) != GridMap.INVALID_CELL_ITEM:
				if level.movement_weights_map.get_cell_item(neighbor_xz + Vector3i(0, 2, 0)) == GridMap.INVALID_CELL_ITEM:
					neighbor = neighbor_xz + Vector3i(0, 1, 0)
					found = true
			elif level.movement_weights_map.get_cell_item(neighbor_xz) != GridMap.INVALID_CELL_ITEM:
				neighbor = neighbor_xz
				found = true
			elif level.movement_weights_map.get_cell_item(neighbor_xz + Vector3i(0, -1, 0)) != GridMap.INVALID_CELL_ITEM:
				neighbor = neighbor_xz + Vector3i(0, -1, 0)
				found = true
			
			if !found:
				continue
			
			var passable : bool = false
			
			## test if unit is blocking search
			var blocking_unit : Character = game_state.get_unit(neighbor)
			if blocking_unit == null:
				if go_through_empty_tiles:
					passable = true
			else:
				match blocking_unit.state.faction:
					CharacterState.Faction.PLAYER:
						if go_through_heroes:
							passable = true
					CharacterState.Faction.ENEMY:
						if go_through_monsters:
							passable = true
					_:
						passable = false
			
			if !passable:
				continue

			# Vertical step limit
			# TODO: useless code? test and remove
			if abs(neighbor.y - pos.y) > 1:
				continue

			var tile_cost: int = 1
			if consider_terrain_cost:
				var weight_id : int = level.movement_weights_map.get_cell_item(neighbor);
				var weight_type : String = level.movement_weights_map.mesh_library.get_item_name(weight_id);
				tile_cost = Terrain.get_weight(weight_type)
			var new_cost: int = current_cost + tile_cost

			if new_cost > max_depth:
				continue

			if not cost_so_far.has(neighbor) or new_cost < int(cost_so_far[neighbor]):
				cost_so_far[neighbor] = new_cost
				frontier.append([neighbor, new_cost])
				if store_path:
					movement_path[neighbor] = pos
	return reachable

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
	var w: Weapon = WeaponRegistry.get_weapon(unit.state.weapon.weapon_id)
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
