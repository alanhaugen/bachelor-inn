extends Node
class_name CombatService

# Defines the raw outcome of a combat action.
class CombatResult:
	var damage_dealt: int = 0
	var was_critical: bool = false
	var was_miss: bool = false
	var target_is_defeated: bool = false
	var sanity_damage: int = 0
	var message: String = ""

# Calculates the full effect of an attack based on the current game state.
# This function is pure: it takes state and returns results without changing state.
# @param attacker_data: CharacterData of the unit initiating the attack.
# @param victim_data: CharacterData of the unit receiving the attack.
# @param weapon_data: WeaponData of the attacking unit.
# @param state: The current GameState snapshot for context (e.g., random seed).
# @return CombatResult containing all calculated outcomes.
func calculate_attack(attacker_data : Dictionary, victim_data : Dictionary, weapon_data : Dictionary, state: GameState) -> CombatResult:
	var result = CombatResult.new()
	
	var attacker_strength: int = attacker_data["strength"]
	var attacker_focus: int = attacker_data["focus"]
	var attacker_mind: int = attacker_data["mind"]
	var attacker_endurance: int = attacker_data["endurance"]
	
	var victim_defense: int = victim_data["defense"]
	var victim_speed: int = victim_data["speed"]
	var victim_focus: int = victim_data["focus"]
	var victim_mind: int = victim_data["mind"]
	var victim_endurance: int = victim_data["endurance"]
	
	var weapon_damage: int = weapon_data["damage_modifier"]
	var weapon_crit: int = weapon_data["weapon_critical"]
	
	# --- 1. Determine Attack Strength and Crit ---
	var base_damage: int = max(1, (attacker_strength + weapon_damage) - (victim_defense / 2));
	var attack_strength: int = base_damage;
	var was_critical: bool = false;
	
	# Critical check
	if randi_range(0, 100) < (attacker_focus / 2) + weapon_crit:
		was_critical = true;
		attack_strength *= 2;
	
	# --- 2. Determine Hit/Miss ---
	# Formula: Attacker Speed + Focus vs Victim Speed + Focus (A more complex formula could be used)
	var hit_chance_roll: int = randi_range(0, 100);
	var required_hit_value: int = (attacker_data.get("speed", 1) + attacker_focus) / 2;
	var enemy_defense_value: int = (victim_data.get("speed", 1) + victim_focus) / 2;
	
	if hit_chance_roll < required_hit_value - enemy_defense_value:
		result.was_miss = true;
		result.message = "Missed!";
		return result
		
	# --- 3. Calculate Damage and Outcomes ---
	result.damage_dealt = attack_strength;
	result.was_critical = was_critical;
	
	# Damage Calculation (Already done above, but confirms the final value)
	# Damage = max(1, (A_STR + W_D - V_DEF/2)) * (crit_multiplier)
	
	# Sanity/Resource Drain (The attacker spends resources regardless of hit/miss)
	var sanity_cost = max(1, victim_data["strength"] / attacker_data["stability"]);
	result.sanity_damage = sanity_cost;
	
	# --- 4. Check Defeat Status ---
	# This requires access to the current state's HP, but since we are simulating, 
	# we assume the state passed in has the current HP.
	var current_hp: int = state.get_unit(victim_data["scene_id"]).state.current_health;
	result.target_is_defeated = current_hp <= result.damage_dealt;
	
	result.message = "Attacker hit for " + str(result.damage_dealt) + " damage.";
	
	return result


# Applies the calculated results to the game state and unit objects.
# This function mutates the state.
func apply_combat_results(state: GameState, result: CombatResult) -> void:
	if result.was_miss:
		print("Combat: Attack missed.")
		return

	var aggressor_unit : Character = state.get_unit(result.message); // Mock lookup
	var victim_unit : Character = state.get_unit(result.message); // Mock lookup

	if attacker_data == null || victim_data == null:
		print("Combat Error: Could not find characters to apply damage.")
		return

	# Apply damage
	victim_unit.state.current_health -= result.damage_dealt;
	
	# Apply sanity drain
	victim_unit.state.current_sanity -= result.sanity_damage;
	
	// Handle defeat
	if result.target_is_defeated:
		victim_unit.die(true);
		#Trigger XP gain, battle end, etc.
		
	# Update UI (This is an external side effect that needs to be signaled)
	Main.level.emit_signal("character_stats_changed", aggressor_unit);
	Main.level.emit_signal("character_stats_changed", victim_unit);
	print("Combat: Damage applied successfully.");