extends Node

const S_HEAL_BASIC: Skill = preload("res://Data/skills/healskill.tres")

var _by_id: Dictionary = {}


func _ready() -> void:
	_by_id.clear()
	_register(S_HEAL_BASIC)


func _register(w: Skill) -> void:
	if w == null:
		push_error("SkillRegister: Tried to reg NULL skill.")
		return
	
	if w.skill_id == "":
		push_error("SkillRegister: skill '" + str(w.skill_name) + "' has EMPTY skill_id (fix the .tres file).")
		return
	
	if _by_id.has(w.skill_id):
		push_warning("SkillRegister: duplicate skill_id '" + w.skill_id + "' found. Overwriting.")
	
	_by_id[w.skill_id] = w;

func get_skill(id: String) -> Skill:
	if _by_id.has(id):
		return _by_id[id];
	
	push_warning("SkillRegister: unknown skill_id found: '" + id + "'. Known: " + str(_by_id.keys()) + ". Returning null")
	return null;
