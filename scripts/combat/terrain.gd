class_name Terrain
extends RefCounted

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
	if (
		t == "Water" or
		t == "Pillar" or
		t == "Rock" or
		t == "Chest" or 
		t == "Mesh5" or 
		t == "Mesh6"
	):
		return false;
	return true;


static func get_weight(t : String) -> int:
	if t == "Corner":
		return 2;
	elif t == "Corner_extension":
		return 2;
	elif t == "Edge":
		return 2;
	elif t == "Edge_Extension":
		return 2;
	elif t == "Flower_Ground_16x16":
		return 3;
	elif t == "Grass (outer layer)":
		return 3;
	elif t == "HillCorner":
		return 2;
	elif t == "InnerCorner":
		return 2;
	elif t == "InnerCornerExtension":
		return 2;
	elif t == "Leaf_Ground_16x16":
		return 3;
	elif t == "Leaf_Ground_2_16x16":
		return 3;
	elif t == "MESH":
		return 2;
	elif t == "Mesh":
		return 2;
	elif t == "Mesh2":
		return 1;
	elif t == "Mesh3":
		return 2;
	elif t == "Mesh4":
		return 2;
	elif t == "Short_grass_tile_33x33":
		return 3;
	elif t == "SideEdge":
		return 2;
	elif t == "SideEdge_Extension":
		return 2;
	elif t == "Single":
		return 2;
	elif t == "Single_Extension":
		return 2;
	elif t == "Tall_grass_tile_32x32":
		return 4;
	elif t == "Upwards Ascending Stair":
		return 2;
	elif t == "Water_Plane":
		return 5;
	return 1;
