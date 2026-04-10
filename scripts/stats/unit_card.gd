extends PanelContainer
class_name UnitCard

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


func setup(character: Character) -> void:
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

## FUNCTIONS
func _check_can_continue() -> bool:
	for c in Main.characters:
		if c != null and c.state.unspent_skill_points > 0:
			return false
	return true

func _on_str_button_pressed() -> void:
	pass # Replace with function body.


func _on_mnd_button_pressed() -> void:
	pass # Replace with function body.


func _on_spd_button_pressed() -> void:
	pass # Replace with function body.


func _on_end_button_pressed() -> void:
	pass # Replace with function body.


func _on_fcs_button_pressed() -> void:
	pass # Replace with function body.
