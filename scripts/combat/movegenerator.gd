class_name MoveGenerator
extends RefCounted

static func generate(unit : Character, state : GameState) -> Array[Move]:
	var moves : Array[Move] = dijkstra(unit, state);
	return moves;


static func dijkstra(unit : Character, state : GameState) -> Array[Move]:
	var frontier :int = 0;
	var frontierPositions :Array;
	var nextFrontierPositions :Array;
	
	var pos: Vector3i = unit.position;
	var moves: Array[Move];
	
	frontierPositions.append(pos);
	
	while (frontier < unit.movement && frontierPositions.is_empty() == false):
		pos = frontierPositions.pop_front();
		
		var north : Vector3i = Vector3i(pos.x, 0, pos.z - 1);
		var south : Vector3i = Vector3i(pos.x, 0, pos.z + 1);
		var east  : Vector3i = Vector3i(pos.x + 1, 0, pos.z);
		var west  : Vector3i = Vector3i(pos.x - 1, 0, pos.z);
		
		var directions : Array[Vector3i] = [north, south, east, west];
		
		# Only register commands for characters that have not moved yet
		if unit.is_moved == false:
			for dir in directions:
				if state.is_inside_map(dir) and state.is_free(dir):
					nextFrontierPositions.append(dir);
					#moves.append(Move.new(startPos, north, type, units_map, selected_unit));
			
		if (frontierPositions.is_empty() == true):
			frontier += 1;
			frontierPositions = nextFrontierPositions.duplicate();
			nextFrontierPositions.clear();
	
	return moves;
