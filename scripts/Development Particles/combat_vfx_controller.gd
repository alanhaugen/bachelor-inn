extends Node3D
class_name CombatVFXController

@export var damage_number_scene : PackedScene
@export var hit_particles_scene : PackedScene
@export var ranged_attack_scene : PackedScene
@export var melee_attack_scene  : PackedScene

var _is_aniamting_attack : bool = false;

func play_attack(result : AttackResult) -> void:
	if result == null:
		return
	
	var attacker : Character= result.aggressor
	if attacker and attacker.state and attacker.state.weapon:
		if attacker.state.weapon.is_melee:
			await _spawn_melee_attack(attacker, result.victim, result)
		else:
			await _spawn_ranged_attack(attacker, result.victim, result)

	
	
	
	
	
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


func _spawn_melee_attack(attacker : Character, target : Character, result: AttackResult) -> void:
	if not melee_attack_scene:
		return
	var slice := melee_attack_scene.instantiate()
	get_tree().current_scene.add_child(slice)
	
	var start_pos: = attacker.global_position + Vector3(0, 0, 0)
	var end_pos: = target.global_position + Vector3(0, 0, 0)
	slice.global_position = start_pos
	slice.look_at(end_pos, Vector3.UP)
	slice.rotation_degrees.y -= 60.0
	
	_is_aniamting_attack = true;
	var tween: = slice.create_tween()

	tween.tween_property(
		slice, 
		"rotation_degrees:y", 
		slice.rotation_degrees.y + 30.0, 
		0.2
	)
	
	
	await tween.finished
	slice.queue_free()
	_spawn_hit_particles(target)
	_spawn_dmg_number_scene(result)
	_trigger_hit_flash(target, result.was_critical)
	_is_aniamting_attack = false;
	
func _spawn_ranged_attack(attacker : Character, target : Character, result: AttackResult) -> void:
	if not ranged_attack_scene:
		return
	var projectile := ranged_attack_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	
	var start_pos: = attacker.global_position + Vector3(0, 1, 0)
	var end_pos: = target.global_position + Vector3(0, 1, 0)

	projectile.global_position = start_pos
	projectile.look_at(end_pos, Vector3.UP)
	
	_is_aniamting_attack = true;
	var tween: = projectile.create_tween()
	
	tween.tween_property(
		projectile, 
		"global_position", 
		end_pos, 
		0.25
	)
	await tween.finished
	projectile.queue_free()
	_spawn_hit_particles(target)
	_spawn_dmg_number_scene(result)
	_trigger_hit_flash(target, result.was_critical)
	_is_aniamting_attack = false;
	
func is_finished() -> bool:
	return !_is_aniamting_attack
	
	
	
