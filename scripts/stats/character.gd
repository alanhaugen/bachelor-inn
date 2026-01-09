extends Node3D
class_name Character
## This class has all the Character visuals
##
## Use this class to with a new scene for
## new characters and enemies

@export var data : CharacterData
@export var state : CharacterState

@export var sprite : Node3D
@export var portrait : Texture2D

#region: --- Unit Stats ---
## This dictates level progression, skills and compatible weapons
enum Speciality
{
	Generic,
	## This class has more movement than the other classes
	## allowing them to get to objectives or outrun enemies.
	## This could for example be a horse rider in a medieval
	## setting or a ranger in a fantasy setting
	Runner,
	## Most classes usually fall in this category in games
	## like fire emblem. If we want to use the sanity mechanic
	## for our game, then these units might have extra resistance
	## from sanity damage from battles
	Militia,
	## The classic healer/utility buffer. Their abilities do not
	## necessarily have to affect battles, they could improve
	## movement or conjure terrain.
	Scholar
}

enum Personality
{
	Normal,
	Zealot,
	Devoted,
	Young,
	Old,
	Jester,
	Therapist,
	Vindictive,
	Snob,
	Crashout,
	Grump,
	Determined,
	Silly,
	SmartAlec,
	HeroComplex,
	Vitriolic,
	Noble,
	Selfish,
	Tired,
	ExCultist,
	FactoryWorker,
	FactoryOwner
}

var camera: Camera3D;
var health_bar: HealthBar;
var level_up_popup: LevelUpPopUp;
var skill_choose_popup: SkillChoose;
var health_bar_ally: HealthBar;
var health_bar_enemy: HealthBar;

@onready var HEALTH_BAR_SCENE: PackedScene = preload("res://scenes/userinterface/health_bar.tscn");
@onready var ENEMY_HEALTH_BAR_SCENE: PackedScene = preload("res://scenes/userinterface/health_bar_enemy.tscn");
@onready var LEVEL_UP_POPUP: PackedScene = preload("res://scenes/userinterface/level_up.tscn");
@onready var SKILL_CHOOSE_POPUP: PackedScene = preload("res://scenes/userinterface/skill_choose.tscn");
@onready var SPRITE: PackedScene = preload("res://art/WIP/CharTest.tscn");

## dont think we need to pre load every weapon, but keeping this as is for now
const Weapon_Unarmed: Weapon = preload("res://data/weapons/Unarmed.tres");
const Weapon_Axe: Weapon = preload("res://data/weapons/Unarmed.tres");
const Weapon_Sword: Weapon = preload("res://data/weapons/Unarmed.tres");
const Weapon_Scepter: Weapon = preload("res://data/weapons/Unarmed.tres");
const Weapon_Spear: Weapon = preload("res://data/weapons/Unarmed.tres");
const Weapon_Bow: Weapon = preload("res://data/weapons/Unarmed.tres");


@export var is_playable :bool = true; ## Player unit or NPC
@export var is_enemy :bool = false; ## Friend or foe
@export var unit_name :String = "Baggins"; ## Unit name
@export var connections :Array = []; ## Connections to other players (how friendly they are to others)
@export var speciality :Speciality = Speciality.Militia; ## Unit speciality
@export var personality :Personality = Personality.Normal; ## Personality type, affects dialogue and loyalty to your commands

@export var health: int = 4; ## Unit health
@export var strength: int = 4; ## Damage with weapons
@export var mind: int = 4; ## Mind reduces sanity loss from combat or other events
@export var speed: int = 4; ## Speed is chance to Avoid = (Speed x 3 + Luck) / 2
#@export var agility: int = 4; ## Agility increases the evasion and hit rate of a unit
@export var focus: int = 4; ## Focus increases hit rate and crit rate of a unit. It also increases defense against sanity attacks

@export var endurance: int = 4; ## Endurance increases defense against physical and magic attacks. It also increases the health of the unit
@export var defense: int = 4; ## Lowers damage of weapon attacks
@export var resistence: int = 4; ## Lowers damage of magic attacks
@export var luck: int = 4; ## Affects many other skills
@export var intimidation: int = 4; ## How the unit affects sanity in battle.
@export var skill: int = 4; ## Chance to hit critical.
#@export var mana: int = 4; ## Amount of magic power
#@export var weapon: Weapon = null; ## Weapon held by unit
#endregion

