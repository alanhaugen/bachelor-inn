extends Resource
class_name GridTile

#region Tile codes
enum Type { ATTACK = 0, MOVE, SELECTED }
#endregion

var weight : int
var pos : Vector3i
var type : Type


func _init(_pos: Vector3i = Vector3i(), _type: Type = Type.MOVE, _weight: int = 1) -> void:
	pos = _pos
	type = _type
	weight = _weight
