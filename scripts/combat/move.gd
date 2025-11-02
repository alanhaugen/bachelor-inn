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

var character1: Character = null; ## The moving character
var character2: Character = null; ## The character being attacked


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
		var weapon_crit: int = 0;
		if character1.weapon:
			weapon_damage = character1.weapon.damage_modifier
			weapon_crit = character1.weapon.weapon_critical;
		var attack_strength: int = character1.strength + weapon_damage;
		
		# Miss logic
		if (randi_range(0,100) < (character2.speed * 3 + character2.luck) / 2):
			print ("Miss");
			return;
		
		if (randi_range(0,100) < (character1.skill / 2) + weapon_crit):
			print("Critical hit!");
			attack_strength *= 2;
		
		character2.current_health -= attack_strength;
		character1.current_sanity -= character2.intimidation;
		
		character1.update_health_bar();
		character2.update_health_bar();
		
		character1.print_stats();
		character2.print_stats();
		
		print(character1.unit_name + " attacks " + character2.unit_name + " and does " + str(attack_strength) + " damage.");
		print(character1.unit_name + " loses " + str(character2.intimidation) + " sanity");
		
		if character2.is_playable == false:
			Main.level.update_stat(character1, Main.level.stat_popup_player);
			Main.level.update_stat(character2, Main.level.stat_popup_enemy);
		else:
			Main.level.update_stat(character1, Main.level.stat_popup_enemy);
			Main.level.update_stat(character2, Main.level.stat_popup_player);
		if character2.current_health <= 0:
			character2.die();
			character1.experience += character2.intimidation;
			Main.level.moves_stack.append(Move.new(start_pos, end_pos, grid_code, units, character1));
		
		character1.hide_ui();
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
