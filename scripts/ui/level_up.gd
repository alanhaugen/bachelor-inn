class_name LevelUpPopUp
extends Control

@onready var character_name: Label = %CharacterName;
@onready var level_number: Label = %LevelNumber;
@onready var health_stat: Label = %HealthStat;
@onready var strength_stat: Label = %StrengthStat;
@onready var movement_stat: Label = %MovementStat;
@onready var mind_stat: Label = %MindStat;
@onready var speed_stat: Label = %SpeedStat;
@onready var endurance_stat: Label = %EnduranceStat;
@onready var focus_stat: Label = %FocusStat;

var name_label: String = "" : set = _set_name;
var level: int = 0 : set = _set_level;
var health: int = 0 : set = _set_health;
var strength: int = 0 : set = _set_strength;
var movement: int = 0 : set = _set_movement;
var mind: int = 0 : set = _set_mind;
var speed: int = 0 : set = _set_speed;
var endurance: int = 0 : set = _set_endurance;
var focus: int = 0 : set = _set_focus;


func _ready() -> void:
	pass;


func _set_name(new_name: String) -> void:
	character_name.text = new_name;


func _set_level(new_level: int) -> void:
	level_number.text = "🏆 Level " + str(new_level);


func _set_health(new_health: int) -> void:
	var health_diff := new_health - health;
	health = new_health;
	var diff := "";
	if health_diff > 0:
		diff = " ⬆ +" + str(health_diff);
	health_stat.text = "🫀 Health: " + str(new_health) + diff;


func _set_strength(new_strength: int) -> void:
	var strength_diff := new_strength - strength;
	strength = new_strength;
	var diff := "";
	if strength_diff > 0:
		diff = " ⬆ +" + str(strength_diff);
	strength_stat.text = "💪 Strength: " + str(new_strength) + diff;


func _set_movement(new_movement: int) -> void:
	var movement_diff := new_movement - movement;
	movement = new_movement;
	var diff := "";
	if movement_diff > 0:
		diff = " ⬆ +" + str(movement_diff);
	movement_stat.text = "🏃 Movement: " + str(new_movement) + diff;


func _set_mind(new_mind: int) -> void:
	var mind_diff := new_mind - mind;
	mind = new_mind;
	var diff := "";
	if mind_diff > 0:
		diff = " ⬆ +" + str(mind_diff);
	mind_stat.text = "🧠 Mind: " + str(new_mind) + diff;


func _set_speed(new_speed: int) -> void:
	var speed_diff := new_speed - speed;
	speed = new_speed;
	var diff := "";
	if speed_diff > 0:
		diff = " ⬆ +" + str(speed_diff);
	speed_stat.text = "⚡ Speed: " + str(new_speed) + diff;


func _set_endurance(new_endurance: int) -> void:
	var endurance_diff := new_endurance - endurance;
	endurance = new_endurance;
	var diff := "";
	if endurance_diff > 0:
		diff = " ⬆ +" + str(endurance_diff);
	endurance_stat.text = "🌟 Endurance: " + str(new_endurance) + diff;


func _set_focus(new_focus: int) -> void:
	var focus_diff := new_focus - focus;
	focus = new_focus;
	var diff := "";
	if focus_diff > 0:
		diff = " ⬆ +" + str(focus_diff);
	focus_stat.text = "🔎 Focus: " + str(new_focus) + diff;


func _on_button_pressed() -> void:
	hide();
	Main.level.is_in_menu = false;
