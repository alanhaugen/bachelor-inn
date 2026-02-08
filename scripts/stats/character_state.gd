extends Resource
class_name CharacterState
## CharacterSate is pure state information.
## No scene or node access should happen here.

#region enums
enum Faction
{
	PLAYER,
	ENEMY,
	NEUTRAL
}

enum UnitPhase
{
	READY,      # Can move
	MOVED,      # Can act
	DONE        # Turn over
}

enum SanityState
{
	CALM, # clear-minded
	UNEASY, # doubt
	DISTORTED, # focus
	OBSESSED, # fear
	DISSOCIATED # delusion
}
#endregion

#region signals
signal sanity_changed(new_value: int)
signal experience_changed(new_value: int)
signal level_changed(new_level: int)
#endregion

#region variables
@export var weapon : Weapon = WeaponRegistry.get_weapon("unarmed");

@export var faction : Faction = Faction.PLAYER;
@export var connections : Array[int] = [];

@export var next_level_experience: int = 1;
@export var experience := 0 : set = _set_experience
@export var level := 1
@export var skills: Array[Skill] = []

var grid_position: Vector3i;
var is_alive: bool = true;
var phase: UnitPhase = UnitPhase.READY
#endregion

#region inferred vars calculated from CharacterData on spawn
@export var max_health : int
@export var max_sanity : int
@export var movement : int
@export var current_health : int
@export var current_sanity : int : set = _set_sanity
@export var current_level : int = 1
@export var stability : int
@export var defense : int
@export var resistance : int
#endregion


#region methods
func is_ally(in_faction: Faction = Faction.PLAYER) -> bool:
	return faction == in_faction;


func is_enemy() -> bool:
	return faction == Faction.ENEMY;


func is_playable() -> bool:
	return faction == Faction.PLAYER;


func duplicate_data() -> CharacterState:
	return duplicate(true);


func _set_sanity(value: int) -> void:
	current_sanity = clamp(value, 0, max_sanity)
	sanity_changed.emit(current_sanity)


func _set_experience(value: int) -> void:
	experience = max(value, 0)

	if experience >= next_level_experience:
		experience -= next_level_experience
		level += 1
		level_changed.emit(level)

	experience_changed.emit(experience)


func get_sanity_state() -> SanityState:
	var sanity := (float(current_sanity) / max_sanity) * 100.0
	
	if sanity >= 80:
		return SanityState.CALM
	elif sanity >= 60:
		return SanityState.UNEASY
	elif sanity >= 40:
		return SanityState.DISTORTED
	elif sanity >= 20:
		return SanityState.OBSESSED
	else:
		return SanityState.DISSOCIATED


func save() -> Dictionary:
	return {
		"faction": faction,
		"grid_position": [grid_position.x, grid_position.y, grid_position.z],
		"is_alive": is_alive,
		"phase": phase,
		"experience": experience,
		"level": level,
		"current_health": current_health,
		"current_sanity": current_sanity,
		"weapon_id": weapon.weapon_id
	}
#endregion
