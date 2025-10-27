extends ColorRect

@onready var health_bar : ProgressBar = $HBoxContainer/Health;
@onready var sanity_bar : ProgressBar = $HBoxContainer/Sanity;

var health : int = 0 : set = _set_health
var sanity : int = 0 : set = _set_sanity


func _ready() -> void:
	health_bar.max_value = 0;
	sanity_bar.max_value = 0;

func _set_health(new_health: int) -> void:
	health_bar.max_value = max(health_bar.max_value, new_health);
	health_bar.value = new_health;
	health = new_health;


func _set_sanity(new_sanity: int) -> void:
	sanity_bar.max_value = max(sanity_bar.max_value, new_sanity);
	sanity_bar.value = new_sanity;
	sanity = new_sanity;
