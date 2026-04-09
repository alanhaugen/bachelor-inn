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

func show_loot(current_weapon: Weapon, new_weapon: Weapon, char: Character) -> void:
	print("Loot Window triggered.")
	_current_weapon = current_weapon
	_new_weapon = new_weapon
	_character = char
	
	_set_weapon_in_loot_window(current_weapon_icon, current_weapon_name, current_weapon_stats, 
	current_weapon)
	_set_weapon_in_loot_window(new_weapon_icon, new_weapon_name, new_weapon_stats, new_weapon)
	
	show()


func _set_weapon_in_loot_window(icon: TextureRect, name_label: Label, stats_label: Label, 
weapon: Weapon) -> void:
	if weapon == null:
		icon.texture = null
		name_label.text = "No weapon found"
		stats_label.text = ""
		return
	
	icon.texture = weapon.weapon_icon if weapon.weapon_icon != null else null
	name_label.text = weapon.weapon_name if weapon.weapon_name != "" else "Unknown"
	stats_label.text = "DMG: %+d\nRNG: %d-%d\nCRIT: %d" % [
		weapon.damage_modifier,
		weapon.min_range,
		weapon.max_range,
		weapon.weapon_critical
	]


func _on_button_discard_pressed() -> void:
	hide()
	## add signal for discarded weapon


func _on_button_keep_pressed() -> void:
	if _character != null and _new_weapon != null:
		_character.state.weapon = _new_weapon
	hide()
	## add singlal and function for keeping new weapon
