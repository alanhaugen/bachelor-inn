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
	if (
		t == "Water" or
		t == "1_1_Pillar" or
		t == "1_0_Rock" or
		t == "Chest" or 
		t == "1_2_Rock new plzdontoveride" or 
		t == "1_3_Rock" or 
		t == "1_0_Water Plane" or 
		t == "1_0_End_Extension" or
		t == "1_0_HillCorner" or
		t == "1_0_HillEdge" or
		t == "1_0_HillWall" or
		t == "1_0_InnerCorner" or
		t == "1_0_InnerCorner_Extension" or
		t == "1_0_SideEdge_Extension" or
		t == "1_0_Single_Extension" or
		t == "MESH"
	):
		return false;
	return true;


static func get_weight(t : String) -> int:
	if t == "1_0_Corner":
		return 2
	elif t == "1_0_Corner_Extension":
		return 2
	elif t == "1_0_Edge":
		return 2
	elif t == "1_0_Edge_Extension":
		return 2
	elif t == "1_0_EmptyTile":
		return 2
	elif t == "1_0_End":
		return 2
	elif t == "1_0_Flower_Ground_16x16":
		return 3
	elif t == "1_0_Flower_ground_2_16x16":
		return 3
	elif t == "1_0_PlainBlock":
		return 2
	elif t == "1_0_SideEdge":
		return 2
	elif t == "1_0_Single":
		return 2
	elif t == "Grass (outer layer)":
		return 3
	elif t == "InnerCorner":
		return 2
	elif t == "InnerCornerExtension":
		return 2
	elif t == "Leaf_Ground_16x16":
		return 3
	elif t == "Leaf_Ground_2_16x16":
		return 3
	elif t == "1_0_StonePath":
		return 1
	elif t == "1_0_Upwards Ascending Stair":
		return 1
	elif t == "1_0_UpwardsPath":
		return 1
	elif t == "Short_grass_tile_33x33":
		return 3
	elif t == "SideEdge":
		return 2
	elif t == "SideEdge_Extension":
		return 2
	elif t == "Single":
		return 2
	elif t == "Single_Extension":
		return 2
	elif t == "Tall_grass_tile_32x32":
		return 4
	elif t == "Upwards Ascending Stair":
		return 2
	elif t == "Water_Plane":
		return 5
	return 1
