class_name Level
extends Node3D
## Map logic for combat levels.
##
## All state and animation logic is found here,
## as well as input handling and audio playback.
# TODO: Stackable tiles for enemies
# TODO: Make your own units passable
# TODO: camp?
# TODO: Make enemies able to occopy several grid-tiles
# TODO: Abilities on level up

@export var level_name :String;

@export var camera_speed: float = 5.0;
@export var mouse_drag_sensitivity: float = 50.0;
@onready var battle_log: Label = $BattleLog

@onready var camera: Camera3D = $Camera3D;
@onready var cursor: Sprite3D = $Cursor;
@onready var map: GridMap = $Map;
@onready var units_map: GridMap = $Units;
@onready var movement_map: GridMap = $MovementDots;
#@onready var collidable_terrain_layer: GridMap = $CollidableTerrainLayer
@onready var path_arrow: GridMap = $PathArrow
@onready var turn_transition: CanvasLayer = $TurnTransition/CanvasLayer
@onready var turn_transition_animation_player: AnimationPlayer = $TurnTransition/AnimationPlayer

@onready var player_label: Label = $TurnTransition/CanvasLayer/VBoxContainer/ColorRect3/playerLabel
@onready var enemy_label: Label = $TurnTransition/CanvasLayer/VBoxContainer/ColorRect3/enemyLabel

@export var minimum_camera_height: float = 1.0;
@export var maximum_camera_height: float = 15.0;

var selected_unit: Character = null;
var selected_enemy_unit: Character = null;
var move_popup: Control;
var stat_popup_player: Control;
var side_bar_1: Control;
var side_bar_2: Control;
var side_bar_3: Control;
var stat_popup_enemy: Control;
var completed_moves :Array[Move];

var characters: Array[Character];

const STATS_POPUP = preload("res://scenes/ui/pop_up.tscn")
const MOVE_POPUP = preload("res://scenes/ui/move_popup.tscn")
const CHEST = preload("res://scenes/grid_items/chest.tscn")
const SIDE_BAR = preload("res://scenes/ui/sidebar.tscn")

var animation_path :Array[Vector3];
var is_animation_just_finished :bool = false;

var is_dragging :bool = false;

enum States { PLAYING, ANIMATING };
var state :int = States.PLAYING;

var is_in_menu: bool = false;
var active_move: Move;
var moves_stack: Array;

var current_moves: Array[Move];
var is_player_turn: bool = true;
var unit_pos: Vector3;
var player_code: int = 0;
var player_code_done: int = 3;
var enemy_code: int = 1;
var attack_code: int = 0;
var move_code: int = 1;


func touch(pos :Vector3) -> bool:
	if (get_tile_name(pos) != "Water" && units_map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM && movement_map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM):
		movement_map.set_cell_item(pos, move_code);
		return true;
	return false;


