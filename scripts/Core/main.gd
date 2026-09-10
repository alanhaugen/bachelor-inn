extends Node
## Main script.
##
## Controls what scene and ui is loaded.
## Loads settings and saves for the game.

# TODO:
# Should own World.tscn, main_menu.tscn, hub.tscn and level.tscn.
# load settings

#region Props
## Current level running
var level: Level;
var current_level_name: String = ""

## Reference to the World node
var world: Node3D;
const WORLD = preload("res://scenes/World/world.tscn")

## Character Units held by the gaming session 
var selected_starting_character: String = "alfred" ## Default as alfred, if something goes wrong. 
var full_roster: Array[String]
var active_party: Array[String]
var characters: Array[Character]

## All levels
var levels: Array[LevelEntry];

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
var is_standalone_test: bool = false

## UI
var flavor_screen: Control = null
var transition_screen: Control = null
#endregion

#region Methods
func _ready() -> void:
	var registry: LevelOrder = preload("res://Data/levels_for_grid_select.tres")
	#var registry: LevelOrder = preload("res://Data/level_order.tres")
	levels = registry.levels
	world = World
	camera_controller = world.get_node("CameraScene")
	
## Unloads the current level instance
func unload_level() -> void:
	if is_instance_valid(level):
		level.queue_free()
	level = null

func next_level() -> void:
	print("next_level() in main.gd triggered!")
	var next_index := current_level_index + 1
	if next_index >= levels.size():
		get_tree().change_scene_to_file("res://scenes/states/victory.tscn")
	else:
		load_level(next_index)

func load_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		push_error("Level index out or range: %d" % index)
		return
	current_level_index = index
	var entry: LevelEntry = levels[index]
	
	if OS.has_feature("mobile"):
		Dialogic.VAR.PLATFORM = "MOBILE";
	else:
		Dialogic.VAR.PLATFORM = "DESKTOP";
	
	unload_level()
	
	var packed := load(entry.scene_path)
	if packed == null:
		push_error("Failed to load level at path: " + entry.scene_path)
		return
	level = packed.instantiate()
	level.level_name = entry.display_name
	world.add_child(level)
	
	await get_tree().process_frame
	
	var ui := get_tree().get_first_node_in_group("ui_controller")
	if ui:
		ui._connect_to_level(level)
	
	show_flavor_screen()
	var menu := get_tree().get_first_node_in_group("main_menu")
	if is_instance_valid(menu):
		menu.queue_free()

func load_single_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		push_error("Level index out of range: %d" % index)
		return
	is_standalone_test = true
	
	 # Populate with default test party from registry
	Main.characters.clear()
	Main.full_roster = ["alfred", "emil", "lucy"]
	Main.active_party = ["alfred", "emil", "lucy"]
	var test_ids := ["alfred", "emil", "lucy"]  # or whatever your default party IDs are
	for id : String in test_ids:
		var chardef: CharacterDefinition = save.registry.characters.get(id, null)
		if chardef == null:
			push_error("No definition found for: " + id)
			continue
		var character := chardef.scene.instantiate()
		character.data = chardef.base_data.duplicate()
		character.state = chardef.base_state.duplicate()
		Main.characters.append(character)
	
	current_level_index = index
	Main.unload_level()
	
	var entry: LevelEntry = levels[index]
	var packed := load(entry.scene_path)
	if packed == null:
		push_error("Failed to load level: " + entry.scene_path)
		return
	
	level = packed.instantiate()
	level.level_name = entry.display_name
	world.add_child(level)
	
	await get_tree().process_frame
	is_standalone_test = false ## Reset flag after test scene is loaded
	
	var ui := get_tree().get_first_node_in_group("ui_controller")
	if ui:
		ui._connect_to_level(level)
	
	var menu := get_tree().get_first_node_in_group("main_menu")
	if is_instance_valid(menu):
		menu.queue_free()

func get_next_level_index() -> int:
	for i in levels.size():
		if levels[i].get_file().get_basename() == current_level_name:
			return i
	return 0

func go_to_level_by_index(index: int) -> void:
	if index < 0 or index >= levels.size():
		push_error("Level index out of range: %d" % index)
		return
	load_level(index)

func get_current_level_index() -> int:
	## Replaced by get_current_entry(). See below.
	for i in levels.size():
		if levels[i].get_file().get_basename() == current_level_name:
			return i
	return 0

func get_current_entry() -> LevelEntry:
	if current_level_index < 0 or current_level_index >= levels.size():
		return null
	return levels[current_level_index]

func go_to_transition_screen() -> void:
	print("go_to_transition_screen called")
	if is_instance_valid(Main.level):
		#Main.level.is_in_menu = true
		Main.level.state_machine.push(StateLevelComplete.new())
		print("Going to Transition Screen. Instance Main.level is valid.")
	var packed := load("res://scenes/states/level_transition.tscn")
	transition_screen = packed.instantiate()
	get_tree().root.add_child(transition_screen)

func show_flavor_screen() -> void:
	if not level_story_text.has(current_level_name):
		return  
	if is_instance_valid(level):
		level.is_in_menu = true
	var packed := load("res://scenes/userinterface/Menus/flavor_text_screen.tscn")
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
