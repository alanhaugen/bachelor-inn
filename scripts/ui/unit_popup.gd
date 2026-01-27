extends Control

@onready var map: Node;
@onready var wait_button: Button = $VBoxContainer/WaitButton
@onready var cancel_button: Button = $VBoxContainer/CancelButton
@onready var ability_button: Button = $VBoxContainer/AbilityButton
@onready var attack_button: Button = $VBoxContainer/AttackButton

signal ability_pressed
signal attack_pressed
signal wait_pressed
signal cancel_pressed

# TODO: remove

func _ready() -> void:
	map = Main.level;


func HidePopup() -> void:
	map.is_in_menu = false;
	#map.path_arrow.clear(); ## should be handeled in map, not here
	ability_button.hide();
	attack_button.hide();
	wait_button.hide();
	cancel_button.hide();
	hide();


func _on_ability_button_pressed() -> void:
	emit_signal("ability_pressed")
	HidePopup();
	
func _on_attack_button_pressed() -> void:
	emit_signal("attack_pressed")
	HidePopup();


func _on_wait_button_pressed() -> void:
	emit_signal("wait_pressed")
	## commenting out stuff so we can handle map and movement stuff outside the UI
	#map.active_move.execute(map.game_state);
	#map.units_map.set_cell_item(map.active_move.start_pos, GridMap.INVALID_CELL_ITEM);
	#map.units_map.set_cell_item(map.active_move.end_pos, map.player_code_done);
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
	emit_signal("cancel_pressed")
	HidePopup();
	#map.selected_unit.reset();
	#map.selected_unit = null;
