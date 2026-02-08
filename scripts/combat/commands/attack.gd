extends Command
class_name Attack
## AttackMove is atomic: movement + attack resolution.
## Used as a single minimax action.

var attack_pos : Vector3i;
var result : AttackResult

var start_pos : Vector3i
var end_pos : Vector3i

func _init(inStartPos : Vector3i, inEndPos : Vector3i, inNeighbour : Vector3i) -> void:
	start_pos = inStartPos;
	end_pos = inNeighbour;
	attack_pos = inEndPos;


func execute(state : GameState) -> void:
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
		print("Critical hit!");
		result.was_critical = true
		attack_strength *= 2
	
	victim.state.current_health -= attack_strength
	result.damage = attack_strength
	result.killed = victim.state.current_health <= 0
	
	print(aggressor.data.unit_name + " attacks " + victim.data.unit_name + " and does " + str(attack_strength) + " damage.")
	print(aggressor.data.unit_name + " attacks " + victim.data.unit_name + " and does " +  str(attack_strength) + " damage. " + str(aggressor.data.strength) + 
							" damage from str, and " + str(weapon_damage) + " weapon damage from " + str(weapon_name) + ". Victim defence is: " + str(victim.state.defense) + ".")
	
	if aggressor.state.is_playable():
		# Do not go insane on victory
		if victim.state.current_health > 0:
			@warning_ignore("integer_division")
			aggressor.state.current_sanity -= victim.data.strength / aggressor.state.stability
	else:
		@warning_ignore("integer_division")
		victim.state.current_sanity -= aggressor.data.strength / victim.state.stability
	if victim.state.current_health <= 0:
		victim.die(false);
		if aggressor.state.is_playable():
			aggressor.state.experience += victim.data.strength;
