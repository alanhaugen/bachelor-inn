extends Move
class_name Attack
## AttackMove is atomic: movement + attack resolution.
## Used as a single minimax action.

var attack_pos : Vector3i;


func _init(inStartPos : Vector3i, inEndPos : Vector3i, inNeighbour : Vector3i) -> void:
	start_pos = inStartPos;
	end_pos = inNeighbour;
	attack_pos = inEndPos;


func execute(state : GameState, simulate_only : bool = false) -> void:
	var weapon_damage : int;
	var weapon_crit : int;
	
	var aggressor : Character = state.get_unit(start_pos);
	var victim : Character = state.get_unit(attack_pos);
	
	if aggressor.weapon:
		weapon_damage = aggressor.weapon.damage_modifier;
		weapon_crit = aggressor.weapon.weapon_critical;
	
	@warning_ignore("integer_division")
	var attack_strength :int = max(1, (aggressor.strength + weapon_damage) - victim.defense / 2);
	
	aggressor.is_moved = true;
	
	if simulate_only == false:
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
	
	if simulate_only == false:
		aggressor.update_health_bar();
		victim.update_health_bar();
		
		Main.battle_log.text = (aggressor.unit_name + " attacks " + victim.unit_name + " and does " + str(attack_strength) + " damage.\n") + Main.battle_log.text;
	
	if aggressor.is_playable:
		# Do not go insane on victory
		if victim.current_health > 0:
			@warning_ignore("integer_division")
			aggressor.current_sanity -= victim.intimidation / aggressor.mind;
			#Main.level.update_stat(aggressor, Main.level.stat_popup_player);
			#Main.level.update_stat(victim, Main.level.stat_popup_enemy);
	else:
		@warning_ignore("integer_division")
		victim.current_sanity -= aggressor.intimidation / victim.mind;
		#Main.level.update_stat(aggressor, Main.level.stat_popup_enemy);
		#Main.level.update_stat(victim, Main.level.stat_popup_player);
	if victim.current_health <= 0:
		victim.die(simulate_only);
		#Main.battle_log.text = (victim.unit_name + " dies.\n") + Main.battle_log.text;
		if aggressor.is_playable and simulate_only == false:
			#Main.battle_log.text = (aggressor.unit_name + " gains " + str(victim.intimidation) + " experience.\n") + Main.battle_log.text;
			aggressor.experience += victim.intimidation;
		#Main.level.moves_stack.append(Move.new(start_pos, end_pos, grid_code, aggressor));
	
	#aggressor.hide_ui();
#		if aggressor.is_playable:
#			aggressor.sprite.modulate = Color(0.338, 0.338, 0.338, 1.0);
