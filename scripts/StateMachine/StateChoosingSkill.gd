extends LevelState
class_name StateChoosingSkill

func enter(level: Node) -> void:
	print("ENTER STATE: StateChoosingSkill.")
	pass

func exit(level: Node) -> void:
	print("EXIT STATE: StateChoosingSkill.")
	pass

func handle_input(level: Node, event: InputEvent) -> void:
	if not level._can_handle_input(event):
		return

	var pos: Vector3i = level.get_grid_cell_from_mouse()
	level._update_cursor(pos)

	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return

	# RMB — cancel
	if event.button_index == MOUSE_BUTTON_RIGHT:
		_cancel(level)
		return

	# Invalid tile — cancel
	if not level.valid_skill_target_tiles.has(pos):
		_cancel(level)
		return

	# Valid target — _handle_skill() manages the await and calls
	# state_machine.transition_to() at the end.
	level._handle_skill(pos)

func _cancel(level: Node) -> void:
	var caster: Character = level.skill_caster
	level._exit_skill_target_mode()
	if caster != null and not caster.state.is_moved:
		level.state_machine.transition_to(StateSelectingMove.new())
	else:
		level.state_machine.transition_to(StateSelectingUnit.new())
