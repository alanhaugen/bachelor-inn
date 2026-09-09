extends ObjectiveBase
class_name ObjectiveKillAll

func _setup() -> void:
	if display_text == "":
		display_text = "Defeat all enemies."# if display_text == "" else display_text
	Main.level.character_died.connect(_on_character_died)

func _on_character_died(character: Character) -> void:
	if is_complete:
		return
	if not is_instance_valid(Main.level):
		return
	if not character.state.is_enemy():
		return
	for c in Main.level.characters:
		if c == null:
			continue
		if c.state.is_enemy() and c.state.is_alive:
			return
	on_objective_complete()	
	#is_complete = true

func disconnect_signals() -> void:
	if Main.level.character_died.is_connected(_on_character_died):
		Main.level.character_died.disconnect(_on_character_died)
