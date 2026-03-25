extends Command
class_name SkillCommand

var skill: Skill
var caster: Character
var target: Character

func _init(in_caster: Character, in_target: Character, in_skill: Skill) -> void:
	caster = in_caster
	target = in_target
	skill = in_skill
	start_pos = caster.state.grid_position
	end_pos = target.state.grid_position

func execute(state: GameState, simulate_only: bool = false) -> void:
	# In the current engine, execute is often used for movement. 
	# For skills, we might just set the flags.
	var sim_caster := state.get_unit(start_pos)
	if sim_caster:
		if skill.uses_action:
			sim_caster.state.is_ability_used = true
	
func prepare(state: GameState, simulate_only: bool = false) -> void:
	result = AttackResult.new()
	result.aggressor = state.get_unit(start_pos)
	result.victim = state.get_unit(end_pos)
	result.vfx_scene = skill.Vfx_Scene
	
	if skill.effect_mods != null and skill.effect_mods.has("damage"):
		result.damage = skill.effect_mods["damage"]

func apply_damage(state: GameState, simulate_only: bool = false) -> void:
	if not result or not result.aggressor or not result.victim:
		return
	
	var sim_victim := result.victim
	var sim_aggressor := result.aggressor
	
	# Apply damage
	if result.damage > 0:
		sim_victim.apply_damage(result.damage, simulate_only, sim_aggressor, skill.skill_name)
	
	# Apply DoT/Effects
	sim_victim.state.apply_skill_effect(skill)
	
	if not simulate_only:
		if is_instance_valid(Main.level):
			Main.level.combat_vfx.play_skill(result)
			Main.level.emit_signal("character_stats_changed", sim_victim)
			if skill.uses_action:
				Main.level.emit_signal("ability_used")

func undo(state: GameState, _simulate_only: bool = false) -> void:
	# Undo is tricky for skills without full state snapshots, but we can try basic stuff if needed.
	# Currently many commands have limited undo.
	var sim_caster := state.get_unit(start_pos)
	if sim_caster and not _simulate_only:
		if skill.uses_action:
			sim_caster.state.is_ability_used = false
