class_name Skill
extends Node

var skill_name : String;
var tooltip : String;
var icon : Texture2D;
var level : int = 1;
var max_level : int = 5;
var command : Command;


func _init(inName : String, inTooltip : String, inIcon : Texture2D, inLevel : int, inMaxLevel : int, inCommand : Command) -> void:
	skill_name = inName;
	tooltip = inTooltip;
	icon = inIcon;
	level = inLevel;
	max_level = inMaxLevel;
	command = inCommand;
