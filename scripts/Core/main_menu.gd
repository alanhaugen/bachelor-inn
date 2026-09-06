extends Node3D

## Reference to the World node
## Doing this in main.gd
#@onready var world: Node3D = $World;

## Reference to the GUI
@onready var gui: Control = $UI;

## Level buttons
#@onready var levelButton: Button = $UI/LevelSelect/LevelSelectVBOX/LoadMap0;
@onready var start_game_button: Button = $UI/MainMenu/Selector/StartGameButton

## Names of levels in the order they will be played
@export var levels_order: LevelOrder
const REGISTRY_PATH := "res://Data/levels_for_grid_select.tres"
var _registry: LevelOrder = preload(REGISTRY_PATH)
var current_level_index: int = -1
@onready var grid_container: GridContainer = $UI/SelectLevelGrid/VBoxContainer/GridContainer

#@onready var camera_controller: CameraController = $World/CameraScene

## Bools
var _slot_pending_overwrite: int = -1

#region --- Processing ---
## Called when the node enters the scene tree for the first time
func _ready() -> void:
	print(OS.get_data_dir())
	add_to_group("main_menu")
	
	#Main.world = world;
	#Main.levels = levels_order.levels; <-- Done in main.gd _ready()
	#Main.camera_controller = camera_controller;
	
	#$UI/LevelSelect.visible = false;
	_fill_grid_with_levels()
	
	print(OS.get_data_dir());
	
	var success : bool = Main.save.is_savefile_existing();
	## TODO: Check if save file-system is ready
	#success = false; # Let's make a new save each time until the save format is stable
	
	if success:
		print("Save file exists, loading");
	else:
		print("No save file found. Creating new save");
		Main.save.create_new_save_data();
	
	# Set focus on the first button
	start_game_button.grab_focus();
#endregion

#region --- Signals ---

## MAIN MENU
func _on_start_game_button_pressed() -> void:
	$UI/LevelSelect.visible = true;
	$UI/MainMenu.visible = false;


func _on_options_button_pressed() -> void:
	$UI/MainMenu.visible = false;
	$UI/OptionsSelect.visible = true;


func _on_credits_button_pressed() -> void:
	$UI/MainMenu.visible = false;
	$UI/CreditsSelect.visible = true;


func _on_quit_button_pressed() -> void:
	get_tree().quit();


## OPTIONS
func _on_back_button_options_pressed() -> void:
	$UI/MainMenu.visible = true;
	$UI/OptionsSelect.visible = false;


## CREDITS
func _on_back_button_credits_pressed() -> void:
	$UI/MainMenu.visible = true;
	$UI/CreditsSelect.visible = false;


## START GAME MENU
func _on_start_tutorial_pressed() -> void:
	$UI/Background.visible = false;
	$UI/LevelSelect.visible = false;
	#Main.save.load_tutorial();
	var packed := load("res://scenes/userinterface/Menus/character_selection.tscn")
	var select_screen : Control = packed.instantiate()
	get_tree().root.add_child(select_screen)


func _on_start_new_game_pressed() -> void:
	print("_on_start_new_game_pressed was pressed.")
	_update_save_buttons()

func _on_load_game_pressed() -> void:
	$UI/LevelSelect.visible = false;
	$UI/LoadSelect.visible = true;
	_update_load_buttons()


func _on_back_button_level_pressed() -> void:
	$UI/LevelSelect.visible = false;
	$UI/MainMenu.visible = true;


## LOAD GAME
func _on_load_map_0_pressed() -> void:
	$UI/Background.visible = false;
	$UI/LoadSelect.visible = false;
	Main.save.read(0);


func _on_load_map_1_pressed() -> void:
	$UI/Background.visible = false;
	$UI/LoadSelect.visible = false;
	Main.save.read(1);


func _on_load_map_2_pressed() -> void:
	$UI/Background.visible = false;
	$UI/LoadSelect.visible = false;
	Main.save.read(2);


func _on_back_button_load_pressed() -> void:
	$UI/LoadSelect.visible = false;
	$UI/LevelSelect.visible = true;


## CREATE SAVE FILE
## TODO: Add warning if player is about to overwrite existing save file
func _on_back_button_create_save_pressed() -> void:
	_slot_pending_overwrite = -1
	$UI/CreateNewSaveFileSelect.visible = false;
	$UI/LevelSelect.visible = true;


func _on_select_save_file_0_pressed() -> void:
	if Main.save.slot_has_data(0) and _slot_pending_overwrite != 0:
		_slot_pending_overwrite = 0
		$UI/CreateNewSaveFileSelect/LevelSelectVBOX/SelectSaveFile0.text = "Slot 1 - Click again to confirm"
		return
	_slot_pending_overwrite = -1
	$UI/Background.visible = false
	$UI/CreateNewSaveFileSelect.visible = false
	Main.current_save_slot = 0
	Main.save.create_new_save_in_slot(0)
	Main.save.read(0)

