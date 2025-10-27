extends Command

var startPos :Vector3i;
var endPos   :Vector3i;
var gridCode :int;
var units    :GridMap;
var isAttack :bool;
var isWait   :bool;


func _init(inStartPos :Vector3i, inEndPos :Vector3i, inGridCode :int, inUnits: GridMap, inIsAttack :bool = false) -> void:
	startPos = inStartPos;
	endPos   = inEndPos;
	gridCode = inGridCode;
	units    = inUnits;
	isAttack = inIsAttack;
	isWait   = false;


func execute() -> void:
	units.set_cell_item(startPos, -1);
	units.set_cell_item(endPos, gridCode);


func undo() -> void:
	units.set_cell_item(endPos, -1);
	units.set_cell_item(startPos, gridCode);
