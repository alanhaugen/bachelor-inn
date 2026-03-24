extends CanvasLayer

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	if Main.level.is_in_menu:
		return
	visible = !visible
	get_tree().paused = visible
	if visible:
		# Optionally grab focus for the first button
		$Control/VBoxContainer/ResumeButton.grab_focus()

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/userinterface/main_menu.tscn")