func dijkstra(startPos :Vector3i, movementLength :int) -> Array[Move]:
	var frontier :int = 0;
	var frontierPositions :Array;
	var nextFrontierPositions :Array;
	
	var pos: Vector3i = startPos;
	var moves: Array[Move];
	
	frontierPositions.append(pos);
	var type: int = units_map.get_cell_item(pos);
	
	var temp_enemy_code :int = enemy_code;
	if (is_player_turn == false):
		enemy_code = player_code;
	
	while (frontier < movementLength && frontierPositions.is_empty() == false):
		pos = frontierPositions.pop_front();
		
		var north: Vector3 = Vector3(pos.x, 0, pos.z - 1);
		var south: Vector3 = Vector3(pos.x, 0, pos.z + 1);
		var east: Vector3 = Vector3(pos.x + 1, 0, pos.z);
		var west :Vector3 = Vector3(pos.x - 1, 0, pos.z);
		
		# Only register non-attack moves for characters that have not moved yet
		if selected_unit.is_moved == false:
			if (touch(north)):
				nextFrontierPositions.append(north);
				moves.append(Move.new(startPos, north, type, units_map, selected_unit));
			
			if (touch(south)):
				nextFrontierPositions.append(south);
				moves.append(Move.new(startPos, south, type, units_map, selected_unit));
			
			if (touch(east)):
				nextFrontierPositions.append(east);
				moves.append(Move.new(startPos, east, type, units_map, selected_unit));
			
			if (touch(west)):
				nextFrontierPositions.append(west);
				moves.append(Move.new(startPos, west, type, units_map, selected_unit));
		
		# Add attack moves
		var neighbour_move: Move = Move.new(startPos, pos, type, units_map, selected_unit);
		if (units_map.get_cell_item(north) == enemy_code):
			moves.append(Move.new(neighbour_move.end_pos, north, type, units_map, selected_unit, true, get_unit(north), neighbour_move));
			movement_map.set_cell_item(north, 0, attack_code);
		if (units_map.get_cell_item(south) == enemy_code):
			moves.append(Move.new(neighbour_move.end_pos, south, type, units_map, selected_unit, true, get_unit(south), neighbour_move));
			movement_map.set_cell_item(south, 0, attack_code);
		if (units_map.get_cell_item(east) == enemy_code):
			moves.append(Move.new(neighbour_move.end_pos, east, type, units_map, selected_unit, true, get_unit(east), neighbour_move));
			movement_map.set_cell_item(east, 0, attack_code);
		if (units_map.get_cell_item(west) == enemy_code):
			moves.append(Move.new(neighbour_move.end_pos, west, type, units_map, selected_unit, true, get_unit(west), neighbour_move));
			movement_map.set_cell_item(west, 0, attack_code);
		
		# Add chest interaction
		#if (units_map.get_cell_item(north) == chest_code):
		#	moves.append(Move.new(neighbour_move.end_pos, north, type, units_map, selected_unit, true, get_unit(north), neighbour_move));
		#	movement_map.set_cell_item(north, 0, interaction_code);
		#if (units_map.get_cell_item(south) == chest_code):
		#	moves.append(Move.new(neighbour_move.end_pos, south, type, units_map, selected_unit, true, get_unit(south), neighbour_move));
		#	movement_map.set_cell_item(south, 0, interaction_code);
		#if (units_map.get_cell_item(east) == chest_code):
		#	moves.append(Move.new(neighbour_move.end_pos, east, type, units_map, selected_unit, true, get_unit(east), neighbour_move));
		#	movement_map.set_cell_item(east, 0, interaction_code);
		#if (units_map.get_cell_item(west) == chest_code):
		#	moves.append(Move.new(neighbour_move.end_pos, west, type, units_map, selected_unit, true, get_unit(west), neighbour_move));
		#	movement_map.set_cell_item(west, 0, interaction_code);
		
		if (frontierPositions.is_empty() == true):
			frontier += 1;
			frontierPositions = nextFrontierPositions.duplicate();
			nextFrontierPositions.clear();
	
	enemy_code = temp_enemy_code;
	
	return moves;


func show_move_popup(window_pos :Vector2) -> void:
	move_popup.show();
	is_in_menu = true;
	move_popup.position = Vector2(window_pos.x + 64, window_pos.y);
	if (active_move.is_attack):
		move_popup.attack_button.show();
	if (active_move.is_wait):
		move_popup.wait_button.show();
	if (active_move.is_attack == false && active_move.is_wait == false):
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


func get_grid_cell_from_mouse() -> Vector3i:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position();
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_direction: Vector3 = camera.project_ray_normal(mouse_pos)
	
	# Cast ray and get intersection point
	var intersection: Vector3 = raycast_to_gridmap(ray_origin, ray_direction)
	if intersection != null:
		# Convert world position to grid coordinates
		var grid_pos: Vector3i = map.local_to_map(map.to_local(intersection));
		return grid_pos;
	
	return Vector3i();


func get_tile_name(pos: Vector3) -> String:
	if map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		return "null";
	return map.mesh_library.get_item_name(map.get_cell_item(pos));


# Expanded the function to do some error searching
func get_unit_name(pos: Vector3) -> String:
	var item_id: int = units_map.get_cell_item(pos)
	if item_id == GridMap.INVALID_CELL_ITEM:
		return "null"
		
	if item_id >= units_map.mesh_library.get_item_list().size():
		push_warning("Invalid MeshLibrary item: " + str(item_id) + " at position: " + str(pos))
		return "null"
		
	return units_map.mesh_library.get_item_name(item_id)
	
	#if units_map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		#return "null";
	#return units_map.mesh_library.get_item_name(units_map.get_cell_item(pos));


