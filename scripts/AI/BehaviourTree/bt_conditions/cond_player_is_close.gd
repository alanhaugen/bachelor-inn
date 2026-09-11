extends BTNode
class_name ConditionPlayerIsClose

const SAFE_DISTANCE: int = 3

func tick(blackboard: BTBlackboard) -> BTNode.Status:
	#print("Condition checking: ", get_script().resource_path)
	var unit := blackboard.unit
	var state := blackboard.state
	
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
	
	if closest_dist > SAFE_DISTANCE:
		return BTNode.Status.FAILURE
	
	blackboard.target = closest
	return BTNode.Status.SUCCESS
