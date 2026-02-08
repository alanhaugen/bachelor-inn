extends Resource
class_name GridTile

#region Tile codes
enum TileFlags
{
	NONE      = 0,
	WALKABLE  = 1 << 0,
	OCCUPIED  = 1 << 1,
	VISIBLE   = 1 << 2,
	ATTACK    = 1 << 3,
	SELECTED  = 1 << 4
}
#endregion

var weight : int
var pos : Vector3i
var type : TileFlags


func _init(_pos: Vector3i = Vector3i(), _type: TileFlags = TileFlags.NONE, _weight: int = 1) -> void:
	pos = _pos
	type = _type
	weight = _weight
