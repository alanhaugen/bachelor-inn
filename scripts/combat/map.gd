class_name Map extends Node3D
## Map logic for combat levels.
##
## All state and animation logic is found here,
## as well as input handling and audio playback.
# TODO: Stackable tiles for enemies
# TODO: Make your own units passable
# TODO: camp?

@export var camera_speed: float = 5.0;
@export var mouse_drag_sensitivity: float = 50.0;
@export var dialogue: Array[String];

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

var selected_unit: Character = null;
var move_popup: Control;

const MOVE_POPUP = preload("res://scenes/ui/move_popup.tscn")
const UNIT = preload("res://scenes/characters/unit.tscn")
const ENEMY = preload("res://scenes/characters/enemy.tscn")
const CHEST = preload("res://scenes/grid_items/chest.tscn")

var animation_path :Array[Vector3];
var is_animation_just_finished :bool = false;

var is_dragging :bool = false;

enum States { PLAYING, ANIMATING };
var state :int = States.PLAYING;

var is_in_menu: bool = false;
var active_move: Move;
var moves_stack: Array;

const Move = preload("res://scripts/combat/move.gd");

var is_player_turn: bool = true;
var unit_pos: Vector3;
var player_code: int = 0;
var player_code_done: int = 3;
var enemy_code: int = 1;
var attack_code: int = 0;
var move_code: int = 1;
var characters: Array[Character];


func touch(pos :Vector3) -> bool:
	if (get_tile_name(pos) != "Water" && units_map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM):
		movement_map.set_cell_item(pos, move_code);
		return true;
	return false;


func dijkstra(startPos :Vector3i, movementLength :int) -> Array[Move]:
	var frontier :int = 0;
	var frontierPositions :Array;
	var nextFrontierPositions :Array;
	
	var pos   :Vector3i = startPos;
	var moves :Array[Move];
	
	frontierPositions.append(pos);
	var type :int = units_map.get_cell_item(pos);
	
	var temp_enemy_code :int = enemy_code;
	if (is_player_turn == false):
		enemy_code = player_code;
	
	while (frontier < movementLength && frontierPositions.is_empty() == false):
		pos = frontierPositions.pop_front();
		
		var north :Vector3 = Vector3(pos.x, 0, pos.z - 1);
		var south :Vector3 = Vector3(pos.x, 0, pos.z + 1);
		var east  :Vector3 = Vector3(pos.x + 1, 0, pos.z);
		var west  :Vector3 = Vector3(pos.x - 1, 0, pos.z);
		
		if (touch(north)):
			nextFrontierPositions.append(north);
			moves.append(Move.new(startPos, north, type, units_map));
		
		if (touch(south)):
			nextFrontierPositions.append(south);
			moves.append(Move.new(startPos, south, type, units_map));
		
		if (touch(east)):
			nextFrontierPositions.append(east);
			moves.append(Move.new(startPos, east, type, units_map));
		
		if (touch(west)):
			nextFrontierPositions.append(west);
			moves.append(Move.new(startPos, west, type, units_map));
		
		# Add attack moves
		if (units_map.get_cell_item(north) == enemy_code):
			moves.append(Move.new(startPos, north, type, units_map, true));
			movement_map.set_cell_item(north, 0, attack_code);
		if (units_map.get_cell_item(south) == enemy_code):
			moves.append(Move.new(startPos, south, type, units_map, true));
			movement_map.set_cell_item(south, 0, attack_code);
		if (units_map.get_cell_item(east) == enemy_code):
			moves.append(Move.new(startPos, east, type, units_map, true));
			movement_map.set_cell_item(east, 0, attack_code);
		if (units_map.get_cell_item(west) == enemy_code):
			moves.append(Move.new(startPos, west, type, units_map, true));
			movement_map.set_cell_item(west, 0, attack_code);
		
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
	if (active_move.isAttack):
		move_popup.attack_button.show();
	if (active_move.isWait):
		move_popup.wait_button.show();
	if (active_move.isAttack == false && active_move.isWait == false):
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


func get_unit_name(pos: Vector3) -> String:
	if units_map.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM:
		return "null";
	return units_map.mesh_library.get_item_name(units_map.get_cell_item(pos));


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
		
		if (get_unit_name(pos) == "Unit"):
			unit_pos = pos;
			movement_map.clear();
			if (selected_unit == get_unit(pos)):
				active_move = Move.new(pos, pos, player_code_done, units_map);
				active_move.isWait = true;
				show_move_popup(windowPos);
			else:
				dijkstra(pos, 3);
				if selected_unit != null:
					var character_script: Character = selected_unit;
					character_script.hide_ui();
				selected_unit = get_unit(pos);
				if selected_unit is Character:
					var character_script: Character = selected_unit;
					character_script.show_ui();
		elif (movement_map.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM):
			active_move = Move.new(unit_pos, pos, player_code_done, units_map);
			if (movement_map.get_cell_item(pos) == attack_code):
				active_move.isAttack = true;
			
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
		
	#elif event is InputEventMouseMotion:
	#	print("Mouse Motion at: ", event.position)


