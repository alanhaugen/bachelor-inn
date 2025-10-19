extends Node2D

var health :int; 	 # Unit health
var strength :int;	 # Damage with weapons
var magic :int;		 # Damage with magic
var luck  :int;		 # Affects many other skills
var speed :int;		 # Speed is chance to Avoid = (Speed x 3 + Luck) / 2
var movement :int;
var defense :int;    # Lowers damage of weapon attacks
var resistence :int; # Lowers damage of magic attacks

# Hit = [(Skill x 3 + Luck) / 2] + Weapon Hit Rate
# Crit = (Skill / 2) + Weapon's Critical
var skill :int;		# Chance to hit critical.

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
