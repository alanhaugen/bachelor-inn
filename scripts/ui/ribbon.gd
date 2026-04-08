extends Control
class_name Ribbon

signal skill_pressed(skill: Skill)

@onready var skills: HBoxContainer = %Skills

var _skill_buttons: Array[TextureButton] = []

func _ready() -> void:
	print("Main.level: ", Main.level)
	Main.level.ability_used.connect(_on_ability_used)
	_skill_buttons = _collect_buttons(skills)
	_connect_group(_skill_buttons, _on_skill_button_pressed)
	_debug_print_buttons()
	set_skills([])

func set_skills(in_skills: Array[Skill]) -> void:
	gray_out_abilities_used(false)
	
	for i in range(_skill_buttons.size()):
		var b: TextureButton = _skill_buttons[i]

		if i < in_skills.size() and in_skills[i] != null:
			var s: Skill = in_skills[i]
			b.show()
			b.disabled = false

			b.texture_normal = s.icon
			b.tooltip_text = "%s\n%s" % [s.skill_name, s.tooltip]

			b.set_meta("skill", s)
		else:
			b.hide()
			b.disabled = true
			b.texture_normal = null
			b.tooltip_text = ""
			b.set_meta("skill", null)

func _collect_buttons(bar: HBoxContainer) -> Array[TextureButton]:
	var out: Array[TextureButton] = []
	for child in bar.get_children():
		var b := child as TextureButton
		if b:
			out.append(b)
	return out

func _connect_group(buttons: Array[TextureButton], handler: Callable) -> void:
	for b in buttons	:
		if not b.pressed.is_connected(handler):
			b.pressed.connect(handler.bind(b))

func _on_skill_button_pressed(button: TextureButton) -> void:
	print("Skill button pressed.")
	if Main.level.is_choosing_skill_attack_origin:
		return
	if Main.level.is_choosing_skill_target:
		return
	var s: Skill = button.get_meta("skill") as Skill
	if s != null:
		skill_pressed.emit(s)


func _on_ability_used() -> void:
	print("ability_used signal received in ribbon")
	gray_out_abilities_used(true)

## TODO: Fix? Faied attempt to gray out ability buttons after use
func gray_out_abilities_used(used: bool) -> void:
	for b in _skill_buttons:
		b.disabled = used
		b.modulate = Color(0.4, 0.4, 0.4, 1.0) if used else Color(1, 1, 1, 1)


func trigger_skill_by_index(index: int) -> void:
	if index < 0 or index >= _skill_buttons.size():
		return
	var button := _skill_buttons[index]
	if button.disabled or not button.visible:
		return
	var s: Skill = button.get_meta("skill") as Skill
	if s != null:
		skill_pressed.emit(s)

func _debug_print_buttons() -> void:
	print("=== Ribbon Debug ===")
	print("Skills buttons found:", _skill_buttons.size())
	for i in range(_skill_buttons.size()):
		print("  Skill slot", i, "->", _skill_buttons[i].name)
	if _skill_buttons.size() != 5:
		push_warning("Expected 5 skill buttons but found %d" % _skill_buttons.size())
	print("====================")
