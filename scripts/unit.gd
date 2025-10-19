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
