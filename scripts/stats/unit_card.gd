extends PanelContainer
class_name UnitCard

@onready var portrait: TextureRect = %Portrait
@onready var unit_name: Label = %UnitName
@onready var health: Label = %Health
@onready var sanity: Label = %Sanity
@onready var weapon: Label = %Weapon
@onready var strenght: Label = %Strenght
@onready var mind : Label = $Mind
@onready var speed: Label = %Speed
@onready var endurance: Label = %Endurance
@onready var focus: Label = %focus

func setup(character: Character) -> void:
	pass