func _input(event: InputEvent) -> void:
	if (state != States.PLAYING):
		return;
	if (is_in_menu):
		return;
	
	if (event is InputEventMouseMotion and is_dragging):
		camera.global_translate(Vector3(-event.relative.x,0,-event.relative.y) / mouse_drag_sensitivity);
	
	if event is InputEventMouseButton:
		# Ignore mouse up events
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			Input.mouse_mode = Input.MouseMode.MOUSE_MODE_CAPTURED;
			is_dragging = true;
		if (event.pressed == false):
			is_dragging = false;
			Input.mouse_mode = Input.MouseMode.MOUSE_MODE_VISIBLE;
			return;
		if (event.button_index != MOUSE_BUTTON_LEFT):
			return;
		
		if (selected_enemy_unit != null):
			selected_enemy_unit.hide_ui();
			stat_popup_enemy.hide();
			if selected_unit == null:
				stat_popup_player.hide();
		
		# Get the tile clicked on
		var pos :Vector3i = get_grid_cell_from_mouse();
		print (pos);
		
		if (get_tile_name(pos) == "Water"):
			return;
		
		var globalPos: Vector3i = map.map_to_local(pos);
		cursor.position = Vector3(globalPos.x, cursor.position.y, globalPos.z);
		#map.set_cell(pos, 1);
		#unitsMap.set_cell(pos, 0, Vector2(14,3));
		cursor.show();
		
		var windowPos: Vector2 = Vector2(0,0);
		
		if (get_unit_name(pos) == CharacterStates.Player):
			Main.tutorial_unit_selected();
			unit_pos = pos;
			movement_map.clear();
			if (selected_unit == get_unit(pos)):
				active_move = Move.new(pos, pos, player_code_done, units_map, selected_unit);
				active_move.is_wait = true;
				show_move_popup(windowPos);
				#show_move_popup(selected_unit.get_unit(pos))
			else:
				if selected_unit != null:
					var character_script: Character = selected_unit;
					character_script.hide_ui();
				selected_unit = get_unit(pos);
				current_moves = dijkstra(pos, get_unit(pos).movement);
				#camera.position.x = selected_unit.position.x;# + 4.5;
				#camera.position.z = selected_unit.position.z + 3.0;#6.5;
				update_stat(selected_unit, stat_popup_player);
		elif (movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM):
			for i in range(current_moves.size()):
				if current_moves[i].end_pos == pos:
					active_move = current_moves[i];
					active_move.aggressor = selected_unit;
					active_move.grid_code = player_code;
					if active_move.neighbour_move:
						active_move.neighbour_move.grid_code = player_code_done;
						active_move.neighbour_move.aggressor = active_move.aggressor;
					break;
			
			show_move_popup(windowPos);
			a_star(unit_pos, pos);
			
			#activeMove.execute();
			
			#unitsMap.set_cell_item(pos, playerCodeDone);
			#unitsMap.set_cell_item(unitPos, -1);
			movement_map.clear();
			#isUnitSelected = false;
		else:
			movement_map.clear();
			
			if selected_unit is Character:
				var character_script: Character = selected_unit;
				character_script.hide_ui();
			
			selected_unit = null;
		
		if (get_unit_name(pos) == CharacterStates.Enemy):
			
			selected_enemy_unit = get_unit(pos);
			update_stat(selected_enemy_unit, stat_popup_enemy);
		
		if (get_unit_name(pos) == CharacterStates.PlayerDone):
			update_stat(get_unit(pos), stat_popup_player);
	#elif event is InputEventMouseMotion:
	#	print("Mouse Motion at: ", event.position)


func update_stat(character: Character, popup: StatPopUp) -> void:
	if character is Character:
		var character_script: Character = character;
		character_script.show_ui();
		character_script.print_stats();
		if popup is StatPopUp:
			var stat_script: StatPopUp = popup;
			stat_script.icon_texture.texture = character_script.portrait;
			stat_script.name_label.text = character_script.unit_name;
			stat_script.max_health = character_script.max_health;
			stat_script.health = character_script.current_health;
			stat_script.max_magic = character_script.magic;
			stat_script.magic = character_script.current_magic;
			stat_script.max_sanity = character_script.mind;
			stat_script.sanity = character_script.current_sanity;
			popup.show();


func _exit_tree() -> void:
	# Wait... is this never called?
	print("Unloading level, exit tree called.");
	move_popup.hide();
	stat_popup_enemy.hide();
	stat_popup_enemy.hide();
	
	# Remove sidebar
	#for i in range(Main.characters.size()):
	# etc.


