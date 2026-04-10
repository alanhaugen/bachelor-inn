extends Node3D

var t: float = 0.0
@export var amp: float = 0.2   
@export var speed: float = 1.5       
var y: float = 0.0      

func _ready() -> void:
	y = position.y

func _process(delta: float) -> void:
	t += delta * speed
	position.y = y + sin(t) * amp
