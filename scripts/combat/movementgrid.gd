extends RefCounted
class_name MovementGrid

#region constants
const DIRECTIONS := [
	Vector3i(1, 0, 0),
	Vector3i(-1, 0, 0),
	Vector3i(0, 0, 1),
	Vector3i(0, 0, -1)
]
#endregion

#region State variables
var movement_overlay : GridMap
var cost_map : Dictionary = {} # Vector3i -> int
var used_cells : Dictionary = {} # Vector3i -> bool
var tile_to_id : Dictionary = {}   # Vector3i -> int
var id_to_tile : Dictionary = {}   # int -> Vector3i
var next_id : int = 0
#endregion


#region methods
func _init(movement_overlay_ : GridMap) -> void:
	movement_overlay = movement_overlay_
	movement_overlay.clear();


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
	tile_to_id.clear()
	id_to_tile.clear()
	next_id = 0


func fill(tiles : Array[GridTile]) -> void:
	clear()
	
	for tile : GridTile in tiles:
		set_tile(tile)


func fill_from_commands(commands : Array[Command], state : GameState) -> void:
	clear()
	
	for command : Command in commands:
		var tile : GridTile
		var weight := state.get_tile_cost(command.end_pos)
		
		if command is Attack:
			tile = GridTile.new(command.attack_pos, GridTile.Type.ATTACK, 9999999)
		
		elif command is Move:
			tile = GridTile.new(command.end_pos, GridTile.Type.MOVE, weight)
		
		if tile:
			set_tile(tile)


func set_tile(tile : GridTile) -> void:
	var p := Vector3i(tile.pos.x, 0, tile.pos.z) # normalize overlay to y = 0
	
	var id := next_id
	next_id += 1
	
	tile_to_id[p] = id
	id_to_tile[id] = p
	
	cost_map[p] = tile.weight
	used_cells[p] = true
	movement_overlay.set_cell_item(p, tile.type)


func set_move_tile(pos : Vector3i) -> void:
	movement_overlay.set_cell_item(pos, GridTile.Type.MOVE)


func set_attack_tile(pos : Vector3i) -> void:
	movement_overlay.set_cell_item(pos, GridTile.Type.ATTACK)


func build_astar() -> AStar3D:
	var astar := AStar3D.new()
	
	# Add points
	for pos : Vector3i in tile_to_id.keys():
		var id : int = tile_to_id[pos]
		var cost := get_cost(pos)
		astar.add_point(id, Vector3(pos), cost)

	## Connect neighbors
	for pos : Vector3i in tile_to_id.keys():
		for dir : Vector3i in DIRECTIONS:
			var neighbor := pos + dir
			if tile_to_id.has(neighbor) and is_walkable(neighbor):
				astar.connect_points(tile_to_id[pos], tile_to_id[neighbor], false)
	#for pos : Vector3i in cost_map.keys():
	#	for dir : Vector3i in DIRECTIONS:
	#		var neighbor := pos + dir
	#		if is_walkable(neighbor):
	#			var from_id : int = tile_to_id[pos]
	#			var to_id : int = tile_to_id[neighbor]
	#			astar.connect_points(from_id, to_id, false)
	
	return astar


func get_path(start : Vector3i, target : Vector3i) -> Array[Vector3i]:
	var astar := build_astar()
	
	var s := Vector3i(start.x, 0, start.z)
	var t := Vector3i(target.x, 0, target.z)
	
	if not tile_to_id.has(s) or not tile_to_id.has(t):
		push_error("start/target not in grid")
		return [];
	
	var start_id : int = tile_to_id[s]
	var target_id : int = tile_to_id[t]

	var ids := astar.get_id_path(start_id, target_id)
	var path : Array[Vector3i] = []

	for id in ids:
		path.append(id_to_tile[id])
	
	return path

func norm(p: Vector3i) -> Vector3i:
	return Vector3i(p.x, 0, p.z)

func get_tile_type(pos: Vector3i) -> int:
	return movement_overlay.get_cell_item(norm(pos))

func is_move_tile(pos: Vector3i) -> bool:
	return get_tile_type(pos) == GridTile.Type.MOVE

func is_attack_tile(pos: Vector3i) -> bool:
	return get_tile_type(pos) == GridTile.Type.ATTACK

#endregion
