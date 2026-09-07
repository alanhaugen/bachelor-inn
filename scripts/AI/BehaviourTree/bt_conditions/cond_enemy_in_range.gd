extends BTNode
class_name ConditionEnemyInRange
## Leaf Node

func tick(blackboard: BTBlackboard) -> BTNode.Status:
	print("Condition checking: ", get_script().resource_path)
	var unit := blackboard.unit
	var state := blackboard.state
	
	var min_range := unit.state.weapon.min_range 
	var max_range := unit.state.weapon.max_range 
	print("ConditionEnemyInRange: unit=", unit.data.unit_name, " weapon range=", min_range, "-", max_range)
	var closest_target: Character = null
	var closest_dist := 99999
	
	var origins: Array[Vector3i] = [unit.state.grid_position]
	var moves := MoveGenerator.generate(unit, state)
	for cmd in moves:
		if cmd is Move:
			origins.append(cmd.end_pos)
	print("  reachable origins count: ", origins.size())
	
	# check each player unit against reachable origin
	for other in state.units:
		if other.state.is_enemy():
			continue
		if not other.state.is_alive:
			continue
		for origin in origins:
			var dist : float = abs(other.state.grid_position.x - origin.x) + abs(other.state.grid_position.z - origin.z)
			#print("Weapon range: ", min_range, "-", max_range, " dist to ", other.data.unit_name, ": ", dist)
			if dist >= min_range and dist <= max_range:
				blackboard.target = other
				blackboard.attack_origin = origin
				return BTNode.Status.SUCCESS
	return BTNode.Status.FAILURE

## If we want to add spells to enemies
## range chack for spells
	# for skill in unit.state.skills:
	#     for other in state.units:
	#         if not _is_valid_skill_target(other, skill, unit):
	#             continue
	#         var dist := manhattan_distance(unit.state.grid_position, other.state.grid_position)
	#         if dist >= skill.min_range and dist <= skill.max_range:
	#             if dist < closest_dist:
	#                 closest_dist = dist
	#                 closest = other
	#                 blackboard.chosen_skill = skill  # store which skill to use
	#
	## ActionAttackClosest would then check blackboard.chosen_skill:
	## if not null → build CastSkill command
	## if null → build Attack command (weapon)
