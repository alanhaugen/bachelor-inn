extends RefCounted
class_name Grid

var grid_map : GridMap


func _init(grid_map_ : GridMap) -> void:
	grid_map = grid_map_


func is_inside(pos : Vector3i) -> bool:
	return grid_map.get_used_cells().has(pos)


func is_valid(pos : Vector3i) -> bool:
	return is_inside(pos)


func clear() -> void:
	grid_map.clear()
