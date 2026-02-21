extends Node
## Main script.
##
## Controls what scene and ui is loaded.
## Loads settings and saves for the game.

# TODO:
# load settings

#region Props
## Current level running
var campaign : CampaignState

## Reference to the World node
var world: Node3D

## All levels
var levels: Array[String]

## Interface to operate camera
var camera_controller: CameraController

## Save file
@onready var save: SaveGame = SaveGame.new()
#endregion

#region Methods
## Loads a new level and cleanup previously loaded level
##
## @param level_name: New level name to load
func load_level(level_name: String) -> void:
	if OS.has_feature("mobile"):
		Dialogic.VAR.PLATFORM = "MOBILE"
	else:
		Dialogic.VAR.PLATFORM = "DESKTOP"
	var level_path: String = "res://scenes/levels/%sLevel.tscn" % level_name
	var level : Level = load(level_path).instantiate()
	level.level_name = level_name
	world.add_child(level) # Add the new level to the World node
#endregion
