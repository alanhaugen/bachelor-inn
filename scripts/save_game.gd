extends Resource
class_name SaveGame

const SAVE_GAME_PATH := "user://noblenights_saves.tres";

## Use this to detect old player save files and update them 
@export var version := 1;
@export var map_name := "first";


func is_savefile_existing() -> bool:
	return FileAccess.file_exists(SAVE_GAME_PATH);


func create_new_save_data() -> void:
	var save_file: Object = FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE);
	
	#var first: Character = Character.new();
	#first.unit_name = "Alfred";
	#first.speciality = Character.Speciality.Scholar;
	#first.movement = 3;
	#first.strength = 1;
	#first.ensure_weapon_equipped(); #adds weapon based on char speciality
	
	#print("SAVE CREATED: ", first.unit_name,
	#", weapon = ", first.weapon.weapon_name,
	#", id = ", first.weapon.weapon_id)
	
	#var w := WeaponRegistry.get_weapon("sword_basic")
	#print("LOOKUP sword_basic: ", w.weapon_name, ", ID: ", w.weapon_id, ", Damage: ", w.damage_modifier)
		
	#var second: Character = Character.new();
	#second.unit_name = "Lucy";
	#second.speciality = Character.Speciality.Militia;
	#second.strength = 10;
	#second.weapon = WeaponRegistry.get_weapon("sword_basic")
		
	#print("SAVE CREATED:", second.unit_name,
	#"weapon=", second.weapon.weapon_name,
	#"id=", second.weapon.weapon_id)
	
	var data1 := CharacterData.new()
	data1.unit_name = "Alfred"
	data1.speciality = CharacterData.Speciality.Runner
	data1.mind = 6
	data1.focus = 5
	data1.speed = 7

	var state1 := CharacterState.new()

	var char1 := Character.new()
	char1.data = data1
	char1.state = state1
	char1.init_current_stats_full() ## make loop for these?
	char1.ensure_weapon_equipped(); ## weapon
	
	var data2 := CharacterData.new()
	data2.unit_name = "Lucy"
	data2.speciality = CharacterData.Speciality.Militia
	data2.strength = 10

	var state2 := CharacterState.new()

	var char2 := Character.new()
	char2.data = data2
	char2.state = state2
	char2.init_current_stats_full()	
	char2.ensure_weapon_equipped(); #weapon
	
	var units: Array[Dictionary] = [char1.save(), char2.save()];
	
	var saves := {
		"Noble Nights Save format": version,
		"Slot 1":
		{
			"level": 0,
			"units": units
		},
		"Slot 2":
		{
			"level": 1,
			"units": units
		},
		"Slot 3":
		{
			"level": 2,
			"units": units
		},
	}
	
	var json_string: String = JSON.stringify(saves);
	
	save_file.store_string(json_string);
	
	save_file.close();


func write(_save_slot: int) -> void:
	var save_file: Object = FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE)
	
	if not is_instance_valid(Main.level):
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

		# JSON provides a static method to serialized JSON string.
		var json_string: String = JSON.stringify(move_data);

		# Store the save dictionary as a new line in the save file.
		save_file.store_line(json_string);
	save_file.close();


func read(save_slot: int) -> bool:
	if not FileAccess.file_exists(SAVE_GAME_PATH):
		return false

	var file := FileAccess.open(SAVE_GAME_PATH, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		push_error("JSON parse error")
		return false
	
	# Get the data from the JSON object.
	var save : Dictionary = json.data
	
	var slot_key := "Slot " + str(save_slot + 1);
	if not save.has(slot_key):
		push_error("Save file missing " + slot_key)
		return false;
		
	var save_slot_data: Dictionary = save[slot_key];
	var level : int = int(save_slot_data.get("level", 0));
	var characters : Array = save_slot_data.get("units", []);
	#var save_slot_data: Dictionary = save.get_or_add("Slot " + str(save_slot + 1));
	#var level: int = save_slot_data.get_or_add("level");
	#var characters: Array = save_slot_data.get("units");
	
	Main.characters.clear();
	
	print(characters);
	
	#for i in range(characters.size()):
		#var new_character: Character = Character.new();
		#new_character.unit_name = characters[i].get("Unit name");
		#new_character.strength = characters[i].get("Strength");
		#new_character.speed = characters[i].get("Speed");
		#new_character.speciality = characters[i].get("Speciality");
		#new_character.skill = characters[i].get("Skill");
		#new_character.resistence = characters[i].get("Resistence");
		#ew_character.movement = characters[i].get("Movement");
		#new_character.mind = characters[i].get("Mind");
		#new_character.mana = characters[i].get("Mana");
		#new_character.luck = characters[i].get("Luck");
		#new_character.is_playable = characters[i].get("Is Playable");
		#new_character.intimidation = characters[i].get("Intimidation");
		#new_character.health = characters[i].get("Health");
		#new_character.focus = characters[i].get("Focus");
		#new_character.experience = characters[i].get("Experience");
		#new_character.endurance = characters[i].get("Endurance");
		#new_character.defense = characters[i].get("Defense");
		#new_character.current_sanity = characters[i].get("Current sanity");
		#new_character.current_mana = characters[i].get("Current mana");
		#new_character.current_health = characters[i].get("Current health");
		#new_character.agility = characters[i].get("Agility");
		
		# default weapon first
		#new_character.ensure_weapon_equipped()

		# override if save had weapon
		#var wep_id := str(new_character.get("Weapon ID"))
		#if wep_id != "":
			#new_character.weapon = WeaponRegistry.get_weapon(wep_id)

				
		#Main.characters.append(new_character);
	
	#Main.load_level(Main.levels[level]);
	
	#var unit: Character = Character.new();
	#unit.name = "Withburn";
	#unit.speciality = Character.Speciality.Support;
	#unit.sprite;
	
	#Main.characters.append(unit);
	#var slot_key := "Slot " + str(save_slot + 1)
	#if not save.has(slot_key):
		#return false

	var slot : Dictionary = save[slot_key]

	if not slot.has("level") or not slot.has("units"):
		return false

	#var level : int = slot["level"]
	var units : Array = slot["units"]

	Main.characters.clear()

	for unit_dict : Dictionary in units:
		var character := Character.new()

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
		# weapon
		var wid := ""
		if state_dict.has("weapon_id"):
			wid = str(state_dict["weapon_id"])
		elif state_dict.has("Weapon ID"): # failsafe for old system
			wid = str(state_dict["Weapon ID"])
		elif state_dict.has("Weapon_ID"): # failsafe for old system
			wid = str(state_dict["Weapon_ID"])

		state.weapon_id = wid
		
		# default weapon first
		#new_character.ensure_weapon_equipped()

		# override if save had weapon
		#var wep_id := str(new_character.get("Weapon ID"))
		#if wep_id != "":
			#new_character.weapon = WeaponRegistry.get_weapon(wep_id)

		character.data = data
		character.state = state

		character.recalc_derived_stats()
		character.ensure_weapon_equipped()

		Main.characters.append(character)

	Main.load_level(Main.levels[level])
	return true
