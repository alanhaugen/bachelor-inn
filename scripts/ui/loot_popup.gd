extends Control
class_name LootPopup

@onready var current_weapon_icon: TextureRect = %CurrentWeaponIcon
@onready var current_weapon_name: Label = %CurrentWeaponName
@onready var current_weapon_stats: Label = %CurrentWeaponStats

@onready var new_weapon_icon: TextureRect = %NewWeaponIcon
@onready var new_weapon_name: Label = %NewWeaponName
@onready var new_weapon_stats: Label = %NewWeaponStats

@onready var button_discard: Button = $ButtonDiscard
@onready var button_keep : Button = $ButtonKeep

var _current_weapon: Weapon = null
var _new_weapon: Weapon = null
var _character: Character = null

func show_lootU(current_weapon: Weapon, new_weapon: Weapon, char: Character) -> void:
	pass


func set_weapon_in_loot_window(icon: Texture2D, name_label: Label, stats_label: Label, 
weapon: Weapon) -> void:
		pass

func _on_discard_button_pressed() -> void:
	hide()
	## add signal for discarded weapon

func _on_keep_button_pressed() -> void:
	if _character != null and _new_weapon != null:
		_character.state.weapon = _new_weapon
	hide()
	## add singlal and function for keeping new weapon
