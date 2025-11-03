class_name SaveGame
extends Resource

const SAVE_GAME_PATH := "user://noblenights_saves.tres";

## Use this to detect old player save files and update them 
@export var version := 1;

@export var map_name := "";


func create_new_save_data() -> void:
	var save_file: Object = FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE);
	
	var units := {
		"Withburn, the Cleric": 
		{
			"name": "Withburn",
			"speciality": "Magican",
			"unit_type": "Playble",
			"texture referance": "res://art/WithburnSpriteSheet",
			"stats": 
				{
					"hp": 15, 
					"max_hp": 15,
					"strength": 5, 
					"magic": 10,
					"skill": 10, 
					"speed": 5,
					"defence": 8, 
					"resistance": 8,
					"movement": 5, 
					"luck": 5
				},
			"level_up_stats":
				{
					"max_hp": 2,
					"strenght": 1, 
					"magic": 3,
					"skill": 1, 
					"speed": 1,
					"defence": 1, 
					"resistance": 2,
					"movement": 0, 
					"luck": 1
				},
				
			"weapon": "Staff of the Generic",
			"level": 1,
			"experience": 0
		},
		"Fen, the Warrior": 
		{
			"name": "Fen",
			"speciality": "Fighter",
			"unit_type": "Playble",
			"texture referance": "res://art/FenSpriteSheet",
			"stats": 
				{
					"hp": 20, 
					"max_hp": 20,
					"strenght": 15, 
					"magic": 3,
					"skill": 10, 
					"speed": 7,
					"defence": 12, 
					"resistance": 4,
					"movement": 6, 
					"luck": 4
				},
			"level_up_stats":
				{
					"max_hp": 2,
					"strenght": 2, 
					"magic": 1,
					"skill": 1, 
					"speed": 1,
					"defence": 2, 
					"resistance": 1,
					"movement": 0, 
					"luck": 1
				},
				
			"weapon": "Sword of the Generic",
			"level": 1,
			"experience": 0
		},
		"bandit": 
		{
			"name": "bandi",
			"speciality": "Fighter",
			"unit_type": "Enemy",
			"texture referance": "res://art/BanditSpriteSheet",
			"stats": 
				{
					"hp": 10, "max_hp": 10,
					"strenght": 8, "magic": 1,
					"skill": 4, "speed": 4,
					"defence": 6, "resistance": 6,
					"movement": 5, "luck": 2
				},
			"level_up_stats":
				{
					"max_hp": 2,
					"strenght": 1, "magic": 3,
					"skill": 1, "speed": 1,
					"defence": 1, "resistance": 2,
					"movement": 0, "luck": 1
				},
				
			"weapon": "Club of the Generic",
			"level": 1,
			"experience": 0
		}
	}
	
	var saves := {
		"Noble Nights Save format": version,
		"Slot 1":
		{
			"level": "first",
			"units": units
		},
		"Slot 2":
		{
			"level": "first",
			"units": units
		},
		"Slot 3":
		{
			"level": "first",
			"units": units
		},
	}
	
	var json_string: String = JSON.stringify(saves);
	
	save_file.store_string(json_string);
	
	save_file.close();


func write(save_slot :int) -> void:
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
	
	print(save);

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
