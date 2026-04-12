extends Node3D
class_name Level
## Map logic for combat levels.
##
## All state and animation logic is found here,
## as well as input handling and audio playback.
# TODO: Stackable tiles for enemies
# TODO: Make your own units passable
# TODO: camp?
# TODO: Make enemies able to occopy several grid-tiles

#### signals 

signal character_selected(character: Character)
signal character_deselected
signal enemy_selected(enemy: Character)
signal enemy_deselected
signal ability_used
signal character_stats_changed(character: Character)
signal party_updated(characters: Array[Character])





@onready var combat_vfx : CombatVFXController = $CombatVFXController

@export var level_name :String

var terrain_grid : Grid
var path_grid : Grid
var occupancy_grid : Grid
var trigger_grid : Grid
var fog_grid : Grid
var movement_grid : MovementGrid
var movement_weights_grid : Grid

@onready var battle_log: Label = $BattleLog

#cursor testing
#const CURSOR_SWORD = preload("uid://ddogsq0mua2ft")
@onready var cursor_sword : Texture2D = preload("res://art/textures/cursor_sword.png")
@onready var cursor_feet : Texture2D = preload("res://art/textures/cursor_feet.png")
@onready var cursor_boot : Texture2D = preload("res://art/textures/cursor_boot.png")
var _last_hovered_pos: Vector3i = Vector3i(-999, -999, -999)
#cursor testing end
@onready var cursor: Sprite3D = $Cursor
@onready var terrain_map: GridMap = %TerrainGrid
@onready var occupancy_map: GridMap = %OccupancyOverlay
@onready var movement_map: GridMap = %MovementOverlay
@onready var movement_weights_map: GridMap = %MovementWeightsGrid
@onready var trigger_map: GridMap = %TriggerOverlay
@onready var path_map: GridMap = $PathOverlay
@onready var fog_map: GridMap = $FogOverlay
@onready var turn_transition: CanvasLayer = $TurnTransition/CanvasLayer
@onready var turn_transition_animation_player: AnimationPlayer = $TurnTransition/AnimationPlayer

@onready var player_label: Label = $TurnTransition/CanvasLayer/VBoxContainer/ColorRect3/playerLabel
@onready var enemy_label: Label = $TurnTransition/CanvasLayer/VBoxContainer/ColorRect3/enemyLabel

var _level_complete : bool = false
var level_has_victory_trigger: bool = false


var selected_unit: Character = null
var last_selected_unit: Character = null
var selected_enemy_unit: Character = null
var active_skill: Skill = null
var skill_caster: Character = null ## The one using ability
var is_choosing_skill_target: bool = false
var is_choosing_skill_attack_origin: bool = false
var valid_skill_target_tiles: Dictionary = {} ## For abilities/spells
var move_popup: Control;
#var stat_popup_player: Control;
#var side_bar_array : Array[SideBar];
#var stat_popup_enemy: Control;
var completed_moves :Array[Command];

var characters: Array[Character];

## For TriggerOverlay and Dialogic
var triggered_positions: Array[Vector3i] = []

const GAME_UI = preload("res://scenes/userinterface/InGameUI_WIP.tscn")

const STATS_POPUP = preload("res://scenes/userinterface/pop_up.tscn")
const MOVE_POPUP = preload("res://scenes/userinterface/move_popup.tscn")
const CHEST = preload("res://scenes/grid_items/chest.tscn")
const SIDE_BAR = preload("res://scenes/userinterface/sidebar.tscn")
const PLAYER: PackedScene = preload("res://scenes/Characters/alfred.tscn");
const BIRD_ENEMY: PackedScene  = preload("res://scenes/Characters/bird.tscn")
const GHOST_ENEMY: PackedScene  = preload("res://scenes/Characters/Ghost_Enemy.tscn")
const HORROR_ENEMY: PackedScene = preload("res://scenes/Characters/Horror_Scene.tscn")
const CORRUPTED_PLAYER_RED: PackedScene = preload("res://scenes/Characters/Char_Corrupted_Player_Orange.tscn")

@onready var loot_popup : LootPopup = $LootPopUp


var animation_path :Array[Vector3];
var is_animation_just_finished :bool = false;
var patrol_paths: Dictionary[String, PatrolPath] = {}
var chests: Dictionary[Vector3i, Chest] = {}
var pending_chest_weapon: Weapon = null

enum States {
	PLAYING,
	ANIMATING,
	TRANSITION,
	CHOOSING_ATTACK };
var state :int = States.PLAYING;
var game_state : GameState;

var is_in_menu: bool = false
var active_move: Command
var moves_stack: Array[Command]

var current_moves: Array[Command]
var is_player_turn: bool = true
var unit_pos: Vector3
var player_code: int = 0
var player_code_done: int = 3
var enemy_code: int = 1
var attack_code: int = 0
var move_code: int = 1

var is_enemy_turn: bool = false
var skill_target_code: int = 0

#region Camera
var camera_controller : CameraController
const post_enemy_move_wait : float = 0.1
const post_enemy_attack_wait : float = 0.4
const pre_enemy_turn_wait : float = 0.2
var wait_timer : float = 0.0
@onready var timer : Timer = $Timer
var wait_for_camera : bool = false
#endregion

#region Key Input Controls
var _held_key: Key = KEY_NONE
var _hold_timer: float = 0.0
var _hold_duration: float = 1.0
var _hold_action: Callable = Callable()
var _key_consumed: bool = false
#endregion

var monster_names := [
	"Xathog-Ruun",
	"Ylthuun",
	"Thozra’el",
	"Khar’Neth",
	"Ulmaggoth",
	"Sleeper",
	"The Thing",
	"He Who Watches",
	"The Drowned",
	"Crawling Silence",
	"Alien",
	"Zhae’kul-ith",
	"Qor’thaal",
	"Nyss-Vek",
	"Hrr’kath",
	"Vool-Xir",
	"Borrowed Faces",
	"The Unfinished",
	"Echo",
	"Sec'Mat",
	"Unfinished projects",
	"d'ave",
	"mar'k",
	"Cringe Memory",
]


func show_move_popup(window_pos :Vector2) -> void:
	return
	move_popup.show();
	is_in_menu = true;
	move_popup.position = Vector2(window_pos.x + 64, window_pos.y);
	if active_move is Attack:
		move_popup.attack_button.show();
	elif (active_move is Wait):
		move_popup.wait_button.show();
	else:
		move_popup.move_button.show();


func raycast_to_gridmap(origin: Vector3, direction: Vector3) -> Vector3:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state;
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin,
		origin + direction * 1000.0
		);

	var result: Dictionary = space_state.intersect_ray(query)
	if result:
		return result.position
	return Vector3();


#fens kinda wonky grid to world transform that might be crap
func grid_to_world(pos: Vector3i) -> Vector3:
	var world:= terrain_map.map_to_local(pos)
	return world