func _ready() -> void:
	cursor.hide();
	movement_map.clear();
	units_map.hide();
	path_arrow.clear();
	
	if (level_name == "first"):
		Dialogic.start(str(level_name) + "Level");
		is_in_menu = true;
	
	Main.battle_log = battle_log;
	
	var units :Array[Vector3i] = units_map.get_used_cells();
	
	var characters_placed := 0;
	
	# Remove dead characters from character list
	var is_done := false;
	while (is_done == false):
		for i in range(Main.characters.size()):
			is_done = true;
			if Main.characters[i].is_alive == false:
				Main.characters.remove_at(i);
				is_done = false;
				break;
	
	print("Loading new level, number of playable characters: " + str(Main.characters.size()));
	
	for i in units.size():
		var pos: Vector3 = units[i];
		var new_unit: Character = null;
		
		if (get_unit_name(pos) == "Unit"):
			if characters_placed < Main.characters.size():
				new_unit = Main.characters[characters_placed];
				new_unit.camera = get_viewport().get_camera_3d();
				characters_placed += 1;
				print("This character exists: " + str(new_unit.unit_name) + " health: " + str(new_unit.current_health));
			else:
				units_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM);
		elif (get_unit_name(pos) == "Enemy"):
			#new_unit = ENEMY.instantiate();
			new_unit = Character.new();
			new_unit.is_playable = false;
			new_unit.unit_name = "Pth'Khuleroth";
			if randi_range(1,2) == 1:
				new_unit.sprite_sheet_path = "res://art/textures/enemy1.png";
			else:
				new_unit.sprite_sheet_path = "res://art/textures/enemy2.png";
		elif (get_unit_name(pos) == "Chest"):
			var chest: Node = CHEST.instantiate();
			chest.position = pos * 2;
			chest.position += Vector3(1, 0, 1);
			add_child(chest);
		else:
			units_map.set_cell_item(pos, GridMap.INVALID_CELL_ITEM);
			
		if (new_unit != null):
			#unitArray.append(newUnit);
			new_unit.position = pos * 2;
			new_unit.position += Vector3(1, 0, 1);
			#newUnit = 2;
			if new_unit.get_parent():
				new_unit.reparent(Main.world, false);
			add_child(new_unit);
			characters.append(new_unit);
			
			if new_unit is Character:
				var character_script: Character = new_unit;
				character_script.hide_ui();
				new_unit.grid_position = pos;
	
	move_popup = MOVE_POPUP.instantiate();
	move_popup.hide();
	Main.gui.add_child(move_popup);
	
	stat_popup_player = STATS_POPUP.instantiate();
	stat_popup_player.hide();
	stat_popup_player.scale = Vector2(Main.ui_scale, Main.ui_scale);
	stat_popup_player.position = Vector2(-get_window().size.x / 2.1, get_window().size.y / 2.5);
	#stat_popup_player.position = Vector2(-555, 235);
	#stat_popup_player.set_anchor(SIDE_LEFT, 0);
	#stat_popup_player.offset_bottom = get_window().size.y/(Main.ui_scale);
	Main.gui.add_child(stat_popup_player);
	
	stat_popup_enemy = STATS_POPUP.instantiate();
	stat_popup_enemy.hide();
	stat_popup_enemy.scale = Vector2(Main.ui_scale, Main.ui_scale);
	stat_popup_enemy.position = Vector2(get_window().size.x /4.6, get_window().size.y / 2.5);
	#stat_popup_enemy.position = Vector2(250, 235);
	#stat_popup_enemy.set_anchor(SIDE_RIGHT, 0);
	Main.gui.add_child(stat_popup_enemy);
	
	for i in range(Main.characters.size()):
		var new_side_bar := SIDE_BAR.instantiate();
		new_side_bar.scale = Vector2(Main.ui_scale, Main.ui_scale);
		if i != 0:
			new_side_bar.offset_bottom = -get_window().size.y/(15/Main.ui_scale)*i;
		Main.gui.add_child(new_side_bar);
	
	#side_bar_1 = SIDE_BAR.instantiate();
	#Main.gui.add_child(side_bar_1);
	#
	#side_bar_2 = SIDE_BAR.instantiate();
	#side_bar_2.offset_bottom = -get_window().size.y/15;
	#Main.gui.add_child(side_bar_2);
	#
	#side_bar_3 = SIDE_BAR.instantiate();
	#side_bar_3.offset_bottom = -get_window().size.y/7.5;
	#Main.gui.add_child(side_bar_3);

	
	turn_transition_animation_player.play();
	#turn_transition.get_canvas().hide();
	#tiles = map.get_used_cells();
#	units.append(unit);


