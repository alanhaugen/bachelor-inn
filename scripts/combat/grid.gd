extends RefCounted
class_name Grid

var grid_map : GridMap


func _init(grid_map_ : GridMap) -> void:
	grid_map = grid_map_

#func is_walkable(pos: Vector3i) -> bool:
#	if terrain.is_blocked(pos):
#		return false
#	if units.has_unit(pos):
#		return false
#	return true

#func cost(pos: Vector3i) -> float:
#	return terrain.cost(pos)
