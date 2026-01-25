extends Node3D
class_name CombatVFXController

@export var damage_number_scene : PackedScene
@export var hit_particles_scene : PackedScene


func play_attack(result : AttackResult) -> void:
	if result == null:
		return
	
	_spawn_dmg_number_scene(result)
	_spawn_hit_particles(result.victim)
	_trigger_hit_flash(result.victim, result.was_critical)
	
	
func _spawn_dmg_number_scene(result : AttackResult) -> void:
	if not damage_number_scene:
		return

	var dmg : Node3D = damage_number_scene.instantiate()
	get_tree().current_scene.add_child(dmg)
	dmg.global_position = result.victim.global_position + Vector3(0,1,0)
	
	dmg.set_value(
		result.damage,
		result.was_critical
	)

func _spawn_hit_particles(target : Character) -> void:
	if not hit_particles_scene:
		return

	var vfx : Node3D = hit_particles_scene.instantiate()
	target.add_child(vfx)
	vfx.position = Vector3.ZERO

	if vfx.has_method("play"):
		vfx.play()

	
func _trigger_hit_flash(target : Character, crit : bool) -> void:
	if target.has_method("flash_hit"):
		target.flash_hit(crit)
