extends Node


static func move_unit(start_pos : Vector3i, end_pos : Vector3i) -> void:
	pass;


static func set_objective_defeat_all() -> void:
	Main.battle_log.text = "Objective: Defeat all enemies";


static func set_objective_find_object(obect_name : String) -> void:
	Main.battle_log.text = "Objective: Find orb";


static func move_camera(pos : Vector3) -> void:
	pass
	#CameraManager.focus(pos)


static func spawn_enemy(type : String, pos : Vector3i) -> void:
	pass
	#UnitSpawner.spawn(type, pos)


#static func move_unit(unit_id : int, pos : Vector3i):
#	GameController.force_move(unit_id, pos)
