extends Node
class_name SerializationService

# Constants for save file paths/keys
const SAVE_GAME_PATH := "user://noblenights_saves.tres";
const SAVE_FORMAT_KEY := "Noble Nights Save format";


## --- Save Logic ---

# Orchestrates saving the entire game state from the GameManager
func save_game_state(manager: GameManager) -> void:
	if not manager.get_current_save_slot() != -1:
		print("SerializationService: Error - Cannot save, no active save slot set.")
		return

	# 1. Get all units from the GameManager
	var units_to_save: Array[Dictionary] = []
	for character in manager.active_characters:
		units_to_save.append(character.save())

	# 2. Get the current level details
	var current_level_data: Dictionary = {
		"level": manager.current_level_name,
		"timestamp": Time.get_datetime_string_from_system(),
		"save_version": 2 # Incremented version number
	}

	# 3. Structure the entire save dictionary
	var saves: Dictionary = {}
	
	# Read existing saves first to preserve other slots
	var existing_saves: Dictionary = {}
	if FileAccess.file_exists(SAVE_GAME_PATH):
		var file := FileAccess.open(SAVE_GAME_PATH, FileAccess.READ)
		var json := JSON.new()
		var err = json.parse(file.get_as_text())
		file.close()
		
		if err == OK:
			existing_saves = json.data
		else:
			push_error("SerializationService: Failed to parse existing save file. Starting fresh.")

	# Copy over existing slots
	saves = existing_saves

	# 4. Overwrite/Create the specified slot
	var slot_key := "Slot " + str(manager.get_current_save_slot() + 1)
	saves[slot_key] = {
		"level": current_level_data["level"],
		"units": units_to_save
	}
	
	# 5. Write the combined dictionary to the file
	var save_file := FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE)
	if save_file:
		var json_string: String = JSON.stringify(saves)
		save_file.store_string(json_string)
		save_file.close()
		print("SerializationService: Successfully saved game to slot " + str(manager.get_current_save_slot() + 1))
	else:
		push_error("SerializationService: Could not open save file for writing.")


# Orchestrates loading the game state from a specific slot
func load_game_state(manager: GameManager, save_slot: int) -> Dictionary:
	if save_slot < 0:
		print("SerializationService: Error - Cannot load, invalid save slot provided.")
		return {}

	if not FileAccess.file_exists(SAVE_GAME_PATH):
		print("SerializationService: Warning - Save file does not exist.")
		return {}
	
	var file := FileAccess.open(SAVE_GAME_PATH, FileAccess.READ)
	if not file:
		push_error("SerializationService: Failed to open save file.")
		return {}

	var json := JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("SerializationService: JSON parsing failed. Error: " + str(err))
		return {}

	var save : Dictionary = json.data
	var slot_key := "Slot " + str(save_slot + 1)
	
	if not save.has(slot_key):
		print("SerializationService: Warning - Save slot " + str(save_slot + 1) + " does not exist.")
		return {}

	var slot : Dictionary = save[slot_key]
	
	var loaded_units_data: Array[Dictionary] = slot.get("units", [])
	var loaded_level_name: String = slot.get("level", "")

	return {
		"level": loaded_level_name,
		"units_data": loaded_units_data
	}


# --- Utility ---

func clear_all_save_data() -> void:
	if FileAccess.file_exists(SAVE_GAME_PATH):
		DirAccess.remove_absolute(SAVE_GAME_PATH)
		print("SerializationService: All save data cleared successfully.")