class_name Map extends Node3D

# TODO: Stackable tiles for enemies
# TODO: Make your own units passable
# TODO: camp?

@export var dialogue : Array[String];

@onready var camera: 					Camera3D 			= $Camera;
@onready var cursor: 					Sprite3D 			= $Cursor;
@onready var map:						GridMap 				= $Map;
@onready var unitsMap:					GridMap 				= $Units;
@onready var movementMap:				GridMap 				= $MovementDots;
@onready var collidable_terrain_layer:	GridMap 				= $CollidableTerrainLayer
@onready var move_popup:					Control 				= $MovePopup
@onready var path_arrow:					TileMapLayer 		= $PathArrow
@onready var animated_unit:				AnimatedSprite2D 	= $AnimatedUnit
@onready var turn_transition	:			CanvasLayer			= $TurnTransition/CanvasLayer
@onready var animation_player:			AnimationPlayer 		= $TurnTransition/AnimationPlayer

@onready var player_label: Label = $TurnTransition/CanvasLayer/VBoxContainer/ColorRect3/playerLabel
@onready var enemy_label: Label = $TurnTransition/CanvasLayer/VBoxContainer/ColorRect3/enemyLabel

var animationPath :Array[Vector2];
var isAnimationJustFinished :bool = false;

enum States { PLAYING, ANIMATING };
var state :int = States.PLAYING;

var isUnitSelected :bool = false;
var inMenu         :bool = false;
var activeMove     :Move;
var movesStack     :Array;

const Move = preload("res://scripts/combat/move.gd");

var playerTurn     :bool = true;
var unitPos        :Vector2;
var playerCode     :Vector2i = Vector2i(29, 69);
var playerCodeDone :Vector2i = Vector2i(28, 75);
var enemyCode      :Vector2i = Vector2i(18, 80);
var attackCode     :Vector2i = Vector2i(22,27);

func Touch(pos :Vector3) -> bool:
	if (collidable_terrain_layer.get_cell_source_id(pos) == -1 && unitsMap.get_cell_source_id(pos) == -1):
		movementMap.set_cell(pos, 6, Vector2i(0,0));
		return true;
	return false;

func Dijkstra(startPos :Vector3i, movementLength :int) -> Array[Move]:
	var frontier :int = 0;
	var frontierPositions :Array;
	var nextFrontierPositions :Array;
	
	var pos   :Vector3i = startPos;
	var moves :Array[Move];
	
	frontierPositions.append(pos);
	var type :Vector2i = unitsMap.get_cell_atlas_coords(pos);
	
	var tempEnemyCode :Vector2i = enemyCode;
	if (playerTurn == false):
		enemyCode = playerCode;
	
	while (frontier < movementLength && frontierPositions.is_empty() == false):
		pos = frontierPositions.pop_front();
		
		var north :Vector3 = Vector3(pos.x, pos.y - 1, 0);
		var south :Vector3 = Vector3(pos.x, pos.y + 1, 0);
		var east  :Vector3 = Vector3(pos.x + 1, pos.y, 0);
		var west  :Vector3 = Vector3(pos.x - 1, pos.y, 0);
		
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
		if (unitsMap.get_cell_atlas_coords(north) == enemyCode):
			moves.append(Move.new(startPos, north, type, unitsMap, true));
			movementMap.set_cell(north, 0, attackCode);
		if (unitsMap.get_cell_atlas_coords(south) == enemyCode):
			moves.append(Move.new(startPos, south, type, unitsMap, true));
			movementMap.set_cell(south, 0, attackCode);
		if (unitsMap.get_cell_atlas_coords(east) == enemyCode):
			moves.append(Move.new(startPos, east, type, unitsMap, true));
			movementMap.set_cell(east, 0, attackCode);
		if (unitsMap.get_cell_atlas_coords(west) == enemyCode):
			moves.append(Move.new(startPos, west, type, unitsMap, true));
			movementMap.set_cell(west, 0, attackCode);
		
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

func _input(event: InputEvent) -> void:
	if (state != States.PLAYING):
		return;
	if (inMenu):
		return;
	
	if event is InputEventMouseButton:
		# Ignore mouse up events
		if (event.pressed == false):
			return;
		
		# Get the tile clicked on
		
		var pos :Vector3i = get_grid_cell_from_mouse();
		##cursor.position = windowPos;
		#map.set_cell(pos, 1);
		#unitsMap.set_cell(pos, 0, Vector2(14,3));
		cursor.show();
		
		if (unitsMap.get_cell_atlas_coords(pos) == playerCode):
			#unitPos = pos;
			movementMap.clear();
			if (isUnitSelected == true):
				activeMove = Move.new(pos, pos, playerCodeDone, unitsMap);
				activeMove.isWait = true;
				##ShowMovePopup(windowPos);
			else:
				Dijkstra(pos, 3);
				isUnitSelected = true;
		elif (movementMap.get_cell_source_id(pos) != -1):
			#activeMove = Move.new(unitPos, pos, playerCodeDone, unitsMap);
			if (movementMap.get_cell_atlas_coords(pos) == attackCode):
				activeMove.isAttack = true;
			##ShowMovePopup(windowPos);
			##AStar(unitPos, pos);
			
			#unitsMap.set_cell(pos, 0, playerCodeDone);
			#unitsMap.set_cell(unitPos, -1);
			movementMap.clear();
		else:
			movementMap.clear();
			isUnitSelected = false;
		
	#elif event is InputEventMouseMotion:
	#	print("Mouse Motion at: ", event.position)


