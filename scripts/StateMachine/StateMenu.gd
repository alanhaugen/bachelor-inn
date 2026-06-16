extends LevelState
class_name StateMenu

func enter(level: Node) -> void:
	level.is_in_menu = true
	level.pause_menu.show()
	level.get_tree().paused = true

func exit(level: Node) -> void:
	level.is_in_menu = false
	level.pause_menu.hide()
	level.get_tree().paused = false

func handle_input(level: Node, event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.key_code == KEY_ESCAPE:
			level.state_machine.pop()
