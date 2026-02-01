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

@export var minimum_camera_height: float = 3.0
@export var maximum_camera_height: float = 15.0

@export var minimum_camera_x: float = -10.0
@export var maximum_camera_x: float = 100.0
@export var minimum_camera_z: float = -10.0
@export var maximum_camera_z: float = 10.0

var selected_unit: Character = null
var selected_enemy_unit: Character = null
var move_popup: Control;
#var stat_popup_player: Control;
#var side_bar_array : Array[SideBar];
#var stat_popup_enemy: Control;
var completed_moves :Array[Command];

var characters: Array[Character];

const GAME_UI = preload("res://scenes/userinterface/InGameUI_WIP.tscn")

const STATS_POPUP = preload("res://scenes/userinterface/pop_up.tscn")
const MOVE_POPUP = preload("res://scenes/userinterface/move_popup.tscn")
const CHEST = preload("res://scenes/grid_items/chest.tscn")
const SIDE_BAR = preload("res://scenes/userinterface/sidebar.tscn")
#const RIBBON: PackedScene = preload("res://scenes/userinterface/ribbon.tscn");
const PLAYER: PackedScene = preload("res://scenes/grid_items/alfred.tscn");
const BIRD_ENEMY: PackedScene  = preload("res://scenes/grid_items/bird.tscn")
const GHOST_ENEMY: PackedScene  = preload("res://scenes/grid_items/Ghost_Enemy.tscn")

var animation_path :Array[Vector3];
var is_animation_just_finished :bool = false;

enum States {
	PLAYING,
	ANIMATING,
	CHOOSING_ATTACK };
var state :int = States.PLAYING;
var game_state : GameState;

var is_in_menu: bool = false
var active_move: Command
var moves_stack: Array

var current_moves: Array[Command]
var is_player_turn: bool = true
var unit_pos: Vector3
var player_code: int = 0
var player_code_done: int = 3
var enemy_code: int = 1
var attack_code: int = 0
var move_code: int = 1

var is_using_ability: bool = false

#region Camera
var camera_controller : CameraController
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
	"Sec'Mat"
]


func show_move_popup(window_pos :Vector2) -> void:
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
		select_unit(list[0])
		return
	var index := list.find(selected_unit)
	if index == -1:
		select_unit(list[0])
		return

	var next_index := (index + 1) % list.size()
	select_unit(list[next_index])


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

	return Vector3i(INF,INF,INF)  # fallback


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
		push_warning("Invalid MeshLibrary item: " + str(item_id) + " at position: " + str(pos))
		return "null"
	
	return occupancy_map.mesh_library.get_item_name(item_id)


func show_attack_tiles(pos: Vector3i) -> void:
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
	if get_grid_cell_from_mouse() == Vector3i(INF, INF, INF):
		return false
	
	if get_viewport().get_mouse_position().y > 700:
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

	return true


func _update_cursor(pos: Vector3i) -> void:
	var world_pos := grid_to_world(pos)
	cursor.position = Vector3(world_pos.x, cursor.position.y, world_pos.z)
	cursor.show()


func _handle_attack_choice(pos: Vector3i) -> void:
	if path_map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		return

	active_move.end_pos = pos
	moves_stack.append(active_move)

	create_path(
		moves_stack.front().start_pos,
		moves_stack.front().end_pos
	)

	state = States.ANIMATING


func _is_invalid_tile(pos: Vector3i) -> bool:
	return get_tile_name(pos) == "Water"


func select_unit(unit: Character) -> void:
	# Switching unit
	_clear_selection()

	selected_unit = unit
	unit_pos = unit.state.grid_position
	_update_cursor(unit.state.grid_position)
	emit_signal("character_selected", selected_unit)

	current_moves = MoveGenerator.generate(selected_unit, game_state)
	movement_grid.fill_from_commands(current_moves, game_state)


func _handle_player_click(pos: Vector3i) -> void:
	# Heal execution shortcut
	if selected_unit == null:
		Tutorial.tutorial_unit_selected()

	unit_pos = pos
	movement_map.clear()

	# Same unit clicked again
	if selected_unit == get_unit(pos):
		active_move = Wait.new(pos)
		show_move_popup(get_viewport().get_mouse_position())
		return

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
	movement_map.clear()
	path_map.clear()

	selected_unit = null
	emit_signal("character_deselected")


func _handle_abilities(pos: Vector3i) -> bool:
	if is_using_ability:
		if movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
			for cmd: Heal in current_moves:
				if cmd.end_pos == pos:
					cmd.execute(game_state)
					is_using_ability = false
					selected_unit.state.is_moved = true
					get_unit(pos).update_health_bar()
					movement_map.clear()
					return true
	return false


func _print_all_nodes_or_something() -> void:
	var type_counts := {}