#andreas's wonky world to grid transform using movement_map, because its used for cursors
func world_to_grid(pos: Vector3) -> Vector3i:
	return movement_map.local_to_map(movement_map.to_local(pos))
	#return terrain_map.local_to_map(terrain_map.to_local(pos))


func get_selectable_characters() -> Array[Character]:
	var result: Array[Character] =[]
	for c in characters:
		if not is_instance_valid(c):
			continue
		if c.state.faction != CharacterState.Faction.PLAYER:
			continue
		#if c.state.is_dead:
			#continue
		result.append(c)
	return result


func select_next_character() -> void:
	var list := get_selectable_characters()
	if list.is_empty():
		return

	if selected_unit == null:
		try_select_unit(list[0])
		return
	var index := list.find(selected_unit)
	if index == -1:
		try_select_unit(list[0])
		return

	var next_index := (index + 1) % list.size()
	try_select_unit(list[next_index])


func _on_turn_transition_finished(anim_name: StringName) -> void:
	if not is_player_turn:
		return
	camera_controller.free_camera()
	if last_selected_unit != null and get_selectable_characters().has(last_selected_unit):
		camera_controller.set_pivot_target_translate(last_selected_unit.position)
		select_unit(last_selected_unit)
	else:
		var first : Character = get_selectable_characters().front()
		if first != null:
			camera_controller.set_pivot_target_translate(first.position)
			#select_unit(first)


func get_grid_cell_from_mouse() -> Vector3i:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera_controller.project_ray_origin(mouse_pos)
	var ray_dir: Vector3 = camera_controller.project_ray_normal(mouse_pos).normalized()

	var max_distance: float = 100.0
	var step: float = 0.1
	var distance: float = 0.0

	var cell_size: Vector3 = movement_weights_map.cell_size
	var best_cell: Vector3i
	var is_best_cell := false

	while distance < max_distance:
		var check_pos: Vector3 = ray_origin + ray_dir * distance

		# Convert world position to GridMap cell coordinates
		var x: int = int(floor(check_pos.x / cell_size.x))
		var y: int = int(floor(check_pos.y / cell_size.y))
		var z: int = int(floor(check_pos.z / cell_size.z))
		var candidate: Vector3i = Vector3i(x, y, z)

		if movement_weights_map.get_used_cells().has(candidate):
			best_cell = candidate
			is_best_cell = true
			break

		distance += step

	
	if is_best_cell != false:
		return best_cell

	return Vector3i(-999,-999,-999)  # fallback


func get_tile_name(pos: Vector3) -> String:
	if terrain_map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		return "null";
	return terrain_map.mesh_library.get_item_name(terrain_map.get_cell_item(pos));


# Expanded the function to do some error searching
func get_unit_name(pos : Vector3) -> String:
	var item_id: int = occupancy_map.get_cell_item(pos)
	if item_id == GridMap.INVALID_CELL_ITEM:
		return "null"
		
	if item_id >= occupancy_map.mesh_library.get_item_list().size():
		push_warning("Invalid Unit MeshLibrary item: " + str(item_id) + " at position: " + str(pos))
		return "null"
	
	return occupancy_map.mesh_library.get_item_name(item_id)


func get_trigger_name(pos : Vector3) -> String:
	var trigger_id: int = trigger_map.get_cell_item(pos)
	if trigger_id == GridMap.INVALID_CELL_ITEM:
		return "null"
	
	if trigger_id >= trigger_map.mesh_library.get_item_list().size():
		push_warning("Invalid Trigger MeshLibrary item: " + str(trigger_id) + " at position: " + str(pos))
		return "null"
	
	return trigger_map.mesh_library.get_item_name(trigger_id)


func show_attack_tiles(pos: Vector3i) -> void:
	is_choosing_skill_attack_origin = true
	## TODO: Gray out abilities?
	path_map.clear()

	var reachable: Array[Vector3i] = []

	# Collect all MOVE destinations (possible attack origins)
	for cmd in current_moves:
		if cmd is Move:
			reachable.append(cmd.end_pos)

	# Include standing still as an origin
	reachable.append(selected_unit.state.grid_position)

	# Generate attack tiles
	var tiles := MoveGenerator.get_attack_origins(
		selected_unit,
		game_state,
		pos,
		reachable
	)

	for tile: Vector3i in tiles:
		path_map.set_cell_item(tile, 0)


func _can_handle_input(event: InputEvent) -> bool:
	##old
	#if get_grid_cell_from_mouse() == Vector3i(INF, INF, INF):
		#return false
	if not is_player_turn:
		return false
	
	if state == States.ANIMATING:
		return false

	if is_in_menu:
		return false

	if not (event is InputEventMouseButton):
		return false

	if event.button_index != MOUSE_BUTTON_LEFT:
		return false

	if not event.pressed:
		return false

	if Input.is_action_pressed("enable_dragging"):
		return false
	
	if get_grid_cell_from_mouse() == Vector3i(-999, -999, -999):
		_clear_selection();
		return false

	return true


func _update_cursor(pos: Vector3i) -> void:
	var world_pos := grid_to_world(pos)
	cursor.position = Vector3(world_pos.x, world_pos.y + 0.1, world_pos.z)
	cursor.show()


func _handle_skill(pos : Vector3i) -> void:
	var used_skill : Skill = active_skill
	# Normalize to same plane your maps/skills use
	##TODO make _handle_skill use height
	#var p := Vector3i(pos.x, 0, pos.z)
	
	var p : Vector3i = Vector3i(pos)
	var target: Character = get_unit(p)
		
	print("SKILL CLICK p=", p,
			" in_valid=", valid_skill_target_tiles.has(p),
			" target=", target)
	
	## check if exit skill
	var exit_skill : bool = false
	if not valid_skill_target_tiles.has(p):
		exit_skill = true
	if target == null:
		exit_skill = true
	if not _is_valid_target(target, used_skill, skill_caster):
		exit_skill = true
	if used_skill.uses_action && skill_caster.state.is_ability_used:
		exit_skill = true

	if exit_skill:
		_exit_skill_target_mode()
		return
	
	## begin executing skill
	print("Casting ", used_skill.skill_id, " from ", skill_caster.data.unit_name, " to ", target.data.unit_name)
	
	## Take all the stuff and compile a list of the results as AttackResult! 
	var result: AttackResult = AttackResult.new()
	result.aggressor = skill_caster
	result.victim = target
	result.vfx_scene =  used_skill.Vfx_Scene
	if used_skill.effect_mods != null and used_skill.effect_mods.has("damage"): 
		result.damage = used_skill.effect_mods.get("damage", 0)
	
	
	## TODO: fix crash here if used_skill is null
	var used_action : bool = used_skill.uses_action
	
	var caster : Character = skill_caster
	if used_action:
		caster.state.is_ability_used = true
		# cast a signal to Ribbon here to gray out ability bar
		print("emitting ability_used signal")
		emit_signal("ability_used")
		emit_signal("character_stats_changed", skill_caster)
		#print("Flag set, is_ability_used: ", caster.state.is_ability_used)

	print("Skill result - aggressor: ", result.aggressor)
	print("Skill result - victim: ", result.victim)
	print("Skill result - vfx_scene: ", result.vfx_scene)
	print("Skill result - damage: ", result.damage)
	await combat_vfx.play_skill(result)
	
	## Impact damage (Fireball)
	if used_skill.effect_mods != null and used_skill.effect_mods.has("damage"):
		target.apply_damage(int(used_skill.effect_mods["damage"]), false, skill_caster, used_skill.skill_name)
	## DoT's
	target.state.apply_skill_effect(used_skill)
	emit_signal("character_stats_changed", target)
	
	_exit_skill_target_mode()
	print("is_ability_used after exit: ", caster.state.is_ability_used)
	#CheckVictoryConditions()


