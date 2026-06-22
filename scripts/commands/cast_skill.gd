extends Command
class_name CastSkill

var target_pos: Vector3i
var skill: Skill

func _init(inStartPos: Vector3i, inEndPos: Vector3i, inTargetPos: Vector3i, inSkill: Skill) -> void:
	start_pos = inStartPos
	end_pos = inEndPos
	target_pos = inTargetPos
	skill = inSkill
	
func prepare(state: GameState, simulate_only: bool = false) -> void:
	result = AttackResult.new()
	var caster: Character = state.get_unit(end_pos)
	if caster == null:
		caster = state.get_unit(start_pos)
	var target: Character = state.get_unit(target_pos)
	
	result.aggressor = caster
	result.victim = target if target != null else caster
	result.target_position = Main.level.grid_to_world(target_pos) + Vector3(0,1,0)
	result.vfx_scene = skill.Vfx_Scene if skill.Vfx_Scene != null else null
	
	if skill.uses_action:
		caster.state.is_ability_used = true
	caster.state.is_moved = true
	
	if skill.effect_mods != null and skill.effect_mods.has("damage") and target != null:
		result.damage = skill.effect_mods.get("damage", 0)

func apply_damage(state: GameState, simulate_only: bool = false) -> void:
	var caster: Character = result.aggressor
	var target: Character = state.get_unit(target_pos)
	
	if target != null and skill.effect_mods != null and skill.effect_mods.has("damage"):
		var dmg := int(skill.effect_mods["damage"])
		target.apply_damage(dmg, simulate_only, caster, skill.skill_name)
		if not simulate_only:
			Main.level.emit_signal("character_stats_changed", target)
	
	if target != null and skill.effect_mods != null and skill.effect_mods.has("current_health"):
		var heal := int(skill.effect_mods["current_health"])
		target.state.current_health = min(target.state.current_health + heal, target.state.max_health)
		if not simulate_only:
			Main.level.emit_signal("character_stats_changed", target)
	
	if simulate_only:
		return
	
	# AoE
	var aoe_tiles := Main.level._get_aoe_tiles(target_pos, skill)
	for aoe_pos in aoe_tiles:
		if aoe_pos == target_pos:
			continue
		var aoe_target: Character = Main.level.get_unit(aoe_pos)
		if aoe_target == null:
			continue
		if not Main.level._is_valid_target(aoe_target, skill, caster):
			continue
		if skill.effect_mods != null and skill.effect_mods.has("damage"):
			var dmg := int(skill.effect_mods["damage"])
			aoe_target.apply_damage(dmg, simulate_only, caster, skill.skill_name)
			Main.level.combat_vfx.spawn_damage_number(dmg, aoe_target.global_position)
		if skill.effect_mods != null and skill.effect_mods.has("current_health"):
			var heal := int(skill.effect_mods["current_health"])
			aoe_target.state.current_health = min(aoe_target.state.current_health + heal, aoe_target.state.max_health)
		aoe_target.state.apply_skill_effect(skill)
		Main.level.emit_signal("character_stats_changed", aoe_target)
	
	if Tutorial.in_tutorial and skill.skill_id == "heal_basic":
		Tutorial.heal_cast = true
		Tutorial.can_advance_timeline = true
		Tutorial.advance_timeline()
