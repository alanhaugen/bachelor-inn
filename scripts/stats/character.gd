class_name Character
extends Node3D
## This class has all the Character stats and visuals
##
## Use this class to make new units and enemies for the game

var sprite: AnimatedSprite3D;

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
var health_bar: ColorRect;
@onready var HEALTH_BAR_SCENE: PackedScene = preload("res://scenes/ui/health_bar.tscn");

@export var is_playable :bool = true; ## Friend or foe
@export var unit_name :String = "Baggins"; ## Unit name
@export var speciality :Speciality = Speciality.Fighter; ## Unit speciality
@export var sprite_sheet_path: String = "res://art/textures/WIP_Animation_previewer.png";

@export var health: int = 4; ## Unit health
@export var strength: int = 4; ## Damage with weapons
@export var movement: int = 4; ## Movement range
@export var mind: int = 4; ## Mind reduces sanity loss from combat or other events
@export var speed: int = 4; ## Speed is chance to Avoid = (Speed x 3 + Luck) / 2
@export var agility: int = 4; ## Agility increases the evasion and hit rate of a unit
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

@export var spawn_location :Vector3i; ## Where the unit will spawn

var max_health: int = health + endurance + floor(strength / 2.0);
@export var current_health: int = max_health;
@export var current_sanity: int = mind;
@export var current_magic: int = magic;

var grid_position: Vector3i;

var next_level_experience: int = 10;

## SKILL TREE


func _set_experience(in_experience: int) -> void:
	experience += in_experience;
	print(unit_name + " gains " + str(in_experience) + " experience points.");
	if (experience > next_level_experience):
		print("Level up!");
		if (speciality == Speciality.Fighter):
			if (next_level_experience >= 10):
				health += 1;
				mind += 1;
			if (next_level_experience >= 100):
				health += 1;
				mind += 1;
			if (next_level_experience >= 1000):
				luck += 1;
				skill += 1;
		print_stats();
		next_level_experience *= 10;


func update_health_bar() -> void:
	health_bar.health = current_health;
	health_bar.sanity = current_sanity;
	health_bar.name_label = unit_name;


func _ready() -> void:
	health_bar = HEALTH_BAR_SCENE.instantiate();
	add_child(health_bar);
	
	sprite = AnimatedSprite3D.new();
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST;
	sprite.sprite_frames = SpriteFrames.new();
	sprite.sprite_frames.add_animation("idle");
	
	var frame_count := 8; # Number of frames in your "idle" animation
	var frame_width := 32; # Width of each individual sprite frame
	var frame_height := 32; # Height of each individual sprite frame
	
	#if speciality == Speciality.Scout:
	var texture: Texture2D = load(sprite_sheet_path);
	
	# Add idle animation
	for i in range(frame_count):
		var atlas := AtlasTexture.new();
		atlas.atlas = texture;
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height);
		sprite.sprite_frames.add_frame("idle", atlas);
	
	# Add walk sideways animation
	for i in range(frame_count):
		var atlas := AtlasTexture.new();
		atlas.atlas = texture;
		atlas.region = Rect2(i * frame_width, frame_width, frame_width, frame_height);
		sprite.sprite_frames.add_frame("walk_side", atlas);
	
	# Add walk down animation
	for i in range(frame_count):
		var atlas := AtlasTexture.new();
		atlas.atlas = texture;
		atlas.region = Rect2(i * frame_width, frame_width * 2, frame_width, frame_height);
		sprite.sprite_frames.add_frame("walk_down", atlas);
	
	# Add walk up animation
	for i in range(frame_count):
		var atlas := AtlasTexture.new();
		atlas.atlas = texture;
		atlas.region = Rect2(i * frame_width, frame_width * 3, frame_width, frame_height);
		sprite.sprite_frames.add_frame("walk_up", atlas);
	
	sprite.play("idle");
	
	#translate(Vector3(0,0.736,-0.463));
	sprite.translate(Vector3(0,0.8,-0.4));
	sprite.rotate(Vector3(1,0,0), deg_to_rad(-60));
	sprite.scale = Vector3(4,4,4);
	
	camera = get_viewport().get_camera_3d();
	update_health_bar();
	
	add_child(sprite);


func _process(_delta: float) -> void:
	var mesh_3d_position: Vector3 = global_transform.origin;
	
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
	reset();
	grid_position = pos;
	sprite.modulate = Color(0.338, 0.338, 0.338, 1.0);


func reset() -> void:
	hide_ui();
	show();
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0);


func die() -> void:
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
		"Agility": agility,
		"Focus": focus,
		
		"Endurance": endurance,
		"Defense": defense,
		"Resistence": resistence,
		"Luck": luck,
		"Intimidation": intimidation,
		"Skill": skill,
		"Magic": magic,
		
		"Experience": experience,
		"Current health": current_health,
		"Current magic": current_magic,
		"Current sanity": current_sanity
	}
	
	return stats;
