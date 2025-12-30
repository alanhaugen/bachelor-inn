class_name Attack
extends Command

var pos : Vector3i;
var end_pos : Vector3i;
var attacker : Character;
var victim : Character;

func _init(inStartPos : Vector3i, in_attacker : Character, in_victim : Character) -> void:
	pos = inStartPos;
	end_pos = pos;
	attacker = in_attacker;
	victim = in_victim;
