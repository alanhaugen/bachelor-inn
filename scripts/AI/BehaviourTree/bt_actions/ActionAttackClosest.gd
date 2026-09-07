extends BTNode
class_name ActionAttackClosest

func tick(blackboard: BTBlackboard) -> BTNode.Status:
	var unit := blackboard.unit
	var state := blackboard.state
	var target := blackboard.target
	
	if target == null:
		return BTNode.Status.SUCCESS
	
	blackboard.chosen_command = Attack.new(
		unit.state.grid_position,
		target.state.grid_position,
		blackboard.attack_origin
	)
	
	#blackboard.chosen_command = Attack.new(unit.state.grid_position, target.state.grid_position, best_origin)
	print("Action fired: ", get_script().resource_path, " command: ", blackboard.chosen_command)
	return BTNode.Status.SUCCESS

## If we want to add spells to enemies
## range cheack for spells
# if blackboard.chosen_skill != null:
	#     var skill_origins := MoveGenerator.get_attack_origins(
	#         unit, state, target.state.grid_position,
	#         reachable,
	#         blackboard.chosen_skill.min_range,
	#         blackboard.chosen_skill.max_range
	#     )
	#     if not skill_origins.is_empty():
	#         blackboard.chosen_command = CastSkill.new(
	#             unit.state.grid_position,
	#             skill_origins[0],
	#             target.state.grid_position,
	#             blackboard.chosen_skill
	#         )
	#         return BTNode.Status.SUCCESS
