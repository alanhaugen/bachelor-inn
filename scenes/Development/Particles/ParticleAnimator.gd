extends Node3D

@export var Sprite: Texture
@export var frame_columns: int = 1
@export var frame_rows: int = 1
@export var fps: float = 4.0
var current_animation: float

var frame_index : int = 0
var frame_timer : float = 0.0
var stop_anim : bool = true


@onready var particle : MeshInstance3D = $Particle

func Play() -> void:
	return


func _process(delta:float) -> void:
	
	frame_timer += delta
	if frame_timer >= 1.0 / fps:
		frame_timer = 0.0
		frame_index = (frame_index + 1) % (frame_columns * frame_rows)
		if stop_anim:
			frame_index = 0
		particle.material_override.set_shader_parameter("frame_index", frame_index)
