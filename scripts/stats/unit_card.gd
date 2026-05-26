extends PanelContainer
class_name UnitCard

## UI Elements
@onready var portrait: TextureRect = %Portrait
@onready var unit_name: Label = %UnitName
@onready var health: Label = %Health
@onready var sanity: Label = %Sanity
@onready var weapon: Label = %Weapon
@onready var strength: Label = %Strength
@onready var mind : Label = %Mind
@onready var speed: Label = %Speed
@onready var endurance: Label = %Endurance
@onready var focus: Label = %Focus
@onready var banner_lvl_up : Label = %BannerLvlUp
@onready var available_points : Label = %BannerPoints

## Buttons
@onready var str_button: Button = %STRButton
@onready var mnd_button: Button = %MNDButton
@onready var spd_button: Button = %SPDButton
@onready var end_button: Button = %ENDButton
@onready var fcs_button: Button = %FCSButton
@onready var str_button_all: Button = %STRButtonAll
@onready var mnd_button_all: Button = %MNDButtonAll
@onready var spd_button_all: Button = %SPDButtonAll
@onready var end_button_all: Button = %ENDButtonAll
@onready var fcs_button_all: Button = %FCSButtonAll
@onready var remove_str_button: Button = %RemoveSTRButton
@onready var remove_mnd_button: Button = %RemoveMNDButton
@onready var remove_spd_button: Button = %RemoveSPDButton
@onready var remove_end_button: Button = %RemoveENDButton
@onready var remove_fcs_button: Button = %RemoveFCSButton

## Variables
var _character : Character = null
var _was_at_full_sanity: bool = false
var _was_at_full_health: bool = false

var str_before : int 
var mind_before : int 
var speed_before : int 
var endurance_before : int
var focus_before : int 

func setup(character: Character) -> void:
	_character = character
	
	_was_at_full_sanity = character.state.current_sanity == character.state.max_sanity
	_was_at_full_health = character.state.current_health == character.state.max_health
	
	str_before = character.data.strength
	mind_before = character.data.mind
	speed_before = character.data.speed
	endurance_before = character.data.endurance
	focus_before = character.data.focus
	
	portrait.texture = character.portrait if character.portrait != null else null
	unit_name.text = character.data.unit_name
	health.text = "HEALTH : %d/%d" % [character.state.current_health, character.state.max_health]
	sanity.text = "SANITY : %d/%d" % [character.state.current_sanity, character.state.max_sanity]
	weapon.text = "WEAPON : %s" % character.state.weapon.weapon_name if character.state.weapon else "Unarmed"
	strength.text = "STRENGTH : %d" % character.data.strength
	mind.text = "MIND : %d" % character.data.mind
	speed.text = "SPEED : %d" % character.data.speed
	endurance.text = "ENDURANCE : %d" % character.data.endurance
	focus.text = "FOCUS : %d" % character.data.focus
	_refresh_stats()


## FUNCTIONS
func _check_can_continue() -> bool:
	for c in Main.characters:
		if c != null and c.state.unspent_skill_points > 0:
			return false
	return true


func _refresh_stats() -> void:
	strength.text = "STRENGTH : %d" % _character.data.strength
	mind.text = "MIND : %d" % _character.data.mind
	speed.text = "SPEED : %d" % _character.data.speed
	endurance.text = "ENDURANCE : %d" % _character.data.endurance
	focus.text = "FOCUS : %d" % _character.data.focus
	
	#var expected_max_hp := 4 + _character.data.endurance + int(floor(_character.data.strength / 2.0))
	#var expected_max_san := (4 + int(floor(_character.data.focus / 2.0)) + int(floor(_character.data.endurance / 2.0))) + _character.data.mind

	health.text = "HP: %d/%d" % [_character.state.current_health, _character.state.max_health]
	sanity.text = "SAN: %d/%d" % [_character.state.current_sanity, _character.state.max_sanity]
	available_points.text = "Available Points: %d" % _character.state.unspent_skill_points
	#banner_lvl_up.visible = _character.state.unspent_skill_points > 0
	_update_buttons()