func _handle_attack_choice(pos: Vector3i) -> void:
	if path_map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		_cancel_attack_choice_mode()
		return

	active_move.end_pos = pos
	moves_stack.append(active_move)

	create_path(
		moves_stack.front().start_pos,
		moves_stack.front().end_pos
	)

	is_choosing_skill_attack_origin = false
	camera_controller.focus_camera(selected_unit)
	state = States.ANIMATING


func _is_invalid_tile(pos: Vector3i) -> bool:
	return get_tile_name(pos) == "Water"


func can_handle_ui_input() -> bool:
		return(
			is_player_turn
			and state == States.PLAYING
			and not is_in_menu
		)


func try_select_unit(unit: Character) -> void:
	if not can_handle_ui_input():
		return
	
	select_unit(unit)


func select_unit(unit: Character) -> void:
	# Switching unit
	_clear_selection()
	
	last_selected_unit = unit
	selected_unit = unit
	camera_controller.set_pivot_target_translate(unit.position)
	
	unit_pos = unit.state.grid_position
	_update_cursor(unit.state.grid_position)
	emit_signal("character_selected", selected_unit)
	## This allows to show attacks
	current_moves = MoveGenerator.generate(selected_unit, game_state)
	## Adding 'true' as a 3rd arg in fill_from_commands exludes attacks
	#current_moves = MoveGenerator.generate(selected_unit, game_state, true)
	movement_grid.fill_from_commands(current_moves, game_state)
	
	if Main.level.level_name.begins_with("tutorial") == true:
		print("Level name matches: ", Main.level.name)
		Tutorial.tutorial_unit_selected()
	## DIALOGIC
	#if (Main.level.name == "tutorial_1"):
	#	print("DIALOGIC TEST")
	#	Dialogic.start_timeline("tutorialpc2")


func _handle_player_click(pos: Vector3i) -> void:
	if is_choosing_skill_target:
		return
	
	unit_pos = pos
	movement_map.clear()

	# Same unit clicked again 
	#Removed as a quickfix
	#if selected_unit == get_unit(pos):
		#active_move = Wait.new(pos)
		#show_move_popup(get_viewport().get_mouse_position())
		#return
		
	select_unit(get_unit(pos))


func _handle_action_tile_click(pos: Vector3i) -> void:
	active_move = null

	var found_move : Move = null
	var found_attack : Attack = null

	for cmd in current_moves:
		if cmd is Move and cmd.end_pos == pos:
			found_move = cmd
		elif cmd is Attack and cmd.attack_pos == pos:
			found_attack = cmd

	# MOVE HAS PRIORITY
	if found_move != null:
		active_move = found_move

		moves_stack.append(active_move)
		camera_controller.focus_camera(selected_unit)
		state = States.ANIMATING
		create_path(unit_pos, pos)
		path_map.clear()

	elif found_attack != null:
		active_move = found_attack

		show_attack_tiles(pos)
		state = States.CHOOSING_ATTACK

	movement_map.clear()


func _clear_selection() -> void:
	emit_signal("character_deselected")
	emit_signal("enemy_deselected")
	movement_map.clear()
	path_map.clear()
	selected_unit = null
	cursor.hide()


#_input is always handled first, then UI, then Unhandled input
#(use property mouse_filter: Stop to let ui steal input, use Ignore to not let UI steal input! 
#always remember to change these on UI nodes when they are created)
func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		if event.pressed:
			if _key_consumed:
				return
			match event.keycode:
				KEY_SPACE:
					_start_hold(KEY_SPACE, 1.0, 
						func() -> void: if is_player_turn and state != States.ANIMATING: end_player_turn()
					)
				KEY_N:
					if Tutorial.in_tutorial:
						_start_hold(KEY_N, 1.0, 
						func() -> void: if is_player_turn and state != States.ANIMATING: Tutorial.tutorial_trigger_victory())
					else:
						_start_hold(KEY_N, 1.0, 
							func() -> void: if is_player_turn and state != States.ANIMATING: next_level()
						)
				KEY_TAB:
					select_next_character()
				KEY_1:
					var ui := get_tree().get_first_node_in_group("ui_controller")
					if ui:
						ui.ribbon.trigger_skill_by_index(0)
				KEY_2:
					var ui := get_tree().get_first_node_in_group("ui_controller")
					if ui:
						ui.ribbon.trigger_skill_by_index(1)
				KEY_3:
					var ui := get_tree().get_first_node_in_group("ui_controller")
					if ui:
						ui.ribbon.trigger_skill_by_index(2)
				KEY_4:
					var ui := get_tree().get_first_node_in_group("ui_controller")
					if ui:
						ui.ribbon.trigger_skill_by_index(3)
				KEY_5:
					var ui := get_tree().get_first_node_in_group("ui_controller")
					if ui:
						ui.ribbon.trigger_skill_by_index(4)
		
		else:
			if event.keycode == _held_key:
				_cancel_hold()
				_key_consumed = false
			elif _key_consumed:
				_key_consumed = false


func _unhandled_input(event: InputEvent) -> void:
	if not _can_handle_input(event):
		return
	
	var pos: Vector3i = get_grid_cell_from_mouse()
	print(pos)

	_update_cursor(pos)
	
	if is_choosing_skill_target == true:
		_handle_skill(pos)
		return;
	
	# Attack selection phase
	if state == States.CHOOSING_ATTACK:
		_handle_attack_choice(pos)
		return

	if _is_invalid_tile(pos):
		return

	# Player unit clicked
	if get_unit_name(pos) == CharacterStates.Player:
		_handle_player_click(pos)
		return

	# Clicked on movement/attack tile
	if movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
		_handle_action_tile_click(pos)
		return

	# Clicked empty tile
	_clear_selection()

	# Enemy clicked (for info panel)
	if get_unit(pos) and get_unit(pos).state.faction == CharacterState.Faction.ENEMY:
		selected_enemy_unit = get_unit(pos)
		emit_signal("enemy_selected", selected_enemy_unit)
		print("hey an enemy has been selected ")


