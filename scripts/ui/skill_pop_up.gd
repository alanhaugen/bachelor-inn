extends Control
class_name  SkillPopup

@onready var skill_name_1: Label = %SkillName1
@onready var skill_name_2: Label = $PanelContainer/VBoxContainer/HBoxContainer/SkillCard2/SkillName2
@onready var skill_name_3: Label = $PanelContainer/VBoxContainer/HBoxContainer/SkillCard3/SkillName3
@onready var icon_texture_1: TextureRect = %TextureRect1
@onready var icon_texture_2: TextureRect = $PanelContainer/VBoxContainer/HBoxContainer/SkillCard2/TextureRect2
@onready var icon_texture_3: TextureRect = $PanelContainer/VBoxContainer/HBoxContainer/SkillCard3/TextureRect3
@onready var description_1: Label = %Description1
@onready var description_2: Label = $PanelContainer/VBoxContainer/HBoxContainer/SkillCard2/Description2
@onready var description_3: Label = $PanelContainer/VBoxContainer/HBoxContainer/SkillCard3/Description3
@onready var stats_1: Label = %Stats1
@onready var stats_2: Label = $PanelContainer/VBoxContainer/HBoxContainer/SkillCard2/Stats2
@onready var stats_3: Label = $PanelContainer/VBoxContainer/HBoxContainer/SkillCard3/Stats3
@onready var select_button_1: Button = %SelectButton1
@onready var select_button_2: Button = $PanelContainer/VBoxContainer/HBoxContainer/SkillCard2/SelectButton2
@onready var select_button_3: Button = $PanelContainer/VBoxContainer/HBoxContainer/SkillCard3/SelectButton3
@onready var leave_button: Button = $PanelContainer/VBoxContainer/LeaveButton

var _skills : Array[Skill] = []
var _character : Character = null
var _chest : Chest = null

func _ready() -> void:
	select_button_1.pressed.connect(func() -> void: _on_skill_selected(0))
	select_button_2.pressed.connect(func() -> void: _on_skill_selected(1))
	select_button_3.pressed.connect(func() -> void: _on_skill_selected(2))
	#leave_button.pressed.connect(func() -> void: _on_leave_button_pressed())

func show_skill_loot(skills: Array[Skill], character: Character, chest: Chest) -> void:
	_skills = skills
	_character = character
	_chest = chest
	
	_add_skill_card(skill_name_1, icon_texture_1, description_1, stats_1, skills[0] if skills.size() > 0 else null)
	_add_skill_card(skill_name_2, icon_texture_2, description_2, stats_2, skills[1] if skills.size() > 1 else null)
	_add_skill_card(skill_name_3, icon_texture_3, description_3, stats_3, skills[2] if skills.size() > 2 else null)

	show()

func _add_skill_card(name_label: Label, icon: TextureRect, description: Label, stats: Label, skill: Skill) -> void:
	if skill == null:
		name_label.text = "Empty"
		icon.texture = null
		description.text = "No description"
		stats.text = "No stats"
		return
	name_label.text = skill.skill_name
	icon.texture = skill.icon
	description.text = skill.tooltip
	if skill.effect_mods.has("damage"):
		stats.text += "\nDamage: %d" % skill.effect_mods["damage"] #heal = current_health
	elif skill.effect_mods.has("current_health"):
		stats.text += "\nHealing: %d" % skill.effect_mods["current_health"]
	if skill.duration_turns > 0:
		stats.text += "\nDuration: %d turns" %skill.duration_turns

## Pressing the select buttons will return an index value, set in ready()
func _on_skill_selected(index: int) -> void:
	if index >= _skills.size():
		return
	var chosen_skill : Skill = _skills[index]
	
	if _character.state.skills.size() < 5:
		_character.state.skills.append(chosen_skill)
		_finish()
	else:
		_show_replace_skill_ui()

func _show_replace_skill_ui() -> void:
	print("_show_replace_skill_ui not implemented. Exiting window.")
	## _finish() should not be here. The function, not the people.
	_finish()

func _on_leave_button_pressed() -> void:
	_finish()

func _finish() -> void:
	if _chest != null:
		_chest.is_looted = true
		_chest.is_opened = false
	if is_instance_valid(Main.level):
		Main.level.is_in_menu = false
		Main.level.has_window_open = false
		Main.level.emit_signal("character_stats_changed", _character)
	hide()


func _on_select_button_1_pressed() -> void:
	pass # Replace with function body.


func _on_select_button_2_pressed() -> void:
	pass # Replace with function body.


func _on_select_button_3_pressed() -> void:
	pass # Replace with function body.