func _update_buttons() -> void:
	#### Buttons enabled disabled
	var has_points := _character.state.unspent_skill_points > 0
	str_button.disabled = not has_points
	str_button_all.disabled = not has_points
	mnd_button.disabled = not has_points
	mnd_button_all.disabled = not has_points
	spd_button.disabled = not has_points
	spd_button_all.disabled = not has_points
	end_button.disabled = not has_points
	end_button_all.disabled = not has_points
	fcs_button.disabled = not has_points
	fcs_button_all.disabled = not has_points
	
	if _character.data.strength == str_before:
		remove_str_button.disabled = true
	else:
		remove_str_button.disabled = false
		
	if _character.data.mind == mind_before:
		remove_mnd_button.disabled = true
	else:
		remove_mnd_button.disabled = false
		
	if _character.data.speed == speed_before:
		remove_spd_button.disabled = true
	else:
		remove_spd_button.disabled = false
	
	if _character.data.endurance == endurance_before:
		remove_end_button.disabled = true
	else:
		remove_end_button.disabled = false
		
	if _character.data.focus == focus_before:
		remove_fcs_button.disabled = true
	else:
		remove_fcs_button.disabled = false
	
	if not has_points:
		var transition := get_tree().get_first_node_in_group("level_transition")
		if transition:
			transition.update_continue_button()


func _spend_skill_point(stat: String) -> void:
	if _character.state.unspent_skill_points <= 0:
		return
	_character.state.unspent_skill_points -= 1
	match stat:
		"strength": _character.data.strength += 1
		"mind": _character.data.mind += 1
		"speed": _character.data.speed += 1
		"endurance": _character.data.endurance += 1
		"focus": _character.data.focus += 1
	_character.update_derived_stats_after_level_up()
	_refresh_stats()
	#var transition := get_tree().get_first_node_in_group("level_transition")
	#if transition:
		#transition.update_continue_button()


func _spend_all_skill_point(stat: String) -> void:
	if _character.state.unspent_skill_points <= 0:
		return
	var p : int = _character.state.unspent_skill_points
	_character.state.unspent_skill_points -= _character.state.unspent_skill_points
	match stat:
		"strength": _character.data.strength += p
		"mind": _character.data.mind += p
		"speed": _character.data.speed += p
		"endurance": _character.data.endurance += p
		"focus": _character.data.focus += p
	_character.update_derived_stats_after_level_up()
	_refresh_stats()
	var transition := get_tree().get_first_node_in_group("level_transition")
	if transition:
		transition.update_continue_button()

func _on_str_button_pressed() -> void:
	_spend_skill_point("strength")

func _on_mnd_button_pressed() -> void:
	_spend_skill_point("mind")

func _on_spd_button_pressed() -> void:
	_spend_skill_point("speed")

func _on_end_button_pressed() -> void:
	_spend_skill_point("endurance")

func _on_fcs_button_pressed() -> void:
	_spend_skill_point("focus")

func _on_str_button_all_pressed() -> void:
	_spend_all_skill_point("strength")

func _on_mnd_button_all_pressed() -> void:
	_spend_all_skill_point("mind")

func _on_spd_button_all_pressed() -> void:
	_spend_all_skill_point("speed")

func _on_end_button_all_pressed() -> void:
	_spend_all_skill_point("endurance")

func _on_fcs_button_all_pressed() -> void:
	_spend_all_skill_point("focus")

func _on_remove_str_button_pressed() -> void:
	if _character.state.unspent_skill_points >= 3:
		return
	_character.data.strength -= 1
	_character.state.unspent_skill_points += 1
	_character.update_derived_stats_after_level_up()
	_refresh_stats()

func _on_remove_mnd_button_pressed() -> void:
	if _character.state.unspent_skill_points >= 3:
		return
	_character.data.mind -= 1
	_character.state.unspent_skill_points += 1
	_character.update_derived_stats_after_level_up()
	_refresh_stats()

func _on_remove_spd_button_pressed() -> void:
	if _character.state.unspent_skill_points >= 3:
		return
	_character.data.speed -= 1
	_character.state.unspent_skill_points += 1
	_character.update_derived_stats_after_level_up()
	_refresh_stats()

func _on_remove_end_button_pressed() -> void:
	if _character.state.unspent_skill_points >= 3:
		return
	_character.data.endurance -= 1
	_character.state.unspent_skill_points += 1
	_character.update_derived_stats_after_level_up()
	_refresh_stats()

func _on_remove_fcs_button_pressed() -> void:
	if _character.state.unspent_skill_points >= 3:
		return
	_character.data.focus -= 1
	_character.state.unspent_skill_points += 1
	_character.update_derived_stats_after_level_up()
	_refresh_stats()
