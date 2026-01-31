extends Control
class_name StatPopUp

@onready var icon_texture: TextureRect = %Icon_texture
@onready var health_bar: ProgressBar = %HealthBar
@onready var mana_bar: ProgressBar = %MagicBar
@onready var sanity_bar: ProgressBar = %SanityBar
@onready var name_label: Label = %CharacterName
@onready var health_text: Label = %HealthText
@onready var magic_text: Label = %MagicText
@onready var sanity_text: Label = %SanityText
@onready var strength_text: Label = %Value_Strength
@onready var mind_text: Label = %Value_Mind
@onready var speed_text: Label = %Value_Speed
@onready var focus_text: Label = %Value_Focus
@onready var endurance_text: Label = %Value_Endurance
@onready var type: Label = %Type
@onready var level_text: Label = %Level

func apply_stats(stats: Dictionary) -> void:
	icon_texture.texture = stats.portrait
	name_label.text = stats.name
	
	health_bar.max_value = stats.max_health
	health_bar.value = stats.health
	health_text.text = "%d/%d" % [stats.health, stats.max_health]
	
	sanity_bar.max_value = stats.max_sanity
	sanity_bar.value = stats.sanity
	sanity_text.text = "%d/%d" % [stats.sanity, stats.max_sanity]
	
	strength_text.text = str(stats.strength)
	mind_text.text = str(stats.mind)
	speed_text.text = str(stats.speed)
	focus_text.text = str(stats.focus)
	endurance_text.text = str(stats.endurance)
	
	level_text.text = "Level: %d" % stats.level
	type.text = stats.type

#old below
var icon: TextureRect = null : set = _set_icon;
var health: int = 0 : set = _set_health;
var mana: int = 0 : set = _set_magic;
var sanity: int = 0 : set = _set_sanity;
var max_health: int = 0 : set = _set_max_health;
var max_mana: int = 0 : set = _set_max_magic;
var max_sanity: int = 0 : set = _set_max_sanity;

var strength: int = 0 : set = _set_strength;
var mind: int = 0 : set = _set_mind;
var speed: int = 0 : set = _set_speed;
var focus: int = 0 : set = _set_focus;
var endurance: int = 0 : set = _set_endurance;

var level: String = "" : set = _set_level;



func _set_icon(texture: TextureRect) -> void:
	icon_texture = texture;


func _set_health(in_health: int) -> void:
	health_bar.value = in_health;
	health_text.text = str(in_health) + "/" + str(max_health);


func _set_magic(in_magic: int) -> void:
	mana_bar.value = in_magic;
	magic_text.text = str(in_magic) + "/" + str(max_mana);


func _set_sanity(in_sanity: int) -> void:
	sanity_bar.value = in_sanity;
	sanity_text.text = str(in_sanity) + "/" + str(max_sanity);


func _set_max_health(in_health: int) -> void:
	health_bar.max_value = in_health;
	max_health = in_health;


func _set_max_magic(in_magic: int) -> void:
	mana_bar.max_value = in_magic;
	max_mana = in_magic;


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


func _set_level(in_text: String) -> void:
	level_text.text = in_text;
