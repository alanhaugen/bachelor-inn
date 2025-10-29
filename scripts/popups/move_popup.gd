extends Control

@onready var map: Node;
@onready var move_button: Button = $VBoxContainer/MoveButton
@onready var attack_button: Button = $VBoxContainer/AttackButton
@onready var wait_button: Button = $VBoxContainer/WaitButton
@onready var cancel_button: Button = $VBoxContainer/CancelButton


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
	if map.active_move.character1.weapon == null or map.active_move.character1.weapon.is_melee:
		map.moves_stack.append(map.active_move.neighbour_move);
	map.moves_stack.append(map.active_move);
	map.a_star(map.moves_stack.front().start_pos, map.moves_stack.front().end_pos, false);
	map.state = map.States.ANIMATING;
	HidePopup();


func _on_wait_button_pressed() -> void:
	map.active_move.execute();
	HidePopup()


func _on_cancel_button_pressed() -> void:
	HidePopup();
	map.selected_unit.reset();
	map.selected_unit = null;
