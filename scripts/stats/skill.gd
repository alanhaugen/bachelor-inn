class_name Skill
extends Resource

@export var skill_name : String;
@export var tooltip : String;
@export var icon : Texture2D;
@export var level : int = 1;
@export var max_level : int = 5;
@export var command : Command;


func _init(inName : String = "", inTooltip : String = "", inIcon : Texture2D = null, inLevel : int = 1, inMaxLevel : int = 1, inCommand : Command = null) -> void:
	skill_name = inName;
	tooltip = inTooltip;
	icon = inIcon;
	level = inLevel;
	max_level = inMaxLevel;
	command = inCommand;
