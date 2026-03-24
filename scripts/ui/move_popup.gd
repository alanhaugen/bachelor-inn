extends Control

@onready var map: Node;
@onready var move_button: Button = $VBoxContainer/MoveButton
@onready var attack_button: Button = $VBoxContainer/AttackButton
@onready var wait_button: Button = $VBoxContainer/WaitButton
@onready var undo_button: Button = $VBoxContainer/UndoButton
@onready var cancel_button: Button = $VBoxContainer/CancelButton

# TODO: remove

func _ready() -> void:
	map = Main.level;
	wait_button.text = "Pass"


func HidePopup() -> void:
	map.is_in_menu = false;
	map.path_map.clear();
	move_button.hide();
	attack_button.hide();
	wait_button.hide();
	undo_button.hide();
	hide();


func _on_move_button_pressed() -> void:
	map.moves_stack.append(map.active_move);
	map.state = map.States.ANIMATING;
	HidePopup();


func _on_attack_button_pressed() -> void:
	#if map.active_move.aggressor.weapon == null or map.active_move.aggressor.weapon.is_melee:
	#	map.moves_stack.append(map.active_move.neighbour_move);
	map.moves_stack.append(map.active_move);
	map.a_star(map.moves_stack.front().start_pos, map.moves_stack.front().end_pos, false);
	map.state = map.States.ANIMATING;
	HidePopup();


func _on_wait_button_pressed() -> void:
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
	if map.active_move:
		map.active_move.undo(map.game_state)
		map._clear_selection()
		map.active_move = null
	HidePopup();
