extends Command

var startPos :Vector3i;
var endPos   :Vector3i;
var type     :Vector2i;
var units    :GridMap;
var isAttack :bool;
var isWait   :bool;

func _init(inStartPos :Vector3i, inEndPos :Vector3i, inType :Vector2i, inUnits: GridMap, inIsAttack :bool = false) -> void:
	startPos = inStartPos;
	endPos   = inEndPos;
	type     = inType;
	units    = inUnits;
	isAttack = inIsAttack;
	isWait   = false;

func execute() -> void:
	units.set_cell(startPos);
	units.set_cell(endPos, 0, type);
	
func undo() -> void:
	units.set_cell(endPos);
	units.set_cell(startPos, 0, type);
