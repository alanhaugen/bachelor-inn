extends Node3D

## Reference to the World node
@onready var world: Node3D = $World;

## Reference to the GUI
@onready var gui: Control = $UI;

## Level buttons
@onready var levelButton: Button = $UI/MapSelector/LoadMap0;

#region: --- Processing ---
## Called when the node enters the scene tree for the first time
func _ready() -> void:
	Main.gui = gui;
	Main.world = world;
	
	print(OS.get_data_dir());
	
	var success:bool = Main.save.read(0);
	
	if success:
		print("loaded save");
	else:
		print("loading save failed. Creating new save");
		Main.save.create_new_save_data();
	
	# Set focus on the first button
	levelButton.grab_focus();
#endregion

#region: --- Signals ---
## Called when the Load Map 0 button is pressed
func _on_load_map_0_pressed() -> void:
	$UI/MapSelector.visible = false;
	Main.load_level("first"); # Load the test level
#endregion
