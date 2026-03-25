extends Control
class_name MovePopup

@onready var map: Level;
@onready var vbox: VBoxContainer = $VBoxContainer
@onready var move_button: Button = $VBoxContainer/MoveButton
@onready var attack_button: Button = $VBoxContainer/AttackButton
@onready var wait_button: Button = $VBoxContainer/WaitButton
@onready var pass_button: Button = $VBoxContainer/PassButton
@onready var undo_button: Button = $VBoxContainer/UndoButton
@onready var abilities_button: Button = $VBoxContainer/AbilitiesButton
@onready var abilities_vbox: VBoxContainer = $AbilitiesVBox
@onready var back_button: Button = $AbilitiesVBox/BackButton

# TODO: remove

func _ready() -> void:
	map = Main.level;


func HidePopup() -> void:
	map.is_in_menu = false;
	map.path_map.clear();
	move_button.hide();
	attack_button.hide();
	abilities_button.hide();
	wait_button.hide();
	pass_button.hide();
	undo_button.hide();
	_clear_ability_buttons()
	vbox.show()
	abilities_vbox.hide()
	hide();


func _clear_ability_buttons() -> void:
	for child in abilities_vbox.get_children():
		if child == back_button:
			continue
		child.queue_free()


func add_abilities(character: Character) -> void:
	_clear_ability_buttons()
	abilities_button.hide()
	
	if character == null or character.state.is_ability_used:
		return
	
	var has_skills := false
	for skill in character.state.skills:
		if skill == null:
			continue
		has_skills = true
		var btn := wait_button.duplicate() as Button
		btn.text = skill.skill_name
		btn.show()
		btn.set_meta(&"skill", skill)
		btn.pressed.connect(_on_ability_button_pressed.bind(skill))
		
		# Gray out if no result
		if map and not map.can_use_skill(character, skill):
			btn.disabled = true
			btn.focus_mode = Control.FOCUS_NONE # Avoid focusing disabled buttons
		else:
			btn.disabled = false
			btn.focus_mode = Control.FOCUS_ALL

		abilities_vbox.add_child(btn)
		abilities_vbox.move_child(btn, abilities_vbox.get_child_count() - 2) # Put above Back button
	
	if has_skills:
		abilities_button.show()


func _on_abilities_button_pressed() -> void:
	vbox.hide()
	abilities_vbox.show()
	# Focus the first ability or back button
	if abilities_vbox.get_child_count() > 0:
		abilities_vbox.get_child(0).grab_focus()


func _on_back_button_pressed() -> void:
	abilities_vbox.hide()
	vbox.show()
	abilities_button.grab_focus()


func _on_ability_button_pressed(skill: Skill) -> void:
	HidePopup()
	map._on_ribbon_skill_pressed(skill)


func _on_move_button_pressed() -> void:
	map.moves_stack.append(map.active_move);
	map.state = CampaignState.LevelState.ANIMATING;
	HidePopup();


func _on_attack_button_pressed() -> void:
	HidePopup()
	map.initiate_attack_selection()


func _on_wait_button_pressed() -> void:
	if map.selected_unit:
		map.selected_unit.state.is_moved = true
		map.selected_unit.state.is_ability_used = true
		map.occupancy_overlay.set_cell_item(map.selected_unit.state.grid_position, map.player_code_done)
		map.emit_signal("character_stats_changed", map.selected_unit)
	HidePopup()


func _on_pass_button_pressed() -> void:
	if map.selected_unit:
		map.selected_unit.state.is_moved = true
		map.selected_unit.state.is_ability_used = true
		map.occupancy_overlay.set_cell_item(map.selected_unit.state.grid_position, map.player_code_done)
		map.emit_signal("character_stats_changed", map.selected_unit)
	HidePopup()


func _on_undo_button_pressed() -> void:
	if map.active_move:
		map.active_move.undo(map.game_state)
		map._clear_selection()
		map.active_move = null
	HidePopup()


func _input(event: InputEvent) -> void:
	if is_instance_valid(map) == false:
		return;
	if map.is_in_menu == false:
		return;
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			_on_cancel_button_pressed();


func _on_cancel_button_pressed() -> void:
	if abilities_vbox.visible:
		_on_back_button_pressed()
		return
		
	if map.active_move:
		map.active_move.undo(map.game_state)
		map._clear_selection()
		map.active_move = null
	HidePopup();
