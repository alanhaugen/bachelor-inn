extends Node
## Main script.
##
## Controls what scene and ui is loaded.
## Loads settings and saves for the game.

# TODO:
# load settings

#region Props
## Current campaign state
var campaign: CampaignState = CampaignState.new()

## Current level node (running in world)
var level: Level

## Reference to the World node
var world: Node3D

## All levels sequencing
var levels: Array[String]

## Interface to operate camera
var camera_controller: CameraController

## Save file
@onready var save: SaveGame = SaveGame.new()
#endregion

#region Shorthands (for compatibility)
var characters: Array[Character]:
	get: return campaign.characters
	set(v): campaign.characters = v

var current_level_index: int:
	get: return campaign.current_level_index
	set(v): campaign.current_level_index = v

var battle_log: Label:
	get: return level.battle_log if level else null
#endregion

#region Methods
func next_level() -> void:
	campaign.current_level_index += 1
	if campaign.current_level_index >= levels.size():
		get_tree().change_scene_to_file("res://scenes/states/victory.tscn")
	else:
		load_level(levels[campaign.current_level_index])

## Loads a new level and cleanup previously loaded level
##
## @param level_name: New level name to load
func load_level(level_name: String) -> void:
	if OS.has_feature("mobile"):
		Dialogic.VAR.PLATFORM = "MOBILE"
	else:
		Dialogic.VAR.PLATFORM = "DESKTOP"
	
	if is_instance_valid(level):
		level.queue_free()
	
	var level_path: String = "res://scenes/levels/%sLevel.tscn" % level_name
	var level_scene := load(level_path)
	if level_scene:
		level = level_scene.instantiate()
		level.level_name = level_name
		campaign.level_name = level_name
		world.add_child(level)
		
		await get_tree().process_frame
		var ui := get_tree().get_first_node_in_group("ui_controller")
		if ui:
			ui._connect_to_level(level)
#endregion