func _input(event: InputEvent) -> void:
	if not _can_handle_input(event):
		return
	
	var pos: Vector3i = get_grid_cell_from_mouse()
	print(pos)
	
	if _handle_abilities(pos):
		return

	_update_cursor(pos)

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
	if get_unit_name(pos) == CharacterStates.Enemy:
		selected_enemy_unit = get_unit(pos)

#	_count_node_types(get_tree().get_root(), type_counts)

	# Convert to array for sorting
	var sorted := []
#	for t: String in type_counts.keys():
#		sorted.append({
#			"type": t,
#			"count": type_counts[t]
#		})

	# Sort descending by count
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["count"] > b["count"]
	)

	print("=== Node Types in Scene (Descending) ===")
	for entry: Dictionary in sorted:
		print("%s: %d" % [entry["type"], entry["count"]])


func _count_node_types(node: Node, counts: Dictionary) -> void:
	var type_name := node.get_class()

	if not counts.has(type_name):
		counts[type_name] = 0
	counts[type_name] += 1


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_TAB:
				select_next_character()
			elif event.keycode == KEY_K:
				#_print_all_nodes_or_something()
				print_orphan_nodes()


func _ready() -> void:
	camera_controller = Main.camera_controller
	camera_controller.make_current()
	camera_controller.setup_minmax_positions(minimum_camera_x, maximum_camera_x, minimum_camera_z, maximum_camera_z)
	camera_controller.springarm_length_maximum = maximum_camera_height
	camera_controller.springarm_length_minimum = minimum_camera_height
	camera_controller.free_camera()
	
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
	
	#ribbon = RIBBON.instantiate();
	#add_child(ribbon);
	#ribbon.hide();
	
	if (level_name == "first"):
		Dialogic.start(str(level_name) + "Level");
		is_in_menu = true;
	if (level_name == "Fen"):
		Dialogic.start("Showcase_Intro")
		is_in_menu = true
	
	Main.battle_log = battle_log;
	
	var units :Array[Vector3i] = occupancy_map.get_used_cells();
	
	var characters_placed := 0;
	
	print("Loading new level, number of playable characters: " + str(Main.characters.size()));
	
	for i in units.size():
		var pos: Vector3 = units[i];
		var new_unit: Character = null;
		
		if (get_unit_name(pos) == "Unit"):
			if characters_placed < Main.characters.size():
				new_unit = Main.characters[characters_placed];
				new_unit.state.is_moved = false;
				new_unit.camera = get_viewport().get_camera_3d();
				characters_placed += 1;
				
				var health := str(new_unit.state.current_health)
				if health == "0":
					health = "fresh unit"
					
				print("This character exists: " + str(new_unit.data.unit_name) + " health: " + str(health) + ".");
			else:
				occupancy_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM);
		elif (get_unit_name(pos) == "Enemy"):
			new_unit = PLAYER.instantiate()
			
			var data := CharacterData.new()

			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY;

			new_unit.data = data
			new_unit.state = c_state

			new_unit.data.unit_name = monster_names[randi_range(0, monster_names.size() - 1)];
		elif (get_unit_name(pos) == "EnemyBird"):
			new_unit = BIRD_ENEMY.instantiate()
			
			var data := CharacterData.new()

			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY;

			new_unit.data = data
			new_unit.state = c_state

			new_unit.data.unit_name = monster_names[randi_range(0, monster_names.size() - 1)];

		elif (get_unit_name(pos) == "EnemyGhost"):
			new_unit = GHOST_ENEMY.instantiate()
			
			var data := CharacterData.new()

			var c_state := CharacterState.new()
			c_state.faction = CharacterState.Faction.ENEMY;

			new_unit.data = data
			new_unit.state = c_state

			new_unit.data.unit_name = monster_names[randi_range(0, monster_names.size() - 1)];
			
		elif (get_unit_name(pos) == "Chest"):
			var chest: Node = CHEST.instantiate();
			chest.position = grid_to_world(pos)

			add_child(chest);
		elif (get_unit_name(pos) == "VictoryTrigger"):
			pass
		else:
			occupancy_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM);
			
		if (new_unit != null):
			#unitArray.append(newUnit);
			new_unit.position = grid_to_world(pos)

			#newUnit = 2;
			if new_unit.get_parent():
				new_unit.reparent(Main.world, false);
			add_child(new_unit);
			characters.append(new_unit);
			
			if new_unit is Character:
				var character_script : Character = new_unit;
				#character_script.hide_ui();
				new_unit.state.grid_position = pos;
	
	move_popup = MOVE_POPUP.instantiate()
	move_popup.hide()
	add_child(move_popup)


	
	game_state = GameState.from_level(self)
	
	turn_transition_animation_player.play()
	#turn_transition.get_canvas().hide();
	#tiles = map.get_used_cells();
