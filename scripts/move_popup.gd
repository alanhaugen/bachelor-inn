extends Control

@onready var map: Node2D = $"..";
@onready var move_button: Button = $VBoxContainer/MoveButton
@onready var attack_button: Button = $VBoxContainer/AttackButton
@onready var wait_button: Button = $VBoxContainer/WaitButton
@onready var cancel_button: Button = $VBoxContainer/CancelButton

func HidePopup() -> void:
	map.inMenu = false;
	map.isUnitSelected = false;
	map.path_arrow.clear();
	move_button.hide();
	attack_button.hide();
	wait_button.hide();
	hide();

func _on_move_button_pressed() -> void:
	map.movesStack.append(map.activeMove);
	map.state = map.States.ANIMATING;
	HidePopup();

func _on_attack_button_pressed() -> void:
	map.movesStack.append(map.activeMove);
	map.state = map.States.ANIMATING;
	HidePopup();

func _on_wait_button_pressed() -> void:
	map.movesStack.append(map.activeMove);
	HidePopup()

func _on_cancel_button_pressed() -> void:
	HidePopup();
