class_name Wait
extends Move


func _init(inStartPos :Vector3i) -> void:
	start_pos = inStartPos
	end_pos = inStartPos


func execute(state : GameState, simulate_only : bool = false) -> void:
	var unit := state.get_unit(start_pos)
	unit.move_to(end_pos, simulate_only)


func undo(state : GameState, simulate_only : bool = false) -> void:
	var unit := state.get_unit(end_pos)
	unit.move_to(start_pos, simulate_only)
