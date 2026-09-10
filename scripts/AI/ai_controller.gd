extends RefCounted
class_name AIController
## This checks if the enemy should run minimax or bt to create a move.

static func choose_move(enemy: Character, state: GameState, context: MissionContext) -> Command:
	match enemy.state.ai_mode:
		CharacterState.AIMode.BEHAVIOUR_TREE:
			return _run_bt(enemy, state, context)
		CharacterState.AIMode.MINIMAX:
			return _run_minimax(enemy, state) ## context not added to minimax yet
		_:
			return Wait.new(enemy.state.grid_position)

static func _run_bt(enemy: Character, state: GameState, context: MissionContext) -> Command:
	print("Running BT for: ", enemy.data.unit_name, " profile: ", enemy.state.bt_profile)
	var cmd := BTRunner.run(enemy, state, context)
	if cmd == null:
		print("Running BT failed. Initiating Wait at Position.")
		return Wait.new(enemy.state.grid_position)
	return cmd

static func _run_minimax(enemy: Character, state: GameState) -> Command:
	var ai := MinimaxAI.new()
	var cmd := ai.choose_best_move(state, enemy.state.search_depth, enemy)
	if cmd == null:
		print("Running MiniMax failed. Initiating Wait at Position.")
		return Wait.new(enemy.state.grid_position)
	return cmd
# func run_minimax()
# func run_bt()

static func run_enemy_turn(level: Level) -> void:
	var any_active_enemies := false
	for unit in level.characters:
		if unit == null:
			continue
		if not unit.state.is_enemy():
			continue
		if unit.state.aggro_state != CharacterState.AggroState.FROZEN:
			any_active_enemies = true
			break
	
	if not any_active_enemies:
		_end_enemy_turn(level)
		return
	
	#var ai := MinimaxAI.new();
	var current_state := GameState.from_level(level);
	
	var currentEnemy : Character = null
	for unit in level.characters:
		if unit == null:
			continue
		if !unit.state.is_enemy():
			continue
		if unit.state.is_moved:
			continue
		currentEnemy = unit
		break
		
	if currentEnemy == null:
		_end_enemy_turn(level)
		return
		
	match currentEnemy.state.aggro_state:
		CharacterState.AggroState.FROZEN:
			currentEnemy.state.is_moved = true
			level.call_deferred("MoveSingleAI")
			return
		CharacterState.AggroState.AGGRESSIVE:
			pass
	
	if currentEnemy != null:
		var curEnemyPos : NullablePosition = NullablePosition.new(currentEnemy.state.grid_position)
		if current_state.has_enemy_moves(curEnemyPos):
			#var move : Command = ai.choose_best_move(current_state, 3, currentEnemy); ## Old AI move gen
			var move: Command = AIController.choose_move(currentEnemy, current_state, level.mission_context)
			level.moves_stack.append(move);
			current_state = current_state.apply_move(move, true);
					
	if not level.moves_stack.is_empty():
		level.create_path(level.moves_stack.front().start_pos, level.moves_stack.front().end_pos); # a-star for pathfinding AI
		level.state_machine.transition_to(StateAnimating.new())
		level.camera_controller.focus_camera(level.selected_unit)
		level.wait_for_camera = true
		level.timer.start(level.pre_enemy_turn_wait)
		await level.timer.timeout
		level.wait_for_camera = false
	else:
		var pivot_chara : Node3D = Main.level.get_selectable_characters().front()
		if (pivot_chara == null):
			return
		level.camera_controller.free_camera()
		level.camera_controller.set_pivot_target_translate(pivot_chara.position)
		if currentEnemy != null:
			currentEnemy.state.is_moved = true
		level.call_deferred("_continue_enemy_turn") ## "Manually" continue loop of Enemy AI

static func _end_enemy_turn(level: Level) -> void:
	level.tick_all_units_end_round()
	for c in level.characters:
		if c == null:
			continue
		level.emit_signal("character_stats_changed", c)
	level.reset_all_units()
	level.is_player_turn = true
	level.check_aggro()
	level.hide_inactive_characters()
	level.camera_controller.free_camera()
	level.state_machine.transition_to(StateTurnTransition.new(true))

#func MoveAI() -> void:
	#var ai := MinimaxAI.new();
	#var current_state := GameState.from_level(Main.level);
	#
	#if current_state.has_enemy_moves():
		#var move : Command = ai.choose_best_move(current_state, 1);
		#Main.level.moves_stack.append(move);
		#current_state = current_state.apply_move(move, true);
	#
	#if (Main.level.moves_stack.is_empty() == false):
		#Main.level.create_path(Main.level.moves_stack.front().start_pos, Main.level.moves_stack.front().end_pos); # a-star for pathfinding AI
		#state = States.ANIMATING;
		#Main.level.camera_controller.focus_camera(Main.level.selected_unit)
	#else:
		#Main.level.camera_controller.set_pivot_target_translate(Main.characters.front().position)
		#Main.level.camera_controller.free_camera()
#
