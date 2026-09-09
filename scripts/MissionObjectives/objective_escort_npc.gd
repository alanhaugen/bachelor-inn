extends ObjectiveBase
class_name ObjectiveEscortNpc

@export var target_npc_name: String = ""
var npc: Character = null

func _setup() -> void:
	if display_text == "":
		display_text = "Find and escort " + target_npc_name + " to safety."# if display_text == "" else display_text
	Main.level.character_died.connect(_on_character_died)
	Main.level.character_stats_changed.connect(_on_stats_changed)

## Game over if the NPC dies
func _on_character_died(character: Character) -> void:
	if is_complete:
		return
	if not is_instance_valid(Main.level):
		return
	if character.data.unit_name == target_npc_name:
		Main.level.trigger_game_over()

func _on_stats_changed(character: Character) -> void:
	print("ObjectiveEscortNpc stats changed: ", character.data.unit_name, 
		  " faction: ", character.state.faction)
	if npc != null:
		print("NPC already set: ", npc.data.unit_name)
		return
	if character.data.unit_name != target_npc_name:
		print("Name mismatch: ", character.data.unit_name, " != ", target_npc_name)
		return
	if character.state.faction == CharacterState.Faction.PLAYER:
		npc = character
		print("NPC reference acquired: ", npc.data.unit_name)
	else:
		print("Faction not player: ", character.state.faction)

func disconnect_signals() -> void:
	if Main.level.character_died.is_connected(_on_character_died):
		Main.level.character_died.disconnect(_on_character_died)
	if Main.level.character_stats_changed.is_connected(_on_stats_changed):
		Main.level.character_stats_changed.disconnect(_on_stats_changed)
