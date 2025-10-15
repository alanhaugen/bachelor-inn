extends Node2D

# TODO: Stackable tiles for enemies
# TODO: Make your own units passable

@onready var cursor                    :Sprite2D = $Cursor;
@onready var map                       :TileMapLayer = $Map;
@onready var unitsMap                  :TileMapLayer = $Units;
@onready var movementMap               :TileMapLayer = $MovementSquares;
@onready var collidable_terrain_layer  :TileMapLayer = $CollidableTerrainLayer
@onready var move_popup                :Control = $MovePopup
@onready var path_arrow                :TileMapLayer = $PathArrow
@onready var animated_unit             : AnimatedSprite2D = $AnimatedUnit

var animationPath :Array[Vector2];

enum States { PLAYING, ANIMATING };
var state :int = States.PLAYING;

var isUnitSelected :bool = false;
var inMenu         :bool = false;
var activeMove     :Move;
var movesStack     :Array;

const Move = preload("res://scripts/move.gd");

var playerTurn     :bool = true;
var unitPos        :Vector2;
var playerCode     :Vector2i = Vector2i(29, 69);
var playerCodeDone :Vector2i = Vector2i(28, 75);
var enemyCode      :Vector2i = Vector2i(18, 80);
var attackCode     :Vector2i = Vector2i(22,27);

func Touch(pos :Vector2) -> bool:
	if (collidable_terrain_layer.get_cell_source_id(pos) == -1 && unitsMap.get_cell_source_id(pos) == -1):
		movementMap.set_cell(pos, 6, Vector2i(0,0));
		return true;
	return false;

func Dijkstra(startPos :Vector2, movementLength :int) -> Array[Move]:
	var frontier :int = 0;
	var frontierPositions :Array;
	var nextFrontierPositions :Array;
	
	var pos   :Vector2 = startPos;
	var moves :Array[Move];
	
	frontierPositions.append(pos);
	var type :Vector2i = unitsMap.get_cell_atlas_coords(pos);
	
	var tempEnemyCode :Vector2i = enemyCode;
	if (playerTurn == false):
		enemyCode = playerCode;
	
	while (frontier < movementLength && frontierPositions.is_empty() == false):
		pos = frontierPositions.pop_front();
		
		var north :Vector2 = Vector2(pos.x, pos.y - 1);
		var south :Vector2 = Vector2(pos.x, pos.y + 1);
		var east  :Vector2 = Vector2(pos.x + 1, pos.y);
		var west  :Vector2 = Vector2(pos.x - 1, pos.y);
		
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
		var pos :Vector2 = map.local_to_map(event.position / map.transform.get_scale());
		var windowPos :Vector2 = map.map_to_local(pos * map.transform.get_scale());
		cursor.position = windowPos;
		#map.set_cell(pos, 1);
		#unitsMap.set_cell(pos, 0, Vector2(14,3));
		cursor.show();
		
		if (unitsMap.get_cell_atlas_coords(pos) == playerCode):
			unitPos = pos;
			movementMap.clear();
			if (isUnitSelected == true):
				activeMove = Move.new(pos, pos, playerCodeDone, unitsMap);
				activeMove.isWait = true;
				ShowMovePopup(windowPos);
			else:
				Dijkstra(pos, 3);
				isUnitSelected = true;
		elif (movementMap.get_cell_source_id(pos) != -1):
			activeMove = Move.new(unitPos, pos, playerCodeDone, unitsMap);
			if (movementMap.get_cell_atlas_coords(pos) == attackCode):
				activeMove.isAttack = true;
			ShowMovePopup(windowPos);
			AStar(unitPos, pos);
			
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
	move_popup.hide();
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
		
		for i :int in path.size():
			animationPath.append(map.map_to_local(path[i]) * map.transform.get_scale());

	if (animationPath.is_empty() == false):
		animated_unit.position = animationPath.pop_front();
	
	path_arrow.set_cell(start);

func MoveAI() -> void:
	var units :Array[Vector2i] = unitsMap.get_used_cells();
	for i in units.size():
		var pos :Vector2i = units[i];
		if (unitsMap.get_cell_atlas_coords(pos) == playerCodeDone):
			unitsMap.set_cell(pos, 0, playerCode);
	
	var aiUnitsMoves :Array;
	for i in units.size():
		var pos :Vector2i = units[i];
		if (unitsMap.get_cell_atlas_coords(pos) == enemyCode):
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
		if (move == null):
			move = aiUnitsMoves[i][randi() % aiUnitsMoves[i].size()];
		
		# Do the attack or move
		movesStack.append(move);

	movementMap.clear();
	animationPath.clear();
	
	if (movesStack.is_empty() == false):
		AStar(movesStack.front().startPos, movesStack.front().endPos, false);
		state = States.ANIMATING;
	
	playerTurn = true;

func CheckVictoryConditions() -> void:
	var units :Array[Vector2i] = unitsMap.get_used_cells();
	var numberOfPlayerUnits :int = 0;
	var numberOfEnemyUnits  :int = 0;
	
	for i in units.size():
		var pos :Vector2i = units[i];
		if (unitsMap.get_cell_atlas_coords(pos) == playerCode || unitsMap.get_cell_atlas_coords(pos) == playerCodeDone):
			numberOfPlayerUnits += 1;
		elif (unitsMap.get_cell_atlas_coords(pos) == enemyCode):
			numberOfEnemyUnits += 1;
	
	if (numberOfPlayerUnits == 0):
		get_tree().change_scene_to_file("res://scenes/gameover.tscn");
	elif (numberOfEnemyUnits == 0):
		get_tree().change_scene_to_file("res://scenes/victory.tscn");

func _process(delta: float) -> void:
	if (state == States.PLAYING):
		if (playerTurn):
			playerTurn = false;
			var units :Array[Vector2i] = unitsMap.get_used_cells();
			for i in units.size():
				var pos :Vector2i = units[i];
				if (unitsMap.get_cell_atlas_coords(pos) == playerCode):
					playerTurn = true;
		else:
			MoveAI();
			CheckVictoryConditions();
	elif (state == States.ANIMATING):
		animated_unit.show();
		# Animations done: stop animating
		if (movesStack.is_empty()):
			state = States.PLAYING;
			animated_unit.hide();
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
				var dir :Vector2 = animationPath.front() - animated_unit.position;
				animated_unit.position += dir.normalized() * 5;# animationPath.front(); #(dir.normalized() * delta) * 5000;
			
			#animated_unit.position.x = animationPath
