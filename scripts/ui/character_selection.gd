extends Control
class_name CharacterSelection

@onready var portrait: TextureRect = %Portrait #Path: CenterContainer/PanelContainer/HBoxContainer/VBoxContainer/HBoxContainer2/HBoxContainerPortrait/Portrait
@onready var character_name: Label = %CharacterName
@onready var character_flavor_text: Label = %CharacterFlavorText
@onready var left_arrow_button: Button = %LeftArrowButton
@onready var right_arrow_button: Button = %RightArrowButton
@onready var start_adventure: Button = %StartAdventure
@onready var stats_label: Label = %StatsLabel

var character_ids: Array[String] = ["alfred", "emil", "lucy"]
var current_index: int = 0

var character_flavor: Dictionary = {
	"alfred": "A seasoned fighter who survived the collapse alone. Stubborn, capable, and tired.",
	"emil": "A scholar who lost everything to the turning. He carries knowledge no one else remembers.",
	"lucy": "Swift and quiet. She has been surviving on her own from before it all begun."
}

func _ready() -> void:
	left_arrow_button.pressed.connect(_on_left_arrow_button_pressed)
	right_arrow_button.pressed.connect(_on_right_arrow_button_pressed)
	start_adventure.pressed.connect(_on_start_adventure_pressed)
	_update_display()

func _update_display() -> void:
	var id := character_ids[current_index]
	var char_def: CharacterDefinition = Main.save.registry.characters.get(id, null)
	if char_def == null:
		push_error("No definition found for: " + id + ".")
		return
	
	portrait.texture = char_def.base_data.portrait if char_def.base_data.has("portrait") else null
	character_name.text = char_def.base_data.unit_name
	character_flavor_text.text = character_flavor.get(id, "")
	stats_label.text = "STRENGTH: %d\nMIND: %d\nSPEED: %d\nENDURANCE: %d\nFOCUS: %d" % [
		char_def.base_data.strength,
		char_def.base_data.mind,
		char_def.base_data.speed,
		char_def.base_data.endurance,
		char_def.base_data.focus,
	]

func _on_left_arrow_button_pressed() -> void:
	current_index = (current_index - 1 + character_ids.size()) % character_ids.size()
	_update_display()


func _on_right_arrow_button_pressed() -> void:
	current_index = (current_index + 1) % character_ids.size()
	_update_display()


func _on_start_adventure_pressed() -> void:
	Main.selected_starting_character = character_ids[current_index]
	queue_free()
	Main.save.load_tutorial()
