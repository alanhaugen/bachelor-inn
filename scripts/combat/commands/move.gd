extends Command
class_name Move
## This is a move
##
## The game consists of commands like move played
## in a queue

var start_pos : Vector3i
var end_pos : Vector3i
var is_wait : bool


func save() -> Dictionary:
	var state := {"start_pos": start_pos,
				  "end_pos": end_pos,
				  "is_wait": is_wait
				  }
	
	return state


func _init(inStartPos :Vector3i, inEndPos :Vector3i) -> void:
	start_pos = inStartPos
	end_pos = inEndPos
	is_wait = false


func execute(state : GameState, simulate_only : bool = false) -> void:
	var unit := state.get_unit(start_pos)
	unit.move_to(end_pos, simulate_only)


func undo(state : GameState, simulate_only : bool = false) -> void:
	var unit := state.get_unit(end_pos)
	unit.move_to(start_pos)
