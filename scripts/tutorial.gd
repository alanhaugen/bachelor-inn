extends Node

enum Step {
	INACTIVE,
	#INTRO,
	#MOVE_AWAY,
	#TERRIAN_EXPLAINED,
	#USE_ABILITIES,
	#COMBAT_EXPLAINED,
	#COMPLETE
	STEP_1,
	STEP_2,
	STEP_3,
	STEP_4,
	STEP_5,
	STEP_6,
	STEP_7
}

var current_step : Step = Step.INACTIVE
var current_timeline: int = 1
var level: Level
var in_tutorial : bool = false
var selection_advances_timeline: bool = true

## Tutorial state
var tutorial_state: TutorialStates = TutorialStates.new();

## This should advance the tutorial to the next timeline
## Given that the naming convention is "tutorialpc" + integer
func advance_timeline() -> void:
	current_timeline += 1
	var next_timeline: String = "tutorialpc" + str(current_timeline)
	
	#if Dialogic.has_timeline(next_timeline):
	if FileAccess.file_exists("res://dialogue/" + next_timeline + ".dtl"):
		tutorial_lock_menus()
		Dialogic.start(next_timeline)
	else:
		in_tutorial = false
		tutorial_unlock_menus()
		tutorial_unlock_camera()


## Start the first tutorial
func start_tutorial() -> void:
	in_tutorial = true
	current_step = Step.STEP_1
	tutorial_lock_menus()
	Dialogic.start("tutorialpc" + str(current_timeline))


func on_timeline_ended() -> void:
	if in_tutorial:
		tutorial_unlock_menus()
		tutorial_unlock_camera()
	
	match current_step:
		#Step.INTRO:
		Step.STEP_1:
			#current_step = Step.MOVE_AWAY
			current_step = Step.STEP_2
			level.is_in_menu = false
		#Step.MOVE_AWAY:
		Step.STEP_2:
			#current_step = Step.TERRIAN_EXPLAINED
			current_step = Step.STEP_3
			level.is_in_menu = false
		#Step.TERRIAN_EXPLAINED:
		Step.STEP_3:
			#current_step = Step.USE_ABILITIES
			current_step = Step.STEP_4
			level.is_in_menu = false
		#Step.USE_ABILITIES:
		Step.STEP_4:
			#current_step = Step.COMBAT_EXPLAINED
			current_step = Step.STEP_5
			level.is_in_menu = false
		#Step.COMBAT_EXPLAINED:
		Step.STEP_5:
			#current_step = Step.COMPLETE
			current_step = Step.STEP_6
			level.is_in_menu = false
		#Step.COMPLETE:
		Step.STEP_6:
			#current_step = Step.INACTIVE
			current_step = Step.STEP_7
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
	if not in_tutorial:
		return
	if not selection_advances_timeline:
		return
	selection_advances_timeline = false
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


func tutorial_highlight_element(target: Control) -> void:
	var highlight := Main.level.get_node("UI/tutorial_highlight")
	highlight.highligh(target)


func tutorial_clear_highlight_element() -> void:
	var highlight := Main.level.get_node("UI/tutorial_highlight")
	highlight.clear()


func tutorial_set_select_unit_advances_timeline() -> void:
	if selection_advances_timeline:
		selection_advances_timeline = false
		return
	else: 
		selection_advances_timeline = true


func _ready() -> void:
	Dialogic.timeline_ended.connect(on_timeline_ended)
