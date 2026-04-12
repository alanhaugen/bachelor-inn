extends Control

@onready var level_name_label: Label = %LevelName
@onready var flavor_text_label: Label = %FlavorText

func _ready() -> void:
	var level_name := Main.current_level_name
	level_name_label.text = Main.level_display_names.get(level_name, level_name)
	flavor_text_label.text = Main.level_story_text.get(level_name, "")
	#await get_tree().create_timer(5.0).timeout
	#_start_tutorial_deferred()


func _start_tutorial_deferred() -> void:
	Tutorial.start_tutorial()


func _on_continuie_button_pressed() -> void:
	if is_instance_valid(Main.flavor_screen):
		Main.flavor_screen.queue_free()
		Main.flavor_screen = null
	if is_instance_valid(Main.level):
		Main.level.is_in_menu = false
		if Main.level.level_name.begins_with("tutorial"):
			Tutorial.level = Main.level
			Tutorial.start_tutorial()
