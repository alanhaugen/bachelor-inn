extends Node
## Main script.
##
## Controls what scene and ui is loaded.
## Loads settings and saves for the game.

# TODO:
# load settings
# load units
# load games

#region: --- Props ---
## Current level running
var level: Level;

## Reference to the World node
var world: Node3D;

## Reference to the GUI
var gui: Control;

## Character Units held by the gaming session 
var characters: Array[Character];

## All levels
var levels: Array[String];

## Level index into levels array
var current_level_index: int = 0;

## Level index into levels array
var battle_log: Label;

## Global UI Scale
var ui_scale: float = 2.4;

## Save file
@onready var save: SaveGame = SaveGame.new();
#endregion

#region: --- Methods ---
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
	unload_level();
	var level_path: String = "res://scenes/levels/%sLevel.tscn" % level_name;
	level = load(level_path).instantiate();
	level.level_name = level_name;
	world.add_child(level) # Add the new level to the World node
#endregion
