class_name Terrain
extends RefCounted

var position : Vector3i;
var type : String;
var weight : int = 1;
var is_passable : bool = true;


func _init(pos : Vector3i, t : String) -> void:
	position = pos;
	type = t;
	if (
		t == "Water" or
		t == "Pillar" or
		t == "Chest"
	):
		is_passable = false;