func _ready() -> void:
	camera_controller = Main.camera_controller

	cursor.hide()
	trigger_map.hide()
	movement_map.clear()
	movement_weights_map.hide()
	occupancy_map.hide()
	path_map.clear()
	fog_map.clear()

	terrain_grid = Grid.new(terrain_map)
	occupancy_grid = Grid.new(movement_map)
	trigger_grid = Grid.new(movement_map)
	movement_grid = MovementGrid.new(movement_map)
	movement_weights_grid = Grid.new(movement_weights_map)
	path_grid = Grid.new(movement_map)
	fog_grid = Grid.new(fog_map)
	
	turn_transition_animation_player.animation_finished.connect(_on_turn_transition_finished)

	#if (level_name == "first"):
		#Dialogic.start(str(level_name) + "Level");
		#is_in_menu = true;
	#elif (level_name == "fen"):
		#Dialogic.start("Showcase_Intro")
		#is_in_menu = true
	#elif (level_name == "tutorial_1"):
		#Tutorial.level = self
		#Tutorial.start_tutorial()
		##Dialogic.start("tutorialpc1")
	#elif (level_name == "fento"):
		#for c in Main.characters:
			#if c.state.faction == CharacterState.Faction.ENEMY:
				#c.state.aggro_range = 20
	
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Main.battle_log = battle_log

	var units: Array[Vector3i] = occupancy_map.get_used_cells()
	var characters_placed := 0

	print("Loading new level, number of playable characters: ", Main.characters.size())
	print("Level name: ", Main.level.name)
	
	_check_for_victory_trigger()

	for i in range(units.size()):
		var pos: Vector3i = units[i]
		var new_unit: Character = null

		var unit_type : String = get_unit_name(pos)
		if(unit_type == "00_Unit"):
			if characters_placed < Main.characters.size():
				new_unit = Main.characters[characters_placed]
				new_unit.state.is_moved = false
				new_unit.camera = get_viewport().get_camera_3d()
				characters_placed += 1

				var health := new_unit.state.current_health
				print(
					"This character exists: ",
					new_unit.data.unit_name,
					" health: ",
					health if health > 0 else "fresh unit"
				)
			else:
				occupancy_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM)
			if new_unit:
				new_unit.position = grid_to_world(pos)

				if new_unit.get_parent() != Main.world:
					Main.world.add_child(new_unit)

				characters.append(new_unit)

				if new_unit is Character:
					new_unit.state.grid_position = pos
					new_unit.sanity_flipped.connect(_on_character_sanity_flipped)
		else:
			spawn_enemy(pos, unit_type, true)

	move_popup = MOVE_POPUP.instantiate()
	move_popup.hide()
	add_child(move_popup)
	
	game_state = GameState.from_level(self)
	
	turn_transition_animation_player.play()
	add_to_group("level")
	
	_register_chests()
	_register_patrol_paths()
	check_aggro()
	hide_inactive_characters()

func spawn_enemy(pos : Vector3i, unit_id : String, _on_ready : bool = false) -> Character:
	var new_enemy: Character = null

	match unit_id:
		"01_Enemy":
			new_enemy = PLAYER.instantiate()
			
			var data := CharacterData.new()
			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY
			
			new_enemy.data = data
			new_enemy.state = c_state
			new_enemy.data.unit_name = monster_names.pick_random()

		"02_Chest":
			var chest := CHEST.instantiate()
			chest.position = grid_to_world(pos)
			add_child(chest)

		"04_EnemyBird":
			new_enemy = BIRD_ENEMY.instantiate()
			var data := CharacterData.new()
			data.speed += 4;
			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY
			
			new_enemy.data = data
			new_enemy.state = c_state
			new_enemy.data.unit_name = monster_names.pick_random()

		"05_EnemyGhost":
			new_enemy = GHOST_ENEMY.instantiate()
			var data := CharacterData.new()
			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY
			
			new_enemy.data = data
			new_enemy.state = c_state
			new_enemy.data.unit_name = monster_names.pick_random()

		"06_EnemyMonster":
			new_enemy = HORROR_ENEMY.instantiate()
			var data := CharacterData.new()
			data.endurance += 6;
			data.strength += 6;
			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY
			
			new_enemy.data = data
			new_enemy.state = c_state
			new_enemy.data.unit_name = monster_names.pick_random()
			
		"07_InsaneCharacter":
			new_enemy = CORRUPTED_PLAYER_RED.instantiate()
			var data := CharacterData.new()
			data.endurance += 6;
			data.strength += 6;
			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY
			
			new_enemy.data = data
			new_enemy.state = c_state
			new_enemy.data.unit_name = monster_names.pick_random()
			
		_:
			occupancy_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM)

	if new_enemy:
		new_enemy.position = grid_to_world(pos)

		if new_enemy.get_parent() != Main.world:
			Main.world.add_child(new_enemy)

		characters.append(new_enemy)
		if(!_on_ready):
			game_state.units.append(new_enemy)
			occupancy_map.set_cell_item(pos, 6)

		if new_enemy is Character:
			new_enemy.state.grid_position = pos
			new_enemy.sanity_flipped.connect(_on_character_sanity_flipped)
	return new_enemy


func get_unit(pos: Vector3i) -> Character:
	for i in range(characters.size()):
		if is_instance_valid(characters[i]):
			if characters[i] is Character:
				var unit: Character = characters[i];
				if unit.state.grid_position == pos:
					return unit;
	return null;


func create_path(start : Vector3i, end : Vector3i) -> void:
	animation_path.clear()
	path_map.clear()
	var foo0 : Command = moves_stack.front()
	var foo1 : Vector3i = foo0.start_pos
	var foo2 : Character = game_state.get_unit(foo1)
	if(foo2.data.unit_name == "Tucy"):
		pass
	var foo3 : Array[Command] = MoveGenerator.generate(foo2, game_state)
	movement_grid.fill_from_commands(foo3, game_state)
	
	var path := movement_grid.get_path(start, end)

	for p in path:
		var anim_pos := grid_to_world(p)
		animation_path.append(anim_pos)

	selected_unit = get_unit(start)


func reset_all_units() -> void:
	var units :Array[Vector3i] = occupancy_map.get_used_cells();
	for i in units.size():
		var pos :Vector3i = units[i];
		if (occupancy_map.get_cell_item(pos) == player_code_done):
			occupancy_map.set_cell_item(pos, player_code);
		var character: Character = get_unit(pos);
		if character is Character:
			var character_script: Character = character;
			character_script.reset();


func MoveAI() -> void:
	var ai := MinimaxAI.new();
	var current_state := GameState.from_level(self);
	
	
	if current_state.has_enemy_moves():
		var move : Command = ai.choose_best_move(current_state, 1);
		moves_stack.append(move);
		current_state = current_state.apply_move(move, true);
	
	if (moves_stack.is_empty() == false):
		create_path(moves_stack.front().start_pos, moves_stack.front().end_pos); # a-star for pathfinding AI
		state = States.ANIMATING;
		camera_controller.focus_camera(selected_unit)
	else:
		camera_controller.set_pivot_target_translate(Main.characters.front().position)
		camera_controller.free_camera()

