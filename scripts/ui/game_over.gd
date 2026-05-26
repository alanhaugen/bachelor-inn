extends Control
class_name GameOver

@onready var retry_button: Button = $ColorRect/VBoxContainer/RetryButton
@onready var back_button: Button = $ColorRect/VBoxContainer/BackButton

func _ready() -> void:
	#retry_button.pressed.connect(_on_retry_button_pressed)
	#back_button.pressed.connect(_on_back_button_pressed)
	if not retry_button.pressed.is_connected(_on_retry_button_pressed):
		retry_button.pressed.connect(_on_retry_button_pressed)
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)
	
func _on_retry_button_pressed() -> void:
	call_deferred("_load_retry")
	#queue_free()
	#if Tutorial.in_tutorial:
		#Tutorial.current_tutorial_level = 1
		#Tutorial.current_timeline = 1
		##call_deferred("_load_retry")
		#Main.save.load_tutorial()
	#else:
		#Main.save.read(Main.current_save_slot)


func _load_retry() -> void:
	print("_load_retry called")
	queue_free()
	if Main.current_save_slot == SaveGame.TUTORIAL_SAVE_SLOT:
		Tutorial.current_tutorial_level = 1
		Tutorial.current_timeline = 1
		Tutorial.in_tutorial = true
		Main.save.load_tutorial()
	else:
		Main.save.read(Main.current_save_slot)


func _on_back_button_pressed() -> void:
	if is_instance_valid(Main.level):
		Main.level.queue_free()
		Main.level = null
	get_tree().change_scene_to_file("res://scenes/userinterface/main_menu.tscn");
	# unload level
	# open main menu
