extends Node
## Main script.
##
## Controls what scene and ui is loaded.
## Loads settings and saves for the game.

# TODO:
# load settings

#region Props
## Current level running
var level: Level;
var current_level_name: String = ""

## Reference to the World node
var world: Node3D;

## Character Units held by the gaming session 
var characters: Array[Character];

## All levels
var levels: Array[String];

## Level index into levels array
var current_level_index: int = 0;

## Level index into levels array
var battle_log: Label;

## Global UI Scale
var ui_scale: float = 1.0;#2.4;

## Interface to operate camera
var camera_controller: CameraController;

## Save file
@onready var save: SaveGame = SaveGame.new();
var current_save_slot: int = 0

## UI
var flavor_screen: Control = null
var transition_screen: Control = null
#endregion

#region Methods
## Unloads the current level instance
func unload_level() -> void:
	#if is_instance_valid(level):
		#level.cleanup_characters_before_load()
		#level.queue_free(); # Free the current level instance
	#level = null;
	if is_instance_valid(level):
		# Only remove enemies from world, leave player characters alone
		for child in world.get_children():
			if child is Character and child.state.is_enemy():
				world.remove_child(child)
				child.queue_free()
		level.queue_free()
	level = null

func next_level() -> void:
	print("current_level_name: '", current_level_name, "'")
	var current_index := -1
	for i in levels.size():
		var basename := levels[i].get_file().get_basename()
		print("levels[", i, "] raw: '", levels[i], "' basename: '", basename, "'")
		if levels[i].get_file().get_basename() == current_level_name:
			current_index = i
			break
	print("current_index: ", current_index)

	if current_index == -1:
		push_error("Current level not found: ", current_level_name)
		return
	
	var next_index := current_index + 1
	if next_index >= levels.size():
		get_tree().change_scene_to_file("res://scenes/states/victory.tscn")
	else:
		load_level_by_name(levels[next_index].get_file().get_basename())
#func next_level() -> void:
#	current_level_index += 1;
#	if current_level_index > levels.size():
#		get_tree().change_scene_to_file("res://scenes/states/victory.tscn");
#	else:
#		load_level(levels[current_level_index]);

## Loads a new level and cleanup previously loaded level
##
## @param level_name: New level name to load
func load_level(level_name: String) -> void:
	print("world valid: ", is_instance_valid(world))
	print("world: ", world)
	if OS.has_feature("mobile"):
		Dialogic.VAR.PLATFORM = "MOBILE";
	else:
		Dialogic.VAR.PLATFORM = "DESKTOP";
	unload_level(); ## TODO: Called too early?
	current_level_name = level_name
	current_level_index = levels.find_custom(func(p: String) -> bool: return p.get_file().get_basename() == level_name)
	#var level_path: String = "res://scenes/levels/%sLevel.tscn" % level_name;
	var level_path: String = "res://scenes/levels/%s.tscn" % level_name;
	print("Attempting to load level path: '", level_path, "'")
	var packed := load(level_path)
	if packed == null:
		push_error("Failed to load level at path: " + level_path)
		return
	level = packed.instantiate()
	#level = load(level_path).instantiate();
	level.level_name = level_name;	
	world.add_child(level) # Add the new level to the World node
	
	await get_tree().process_frame
	#SaveGame.new().save_progress(current_save_slot, current_level_index)
	var ui := get_tree().get_first_node_in_group("ui_controller")
	if ui:
		ui._connect_to_level(level)
	Main.show_flavor_screen()


func load_level_by_name(level_name: String) -> void:
	#current_level_name = level_name
	for path : String in levels:
		if path.get_file().get_basename() == level_name:
			load_level(level_name)
			return
	push_error("No level found matching name: " + level_name)


## Not in use atm
func load_next_level() -> void:
	# This splits "tutorial_1" into ["tutorial", "1"] from the right
	var parts := current_level_name.rsplit("_", true, 1)
	if parts.size() < 2 or not parts[1].is_valid_int():
		push_error("Cannot increment level name: " + current_level_name)
		return
	var next_name := parts[0] + "_" + str(parts[1].to_int() + 1)
	load_level_by_name(next_name)


func get_next_level_index() -> int:
	for i in levels.size():
		if levels[i].get_file().get_basename() == current_level_name:
			return i
	return 0


func get_current_level_index() -> int:
	for i in levels.size():
		if levels[i].get_file().get_basename() == current_level_name:
			return i
	return 0


func go_to_transition_screen() -> void:
	if is_instance_valid(Main.level):
		Main.level.is_in_menu = true
	var packed := load("res://scenes/states/level_transition.tscn")
	transition_screen = packed.instantiate()
	get_tree().root.add_child(transition_screen)

func show_flavor_screen() -> void:
	if not level_story_text.has(current_level_name):
		return  
	if is_instance_valid(level):
		level.is_in_menu = true
	var packed := load("res://scenes/userinterface/flavor_text_screen.tscn")
	flavor_screen = packed.instantiate()
	get_tree().root.add_child(flavor_screen)

#endregion

var level_display_names: Dictionary = {
	"tutorialDesignedLevel": "The Escape  :  ",
	"tutorial_2": "Ruins  :  ",
	"tutorial_3": "The Camp  :  ",
	"fen": "The Fen  :  ",
	"fento": "Keep Fen  :  ",
	"waterfallLevel": "The Waterfall  :  ",
	"woodlandsLevel": "The Woodlands  :  "
}

var level_flavor_texts: Dictionary = {
	"tutorialDesignedLevel": "You tumble down the hillside...",
	"tutorial_2": "Ancient ruins hide forgotten secrets.",
	"tutorial_3": "The aid of those of kindled spirit.",
	"fen": "The sound of chasing footsteps..",
	"fento": "They keep coming.",
	"waterfallLevel": "The sound of rushing water fills the air.",
	"woodlandsLevel": "The trees whisper of things soon forgotten."
}

var level_story_text : Dictionary = {
	"tutorialDesignedLevel": 
	"\nAn evil force has swept across the world.\n
	The majority of folks have been taken and turned, but there are a few who still remain human.\n
	You lived quietly for so long, but alas one of those.. things.. found your hideout.\n 
	The only thing to do is to flee.\n\n\n",
	"tutorial_2":
	"\nYou find yourself inside a smal, but sturdy set of ruins.\n 
	The thing that was chasing you has stopped.. For now.\n 
	The ruins are damp, and a faint draft causes a small torch to flicker on the far side.\n 
	A lit torch? Could someone have been here recently?\n\n
	.. you hear something\n\n\n",
	"tutorial_3":
	"\nThe faint sound of a voice draws your attention.\n
	You stumble upon a makeshift camp outside a worn stable.\n
	Two shadows make out a silhuette before a flickering bonfire.\n\n\n",
	"fento": 
	"\nFeral screams pierce the night. Several monsters, no doubt.\n
	You rush out as fast as you can. Lucy and Emil are already on their feet.\n
	You draw your weapon.\n\n\n",
	"fen":
	"\nPast the river, to the east, your party is embraced by a shining light.\n
	Behind you - more monsters.\n\n\n",
	"waterfallLevel":
	"\nH20\n\n\n",
	"woodlandsLevel":
	"\nHowMuchWoodWouldAWoodchuckChuckIfAWoodchuckCouldChuckWood?\n\n\n"
}
