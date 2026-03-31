extends Node3D

## Reference to the World node
@onready var world: Node3D = $World;

## Reference to the GUI
@onready var gui: Control = $UI;

## Level buttons
@onready var levelButton: Button = $UI/LevelSelect/LevelSelectVBOX/LoadMap0;

## Names of levels in the order they will be played
@export var levels_order: LevelOrder

@onready var camera_controller: CameraController = $World/CameraScene

#region --- Processing ---
## Called when the node enters the scene tree for the first time
func _ready() -> void:
	Main.world = world;
	Main.levels = levels_order.levels;
	Main.camera_controller = camera_controller;
	
	$UI/LevelSelect.visible = false;
	
	print(OS.get_data_dir());
	
	var success : bool = Main.save.is_savefile_existing();
	success = false; # Let's make a new save each time until the save format is stable
	
	if success:
		print("loaded save");
	else:
		print("loading save failed. Creating new save");
		Main.save.create_new_save_data();
	
	# Set focus on the first button
	#LevelButton.grab_focus();
#endregion

#region --- Signals ---

## MAIN MENU
func _on_start_game_button_pressed() -> void:
	$UI/LevelSelect.visible = true;
	$UI/MainMenu.visible = false;


func _on_options_button_pressed() -> void:
	pass # Replace with function body.


func _on_credits_button_pressed() -> void:
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	get_tree().quit();


## START GAME MENU
func _on_start_tutorial_pressed() -> void:
	$UI/Background.visible = false;
	$UI/LevelSelect.visible = false;
	Main.save.load_tutorial();


func _on_start_new_game_pressed() -> void:
	$UI/LevelSelect.visible = false
	$UI/CreateNewSaveFileSelect.visible = true


func _on_load_game_pressed() -> void:
	$UI/LevelSelect.visible = false;
	$UI/LoadSelect.visible = true;


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
	$UI/CreateNewSaveFileSelect.visible = false;
	$UI/LevelSelect.visible = true;


func _on_select_save_file_0_pressed() -> void:
	$UI/Background.visible = false
	$UI/CreateNewSaveFileSelect.visible = false
	Main.current_save_slot = 0
	Main.save.create_new_save_in_slot(0)
	Main.save.read(0)


func _on_select_save_file_1_pressed() -> void:
	$UI/Background.visible = false
	$UI/CreateNewSaveFileSelect.visible = false
	Main.current_save_slot = 1
	Main.save.create_new_save_in_slot(1)
	Main.save.read(1)


func _on_select_save_file_2_pressed() -> void:
	$UI/Background.visible = false
	$UI/CreateNewSaveFileSelect.visible = false
	Main.current_save_slot = 2
	Main.save.create_new_save_in_slot(2)
	Main.save.read(2)
#endregion
