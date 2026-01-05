extends RefCounted
class_name GameState
## GameState is pure simulation state for AI and rules.
## No scene or node access should happen here.

var units : Array[Character] = [];
var terrain : Array[Terrain] = [];
var is_current_player_enemy := true;


static func from_level(level : Level) -> GameState:
	var state : GameState = GameState.new();
	
	var level_units :Array[Vector3i] = level.units_map.get_used_cells();
	for i in range(level_units.size()):
		var pos : Vector3i = level_units[i];
		var character : Character = level.get_unit(pos);
		# Add a unit to the units array
		if character is Character:
			state.units.append(character);
		else:
			# Interactables will be considered terrain, but is in the units_map
			var id : int = level.units_map.get_cell_item(pos);
			var type : String = level.units_map.mesh_library.get_item_name(id);
			state.terrain.append(Terrain.new(pos, type));
	
	var level_terrain :Array[Vector3i] = level.map.get_used_cells();
	for i in range(level_terrain.size()):
		var pos : Vector3i = level_terrain[i];
		var id : int = level.map.get_cell_item(pos);
		var type : String = level.map.mesh_library.get_item_name(id);
		state.terrain.append(Terrain.new(pos, type));
	
	state.is_current_player_enemy = (level.is_player_turn == false);
	
	return state;


func clone() -> GameState:
	var cloned_state : GameState = GameState.new();
	
	for unit in units:
		cloned_state.units.append(unit.clone());
	
	cloned_state.terrain = terrain;
	
	cloned_state.is_current_player_enemy = is_current_player_enemy;
	
	return cloned_state;


func reset_moves() -> void:
	for unit in units:
		unit.state.is_moved = false;


func apply_move(move : Command, simulate_only : bool = false) -> GameState:
	var new_state : GameState = clone();
	
	var unit : Character = new_state.get_unit(move.start_pos)
	unit.state.is_moved = true;
	
	move.execute(new_state, simulate_only);
	
	if new_state.no_units_remaining():
		new_state.end_turn();
	
	return new_state;


func no_units_remaining() -> bool:
	for unit in units:
		if unit.state.is_moved == false and unit.state.is_enemy() == is_current_player_enemy:
			return false;
	return true;


func end_turn() -> void:
	is_current_player_enemy = !is_current_player_enemy;
	reset_moves();


func get_legal_moves() -> Array[Command]:
	var moves : Array[Command] = []

	for unit in units:
		if unit.state.is_moved:
			continue;
		if unit.state.is_alive == false:
			continue;
		if unit.state.is_enemy() != is_current_player_enemy:
			continue;
		
		moves += MoveGenerator.generate(unit, self);

	return moves


func has_enemy_moves() -> bool:
	if get_legal_moves().is_empty():
		return false;
	
	return true;


func is_inside_map(pos : Vector3i) -> bool:
	for t in terrain:
		if t.position == pos:
			return true;
	
	return false;


func is_free(pos : Vector3i) -> bool:
	for t in terrain:
		if t.position == pos and t.is_passable == false:
			return false;
	
	for u in units:
		if u.state.grid_position == pos and u.state.is_alive:
			return false;
	
	return true;


func get_tile_cost(pos : Vector3i) -> int:
	for t in terrain:
		if t.position == pos and t.is_passable:
			return t.weight;
	return INF;


func is_enemy(pos : Vector3i) -> bool:
	for u in units:
		if u.state.is_enemy() == !is_current_player_enemy and u.state.grid_position == pos:
			return true;
	
	return false;


func is_unit(pos : Vector3i) -> bool:
	for u in units:
		if u.state.grid_position == pos:
			return true;
	
	return false;


func get_unit(pos : Vector3i) -> Character:
	for u in units:
		u.print_stats();
		if u.state.grid_position == pos:
			return u;
	
	return null;


func save() -> Dictionary:
	var state := {"units": units };
	
	return state;
