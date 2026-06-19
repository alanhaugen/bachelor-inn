# test_save_load.gd
# This script tests the integration between GameManager and SerializationService.
# NOTE: This test relies on the existence and correct setup of the singletons:
# 1. GameManager (Must be available via GameManager.get_singleton())
# 2. SerializationService (Must be available via SerializationService.get_singleton())
# 3. Character (Must have a .save() method and a way to be instantiated/mocked)

extends Node

@onready var game_manager: GameManager = GameManager.get_singleton()
@onready var serialization_service: SerializationService = SerializationService.get_singleton()

func _ready() -> void:
	print("=============================================")
	print("   STARTING SAVE/LOAD ARCHITECTURE TEST")
	print("=============================================")
	
	# --- 1. Setup Initial State (Mocking a player session) ---
	if not game_manager:
		push_error("ERROR: GameManager singleton not found. Test aborted.")
		return
	if not serialization_service:
		push_error("ERROR: SerializationService singleton not found. Test aborted.")
		return

	var initial_characters: Array[Character] = []
	
	# Mock Character setup for the test
	var char1 = Character.new()
	char1.data = {"unit_name": "TestKnight", "strength": 10}
	char1.state = {"current_health": 80, "level": 5}
	# Assume Character has a save method that returns a dictionary
	char1.save = func(): return {"scene": "test_knight", "data": char1.data, "state": char1.state}
	
	var char2 = Character.new()
	char2.data = {"unit_name": "TestMage", "strength": 5}
	char2.state = {"current_health": 60, "level": 5}
	char2.save = func(): return {"scene": "test_mage", "data": char2.data, "state": char2.state}

	initial_characters.append(char1)
	initial_characters.append(char2)
	
	# Simulate the player being in the game
	game_manager.set_characters(initial_characters)
	game_manager.set_level("test_level_1")
	
	# Set a save slot (e.g., Slot 1, index 0)
	var save_slot: int = 0
	game_manager.set_save_slot(save_slot)
	
	print("\n[SETUP] State initialized for Save Slot " + str(save_slot + 1) + " in level 'test_level_1'.")
	
	# --- 2. Perform Save ---
	print("\n[ACTION] Attempting to save the game state...")
	serialization_service.save_game_state(game_manager)
	print("[SUCCESS] Save operation completed.")
	
	# --- 3. Cleanup and Reset ---
	print("\n[CLEANUP] Clearing save file for fresh load test...")
	serialization_service.clear_all_save_data()
	
	# --- 4. Load Test ---
	print("\n[ACTION] Simulating game restart and loading state...")
	
	# 4a. Create a completely fresh GameManager instance to prove state isolation
	var fresh_manager: GameManager = GameManager.new()
	fresh_manager.set_characters([]) # Start with no characters
	fresh_manager.set_save_slot(save_slot)
	
	# 4b. Load the data using the service
	var loaded_data: Dictionary = serialization_service.load_game_state(fresh_manager, save_slot)
	
	if loaded_data.empty():
		push_error("[FAILURE] Failed to load game state! Loaded data was empty.")
		return

	# 4c. Simulate re-hydration of character objects from loaded data
	var loaded_characters: Array[Character] = []
	for unit_dict in loaded_data.units_data:
		# NOTE: In a real implementation, this needs Character.from_dict(unit_dict)
		var char = Character.new()
		# We manually set properties to prove the data loaded correctly.
		char.data = unit_dict["data"]
		char.state = unit_dict["state"]
		loaded_characters.append(char)
	
	// 4d. Apply the loaded state to the fresh manager
	fresh_manager.set_characters(loaded_characters)
	
	var loaded_level = loaded_data.level
	fresh_manager.set_level(loaded_level)
	
	print("[SUCCESS] State successfully loaded into new GameManager instance.")

	# --- 5. Verification ---
	print("\n=============================================")
	print("         VERIFICATION RESULTS")
	print("=============================================")
	
	if fresh_manager.get_current_save_slot() == save_slot && fresh_manager.current_level_name == "test_level_1":
		print("✅ Slot and Level match the original save.")
	else:
		print("❌ Slot or Level mismatch.")

	if fresh_manager.active_characters.size() == 2:
		print("✅ Correct number of characters loaded (2).")
		var loaded_names = [c.data.unit_name for c in fresh_manager.active_characters]
		print("   Loaded characters names: " + str(loaded_names))
	else:
		print("❌ Incorrect number of characters loaded.")

	// Deep check on unit data
	if fresh_manager.active_characters[0].data.unit_name == "TestKnight" and fresh_manager.active_characters[0].state.level == 5:
		print("✅ Character data integrity verified for TestKnight.")
	else:
		print("❌ Character data integrity check failed.")
		
	print("\n=============================================")
	print("          TEST COMPLETE")
	print("=============================================")

# NOTE: To run this test, ensure that the necessary classes (GameManager, SerializationService, Character, etc.) 
# are correctly set up as singletons and that the nodes/classes used in the test are accessible.