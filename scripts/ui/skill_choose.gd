extends Control
class_name SkillChoose

@onready var name_speciality: Label = %NameSpeciality
@onready var skill_1: Button = %Skill1
@onready var skill_2: Button = %Skill2
@onready var label_skill_1: Label = %LabelSkill1
@onready var label_skill_2: Label = %LabelSkill2
var unit : Character;
var first_skill : Skill;
var second_skill : Skill;

var text :String = "" : set = set_text;


func set_text(in_text : String) -> void:
	text = in_text;
	name_speciality.text = in_text;


func _on_skill_1_pressed() -> void:
	unit.skills.append(first_skill);
	hide();


func _on_skill_2_pressed() -> void:
	unit.skills.append(second_skill);
	hide();
