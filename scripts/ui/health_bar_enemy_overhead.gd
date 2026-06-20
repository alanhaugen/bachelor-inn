extends Node3D

@onready var background: Sprite3D = $Node3D/Background
@onready var trail: Sprite3D = $Node3D/Trail
@onready var current: Sprite3D = $Node3D/Current

var character: Character
var _trail_tween: Tween

func _ready() -> void:
	pass
