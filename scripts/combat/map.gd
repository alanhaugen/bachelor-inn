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
@onready var unitsMap: GridMap = $Units;
@onready var movementMap: GridMap = $MovementDots;
#@onready var collidable_terrain_layer: GridMap = $CollidableTerrainLayer
@onready var move_popup: Control = $MovePopup
@onready var path_arrow: GridMap = $PathArrow
@onready var turn_transition: CanvasLayer = $TurnTransition/CanvasLayer
@onready var turn_transition_animation_player: AnimationPlayer = $TurnTransition/AnimationPlayer

@onready var player_label: Label = $TurnTransition/CanvasLayer/VBoxContainer/ColorRect3/playerLabel
@onready var enemy_label: Label = $TurnTransition/CanvasLayer/VBoxContainer/ColorRect3/enemyLabel

var animated_unit: AnimatableBody3D;

const UNIT = preload("uid://btmpi20wskms7")
const ENEMY = preload("uid://beocud5p1563r")
const CHEST = preload("uid://ctcbsf1b8tg5x")

var animationPath :Array[Vector3i];
var isAnimationJustFinished :bool = false;

var is_dragging :bool = false;

enum States { PLAYING, ANIMATING };
var state :int = States.PLAYING;

var isUnitSelected: bool = false;
var inMenu: bool = false;
var activeMove: Move;
var movesStack: Array;

const Move = preload("res://scripts/combat/move.gd");

var is_player_turn: bool = true;
var unitPos        :Vector3;
var playerCode     :int = 0;
var playerCodeDone :int = 3;
var enemyCode      :int = 1;
var attackCode     :int = 0;


func Touch(pos :Vector3) -> bool:
	if (GetTileName(pos) != "Water" && unitsMap.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM):
		movementMap.set_cell_item(pos, 0);
		return true;
	return false;


func Dijkstra(startPos :Vector3i, movementLength :int) -> Array[Move]:
	var frontier :int = 0;
	var frontierPositions :Array;
	var nextFrontierPositions :Array;
	
	var pos   :Vector3i = startPos;
	var moves :Array[Move];
	
	frontierPositions.append(pos);
	var type :int = unitsMap.get_cell_item(pos);
	
	var tempEnemyCode :int = enemyCode;
	if (is_player_turn == false):
		enemyCode = playerCode;
	
	while (frontier < movementLength && frontierPositions.is_empty() == false):
		pos = frontierPositions.pop_front();
		
		var north :Vector3 = Vector3(pos.x, 0, pos.z - 1);
		var south :Vector3 = Vector3(pos.x, 0, pos.z + 1);
		var east  :Vector3 = Vector3(pos.x + 1, 0, pos.z);
		var west  :Vector3 = Vector3(pos.x - 1, 0, pos.z);
		
		if (Touch(north)):
			nextFrontierPositions.append(north);
			moves.append(Move.new(startPos, north, type, unitsMap));
		
		if (Touch(south)):
			nextFrontierPositions.append(south);
			moves.append(Move.new(startPos, south, type, unitsMap));
		
		if (Touch(east)):
			nextFrontierPositions.append(east);
			moves.append(Move.new(startPos, east, type, unitsMap));
		
		if (Touch(west)):
			nextFrontierPositions.append(west);
			moves.append(Move.new(startPos, west, type, unitsMap));
		
		# Add attack moves
		if (unitsMap.get_cell_item(north) == enemyCode):
			moves.append(Move.new(startPos, north, type, unitsMap, true));
			movementMap.set_cell_item(north, 0, attackCode);
		if (unitsMap.get_cell_item(south) == enemyCode):
			moves.append(Move.new(startPos, south, type, unitsMap, true));
			movementMap.set_cell_item(south, 0, attackCode);
		if (unitsMap.get_cell_item(east) == enemyCode):
			moves.append(Move.new(startPos, east, type, unitsMap, true));
			movementMap.set_cell_item(east, 0, attackCode);
		if (unitsMap.get_cell_item(west) == enemyCode):
			moves.append(Move.new(startPos, west, type, unitsMap, true));
			movementMap.set_cell_item(west, 0, attackCode);
		
		if (frontierPositions.is_empty() == true):
			frontier += 1;
			frontierPositions = nextFrontierPositions.duplicate();
			nextFrontierPositions.clear();
	
	enemyCode = tempEnemyCode;
	
	return moves;


