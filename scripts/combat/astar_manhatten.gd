class_name AStarManhatten
extends AStar3D

func _compute_cost(u: int, v: int) -> float:
	var u_pos: Vector3 = get_point_position(u)
	var v_pos: Vector3 = get_point_position(v)
	return abs(u_pos.x - v_pos.x) + abs(u_pos.y - v_pos.y) + abs(u_pos.z - v_pos.z)

func _estimate_cost(u: int, v: int) -> float:
	var u_pos: Vector3 = get_point_position(u)
	var v_pos: Vector3 = get_point_position(v)
	return abs(u_pos.x - v_pos.x) + abs(u_pos.y - v_pos.y) + abs(u_pos.z - v_pos.z)
