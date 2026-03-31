extends Node

enum Step {
	INACTIVE,
	INTRO,
	MOVE_AWAY,
	TERRIAN_EXPLAINED,
	USE_ABILITIES,
	COMBAT_EXPLAINED,
	COMPLETE
}

var current_step : Step = Step.INACTIVE
var current_timeline: int = 1
var level: Level

## Tutorial state
var tutorial_state: TutorialStates = TutorialStates.new();

## This should advance the tutorial to the next timeline
## Given that the naming convention is tutorialpc + integer
func advance_timeline() -> void:
	current_timeline += 1
	tutorial_lock_menus()
	Dialogic.start("tutorialpc" + str(current_timeline))


## Start the first tutorial
func start_tutorial() -> void:
	current_step = Step.INTRO
	tutorial_lock_menus()
	Dialogic.start("tutorialpc" + str(current_timeline))


func on_timeline_ended() -> void:
	tutorial_unlock_menus()
	tutorial_unlock_camera()
	match current_step:
		Step.INTRO:
			current_step = Step.MOVE_AWAY
			level.is_in_menu = false
		Step.MOVE_AWAY:
			current_step = Step.TERRIAN_EXPLAINED
			level.is_in_menu = false
		Step.TERRIAN_EXPLAINED:
			current_step = Step.USE_ABILITIES
			level.is_in_menu = false
		Step.USE_ABILITIES:
			current_step = Step.COMBAT_EXPLAINED
			level.is_in_menu = false
		Step.COMBAT_EXPLAINED:
			current_step = Step.COMPLETE
			level.is_in_menu = false
		Step.COMPLETE:
			current_step = Step.INACTIVE
			level.is_in_menu = false


## Make tutorial wait for signal
## 
## Disable inputs from the player
func tutorial_wait_for_signal() -> void:
	Dialogic.Inputs.manual_advance.system_enabled = false;


## Lock the camera so it can't be moved with
## the mouse, WASD or the arrow keys
func tutorial_lock_camera() -> void:
	Main.camera_controller.lock_camera()
	Main.camera_controller.freeze_camera_mode = true


## Unlock the camera so it can be moved with
## the mouse, WASD or the arrow keys
func tutorial_unlock_camera() -> void:
	Main.camera_controller.unlock_camera()
	Main.camera_controller.freeze_camera_mode = false


## Make it so the buttons in the game do nothing
func tutorial_lock_menus() -> void:
	Main.level.is_in_menu = true;


## Make the menus in the game operable again
func tutorial_unlock_menus() -> void:
	Main.level.is_in_menu = false;


## React to camera moving in tutorial
func tutorial_camera_moved() -> void:
	if tutorial_state.CameraTutorial == false:
		if Dialogic.Inputs.manual_advance.system_enabled == false:
			Dialogic.Inputs.manual_advance.system_enabled = true;
			tutorial_state.CameraTutorial = true;
			Dialogic.start_timeline("tutorial2");


## Give a specific tile a special marker
func tutorial_highlight_tile(x : int, y : int, z: int) -> void:
	#Main.level.movement_map.set_cell_item(Vector3i(x, y, 0), 1);
	Main.level.movement_map.set_cell_item(Vector3i(x, y, z), 4);


## React to player selecting unit in tutorial
func tutorial_unit_selected() -> void:
	if tutorial_state.SelectTutorial == false:
		tutorial_state.SelectTutorial = true
		Tutorial.advance_timeline()
	#if tutorial_state.SelectTutorial == false:
	#	if Dialogic.Inputs.manual_advance.system_enabled == false:
	#		Dialogic.Inputs.manual_advance.system_enabled = true;
	#		tutorial_state.SelectTutorial = true;
	#		Dialogic.start_timeline("tutorial3");
	#		#set_mouse_filter(Control.MOUSE_FILTER_IGNORE);


## React to player moving units in tutorial
func tutorial_unit_moved() -> void:
	if tutorial_state.MoveTutorial == false and tutorial_state.SelectTutorial:
		tutorial_state.MoveTutorial = true;
		await get_tree().create_timer(2).timeout # wait a second so the previous dialogue closes
		Dialogic.start("tutorial4");


func tutorial_move_camera() -> void:
	pass


## Hide an object in the level
## This function can be called via Dialogic
##
## @param object_name: Name of Node3D object
func hide_object(object_name : String) -> void:
	var object :Node3D = Main.world.get_node("Map3d/" + object_name);
	object.hide();


func _ready() -> void:
	Dialogic.timeline_ended.connect(on_timeline_ended)
