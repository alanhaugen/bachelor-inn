extends Resource
class_name CharacterState

#region enums
enum Faction { PLAYER, ENEMY, NEUTRAL };
#endregion

#region signals
signal sanity_changed(new_value: int)
signal experience_changed(new_value: int)
signal level_changed(new_level: int)
#endregion

#region variables
@export var weapon : Weapon = null; ## Weapon held by unit

@export var faction : Faction = Faction.PLAYER;
@export var connections : Array[int] = [];

@export var grid_position: Vector3i;
@export var next_level_experience: int = 1;
@export var is_alive: bool = true;
@export var is_moved :bool = false;
@export var experience := 0 : set = _set_experience
@export var level := 1
@export var skills: Array[Skill] = []
#endregion

#region inferred vars calculated from CharacterData on spawn
@export var max_health : int;
@export var movement : int;
@export var current_health : int;
@export var current_sanity : int : set = _set_sanity;
@export var current_mana: int;
@export var current_level: int = 1;
#endregion


#region methods
func is_enemy() -> bool:
	return faction == Faction.ENEMY;


func is_playable() -> bool:
	return faction == Faction.PLAYER;


func duplicate_data() -> CharacterState:
	return duplicate(true);


func _set_sanity(value: int) -> void:
	current_sanity = clamp(value, 0, 999)
	sanity_changed.emit(current_sanity)


func _set_experience(value: int) -> void:
	experience = max(value, 0)

	if experience >= next_level_experience:
		experience -= next_level_experience
		level += 1
		level_changed.emit(level)

	experience_changed.emit(experience)


func save() -> Dictionary:
	return {
		"faction": faction,
		"grid_position": [grid_position.x, grid_position.y, grid_position.z],
		"is_alive": is_alive,
		"is_moved": is_moved,
		"experience": experience,
		"level": level,
		"current_health": current_health,
		"current_sanity": current_sanity,
		"current_mana": current_mana
	}
#endregion
