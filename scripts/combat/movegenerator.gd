class_name MoveGenerator
extends RefCounted

static func generate(unit : Character, state : GameState) -> Array[Command]:
	var moves : Array[Command] = dijkstra(unit, state);
	return moves;


static func dijkstra(unit : Character, state : GameState) -> Array[Command]:
	var frontier := 0
	var frontierPositions :Array = []
	var nextFrontierPositions :Array = []
	var visited :Dictionary = {}
	var commands :Array[Command] = []
	var reachable :Array[Vector3i] = []
	var attacks :Array[Vector3i] = []

	var start_pos :Vector3i = unit.grid_position
	frontierPositions.append(start_pos)
	visited[start_pos] = true

	while frontier < unit.movement and frontierPositions.is_empty() == false:
		var pos :Vector3i = frontierPositions.pop_front()

		var directions := [
			Vector3i(pos.x, 0, pos.z - 1),
			Vector3i(pos.x, 0, pos.z + 1),
			Vector3i(pos.x + 1, 0, pos.z),
			Vector3i(pos.x - 1, 0, pos.z)
		]

		if unit.is_moved == false:
			for dir : Vector3i in directions:
				if dir == start_pos:
					continue
				if visited.has(dir):
					continue;
				if state.is_inside_map(dir) and state.is_free(dir):
					visited[dir] = true
					nextFrontierPositions.append(dir)
					if not reachable.has(dir):
						reachable.append(dir);
				if state.is_enemy(dir):
					if not attacks.has(dir):
						attacks.append(dir);
		
		if frontierPositions.is_empty():
			frontier += 1
			frontierPositions = nextFrontierPositions.duplicate()
			nextFrontierPositions.clear()
	
	for tile :Vector3i in reachable:
		commands.append(
			Move.new(start_pos, tile, unit.speciality, unit)
		);
	
	for tile :Vector3i in attacks:
		commands.append(
			Attack.new(tile, unit, null)
		);
	
	return commands;
