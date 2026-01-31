extends Control
class_name CharacterPreview

@onready var icon_texture: TextureRect = %Icon_texture
@onready var health_bar: ProgressBar = %HealthBar
@onready var sanity_bar: ProgressBar = %SanityBar



var is_selected: bool = false : set =_set_is_selected;
func _set_is_selected(in_is_selected: bool) -> void:
	$SelectedUnit.visible = in_is_selected
	
func apply_stats(stats: Dictionary) -> void:
	icon_texture.texture = stats.portrait
	health_bar.max_value = stats.max_health
	health_bar.value = stats.health
	sanity_bar.max_value = stats.max_sanity
	sanity_bar.value = stats.sanity

func _on_button_pressed() -> void:
	#something something send a signal to Level to say that this character is selected
	print("Character has been pressed :D")
