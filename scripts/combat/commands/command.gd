extends Resource
class_name Command
## Command pattern
##
## https://gameprogrammingpatterns.com/command.html


func execute(_state : GameState, _simulate_only : bool = false) -> void:
	pass;


func undo(_state : GameState, _simulate_only : bool = false) -> void:
	pass;
