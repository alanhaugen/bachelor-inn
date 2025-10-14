extends Node2D

var tiles :Array;
var units :Array;

@onready var cursor: Sprite2D = $Cursor;
@onready var map :TileMapLayer = $Map;
@onready var unitsMap :TileMapLayer = $Units;
@onready var movementMap :TileMapLayer = $MovementSquares;
@onready var collidable_terrain_layer: TileMapLayer = $CollidableTerrainLayer

var isUnitSelected :bool = false;
var unitPos :Vector2;

func Touch(pos :Vector2) -> bool:
	if (collidable_terrain_layer.get_cell_source_id(pos) == -1 && unitsMap.get_cell_source_id(pos) == -1):
		movementMap.set_cell(pos, 0, Vector2(14,3));
		return true;
	return false;

func Dijkstra(pos :Vector2, movementLength :int) -> void:
	var frontier :int = 0;
	var frontierPositions :Array;
	var nextFrontierPositions :Array;
	
	frontierPositions.append(pos);
	
	while (frontier < movementLength && frontierPositions.is_empty() == false):
		pos = frontierPositions.pop_front();
		
		var north :Vector2 = Vector2(pos.x, pos.y - 1);
		var south :Vector2 = Vector2(pos.x, pos.y + 1);
		var east  :Vector2 = Vector2(pos.x + 1, pos.y);
		var west  :Vector2 = Vector2(pos.x - 1, pos.y);
		
		if (Touch(north)):
			nextFrontierPositions.append(north);
		
		if (Touch(south)):
			nextFrontierPositions.append(south);
		
		if (Touch(east)):
			nextFrontierPositions.append(east);
		
		if (Touch(west)):
			nextFrontierPositions.append(west);
		
		if (frontierPositions.is_empty() == true):
			frontier += 1;
			frontierPositions = nextFrontierPositions.duplicate();
			nextFrontierPositions.clear();
	
	return;

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
		
		if (unitsMap.get_cell_source_id(pos) != -1):
			isUnitSelected = true;
			unitPos = pos;
			movementMap.clear();
			
			Dijkstra(pos, 2);
			
		elif (isUnitSelected == true && movementMap.get_cell_source_id(pos) != -1):
			unitsMap.set_cell(pos, 0, Vector2(29, 69));
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

#func _process(delta: float) -> void:
#	return