func ShowMovePopup(windowPos :Vector2) -> void:
	move_popup.show();
	inMenu = true;
	move_popup.position = Vector2(windowPos.x + 64, windowPos.y);
	if (activeMove.isAttack):
		move_popup.attack_button.show();
	if (activeMove.isWait):
		move_popup.wait_button.show();
	if (activeMove.isAttack == false && activeMove.isWait == false):
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


func GetTileName(pos: Vector3) -> String:
	return map.mesh_library.get_item_name(map.get_cell_item(pos));


func GetUnitName(pos: Vector3) -> String:
	print(str(pos) + " " + str(unitsMap.get_cell_item(pos)));
	if unitsMap.get_cell_item(pos) == GridMap.INVALID_CELL_ITEM or unitsMap.get_cell_item(pos) == 7:
		return "null";
	return unitsMap.mesh_library.get_item_name(unitsMap.get_cell_item(pos));


func _input(event: InputEvent) -> void:
	if (state != States.PLAYING):
		return;
	if (inMenu):
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
		
		# Get the tile clicked on
		var pos :Vector3i = get_grid_cell_from_mouse();
		print (pos);
		
		if (GetTileName(pos) == "Water"):
			return;
		
		var globalPos: Vector3i = map.map_to_local(pos);
		cursor.position = Vector3(globalPos.x, cursor.position.y, globalPos.z);
		#map.set_cell(pos, 1);
		#unitsMap.set_cell(pos, 0, Vector2(14,3));
		cursor.show();
		
		if (GetUnitName(pos) == "Unit"):
			unitPos = pos;
			movementMap.clear();
			Dijkstra(pos, 3);
			#if (isUnitSelected == true):
			#	activeMove = Move.new(pos, pos, playerCodeDone, unitsMap);
			#	activeMove.isWait = true;
			#	##ShowMovePopup(windowPos);
			#else:
			#	Dijkstra(pos, 3);
			#	isUnitSelected = true;
		elif (movementMap.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM):
			activeMove = Move.new(unitPos, pos, playerCodeDone, unitsMap);
			if (movementMap.get_cell_item(pos) == attackCode):
				activeMove.isAttack = true;
			
			var windowPos: Vector2 = Vector2(0,0);
			ShowMovePopup(windowPos);
			AStar(unitPos, pos);
			
			#activeMove.execute();
			
			#unitsMap.set_cell_item(pos, playerCodeDone);
			#unitsMap.set_cell_item(unitPos, -1);
			movementMap.clear();
			#isUnitSelected = false;
		else:
			movementMap.clear();
			#isUnitSelected = false;
		
	#elif event is InputEventMouseMotion:
	#	print("Mouse Motion at: ", event.position)


#func _init() -> void:

func _ready() -> void:
	cursor.hide();
	movementMap.clear();
	unitsMap.hide();
	path_arrow.clear();
	
	var units :Array[Vector3i] = unitsMap.get_used_cells();
	
	for i in units.size():
		var pos: Vector3 = units[i];
		var newUnit: Node = null;
		if (GetUnitName(pos) == "Unit"):
			newUnit = UNIT.instantiate();
			newUnit.scale *= 5;
		elif (GetUnitName(pos) == "Enemy"):
			newUnit = ENEMY.instantiate();
			newUnit.scale *= 5;
		elif (GetUnitName(pos) == "Chest"):
			newUnit = CHEST.instantiate();
			
		if (newUnit != null):
			#unitArray.append(newUnit);
			newUnit.position = pos * 2;
			newUnit.position += Vector3(1, 0, 1);
			#newUnit = 2;
			add_child(newUnit);
	
	move_popup.hide();
	turn_transition_animation_player.play();
	#turn_transition.get_canvas().hide();
	#tiles = map.get_used_cells();
