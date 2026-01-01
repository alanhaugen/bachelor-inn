extends Node


static func move_unit(start_pos : Vector3i, end_pos : Vector3i) -> void:
	pass;


static func set_objective_defeat_all() -> void:
	Main.battle_log.text = "Objective: Defeat all enemies";


static func set_objective_find_object(obect_name : String) -> void:
	Main.battle_log.text = "Objective: Find orb";
