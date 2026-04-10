extends Control

const UNIT_CARD := preload("res://scenes/states/UnitCard.tscn")

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	var level_name := Main.current_level_name
	$VBoxContainer/LevelName.text = Main.level_display_names.get(level_name, level_name)
	$VBoxContainer/FlavorText.text = Main.level_flavor_texts.get(level_name, "")
	
	## TODO: FIll in the "card slots" for each unit
	for c in Main.characters:
		if c == null:
			continue
		var card := UNIT_CARD.instantiate() as UnitCard
		$VBoxContainer/UnitContainer.add_child(card)
		card.setup(c)

func _on_continue_button_pressed() -> void:
	if is_instance_valid(Main.level):
		Main.level.is_in_menu = false
	Main.transition_screen.queue_free()
	Main.transition_screen = null
	Main.next_level()
