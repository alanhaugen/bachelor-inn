extends LevelState
class_name StateGameOver

func enter(level: Node) -> void:
	print("ENTER STATE: StateGameOver.")
	level.is_in_menu = true
	var ui:= level.get_tree().get_first_node_in_group("ui_controller")
	if ui:
		ui.hide()
	level.game_over_screen.show()

func exit(level: Node) -> void:
	print("EXIT STATE: StateGameOver.")
	pass

func handle_input(level: Node, event: InputEvent) -> void:
	pass
