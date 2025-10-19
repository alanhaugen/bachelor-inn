class_name unit extends Node

enum Speciality
{
	Magician,
	Archer,
	Fighter
}

# Here are the properties of a unit

@export var isPlayable :bool = true;
@export var unitName :String = "Believer"; ## Unit health
@export var speciality :Speciality = Speciality.Fighter;

@export var health :int     = 3; ## Unit health
@export var skill :int      = 3; ## Chance to hit critical.
@export var strength :int   = 3; ## Damage with weapons
@export var magic :int      = 3; ## Damage with magic
@export var luck  :int      = 3; ## Affects many other skills
@export var speed :int      = 3; ## Speed is chance to Avoid = (Speed x 3 + Luck) / 2
@export var movement :int   = 3; ## Movement range
@export var defense :int    = 3; ## Lowers damage of weapon attacks
@export var resistence :int = 3; ## Lowers damage of magic attacks

# Hit = [(Skill x 3 + Luck) / 2] + Weapon Hit Rate
# Crit = (Skill / 2) + Weapon's Critical

func attack() -> void:
	pass;

func move() -> void:
	pass;
