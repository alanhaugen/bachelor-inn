extends Resource
class_name CharacterState
## CharacterSate is pure state information.
## No scene or node access should happen here.

#region enums
enum Faction { PLAYER, ENEMY, NEUTRAL }

enum SanityState
{
	CALM, # clear-minded
	UNEASY, # doubt
	DISTORTED, # focus
	OBSESSED, # fear
	DISSOCIATED # delusion
}
#endregion

#region signals
signal sanity_changed(new_value: int)
signal experience_changed(new_value: int)
signal level_changed(new_level: int)
#endregion

#region variables
@export var weapon : Weapon = WeaponRegistry.get_weapon("unarmed");

@export var faction : Faction = Faction.PLAYER;
@export var connections : Array[int] = [];

@export var grid_position: Vector3i;
@export var next_level_experience: int = 1;
@export var is_alive: bool = true;
@export var is_moved :bool = false;
@export var has_preformed_action :bool = false;
@export var is_ability_used :bool = false;
@export var experience := 0 : set = _set_experience
@export var level := 1
@export var skills: Array[Skill] = []
@export var active_effects: Array[Dictionary] = []
#endregion

#region inferred vars calculated from CharacterData on spawn
@export var max_health : int
@export var max_sanity : int
@export var movement : int
@export var current_health : int
@export var current_sanity : int : set = _set_sanity
@export var current_level : int = 1
@export var stability : int
@export var defense : int
@export var resistance : int
#endregion


#region methods
func is_enemy() -> bool:
	return faction == Faction.ENEMY;


func is_playable() -> bool:
	return faction == Faction.PLAYER;


func duplicate_data() -> CharacterState:
	return duplicate(true);


func _set_sanity(value: int) -> void:
	current_sanity = clamp(value, 0, max_sanity)
	sanity_changed.emit(current_sanity)


func _set_experience(value: int) -> void:
	experience = max(value, 0)

	if experience >= next_level_experience:
		experience -= next_level_experience
		level += 1
		level_changed.emit(level)

	experience_changed.emit(experience)


func get_sanity_state() -> SanityState:
	var sanity := (float(current_sanity) / max_sanity) * 100.0
	
	if sanity >= 80:
		return SanityState.CALM
	elif sanity >= 60:
		return SanityState.UNEASY
	elif sanity >= 40:
		return SanityState.DISTORTED
	elif sanity >= 20:
		return SanityState.OBSESSED
	else:
		return SanityState.DISSOCIATED


func apply_skill_effect(skill: Skill) -> void:
	if skill == null:
		return

	if skill.duration_turns <= 0:
		return

	# Check if effect already exists + refresh duration
	for e in active_effects:
		if e.get("id") == skill.skill_id:
			e["rounds"] = max(int(e.get("rounds", 0)), skill.duration_turns)
			e["mods"] = skill.effect_mods.duplicate(true)
			e["source"] = skill.skill_id
			return
			
	active_effects.append({
		"id": skill.skill_id,
		"rounds": skill.duration_turns,
		"mods": skill.effect_mods.duplicate(true),
		"source": skill.skill_id})

func get_effective_movement() -> int:
	var base: int = movement
	var bonus: int = 0
	const K_MOVEMENT: StringName = &"movement"

	for e: Dictionary in active_effects:
		var mods: Dictionary = e.get("mods", {}) as Dictionary
		bonus += int(mods.get(K_MOVEMENT, 0))

	return max(0, base + bonus)

## This tics down spells and effects that lasts for more than 1 round.
func tick_effects_end_round() -> void:
	for i in range(active_effects.size() - 1, -1, -1):
		var e: Dictionary = active_effects[i]

		# Missing rounds? Treat as expired.
		if not e.has("rounds"):
			active_effects.remove_at(i)
			continue

		var r: int = int(e.get("rounds", 0)) - 1
		if r <= 0:
			active_effects.remove_at(i)
		else:
			e["rounds"] = r
			active_effects[i] = e 


static func make_active_effect(skill: Skill, caster: Object) -> Dictionary:
	return {
		"skill": skill,
		"skill_id": skill.skill_id,
		"caster": caster, # can be Character, CharacterState, etc.
		"caster_instance_id": caster.get_instance_id() if caster else 0,
		"remaining_turns": skill.duration_turns,
		"mods": skill.effect_mods.duplicate(true) # deep copy
	}

func save() -> Dictionary:
	# Convert Skill resources -> Array[String] for JSON
	var ids: Array[String] = []
	for s: Skill in skills:
		if s == null:
			continue
		if s.skill_id == "":
			continue
		ids.append(s.skill_id)
	
	return {
		"faction": faction,
		"grid_position": [grid_position.x, grid_position.y, grid_position.z],
		"is_alive": is_alive,
		"is_moved": is_moved,
		"experience": experience,
		"level": level,
		"current_health": current_health,
		"current_sanity": current_sanity,
		"weapon_id": weapon.weapon_id,
		"skill_ids" : ids
	}
#endregion
