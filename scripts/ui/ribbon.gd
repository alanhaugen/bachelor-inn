class_name Ribbon
extends Control

@onready var skills: HBoxContainer = %Skills
@onready var abilities: HBoxContainer = %Abilities

func set_skills(in_skills : Array[Skill]) -> void:
	for node in skills.get_children():
		node.queue_free()
	
	for skill in in_skills:
		var icon : TextureRect = TextureRect.new();
		icon.texture = skill.icon;
		icon.tooltip_text = skill.skill_name + "\n" + skill.tooltip;
		icon.custom_minimum_size = Vector2(100,100);
		skills.add_child(icon);


func set_abilities() -> void:
	pass;
