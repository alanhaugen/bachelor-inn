extends RefCounted
class_name BTRunner

static func run(unit: Character, state: GameState, context: MissionContext) -> Command:
	var tree: BTNode = _get_profile(unit.state.bt_profile)
	print("BTRunner: building tree for profile: ", unit.state.bt_profile)
	var blackboard := BTBlackboard.new(unit, state, context)
	#blackboard.movement_grid = Main.level.movement_grid
	blackboard.weights_map = Main.level.movement_weights_map
	print("BTRunner: ticking tree")
	var result := tree.tick(blackboard)
	print("BTRunner: result: ", result)
	
	match result:
		BTNode.Status.SUCCESS:
			print("BTRunner: chosen_command: ", blackboard.chosen_command)
			return blackboard.chosen_command
		_:
			return Wait.new(unit.state.grid_position)

static func _get_profile(profile: int) -> BTNode:
	match profile:
		CharacterState.BTProfile.BRUTE:
			return BTBrute.build()
		CharacterState.BTProfile.SNIPER:
			return BTSniper.build()
		_:
			return BTDefault.build()
