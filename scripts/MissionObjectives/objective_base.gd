extends Node
class_name ObjectiveBase

@export var display_text: String = ""
@export var is_optional: bool = false

var is_complete: bool = false

func _ready() -> void:
	add_to_group("objectives")
	_setup()

func on_objective_complete() -> void:
	is_complete = true
	print("Objective complete: ", display_text)
	#Main.level.CheckVictoryConditions()

func _setup() -> void:
	pass  # override in each objective type

func check() -> void:
	pass  # override in each objective type