func get_unit(pos: Vector3i) -> Character:
	for i in range(characters.size()):
		if is_instance_valid(characters[i]):
			if characters[i] is Character:
				var unit: Character = characters[i];
				if unit.grid_position == pos:
					return unit;
	push_error("Did not find character at " + str(pos));
	return null;


func a_star(start :Vector3i, end :Vector3i, showPath :bool = true) -> void:
	path_arrow.clear();
	
	var astar :AStarGrid2D = AStarGrid2D.new();
	
	astar.region = Rect2i(0, 0, 40, 40);
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update();

	# Fill in the data from the tilemap layers into the a-star datastructure
	for i in range(astar.region.position.x, astar.region.end.x):
		for j in range(astar.region.position.y, astar.region.end.y):
			var pos: Vector2i = Vector2i(i, j);
			var pos3D: Vector3i = Vector3i(i - 11, 0, j - 15);
			if (get_tile_name(pos3D) == "Water"):
				astar.set_point_solid(pos);
			if (get_unit_name(pos3D) != "null" && pos3D != end):
				astar.set_point_solid(pos);

	var path :PackedVector2Array = astar.get_point_path(Vector2i(start.x + 11, start.z + 15), Vector2i(end.x + 11, end.z + 15));
	
	if not path.is_empty():
		if (showPath):
			for i in range(path.size()):
				var pos: Vector3 = Vector3(path[i].x - 11, 0, path[i].y - 15);
				path_arrow.set_cell_item(pos, 0);
	
		animation_path.clear();
		
		for i :int in path.size():
			var anim_pos: Vector3 = map.map_to_local(Vector3(path[i].x - 11, 0.0, path[i].y - 15));
			anim_pos.y = 0;
			animation_path.append(anim_pos);
	
	selected_unit = get_unit(start);
	
	#if (animation_path.is_empty() == false):
	#	animated_unit.position = animation_path.pop_front();
	
	path_arrow.set_cell_item(start, GridMap.INVALID_CELL_ITEM);


func reset_all_units() -> void:
	var units :Array[Vector3i] = units_map.get_used_cells();
	for i in units.size():
		var pos :Vector3i = units[i];
		if (units_map.get_cell_item(pos) == player_code_done):
			units_map.set_cell_item(pos, player_code);
		var character: Character = get_unit(pos);
		if character is Character:
			var character_script: Character = character;
			character_script.reset();


func MoveAI() -> void:
	reset_all_units();
	
	var aiUnitsMoves :Array = [];
	var units :Array[Vector3i] = units_map.get_used_cells();
	var current_state : GameState = GameState.new();
	
	# Make array of all possible moves
	for i in range(units.size()):
		var pos :Vector3i = units[i];
		if (units_map.get_cell_item(pos) == enemy_code):
			aiUnitsMoves.append(Array());
			selected_unit = get_unit(pos);
			aiUnitsMoves[aiUnitsMoves.size() - 1] += dijkstra(pos, get_unit(pos).movement);
			
			current_state.units.append(get_unit(pos));
			current_state.moves += dijkstra(pos, get_unit(pos).movement);
	
	# Move each enemy unit
	for i :int in range(aiUnitsMoves.size()):
		var move :Move = null;
		
		# First look for an attack
		for j :int in range(aiUnitsMoves[i].size()):
			if (aiUnitsMoves[i][j].is_attack == true):
				move = aiUnitsMoves[i][j];
				break;
		
		# No attacks found, choose the best move based on minimax algorithm
		if move == null and aiUnitsMoves[i].is_empty() == false:
			#move = choose_best_move(current_state, 2);
			# Choose random move
			move = aiUnitsMoves[i][randi() % aiUnitsMoves[i].size()];
		
		# Do the attack or move
		if move == null:
			push_error("No moves found for enemy");
			continue;
			
		if move.is_attack:
			moves_stack.append(move.neighbour_move);
		
		moves_stack.append(move);
		
		# Remove move from ai stack
		aiUnitsMoves[i].erase(move);
	
	movement_map.clear(); 
	animation_path.clear();
	
	if (moves_stack.is_empty() == false):
		a_star(moves_stack.front().start_pos, moves_stack.front().end_pos, false);
		state = States.ANIMATING;


