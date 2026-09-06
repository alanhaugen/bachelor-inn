extends BTNode
class_name ActionFlee

func tick(blackboard: BTBlackboard) -> BTNode.Status:
	var unit := blackboard.unit
	var state := blackboard.state
	var threat := blackboard.target

	if threat == null:
		return BTNode.Status.FAILURE
	
	# Find the tile furthest away 
	var farthest_tile : Vector3i = unit.state.grid_position
	var farthest_dist : float = -1.0
	for cell in Main.level.movement_weights_map.get_used_cells():
		var dist: float = abs(cell.x - threat.state.grid_position.x) + abs(cell.z - threat.state.grid_position.z)
		if dist > farthest_dist:
			farthest_tile = cell
			farthest_dist = dist
	if farthest_tile == unit.state.grid_position:
		return BTNode.Status.FAILURE
	
	var path: Array[Vector3i] = MovementGrid.find_path(
		unit.state.grid_position, farthest_tile, blackboard.weights_map
	)
	
	if path.is_empty():
		return BTNode.Status.FAILURE
	
	# Generate all reachable move tiles
	var moves := MoveGenerator.generate(unit, state)
	var reachable: Dictionary = {}
	for cmd in moves:
		if cmd is Move:
			reachable[cmd.end_pos] = cmd
	
	var best_move: Move = null
	for i in range(path.size() -1, -1, -1):
		var tile: Vector3i = path[i]
		if reachable.has(tile):
			best_move = reachable[tile]
			break
	if best_move == null:
		return BTNode.Status.FAILURE
	
	blackboard.chosen_command = best_move
	#print("Action fired: ", get_script().resource_path, " command: ", blackboard.chosen_command)
	return BTNode.Status.SUCCESS
