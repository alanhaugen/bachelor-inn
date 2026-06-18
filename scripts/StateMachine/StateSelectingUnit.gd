extends LevelState
class_name StateSelectingUnit

## Needs:
## - able to click friendly units -> transition to state
## - able to click enemy units -> trigger enemy UI card
## - able to open main menu -> controlled in level.gd (global access)
## - able to move camera around -> controlled in level.gd

## Signals made in enter() must be disconnected in exit()
func enter(level: Node) -> void:
	print("ENTER STATE: StateSelectingUnit.")
	level.clear_selection()

func exit(level: Node) -> void:
	print("EXIT STATE: StateSelectingUnit.")
	pass

func handle_input(level: Node, event: InputEvent) -> void:
	if not level._can_handle_input(event):
		return
	
	var pos: Vector3i = level.get_grid_cell_from_mouse()
	level._update_cursor(pos)
	
	if level._is_invalid_tile(pos):
		return
	
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	
	#Player Unit Clicked
	if level.get_unit_name(pos) == CharacterStates.Player:
		level.handle_player_click(pos)
		level.state_machine.transition_to(StateSelectingMove.new())
		return
	
	var unit: Character = level.get_unit(pos)
	if unit and unit.state.faction == CharacterState.Faction.ENEMY:
		level.selected_enemy_unit = unit
		level.emit_signal("enemy_selected", unit)
