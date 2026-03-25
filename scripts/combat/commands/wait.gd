extends Move
class_name Wait

var is_moved_changed : bool = false
var is_ability_used_changed : bool = false

func _init(inStartPos :Vector3i) -> void:
	start_pos = inStartPos
	end_pos = inStartPos


func execute(state : GameState, simulate_only : bool = false) -> void:
	var unit : Character = state.get_unit(start_pos)
	if !unit.state.is_moved:
		unit.state.is_moved = true
		is_moved_changed = true
	if !unit.state.is_ability_used:
		unit.state.is_ability_used = true
		is_ability_used_changed = true
	Main.level.character_stats_changed.emit(unit)


func undo(state : GameState, simulate_only : bool = false) -> void:
	var unit : Character = state.get_unit(start_pos)
	if is_ability_used_changed:
		unit.state.is_ability_used = false
		is_ability_used_changed = false
	if is_moved_changed:
		unit.state.is_moved = false
		is_moved_changed = false
	Main.level.character_stats_changed.emit(unit)