#func _init() -> void:

func _ready() -> void:
	cursor.hide();
	movement_map.clear();
	units_map.hide();
	path_arrow.clear();
	
	var units :Array[Vector3i] = units_map.get_used_cells();
	
	for i in units.size():
		var pos: Vector3 = units[i];
		var new_unit: Character = null;
		
		if (get_unit_name(pos) == "Unit"):
			new_unit = UNIT.instantiate();
			characters.append(new_unit);
		elif (get_unit_name(pos) == "Enemy"):
			new_unit = ENEMY.instantiate();
			characters.append(new_unit);
		elif (get_unit_name(pos) == "Chest"):
			var chest: Node = CHEST.instantiate();
			chest.position = pos * 2;
			chest.position += Vector3(1, 0, 1);
			add_child(chest);
			
		if (new_unit != null):
			#unitArray.append(newUnit);
			new_unit.position = pos * 2;
			new_unit.position += Vector3(1, 0, 1);
			#newUnit = 2;
			add_child(new_unit);
			
			if new_unit is Character:
				var character_script: Character = new_unit;
				character_script.hide_ui();
				new_unit.grid_position = pos;
	
	move_popup = MOVE_POPUP.instantiate();
	move_popup.hide();
	Main.gui.add_child(move_popup);
	
	turn_transition_animation_player.play();
	#turn_transition.get_canvas().hide();
	#tiles = map.get_used_cells();
#	units.append(unit);


func get_unit(pos: Vector3i) -> Character:
	for i in range(characters.size()):
		if (is_instance_valid(characters[i])):
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


func MoveAI() -> void:
	var units :Array[Vector3i] = units_map.get_used_cells();
	for i in units.size():
		var pos :Vector3i = units[i];
		if (units_map.get_cell_item(pos) == player_code_done):
			units_map.set_cell_item(pos, player_code);
			var character: Character = get_unit(pos);
			if character is Character:
				var character_script: Character = character;
				character.reset();
	
	var aiUnitsMoves :Array;
	for i in units.size():
		var pos :Vector3i = units[i];
		if (units_map.get_cell_item(pos) == enemy_code):
			aiUnitsMoves.append(Array());
			aiUnitsMoves[aiUnitsMoves.size() - 1] += dijkstra(pos, 3);
	
	# Move each enemy unit
	for i :int in aiUnitsMoves.size():
		var move :Move = null;
		
		# First look for an attack
		for j :int in aiUnitsMoves[i].size():
			if (aiUnitsMoves[i][j].isAttack == true):
				move = aiUnitsMoves[i][j];
		
		# No attacks found, choose a random move
		if move == null:
			move = aiUnitsMoves[i][randi() % aiUnitsMoves[i].size()];
		
		# Do the attack or move
		moves_stack.append(move);

	movement_map.clear();
	animation_path.clear();
	
	if (moves_stack.is_empty() == false):
		a_star(moves_stack.front().startPos, moves_stack.front().endPos, false);
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
		get_tree().change_scene_to_file("res://scenes/states/victory.tscn");


func _process(delta: float) -> void:
	if (turn_transition_animation_player.is_playing()):
		turn_transition.show();
		return;
	
	turn_transition.hide();
	
	if Input.is_action_pressed("pan_right"):
		camera.global_translate(Vector3(1,0,0) * camera_speed * delta);
	if Input.is_action_pressed("pan_left"):
		camera.global_translate(Vector3(-1,0,0) * camera_speed * delta);
	if Input.is_action_pressed("pan_up"):
		camera.global_translate(Vector3(0,0,-1) * camera_speed * delta);
	if Input.is_action_pressed("pan_down"):
		camera.global_translate(Vector3(0,0,1) * camera_speed * delta);
	if Input.is_action_pressed("selected"):
		pass;
	
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
			if (active_move.isAttack):
				var attacked_unit: Character = get_unit(active_move.endPos);
				if attacked_unit is Character:
					attacked_unit.queue_free();
			if selected_unit is Character:
					var character_script: Character = selected_unit;
					character_script.move_to(active_move.endPos);
			selected_unit = null;
			active_move = moves_stack.pop_front();
			active_move.execute();
			
			if (moves_stack.is_empty() == false):
				a_star(moves_stack.front().startPos, moves_stack.front().endPos, false);
			
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
			
			#animated_unit.position.x = animationPath
