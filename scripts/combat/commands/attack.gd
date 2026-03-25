extends Command
class_name Attack
## AttackMove is atomic: movement + attack resolution.
## Used as a single minimax action.

var attack_pos : Vector3i;


func _init(inStartPos : Vector3i, inEndPos : Vector3i, inNeighbour : Vector3i) -> void:
	start_pos = inStartPos;
	end_pos = inNeighbour;
	attack_pos = inEndPos;


func execute(state : GameState, simulate_only : bool = false) -> void:
	var unit := state.get_unit(start_pos)
	if unit:
		unit.move_to(end_pos, simulate_only)
		unit.state.is_moved = true
		unit.state.is_ability_used = true


func prepare(state : GameState, simulate_only: bool = false) -> void:
	result = AttackResult.new()

	print("[DEBUG_LOG] Attack prepare: aggressor moving from ", start_pos, " to ", end_pos, " victim at ", attack_pos)
	# The unit should have just moved to end_pos in execute()
	var aggressor : Character = state.get_unit(end_pos);
	var victim : Character = state.get_unit(attack_pos);
	
	if not aggressor:
		# Fallback: maybe it didn't move yet in this state?
		aggressor = state.get_unit(start_pos)
		if aggressor:
			print("[DEBUG_LOG] Attack prepare: found aggressor at start_pos ", start_pos, " instead of end_pos ", end_pos)

	result.aggressor = aggressor
	result.victim = victim
	
	if not aggressor or not victim:
		print("[DEBUG_LOG] Attack prepare FAILED: aggressor found: ", aggressor != null, " victim found: ", victim != null, " at ", attack_pos)
		return
	print("[DEBUG_LOG] Attack prepare SUCCESS: ", aggressor.data.unit_name, " vs ", victim.data.unit_name)

	# Weapons
	var weapon_damage : int;
	var weapon_crit : int;
	var weapon_name : String;
	

	if aggressor.state.weapon:
		weapon_damage = aggressor.state.weapon.damage_modifier;
		weapon_crit = aggressor.state.weapon.weapon_critical;
		weapon_name = aggressor.state.weapon.weapon_name;
		
	@warning_ignore("integer_division")
	var attack_strength :int = max(1, (aggressor.data.strength + weapon_damage) - (victim.state.defense / 2));

	# Critical logic
	if simulate_only == false:
		@warning_ignore("integer_division")
		if (randi_range(0,100) < (aggressor.data.focus / 2) + weapon_crit):
			result.was_critical = true;
			attack_strength *= 2;
	
	result.damage = attack_strength
	



func apply_damage(state: GameState , simulate_only: bool = false) -> void:
	print("[DEBUG_LOG] Attack apply_damage: result valid: ", result != null)
	if not result or not result.aggressor or not result.victim:
		print("[DEBUG_LOG] Attack apply_damage FAILED: missing result or units")
		return

	var aggressor : Character = result.aggressor;
	var victim : Character = result.victim;
	
	if simulate_only == false:
		if result.was_critical:
			print("Critical hit!");
		
		var weapon_name : String = ""
		var weapon_damage : int = 0
		if aggressor.state.weapon:
			weapon_name = aggressor.state.weapon.weapon_name
			weapon_damage = aggressor.state.weapon.damage_modifier
			
	
	# result.damage is already calculated in prepare()
	print("[DEBUG_LOG] Attack applying damage: ", result.damage, " to ", victim.data.unit_name)
	result.killed = victim.apply_damage(result.damage, simulate_only, aggressor, "Attack")
	print("[DEBUG_LOG] Attack applied damage. Victim killed: ", result.killed)
	
	# Play SFX on result (only in real execution)
	if not simulate_only and is_instance_valid(Main.level):
		Main.level.play_attack_sfx(result.damage > 0)
	
	# sanity
	if not simulate_only:
		if aggressor.state.is_playable():
			pass
			#if victim.state.current_health > 0:
				#@warning_ignore("integer_division")
				#aggressor.state.current_sanity -= victim.data.strength / aggressor.state.stability
		else:
			@warning_ignore("integer_division")
			victim.state.current_sanity -= aggressor.data.strength / victim.state.stability
	
	# death
	if result.killed:
		if aggressor.state.is_playable() and not simulate_only:
			aggressor.state.experience += victim.data.strength
	
	if not simulate_only:
		Main.level.emit_signal("character_stats_changed", aggressor)
		Main.level.emit_signal("character_stats_changed", victim)
	

