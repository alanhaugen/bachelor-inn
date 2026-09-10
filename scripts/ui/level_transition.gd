extends Control

const UNIT_CARD := preload("res://scenes/states/UnitCard.tscn")
@onready var continue_button: Button = $VBoxContainer/ContinueButton
#@onready var continue_button: Button = $VBoxContainer/ContinueButton

func _ready() -> void:
	_setup_ui()
	update_continue_button()

func _setup_ui() -> void:
	var entry := Main.levels[Main.current_level_index]	#var level_name := Main.levels[Main.current_level_index].display_name
	$VBoxContainer/HBoxContainer/LevelName.text = entry.display_name#Main.level_display_names.get(level_name, level_name)
	$VBoxContainer/HBoxContainer/FlavorText.text = entry.flavor_text#Main.level_flavor_texts.get(level_name, "")
	
	## TODO: FIll in the "card slots" for each unit
	for c in Main.characters:
		if c == null:
			continue
		c.state.unspent_attribute_points += c.state.attribute_points_per_level
		var card := UNIT_CARD.instantiate() as UnitCard
		$VBoxContainer/UnitContainer.add_child(card)
		card.setup(c)

func _on_continue_button_pressed() -> void:
	print("Continue pressed")
	for c in Main.characters:
		if c == null:
			continue
		if c.state.unspent_attribute_points > 0:
			return
	Main.transition_screen.queue_free()
	Main.transition_screen = null
	Main.next_level()

func update_continue_button() -> void:
	for c in Main.characters:
		c.state.level += 1
		print("Level up! " + c.data.unit_name + " is now level " + str(c.state.level))