func MoveSingleAI() -> void:
	#check_aggro()
	#Hide "End Turn button" and other UI elements
	var ai := MinimaxAI.new();
	var current_state := GameState.from_level(self);
	var any_active_enemies := false
	
	## Check if any enemies are active, if not, return to player turn
	for unit in characters:
		if unit == null:
			continue
		if not unit.state.is_enemy():
			continue
		if unit.state.aggro_state != CharacterState.AggroState.FROZEN:
			any_active_enemies = true
			break
	
	if not any_active_enemies:
		is_player_turn = true
		is_animation_just_finished = true
		reset_all_units()
		check_aggro()
		hide_inactive_characters()
		camera_controller.free_camera()
		#if last_selected_unit != null and get_selectable_characters().has(last_selected_unit):
			#camera_controller.set_pivot_target_translate(last_selected_unit.position)
		#return
	
	var currentEnemy : Character = null
	for unit in characters:
		if unit == null:
			continue
		if !unit.state.is_enemy():
			continue
		if unit.state.is_moved:
			continue
		currentEnemy = unit
		break
		
	if currentEnemy == null:
		return
		
	match currentEnemy.state.aggro_state:
		CharacterState.AggroState.FROZEN:
			currentEnemy.state.is_moved = true
			#MoveSingleAI()
			call_deferred("MoveSingleAI")
			return
		CharacterState.AggroState.PATROL_RANDOM:
			## TODO: Implement random patrol
			var offsets := [Vector3i(1,0,0), Vector3i(0,1,0), Vector3i(0,0,1)]
			offsets.shuffle()
			var moved := false
			for offset : Vector3i in offsets:
				var target : Vector3i = currentEnemy.state.grid_position + offset
				if current_state.is_free(target) and current_state.get_tiles_at_xz(target.x, target.z).size() > 0:
					moves_stack.append(Move.new(currentEnemy.state.grid_position, target))
					create_path(currentEnemy.state.grid_position, target)
					selected_unit = currentEnemy
					camera_controller.focus_camera(currentEnemy)
					state = States.ANIMATING
					#wait_for_camera = true
					#timer.start(pre_enemy_turn_wait)
					#await timer.timeout
					#wait_for_camera = false
					moved = true
					break
			if not moved:
				currentEnemy.state.is_moved = true
				#MoveSingleAI()
				call_deferred("MoveSingleAI")
			return
		CharacterState.AggroState.PATROL_PATH:
			## TODO: Implement waypoint patrol
			var path: PatrolPath = patrol_paths.get(currentEnemy.data.unit_name, null)
			if path == null:
				push_error("No patrol path found for: " + currentEnemy.data.unit_name)
				currentEnemy.state.aggro_state = CharacterState.AggroState.PATROL_RANDOM
				#MoveSingleAI()
				call_deferred("MoveSingleAI")
				return
			
			var waypoints := path.get_waypoints(self)
			if waypoints.is_empty():
				currentEnemy.state.is_moved = true
				#MoveSingleAI()
				call_deferred("MoveSingleAI")
			return

			# Get next waypoint, wrap around when reaching the end
			var target := waypoints[currentEnemy.state.patrol_index % waypoints.size()]

			# If already at waypoint, advance to next
			if target == currentEnemy.state.grid_position:
				currentEnemy.state.patrol_index += 1
				target = waypoints[currentEnemy.state.patrol_index % waypoints.size()]
	
			# Move one step toward the waypoint using existing pathfinding
			var move_targets := MoveGenerator.generate_move(currentEnemy, current_state)
			var best_move: Move = null
			var best_dist := INF
			
			for m in move_targets:
				var dx : int = abs(m.end_pos.x - target.x)
				var dz : int = abs(m.end_pos.z - target.z)
				var dist : int = dx + dz
				if dist < best_dist:
					best_dist = dist
					best_move = m
			
			if best_move != null:
				# Check if we reached the waypoint after this move
				if best_move.end_pos == target:
					currentEnemy.state.patrol_index += 1
				moves_stack.append(best_move)
				create_path(best_move.start_pos, best_move.end_pos)
				selected_unit = currentEnemy
				camera_controller.focus_camera(currentEnemy)
				state = States.ANIMATING
			else:
				currentEnemy.state.is_moved = true
				#MoveSingleAI()
				call_deferred("MoveSingleAI")
			return
		CharacterState.AggroState.AGGRESSIVE:
			pass
	
	if currentEnemy != null:
		var curEnemyPos : NullablePosition = NullablePosition.new(currentEnemy.state.grid_position)
		if current_state.has_enemy_moves(curEnemyPos):
			var move : Command = ai.choose_best_move(current_state, 3, currentEnemy);
			moves_stack.append(move);
			current_state = current_state.apply_move(move, true);
	
	if (moves_stack.is_empty() == false):
		create_path(moves_stack.front().start_pos, moves_stack.front().end_pos); # a-star for pathfinding AI
		state = States.ANIMATING;
		camera_controller.focus_camera(selected_unit)
		wait_for_camera = true
		timer.start(pre_enemy_turn_wait)
		await timer.timeout
		wait_for_camera = false
	else:
		var pivot_chara : Node3D = get_selectable_characters().front()
		if(pivot_chara == null):
			return
		camera_controller.free_camera()
		camera_controller.set_pivot_target_translate(pivot_chara.position)


func CheckTriggerConditions() -> void:
	## 02_Trigger2 = interact events like chest, sign post
	## 03_Trigger3 = Dialogic events automatic trigger
	var messages : int = 0
	var units :Array[Vector3i] = occupancy_map.get_used_cells();
	for i in units.size():
		var pos :Vector3i = units[i];
		if (occupancy_map.get_cell_item(pos) == player_code || occupancy_map.get_cell_item(pos) == player_code_done):
			if get_trigger_name(pos) == "02_Trigger2":
				_on_chest_opened(pos)
				print("Player Unit moved to interact event tile. A window should appear now.");
			elif get_trigger_name(pos) == "03_Trigger3":
				if triggered_positions.has(pos):
					continue
				print("Trigger fired at: ", pos)
				triggered_positions.append(pos)
				Tutorial.advance_timeline()
			
			var adjacent := [
				pos + Vector3i(1, 0, 0),
				pos + Vector3i(1, 0, 1),
				pos + Vector3i(1, 0, -1),
				pos + Vector3i(-1, 0, 0),
				pos + Vector3i(-1, 0, 1),
				pos + Vector3i(-1, 0, -1),
				pos + Vector3i(0, 0, 1),
				pos + Vector3i(0, 0, -1)
			]
			for adj : Vector3i in adjacent:
				if get_trigger_name(adj) == "02_Chest":
					if triggered_positions.has(adj):
						continue
					triggered_positions.append(adj)
					_on_chest_opened(adj)

