class_name Move extends Command
## This is a move
##
## The game consists of moves played in a queue

var start_pos: Vector3i;
var end_pos: Vector3i;
var grid_code: int;
var units: GridMap;
var is_attack: bool;
var is_wait: bool;
var neighbour_move: Move = null;

var character1: Character = null;
var character2: Character = null;


func _init(inStartPos :Vector3i, inEndPos :Vector3i, inGridCode :int, inUnits: GridMap, inCharacter1: Character, inIsAttack :bool = false, inCharacter2: Character = null, in_neighbour_move: Move = null) -> void:
	start_pos = inStartPos;
	end_pos = inEndPos;
	grid_code = inGridCode;
	units = inUnits;
	is_attack = inIsAttack;
	is_wait = false;
	character1 = inCharacter1;
	character2 = inCharacter2;
	neighbour_move = in_neighbour_move;


func execute() -> void:
	if is_attack:
		var weapon_damage: int = 0;
		if character1.weapon:
			weapon_damage = character1.weapon.damage_modifier
		var attack_strength: int = character1.strength + weapon_damage;
		character2.current_health -= attack_strength;
		character2.update_health_bar();
		if character2.is_playable == false:
			Main.level.update_stat(character2, Main.level.stat_popup_player);
		else:
			Main.level.update_stat(character2, Main.level.stat_popup_enemy);
		if character2.current_health <= 0:
			character2.die();
			Main.level.moves_stack.append(Move.new(start_pos, end_pos, grid_code, units, character1));
	else:
		character1.move_to(end_pos);
		units.set_cell_item(start_pos, GridMap.INVALID_CELL_ITEM);
		units.set_cell_item(end_pos, grid_code);


func undo() -> void:
	units.set_cell_item(end_pos, GridMap.INVALID_CELL_ITEM);
	units.set_cell_item(start_pos, grid_code);
	
	character1.move_to(start_pos);
	if is_attack:
		character2.move_to(end_pos);
