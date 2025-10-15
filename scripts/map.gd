extends Node2D

# TODO: Stackable tiles for enemies
# TODO: Make your own units passable

@onready var cursor: Sprite2D = $Cursor;
@onready var map :TileMapLayer = $Map;
@onready var unitsMap :TileMapLayer = $Units;
@onready var movementMap :TileMapLayer = $MovementSquares;
@onready var collidable_terrain_layer: TileMapLayer = $CollidableTerrainLayer

const Move = preload("res://scripts/move.gd");

var playerTurn :bool = true;
var unitPos :Vector2;
var playerCode     :Vector2i = Vector2i(29, 69);
var playerCodeDone :Vector2i = Vector2i(28, 75);
var enemyCode      :Vector2i = Vector2i(18, 80);

func Touch(pos :Vector2) -> bool:
	if (collidable_terrain_layer.get_cell_source_id(pos) == -1 && unitsMap.get_cell_source_id(pos) == -1):
		movementMap.set_cell(pos, 0, Vector2(14,3));
		return true;
	return false;

func Dijkstra(startPos :Vector2, movementLength :int) -> Array[Move]:
	var frontier :int = 0;
	var frontierPositions :Array;
	var nextFrontierPositions :Array;
	
	var pos :Vector2 = startPos;
	var moves :Array[Move];
	
	frontierPositions.append(pos);
	var type :Vector2i = unitsMap.get_cell_atlas_coords(pos);
	
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
		
		if (frontierPositions.is_empty() == true):
			frontier += 1;
			frontierPositions = nextFrontierPositions.duplicate();
			nextFrontierPositions.clear();
	
	return moves;

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Ignore mouse up events
		if (event.pressed == false):
			return;
		
		# Get the tile clicked on
		var pos :Vector2 = map.local_to_map(event.position / map.transform.get_scale());
		cursor.position = map.map_to_local(pos * map.transform.get_scale());
		#map.set_cell(pos, 1);
		#unitsMap.set_cell(pos, 0, Vector2(14,3));
		cursor.show();
		
		if (unitsMap.get_cell_atlas_coords(pos) == playerCode):
			unitPos = pos;
			movementMap.clear();
			Dijkstra(pos, 3);
		elif (movementMap.get_cell_source_id(pos) != -1):
			unitsMap.set_cell(pos, 0, playerCodeDone);
			unitsMap.set_cell(unitPos, -1);
			movementMap.clear();
		else:
			movementMap.clear();
		
	#elif event is InputEventMouseMotion:
	#	print("Mouse Motion at: ", event.position)


#func _init() -> void:

func _ready() -> void:
	cursor.hide();
	#tiles = map.get_used_cells();
#	units.append(unit);

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
	
	for i in aiUnitsMoves.size():
		var randomMove :Move = aiUnitsMoves[i][randi() % aiUnitsMoves.size()];
		randomMove.exectute();
	
	movementMap.clear();
	
	playerTurn = true;

func _process(delta: float) -> void:
	if (playerTurn):
		var units :Array[Vector2i] = unitsMap.get_used_cells();
		playerTurn = false;
		for i in units.size():
			var pos :Vector2i = units[i];
			if (unitsMap.get_cell_atlas_coords(pos) == playerCode):
				playerTurn = true;
	else:
		MoveAI();
