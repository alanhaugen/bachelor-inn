extends Move
class_name Wait


func _init(inStartPos :Vector3i) -> void:
	start_pos = inStartPos
	end_pos = inStartPos


func execute(state : GameState, simulate_only : bool = false) -> void:
	var unit := state.get_unit(start_pos)
	if unit:
		unit.move_to(end_pos, simulate_only)
		unit.state.is_moved = true
		unit.state.is_ability_used = true
		if not simulate_only:
			print("[AI_DEBUG] Wait.execute() set flags for '", unit.data.unit_name, "': moved=", unit.state.is_moved, ", ability_used=", unit.state.is_ability_used)


func undo(state : GameState, _simulate_only : bool = false) -> void:
	var unit := state.get_unit(end_pos)
	if unit:
		unit.move_to(start_pos, _simulate_only)
		if not _simulate_only:
			unit.state.is_moved = false
			unit.state.is_ability_used = false
