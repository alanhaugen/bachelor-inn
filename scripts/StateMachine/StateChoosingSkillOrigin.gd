extends LevelState
class_name StateChoosingSkillOrigin

## This is where we decide where to cast skills from

func _enter(level: Node) -> void:
	print("ENTER STATE: StateChoosingSkillOrigin.")
	pass
	
func _exit(level: Node) -> void:
	print("EXIT STATE: StateChoosingSkillOrigin.")
	level.path_map.clear()
	level.is_choosing_skill_attack_origin = false

func handle_input(level: Node, event: InputEvent) -> void:
	if not level._can_handle_input(event):
		return
	var pos: Vector3i = level.get_grid_cell_from_mouse()
	level._update_cursor(pos)
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	
	if level.path_map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		_cancel(level)
		return
	
	var caster: Character = level.skill_caster
	var actual_target_pos: Vector3i = level.skill_target_pos
	if level.active_skill.aoe_shape == Skill.AoEShape.NONE and level.skill_target_pos == caster.state.grid_position:
		actual_target_pos = pos
	var cast := CastSkill.new(caster.state.grid_position, pos, actual_target_pos, level.active_skill)
	level.moves_stack.append(cast)
	level.create_path(caster.state.grid_position, pos)
	level.camera_controller.focus_camera(caster)
	
	level.active_skill = null
	level.skill_caster = null
	level.valid_skill_target_tiles.clear()
	
	level.state_machine.transition_to(StateAnimating.new())

func _cancel(level: Node) -> void:
	var caster: Character = level.skill_caster
	level._exit_skill_target_mode()
	if is_instance_valid(caster):
		level.state_machine.transition_to(StateSelectingMove.new())
	else:
		level.state_machine.transition_to(StateSelectingUnit.new())
