extends LevelState
class_name StateLevelComplete

func enter(level: Node) -> void:
	print("ENTER STATE: StateLevelComplete.")
	level.is_in_menu = true

func exit(level: Node) -> void:
	print("EXIT STATE: StateMenu.")
	level.is_in_menu = false

func handle_input(level: Node, event: InputEvent) -> void:
	pass