func CheckVictoryConditions() -> void:
	## Next_level() should not run here, but in the stat screen after button is pressed
	## Victory conditions should just freeze the game, unload, and add an intermed screen / load screen
	var units :Array[Vector3i] = occupancy_map.get_used_cells();
	var numberOfPlayerUnits :int = 0;
	var numberOfEnemyUnits  :int = 0;
	
	for i in units.size():
		var pos :Vector3i = units[i];
		var cell_item : int = occupancy_map.get_cell_item(pos)
		if cell_item == player_code or cell_item == player_code_done:
			if get_trigger_name(pos) == "00_Victory":
				is_player_turn = true;
				next_level();
				return;
			numberOfPlayerUnits += 1;
		elif cell_item == 2:
			continue
		elif cell_item >= enemy_code:
			numberOfEnemyUnits += 1;
	
	if (numberOfPlayerUnits == 0):
		get_tree().change_scene_to_file("res://scenes/states/gameover.tscn");
	elif (numberOfEnemyUnits == 0 and not level_has_victory_trigger):
		is_player_turn = true;
		next_level();
		return;

##Removing unwanted occupants and resetting movement of characters
func next_level() -> void:
	## Guard for our not so nice next level system
	print("next_level() in level.gd triggered!")
	if _level_complete:
		return
	_level_complete = true
	
	var positions : Array[Vector3i] = occupancy_map.get_used_cells();
	for i in positions.size():
		var unit : Character = get_unit(positions[i])
		var cell_item := occupancy_map.get_cell_item(positions[i])
		if cell_item == 3 or cell_item == 0:
			if unit == null:
				continue
			unit.reset();
			unit.state.grid_position = Vector3i(0, 0, 0)

		##Remove all other occupants, since they should not be in the next level
		else:
			if unit == null:
				print("No unit found at enemy position: ", positions[i])
				continue
			print("Killing unit: ", unit.data.unit_name)			
			unit.die(false)
	
	## Force Delete Enemy Units from map
	for c in characters:
		if c == null:
			continue
		if not c.state.is_enemy():
			continue
		if is_instance_valid(c):
			print("Force deleting unit enemy: " + str(c.data.unit_name))
			if c.get_parent() != null:
				c.get_parent().remove_child(c)
			c.free()
			
	# Healing units between levels
	for i in Main.characters.size():
		Main.characters[i].state.current_health = Main.characters[i].state.max_health;
	
	## SAVE GAME HAPPENS HERE
	var surviving_chars : Array[Character] = []
	for c in characters:
		if c != null and c.state.is_alive:
			surviving_chars.append(c)
	Main.characters = surviving_chars
	Main.save.save_progress(Main.current_save_slot, Main.get_next_level_index())
	Main.go_to_transition_screen()

func _on_character_sanity_flipped(character: Character) -> void:
	print("heyaaa, we just flipped sanity")
	emit_signal("character_stats_changed", character)
	#characters.erase(character)
	
	

func interpolate_to(target_transform:Transform3D, delta:float) -> void:
	camera_controller.set_pivot_target_transform(target_transform)

#func tick_all_units_end_round(owner: Character) -> void:
func tick_all_units_end_round() -> void:
	## Iterate over duplicates, to avoid null values if units die
	#var dupe := characters.duplicate()
	
	var c:Character = null
	for index : int in range(characters.size()):
		if(characters.get(index) == null):
			push_warning("Character with index %d in characters array was null at end of tick" % index)
			continue
		c = characters.get(index)
		if not is_instance_valid(c):
			continue
		if not (c is Character):
			continue
		if c.state and c.state.is_alive == false:
			continue
		
		var health_before := c.state.current_health
		var sanity_before := c.state.current_sanity
		c.state.tick_effects_end_round(c)
		
		var health_diff := c.state.current_health - health_before
		var sanity_diff := c.state.current_sanity - sanity_before
		if health_diff != 0:
			combat_vfx.spawn_damage_number(health_diff, c.global_position)
		if sanity_diff != 0:
			combat_vfx.spawn_damage_number(sanity_diff, c.global_position + Vector3(0,0.5,0))


func _on_ribbon_skill_pressed(skill: Skill) -> void:
	#print("is_ability_used at ribbon press: ", selected_unit.state.is_ability_used if selected_unit else "no unit")
	#if skill == active_skill:
	#	return
	if selected_unit != null and selected_unit.state.is_ability_used:
		print("Unit has already used their ability this turn.")
		return
	_exit_skill_target_mode()
	movement_grid.clear()
	
	if selected_unit == null:
		print("Pressed skill: ", skill.skill_id, " but no unit selected. This should never happen!")
		return
	
	active_skill = skill
	skill_caster = selected_unit
	is_choosing_skill_target = true
	
	_show_skill_target_tiles(skill_caster.state.grid_position, active_skill)
	print("Entered skill target mode: ", active_skill.skill_id, ". Caster: ", skill_caster.data.unit_name)

func _show_skill_target_tiles(origin: Vector3i, skill: Skill) -> void:
	#valid_skill_target_tiles.clear()
	#path_map.clear() 
#
	#var tiles_in_range: Array[Vector3i] = _get_tiles_in_manhattan_range(origin, skill.min_range, skill.max_range)
#
	#for t in tiles_in_range:
		#var unit: Character = get_unit(t)
		#if _is_valid_target(unit, skill, skill_caster):
			#valid_skill_target_tiles[t] = true
			#path_map.set_cell_item(t, skill_target_code)
	#
	#valid_skill_target_tiles.clear()
	#path_map.clear()

	#var o := Vector3i(origin.x, 0, origin.z)
	var o := Vector3i(origin)
	var tiles_in_range: Array[Vector3i] = Math._get_tiles_in_manhattan_range(o, skill.min_range, skill.max_range)

	for t in tiles_in_range:
		#var p := Vector3i(t.x, 0, t.z)
		var p := Vector3i(t)
		var unit: Character = get_unit(p)

		if unit == null:
			continue

		if _is_valid_target(unit, skill, skill_caster):
			valid_skill_target_tiles[p] = true
			path_map.set_cell_item(p, skill_target_code)


func _exit_skill_target_mode() -> void:
	var caster := skill_caster
	is_choosing_skill_target = false
	active_skill = null
	skill_caster = null
	valid_skill_target_tiles.clear()
	path_map.clear()
	print("caster is_moved: ", caster.state.is_moved if caster else "null")
	if caster != null and caster.state.is_moved == false:
		select_unit(caster)


func _cancel_attack_choice_mode() -> void:
	is_choosing_skill_attack_origin = false
	state = States.PLAYING
	path_map.clear()
	active_move = null
	var attacker := selected_unit
	if attacker != null and attacker.state.is_moved == false:
		select_unit(attacker)


func _is_valid_target(unit: Character, skill: Skill, caster: Character) -> bool:
	if unit == null or skill == null or caster == null:
		return false

	match skill.target_faction:
		Skill.TargetFaction.FRIENDLY:
			return unit.state.faction == caster.state.faction or unit == caster
		Skill.TargetFaction.ENEMY:
			return unit.state.faction != caster.state.faction
		Skill.TargetFaction.BOTH:
			return true
		Skill.TargetFaction.SELF:
			return unit == caster
		
	return false


