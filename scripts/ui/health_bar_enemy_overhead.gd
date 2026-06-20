extends Node3D

@onready var background: Sprite3D = $Node3D/Background
@onready var trail: Sprite3D = $Node3D/Trail
@onready var current: Sprite3D = $Node3D/Current

var character: Character
var _trail_tween: Tween

func _ready() -> void:
	character = get_parent() as Character
	if character == null:
		push_warning("HealthBarEnemy found no parent.")
		return
	
	Main.level.character_stats_changed.connect(_on_character_stats_changed)
	
	var percent := float(character.state.current_health) / character.state.max_health
	current.scale.x = percent
	trail.scale.x = percent
	visible = percent < 1.0

func _on_character_stats_changed(changed_character: Character) -> void:
	if changed_character != character:
		return
	
	var percent := float(character.state.current_health) / character.state.max_health
	set_health_percent(percent)

func set_health_percent(new_percent: float) -> void:
	new_percent = clamp(new_percent, 0.0, 1.0)
	trail.scale.x = current.scale.x
	current.scale.x = new_percent
	
	if _trail_tween:
		_trail_tween.kill()
	_trail_tween = create_tween()
	_trail_tween.tween_property(trail, "scale:x", new_percent, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	visible = new_percent < 1.0
	
	if new_percent <= 0.0:
		await _trail_tween.finished
		queue_free()
	
	
