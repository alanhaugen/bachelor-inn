extends Node
class_name MovementGrid

#region State variables
@onready var movement_overlay : GridMap = %MovementOverlay
var cost_map : Dictionary = {} # Vector3i -> int
var used_cells : Dictionary = {} # Vector3i -> bool
var tile_to_id : Dictionary = {}   # Vector3i -> int
var id_to_tile : Dictionary = {}   # int -> Vector3i
var next_id : int = 0
#endregion


#region methods
func is_inside(pos : Vector3i) -> bool:
	return used_cells.has(pos)


func is_walkable(pos : Vector3i) -> bool:
	if not is_inside(pos):
		return false
	return movement_overlay.get_cell_item(pos) != GridMap.INVALID_CELL_ITEM


func get_cost(pos : Vector3i) -> int:
	return cost_map.get(pos, 1)


func is_blocked(pos : Vector3i) -> bool:
	return not is_walkable(pos)


func clear() -> void:
	movement_overlay.clear()
	cost_map.clear()
	used_cells.clear()
	id_to_tile.clear()
	next_id = 0


func fill(tiles : Array[GridTile]) -> void:
	clear()
	
	for tile : GridTile in tiles:
		set_tile(tile)


func set_tile(tile : GridTile) -> void:
	var id := next_id
	next_id += 1
	
	tile_to_id[tile.pos] = id
	id_to_tile[id] = tile.pos
	
	cost_map[tile.pos] = tile.weight
	used_cells[tile.pos] = true
	movement_overlay.set_cell_item(tile.pos, tile.type)
#endregion