func _process(delta: float) -> void:
	_process_old(delta)
	return
	
	# FUTURE:
	match state:
		States.PLAYING:
			process_playing(delta)
		States.ANIMATING:
			process_animating(delta)
		States.TRANSITION:
			process_transition(delta)


func process_playing(delta: float) -> void:
	pass


func process_animating(delta: float) -> void:
	pass


func process_transition(delta: float) -> void:
	pass


func get_screen_position(sprite: Sprite3D) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return Vector2.ZERO

	if camera.is_position_behind(sprite.global_position):
		return Vector2(-9999, -9999) # or hide UI

	return camera.unproject_position(sprite.global_position)

func _draw_path_arrow() -> void:
	if state == States.PLAYING and selected_unit and is_in_menu == false:
		var pos :Vector3i = get_grid_cell_from_mouse();
		if movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
			path_map.clear()
			var points : Array[Vector3i] = movement_grid.get_path(selected_unit.state.grid_position, pos)
			
			for point : Vector3i in points:
				path_map.set_cell_item(point, 3) #SET PATH MAP TO BE THE TILE IN ARRAY WHEN DRAWING PATH ARROW

func _process_old(delta: float) -> void:
	_update_cursor_on_hover()
	
	## KEYBOARD INPUT CONTROL
	if _held_key != KEY_NONE:
		_hold_timer += delta
		if _hold_timer >= _hold_duration:
			_key_consumed = true
			_hold_action.call()
			_cancel_hold()
	## KEYBOARD INPUT CONTROL END
	
	if (turn_transition_animation_player.is_playing()):
		turn_transition.show()
		camera_controller.lock_camera()
		return;
	if(!combat_vfx.is_finished()):
		return
	if wait_for_camera:
		return
	#for i in Main.characters.size():
		#update_side_bar(Main.characters[i], side_bar_array[i]);
		
	turn_transition.hide();
	camera_controller.unlock_camera()
	
	_draw_path_arrow()
	
	if (is_in_menu):
		return;
		
	#CheckTriggerConditions();
	CheckVictoryConditions();
	
	if (state == States.PLAYING):
		if (is_animation_just_finished):
			is_animation_just_finished = false;
			turn_transition_animation_player.play();
			enemy_label.hide();
			player_label.show();
		if (is_player_turn):
			is_player_turn = false;
			var units :Array[Vector3i] = occupancy_map.get_used_cells();
			for i in units.size():
				var pos :Vector3i = units[i];
				if (occupancy_map.get_cell_item(pos) == player_code):
					is_player_turn = true;
			if (is_player_turn == false):
				turn_transition_animation_player.play();
				enemy_label.show();
				player_label.hide();
		else:
			## This is the enemy phase - Probably should not run 'reset_all_units()' here.
			MoveSingleAI()
	elif (state == States.ANIMATING):
		# Animations done: stop animating
		if (moves_stack.is_empty()):
			state = States.PLAYING
			movement_map.clear()
			CheckTriggerConditions() ## 
			
			if (is_player_turn == false):
				## END OF ROUND - RESET POINT
				## Going from enemy phase to player phase
				is_animation_just_finished = true;
				tick_all_units_end_round(); ## Decay effects
				## TODO: Implement damagenumbers
				for c in Main.characters:
					if c == null:
						continue
					emit_signal("character_stats_changed", c)
				
				reset_all_units();
				is_player_turn = true;
				check_aggro()
				hide_inactive_characters()
				
				## TUTORIAL
				if Tutorial.in_tutorial and not Tutorial.selection_advances_timeline and Tutorial.timeline_advances_at_player_turn_begins:
				#if Tutorial.in_tutorial and not	Tutorial.timeline_advances_at_player_turn_begins:
					Tutorial.advance_timeline()
				
				
				 # Pan camera back to player after enemy turn ends
				#camera_controller.free_camera()
				#if last_selected_unit != null and get_selectable_characters().has(last_selected_unit):
					#camera_controller.set_pivot_target_translate(last_selected_unit.position)
					#call_deferred("selected_unit", last_selected_unit)
				#else:
					#var first : Character = get_selectable_characters().front()
					#if first != null:
						#camera_controller.set_pivot_target_translate(first.position)
						#call_deferred("selected_unit", first)
		# Done with one move, execute it and start on next
		
		elif (animation_path.is_empty()):
			active_move = moves_stack.pop_front();
			#if get_trigger_name(active_move.end_pos) == "Victory":
				#next_level();
				##Dialogic.start(level_name + "LevelVictory")
			
			active_move.prepare(game_state)
			await combat_vfx.play_attack(active_move.result)
			active_move.apply_damage(game_state)
			
			
			#looks like this is end of player turn! 
			
			if is_player_turn:
				active_move = Wait.new(active_move.end_pos)
				#show_move_popup(get_screen_position(selected_unit.sprite))
				for character in characters:
					if characters == null: 
						return
					emit_signal("character_stats_changed", character)
			
			var code := enemy_code;
			if is_player_turn:
				code = player_code_done;
			occupancy_map.set_cell_item(active_move.start_pos, GridMap.INVALID_CELL_ITEM);
			occupancy_map.set_cell_item(active_move.end_pos, code);
			selected_unit.move_to(active_move.end_pos);
			selected_unit.pause_anim()
			camera_controller.free_camera()
			if not is_player_turn:
				_clear_selection()

			completed_moves.append(active_move);
			Tutorial.tutorial_unit_moved();
			
			if is_player_turn == false:
				#MoveAI(); # called after an enemy is done moving
				if(active_move is Attack):
					wait_for_camera = true
					timer.start(post_enemy_attack_wait)
					await timer.timeout
					wait_for_camera = false
				elif active_move is Move:
					wait_for_camera = true
					timer.start(post_enemy_move_wait)
					await timer.timeout
					wait_for_camera = false
				MoveSingleAI() ## called after an enemy is done moving
				## Update all character ui at the end of enemy turn, to update tickable ui elements
				for character in Main.characters:
					if characters == null: 
						return
					emit_signal("character_stats_changed", character)

			
			if (moves_stack.is_empty() == false):
				## called after any enemy except the final enemy is done moving
				create_path(moves_stack.front().start_pos, moves_stack.front().end_pos); # a-star for enemy animation/movement?
			
			if (animation_path.is_empty() == false):
				## called after any enemy except the final enemy is done moving
				selected_unit.position = animation_path.pop_front();
		## Process animation
		else:
			var movement_speed := 8.0 # units per second WHAT IS THIS???
			var target : Vector3 = animation_path.front()
			var dir : Vector3 = target - selected_unit.position
			var step := movement_speed * delta
			
			#if the unit is very close to their next footstep in animation
			if dir.length() <= step:
				selected_unit.position = target
				animation_path.pop_front()
			#if the unit is more than a footstep away from the animation target
			#position: move closer and move back to the if statement above
			else:
				selected_unit.position += dir.normalized() * step
				
				if (dir.z > 0):
					selected_unit.play(selected_unit.run_down_animation)
				elif (dir.z < 0):
					selected_unit.play(selected_unit.run_up_animation)
				elif (dir.x > 0):
					selected_unit.play(selected_unit.run_right_animation)
				elif (dir.x < 0):
					selected_unit.play(selected_unit.run_left_animation)

