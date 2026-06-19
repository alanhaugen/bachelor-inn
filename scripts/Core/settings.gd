extends Node
## SHOULD BE SET TO AUTOLOAD
## Use Godot's built in config files
## This file is for future settings in Menu

var auto_select_next_unit: bool = false
var master_volume: float = 1.0
var show_enemy_healthbar: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	#load_settings()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
