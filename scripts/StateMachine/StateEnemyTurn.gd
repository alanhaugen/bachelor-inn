extends LevelState
class_name StateEnemyTurn

func enter(level: Node) -> void:
	print("ENTER STATE: StateEnemyTurn.")
	level.is_player_turn = false
	## TODO: Hide player card bottom right
	level.enemy_label.show()
	level.player_label.hide()
	level.MoveSingleAI()

func exit(level: Node) -> void:
	print("EXIT STATE: StateEnemyTurn.")
	pass

func handle_input(level: Node, event: InputEvent) -> void:
	## Ignore all input during animation
	pass
