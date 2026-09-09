extends ObjectiveBase
class_name ObjectiveDestroyObject

@export var target_object_name: String = ""

func _setup() -> void:
	if display_text == "":
		display_text = "Destroy the object: " + target_object_name
	# This should check if the name of the object destroyed is the objective 
	# Should be a nautral unit
	Main.level.character_died.connect(_on_character_died)

func _on_character_died(character: Character) -> void:
	if is_complete:
		return
	if character.data.unit_name != target_object_name:
		return
	print("Objective destroyed - running 'on_objective_complete' from DestroyObject.")
	on_objective_complete()
