extends Control
class_name Ribbon

@onready var skills: HBoxContainer = %Skills

func set_skills(in_skills : Array[Skill]) -> void:
	for node in skills.get_children():
		node.queue_free()
	
	for skill in in_skills:
		var button := TextureButton.new()
		button.texture_normal = skill.icon
		button.tooltip_text = skill.skill_name + "\n" + skill.tooltip
		button.custom_minimum_size = Vector2(100, 100)
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.pressed.connect(_on_skill_pressed.bind(skill))
		
		skills.add_child(button)


func _on_skill_pressed(skill: Skill) -> void:
	print("Pressed skill " + skill.skill_name)
	#emit_signal("skill_pressed", skill)
	var commands: Array[Command]
	var selected_unit := Main.level.selected_unit
	if selected_unit:
		for unit: Character in Main.level.game_state.units:
			if unit.state.is_ally():
				commands.append(Heal.new(selected_unit.state.grid_position, unit.state.grid_position, selected_unit.data.mind))
		Main.level.path_map.clear()
		Main.level.current_moves = commands
		Main.level.movement_grid.fill_from_commands(commands, Main.level.game_state)
		Main.level.is_using_ability = true
