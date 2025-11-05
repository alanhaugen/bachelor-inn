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

## Save file
@onready var save: SaveGame = SaveGame.new();
#endregion

#region: --- Methods ---
## Unloads the current level instance
func unload_level() -> void:
	if is_instance_valid(level):
		level.queue_free(); # Free the current level instance
	level = null

## Loads a new level and cleanup previously loaded level
##
## @param level_name: New level name to load
func load_level(level_name: String) -> void:
	unload_level();
	var level_path: String = "res://scenes/levels/%sLevel.tscn" % level_name;
	level = load(level_path).instantiate();
	world.add_child(level) # Add the new level to the World node
#endregion
