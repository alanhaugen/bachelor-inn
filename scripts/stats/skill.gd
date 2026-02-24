extends Resource
class_name Skill

enum TargetFaction
{
	FRIENDLY, ## Will use friendly as both friendly and self first
	ENEMY,
	BOTH,
	SELF
}

## ID
@export var skill_id : String
@export var skill_name : String
@export var tooltip : String
@export var icon : Texture2D
@export var current_level : int = 1
var max_level : int = 5
@export var command : Command

## STATS
## Stat effects are now stored in a dictionary per spell/ability
## Add new Dict -> New Key: StringName, New Value: Int
## Key names MUST match the variable name inside character_state.gd, or variable name used in runtime!!!
@export var effect_mods : Dictionary = {}
@export var min_range: int = 1;
@export var max_range: int = 3;
@export var duration_turns: int = 0     ## how long it lasts
@export var target_faction: TargetFaction = TargetFaction.FRIENDLY
#@export var cast_on_friendly_ability: bool = true
#@export var cast_on_enemy_ability: bool = false



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