#	units.append(unit);


func AStar(start :Vector3i, end :Vector3i, showPath :bool = true) -> void:
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
			var pos :Vector2i = Vector2i(i, j);
			var pos3D :Vector3i = Vector3i(i, 0, j);
			if (GetTileName(pos3D) == "Water"):
				astar.set_point_solid(pos);
			if (GetUnitName(pos3D) != "null" && pos3D != end):
				astar.set_point_solid(pos);

	var path :PackedVector2Array = astar.get_point_path(Vector2i(start.x, start.z), Vector2i(end.x, end.z));
	
	if not path.is_empty():
		if (showPath):
			path_arrow.set_cells_terrain_connect(path, 0, 0);
	
		animationPath.clear();
		
		for i :int in path.size():
			animationPath.append(map.map_to_local(Vector3(path[i].x, 0.0, path[i].y)));

	if (animationPath.is_empty() == false):
		animated_unit.position = animationPath.pop_front();
	
	path_arrow.set_cell_item(start, -1);


func MoveAI() -> void:
	var units :Array[Vector3i] = unitsMap.get_used_cells();
	for i in units.size():
		var pos :Vector3i = units[i];
		if (unitsMap.get_cell_item(pos) == playerCodeDone):
			unitsMap.set_cell_item(pos, playerCode);
	
	var aiUnitsMoves :Array;
	for i in units.size():
		var pos :Vector3i = units[i];
		if (unitsMap.get_cell_item(pos) == enemyCode):
			aiUnitsMoves.append(Array());
			aiUnitsMoves[aiUnitsMoves.size() - 1] += Dijkstra(pos, 3);
	
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
		movesStack.append(move);

	movementMap.clear();
	animationPath.clear();
	
	if (movesStack.is_empty() == false):
		AStar(movesStack.front().startPos, movesStack.front().endPos, false);
		state = States.ANIMATING;


func CheckVictoryConditions() -> void:
	var units :Array[Vector3i] = unitsMap.get_used_cells();
	var numberOfPlayerUnits :int = 0;
	var numberOfEnemyUnits  :int = 0;
	
	for i in units.size():
		var pos :Vector3i = units[i];
		if (unitsMap.get_cell_item(pos) == playerCode || unitsMap.get_cell_item(pos) == playerCodeDone):
			numberOfPlayerUnits += 1;
		elif (unitsMap.get_cell_item(pos) == enemyCode):
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
		if (isAnimationJustFinished):
			isAnimationJustFinished = false;
			turn_transition_animation_player.play();
			enemy_label.hide();
			player_label.show();
		if (is_player_turn):
			is_player_turn = false;
			var units :Array[Vector3i] = unitsMap.get_used_cells();
			for i in units.size():
				var pos :Vector3i = units[i];
				if (unitsMap.get_cell_item(pos) == playerCode):
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
		if (movesStack.is_empty()):
			state = States.PLAYING;
			if (is_player_turn == false):
				isAnimationJustFinished = true;
				is_player_turn = true;
		# Done with one move, execute it and start on next
		elif (animationPath.is_empty()):
			activeMove = movesStack.pop_front();
			activeMove.execute();
			
			if (movesStack.is_empty() == false):
				AStar(movesStack.front().startPos, movesStack.front().endPos, false);
			
			if (animationPath.is_empty() == false):
				animated_unit.position = animationPath.pop_front();
		# Process animation
		else:
			if (is_equal_approx(animated_unit.position.x, animationPath.front().x) && is_equal_approx(animated_unit.position.y, animationPath.front().y)):
				animated_unit.position = animationPath.pop_front();
			else:
				var movement_speed :float = 5;
				var dir :Vector3 = animationPath.front() - animated_unit.position;
				animated_unit.position += dir.normalized() * movement_speed;# * delta);
			
			#animated_unit.position.x = animationPath
