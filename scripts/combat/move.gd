class_name Move
extends Command
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
var is_done: bool = false;
var weapon_damage: int = 0;
var weapon_crit: int = 0;
var attack_strength: int = 0;

var aggressor: Character = null; ## The moving character
var victim: Character = null; ## The character being attacked


func save() -> Dictionary:
	var state := {"start_pos": start_pos,
				  "end_pos": end_pos,
				  "grid_code": grid_code,
				  "is_attack": is_attack,
				  "is_wait": is_wait
				  };
	
	return state;


func _init(inStartPos :Vector3i, inEndPos :Vector3i, inGridCode :int, inUnits: GridMap, inCharacter1: Character, inIsAttack :bool = false, inCharacter2: Character = null, in_neighbour_move: Move = null) -> void:
	start_pos = inStartPos;
	end_pos = inEndPos;
	grid_code = inGridCode;
	units = inUnits;
	is_attack = inIsAttack;
	is_wait = false;
	aggressor = inCharacter1;
	victim = inCharacter2;
	neighbour_move = in_neighbour_move;


func execute() -> void:
	if is_attack:
		if aggressor.weapon:
			weapon_damage = aggressor.weapon.damage_modifier;
			weapon_crit = aggressor.weapon.weapon_critical;
		
		@warning_ignore("integer_division")
		attack_strength = max(1, (aggressor.strength + weapon_damage) - victim.defense / 2);
		
		#Main.battle_log.text += "\nAttacker: \n";
		#Main.battle_log.text += str(character1.save());
		#Main.battle_log.text += "\n-----\n";
		#Main.battle_log.text += "Victim: ";
		#Main.battle_log.text += str(character2.save());
		
		# Miss logic
		@warning_ignore("integer_division")
		if (randi_range(0,100) < (victim.speed * 3 + victim.luck) / 2):
			Main.battle_log.text = ("Miss\n") + Main.battle_log.text;
			print ("Miss");
			attack_strength = 0;
			return;
		
		# Critical logic
		@warning_ignore("integer_division")
		if (randi_range(0,100) < (aggressor.skill / 2) + weapon_crit):
			Main.battle_log.text = ("Critical hit!\n") + Main.battle_log.text;
			print("Critical hit!");
			attack_strength *= 2;
		
		victim.current_health -= attack_strength;
		
		aggressor.update_health_bar();
		victim.update_health_bar();
		
		Main.battle_log.text = (aggressor.unit_name + " attacks " + victim.unit_name + " and does " + str(attack_strength) + " damage.\n") + Main.battle_log.text;
		
		if aggressor.is_playable:
			# Do not go insane on victory
			if victim.current_health > 0:
				@warning_ignore("integer_division")
				aggressor.current_sanity -= victim.intimidation / aggressor.mind;
				Main.level.update_stat(aggressor, Main.level.stat_popup_player);
				Main.level.update_stat(victim, Main.level.stat_popup_enemy);
		else:
			@warning_ignore("integer_division")
			victim.current_sanity -= aggressor.intimidation / victim.mind;
			Main.level.update_stat(aggressor, Main.level.stat_popup_enemy);
			Main.level.update_stat(victim, Main.level.stat_popup_player);
		if victim.current_health <= 0:
			victim.die();
			Main.battle_log.text = (victim.unit_name + " dies.\n") + Main.battle_log.text;
			if aggressor.is_playable:
				Main.battle_log.text = (aggressor.unit_name + " gains " + str(victim.intimidation) + " experience.\n") + Main.battle_log.text;
				aggressor.experience += victim.intimidation;
			Main.level.moves_stack.append(Move.new(start_pos, end_pos, grid_code, units, aggressor));
		
		aggressor.hide_ui();
		aggressor.sprite.modulate = Color(0.338, 0.338, 0.338, 1.0);
	else:
		aggressor.move_to(end_pos);
		units.set_cell_item(start_pos, GridMap.INVALID_CELL_ITEM);
		units.set_cell_item(end_pos, grid_code);
		aggressor.is_moved = true;
		if end_pos == start_pos:
			aggressor.sprite.modulate = Color(0.338, 0.338, 0.338, 1.0);


func redo() -> void:
	if is_done == false:
		execute();
	else:
		if is_attack:
			victim.health -= attack_strength;
		else:
			aggressor.move_to(end_pos);
			units.set_cell_item(start_pos, GridMap.INVALID_CELL_ITEM);
			units.set_cell_item(end_pos, grid_code);


func undo() -> void:
	if is_done:
		units.set_cell_item(end_pos, GridMap.INVALID_CELL_ITEM);
		units.set_cell_item(start_pos, grid_code);
		
		if is_attack:
			victim.health += attack_strength;
			victim.sanity += attack_strength;
			victim.move_to(end_pos);
		else:
			aggressor.is_moved = false;
		aggressor.move_to(start_pos);
		aggressor.sprite.modulate = Color(1.0, 1.0, 1.0, 1.0);
