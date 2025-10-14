extends Node2D

var tiles :Array;
var units :Array;

@onready var cursor: Sprite2D = $Cursor;
@onready var map :TileMapLayer = %Map;

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var pos :Vector2 = map.local_to_map(event.position / map.transform.get_scale());
		cursor.position = map.map_to_local(pos * 5);
		map.set_cell(pos,1);
		cursor.show();
	#elif event is InputEventMouseMotion:
	#	print("Mouse Motion at: ", event.position)


#func _init() -> void:

func _ready() -> void:
	cursor.hide();
	#tiles = map.get_used_cells();
#	units.append(unit);

#func _process(delta: float) -> void:
#	return
