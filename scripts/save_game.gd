class_name SaveGame
extends Resource

const SAVE_GAME_PATH := "user://noblenights_saves.tres";

## Use this to detect old player save files and update them 
@export var version := 1;

@export var map_name := "";


func create_new_save_data() -> void:
	var save_file: Object = FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE);
	
	var saves: Array[String];
	
	saves.append("Slot 0");
	saves.append("Slot 1");
	saves.append("Slot 2");
	
	var json_string: String = JSON.stringify(saves);
	
	save_file.store_string(json_string);
	
	save_file.close();
	

func write(save_slot :int) -> void:
	var save_file: Object = FileAccess.open(SAVE_GAME_PATH, FileAccess.WRITE)
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
	while save_file.get_position() < save_file.get_length():
		var json_string: String = save_file.get_line();

		# Creates the helper class to interact with JSON.
		var json: JSON = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		var parse_result: Error = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object.
		var node_data: Variant = json.data;

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
