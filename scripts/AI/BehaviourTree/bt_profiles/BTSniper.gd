extends RefCounted
class_name BTSniper

static func build() -> BTNode:
	## NOTE: Here, we create each branch
	var attack_sequence: BTSequence = BTSequence.new()
	attack_sequence.add_child(ConditionEnemyInRange.new())
	attack_sequence.add_child(ActionAttackClosest.new())
	
	var reposition_squence: BTSequence = BTSequence.new()
	reposition_squence.add_child(ConditionCanReachAttackRange.new())
	reposition_squence.add_child(ActionAttackFromMaxRange.new())
	
	var flee_sequence: BTSequence = BTSequence.new()
	flee_sequence.add_child(ConditionPlayerIsClose.new())
	flee_sequence.add_child(ActionFlee.new())

	var root: BTSelector = BTSelector.new()
	## NOTE: The order here top-down defines the left-to-right sequence the BT will search
	root.add_child(reposition_squence)
	#root.add_child(attack_sequence)
	root.add_child(flee_sequence)
	root.add_child(ActionMoveTowardClosest.new())
	root.add_child(ActionWait.new())

	return root
