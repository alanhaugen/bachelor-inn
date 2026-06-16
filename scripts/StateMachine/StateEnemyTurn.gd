extends LevelState
class_name StateEnemyTurn

func enter(level: Node) -> void:
	level.is_player_turn = false
	level.enemy_label.show()
	level.player_label.hide()
	level.MoveSingleAI()

func exit(level: Node) -> void:
	pass

func handle_input(level: Node, event: InputEvent) -> void:
	## Ignore all input during animation
	pass
