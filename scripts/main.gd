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
#endregion

#region Methods
## Unloads the current level instance
func unload_level() -> void:
	if is_instance_valid(level):
		level.queue_free(); # Free the current level instance
	level = null;


func next_level() -> void:
	current_level_index += 1;
	if current_level_index > levels.size():
		get_tree().change_scene_to_file("res://scenes/states/victory.tscn");
	else:
		load_level(levels[current_level_index]);

## Loads a new level and cleanup previously loaded level
##
## @param level_name: New level name to load
func load_level(level_name: String) -> void:
	if OS.has_feature("mobile"):
		Dialogic.VAR.PLATFORM = "MOBILE";
	else:
		Dialogic.VAR.PLATFORM = "DESKTOP";
	unload_level();
	#var level_path: String = "res://scenes/levels/%sLevel.tscn" % level_name;
	var level_path: String = "res://scenes/levels/%s.tscn" % level_name;
	level = load(level_path).instantiate();
	level.level_name = level_name; ## TODO: Remove? This does nothing?
	world.add_child(level) # Add the new level to the World node
	
	await get_tree().process_frame
	var ui := get_tree().get_first_node_in_group("ui_controller")
	if ui:
		ui._connect_to_level(level)

func load_level_by_name(level_name: String) -> void:
	current_level_name = level_name
	for path : String in levels:
		if path.get_file().get_basename() == level_name:
			load_level(level_name)
			return
	push_error("No level found matching name: " + level_name)

func load_next_level() -> void:
	# This splits "tutorial_1" into ["tutorial", "1"] from the right
	var parts := current_level_name.rsplit("_", true, 1)
	if parts.size() < 2 or not parts[1].is_valid_int():
		push_error("Cannot increment level name: " + current_level_name)
		return
		var next_name := parts[0] + "_" + str(parts[1].to_int() + 1)
		load_level_by_name(next_name)
#endregion
