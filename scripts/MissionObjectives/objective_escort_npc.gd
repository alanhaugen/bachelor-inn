extends ObjectiveBase
class_name ObjectiveEscortNpc

@export var target_npc_name: String = ""
@export var escape_trigger: String = "05_escape"
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
	if not character.state.is_enemy():
		return
	for c in Main.level.characters:
		if c == null:
			continue
		if c.state.name == target_npc_name and not c.state.is_alive:
			Main.level.trigger_game_over()
		else:
			return
	#on_objective_complete()

func _on_stats_changed(character: Character) -> void:
	if npc != null:
		return
	if character.data.unit_name != target_npc_name:
		return
	if character.state.faction == CharacterState.Faction.PLAYER:
		npc = character
