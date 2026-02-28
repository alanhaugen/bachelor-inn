extends Control
class_name CharacterPreview

signal preview_selected(character: Character)

@onready var icon_texture: TextureRect = %Icon_texture
@onready var health_bar: ProgressBar = %HealthBar
@onready var sanity_bar: ProgressBar = %SanityBar
@onready var selected_indicator: Control = %SelectedUnit
@onready var character_name:Label= %CharacterName
@onready var effectDrawer: Control = %EffectDrawer
@onready var OC_ED_ICON: TextureRect = %OC_ED_Icon

@onready var effectContainer: HBoxContainer = %EffectHbox

@onready var notMoved: TextureRect = %NotMoved
@onready var notAction: TextureRect = %NotAction
@onready var Moved: TextureRect = %Moved
@onready var Action: TextureRect = %Action 

var has_moved: bool = false : set =_set_has_moved
var has_used_ability: bool = false : set =_set_has_used_ability

var ActiveEffectUI: PackedScene = preload("res://scenes/userinterface/active_effect_scene.tscn")

var character: Character
var is_selected: bool = false : set =_set_is_selected;

func _set_has_moved(in_has_moved: bool) -> void:
	notMoved.visible = !in_has_moved
	Moved.visible = in_has_moved

func _set_has_used_ability(in_has_used_ability: bool) -> void:
	notAction.visible = !in_has_used_ability
	Action.visible = in_has_used_ability
	
func _set_is_selected(in_is_selected: bool) -> void:
	selected_indicator.visible = in_is_selected

func update_effects_ui(in_character: Character) -> void:
	for child in effectContainer.get_children():
		child.queue_free()
	
	for effect in character.state.active_effects:
		var ui : Control =ActiveEffectUI.instantiate()
		ui.set_visuals(effect)
		effectContainer.add_child(ui)

func apply_stats(stats: Dictionary, in_character: Character) -> void:
	character = in_character
	character_name.text = stats.name
	icon_texture.texture = stats.portrait
	health_bar.max_value = stats.max_health
	health_bar.value = stats.health
	sanity_bar.max_value = stats.max_sanity
	sanity_bar.value = stats.sanity
	has_moved = character.state.is_moved 
	has_used_ability = character.state.is_ability_used

func _on_button_pressed() -> void:
	emit_signal("preview_selected", character)



func _on_oc_effect_drawer_pressed() -> void:
	effectDrawer.visible = not effectDrawer.visible
	OC_ED_ICON.flip_v = not effectDrawer.visible
	if effectDrawer.visible:
		custom_minimum_size = Vector2(0,64)
	elif not effectDrawer.visible:
		custom_minimum_size = Vector2(0,46)
