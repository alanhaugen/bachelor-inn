extends ProgressBar

@onready var timer : Timer = $Timer
@onready var damage_bar : ProgressBar = $DamageBar

var health : int = 0 : set = _set_health

func _set_health(new_health : int) -> void:
	var prev_health : int = health
	health = min(max_value, new_health)
	value = health
	
	if health <= 0:
		queue_free()
	else:
		damage_bar.value = health
	
	if health < prev_health:
		timer.start()

func init_health(_health : int) ->void:
	health = _health
	max_value = health
	value = health
	damage_bar.max_value = health
	damage_bar.value = health

func _on_timer_timeout() -> void:
	damage_bar.value = health
