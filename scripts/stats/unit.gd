class_name Character extends Node
## This class has all the Character stats and visuals
##
## Use this class to make new units and enemies for the game

#region: --- Unit Stats ---
## This dictates level progression, skills and compatible weapons
enum Speciality
{
	## This class has more movement than the other classes
	## allowing them to get to objectives or outrun enemies
	Scout,
	## Most classes usually fall in this category in games
	## like fire emblem. If we want to use the sanity
	## mechanic for our game, then these units might have
	## extra resistance from sanity damage from battles.
	Support,
	## The classic healer/utility buffer. Their abilities
	## do not necessarily have to affect battles, they
	## could improve movement or conjure terrain.
	Fighter
}

@onready var camera: Camera3D;
@onready var character: AnimatedSprite3D = $Character
@onready var health_bar: ColorRect = %HealthBar

@export var is_playable :bool = true; ## Friend or foe
@export var unit_name :String = "Bernard Grunderburger"; ## Unit name
@export var speciality :Speciality = Speciality.Fighter; ## Unit speciality

@export var health :int       = 4;    ## Unit health
@export var movement :int     = 4;    ## Movement range
@export var mind :int         = 4;    ## Mind reduces sanity loss from combat or other events
@export var defense :int      = 4;    ## Lowers damage of weapon attacks
@export var resistence :int   = 4;    ## Lowers damage of magic attacks
@export var luck  :int        = 4;    ## Affects many other skills
@export var intimidation :int = 4;    ## How the unit affects sanity in battle.
@export var skill :int        = 4;    ## Chance to hit critical.
@export var strength :int     = 4;    ## Damage with weapons
@export var magic :int        = 4;    ## Damage with magic
@export var speed :int        = 4;    ## Speed is chance to Avoid = (Speed x 3 + Luck) / 2
@export var weapon :Weapon    = null; ## Weapon held by unit
#endregion

@export var experience : int  = 0;
@export var skills : Array[Skill];

@export var spawn_location :Vector3i; ## Where the unit will spawn

@export var current_health: int = health;
@export var current_sanity: int = mind;
@export var grid_position: Vector3i;

## SKILL TREE


func _ready() -> void:
	camera = get_viewport().get_camera_3d();
	health_bar.health = current_health;
	health_bar.sanity = current_sanity;
	health_bar.name_label = unit_name;


func _process(_delta: float) -> void:
	var mesh_3d_position: Vector3 = character.global_transform.origin;
	
	if camera:
		var screen_position_2d: Vector2 = camera.unproject_position(mesh_3d_position + Vector3(0, 1, 0))
		health_bar.position = screen_position_2d - Vector2(150, 0);


func hide_ui() -> void:
	health_bar.hide();


func show_ui() -> void:
	health_bar.show();


func move_to(pos: Vector3i) -> void:
	hide_ui();
	grid_position = pos;
	character.modulate = Color(0.338, 0.338, 0.338, 1.0);


func reset() -> void:
	character.modulate = Color(1.0, 1.0, 1.0, 1.0);


# Hit = [(Skill x 3 + Luck) / 2] + Weapon Hit Rate
# Crit = (Skill / 2) + Weapon's Critical

var units: = {
	"Withburn, the Cleric": 
	{
		"name": "Withburn",
		"speciality": "Magican",
		"unit_type": "Playble",
		"texture referance": "res://art/WithburnSpriteSheet",
		"stats": 
			{
				"hp": 15, 
				"max_hp": 15,
				"strenght": 5, 
				"magic": 10,
				"skill": 10, 
				"speed": 5,
				"defence": 8, 
				"resistance": 8,
				"movement": 5, 
				"luck": 5
			},
		"level_up_stats":
			{
				"max_hp": 2,
				"strenght": 1, 
				"magic": 3,
				"skill": 1, 
				"speed": 1,
				"defence": 1, 
				"resistance": 2,
				"movement": 0, 
				"luck": 1
			},
			
		"weapon": "Staff of the Generic",
		"level": 1,
		"experience": 0
	},
	"Fen, the Warrior": 
	{
		"name": "Fen",
		"speciality": "Fighter",
		"unit_type": "Playble",
		"texture referance": "res://art/FenSpriteSheet",
		"stats": 
			{
				"hp": 20, 
				"max_hp": 20,
				"strenght": 15, 
				"magic": 3,
				"skill": 10, 
				"speed": 7,
				"defence": 12, 
				"resistance": 4,
				"movement": 6, 
				"luck": 4
			},
		"level_up_stats":
			{
				"max_hp": 2,
				"strenght": 2, 
				"magic": 1,
				"skill": 1, 
				"speed": 1,
				"defence": 2, 
				"resistance": 1,
				"movement": 0, 
				"luck": 1
			},
			
		"weapon": "Sword of the Generic",
		"level": 1,
		"experience": 0
	},
	"bandit": 
	{
		"name": "bandi",
		"speciality": "Fighter",
		"unit_type": "Enemy",
		"texture referance": "res://art/BanditSpriteSheet",
		"stats": 
			{
				"hp": 10, "max_hp": 10,
				"strenght": 8, "magic": 1,
				"skill": 4, "speed": 4,
				"defence": 6, "resistance": 6,
				"movement": 5, "luck": 2
			},
		"level_up_stats":
			{
				"max_hp": 2,
				"strenght": 1, "magic": 3,
				"skill": 1, "speed": 1,
				"defence": 1, "resistance": 2,
				"movement": 0, "luck": 1
			},
			
		"weapon": "Club of the Generic",
		"level": 1,
		"experience": 0
	}
}
