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

## Variables
var _character : Character = null

func setup(character: Character) -> void:
	_character = character
	portrait.texture = character.portrait if character.portrait != null else null
	unit_name.text = character.data.unit_name
	health.text = "HP: %d/%d" % [character.state.current_health, character.state.max_health]
	sanity.text = "SAN: %d/%d" % [character.state.current_sanity, character.state.max_sanity]
	weapon.text = "WEP: %s" % character.state.weapon.weapon_name if character.state.weapon else "None"
	strength.text = "STR: %d" % character.data.strength
	mind.text = "MND: %d" % character.data.mind
	speed.text = "SPD: %d" % character.data.speed
	endurance.text = "END: %d" % character.data.endurance
	focus.text = "FOC: %d" % character.data.focus
	_refresh_stats()


## FUNCTIONS
func _check_can_continue() -> bool:
	for c in Main.characters:
		if c != null and c.state.unspent_skill_points > 0:
			return false
	return true


func _refresh_stats() -> void:
	strength.text = "STR: %d" % _character.data.strength
	mind.text = "MND: %d" % _character.data.mind
	speed.text = "SPD: %d" % _character.data.speed
	endurance.text = "END: %d" % _character.data.endurance
	focus.text = "FOC: %d" % _character.data.focus
	available_points.text = "Points: %d" % _character.state.unspent_skill_points
	banner_lvl_up.visible = _character.state.unspent_skill_points > 0
	_update_buttons()

func _update_buttons() -> void:
	var has_points := _character.state.unspent_skill_points > 0
	str_button.disabled = not has_points
	mnd_button.disabled = not has_points
	spd_button.disabled = not has_points
	end_button.disabled = not has_points
	fcs_button.disabled = not has_points


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
	_refresh_stats()

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
