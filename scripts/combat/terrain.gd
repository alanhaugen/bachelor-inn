class_name Terrain
extends RefCounted

var position : Vector3i;
var type : String;


func _init(pos : Vector3i, t : String) -> void:
	position = pos;
	type = t;