#@export var experience : int  = 0 : set = _set_experience;
@export var skills : Array[Skill];

## made a func 'update_on_level_up' to update unit stats on level up.
var max_health: int = health + endurance + floor(strength / 2.0);
#var max_mana: int = mana + mind - current_sanity; ##placeholder composition
@export var movement: int = 4 + floor(speed / 3); ## Movement range
@export var current_health: int = max_health;
#@export var current_sanity: int = mind : set = _set_sanity;
#@export var current_mana: int = mana;
@export var current_level: int = 1;

var grid_position: Vector3i;

var next_level_experience: int = 1;

var is_alive: bool = true;

## Has move been done yet?
## Only attack commands will then be possible
var is_moved :bool = false; 

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


func clone() -> Character:
	var c := Character.new()
	c.data = data.duplicate_data()
	c.state = state.duplicate_data()
	return c


func _on_sanity_changed(in_sanity: int) -> void:
	#state.current_sanity = in_sanity
	if in_sanity > data.mind:
		in_sanity = data.mind
	#if (Main.battle_log):
	#	var dir := " loses ";
	#	if current_sanity < in_sanity:
	#		dir = " gains ";
	#	Main.battle_log.text = unit_name + dir + str(abs(current_sanity - in_sanity)) + " sanity\n" + Main.battle_log.text;
	#state.current_sanity = in_sanity
	if state.current_sanity < 0 and state.current_health > 0:
		state.faction = CharacterState.Faction.ENEMY
	#	Main.level.units_map.set_cell_item(grid_position, Main.level.enemy_code);
	#	Main.battle_log.text = unit_name +" has gone insane!\n" + Main.battle_log.text;
		data.unit_name = data.unit_name + "'cthulhu"
		health_bar = health_bar_enemy
	#	health_bar_ally.hide();
	#	health_bar_enemy.show();
	#if health_bar:
	#	update_health_bar();


func get_random_unaquired_skill(ignore_skill : Skill = null) -> Skill:
	var new_skill : Skill = null;
	var skill_lookup :Array[Skill] = SkillData.generic_skills;
	if data.speciality == CharacterData.Speciality.Runner:
		skill_lookup = SkillData.runner_skills;
	if data.speciality == CharacterData.Speciality.Militia:
		skill_lookup = SkillData.militia_skills;
	if data.speciality == CharacterData.Speciality.Scholar:
		skill_lookup = SkillData.scholar_skills;
	if skill_lookup.size() != state.skills.size():
		while new_skill == null or new_skill == ignore_skill:
			new_skill = skill_lookup[randi_range(0, SkillData.generic_skills.size() -1)];
	# If you sent in a skill to ignore, but no other skills were found, send back ignored skill
	if ignore_skill != null and new_skill == null:
		return ignore_skill;
	return new_skill;


func _on_experience_changed(in_experience: int) -> void:
	#data.experience += in_experience;
	print(data.unit_name + " gains " + str(in_experience) + " experience points.");
	if (state.experience > state.next_level_experience):
		print("Level up!");
		state.current_level += 1;
		if (data.speciality == CharacterData.Speciality.Militia):
			if (state.next_level_experience >= 10):
				data.health += 1;
				data.mind += 1;
			if (state.next_level_experience >= 100):
				data.health += 1;
				data.mind += 1;
			if (state.next_level_experience >= 1000):
				data.luck += 1;
				data.skill += 1;
		
		state.next_level_experience *= 10;
		calibrate_level_popup();
		level_up_popup.show();
		Main.level.is_in_menu = true;
		
		var new_skill_1 : Skill = get_random_unaquired_skill();
		var new_skill_2 : Skill = get_random_unaquired_skill(new_skill_1);
		
		if new_skill_1 != null:
			skill_choose_popup.unit = self;
			
			skill_choose_popup.icon_1.texture = new_skill_1.icon;
			skill_choose_popup.skill_name_1.text = new_skill_1.skill_name;
			skill_choose_popup.label_skill_1.text = new_skill_1.tooltip;
			skill_choose_popup.first_skill = new_skill_1;
			skill_choose_popup.icon_2.texture = new_skill_2.icon;
			skill_choose_popup.skill_name_2.text = new_skill_2.skill_name;
			skill_choose_popup.label_skill_2.text = new_skill_2.tooltip;
			skill_choose_popup.second_skill = new_skill_2;
			skill_choose_popup.show();


