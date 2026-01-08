extends Resource
class_name Weapon 

## Weapons are just data, which is why we extend Resource.
## Should match attack functionality (will probably have ranged attack as separate script)

## ID
@export var weapon_id : String;
@export var weapon_name : String;
@export var text_tooltip : String; ## weapon description for hoover over etc.
@export var icon : Texture2D;
#@export var weapon_type: String;
#enum WeaponType { SWORD, AXE, SPEAR, BOW, SCEPTER, UNARMED }
#@export var weapon_type: WeaponType = WeaponType.SWORD

## Stats
@export var damage_modifier: int = 1;
@export var weapon_critical: int = 1;
@export var accuracy: int = 1;
@export var min_range: int = 1;
@export var max_range: int = 1;

## Bools
#@export var is_melee: bool = true;				## might be redundant due to min_ max_range
@export var uses_action:  bool = true; 			## if we want abilities that allows for more actions
@export var requires_wep_skill: bool = false; 	## Ex. need polearm training to use polearm
@export var requires_skill_tag: bool = false; 	## Ex. 

## Probably shouldnt have commands inside here
#var command : Command;

func is_melee() -> bool:
	return max_range <= 1;

func in_range(distance: int) -> bool:
	return distance >= min_range and distance <= max_range;
	
## might come in handy
static func manhattan(a: Vector3i, b: Vector3i) -> int:
	return abs(a.x - b.x) + abs(a.z - b.z);

@export var damage_modifier: int = 1;
@export var weapon_critical: int = 1;
@export var is_melee: bool = false;
