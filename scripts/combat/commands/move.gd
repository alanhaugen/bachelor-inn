class_name Move
extends Command
## This is a move
##
## The game consists of commands like move played
## in a queue

var start_pos: Vector3i;
var end_pos: Vector3i;
var is_wait: bool;


func save() -> Dictionary:
	var state := {"start_pos": start_pos,
				  "end_pos": end_pos,
				  "is_wait": is_wait
				  };
	
	return state;


func _init(inStartPos :Vector3i, inEndPos :Vector3i) -> void:
	start_pos = inStartPos;
	end_pos = inEndPos;
	is_wait = false;


func execute(state : GameState) -> void:
	var unit := state.get_unit(start_pos);
	unit.move_to(end_pos);
	#aggressor.move_to(end_pos);
	#units.set_cell_item(start_pos, GridMap.INVALID_CELL_ITEM);
	#units.set_cell_item(end_pos, grid_code);
	#aggressor.is_moved = true;
#		if aggressor.is_playable:
#			if end_pos == start_pos:
#				aggressor.sprite.modulate = Color(0.338, 0.338, 0.338, 1.0);


func undo(state : GameState) -> void:
	var unit := state.get_unit(end_pos);
	unit.move_to(start_pos);
