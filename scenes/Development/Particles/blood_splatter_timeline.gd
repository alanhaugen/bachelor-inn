extends Node3D

@export_group("scalings")
@export var min_x_scale: float = 0.3
@export var max_x_scale: float = 1.0
@export var min_z_scale: float = 0.9
@export var max_z_scale: float = 3.0

@export_group("Settings")
@export var mesh: MeshInstance3D 
@export var duration: float = 10.0

var bloodCol: Color = Color.DARK_RED 

func _ready() -> void:
	rand_scale()
	tween_shader()
	
func rand_scale() -> void:
	var random_x: float = randf_range(min_x_scale, max_x_scale)
	var random_z: float = randf_range(min_z_scale, max_z_scale)
	scale = Vector3(random_x, scale.y, random_z)

func tween_shader() -> void:
	if not mesh:
		return
	#get mat and dupe mat cuz timeline was global for all who had this mat lol
	var b_mat: ShaderMaterial = mesh.get_active_material(0)
	if not b_mat or not b_mat is ShaderMaterial:
		return
	var mat: ShaderMaterial = b_mat.duplicate()
	mesh.set_surface_override_material(0, mat)
	
	mat.set_shader_parameter("albedo", bloodCol)
	var tween: Tween = create_tween()
	mat.set_shader_parameter("d_value", 0.0)
	tween.tween_property(mat, "shader_parameter/d_value", 1.0, duration)
	
	tween.tween_callback(queue_free)