func CheckVictoryConditions() -> void:
	var units :Array[Vector3i] = units_map.get_used_cells();
	var numberOfPlayerUnits :int = 0;
	var numberOfEnemyUnits  :int = 0;
	
	for i in units.size():
		var pos :Vector3i = units[i];
		if (units_map.get_cell_item(pos) == player_code || units_map.get_cell_item(pos) == player_code_done):
			numberOfPlayerUnits += 1;
		elif (units_map.get_cell_item(pos) == enemy_code):
			numberOfEnemyUnits += 1;
	
	if (numberOfPlayerUnits == 0):
		get_tree().change_scene_to_file("res://scenes/states/gameover.tscn");
	elif (numberOfEnemyUnits == 0):
		Main.next_level();


func _process(delta: float) -> void:
	if (turn_transition_animation_player.is_playing()):
		turn_transition.show();
		return;
	
	turn_transition.hide();
	
	if Input.is_action_pressed("pan_right"):
		camera.global_translate(Vector3(1,0,0) * camera_speed * delta);
		#camera.global_translate(Vector3(1,0,-1) * camera_speed * delta);
		Main.tutorial_camera_moved();
	if Input.is_action_pressed("pan_left"):
		camera.global_translate(Vector3(-1,0,0) * camera_speed * delta);
		#camera.global_translate(Vector3(-1,0,1) * camera_speed * delta);
	if Input.is_action_pressed("pan_up"):
		camera.global_translate(Vector3(0,0,-1) * camera_speed * delta);
		#camera.global_translate(Vector3(-1,0,-1) * camera_speed * delta);
	if Input.is_action_pressed("pan_down"):
		camera.global_translate(Vector3(0,0,1) * camera_speed * delta);
		#camera.global_translate(Vector3(1,0,1) * camera_speed * delta);
	if Input.is_action_pressed("selected"):
		pass;
	
	if camera.global_position.y > minimum_camera_height:
		if Input.is_action_just_released("zoom_in") or Input.is_action_pressed("zoom_in"):
			camera.global_position -= camera.global_transform.basis.z * camera_speed * 20 * delta;
	if camera.global_position.y < maximum_camera_height:
		if Input.is_action_just_released("zoom_out") or Input.is_action_pressed("zoom_out"):
			camera.global_position += camera.global_transform.basis.z * camera_speed * 20 * delta;
	
	if (state == States.PLAYING):
		if (is_animation_just_finished):
			is_animation_just_finished = false;
			turn_transition_animation_player.play();
			enemy_label.hide();
			player_label.show();
		if (is_player_turn):
			is_player_turn = false;
			var units :Array[Vector3i] = units_map.get_used_cells();
			for i in units.size():
				var pos :Vector3i = units[i];
				if (units_map.get_cell_item(pos) == player_code):
					is_player_turn = true;
			if (is_player_turn == false):
				turn_transition_animation_player.play();
				enemy_label.show();
				player_label.hide();
		else:
			MoveAI();
			CheckVictoryConditions();
	elif (state == States.ANIMATING):
		# Animations done: stop animating
		if (moves_stack.is_empty()):
			state = States.PLAYING;
			if (is_player_turn == false):
				is_animation_just_finished = true;
				is_player_turn = true;
		# Done with one move, execute it and start on next
		elif (animation_path.is_empty()):
			selected_unit = null;
			active_move = moves_stack.pop_front();
			active_move.execute();
			completed_moves.append(active_move);
			
			if (moves_stack.is_empty() == false and moves_stack.front().is_attack == false):
				a_star(moves_stack.front().start_pos, moves_stack.front().end_pos, false);
			
			if (animation_path.is_empty() == false):
				selected_unit.position = animation_path.pop_front();
		# Process animation
		else:
			if (is_equal_approx(selected_unit.position.x, animation_path.front().x) && is_equal_approx(selected_unit.position.z, animation_path.front().z)):
				selected_unit.position = animation_path.pop_front();
			else:
				var movement_speed :float = 0.05;
				var dir :Vector3 = animation_path.front() - selected_unit.position;
				selected_unit.position += dir.normalized() * movement_speed;# * delta);
				#camera.position.x = selected_unit.position.x;# + 4.5;
				#camera.position.z = selected_unit.position.z + 3.0;#6.5;
				
				#if (dir.z > 0):
				#	selected_unit.sprite.play_clip("walk_up");
				#elif (dir.z < 0):
				#	selected_unit.sprite.play_clip("walk_down");
				#elif (dir.x > 0):
				#	selected_unit.sprite.play_clip("walk_side");
				#	selected_unit.sprite.flip_h = false;
				#elif (dir.x < 0):
				#	selected_unit.sprite.play_clip("walk_side");
				#	selected_unit.sprite.flip_h = true;
			
			#animated_unit.position.x = animationPath
