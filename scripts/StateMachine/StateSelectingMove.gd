extends LevelState
class_name StateSelectingMove

## Signals made in enter() must be disconnected in exit()
func enter(level: Node) -> void:
	if level.last_selected_unit != null:
		level.select_unit(level.last_selected_unit)
	print("ENTER STATE: StateSelectingMove.")
	pass

func exit(level: Node) -> void:
	print("EXIT STATE: StateSelectingMove.")
	level.movement_map.clear()
	#level.path_map.clear()

func handle_input(level: Node, event: InputEvent) -> void:
	print("handle_input received: ", event)
	
	if not level._can_handle_input(event):
		return
	
	var pos: Vector3i = level.get_grid_cell_from_mouse()
	level._update_cursor(pos)
	
	# Key inputs
	if event is InputEventKey and not event.echo and event.pressed:
		match event.keycode:
			KEY_TAB:
				print("Key Input TAB registered.")
				level.select_next_character()
				#level.state_machine.transition_to(StateSelectingMove.new())
				return
			KEY_1:
				var ui := level.get_tree().get_first_node_in_group("ui_controller")
				if ui:
					ui.ribbon.trigger_skill_by_index(0)
				return
			KEY_2:
				var ui := level.get_tree().get_first_node_in_group("ui_controller")
				if ui:
					ui.ribbon.trigger_skill_by_index(1)
				return
			KEY_3:
				var ui := level.get_tree().get_first_node_in_group("ui_controller")
				if ui:
					ui.ribbon.trigger_skill_by_index(2)
				return
			KEY_4:
				var ui := level.get_tree().get_first_node_in_group("ui_controller")
				if ui:
					ui.ribbon.trigger_skill_by_index(3)
				return
			KEY_5:
				var ui := level.get_tree().get_first_node_in_group("ui_controller")
				if ui:
					ui.ribbon.trigger_skill_by_index(4)
				return
	
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
		
	if level._is_invalid_tile(pos): ## TODO: This checks for water tiles. Should be renamed.
		return
	
	# Click another player unit
	if level.get_unit_name(pos) == CharacterStates.Player:
		level._handle_player_click(pos)
		level.state_machine.transition_to(StateSelectingMove.new())
		return
		
	# Click movement tile or enemy unit
	if level.movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
		var result: String = level._handle_action_tile_click(pos)
		match result:
			"move":
				level.state_machine.transition_to(StateAnimating.new())
				pass
			"attack":
				level.state_machine.transition_to(StateChoosingAttack.new())
				pass
		return
	
	# Click enemy unit
	#if level.get_unit_name(pos) == CharacterStates.Enemy:
		#level.selected_enemy_unit = level.get_unit(pos)
		#emit_signal("enemy_selected", level.selected_enemy_unit)
	
	# Click empty tile /anything else
	level._clear_selection()
	level.state_machine.transition_to(StateSelectingUnit.new())
	
	
	#if level.get_unit(pos) and level.get_unit(pos).state.faction == CharacterState.Faction.ENEMY:
			#level.selected_enemy_unit = level.get_unit(pos)
			#level.emit_signal("enemy_selected", selected_enemy_unit)
			#print("hey an enemy has been selected ")
