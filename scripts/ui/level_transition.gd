extends Control

const UNIT_CARD := preload("res://scenes/states/UnitCard.tscn")
@onready var continue_button: Button = $VBoxContainer/ContinueButton
#@onready var continue_button: Button = $VBoxContainer/ContinueButton

func _ready() -> void:
	_setup_ui()
	update_continue_button()

func _setup_ui() -> void:
	var level_name := Main.current_level_name
	$VBoxContainer/HBoxContainer/LevelName.text = Main.level_display_names.get(level_name, level_name)
	$VBoxContainer/HBoxContainer/FlavorText.text = Main.level_flavor_texts.get(level_name, "")
	
	## TODO: FIll in the "card slots" for each unit
	for c in Main.characters:
		if c != null:
			c.state.unspent_skill_points += 3
		if c == null:
			continue
		var card := UNIT_CARD.instantiate() as UnitCard
		$VBoxContainer/UnitContainer.add_child(card)
		card.setup(c)


func _on_continue_button_pressed() -> void:
	for c in Main.characters:
		if c!= null and c.state.unspent_skill_points > 0:
			return
	if is_instance_valid(Main.level):
		Main.level.is_in_menu = false
	Main.transition_screen.queue_free()
	Main.transition_screen = null
	Main.next_level()


func update_continue_button() -> void:
	## Order in "spend_skill_points()" in unit_card.gd is wrong, so the trigger cant happen atm.
	for c in Main.characters:
		c.state.level += 1
		print("Level up! " + c.data.unit_name + " is now level " + str(c.state.level))
