class_name SaveGame
extends Resource

const SAVE_GAME_PATH := "user://save.tres";

## Use this to detect old player save files and update them 
@export var version := 1;

@export var map_name := "";


func save() -> void:
	pass;


func read(save_slot: int) -> void:
	if save_slot == 0:
		pass;
	pass;
