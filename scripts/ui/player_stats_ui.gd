extends Control
class_name PlayerStats

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
