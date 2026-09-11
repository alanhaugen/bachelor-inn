extends RefCounted
class_name LevelState

func enter(_level: Node) -> void:
	pass

func exit(_level: Node) -> void:
	pass

func update(_level: Node, _delta: float) -> void:
	pass

func handle_input(_level: Node, _event: InputEvent) -> void:
	pass
