extends Sprite3D
class_name Sprite3DAnimator

@export_category("Animations")
@export var base_animation : SpriteAnim

#@export_category("Atlas Layout")
#@export var frame_columns : int = 6
#@export var frame_rows : int = 1

@export_category("Playback")
@export var autoplay : bool = true

var current_animation : SpriteAnim = null
var frame_index : int = 0
var frame_timer : float = 0.0


func play(anim : SpriteAnim) -> void:
	if anim == null:
		return

	current_animation = anim
	frame_index = 0
	frame_timer = 0.0

	var mat := material_override as ShaderMaterial
	if mat == null:
		push_error("Sprite3DAnimator requires a ShaderMaterial on material_override.")
		return

	mat.set_shader_parameter("diffuse_atlas", anim.diffuse_atlas)
	mat.set_shader_parameter("normal_atlas", anim.normal_atlas)
	mat.set_shader_parameter("mask_atlas", anim.mask_atlas)

	mat.set_shader_parameter("frame_index", 0)
	mat.set_shader_parameter("frame_columns", current_animation.frame_columns)
	mat.set_shader_parameter("frame_rows", current_animation.frame_rows)


func _ready() -> void:
	if autoplay and base_animation:
		play(base_animation)




func _process(delta : float) -> void:
	if current_animation == null:
		return

	frame_timer += delta
	if frame_timer >= 1.0 / current_animation.fps:
		frame_timer = 0.0
		frame_index = (frame_index + 1) % (current_animation.frame_columns * current_animation.frame_rows)
		material_override.set_shader_parameter("frame_index", frame_index)


func play_animation() -> void:
	play(base_animation)
