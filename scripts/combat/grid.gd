extends RefCounted
class_name Grid

var grid : GridMap


func _init(grid_map : GridMap) -> void:
	grid = grid_map


func set_tile(tile : GridTile) -> void:
	grid.set_cell_item(tile.pos, tile.type)


func cell_to_world(pos: Vector3i) -> Vector3:
	return grid.to_global(grid.map_to_local(pos))


func is_walkable(pos: Vector3i, from_pos: Vector3i = pos) -> bool:
	if not grid.get_used_cells().has(pos):
		return false
	if grid.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		return false
	if from_pos != pos and abs(pos.y - from_pos.y) > 1:
		return false
	return true


func get_tiles_at_xz(x: int, z: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []

	# Loop through all used cells in the GridMap
	for cell_pos in grid.get_used_cells():
		if cell_pos.x == x and cell_pos.z == z:
			result.append(cell_pos)

	# Sort by Y descending (topmost first)
	result.sort_custom(func(a: Vector3, b: Vector3) -> int:
		if a.y > b.y:
			return -1
		elif a.y < b.y:
			return 1
		return 0
	)

	return result

# Helper for sorting by Y descending
func _sort_by_y_desc(a: Vector3i, b: Vector3i) -> int:
	if a.y > b.y:
		return -1
	elif a.y < b.y:
		return 1
	return 0


func to_local(pos: Vector3) -> Vector3:
	return grid.to_local(pos)


func is_inside(pos : Vector3i) -> bool:
	return grid.get_used_cells().has(pos)


func is_valid(pos : Vector3i) -> bool:
	return is_inside(pos)


func clear() -> void:
	grid.clear()
