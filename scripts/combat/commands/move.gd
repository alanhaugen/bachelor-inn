extends Command
class_name Move
## This is a move
##
## The game consists of commands like move played
## in a queue

var is_moved_changed : bool = false

func save() -> Dictionary:
	var state := {"start_pos": start_pos,
				  "end_pos": end_pos
				  }
	
	return state


func _init(inStartPos :Vector3i, inEndPos :Vector3i) -> void:
	start_pos = inStartPos
	end_pos = inEndPos

func apply_damage(state: GameState, simulate_only: bool = false) -> void:
	var unit : Character = state.get_unit(start_pos)
	var pre_moved_value : bool = unit.state.is_moved
	unit.move_to(end_pos, simulate_only)
	if pre_moved_value != unit.state.is_moved:
		is_moved_changed = true
	if !simulate_only:
		Main.level.character_stats_changed.emit(unit)


func undo(state : GameState, simulate_only : bool = false) -> void:
	var unit : Character = state.get_unit(end_pos)
	unit.move_to(start_pos, simulate_only)
	if is_moved_changed:
		is_moved_changed = false
		unit.state.is_moved = false
	if !simulate_only:
		Main.level.character_stats_changed.emit(unit)
