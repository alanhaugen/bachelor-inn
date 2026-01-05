extends Resource
class_name Command
## Command pattern
##
## https://gameprogrammingpatterns.com/command.html


func execute(state : GameState, simulate_only : bool = false) -> void:
	pass;


func undo(state : GameState, simulate_only : bool = false) -> void:
	pass;
