extends Node3D
class_name Character
## This class has all the Character visuals
##
## Use this class to with a new scene for
## new characters and enemies

@export var data : CharacterData
@export var state : CharacterState

#region packed scenes
const HEALTH_BAR_SCENE : PackedScene = preload("res://scenes/userinterface/health_bar.tscn")
const ENEMY_HEALTH_BAR_SCENE : PackedScene = preload("res://scenes/userinterface/health_bar_enemy.tscn")
const LEVEL_UP_POPUP : PackedScene = preload("res://scenes/userinterface/level_up.tscn")
const SKILL_CHOOSE_POPUP : PackedScene = preload("res://scenes/userinterface/skill_choose.tscn")
const SPRITE : PackedScene = preload("res://art/WIP/CharTest.tscn")
#endregion

#region inferred variables
var sprite : Node3D
var portrait : Texture2D

var camera : Camera3D
var health_bar : HealthBar
var level_up_popup : LevelUpPopUp
var skill_choose_popup : SkillChoose
var health_bar_ally : HealthBar
var health_bar_enemy : HealthBar
#endregion


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
	
	state.max_health = data.health + data.endurance + floor(data.strength / 2.0);
	state.movement = 4 + floor(data.speed / 3); ## Movement range
	state.current_health = state.max_health;
	state.current_sanity = data.mind;
	state.current_mana = data.mana;
	
	#if personality == Personality.Zealot:
	#	skills.append(generic_skills[0]);
	state.skills.append(SkillData.all_skills[data.speciality][data.personality % (SkillData.all_skills[data.speciality].size() - 1)]);
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


func save() -> Dictionary:
	return {
		"data": data.save(),
		"state": state.save()
	}
