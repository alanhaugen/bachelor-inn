extends LevelState
class_name StateChoosingAttack

## Signals made in enter() must be disconnected in exit()
func enter(level: Node) -> void:
	pass

func exit(level: Node) -> void:
	level.path_map.clear()

func handle_input(level: Node, event: InputEvent) -> void:
	if not level._can_handle_input(event):
		return
	
	var pos: Vector3i = level.get_grid_cell_from_mouse()
	level._update_cursor(pos)
	
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	
	if event.button_index == MOUSE_BUTTON_RIGHT:
		_cancel(level)
		return
	
	if level.path_map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		_cancel(level)
		return
	
func _cancel(level: Node) -> void:
	level._cancel_attack_choice_mode()
	if level.selected_unit != null and not level.selected_unit.state.is_moved:
		## Go back to selecting move
		level.state_machine.transition_to(StateSelectingMove.new())
	else:
		## Unit already moved, nothing to go back to.
		level.state_machine.transition_to(StateSelectingUnit.new())