func _on_select_save_file_1_pressed() -> void:
	if Main.save.slot_has_data(1) and _slot_pending_overwrite != 1:
		_slot_pending_overwrite = 1
		$UI/CreateNewSaveFileSelect/LevelSelectVBOX/SelectSaveFile1.text = "Slot 2 - Click again to confirm"
		return
	_slot_pending_overwrite = -1
	$UI/Background.visible = false
	$UI/CreateNewSaveFileSelect.visible = false
	Main.current_save_slot = 1
	Main.save.create_new_save_in_slot(1)
	Main.save.read(1)


func _on_select_save_file_2_pressed() -> void:
	if Main.save.slot_has_data(2) and _slot_pending_overwrite != 2:
		_slot_pending_overwrite = 2
		$UI/CreateNewSaveFileSelect/LevelSelectVBOX/SelectSaveFile2.text = "Slot 3 - Click again to confirm"
		return
	_slot_pending_overwrite = -1
	$UI/Background.visible = false
	$UI/CreateNewSaveFileSelect.visible = false
	Main.current_save_slot = 2
	Main.save.create_new_save_in_slot(2)
	Main.save.read(2)

func _on_delete_save_data_pressed() -> void:
	Main.save.clear_save_file()
	_update_save_buttons()
#endregion

func _update_create_save_buttons() -> void:
	var buttons := [
		$UI/CreateNewSaveFileSelect/LevelSelectVBOX/SelectSaveFile0,
		$UI/CreateNewSaveFileSelect/LevelSelectVBOX/SelectSaveFile1,
		$UI/CreateNewSaveFileSelect/LevelSelectVBOX/SelectSaveFile2
	]
	for i in buttons.size():
		if Main.save.slot_has_data(i):
			buttons[i].text = "Slot " + str(i + 1) + " (OVERWRITE?)"
		else:
			buttons[i].text = "Slot " + str(i + 1) + " (Empty)"


func _update_load_buttons() -> void:
	var load_buttons := [
		$UI/LoadSelect/LevelSelectVBOX/LoadMap0,
		$UI/LoadSelect/LevelSelectVBOX/LoadMap1,
		$UI/LoadSelect/LevelSelectVBOX/LoadMap2
	]
	for i in load_buttons.size():
		if Main.save.slot_has_data(i):
			load_buttons[i].text = "Slot " + str(i+1)
			load_buttons[i].disabled = false
		else:
			load_buttons[i].text = "Slot " + str(i+1) + "EMPTY"
			load_buttons[i].disabled = true


func _update_save_buttons() -> void:
	$UI/LevelSelect.visible = false
	$UI/CreateNewSaveFileSelect.visible = true
	
	var save_buttons := [		
		$UI/CreateNewSaveFileSelect/LevelSelectVBOX/SelectSaveFile0,
		$UI/CreateNewSaveFileSelect/LevelSelectVBOX/SelectSaveFile1,
		$UI/CreateNewSaveFileSelect/LevelSelectVBOX/SelectSaveFile2
	]
	for i in save_buttons.size():
		if Main.save.slot_has_data(i):
			save_buttons[i].text = "Slot " + str(i+1) + " - Overwrite?"
		else:
			save_buttons[i].text = "Slot " + str(i+1) + " - EMPTY"


var credits: Dictionary = {
	"Project lead" : "Kittel",
	"Art 1" : "Mari",
	"Art 2" : "Fen",
	"Programming 1" : "Alan",
	"Programming 2" : "Alexander",
	"Programming 3" : "Andreas",
	"Music" : "Han fyren"
}


func _on_level_select_pressed() -> void:
	print("Level Selection Pressed.")
	## Hide current UI
	$UI/LevelSelect.visible = false
	## Show grid with level nodes
	$UI/SelectLevelGrid.visible = true

func _fill_grid_with_levels() -> void:
	# Iterate over level_order.tres and fill grid with buttons to start each level
	# Will only play scene, not use save game system
	for i in range(_registry.levels.size()):
		var entry: LevelEntry = _registry.levels[i]
		var button:= Button.new()
		button.text = entry.display_name
		button.pressed.connect(_on_level_button_pressed.bind(i))
		grid_container.add_child(button)
	pass

func _on_level_button_pressed(index: int) -> void:
	$UI.visible = false
	Main.load_single_level(index)
	
func _on_back_button_level_select_pressed() -> void:
	$UI/SelectLevelGrid.visible = false;
	$UI/LevelSelect.visible = true;