#func _init() -> void:

func _ready() -> void:
	cursor.hide();
	##move_popup.hide();
	#turn_transition
	##animation_player.play();
	#turn_transition.get_canvas().hide();
	#tiles = map.get_used_cells();
#	units.append(unit);

func AStar(start :Vector2i, end :Vector2i, showPath :bool = true) -> void:
	path_arrow.clear();
	
	var astar :AStarGrid2D = AStarGrid2D.new();
	
	astar.region = Rect2i(0, 0, 18, 10);
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update();

	# Fill in the data from the tilemap layers into the a-star datastructure
	for i in range(astar.region.position.x, astar.region.end.x):
		for j in range(astar.region.position.y, astar.region.end.y):
			var pos :Vector2i = Vector2i(i, j);
			if (collidable_terrain_layer.get_cell_source_id(pos) != -1):
				astar.set_point_solid(pos);
			if (unitsMap.get_cell_source_id(pos) != -1 && pos != end):
				astar.set_point_solid(pos);

	var path :PackedVector2Array = astar.get_point_path(start, end);
	
	if not path.is_empty():
		if (showPath):
			path_arrow.set_cells_terrain_connect(path, 0, 0);
	
		animationPath.clear();
		
		##for i :int in path.size():
		##	animationPath.append(map.map_to_local(path[i]) * map.transform.get_scale());

	if (animationPath.is_empty() == false):
		animated_unit.position = animationPath.pop_front();
	
	path_arrow.set_cell(start);

func MoveAI() -> void:
	var units :Array[Vector3i] = unitsMap.get_used_cells();
	for i in units.size():
		var pos :Vector3i = units[i];
##		if (unitsMap.get_cell_atlas_coords(pos) == playerCodeDone):
##			unitsMap.set_cell(pos, 0, playerCode);
	
	var aiUnitsMoves :Array;
	for i in units.size():
		var pos :Vector3i = units[i];
##		if (unitsMap.get_cell_atlas_coords(pos) == enemyCode):
##			aiUnitsMoves.append(Array());
##			aiUnitsMoves[aiUnitsMoves.size() - 1] += Dijkstra(pos, 3);
	
	# Move each enemy unit
	for i :int in aiUnitsMoves.size():
		var move :Move = null;
		
		# First look for an attack
		for j :int in aiUnitsMoves[i].size():
			if (aiUnitsMoves[i][j].isAttack == true):
				move = aiUnitsMoves[i][j];
		
		# No attacks found, choose a random move
		if (move == null):
			move = aiUnitsMoves[i][randi() % aiUnitsMoves[i].size()];
		
		# Do the attack or move
		movesStack.append(move);

	movementMap.clear();
	##animationPath.clear();
	
	if (movesStack.is_empty() == false):
		AStar(movesStack.front().startPos, movesStack.front().endPos, false);
		state = States.ANIMATING;

func CheckVictoryConditions() -> void:
	var units :Array[Vector3i] = unitsMap.get_used_cells();
	var numberOfPlayerUnits :int = 0;
	var numberOfEnemyUnits  :int = 0;
	
	for i in units.size():
		var pos :Vector3i = units[i];
##		if (unitsMap.get_cell_atlas_coords(pos) == playerCode || unitsMap.get_cell_atlas_coords(pos) == playerCodeDone):
##			numberOfPlayerUnits += 1;
##		elif (unitsMap.get_cell_atlas_coords(pos) == enemyCode):
##			numberOfEnemyUnits += 1;
	
	if (numberOfPlayerUnits == 0):
		get_tree().change_scene_to_file("res://scenes/states/gameover.tscn");
	elif (numberOfEnemyUnits == 0):
		get_tree().change_scene_to_file("res://scenes/states/victory.tscn");

func _process(delta: float) -> void:
	##if (animation_player.is_playing()):
	##	turn_transition.show();
	##	return;
	
	##turn_transition.hide();
	
	if (state == States.PLAYING):
		if (isAnimationJustFinished):
			isAnimationJustFinished = false;
			animation_player.play();
			enemy_label.hide();
			player_label.show();
		if (playerTurn):
			playerTurn = false;
			var units :Array[Vector3i] = unitsMap.get_used_cells();
			for i in units.size():
				var pos :Vector3i = units[i];
##				if (unitsMap.get_cell_atlas_coords(pos) == playerCode):
##					playerTurn = true;
##			if (playerTurn == false):
##				animation_player.play();
##				enemy_label.show();
##				player_label.hide();
		else:
			MoveAI();
			CheckVictoryConditions();
	elif (state == States.ANIMATING):
		animated_unit.show();
		# Animations done: stop animating
		if (movesStack.is_empty()):
			state = States.PLAYING;
			animated_unit.hide();
			if (playerTurn == false):
				isAnimationJustFinished = true;
				playerTurn = true;
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
				var dir :Vector2 = animationPath.front() - animated_unit.position;
				animated_unit.position += dir.normalized() * movement_speed;# * delta);
			
			#animated_unit.position.x = animationPath
