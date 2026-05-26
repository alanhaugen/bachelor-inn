extends Node3D
class_name PatrolPath

@export var enemy_name : String = ""

@export var waypoints : Array[Vector3i] = []

func get_waypoints(level: Node) -> Array[Vector3i]:
	var points: Array[Vector3i] = []
	for child in get_children():
		if child is Node3D:
			points.append(level.world_to_grid(child.global_position))
	return points