#old, replaced by Prepare and Apply
#func execute(state : GameState, simulate_only : bool = false) -> void:
	#result = AttackResult.new()
	#
	#
	#var aggressor : Character = state.get_unit(start_pos);
	#var victim : Character = state.get_unit(attack_pos);
	#
	#result.aggressor = aggressor
	#result.victim = victim
	#
	#if aggressor.state.is_playable():
		#aggressor.state.is_ability_used = true
	#aggressor.state.is_moved = true;
	#
	#
	##weapons
	#var weapon_damage : int;
	#var weapon_crit : int;
	#var weapon_name : String;
	#
	#if aggressor.state.weapon:
		#weapon_damage = aggressor.state.weapon.damage_modifier;
		#weapon_crit = aggressor.state.weapon.weapon_critical;
		#weapon_name = aggressor.state.weapon.weapon_name;
	#
	#@warning_ignore("integer_division")
	#var attack_strength :int = max(1, (aggressor.data.strength + weapon_damage) - (victim.state.defense / 2));
	#
	#
	#if simulate_only == false:
		## Miss logic
		#@warning_ignore("integer_division")
		#if (randi_range(0,100) < (victim.data.speed * 3 + victim.data.focus) / 2):
			#Main.battle_log.text = ("Miss\n") + Main.battle_log.text;
			#print ("Miss");
			#attack_strength = 0;
			## TODO: double attack if difference in speed between an enemy is high enough
			#return;
		#
		## Critical logic
		#@warning_ignore("integer_division")
		#if (randi_range(0,100) < (aggressor.data.focus / 2) + weapon_crit):
			#Main.battle_log.text = ("Critical hit!\n") + Main.battle_log.text;
			#print("Critical hit!");
			#result.was_critical = true;
			#attack_strength *= 2;
	#
	#victim.state.current_health -= attack_strength;
	#result.damage = attack_strength
	#result.killed = victim.state.current_health <= 0
	#
	#
	#if simulate_only == false:
		##aggressor.update_health_bar();
		##victim.update_health_bar();
		#
		##Main.battle_log.text = (aggressor.data.unit_name + " attacks " + victim.data.unit_name + " and does " + str(attack_strength) + " damage.\n") + Main.battle_log.text;
		#Main.battle_log.text = (aggressor.data.unit_name + " attacks " + victim.data.unit_name + " and does " +  str(attack_strength) + " damage. " + str(aggressor.data.strength) + 
								#" damage from str, and " + str(weapon_damage) + " weapon damage from " + str(weapon_name) + ". Victim defence is: " + str(victim.state.defense) + ".\n") + Main.battle_log.text;
	#
	#if aggressor.state.is_playable():
		## Do not go insane on victory
		#if victim.state.current_health > 0:
			#@warning_ignore("integer_division")
			#aggressor.state.current_sanity -= victim.data.strength / aggressor.state.stability
	#else:
		#@warning_ignore("integer_division")
		#victim.state.current_sanity -= aggressor.data.strength / victim.state.stability
	#if victim.state.current_health <= 0:
		#victim.die(simulate_only);
		#if aggressor.state.is_playable() and simulate_only == false:
			#aggressor.state.experience += victim.data.strength;


func undo(state : GameState, _simulate_only : bool = false) -> void:
	# Undoing an attack move mostly means returning the unit to its original position
	# if the player undoes from the popup.
	var unit := state.get_unit(end_pos)
	if unit:
		unit.move_to(start_pos, _simulate_only)
		if not _simulate_only:
			unit.state.is_moved = false
			unit.state.is_ability_used = false
	else:
		# Maybe it's at the start_pos still (if it hasn't moved yet)?
		unit = state.get_unit(start_pos)
		if unit and not _simulate_only:
			unit.state.is_moved = false
			unit.state.is_ability_used = false

	# If the attack was already executed (damage applied), we would need to revert it.
	# Currently, Undo in move_popup is called BEFORE execute(), so only movement needs reverting.
	# However, if we want to support undoing a full action later:
	if result and result.victim:
		result.victim.state.current_health += result.damage
		if result.killed:
			# Re-adding a dead unit is complex because it was queue_free'd.
			# For now, this undo is intended for the pre-action movement.
			pass
