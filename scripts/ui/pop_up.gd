class_name StatPopUp
extends Control

@onready var icon_texture: TextureRect = %Icon_texture
@onready var health_bar: ProgressBar = %HealthBar
@onready var magic_bar: ProgressBar = %MagicBar
@onready var sanity_bar: ProgressBar = %SanityBar
@onready var name_label: Label = %CharacterName
@onready var health_text: Label = %HealthText
@onready var magic_text: Label = %MagicText
@onready var sanity_text: Label = %SanityText
@onready var strength_text: Label = %Strength
@onready var mind_text: Label = %Mind
@onready var speed_text: Label = %Speed
@onready var focus_text: Label = %Focus
@onready var endurance_text: Label = %Endurance
@onready var type: Label = %Type

var icon: TextureRect = null : set = _set_icon;
var health: int = 0 : set = _set_health;
var magic: int = 0 : set = _set_magic;
var sanity: int = 0 : set = _set_sanity;
var max_health: int = 0 : set = _set_max_health;
var max_magic: int = 0 : set = _set_max_magic;
var max_sanity: int = 0 : set = _set_max_sanity;

var strength: int = 0 : set = _set_strength;
var mind: int = 0 : set = _set_mind;
var speed: int = 0 : set = _set_speed;
var focus: int = 0 : set = _set_focus;
var endurance: int = 0 : set = _set_endurance;


func _set_icon(texture: TextureRect) -> void:
	icon_texture = texture;


func _set_health(in_health: int) -> void:
	health_bar.value = in_health;
	health_text.text = str(in_health) + "/" + str(max_health);


func _set_magic(in_magic: int) -> void:
	magic_bar.value = in_magic;
	magic_text.text = str(in_magic) + "/" + str(max_magic);


func _set_sanity(in_sanity: int) -> void:
	sanity_bar.max_value = in_sanity;
	sanity_text.text = str(in_sanity) + "/" + str(max_sanity);


func _set_max_health(in_health: int) -> void:
	health_bar.max_value = in_health;
	max_health = in_health;


func _set_max_magic(in_magic: int) -> void:
	magic_bar.max_value = in_magic;
	max_magic = in_magic;


func _set_max_sanity(in_sanity: int) -> void:
	sanity_bar.max_value = in_sanity;
	max_sanity = in_sanity;


func _set_strength(in_strength: int) -> void:
	strength = in_strength;
	strength_text.text = str(strength);


func _set_mind(in_mind: int) -> void:
	mind = in_mind;
	mind_text.text = str(mind);


func _set_speed(in_speed: int) -> void:
	speed = in_speed;
	speed_text.text = str(speed);


func _set_focus(in_focus: int) -> void:
	focus = in_focus;
	focus_text.text = str(focus);


func _set_endurance(in_endurance: int) -> void:
	endurance = in_endurance;
	endurance_text.text = str(endurance);


func _set_type(in_text: String) -> void:
	type.text = in_text;
