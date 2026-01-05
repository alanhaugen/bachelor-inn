extends Resource
class_name SkillData


var generic_skills :Array[Skill] = [
	Skill.new("Spear training", "Enables wielding of Spear type weapons", load("res://art/textures/M_Orb.png"), 0, 1, null),
	Skill.new("Adrenaline", "The first time health is lost each combat, double movement and attack on the next turn", load("res://art/textures/M_Orb.png"), 0, 1, null),
	Skill.new("Precision	", "Damage does not vary (damage done = ¾ maxdamage + ¼ mindamage)", load("res://art/textures/M_Orb.png"), 0, 1, null)
]

var runner_skills :Array[Skill] = [
	Skill.new("Trailblazer", "After moving through negative terrain, the terrain effects are disabled until end of turn", load("res://art/textures/M_Orb.png"), 0, 1, null),
	Skill.new("Fleet foot", "Unaffected by negative terrain", load("res://art/textures/M_Orb.png"), 0, 1, null),
	Skill.new("Trapper", "A new action which turns a 2x2 area into negative terrain", load("res://art/textures/M_Orb.png"), 0, 1, null),
	Skill.new("Archery", "Enables wielding of Bow & Arrow", load("res://art/textures/M_Orb.png"), 0, 1, null),
	Skill.new("Pivot", "Allows you to move again with remaining movement after using an action", load("res://art/textures/M_Orb.png"), 0, 1, null)
]

var militia_skills :Array[Skill] = [
	Skill.new("Fighting Cause", "Lose 50% less sanity from battling horrors", load("res://art/textures/M_Orb.png"), 0, 1, null),
	Skill.new("Heavy weapons training", "Can use heavy weapons (big axe, big hammer, big stick)", load("res://art/textures/M_Orb.png"), 0, 1, null),
	Skill.new("Obstructor", "Enemies cannot move out of tiles adjacent to this character", load("res://art/textures/M_Orb.png"), 0, 1, null),
	Skill.new("Enhanced constitution", "Regains 1 health at the start of each turn. Gains additional Endurance", load("res://art/textures/M_Orb.png"), 0, 1, null),
]

var scholar_skills :Array[Skill] = [
	Skill.new("Console", "A new ability which restores sanity to an adjacent ally. Half of the sanity restored is lost by this unit", load("res://art/textures/M_Orb.png"), 1, 5, null),
	Skill.new("Firearms enthusiast", "Enables wielding of firearms", load("res://art/textures/M_Orb.png"), 0, 1, null),
	Skill.new("Pyrochemistry", "Gains 2 improvised explosives for each combat which can be used for a ranged attack", load("res://art/textures/M_Orb.png"), 0, 1, null),
	Skill.new("Medicine", "A new ability which gives an adjacent ally healing for the next 3 turns. This is removed if the ally enters combat", load("res://art/textures/M_Orb.png"), 0, 1, null)
]

var all_skills :Array[Array] = [
	generic_skills,
	runner_skills,
	militia_skills,
	scholar_skills
];
