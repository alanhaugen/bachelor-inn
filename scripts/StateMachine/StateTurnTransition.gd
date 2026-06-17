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
		level.state_machine.transition_to(StateSelectingUnit.new())
	else:
		level.is_player_turn = false
		level.state_machine.transition_to(StateEnemyTurn.new())
