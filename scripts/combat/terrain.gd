extends RefCounted
class_name Terrain

var position : Vector3i;
var type : String;
var weight : int = 1;
var is_passable : bool = true;


func _init(pos : Vector3i, t : String) -> void:
	position = pos;
	type = t;
	weight = get_weight(t);
	is_passable = is_tile_passable(t);


static func is_tile_passable(t : String) -> bool:
	return true;


static func get_weight(t : String) -> int:
	if t == "1_1_W1":
		return 1
	elif t == "1_1_W2":
		return 2
	elif t == "1_1_W3":
		return 3
	return 1
