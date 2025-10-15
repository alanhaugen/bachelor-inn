extends Command

var startPos :Vector2i;
var endPos   :Vector2i;
var type     :Vector2i;
var units: TileMapLayer;

func _init(inStartPos :Vector2i, inEndPos :Vector2i, inType :Vector2i, inUnits: TileMapLayer) -> void:
	startPos = inStartPos;
	endPos   = inEndPos;
	type     = inType;
	units    = inUnits;

func exectute() -> void:
	units.set_cell(startPos);
	units.set_cell(endPos, 0, type);
	
func undo() -> void:
	units.set_cell(endPos);
	units.set_cell(startPos, 0, type);
