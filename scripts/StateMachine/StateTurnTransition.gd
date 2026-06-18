extends LevelState
class_name StateTurnTransition

var _to_player: bool

func _init(to_player: bool) -> void:
	_to_player = to_player

func enter(level: Node) -> void:
	if _to_player:
		level.enemy_label.hide()
		level.player_label.show()
	else:
		level.enemy_label.show()
		level.player_label.hide()
		level.check_aggro()
		level.hide_inactive_characters()
	
	level.turn_transition_animation_player.animation_finished.connect(
		_on_animation_finished.bind(level), CONNECT_ONE_SHOT ## Auto disconnect after fire'ing once
	)
	level.turn_transition_animation_player.play()

func exit(level: Node) -> void:
	pass

func handle_input(level: Node, event: InputEvent) -> void:
	## Block all input during animation (helps for Tutorial :D)
	pass 

func _on_animation_finished(anim_name: StringName, level: Node) -> void:
	if _to_player:
		level.is_player_turn = true
		var selectables: Character = level.get_selectable_characters()
		
		if selectables.is_empty():
			level.state_machine.transition_to(StateSelectingUnit.new())
			return
		
		if level.last_selected_unit != null and selectables.has(level.last_selected_unit):
			level.camera_controller.free_camera()
			level.camera_controller.set_pivot_target_translate(level.last_selected_unit)
			level.select_unit(level.last_selected_unit)
			level.state_machine.transition_to(StateSelectingMove.new())
		else:
			level.camera_controller.free_camera()
			level.camera_controller.set_pivot_target_translate(selectables.front())
			if not Tutorial.in_tutorial:
				level.select_unit(selectables.front())
				level.state_machine.transition_to(StateSelectingMove.new())
			else:
				level.state_machine.transition_to(StateSelectingUnit.new())
	else:
		level.is_player_turn = false
		level.state_machine.transition_to(StateEnemyTurn.new())
