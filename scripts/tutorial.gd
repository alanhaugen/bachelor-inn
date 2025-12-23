extends Node

## Tutorial state
var tutorial_state: TutorialStates = TutorialStates.new();


## Start the first tutorial
func start_tutorial() -> void:
	Dialogic.start_timeline("tutorial1");


## Make tutorial wait for signal
## 
## Disable inputs from the player
func tutorial_wait_for_signal() -> void:
	Dialogic.Inputs.manual_advance.system_enabled = false;


func tutorial_lock_camera() -> void:
	Main.level.lock_camera = true;


func tutorial_unlock_camera() -> void:
	Main.level.lock_camera = false;


func tutorial_lock_menus() -> void:
	Main.level.is_in_menu = true;


func tutorial_unlock_menus() -> void:
	Main.level.is_in_menu = false;


## React to camera moving in tutorial
func tutorial_camera_moved() -> void:
	if tutorial_state.CameraTutorial == false:
		if Dialogic.Inputs.manual_advance.system_enabled == false:
			Dialogic.Inputs.manual_advance.system_enabled = true;
			tutorial_state.CameraTutorial = true;
			Dialogic.start_timeline("tutorial2");


func tutorial_highlight_tile(x : int, y : int) -> void:
	Main.level.movement_map.set_cell_item(Vector3i(x, y, 0), 1);


## React to player selecting unit in tutorial
func tutorial_unit_selected() -> void:
	if tutorial_state.SelectTutorial == false:
		if Dialogic.Inputs.manual_advance.system_enabled == false:
			Dialogic.Inputs.manual_advance.system_enabled = true;
			tutorial_state.SelectTutorial = true;
			Dialogic.start_timeline("tutorial3");
			#set_mouse_filter(Control.MOUSE_FILTER_IGNORE);


## React to player moving units in tutorial
func tutorial_unit_moved() -> void:
	if tutorial_state.MoveTutorial == false and tutorial_state.SelectTutorial:
		tutorial_state.MoveTutorial = true;
		Dialogic.start("tutorial4");


## Hide an object in the level
## This function can be called via Dialogic
##
## @param object_name: Name of Node3D object
func hide_object(object_name : String) -> void:
	var object :Node3D = Main.world.get_node("Map3d/" + object_name);
	object.hide();
