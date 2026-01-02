class_name SaveGame
extends Resource

const SAVE_GAME_PATH := "user://noblenights_saves.tres";

## Use this to detect old player save files and update them 
@export var version := 1;
@export var map_name := "first";


func is_savefile_existing() -> bool:
	return FileAccess.file_exists(SAVE_GAME_PATH);


func create_new_save_data() -> void:
	var save_file: Object = FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE);
	
	var first: Character = Character.new();
	first.unit_name = "Alfred";
	first.speciality = Character.Speciality.Scholar;
	first.movement = 3;
	first.strength = 1;
	
	var second: Character = Character.new();
	second.unit_name = "Lucy";
	second.speciality = Character.Speciality.Militia;
	second.strength = 10;
	
	var units: Array[Dictionary] = [first.save(), second.save()];
	
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
	
	if is_instance_valid(Main.level):
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
		return false; # Error! We don't have a save to load.

	var save_file: Object = FileAccess.open(SAVE_GAME_PATH, FileAccess.READ);
	var json_string: String = save_file.get_as_text();

	# Creates the helper class to interact with JSON.
	var json: JSON = JSON.new()

	# Check if there is any error while parsing the JSON string, skip in case of failure.
	var parse_result: Error = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return false;

	# Get the data from the JSON object.
	var save: Dictionary = json.data;
	
	var save_slot_data: Dictionary = save.get_or_add("Slot " + str(save_slot + 1));
	
	var level: int = save_slot_data.get_or_add("level");
	
	var characters: Array = save_slot_data.get("units");
	
	Main.characters.clear();
	
	print(characters);
	
	for i in range(characters.size()):
		var new_character: Character = Character.new();
		new_character.unit_name = characters[i].get("Unit name");
		new_character.strength = characters[i].get("Strength");
		new_character.speed = characters[i].get("Speed");
		new_character.speciality = characters[i].get("Speciality");
		new_character.skill = characters[i].get("Skill");
		new_character.resistence = characters[i].get("Resistence");
		new_character.movement = characters[i].get("Movement");
		new_character.mind = characters[i].get("Mind");
		new_character.mana = characters[i].get("Mana");
		new_character.luck = characters[i].get("Luck");
		new_character.is_playable = characters[i].get("Is Playable");
		new_character.intimidation = characters[i].get("Intimidation");
		new_character.health = characters[i].get("Health");
		new_character.focus = characters[i].get("Focus");
		new_character.experience = characters[i].get("Experience");
		new_character.endurance = characters[i].get("Endurance");
		new_character.defense = characters[i].get("Defense");
		new_character.current_sanity = characters[i].get("Current sanity");
		new_character.current_mana = characters[i].get("Current mana");
		new_character.current_health = characters[i].get("Current health");
		#new_character.agility = characters[i].get("Agility");
		
		Main.characters.append(new_character);
	
	Main.load_level(Main.levels[level]);
	
	#var unit: Character = Character.new();
	#unit.name = "Withburn";
	#unit.speciality = Character.Speciality.Support;
	#unit.sprite;
	
	#Main.characters.append(unit);

	# Firstly, we need to create the object and add it to the tree and set its position.
	#var new_object = load(node_data["filename"]).instantiate()
	#get_node(node_data["parent"]).add_child(new_object)
	#new_object.position = Vector2(node_data["pos_x"], node_data["pos_y"])

	# Now we set the remaining variables.
	#for i in node_data.keys():
	#	if i == "filename" or i == "parent" or i == "pos_x" or i == "pos_y":
	#		continue
	#	new_object.set(i, node_data[i])
	return true;
