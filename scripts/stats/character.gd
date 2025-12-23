class_name Character
extends Node3D
## This class has all the Character stats and visuals
##
## Use this class to make new units and enemies for the game

const SPRITE = preload("res://art/WIP/CharTest.tscn");

var sprite: Node3D;
var portrait: Texture2D;

#region: --- Unit Stats ---
## This dictates level progression, skills and compatible weapons
enum Speciality
{
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
	Grmp,
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
var health_bar_ally: HealthBar;
var health_bar_enemy: HealthBar;

@onready var HEALTH_BAR_SCENE: PackedScene = preload("res://scenes/ui/health_bar.tscn");
@onready var ENEMY_HEALTH_BAR_SCENE: PackedScene = preload("res://scenes/ui/health_bar_enemy.tscn");
@onready var LEVEL_UP_POPUP: PackedScene = preload("res://scenes/ui/level_up.tscn");


@export var is_playable :bool = true; ## Friend or foe
@export var unit_name :String = "Baggins"; ## Unit name
@export var connections :Array = []; ## Connections to other players (how friendly they are to others)
@export var speciality :Speciality = Speciality.Militia; ## Unit speciality
@export var personality :Personality = Personality.Normal; ## Personality type, affects dialogue and loyalty to your commands
@export var sprite_sheet_path: String = "res://art/textures/WIP_Animation_previewer.png";

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
@export var magic: int = 4; ## Damage with magic
@export var weapon: Weapon = null; ## Weapon held by unit
#endregion

@export var experience : int  = 0 : set = _set_experience;
@export var skills : Array[Skill];

var max_health: int = health + endurance + floor(strength / 2.0);
@export var movement: int = 4 + floor(speed / 3); ## Movement range
@export var current_health: int = max_health;
@export var current_sanity: int = mind : set = _set_sanity;
@export var current_magic: int = magic;
@export var current_level: int = 1;

var grid_position: Vector3i;

var next_level_experience: int = 10;

var is_alive: bool = true;

## Has move been done yet?
## Only attack commands will then be possible
var is_moved :bool = false; 

## SKILL TREE


func _close_level_up() -> void:
	pass;


func _set_sanity(in_sanity: int) -> void:
	if in_sanity > mind:
		in_sanity = mind;
	if (Main.battle_log):
		var dir := " loses ";
		if current_sanity < in_sanity:
			dir = " gains ";
		Main.battle_log.text = unit_name + dir + str(abs(current_sanity - in_sanity)) + " sanity\n" + Main.battle_log.text;
	current_sanity = in_sanity;
	if current_sanity < 0 and current_health > 0:
		is_playable = false;
		Main.level.units_map.set_cell_item(grid_position, Main.level.enemy_code);
		Main.battle_log.text = unit_name +" has gone insane!\n" + Main.battle_log.text;
		unit_name = unit_name + "'cthulhu";
		health_bar = health_bar_enemy;
		health_bar_ally.hide();
		health_bar_enemy.show();
	if health_bar:
		update_health_bar();


func _set_experience(in_experience: int) -> void:
	experience += in_experience;
	print(unit_name + " gains " + str(in_experience) + " experience points.");
	if (experience > next_level_experience):
		print("Level up!");
		current_level += 1;
		if (speciality == Speciality.Militia):
			if (next_level_experience >= 10):
				health += 1;
				mind += 1;
			if (next_level_experience >= 100):
				health += 1;
				mind += 1;
			if (next_level_experience >= 1000):
				luck += 1;
				skill += 1;
		
		next_level_experience *= 10;
		calibrate_level_popup();
		level_up_popup.show();


func update_health_bar() -> void:
	health_bar.health = current_health;
	health_bar.sanity = current_sanity;
	health_bar.name_label = unit_name;


func calibrate_level_popup() -> void:
	level_up_popup.health = health;
	level_up_popup.focus = focus;
	level_up_popup.level = current_level;
	level_up_popup.mind = mind;
	level_up_popup.movement = movement;
	level_up_popup.speed = speed;
	level_up_popup.strength = strength;
	#level_up_popup.agility = agility;


func _ready() -> void:
	health_bar_ally = HEALTH_BAR_SCENE.instantiate();
	health_bar_enemy = ENEMY_HEALTH_BAR_SCENE.instantiate();
	add_child(health_bar_ally);
	add_child(health_bar_enemy);
	health_bar_ally.hide();
	health_bar_enemy.hide();
	
