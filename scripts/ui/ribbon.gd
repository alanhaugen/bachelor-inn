extends Control
class_name Ribbon

signal skill_pressed(skill: Skill)
signal ability_pressed(skill: Skill)

@onready var skills: HBoxContainer = %Skills
@onready var abilities: HBoxContainer = %Abilities

var _skill_buttons: Array[TextureButton] = []
var _ability_buttons: Array[TextureButton] = []

func _ready() -> void:
	_skill_buttons = _collect_buttons(skills)
	_ability_buttons = _collect_buttons(abilities)

	_connect_group(_skill_buttons, _on_skill_button_pressed)
	_connect_group(_ability_buttons, _on_ability_button_pressed)

	_debug_print_buttons() # 👈 add this

	## Fills action bar based on units abilities
	set_skills([])
	set_abilities([])


func set_skills(in_skills: Array[Skill]) -> void:
	_fill_buttons(_skill_buttons, in_skills, "skill")


func set_abilities(in_abilities: Array[Skill]) -> void:
	_fill_buttons(_ability_buttons, in_abilities, "ability")


func set_skills_enabled(enabled: bool) -> void:
	_set_group_enabled(_skill_buttons, enabled, "skill")


func set_abilities_enabled(enabled: bool) -> void:
	_set_group_enabled(_ability_buttons, enabled, "ability")


func _set_group_enabled(buttons: Array[TextureButton], enabled: bool, meta_key: String) -> void:
	for b in buttons:
		var s: Skill = b.get_meta(meta_key) as Skill

		if s == null:
			b.hide()
			continue

		b.show()
		b.disabled = not enabled
		## Evt gråfarge ved ønske
		# b.modulate = Color(1,1,1,1) if enabled else Color(0.6,0.6,0.6,1)


func _collect_buttons(bar: HBoxContainer) -> Array[TextureButton]:
	var out: Array[TextureButton] = []
	for child in bar.get_children():
		var b := child as TextureButton
		if b:
			out.append(b)
	return out


func _connect_group(buttons: Array[TextureButton], handler: Callable) -> void:
	for b in buttons:
		if not b.pressed.is_connected(handler):
			b.pressed.connect(handler.bind(b))


func _fill_buttons(buttons: Array[TextureButton], entries: Array[Skill], meta_key: String) -> void:
	for i in range(buttons.size()):
		var b := buttons[i]

		if i < entries.size() and entries[i] != null:
			var s: Skill = entries[i]
			b.show()
			b.disabled = false
			b.texture_normal = s.icon
			b.tooltip_text = "%s\n%s" % [s.skill_name, s.tooltip]
			b.set_meta(meta_key, s)
		else:
			b.hide()
			b.disabled = true
			b.texture_normal = null
			b.tooltip_text = ""
			b.set_meta(meta_key, null)


func _on_skill_button_pressed(button: TextureButton) -> void:
	var s: Skill = button.get_meta("skill") as Skill
	if s != null:
		skill_pressed.emit(s)

func _on_ability_button_pressed(button: TextureButton) -> void:
	var s: Skill = button.get_meta("ability") as Skill
	if s != null:
		ability_pressed.emit(s)


func _debug_print_buttons() -> void:
	print("=== this is a temp Ribbon Debug ===")

	print("Skills buttons found:", _skill_buttons.size())
	for i in range(_skill_buttons.size()):
		print("  Skill slot", i, "->", _skill_buttons[i].name)

	print("Abilities buttons found:", _ability_buttons.size())
	for i in range(_ability_buttons.size()):
		print("  Ability slot", i, "->", _ability_buttons[i].name)

	if _skill_buttons.size() != 5:
		push_warning("Expected 5 skill buttons but found %d" % _skill_buttons.size())

	if _ability_buttons.size() != 5:
		push_warning("Expected 5 ability buttons but found %d" % _ability_buttons.size())

	print("====================")
