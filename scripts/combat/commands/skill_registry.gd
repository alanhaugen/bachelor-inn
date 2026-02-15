extends Node
# TODO: Set to autoload

const S_NO_SKILL = preload("res://Data/Abilities/no_skill.tres")
const S_HEAL_BASIC = preload("res://Data/Abilities/heal_basic.tres")
const S_FIREBALL_BASIC = preload("res://Data/Abilities/fireball_basic.tres")
const S_MELEE_SWEEP = preload("res://Data/Abilities/melee_sweep.tres")
const S_HASTE_BASIC = preload("res://Data/Abilities/haste_basic.tres")

var _by_id: Dictionary = {}


func _ready() -> void:
	_by_id.clear()
	_register(S_NO_SKILL)
	_register(S_HEAL_BASIC)
	_register(S_FIREBALL_BASIC)
	_register(S_MELEE_SWEEP)
	_register(S_HASTE_BASIC)

func _register(s: Skill) -> void:
	if s == null:
		push_error("SkillRegister: Tried to reg NULL skill.")
		return
	
	if s.skill_id == "":
		push_error("SkillRegister: Skill '" + str(s.skill_name) + "' has EMPTY skill_id (fix the .tres file).")
		return
	
	if _by_id.has(s.skill_id):
		push_warning("SkillRegister: duplicate skill_id '" + s.skill_id+ "' found. Overwriting.")
	
	_by_id[s.skill_id] = s;

func get_skill(id: String) -> Skill:
	if _by_id.has(id):
		return _by_id[id];
	
	push_warning("SkillRegister: unknown skill_id found: '" + id + "'. Known: " + str(_by_id.keys()) + ". Returning NOTHING")
	return S_NO_SKILL;
