class_name StatPopUp
extends Control

@onready var icon_texture: TextureRect = %Icon_texture
@onready var health_bar: ProgressBar = %HealthBar
@onready var magic_bar: ProgressBar = %MagicBar
@onready var sanity_bar: ProgressBar = %SanityBar

var icon: TextureRect = null : set = _set_icon;
var health: int = 0 : set = _set_health;
var magic: int = 0 : set = _set_magic;
var sanity: int = 0 : set = _set_sanity;
var max_health: int = 0 : set = _set_max_health;
var max_magic: int = 0 : set = _set_max_magic;
var max_sanity: int = 0 : set = _set_max_sanity;


func _set_icon(texture: TextureRect) -> void:
	icon_texture = texture;


func _set_health(in_health: int) -> void:
	health_bar.value = in_health;


func _set_magic(in_magic: int) -> void:
	magic_bar.value = in_magic;


func _set_sanity(in_sanity: int) -> void:
	sanity_bar.max_value = in_sanity;


func _set_max_health(in_health: int) -> void:
	health_bar.max_value = in_health;


func _set_max_magic(in_magic: int) -> void:
	magic_bar.max_value = in_magic;


func _set_max_sanity(in_sanity: int) -> void:
	sanity_bar.max_value = in_sanity;
