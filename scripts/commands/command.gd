extends Resource
class_name Command
## Command pattern
##
## https://gameprogrammingpatterns.com/command.html

var result: AttackResult = null
var start_pos : Vector3i
var end_pos : Vector3i

func execute(_state : GameState, _simulate_only : bool = false) -> void:
	pass;

func prepare(_state: GameState, _simulate_only : bool = false) -> void:
	pass;
	
func apply_damage(_state: GameState, _simulate_only: bool = false) -> void:
	pass;

func undo(_state : GameState, _simulate_only : bool = false) -> void:
	pass;
