extends Node3D
class_name Chest

enum LootType {WEAPON, SKILL}

@export var loot_type : LootType = LootType.WEAPON
@export var weapon_id: String = ""
@export var skill_id_1: String = ""
@export var skill_id_2: String = ""
@export var skill_id_3: String = ""
@export var dialogue_timeline: String = "chest_tutorial"
var is_opened: bool = false
var is_looted: bool = false