#	units.append(unit);
	add_to_group("level")
	emit_signal("party_updated", characters)
	



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
	movement_grid.fill_from_commands(MoveGenerator.generate(game_state.get_unit(moves_stack.front().start_pos), game_state), game_state)
	
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
		var move : Command = ai.choose_best_move(current_state, 2);
		moves_stack.append(move);
		current_state = current_state.apply_move(move, true);
	
	if (moves_stack.is_empty() == false):
		create_path(moves_stack.front().start_pos, moves_stack.front().end_pos); # a-star for pathfinding AI
		state = States.ANIMATING;
		camera_controller.focus_camera(selected_unit)
	else:
		camera_controller.free_camera()


func CheckVictoryConditions() -> void:
	var units :Array[Vector3i] = occupancy_map.get_used_cells();
	var numberOfPlayerUnits :int = 0;
	var numberOfEnemyUnits  :int = 0;
	
	for i in units.size():
		var pos :Vector3i = units[i];
		if (occupancy_map.get_cell_item(pos) == player_code || occupancy_map.get_cell_item(pos) == player_code_done):
			numberOfPlayerUnits += 1;
		elif (occupancy_map.get_cell_item(pos) >= enemy_code):
			numberOfEnemyUnits += 1;
	
	if (numberOfPlayerUnits == 0):
		get_tree().change_scene_to_file("res://scenes/states/gameover.tscn");
	elif (numberOfEnemyUnits == 0):
		Main.next_level();


func interpolate_to(target_transform:Transform3D, delta:float) -> void:
	#global_transform.origin = global_transform.origin.lerp(
	#	target_transform.origin,
	#	1.0 - exp(-camera_speed * delta)
	#)
	#
	#global_transform.basis = global_transform.basis.slerp(
	#	target_transform.basis,
	#	1.0 - exp(-camera_speed * delta)
	#)
	camera_controller.set_pivot_target_transform(target_transform);


func _process(delta: float) -> void:
	if (turn_transition_animation_player.is_playing()):
		turn_transition.show()
		camera_controller.lock_camera()
		return;
		
	#for i in Main.characters.size():
		#update_side_bar(Main.characters[i], side_bar_array[i]);
		
	turn_transition.hide();
	camera_controller.unlock_camera()
	
	if state == States.PLAYING and selected_unit and is_in_menu == false:
		var pos :Vector3i = get_grid_cell_from_mouse();
		if movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM:
			path_map.clear()
			var points := movement_grid.get_path(selected_unit.state.grid_position, pos)
			for point in points:
				path_map.set_cell_item(point, 0)
			#a_star(selected_unit.state.grid_position, pos); # a-star for drawing arrow
			#if get_unit(pos) is Character and get_unit(pos).state.is_enemy():
			#	update_stat(get_unit(pos), stat_popup_enemy);
	
	if (is_in_menu):
		return;
	
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
			reset_all_units();
			MoveAI();
	elif (state == States.ANIMATING):
		# Animations done: stop animating
		if (moves_stack.is_empty()):
			state = States.PLAYING;
			movement_map.clear()
			if (is_player_turn == false):
				is_animation_just_finished = true;
				is_player_turn = true;
		# Done with one move, execute it and start on next
		elif (animation_path.is_empty()):
			active_move = moves_stack.pop_front();
			if get_unit_name(active_move.end_pos) == "VictoryTrigger":
				Dialogic.start(level_name + "LevelVictory")
				
			active_move.execute(game_state)
			
			if active_move is Attack: 
				combat_vfx.play_attack(active_move.result)
			
			if is_player_turn:
				active_move = Wait.new(active_move.end_pos)
				show_move_popup(get_viewport().get_mouse_position())
			
			CheckVictoryConditions();
			var code := enemy_code;
			if is_player_turn:
				code = player_code_done;
			occupancy_map.set_cell_item(active_move.start_pos, GridMap.INVALID_CELL_ITEM);
			occupancy_map.set_cell_item(active_move.end_pos, code);
			selected_unit.move_to(active_move.end_pos);
			selected_unit.pause_anim()
			_clear_selection()

			completed_moves.append(active_move);
			Tutorial.tutorial_unit_moved();
			
			if is_player_turn == false:
				MoveAI(); # called after an enemy is done moving
			
			if (moves_stack.is_empty() == false):
				#called after any enemy except the final enemy is done moving
				create_path(moves_stack.front().start_pos, moves_stack.front().end_pos); # a-star for enemy animation/movement?
			
			if (animation_path.is_empty() == false):
				#called after any enemy except the final enemy is done moving
				selected_unit.position = animation_path.pop_front();
		# Process animation
		else:
			var movement_speed := 8.0 # units per second
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
