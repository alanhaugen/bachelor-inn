extends Node
# Weapon_Registry is set to autoload

const W_UNARMED: Weapon = preload("res://Data/Weapons/unarmed.tres")
const W_AXE_BASIC: Weapon = preload("res://Data/Weapons/axe_basic.tres")
#const W_BOW: Weapon = preload()
const W_SCEPTER_BASIC: Weapon = preload("res://Data/Weapons/scepter_basic.tres")
const W_SWORD_BASIC: Weapon = preload("res://Data/Weapons/sword_basic.tres")
#const W_SWORD_ELITE: Weapon = preload("res://Data/Weapons/sword_elite.tres")
const W_SWORD_ADVANCED: Weapon = preload("res://Data/Weapons/sword_advanced.tres")


var _by_id: Dictionary = {}


func _ready() -> void:
	_by_id.clear()
	_register(W_UNARMED)
	_register(W_AXE_BASIC)
	_register(W_SWORD_BASIC)
	_register(W_SCEPTER_BASIC)
	#_register(W_SWORD_ELITE)
	_register(W_SWORD_ADVANCED)
	#_register(W_AXE)


func _register(w: Weapon) -> void:
	if w == null:
		push_error("WepRegister: Tried to reg NULL weapon.")
		return
	
	if w.weapon_id == "":
		push_error("WepRegister: weapon '" + str(w.weapon_name) + "' has EMPTY weapon_id (fix the .tres file).")
		return
	
	if _by_id.has(w.weapon_id):
		push_warning("WepRegister: duplicate weapon_id '" + w.weapon_id+ "' found. Overwriting.")
	
	_by_id[w.weapon_id] = w;

func get_weapon(id: String) -> Weapon:
	if _by_id.has(id):
		return _by_id[id];
	
	push_warning("WepRegister: unknown weapon_id found: '" + id + "'. Known: " + str(_by_id.keys()) + ". Returning UNARMED")
	return W_UNARMED;
	
