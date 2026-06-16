extends RefCounted
class_name LevelState

func enter(level: Node) -> void:
	pass

func exit(level: Node) -> void:
	pass

func update(level: Node, delta: float) -> void:
	pass

func handle_input(level: Node, event: InputEvent) -> void:
	pass
