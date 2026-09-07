extends BTNode
class_name ActionAttackFromMaxRange

func tick(blackboard: BTBlackboard) -> BTNode.Status:
	var unit := blackboard.unit
	var target := blackboard.target
	var origin := blackboard.attack_origin
	
	if target == null:
		return BTNode.Status.FAILURE
	if origin == Vector3i.ZERO:
		return BTNode.Status.FAILURE
	
	blackboard.chosen_command = Attack.new(
		unit.state.grid_position,
		target.state.grid_position,
		origin
	)
	print("Action fired: ", get_script().resource_path, " command: ", blackboard.chosen_command)
	return BTNode.Status.SUCCESS
