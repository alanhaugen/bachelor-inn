extends Node3D
class_name CombatVFXController

@export var damage_number_scene : PackedScene
@export var hit_particles_scene : PackedScene
@export var ranged_attack_scene : PackedScene
@export var ranged_attack_magic : PackedScene
@export var melee_attack_scene  : PackedScene
@export var melee_attack_magic  : PackedScene
@export var blood_splatter  : PackedScene
@export var splash_radius: float = 1.0

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

func play_skill(result : AttackResult) -> void:
	#if result == null:
		#return
	#var dmg : int = result.damage if result.damage != null else 0
	#print("play_skill dmg: ", dmg)
	#if dmg > 0:
		#_spawn_dmg_number_scene(result)
	#
	#var effect : PackedScene = result.vfx_scene
	#print("play_skill effect: ", effect)
	#if effect == null:
		#return
		#
	#var vfx : Node3D = effect.instantiate()
	#print("vfx instantiated: ", vfx)
	#get_tree().current_scene.add_child(vfx)
	#print("vfx added to scene at: ", result.aggressor.global_position)
	#vfx.global_position = result.aggressor.global_position + Vector3(0,1,0)
	#vfx.look_at(result.victim.global_position + Vector3(0,1,0), Vector3.UP)
		#
	#print("play_skill called, vfx_scene: ", result.vfx_scene)
	##var target : Character = result.victim
	#
	#var tween := vfx.create_tween()
	#tween.tween_property(vfx, "global_position", result.victim.global_position + Vector3(0,1,0), 0.25)
	#await tween.finished
	#print("tween finished, freeing vfx")
	#vfx.queue_free()
	#
	#if dmg > 0:
		#_spawn_hit_particles(result.victim)
		#_trigger_hit_flash(result.victim, result.was_critical)
		
	if result == null:
		return
	
	var dmg : int = result.damage if result.damage != null else 0
	if dmg > 0:
		_spawn_dmg_number_scene(result)
		
	var effect : PackedScene = result.vfx_scene
	if effect == null:
		return
	
	var vfx : Node3D = effect.instantiate()
	get_tree(). current_scene.add_child(vfx)
	
	## TODO: Effect plays twice if AoE ability is cast directly on enemy
	if dmg > 0:
		vfx.global_position = result.aggressor.global_position + Vector3(0,0.5,0)
		vfx.look_at(result.victim.global_position + Vector3(0,0.5,0), Vector3.UP)
		var tween := vfx.create_tween()
		tween.tween_property(vfx, "global_position", result.victim.global_position + Vector3(0,0.5,0), 0.25)
		await tween.finished
		if vfx.has_method("play"):
			await vfx.play()
		else:
			await get_tree().create_timer(0.5).timeout
			vfx.queue_free()
		_spawn_hit_particles(result.victim)
		_trigger_hit_flash(result.victim, result.was_critical)
	else:
		vfx.global_position = result.target_position if result.target_position != Vector3.ZERO else result.aggressor.global_position#result.victim.global_position
		if vfx.has_method("play"):
			await vfx.play()
		else:
			await get_tree().create_timer(0.5).timeout
			vfx.queue_free()
	return


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


func spawn_damage_number(amount: int, position: Vector3, is_critical: bool = false) -> void:
	if not damage_number_scene:
		return
	var dmg: Node3D = damage_number_scene.instantiate()
	get_tree().current_scene.add_child(dmg)
	dmg.global_position = position + Vector3(0, 1, 0)
	dmg.set_value(amount, is_critical)


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

func _spawn_blood_splatter(target : Character, attacker : Character) -> void:
	if not blood_splatter:
		return
	
	var space_state: PhysicsDirectSpaceState3D = target.get_world_3d().direct_space_state
	var attacker_pos: Vector3 = attacker.global_position
	var target_pos: Vector3 =target.global_position
	#make flat :3
	attacker_pos.y = 0
	target_pos.y = 0
	
	var splash_dir: Vector3 = (target_pos - attacker_pos).normalized()

	var splash_center: Vector3 = target.global_position + (splash_dir * splash_radius)
	
	var start_pos: Vector3 = splash_center + Vector3(0, 1.0, 0)
	var end_pos: Vector3 = splash_center + Vector3(0, -4.0, 0)
	
	#old places under 
	#var start_pos: Vector3 = target.global_position + Vector3(0, 1.0, 0)
	#var end_pos: Vector3 = target.global_position + Vector3(0, -4.0, 0)
	
	#checks collission mask 2 :3
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.collision_mask = 2
	var result: Dictionary = space_state.intersect_ray(query)
	if not result.is_empty():
		var splatter: Node3D = blood_splatter.instantiate()
		
		if "bloodColor" in target:
			splatter.bloodCol = target.bloodColor
		get_tree().current_scene.add_child(splatter)
		splatter.global_position = result.position + Vector3(0, 0.01, 0)

		var look_target: Vector3 = splatter.global_position + splash_dir
		splatter.look_at(look_target, Vector3.UP)
		
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
	_spawn_blood_splatter(target, attacker)
	_is_aniamting_attack = false;
	
func _spawn_ranged_attack(attacker : Character, target : Character, result: AttackResult) -> void:
	var projectile_scene: PackedScene = result.vfx_scene if result.vfx_scene != null else ranged_attack_scene
	if not ranged_attack_scene:
		return
	
	#var projectile := ranged_attack_scene.instantiate()
	var projectile := projectile_scene.instantiate()
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
	_spawn_blood_splatter(target, attacker)
	_is_aniamting_attack = false;

## Delete
#func _spawn_ability_attack(attacker : Character, target : Character, result: AttackResult) -> void:
	##var projectile_scene: PackedScene = result.vfx_scene if result.vfx_scene != null else ranged_attack_scene
	#var effect : PackedScene = result.vfx_scene
	#if effect == null:
		#return
	##if not ranged_attack_scene:
	##	return
	#
	##var projectile := ranged_attack_scene.instantiate()
	##var projectile := projectile_scene.instantiate()
	#var vfx : Node3D = effect.instantiate()
	#get_tree().current_scene.add_child(vfx)
	#
	#var start_pos: = attacker.global_position + Vector3(0, 1, 0)
	#var end_pos: = target.global_position + Vector3(0, 1, 0)
	#vfx.global_position = start_pos
	#vfx.look_at(end_pos, Vector3.UP)
	#
	##_is_aniamting_attack = true;
	#var tween: = vfx.create_tween()
	#tween.tween_property(
		#vfx, 
		#"global_position", 
		#end_pos, 
		#0.25
	#)
	#await tween.finished
	#vfx.queue_free()
	#if result.damage > 0:
		#_spawn_hit_particles(target)
		#_spawn_dmg_number_scene(result)
		#_trigger_hit_flash(target, result.was_critical)
	#_is_aniamting_attack = false;


func is_finished() -> bool:
	return !_is_aniamting_attack