	if is_playable:
		health_bar = health_bar_ally;
	else:
		health_bar = health_bar_enemy;
	
	level_up_popup = LEVEL_UP_POPUP.instantiate();
	add_child(level_up_popup);
	level_up_popup.hide();
	level_up_popup.name_label = unit_name;
	calibrate_level_popup();
	
	sprite = SPRITE.instantiate();
	
	#sprite.sprite_frames = SpriteFrames.new();
	#sprite.sprite_frames.add_animation("idle");
	#sprite.sprite_frames.add_animation("walk_side");
	#sprite.sprite_frames.add_animation("walk_down");
	#sprite.sprite_frames.add_animation("walk_up");
	
	#var frame_count := 6; # Number of frames in your "idle" animation
	#var frame_width := 32; # Width of each individual sprite frame
	#var frame_height := 32; # Height of each individual sprite frame
	
	#if speciality == Speciality.Scout:
	#var texture: Texture2D = load(sprite_sheet_path);
	#var region_to_extract := Rect2(0, 0, frame_width, frame_height);
	#portrait = AtlasTexture.new();
	#portrait.atlas = texture;
	#portrait.region = region_to_extract;
	
	# Add idle animation
	#for i in range(frame_count):
	#	var atlas := AtlasTexture.new();
	#	atlas.atlas = texture;
	#	atlas.region = Rect2((i+2) * frame_width, 0, frame_width, frame_height);
	#	sprite.sprite_frames.add_frame("idle", atlas);
	
	# Add walk sideways animation
	#for i in range(frame_count):
	#	var atlas := AtlasTexture.new();
	#	atlas.atlas = texture;
	#	atlas.region = Rect2(i * frame_width, frame_width, frame_width, frame_height);
	#	sprite.sprite_frames.add_frame("walk_side", atlas);
	
	# Add walk down animation
	#for i in range(frame_count):
	#	var atlas := AtlasTexture.new();
	#	atlas.atlas = texture;
	#	atlas.region = Rect2(i * frame_width, frame_width * 2, frame_width, frame_height);
	#	sprite.sprite_frames.add_frame("walk_up", atlas);
	
	# Add walk up animation
	#for i in range(frame_count):
	#	var atlas := AtlasTexture.new();
	#	atlas.atlas = texture;
	#	atlas.region = Rect2(i * frame_width, frame_width * 3, frame_width, frame_height);
	#	sprite.sprite_frames.add_frame("walk_down", atlas);
	
	#sprite.play("idle");
	
	#translate(Vector3(0,0.736,-0.463));
	sprite.translate(Vector3(0,0.8,-0.4));
	sprite.rotate(Vector3(1,0,0), deg_to_rad(-60));
	sprite.scale = Vector3(4,4,4);
	
	camera = get_viewport().get_camera_3d();
	update_health_bar();
	
	add_child(sprite);


func _process(_delta: float) -> void:
	var mesh_3d_position: Vector3 = global_transform.origin;
	
	if is_alive:
		show_ui(); # hack, TODO: removeme
	
	if camera:
		var screen_position_2d: Vector2 = camera.unproject_position(mesh_3d_position + Vector3(0, 1, 0))
		health_bar.position = screen_position_2d - Vector2(3 * 7, 0);
		health_bar.position.y += 70; # move down a little 


func hide_ui() -> void:
	health_bar.hide();


func show_ui() -> void:
	health_bar.show();


func move_to(pos: Vector3i) -> void:
	is_alive = true;
	#reset();
	grid_position = pos;
	#if is_playable:
	#	sprite.modulate = Color(0.338, 0.338, 0.338, 1.0);


func reset() -> void:
	is_alive = true;
	# slowly heal sanity
	if is_playable:
		current_sanity += 1;
	hide_ui();
	show();
	is_moved = false;
#	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0);


func die() -> void:
	is_alive = false;
	hide_ui();
	hide();
	grid_position = Vector3(-100, -100, -100);


func print_stats() -> void:
	print(save());


func save() -> Dictionary:
	var stats := {
		"Is Playable": is_playable,
		"Sprite sheet path": sprite_sheet_path,
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
		"Magic": magic,
		
		"Experience": experience,
		"Next level experience": next_level_experience,
		"Current level": current_level,
		"Current health": current_health,
		"Current magic": current_magic,
		"Current sanity": current_sanity
	}
	
	return stats;
