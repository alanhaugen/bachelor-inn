extends Control
class_name PauseMenu

@onready var options: Button = %Options
@onready var resume_button: Button = %ResumeButton
@onready var back_to_main_menu: Button = %BackToMainMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_resume_button_pressed() -> void:
	print("Resume Button pressed.")
	Main.level.is_in_menu = false
	Main.level.get_tree().paused = false
	self.hide()


func _on_back_to_main_menu_pressed() -> void:
	Main.level.is_in_menu = false
	Main.level.get_tree().paused = false
	if is_instance_valid(Main.level):
		Main.level.queue_free()
		Main.level = null
	get_tree().change_scene_to_file("res://scenes/userinterface/main_menu.tscn");


func _on_options_pressed() -> void:
	print("Options Menu Button pressed from in game.")
