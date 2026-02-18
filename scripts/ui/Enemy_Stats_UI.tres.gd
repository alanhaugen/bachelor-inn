extends Control
class_name EnemyStatsUI

@onready var icon_texture: TextureRect = %Icon_texture
@onready var health_bar: ProgressBar = %HealthBar
@onready var name_label: Label = %CharacterName
@onready var health_text: Label = %HealthText
@onready var type: Label = %Type
@onready var oc_icon: TextureRect = %O_C_icon


var current_enemy: Character = null



func apply_stats(stats: Dictionary, enemy: Character) -> void:
	current_enemy = enemy
	icon_texture.texture = stats.portrait
	name_label.text = stats.name
	
	health_bar.max_value = stats.max_health
	health_bar.value = stats.health
	health_text.text = "%d/%d" % [stats.health, stats.max_health]
