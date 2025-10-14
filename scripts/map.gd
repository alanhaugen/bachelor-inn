extends Node2D

var tiles :Array;
var units :Array;

@onready var cursor: Sprite2D = $Cursor;
@onready var map :TileMapLayer = %Map;
@onready var unitsMap :TileMapLayer = $Units;
@onready var movementMap :TileMapLayer = $MovementSquares;

var isUnitSelected :bool = false;
var unitPos :Vector2;

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# Ignore mouse up events
		if (event.pressed == false):
			return;
		
		# Get the tile clicked on
		var pos :Vector2 = map.local_to_map(event.position / map.transform.get_scale());
		cursor.position = map.map_to_local(pos * 5);
		#map.set_cell(pos, 1);
		#unitsMap.set_cell(pos, 0, Vector2(14,3));
		cursor.show();
		
		if (unitsMap.get_cell_source_id(pos) != -1):
			isUnitSelected = true;
			unitPos = pos;
			movementMap.set_cell(Vector2(pos.x -1, pos.y), 0, Vector2(14,3));
			movementMap.set_cell(Vector2(pos.x +1, pos.y), 0, Vector2(14,3));
			movementMap.set_cell(Vector2(pos.x, pos.y+1), 0, Vector2(14,3));
			movementMap.set_cell(Vector2(pos.x, pos.y-1), 0, Vector2(14,3));
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
