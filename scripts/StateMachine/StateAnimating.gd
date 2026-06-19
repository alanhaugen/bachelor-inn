extends LevelState
class_name StateAnimating

var _is_processing: bool = false

func enter(level: Node) -> void:
	print("ENTER STATE: StateAnimating.")
	_is_processing = false

func exit(level: Node) -> void:
	print("EXIT STATE: StateAnimating.")
	level.movement_map.clear()
	_is_processing = false

func handle_input(level: Node, event: InputEvent) -> void:
	## Ignore all inputs except pause, which runs from level.gd
	pass 

func update(level: Node, delta: float) -> void:
	if not level.animation_path.is_empty():
		_move_along_path(level, delta)
		return
	
	if not level.moves_stack.is_empty() and not _is_processing:
		_process_next_move(level)
		return
	
	if level.moves_stack.is_empty() and not _is_processing:
		_finish_animation(level)

func _move_along_path(level: Node, delta: float) -> void:
	var movement_speed: float = 8.0
	var target: Vector3 = level.animation_path.front()
	var dir: Vector3 = target - level.selected_unit.position
	var step: = movement_speed * delta
	
	if dir.length() <= step:
		level.selected_unit.position = target
		level.animation_path.pop_front()
	else:
		level.selected_unit.position += dir.normalized() * step
		if dir.z > 0:
			level.selected_unit.play(level.selected_unit.run_down_animation)
		elif dir.z < 0:
			level.selected_unit.play(level.selected_unit.run_up_animation)
		elif dir.x > 0:
			level.selected_unit.play(level.selected_unit.run_right_animation)
		elif dir.x < 0:
			level.selected_unit.play(level.selected_unit.run_left_animation)


func _process_next_move(level: Node) -> void:
	_is_processing = true
	
	level.active_move = level.moves_stack.pop_front()
	level.active_move.prepare(level.game_state)
	await level.combat_vfx.play_attack(level.active_move.result)
	level.active_move.apply_damage(level.game_state)
	
	if level.is_player_turn:
		level.active_move = Wait.new(level.active_move.end_pos)
	
	var code: int = level.enemy_code
	if level.is_player_turn:
		code = level.player_code_done
	level.occupancy_map.set_cell_item(level.active_move.start_pos, GridMap.INVALID_CELL_ITEM)
	level.occupancy_map.set_cell_item(level.active_move.end_pos, code)
	level.selected_unit.move_to(level.active_move.end_pos)
	level.selected_unit.pause_anim()
	level.camera_controller.free_camera()
	
	if not level.is_player_turn:
		level._clear_selection()
	
	level.completed_moves.append(level.active_move)
	
	if Tutorial.in_tutorial:
		Tutorial.tutorial_unit_moved()
	
	if not level.is_player_turn:
		if level.active_move is Attack:
			level.wait_for_camera = true
			level.timer.start(level.post_enemy_attack_wait)
			await level.timer.timeout
			level.wait_for_camera = false
		level.MoveSingleAI() ## Will be moved to own EnemyTurnState
		for character: Character in level.Main.characters:
			if character == null:
				continue
			level.emit_signal("character_stats_changed", character)
	
	if not level.moves_stack.is_empty():
		level.create_path(
			level.moves_stack.front().start_pos,
			level.moves_stack.front().end_pos
			)
	
	if not level.animation_path.is_empty():
		level.selected_unit.position = level.animation_path.pop_front()
	
	_is_processing = false

func _finish_animation(level: Node) -> void:
	level.CheckTriggerConditions()
	level.CheckVictoryConditions()
	
	if not level.is_player_turn:
		# End of enemy turn - trans to player turn
		level.tick_all_units_end_round()
		for c in Main.characters:
			if c == null:
				continue
			level.emit_signal("character_stats_changed", c)
		level.reset_all_units()
		level.is_player_turn = true
		level.check_aggro()
		level.hide_inactive_characters()
		level.state_machine.transition_to(StateTurnTransition.new(true))
	else:
		level.state_machine.transition_to(StateSelectingUnit.new())
