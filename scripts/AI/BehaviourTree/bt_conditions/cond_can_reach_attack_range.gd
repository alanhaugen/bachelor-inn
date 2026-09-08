extends BTNode
class_name ConditionCanReachAttackRange

func tick(blackboard: BTBlackboard) -> BTNode.Status:
	var unit := blackboard.unit
	var state := blackboard.state
	var min_range := unit.state.weapon.min_range
	var max_range := unit.state.weapon.max_range
	#print("ConditionCanReachAttackRange: ", unit.data.unit_name, " weapon=", min_range, "-", max_range, " pos=", unit.state.grid_position)
	var moves := MoveGenerator.generate(unit, state)
	var reachable: Array[Vector3i] = [unit.state.grid_position]
	for cmd in moves:
		if cmd is Move:
			reachable.append(cmd.end_pos)
	
	var best_origin: Vector3i = Vector3i.ZERO
	var best_score: float = -99999.0
	var best_target: Character = null
	
	for origin in reachable:
		var closest_in_range: Character = null
		var closest_in_range_distance: float = 99999.0
		var min_dist_to_any_player: float = 99999.0

		for other in state.units:
			if other.state.is_enemy():
				continue
			if not other.state.is_alive:
				continue
			var dist: float = abs(other.state.grid_position.x - origin.x) + abs(other.state.grid_position.z - origin.z)
			if dist < min_dist_to_any_player:
				min_dist_to_any_player = dist
			if dist >= min_range and dist <= max_range and dist < closest_in_range_distance:
				closest_in_range_distance = dist
				closest_in_range = other
		
		if closest_in_range == null:
			continue
		
		var dist_to_ideal: float = abs(closest_in_range_distance - float(max_range))
		var score: float = min_dist_to_any_player - dist_to_ideal
		if score > best_score:
			best_score = score
			best_origin = origin
			best_target = closest_in_range
	
	if best_origin == Vector3i.ZERO or best_target == null:
		return BTNode.Status.FAILURE
	blackboard.target = best_target
	blackboard.attack_origin = best_origin
	return BTNode.Status.SUCCESS
