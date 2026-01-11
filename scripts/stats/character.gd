extends Node3D
class_name Character
## This class has all the Character visuals
##
## Use this script with a new scene for
## new characters / enemies

@export_category("Animations")
@export var run_left_animation : SpriteAnim
@export var run_up_animation : SpriteAnim
@export var run_down_animation : SpriteAnim

@export_category("UI")
@export var portrait : Texture2D

@export_category("Model")
@export var data : CharacterData
@export var state : CharacterState

#region animation state
var current_animation : SpriteAnim = null

var frame_index : int = 0
var frame_timer : float = 0.0
var stop_anim : bool = true

var my_material : ShaderMaterial = null

@onready var sprite : Sprite3D = $Sprite
#endregion

#region packed scenes
const HEALTH_BAR_SCENE : PackedScene = preload("res://scenes/userinterface/health_bar.tscn")
const ENEMY_HEALTH_BAR_SCENE : PackedScene = preload("res://scenes/userinterface/health_bar_enemy.tscn")
const LEVEL_UP_POPUP : PackedScene = preload("res://scenes/userinterface/level_up.tscn")
const SKILL_CHOOSE_POPUP : PackedScene = preload("res://scenes/userinterface/skill_choose.tscn")
#endregion

#region inferred variables
var camera : Camera3D
var health_bar : HealthBar
var level_up_popup : LevelUpPopUp
var skill_choose_popup : SkillChoose
var health_bar_ally : HealthBar
var health_bar_enemy : HealthBar
#endregion


func play(anim : SpriteAnim) -> void:
	if anim == null:
		return
	
	stop_anim = false
	
	if current_animation == anim:
		return

	current_animation = anim;
	frame_index = 0
	frame_timer = 0.0
	
	if my_material == null:
		var mat := sprite.material_override as ShaderMaterial
		if mat == null:
			push_error("Sprite3DAnimator requires a ShaderMaterial on material_override.")
			return
		
		my_material = mat.duplicate(true)
		sprite.material_override = my_material
	
	my_material.set_shader_parameter("diffuse_atlas", current_animation.diffuse_atlas)
	my_material.set_shader_parameter("normal_atlas", current_animation.normal_atlas)
	my_material.set_shader_parameter("mask_atlas", current_animation.mask_atlas)

	my_material.set_shader_parameter("frame_index", 0)
	my_material.set_shader_parameter("frame_columns", current_animation.frame_columns)
	my_material.set_shader_parameter("frame_rows", current_animation.frame_rows)


func pause_anim() -> void:
	stop_anim = true


func clone() -> Character:
	var c := Character.new()
	c.data = data.duplicate_data()
	c.state = state.duplicate_data()
	return c


func _on_sanity_changed(_in_sanity : int) -> void:
	if state.current_sanity <= 0 and state.current_health >= 0:
		state.faction = CharacterState.Faction.ENEMY
		data.unit_name = data.unit_name + "'cthulhu"
		health_bar = health_bar_enemy
		health_bar_ally.hide()
		health_bar_enemy.show()
		Main.characters.erase(self)
	if health_bar:
		update_health_bar()


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
		
		calc_derived_stats()
		
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


func update_health_bar() -> void:
	health_bar.health = state.current_health;
	health_bar.sanity = state.current_sanity;
	health_bar.name_label = data.unit_name;


func calibrate_level_popup() -> void:
	level_up_popup.focus = data.focus;
	level_up_popup.level = state.current_level;
	level_up_popup.mind = data.mind;
	level_up_popup.movement = state.movement;
	level_up_popup.speed = data.speed;
	level_up_popup.strength = data.strength;
	level_up_popup.endurance = data.endurance;


func calc_derived_stats() -> void:
	state.defense = 4 + data.endurance
	state.resistance = 4 + floor(data.focus / 2.0) + floor(data.endurance / 2.0)
	state.max_health = 4 + data.endurance + floor(data.strength / 2.0);
	state.max_sanity = state.resistance + data.mind
	state.movement = 4 + floor(data.speed / 3.0)
	state.current_health = state.max_health
	state.current_sanity = state.max_sanity
	state.stability = max(1, data.focus - data.mind)


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
	
	calc_derived_stats()
	
	#if personality == Personality.Zealot:
	#	skills.append(generic_skills[0]);
	state.skills.append(get_random_unaquired_skill());
	#abilities.append(abilites[0]);
	
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
	
	skill_choose_popup = SKILL_CHOOSE_POPUP.instantiate()
	add_child(skill_choose_popup)
	skill_choose_popup.text = data.unit_name + ", " + CharacterData.Speciality.keys()[data.speciality]
	skill_choose_popup.hide()
	
	sprite.translate(Vector3(0.3,1.0,-0.1))
	sprite.rotate(Vector3(1,0,0), deg_to_rad(-60))
	sprite.scale = Vector3(4,4,4)
	
	play(run_down_animation)
	stop_anim = true
	
	camera = get_viewport().get_camera_3d()
	update_health_bar()


func _process(delta: float) -> void:
	var mesh_3d_position: Vector3 = global_transform.origin;
	
	if state.is_alive:
		show_ui() # hack, TODO: removeme
	
	if camera:
		var screen_position_2d: Vector2 = camera.unproject_position(mesh_3d_position + Vector3(0, 1, 0))
		health_bar.position = screen_position_2d - Vector2(3 * 15, 0);
		health_bar.position.y += 70; # move down a little 
	
	if current_animation == null:
		return
	
	frame_timer += delta
	
	if frame_timer >= 1.0 / current_animation.fps:
		frame_timer = 0.0
		frame_index = (frame_index + 1) % (current_animation.frame_columns * current_animation.frame_rows)
		if stop_anim:
			frame_index = 0
		sprite.material_override.set_shader_parameter("frame_index", frame_index)


func hide_ui() -> void:
	health_bar.hide()


func show_ui() -> void:
	health_bar.show()


func move_to(pos: Vector3i, simulate_only: bool = false) -> void:
	if simulate_only == false:
		Main.level.occupancy_map.set_cell_item(state.grid_position, GridMap.INVALID_CELL_ITEM);
	
	state.is_alive = true;
	state.grid_position = pos;
	state.is_moved = true;
	
	if simulate_only == false:
		var grid_code := Main.level.player_code;
		if state.is_enemy():
			grid_code = Main.level.enemy_code;
		Main.level.occupancy_map.set_cell_item(state.grid_position, grid_code);
		if state.is_playable():
			my_material.set_shader_parameter("grey_tint", true)


func reset() -> void:
	state.is_alive = true;
	# slowly heal sanity
	if state.is_playable():
		state.current_sanity += 1;
		state.is_ability_used = false
	hide_ui();
	show();
	state.is_moved = false;
	my_material.set_shader_parameter("grey_tint", false)


func die(simulate_only : bool) -> void:
	state.is_alive = false
	
	if simulate_only == false:
		if state.is_playable():
			Main.characters.erase(self)
		Main.level.game_state.units.erase(self)
		Main.level.occupancy_map.set_cell_item(state.grid_position, GridMap.INVALID_CELL_ITEM)
		queue_free()


func print_stats() -> void:
	print(save());


func save() -> Dictionary:
	return {
		"data": data.save(),
		"state": state.save()
	}
