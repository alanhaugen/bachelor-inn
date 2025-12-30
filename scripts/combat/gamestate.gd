class_name GameState
extends RefCounted

var units :Array[Character] = [];
var terrain :Array[Terrain] = [];
var is_current_player_enemy := true;


static func from_level(level : Level) -> GameState:
	var state : GameState = GameState.new();
	
	var level_units :Array[Vector3i] = level.units_map.get_used_cells();
	for i in range(level_units.size()):
		var pos :Vector3i = level_units[i];
		var character: Character = level.get_unit(pos);
		if character is Character:
			state.units.append(character);
	
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
		cloned_state.units.append(unit);
	
	cloned_state.is_current_player_enemy = is_current_player_enemy;
	
	return cloned_state;


func apply_move(move : Move) -> GameState:
	var new_state : GameState = GameState.new();# := duplicate(true);

	# Move unit
	for unit : Character in units:
		if unit.pos == move.start_pos:
			unit.pos = move.end_pos;

	# Handle attack
	if move.is_attack:
		for unit : Character in units:
			if unit.pos == move.attack_pos:
				unit.hp -= move.damage;
	
	return new_state;


func get_legal_moves() -> Array[Move]:
	var moves : Array[Move] = []

	for unit in units:
		if unit.is_enemy == is_current_player_enemy:
			moves += MoveGenerator.generate(unit, self);

	return moves


func has_enemy_moves() -> bool:
	var moves : Array[Move] = [];
	
	for unit in units:
		if unit.is_enemy:
			moves += MoveGenerator.generate(unit, self);
	
	if moves.is_empty():
		return false;
	
	return true;


func is_inside_map(pos : Vector3i) -> bool:
	for t in terrain:
		if t.position == pos:
			return true;
	
	return false;


func is_free(pos : Vector3i) -> bool:
	for t in terrain:
		if t.position == pos and t.type == "Water":
			return false;
	
	for u in units:
		if u.grid_position == pos:
			return false;
	
	return true;


func save() -> Dictionary:
	var state := {"units": units };
	
	return state;
