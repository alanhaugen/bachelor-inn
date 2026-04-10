class_name Math extends RefCounted

static func _get_tiles_in_manhattan_range(origin: Vector3i, min_r: int, max_r: int, min_y : int = -1, max_y : int = 5) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	min_r = max(min_r, 0)
	max_r = max(max_r, 0)

	for dx in range(-max_r, max_r + 1):
		var rem:int = max_r - abs(dx)
		for dz in range(-rem, rem + 1):
			for dy in range(min_y, max_y):
				var dist :int = abs(dx) + abs(dz)
				if dist < min_r or dist > max_r:
					continue
				out.append(Vector3i(origin.x + dx, origin.y+dy, origin.z + dz))
	return out
