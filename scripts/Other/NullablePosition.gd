class_name NullablePosition extends RefCounted

var position : Vector3i = Vector3i(0, 0, 0)

func _init(pos : Vector3i) -> void:
	position = pos
