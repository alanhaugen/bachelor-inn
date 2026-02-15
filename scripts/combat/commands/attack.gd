extends Command
class_name Attack
## AttackMove is atomic: movement + attack resolution.
## Used as a single minimax action.

var attack_pos : Vector3i;


var start_pos : Vector3i
var end_pos : Vector3i

func _init(inStartPos : Vector3i, inEndPos : Vector3i, inNeighbour : Vector3i) -> void:
	start_pos = inStartPos;
	end_pos = inNeighbour;
	attack_pos = inEndPos;



func prepare(state : GameState) -> void:
	result = AttackResult.new()

	var aggressor : Character = state.get_unit(start_pos);
	var victim : Character = state.get_unit(attack_pos);
	
	result.aggressor = aggressor
	result.victim = victim
	
	if aggressor.state.is_playable():
		aggressor.state.is_ability_used = true
	aggressor.state.is_moved = true;
	
	
		#weapons
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
	@warning_ignore("integer_division")
	if (randi_range(0,100) < (aggressor.data.focus / 2) + weapon_crit):
		Main.battle_log.text = ("Critical hit!\n") + Main.battle_log.text;
		print("Critical hit!");
		result.was_critical = true;
		attack_strength *= 2;
	
	result.damage = attack_strength


# never called if its a ranged attack???? seems to be a timing issue
func apply_damage(state: GameState) -> void:
	var aggressor : Character = result.aggressor;
	var victim : Character = result.victim;

	#apply dmg
	victim.state.current_health -= result.damage

	#sanity
	if aggressor.state.is_playable():
		if victim.state.current_health > 0:
			@warning_ignore("integer_division")
			aggressor.state.current_sanity -= victim.data.strength / aggressor.state.stability
	else:
		@warning_ignore("integer_division")
		victim.state.current_sanity -= aggressor.data.strength / victim.state.stability
	
	#death
	if victim.state.current_health <= 0:
		victim.die(false)
		if aggressor.state.is_playable():
			aggressor.state.experience += victim.data.strength
	
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
