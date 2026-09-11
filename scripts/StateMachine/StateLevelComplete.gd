extends LevelState
class_name StateLevelComplete

func enter(level: Node) -> void:
	print("ENTER STATE: StateLevelComplete.")
	level.is_in_menu = true

func exit(level: Node) -> void:
	print("EXIT STATE: StateMenu.")
	level.is_in_menu = false

func handle_input(_level: Node, _event: InputEvent) -> void:
	pass
