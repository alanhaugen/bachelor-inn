extends LevelState
class_name StateSelectingMove

## Signals made in enter() must be disconnected in exit()
func enter(level: Node) -> void:
	pass

func exit(level: Node) -> void:
	level.movement_map.clear()
	level.path_map.clear()

func handle_input(level: Node, event: InputEvent) -> void:
	if not level._can_handle_input(event):
		return
	
	var pos: Vector3i = level.get_grid_cell_from_mouse()
	level._update_cursor(pos)
	
	# Key inputs
	if event is InputEventKey and not event.echo and event.pressed:
		match event.keycode:
			KEY_TAB:
				level.select_next_character()
				level.state_machine.transition_to(StateSelectingMove.new())
				return
			KEY_1: ## TODO: Add all key binds to action bar skills
				#level.state_machine.transition_to(StateSelectSpellTarget.new())
				pass
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	
	# RMB - Cancel / deselect
	if event.button_index == MOUSE_BUTTON_RIGHT:
		level._clear_selection()
		level.state_machine.transition_to(StateSelectingUnit.new())
		return
	
	# Click another player unit
	if level.get_unit_name(pos) == CharacterStates.Player:
		level._handle_player_click(pos)
		level.state_machine.transition_to(StateSelectingUnit.new())
		return
		
	# Click empty tile
	if level._is_invalid_tile(pos):
		level._clear_selection()
		level.state_machine.transition_to(StateSelectingUnit.new())
		return
	
	# Click movement tile or enemy unit
	if level.movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
		var result: String = level.handle_action_tile_click(pos)
		match result:
			"move":
				print("Match found: Transitioning to Animating State.")
				#level.state_machine.transistion_to(StateAnimating.new())
				pass
			"attack":
				print("Match found: Transitioning to Choosing Attack State")
				#level.state_machine.transition_to(StateChoosingAttack.new())
				pass
		return
	# Click enemy unit
