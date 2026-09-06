extends BTNode
class_name ActionMoveTowardClosest

func tick(blackboard: BTBlackboard) -> BTNode.Status:
	#print("ActionMoveTowardClosest ticking")
	#print("movement_grid: ", blackboard.movement_grid)
	var unit := blackboard.unit
	var state := blackboard.state

	# Find closest player unit
	var closest: Character = null
	var closest_dist : float = 99999
	
	for other in state.units:
		if other.state.is_enemy():
			continue
		if not other.state.is_alive:
			continue
		var dist : float = abs(other.state.grid_position.x - unit.state.grid_position.x) \
					+ abs(other.state.grid_position.z - unit.state.grid_position.z)
		if dist < closest_dist:
			closest_dist = dist
			closest = other
	
	if closest == null:
		#print("FAIL: no closest found")
		return BTNode.Status.FAILURE
		
	print("Closest: ", closest.data.unit_name, " at ", closest.state.grid_position)
	# -- Pathfinding --
	#var path: Array[Vector3i] = blackboard.movement_grid.get_path(unit.state.grid_position, closest.state.grid_position)
	var path: Array[Vector3i] = MovementGrid.find_path(
		unit.state.grid_position,
		closest.state.grid_position,
		blackboard.weights_map)
	#print("Path length: ", path.size(), " path: ", path)
	if path.is_empty():
		#print("FAIL: no path found")
		return BTNode.Status.FAILURE
		
	# Find reachable move tile closest to the target by following path
	var moves := MoveGenerator.generate(unit, state)
	var reachable: Dictionary = {}	
	for cmd in moves:
		if not cmd is Move:
			continue
		else:
			reachable[cmd.end_pos] = cmd
	#print("Reachable tiles: ", reachable.keys())
	var best_move: Move = null
	## NOTE: path.size()-2 here because we exclude the occupied tile of the player unit
	for i in range(path.size() -2, -1, -1):
		var tile: Vector3i = path[i]
		if reachable.has(tile):
			best_move = reachable[tile]
			break
			
	if best_move == null:        
		print("FAIL: no path tile in reachable set")
		return BTNode.Status.FAILURE
	
	blackboard.target = closest
	blackboard.chosen_command = best_move
	print("Action fired: ", get_script().resource_path, " command: ", blackboard.chosen_command)
	return BTNode.Status.SUCCESS
