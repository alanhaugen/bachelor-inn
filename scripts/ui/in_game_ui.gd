extends Control
class_name ui_controller

#@export var SelectedCharacterStatus: PackedScene
@export var CharacterPreview: PackedScene 
#var level.gd (holds all the data i need, i probably should only get the dictionary from it when stats like
#selected character or hp change, 
@onready var preview_container := %Characters_VBOX



#build all stats into a dictionary for use in the sub UI items
func build_character_stats(character: Character) -> Dictionary:
	return {
		"portrait": character.portrait,
		"name": character.data.unit_name,

		"health": character.state.current_health,
		"max_health": character.state.max_health,
		"sanity": character.state.current_sanity,
		"max_sanity": character.state.max_sanity,

		"strength": character.data.strength,
		"mind": character.data.mind,
		"speed": character.data.speed,
		"focus": character.data.focus,
		"endurance": character.data.endurance,

		"level": character.state.current_level,
		"type": "%s %s" % [
			CharacterData.Speciality.keys()[character.data.speciality],
			CharacterData.Personality.keys()[character.data.personality]
		]
	}


#Update the player stats to send it to the Player_Stats, gets set in its own script
func update_playerStats(character: Character, popup: StatPopUp) -> void:
	popup.apply_stats(build_character_stats(character))
	popup.show();


#adds character preview scene to Vbox
func _add_CharacterPreview(character: Character) -> CharacterPreview:
	var preview := CharacterPreview.instantiate()
	preview_container.add_child(preview)
	preview.apply_stats(build_character_stats(character))
	return preview
