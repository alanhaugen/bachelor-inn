extends Resource
class_name GridTile

#region Tile codes
enum Type { ATTACK = 0, MOVE }
#endregion

var weight : int;
var pos : Vector3i;
var type : Type;
