extends Node
# WeaponRegistry is set to autoload

const W_UNARMED: Weapon = preload("res://data/weapons/Unarmed.tres")
const W_AXE: Weapon     = preload("res://data/weapons/Axe.tres")
const W_BOW: Weapon     = preload("res://data/weapons/Bow.tres")
const W_SCEPTER: Weapon = preload("res://data/weapons/Scepter.tres")
const W_SPEAR: Weapon   = preload("res://data/weapons/Spear.tres")
const W_SWORD: Weapon   = preload("res://data/weapons/Sword.tres")

var _by_id: Dictionary = {}

func _ready() -> void:
	_by_id.clear()
	_register(W_UNARMED)
	_register(W_AXE)
	_register(W_BOW)
	_register(W_SCEPTER)
	_register(W_SPEAR)
	_register(W_SWORD)

	#print("WeaponRegistry keys:", _by_id.keys())

func _register(w: Weapon) -> void:
	if w == null:
		push_error("WeaponRegistry: tried to register null weapon")
		return

	if w.weapon_id == "":
		push_error("WeaponRegistry: weapon '" + str(w.weapon_name) + "' has EMPTY weapon_id (fix the .tres)")
		return

	if _by_id.has(w.weapon_id):
		push_warning("WeaponRegistry: duplicate weapon_id '" + w.weapon_id + "' (overwriting)")

	_by_id[w.weapon_id] = w

func get_weapon(id: String) -> Weapon:
	if _by_id.has(id):
		return _by_id[id]

	push_warning("WeaponRegistry: unknown weapon_id '" + id + "'. Known: " + str(_by_id.keys()))
	return W_UNARMED
