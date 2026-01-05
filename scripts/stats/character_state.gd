extends Resource
class_name CharacterState

#region enums
enum Faction { PLAYER, ENEMY, NEUTRAL };
#endregion

#region variables
@export var weapon : Weapon = null; ## Weapon held by unit

@export var faction : Faction = Faction.PLAYER;
@export var connections : Array[int] = [];

@export var grid_position: Vector3i;
@export var next_level_experience: int = 1;
@export var is_alive: bool = true;
@export var is_moved :bool = false;
@export var experience := 0
@export var level := 1
@export var skills: Array[Skill] = []
#endregion

#region inferred vars calculated from CharacterData on spawn
@export var max_health : int;
@export var movement : int;
@export var current_health : int;
@export var current_sanity : int;
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
