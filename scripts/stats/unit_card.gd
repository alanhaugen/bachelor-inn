extends PanelContainer
class_name UnitCard

@onready var portrait: TextureRect = %Portrait
@onready var unit_name: Label = %UnitName
@onready var health: Label = %Health
@onready var sanity: Label = %Sanity
@onready var weapon: Label = %Weapon
@onready var strength: Label = %Strenght
@onready var mind : Label = $Mind
@onready var speed: Label = %Speed
@onready var endurance: Label = %Endurance
@onready var focus: Label = %focus

func setup(character: Character) -> void:
	portrait.texture = character.portrait
	unit_name.text = character.data.unit_name
	health.text = "HP: %d/%d" % [character.state.current_health, character.state.max_health]
	sanity.text = "SAN: %d/%d" % [character.state.current_sanity, character.state.max_sanity]
	weapon.text = "WEP: %s" % character.state.weapon.weapon_name if character.state.weapon else "None"
	strength.text = "STR: %d" % character.data.strength
	mind.text = "MND: %d" % character.data.mind
	speed.text = "SPD: %d" % character.data.speed
	endurance.text = "END: %d" % character.data.endurance
	focus.text = "FOC: %d" % character.data.focus
