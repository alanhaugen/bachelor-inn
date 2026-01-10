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
	
	if aggressor.state.weapon:
		weapon_damage = aggressor.state.weapon.damage_modifier;
		weapon_crit = aggressor.state.weapon.weapon_critical;
	
	@warning_ignore("integer_division")
	var attack_strength :int = max(1, (aggressor.data.strength + weapon_damage) - victim.state.defense / 2);
	
	aggressor.state.is_moved = true;
	
	if simulate_only == false:
		# Miss logic
		@warning_ignore("integer_division")
		if (randi_range(0,100) < (victim.data.speed * 3 + victim.data.focus) / 2):
			Main.battle_log.text = ("Miss\n") + Main.battle_log.text;
			print ("Miss");
			attack_strength = 0;
			# TODO: double attack if difference in speed between an enemy is high enough
			return;
		
		# Critical logic
		@warning_ignore("integer_division")
		if (randi_range(0,100) < (aggressor.data.focus / 2) + weapon_crit):
			Main.battle_log.text = ("Critical hit!\n") + Main.battle_log.text;
			print("Critical hit!");
			attack_strength *= 2;
	
	victim.state.current_health -= attack_strength;
	
	if simulate_only == false:
		aggressor.update_health_bar();
		victim.update_health_bar();
		
		Main.battle_log.text = (aggressor.data.unit_name + " attacks " + victim.data.unit_name + " and does " + str(attack_strength) + " damage.\n") + Main.battle_log.text;
	
	if aggressor.state.is_playable():
		# Do not go insane on victory
		if victim.state.current_health > 0:
			@warning_ignore("integer_division")
			aggressor.state.current_sanity -= victim.data.strength / aggressor.state.stability
			#Main.level.update_stat(aggressor, Main.level.stat_popup_player);
			#Main.level.update_stat(victim, Main.level.stat_popup_enemy);
	else:
		@warning_ignore("integer_division")
		victim.state.current_sanity -= aggressor.data.strength / victim.state.stability
		#Main.level.update_stat(aggressor, Main.level.stat_popup_enemy);
		#Main.level.update_stat(victim, Main.level.stat_popup_player);
	if victim.state.current_health <= 0:
		victim.die(simulate_only);
		#Main.battle_log.text = (victim.unit_name + " dies.\n") + Main.battle_log.text;
		if aggressor.state.is_playable() and simulate_only == false:
			#Main.battle_log.text = (aggressor.unit_name + " gains " + str(victim.intimidation) + " experience.\n") + Main.battle_log.text;
			aggressor.state.experience += victim.data.strength;
		#Main.level.moves_stack.append(Move.new(start_pos, end_pos, grid_code, aggressor));
	
	#aggressor.hide_ui();
#		if aggressor.is_playable:
#			aggressor.sprite.modulate = Color(0.338, 0.338, 0.338, 1.0);
