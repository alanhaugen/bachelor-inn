extends Resource
class_name SaveGame

const SAVE_GAME_PATH := "user://noblenights_saves.tres";


## Use this to detect old player save files and update them 
@export var version := 1;
@export var map_name := "first";
var registry: CharacterRegistry = load("res://scripts/Characters/CharacterRegistry.tres")



func is_savefile_existing() -> bool:
	return FileAccess.file_exists(SAVE_GAME_PATH);


func create_new_from_state(slot:int, level: int, state: GameState) -> void:
	var units: Array[Character]
	
	for unit in state.units:
		units.append(unit.save())
	
	# TODO: Save into correct slot
	# TODO: Make sure it does not overwrite other files
	var _save := {
		"level": level,
		"units": units
	}
	
	# TODO: Save to file
	#var json_string: String = JSON.stringify(saves);
	#save_file.store_string(json_string);
	#save_file.close();


func create_new_save_data() -> void:
	var save_file: Object = FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE);
	
	var units := []
	
	for id: String in registry.characters.keys():
		var def: CharacterDefinition = registry.characters[id]
		
		var char := Character.new()
		char.data = def.base_data.duplicate()
		char.state = def.base_state.duplicate()
		char.scene_id = id
		
		units.append(char.save())
	
	
	var saves := {
		"Noble Nights Save format": version,
		"Slot 1":
		{
			"level": 3,
			"units": units
		},
		"Slot 2":
		{
			"level": 4,
			"units": units
		},
		"Slot 3":
		{
			"level": 5,
			"units": units
		},
	}
	
	var json_string: String = JSON.stringify(saves);
	save_file.store_string(json_string);
	save_file.close();

func create_new_save_in_slot(save_slot: int) -> void:
	# Read existing saves first
	var saves := {}
	if FileAccess.file_exists(SAVE_GAME_PATH):
		var file := FileAccess.open(SAVE_GAME_PATH, FileAccess.READ)
		var json := JSON.new()
		json.parse(file.get_as_text())
		file.close()
		saves = json.data

	# Build fresh units
	var units := []
	for id: String in registry.characters.keys():
		var def: CharacterDefinition = registry.characters[id]
		var char := Character.new()
		char.data = def.base_data.duplicate()
		char.state = def.base_state.duplicate()
		char.scene_id = id
		units.append(char.save())

	# Only overwrite the selected slot
	saves["Noble Nights Save format"] = version
	saves["Slot " + str(save_slot + 1)] = {"level": 3, "units": units}
	var save_file := FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(saves))
	save_file.close()


func write(_save_slot: int) -> void:
	var save_file: Object = FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE)
	
	if !is_instance_valid(Main.level):
		push_error("Main level does not exist");
		return;
	
	var moves: Array[Move] = Main.level.moves;
	for move: Move in moves:
		# Check the node has a save function.
		if !move.has_method("save"):
			print("node '%s' is missing a save() function, skipped" % move.name)
			continue

		# Call the node's save function.
		var move_data: String = move.call("save")

		# Store the save dictionary as a new line in the save file.
		save_file.store_line(JSON.stringify(move_data));
	save_file.close();


func read(save_slot: int) -> bool:
	if not FileAccess.file_exists(SAVE_GAME_PATH):
		return false

	Main.current_save_slot = save_slot
	
	var file := FileAccess.open(SAVE_GAME_PATH, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		push_error("JSON parse error")
		return false

	var save : Dictionary = json.data

	var slot_key := "Slot " + str(save_slot + 1)
	if not save.has(slot_key):
		return false

	var slot : Dictionary = save[slot_key]

	if not slot.has("level") or not slot.has("units"):
		return false

	var level : int = slot["level"]
	var units : Array = slot["units"]

	Main.characters.clear()

	for unit_dict : Dictionary in units:
		
		var scene_id : String = unit_dict.get("scene")
		var def: CharacterDefinition = registry.characters.get(scene_id)
		if def == null:
			push_error("Unknown character scene_id: " + scene_id)
			continue
		var packed_scene: PackedScene = def.scene
		
		var character := packed_scene.instantiate();

		# --- DATA ---
		var data := CharacterData.new()
		var data_dict : Dictionary = unit_dict["data"]

		data.unit_name = data_dict["unit_name"]
		data.speciality = data_dict["speciality"]
		data.personality = data_dict["personality"]
		data.strength = data_dict["strength"]
		data.mind = data_dict["mind"]
		data.speed = data_dict["speed"]
		data.focus = data_dict["focus"]
		data.endurance = data_dict["endurance"]


		# --- STATE ---
		var state := CharacterState.new()
		var state_dict : Dictionary = unit_dict["state"]

		var gp : Array = state_dict["grid_position"]
		state.grid_position = Vector3i(gp[0], gp[1], gp[2])

		state.faction = state_dict["faction"]
		state.experience = state_dict["experience"]
		state.level = state_dict["level"]
		state.current_health = state_dict["current_health"]
		state.current_sanity = state_dict["current_sanity"]
		state.weapon = WeaponRegistry.get_weapon(state_dict["weapon_id"])
		state.skills.clear()
		var ids: Array = state_dict.get("skill_ids", [])
		for id_any: String in ids:
			var id: String = str(id_any)
			var s: Skill = SkillRegistry.get_skill(id)
			if s != null:
				state.skills.append(s)
		
		character.data = data
		character.state = state
		
		#print("DEBUG LOADED unit:", data.unit_name, " skills:", state.skills.size(), " ids:", state_dict.get("skill_ids", []))
		#print("LOADED ", data.unit_name, " skill_ids=", state_dict.get("skill_ids", []))
		#print("RESOLVED ", data.unit_name, " skills=", state.skills.map(func(s: Skill) -> String: return s.skill_id if s else "NULL"))
		
		Main.characters.append(character)
	var level_name : String = Main.levels[level].get_file().get_basename()
	Main.load_level(level_name)
	return true


func load_tutorial() -> void:
	print("load_tutorial() pressed.")
	Main.characters.clear()
	
	for id: String in registry.characters.keys():
		var chardef : CharacterDefinition = registry.characters[id]
		if chardef == null:
			continue
		var character := chardef.scene.instantiate()
		character.data = chardef.base_data.duplicate()
		character.state = chardef.base_state.duplicate()
		
		Main.characters.append(character)
	
	#Main.current_level_name = "tutorial_1"
	#Main.load_level("tutorial_1")
	Main.current_level_name = "tutorialDesignedLevel"
	Main.load_level("tutorialDesignedLevel")


func save_progress(save_slot: int, level_index: int) -> void:
	var file := FileAccess.open(SAVE_GAME_PATH, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_string) != OK:
		push_error("JSON parse error on save")
		return
	
	var saves: Dictionary = json.data
	var slot_key := "Slot" + str(save_slot +1)
	var units := []
	for char in Main.characters:
		if char == null:
			continue
		units.append(char.save())
		
	saves[slot_key] = {"level": level_index, "units": units}
	
	var save_file := FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(saves))
	save_file.close()


func slot_has_data(save_slot: int) -> bool:
	if not FileAccess.file_exists(SAVE_GAME_PATH):
		return false
	var file := FileAccess.open(SAVE_GAME_PATH, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_string) != OK:
		return false
	var save: Dictionary = json.data
	var slot_key := "Slot " + str(save_slot + 1)
	return save.has(slot_key) and save[slot_key].get("units", []).size() > 0
