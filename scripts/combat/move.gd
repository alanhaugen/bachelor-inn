extends Command

var start_pos :Vector3i;
var end_pos   :Vector3i;
var grid_code :int;
var units    :GridMap;
var is_attack :bool;
var is_wait   :bool;

var character1 :Character = null;
var character2 :Character = null;


func _init(inStartPos :Vector3i, inEndPos :Vector3i, inGridCode :int, inUnits: GridMap, inCharacter1: Character, inIsAttack :bool = false, inCharacter2: Character = null) -> void:
	start_pos = inStartPos;
	end_pos   = inEndPos;
	grid_code = inGridCode;
	units    = inUnits;
	is_attack = inIsAttack;
	is_wait   = false;
	character1 = inCharacter1;
	character2 = inCharacter2;


func execute() -> void:
	units.set_cell_item(start_pos, GridMap.INVALID_CELL_ITEM);
	units.set_cell_item(end_pos, grid_code);
	
	character1.move_to(end_pos);
	if is_attack:
		character2.die();


func undo() -> void:
	units.set_cell_item(end_pos, GridMap.INVALID_CELL_ITEM);
	units.set_cell_item(start_pos, grid_code);
	
	character1.move_to(start_pos);
	if is_attack:
		character2.move_to(end_pos);
