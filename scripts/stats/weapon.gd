extends Resource
class_name Weapon 

## ID
@export var weapon_id : String;
@export var weapon_name : String;
@export var weapon_tooltip : String;
@export var weapon_icon : Texture2D;


## STATS
@export var damage_modifier: int = 1; ## Additional damage 
@export var weapon_critical: int = 1;
@export var min_range: int = 1;
@export var max_range: int = 1;
@export var accuracy: int = 1;


## BOOLS (if we want to implement restrictions etc. later)
@export var uses_action: bool = true;
@export var requires_wep_skill: bool = false; ## Feks. polearm training etc.
@export var requires_skill_tag: bool = false; ## Må ikke være skill. Kan være class specific etc. 
@export var is_melee: bool = false;



func in_range(distance: int) -> bool:
	return distance >= min_range and distance <= max_range;
