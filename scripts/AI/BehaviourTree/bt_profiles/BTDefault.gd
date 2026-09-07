extends RefCounted
class_name BTDefault

static func build() -> BTNode:
	## NOTE: Here, we create each branch
	var attack_sequence: BTSequence = BTSequence.new()
	attack_sequence.add_child(ConditionEnemyInRange.new())
	attack_sequence.add_child(ActionAttackClosest.new())

	var move_sequence: BTSequence = BTSequence.new()
	move_sequence.add_child(ConditionPlayerIsClose.new())
	move_sequence.add_child(ActionMoveTowardClosest.new())

	var root: BTSelector = BTSelector.new()
	## NOTE: The order here top-down defines the left-to-right sequence the BT will search
	root.add_child(attack_sequence)
	root.add_child(move_sequence)
	root.add_child(ActionMoveTowardClosest.new())
	root.add_child(ActionWait.new())

	return root
