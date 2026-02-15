extends Resource
class_name Skill


## ID
@export var skill_id : String
@export var skill_name : String
@export var tooltip : String
@export var icon : Texture2D
@export var current_level : int = 1
var max_level : int = 5
@export var command : Command

## STATS
@export var damage_amount: int = 0;
@export var heal_amount: int = 0;
@export var heal_sanity_amount: int = 0;
@export var min_range: int = 1;
@export var max_range: int = 1;
@export var speed_bonus: int = 0        # how many tiles extra
@export var duration_turns: int = 0     # how long it lasts

# BOOLS / REQUIREMENTS
@export var uses_action: bool = true;
@export var requires_speciality: bool = false; ## Feks. polearm training etc.
@export var has_requirement: bool = false; ## Må ikke være skill. Kan være class specific etc. 

func _init(inName : String = "", inTooltip : String = "", inIcon : Texture2D = null, inLevel : int = 1, inMaxLevel : int = 1, inCommand : Command = null) -> void:
	skill_name = inName
	tooltip = inTooltip
	icon = inIcon
	current_level = inLevel
	max_level = inMaxLevel
	command = inCommand
