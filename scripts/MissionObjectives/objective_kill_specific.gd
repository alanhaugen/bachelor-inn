extends ObjectiveBase
class_name ObjectiveKillSpecificUnit

@export var target_unit_name: String = ""

func _setup() -> void:
	if display_text == "":
		display_text = "Defeat " + target_unit_name
	Main.level.character_died.connect(_on_character_died)

func _on_character_died(character: Character) -> void:
	if is_complete:
		return
	if character.data.unit_name != target_unit_name:
		return
	on_objective_complete()

func disconnect_signals() -> void:
	if Main.level.character_died.is_connected(_on_character_died):
		Main.level.character_died.disconnect(_on_character_died)
