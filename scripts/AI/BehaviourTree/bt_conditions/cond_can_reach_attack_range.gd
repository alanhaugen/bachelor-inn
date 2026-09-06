extends BTNode
class_name ConditionCanReachAttackRange

func tick(blackboard: BTBlackboard) -> BTNode.Status:
	var unit := blackboard.unit
	var state := blackboard.state
	
	var min_range := unit.state.weapon.min_range
	var max_range := unit.state.weapon.max_range

	var moves := MoveGenerator.generate(unit, state)
	var reachable: Array[Vector3i] = [unit.state.grid_position]
	for cmd in moves:
		if cmd is Move:
			reachable.append(cmd.end_pos)
	
	var closest: Character = null
	var closest_dist: float = 99999.0
	for other in state.units:
		if other.state.is_enemy():
			continue
		if not other.state.is_alive:
			continue
		var dist: float = abs(other.state.grid_position.x - unit.state.grid_position.x) + abs(other.state.grid_position.z - unit.state.grid_position.z)
		if dist < closest_dist:
			closest_dist = dist
			closest = other
	
	if closest == null:
		return BTNode.Status.FAILURE
	
	# Find reachable tile with ideal attackrang
	var best_origin: Vector3i = Vector3i.ZERO
	var best_dist_to_ideal: float = 99999.0
	var ideal_range: float = float(max_range)
	
	for origin in reachable:
		var dist: float = abs(closest.state.grid_position.x - origin.x) + abs(closest.state.grid_position.z - origin.z)
		if dist >= min_range and dist <= max_range:
			# Already within weapon range
			continue
		var dist_to_ideal: float = abs(dist - ideal_range)
		if dist_to_ideal < best_dist_to_ideal:
			best_dist_to_ideal = dist_to_ideal
			best_origin = origin
		
	if best_origin == Vector3i.ZERO:
		return BTNode.Status.FAILURE
	
	blackboard.target = closest
	blackboard.attack_origin = best_origin
	return BTNode.Status.SUCCESS