func end_player_turn() -> bool:
	if !is_player_turn:
		return false
	if (turn_transition_animation_player.is_playing()):
		return false
	if(!combat_vfx.is_finished()):
		return false
	if wait_for_camera:
		return false
	if (is_in_menu):
		return false
	if state != States.PLAYING:
		return false
	var units :Array[Vector3i] = occupancy_map.get_used_cells();
	for i in units.size():
		var pos :Vector3i = units[i];
		if (occupancy_map.get_cell_item(pos) == player_code):
			active_move = Wait.new(pos)
			active_move.execute(game_state);
			occupancy_map.set_cell_item(active_move.start_pos, GridMap.INVALID_CELL_ITEM);
			occupancy_map.set_cell_item(active_move.end_pos, player_code_done);
	return true


func _update_cursor_on_hover() -> void:
	#Input.set_custom_mouse_cursor(cursor_sword, Input.CURSOR_ARROW, Vector2(8, 8))
	#print("cursor update called, texture is null: ", cursor_sword == null)
	
	var mouse_pos := get_viewport().get_mouse_position()
	var origin := camera_controller.project_ray_origin(mouse_pos)
	var direction := camera_controller.project_ray_normal(mouse_pos)
	var world_pos := raycast_to_gridmap(origin, direction)
	
	if world_pos == Vector3():
		Input.set_custom_mouse_cursor(null)
		return
		
	var grid_pos := world_to_grid(world_pos)
	#print("grid_pos: ", grid_pos, " cell_item: ", movement_map.get_cell_item(grid_pos))

	if grid_pos == _last_hovered_pos:
		return
	_last_hovered_pos = grid_pos
	
	var cell := movement_map.get_cell_item(grid_pos)
	if cell == GridTile.Type.ATTACK:
		Input.set_custom_mouse_cursor(cursor_sword, Input.CURSOR_ARROW, Vector2(8, 8))
	elif cell == GridTile.Type.INTERACT:
		Input.set_custom_mouse_cursor(cursor_boot, Input.CURSOR_ARROW, Vector2(8, 8))
	else:
		Input.set_custom_mouse_cursor(null)

## DIALOGIC AND INTERACTION
func _on_dialogic_signal(argument: String) -> void:
	#Tutorial.in_tutorial = true
	if argument == "set_health_1":
		for c in characters:
			if c.state.faction == CharacterState.Faction.PLAYER:
				c.state.current_health = 1
				emit_signal("character_stats_changed", c)
				break
	elif argument == "highlight_health_bar":
		print("Highlight Health Bar CALLED")
		var ui : Control = get_tree().get_first_node_in_group("ui_controller")
		var highlight := get_tree().get_first_node_in_group("tutorial_highlight")
		print("ui: ", ui)
		print("highlight: ", highlight)
		if ui and highlight:
			highlight.highlight(ui.player_stats)
	elif argument == "clear_highlight":
		var highlight := get_tree().get_first_node_in_group("tutorial_highlight")
		if highlight:
			highlight.clear()
	elif argument == "enable_selection_advances_timeline":
		Tutorial.selection_advances_timeline = true
	else:
		#Tutorial.selection_advances_timeline = true
		Tutorial.advance_timeline()
## DIALOGIC AND INTERACTION END

func _register_patrol_paths() -> void:
	for child in get_children():
		if child is PatrolPath:
			patrol_paths[child.enemy_name] = child
			print("Registered patrol path for: ", child.enemy_name, " waypoints: ", child.get_waypoints(self))


func check_aggro() -> void:
	print("Check_Aggro() called")
	for unit in characters:
		if unit == null:
			continue
		if not unit.state.is_enemy():
			continue
		if unit.state.aggro_state == CharacterState.AggroState.AGGRESSIVE:
			continue
			
		for player_unit in characters:
			if player_unit == null:
				continue
			if player_unit.state.faction != CharacterState.Faction.PLAYER:
				continue
			
			var distx : int = abs(unit.state.grid_position.x - player_unit.state.grid_position.x)
			var distz : int = abs(unit.state.grid_position.z - player_unit.state.grid_position.z)
			var dist : int = distx + distz
			if dist <= unit.state.aggro_range:
				unit.state.aggro_state = CharacterState.AggroState.AGGRESSIVE
				print(unit.data.unit_name, " has aggro")
				break

func hide_inactive_characters() -> void:
	## TODO: Implement hiding player units when out of combat
	##       Implement spawning player units when re entering combat
	var any_active_enemy := false
	# This hide inactive enemies
	for unit in characters:
		if unit == null:
			continue
		if not unit.state.is_enemy():
			continue
		if unit.state.aggro_state == CharacterState.AggroState.FROZEN:
			unit.hide()
			any_active_enemy = true
		else:
			unit.show()
	
	# This hides all but 1 unit when out of combat
	## TODO: Add function to respawn units around unhidden unit when entering
	##       combat.
	#var first_shown := false
	#for c in Main.characters:
		#if c == null:
			#continue
		#if c.state.faction != CharacterState.Faction.PLAYER:
			#continue
		#if any_active_enemy:
			#c.show()
		#else:
			#if not first_shown:
				#c.show()
				#first_shown = true
			#else:
				#c.hide()


func _register_chests() -> void:
	for child in get_children():
		if child is Chest:
			var grid_pos := world_to_grid(child.global_position)
			chests[grid_pos] = child
			print("Registered chest at: ", grid_pos, " weapon: ", child.weapon_id)


func _on_chest_opened(pos: Vector3i) -> void:
	print("on_chest_opened triggered.")
	var chest: Chest = chests.get(pos, null)
	if chest == null:
		push_error("No chest found at: " + str(pos))
		return
	if chest.is_opened:
		return
	chest.is_opened = true
	
	var new_weapon : Weapon = WeaponRegistry.get_weapon(chest.weapon_id)
	if new_weapon == null:
		push_error(chest.weapon_id + " Weapon in chest not found.")
		return
	else:
		print("New weapon is: " + new_weapon.weapon_name)
	
	is_in_menu = true
	print("loot_popup: ", loot_popup)
	var current_weapon : Weapon = selected_unit.state.weapon if selected_unit != null else null
	loot_popup.show_loot(current_weapon, new_weapon, selected_unit)


func _start_hold(key: Key, duration: float, action: Callable) -> void:
	_held_key = key
	_hold_timer = 0.0
	_hold_duration = duration
	_hold_action = action
	_key_consumed = false

func _cancel_hold() -> void:
	_held_key = KEY_NONE
	_hold_timer = 0.0
	_hold_action = Callable()

func _check_for_victory_trigger() -> void:
	for pos in trigger_map.get_used_cells():
		if get_trigger_name(pos) == "00_Victory":
			level_has_victory_trigger = true
			return
