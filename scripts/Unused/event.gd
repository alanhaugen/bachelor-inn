extends Node


static func move_unit(_start_pos : Vector3i, _end_pos : Vector3i) -> void:
	pass;


static func set_objective_defeat_all() -> void:
	Main.battle_log.text = "Objective: Defeat all enemies";


static func set_objective_find_object(_obect_name : String) -> void:
	Main.battle_log.text = "Objective: Find orb";


static func move_camera(_pos : Vector3) -> void:
	pass
	#CameraManager.focus(pos)


static func spawn_enemy(_type : String, _pos : Vector3i) -> void:
	pass
	#UnitSpawner.spawn(type, pos)


#static func move_unit(unit_id : int, pos : Vector3i):
#	GameController.force_move(unit_id, pos)