func recalc_derived_stats() -> void:
	## Derived from data only - safe to call after level up, after data changes, after load etc..
	state.max_health = data.health + data.endurance + floor(data.strength / 2.0)
	state.movement = 4 + floor(data.speed / 3.0)

	# Optional: clamp current values so they remain valid
	state.current_health = clamp(state.current_health, 0, state.max_health)
	state.current_mana = max(state.current_mana, 0)
	state.current_sanity = clamp(state.current_sanity, 0, 100)


func init_current_stats_full() -> void:
	## For new units only
	recalc_derived_stats()
	state.current_health = state.max_health
	state.current_sanity = data.mind
	state.current_mana = data.mana
	
	
func update_health_bar() -> void:
	health_bar.health = state.current_health;
	health_bar.sanity = state.current_sanity;
	health_bar.name_label = data.unit_name;


func calibrate_level_popup() -> void:
	level_up_popup.health = data.health;
	level_up_popup.focus = data.focus;
	level_up_popup.level = state.current_level;
	level_up_popup.mind = data.mind;
	level_up_popup.movement = state.movement;
	level_up_popup.speed = data.speed;
	level_up_popup.strength = data.strength;
	#level_up_popup.agility = agility;


func _ready() -> void:
	if state:
		state.sanity_changed.connect(_on_sanity_changed)
		state.experience_changed.connect(_on_experience_changed)
	
	health_bar_ally = HEALTH_BAR_SCENE.instantiate();
	health_bar_enemy = ENEMY_HEALTH_BAR_SCENE.instantiate();
	add_child(health_bar_ally);
	add_child(health_bar_enemy);
	health_bar_ally.hide();
	health_bar_enemy.hide();
	
	recalc_derived_stats();
	## might not be pretty,, but need something for new units
	if state.current_health <= 0 and state.current_mana <= 0 and state.current_sanity <= 0:
		init_current_stats_full()

	#ensure_weapon_equipped()
	#state.max_health = data.health + data.endurance + floor(data.strength / 2.0);
	#state.movement = 4 + floor(data.speed / 3.0); ## Movement range
	#state.current_health = state.max_health;
	#state.current_sanity = data.mind;
	#state.current_mana = data.mana;
	
	#if personality == Personality.Zealot:
	#	skills.append(generic_skills[0]);
	#state.skills.append(SkillData.all_skills[data.speciality][data.personality % (SkillData.all_skills[data.speciality].size() - 1)]);
	#abilities.append(abilites[0]);
	#func init_starting_skill_once() -> void:
	if state.skills.is_empty():
		state.skills.append(SkillData.all_skills[data.speciality][data.personality % 
			(SkillData.all_skills[data.speciality].size() - 1)])
	
	if state.is_playable():
		health_bar = health_bar_ally;
	else:
		health_bar = health_bar_enemy;
		state.faction = CharacterState.Faction.ENEMY;
	
	level_up_popup = LEVEL_UP_POPUP.instantiate();
	add_child(level_up_popup);
	level_up_popup.hide();
	level_up_popup.name_label = data.unit_name;
	calibrate_level_popup();
	
	skill_choose_popup = SKILL_CHOOSE_POPUP.instantiate();
	add_child(skill_choose_popup);
	skill_choose_popup.text = data.unit_name + ", " + CharacterData.Speciality.keys()[data.speciality];
	skill_choose_popup.hide();
	
	sprite = SPRITE.instantiate();
	
	sprite.translate(Vector3(0,0.8,-0.4));
	sprite.rotate(Vector3(1,0,0), deg_to_rad(-60));
	sprite.scale = Vector3(4,4,4);
	
	camera = get_viewport().get_camera_3d();
	update_health_bar();
	
	add_child(sprite);


