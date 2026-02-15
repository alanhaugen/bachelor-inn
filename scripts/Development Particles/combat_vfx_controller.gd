extends Node3D
class_name CombatVFXController

@export var damage_number_scene : PackedScene
@export var hit_particles_scene : PackedScene
@export var ranged_attack_scene : PackedScene

func play_attack(result : AttackResult) -> void:
	if result == null:
		return
	
	var attacker : Character= result.aggressor
	if attacker and attacker.state and attacker.state.weapon:
		if attacker.state.weapon.is_melee():
			_spawn_hit_particles(result.victim)
			_spawn_dmg_number_scene(result)
			_trigger_hit_flash(result.victim, result.was_critical)
		else:
			_spawn_ranged_attack(attacker, result.victim, result)
	
	
	
	
	
	
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


func _spawn_ranged_attack(attacker : Character, target : Character, result: AttackResult) -> void:
	if not ranged_attack_scene:
		return
	var projectile := ranged_attack_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = attacker.global_position + Vector3(0, 1, 0)
	
	var tween: = projectile.create_tween()
	tween.tween_property(
		projectile, "global_position", target.global_position + Vector3(0, 1, 0), 0.5
	)
	
	tween.finished.connect(func() -> void:
		projectile.queue_free()
		_spawn_hit_particles(target)
		_spawn_dmg_number_scene(result)
		_trigger_hit_flash(target, result.was_critical)
	)
	
	
	
	
	
