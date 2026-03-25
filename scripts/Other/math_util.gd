extends RefCounted
class_name MathUtil

static func ManhattanDistance(a : Vector3i, b : Vector3i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)
