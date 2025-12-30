extends Control

@onready var map: Node;
@onready var move_button: Button = $VBoxContainer/MoveButton
@onready var attack_button: Button = $VBoxContainer/AttackButton
@onready var wait_button: Button = $VBoxContainer/WaitButton
@onready var cancel_button: Button = $VBoxContainer/CancelButton

# TODO: remove

func _ready() -> void:
	map = Main.level;


func HidePopup() -> void:
	map.is_in_menu = false;
	map.path_arrow.clear();
	move_button.hide();
	attack_button.hide();
	wait_button.hide();
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
	map.active_move.execute(map.game_state);
	map.units_map.set_cell_item(map.active_move.start_pos, GridMap.INVALID_CELL_ITEM);
	map.units_map.set_cell_item(map.active_move.end_pos, map.player_code_done);
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
	HidePopup();
	#map.selected_unit.reset();
	map.selected_unit = null;
