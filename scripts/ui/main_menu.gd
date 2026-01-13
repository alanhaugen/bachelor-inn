extends Node3D

## Reference to the World node
@onready var world: Node3D = $World;

## Reference to the GUI
@onready var gui: Control = $UI;

## Level buttons
@onready var levelButton: Button = $UI/VBoxContainer/LevelSelect/LoadMap0;

## Names of levels in the order they will be played
@export var levels_order: LevelOrder

@onready var camera_controller: CameraController = $World/CameraScene

#region: --- Processing ---
## Called when the node enters the scene tree for the first time
func _ready() -> void:
	Main.world = world;
	Main.levels = levels_order.levels;
	Main.camera_controller = camera_controller;
	
	$UI/VBoxContainer/LevelSelect.visible = false;
	
	print(OS.get_data_dir());
	
	var success:bool = Main.save.is_savefile_existing();
	success = false; # Let's make a new save each time until the save format is stable
	
	if success:
		print("loaded save");
	else:
		print("loading save failed. Creating new save");
		Main.save.create_new_save_data();
	
	# Set focus on the first button
	levelButton.grab_focus();
#endregion

#region: --- Signals ---
func _on_load_map_0_pressed() -> void:
	$UI/Background.visible = false;
	$UI/VBoxContainer/LevelSelect.visible = false;
	Main.save.read(0);
func _on_load_map_1_pressed() -> void:
	$UI/Background.visible = false;
	$UI/VBoxContainer/LevelSelect.visible = false;
	Main.save.read(1);
func _on_load_map_2_pressed() -> void:
	$UI/Background.visible = false;
	$UI/VBoxContainer/LevelSelect.visible = false;
	Main.save.read(2);
func _on_start_game_button_pressed() -> void:
	$UI/VBoxContainer/LevelSelect.visible = true;
	$UI/VBoxContainer/MainMenu.visible = false;
func _on_back_button_pressed() -> void:
	$UI/VBoxContainer/LevelSelect.visible = false;
	$UI/VBoxContainer/MainMenu.visible = true;
func _on_quit_button_pressed() -> void:
	get_tree().quit();
#endregion
