extends Node
class_name GameManager

# Core State Variables
@export var current_level_name: String = ""
var active_characters: Array[Character] = []
var current_save_slot: int = -1 # 0-indexed, -1 means no save
var is_player_in_menu: bool = false

# Signals for state change observation
signal level_changed(level_name: String)
signal characters_updated(characters: Array[Character])


# --- Character Management ---

func add_character(character: Character) -> void:
	# Use a set or check for existence if we anticipate multiple additions
	if not active_characters.has(character):
		active_characters.append(character)
		emit_signal("characters_updated", active_characters)

func set_characters(characters: Array[Character]) -> void:
	active_characters = characters
	emit_signal("characters_updated", active_characters)


# --- Level Management ---

func set_level(level_name: String) -> void:
	if current_level_name != level_name:
		current_level_name = level_name
		emit_signal("level_changed", level_name)
		print("GameManager: Level changed to " + level_name)

# --- Save Slot Management ---

func set_save_slot(slot: int) -> void:
	if slot >= 0:
		current_save_slot = slot
		print("GameManager: Set save slot to " + str(slot + 1))

func get_current_save_slot() -> int:
	return current_save_slot