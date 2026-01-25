extends Node3D

@export var float_height := 1.0
@export var duration := 0.8
@export var crit_color := Color(1.0, 0.3, 0.3)
@export var normal_color := Color(1.0, 1.0, 1.0)

@onready var label : Label3D = $Label3D


func set_value(amount : int, crit : bool) -> void:
	label.text = str(amount)
	label.modulate = crit_color if crit else normal_color
	_play()
	
func _play() -> void:
	var start_pos := position
	var end_pos := position + Vector3(0, float_height, 0)

	var tween := create_tween()
	tween.tween_property(
		self,
		"position",
		end_pos,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(
		label,
		"modulate:a",
		0.0,
		duration
	)

	tween.finished.connect(queue_free)