func _process(_delta: float) -> void:
	var mesh_3d_position: Vector3 = global_transform.origin;
	
	if state.is_alive:
		show_ui(); # hack, TODO: removeme
	
	if camera:
		var screen_position_2d: Vector2 = camera.unproject_position(mesh_3d_position + Vector3(0, 1, 0))
		health_bar.position = screen_position_2d - Vector2(3 * 7, 0);
		health_bar.position.y += 70; # move down a little 


func hide_ui() -> void:
	health_bar.hide();


func show_ui() -> void:
	health_bar.show();


func move_to(pos: Vector3i, simulate_only: bool = false) -> void:
	if simulate_only == false:
		Main.level.units_map.set_cell_item(state.grid_position, GridMap.INVALID_CELL_ITEM);
	
	state.is_alive = true;
	#reset();
	state.grid_position = pos;
	state.is_moved = true;
	
	if simulate_only == false:
		var grid_code := Main.level.player_code_done;
		if state.is_enemy():
			grid_code = Main.level.enemy_code;
		Main.level.units_map.set_cell_item(state.grid_position, grid_code);
	#if is_playable:
	#	sprite.modulate = Color(0.338, 0.338, 0.338, 1.0);


func reset() -> void:
	state.is_alive = true;
	# slowly heal sanity
	if state.is_playable():
		state.current_sanity += 1;
	hide_ui();
	show();
	state.is_moved = false;
#	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0);


func die(simulate_only : bool) -> void:
	if state.is_alive == false:
		push_error("Killing already dead unit");
	
	state.is_alive = false;
	
	if simulate_only == false:
		hide_ui();
		hide();
		Main.level.units_map.set_cell_item(state.grid_position, GridMap.INVALID_CELL_ITEM);
	
	state.grid_position = Vector3(-100, -100, -100);


func print_stats() -> void:
	print(save());
	

func update_on_level_up() -> void:
	update_max_health();
	#update_sanity();

func update_max_health() -> int:
	return health + endurance + floor(strength / 2.0);

#func update_sanity() -> int:
	#return current_sanity + floor(mind/4);
	
func get_default_weapon_id() -> String:
	match data.speciality:
		CharacterData.Speciality.Militia:
			return "sword_basic";
		CharacterData.Speciality.Runner:
			return "bow_basic";      # temporarily melee range for bow 
		CharacterData.Speciality.Scholar:
			return "scepter_basic";
		_:
			return "unarmed";
			
func ensure_weapon_equipped() -> void:
	if state == null:
		return;
	if state.weapon_id == "" or WeaponRegistry.get_weapon(state.weapon_id) == null:
		state.weapon_id = get_default_weapon_id();
		#weapon = WeaponRegistry.get_weapon(get_default_weapon_id())

func get_weapon() -> Weapon:
	ensure_weapon_equipped();
	return WeaponRegistry.get_weapon(state.weapon_id);

func can_attack() -> bool:
	return true;

func can_use_weapon(w: Weapon) -> bool:
	return true;
	
func get_max_attack_range() -> int:
	return get_weapon().max_range;


func save() -> Dictionary:
	var stats := {
		"Is Playable": is_playable,
		"Unit name": unit_name,
		"Speciality": speciality,
		
		"Health": health,
		"Strength": strength,
		"Movement": movement,
		"Mind": mind,
		"Speed": speed,
		#"Agility": agility,
		"Focus": focus,
		
		"Endurance": endurance,
		"Defense": defense,
		"Resistence": resistence,
		"Luck": luck,
		"Intimidation": intimidation,
		"Skill": skill,
		#"Mana": mana,
		
		#"Experience": experience,
		"Next level experience": next_level_experience,
		"Current level": current_level,
		"Current health": current_health,
		#"Current mana": current_mana,
		#"Current sanity": current_sanity,
		"Weapon ID": get_weapon().weapon_id
}

	return {
		"data": data.save(),
		"state": state.save()
	}
