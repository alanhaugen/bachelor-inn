extends Node

# TODO:
# load settings
# load units
# load games

#region: --- Props ---
## Current level running
var level : Map;

## Reference to the World node
@onready var world : Node3D = $World;

## Reference to the GUI
@onready var gui : Control = $UI;
@onready var levelButton : Button = $UI/MapSelector/LoadMap0;
#endregion

#region: --- Processing ---
## Called when the node enters the scene tree for the first time
func _ready() -> void:
	levelButton.grab_focus(); # Set focus on a button
#endregion

#region: --- Signals ---
## Called when the Load Map 0 button is pressed
func _on_load_map_0_pressed() -> void:
	load_level("first"); # Load the test level
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
	$UI/MapSelector.visible = false # Hide the map selector UI
#endregion
