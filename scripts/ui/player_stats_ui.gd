extends Control
class_name PlayerStatsUI

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
@onready var Stats_Container: Control = %Stats
@onready var open_close_stats_button: Button = %Open_Close_stats
@onready var oc_icon: TextureRect = %O_C_icon


func apply_stats(stats: Dictionary) -> void:
	icon_texture.texture = stats.portrait
	name_label.text = stats.name
	
	health_bar.max_value = stats.max_health
	health_bar.value = stats.health
	health_text.text = "%02d/%02d" % [stats.health, stats.max_health]
	
	sanity_bar.max_value = stats.max_sanity
	sanity_bar.value = stats.sanity
	sanity_text.text = "%02d/%02d" % [stats.sanity, stats.max_sanity]
	
	strength_text.text = str(stats.strength).pad_zeros(2)
	mind_text.text = str(stats.mind).pad_zeros(2)
	speed_text.text = str(stats.speed).pad_zeros(2)
	focus_text.text = str(stats.focus).pad_zeros(2)
	endurance_text.text = str(stats.endurance).pad_zeros(2)
	
	level_text.text = "Level: %d" % stats.level
	type.text = stats.type

func _on_open_close_stats_pressed() -> void:
	Stats_Container.visible = not Stats_Container.visible
	oc_icon.flip_h = not Stats_Container.visible
