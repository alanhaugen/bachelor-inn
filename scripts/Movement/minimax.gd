class_name MinimaxAI
extends RefCounted

func minimax(state : GameState, depth : int, specific_character_pos : NullablePosition = null) -> float:
	if depth == 0:
		return evaluate(state)

	var moves : Array[Command] = state.get_legal_moves(specific_character_pos)
	if moves.is_empty():
		return evaluate(state)

	var enemy_turn := state.is_current_player_enemy
	
	
	if enemy_turn:
		var best := -INF
		for move : Command in moves:
			var end_pos : NullablePosition = null
			if specific_character_pos != null:
				if move is Attack:
					end_pos = NullablePosition.new(move.attack_pos)
				elif move is Move:
					end_pos = NullablePosition.new(move.end_pos)
				else:
					push_error("UNHANDLED COMMAND TYPE")
			best = max(best, minimax(state.apply_move(move, true), depth - 1, end_pos))
		return best
	else:
		var best := INF
		for move : Command in moves:
			var end_pos : NullablePosition = null
			if specific_character_pos != null:
				if move is Attack:
					end_pos = NullablePosition.new(move.attack_pos)
				elif move is Move:
					end_pos = NullablePosition.new(move.end_pos)
				else:
					push_error("UNHANDLED COMMAND TYPE")
			best = min(best, minimax(state.apply_move(move, true), depth - 1, end_pos))
		return best


func evaluate(state : GameState) -> int:
	var score := 0
	
	# Collect all player units and their positions
	var player_units := []
	var player_positions := []
	for unit in state.units:
		if not unit.state.is_enemy():
			player_units.append(unit)
			player_positions.append(unit.state.grid_position)
	
	for player : Character in player_units:
				var damage_dealt : int = player.state.max_health - player.state.current_health
				if damage_dealt > 0:
					score += damage_dealt * 10  # reward proportional to damage dealt
				if not player.state.is_alive:
					score += 500  # big bonus for killing a player unit
	
	for unit : Character in state.units:
		var unit_value := unit.state.current_health * 10
		if unit.state.is_enemy():
			# Basic value
			score += unit_value
			
			# Mobility bonus
			if not unit.state.is_moved:
				score += 5
			
			# Find closest player
			var closest_dist := 99999 #INF
			var closest_player : Character = null
			for player : Character in player_units:
				var dist : int = abs(player.state.grid_position.x - unit.state.grid_position.x) + abs(player.state.grid_position.z - unit.state.grid_position.z)
				if dist < closest_dist:
					closest_dist = dist
					closest_player = player
			
			# Distance incentive: closer to player = better
			score += max(0, 10 - closest_dist)
			
			# Best outcome, execute an attack
			#if unit.state.is_ability_used:
				#print("Enemy used ability - adding 200 bonus")
				#score += 200
			
			
			# Bonus for being in weapon range
			#if closest_dist >= unit.state.weapon.min_range and closest_dist <= unit.state.weapon.max_range:
				#score += 100
				#if closest_player:
					#score += max(0, 20 - closest_player.state.current_health)
			
			# Big bonus for being able to attack next turn (weapon range commented out)
			if closest_dist <= unit.state.movement: # + unit.state.weapon.max_range:
				score += 100  # strong incentive to attack
				
				# Bonus for finishing off low-health target
				if closest_player:
					score += max(0, 20 - closest_player.state.current_health)
			
			# Slight penalty for moving away from closest player
			## TODO: float converted to int here
			score -= closest_dist * 2

		else:
			# Player units reduce total score
			score -= unit_value
			if not unit.state.is_moved:
				score -= 2

	return score


func choose_best_move(state : GameState, depth : int, specific_character : Character = null) -> Command:
	var best_score := -INF
	var best_move : Command = null
	var start_pos : NullablePosition = null
	
	if(specific_character != null):
		start_pos = NullablePosition.new(specific_character.state.grid_position)
		
	for move in state.get_legal_moves(start_pos):
		var end_pos : NullablePosition = null
		if(specific_character != null):
			if move is Attack:
				end_pos = NullablePosition.new(move.attack_pos)
			elif move is Move:
				end_pos = NullablePosition.new(move.end_pos)
			else:
				push_error("UNHANDLED COMMAND TYPE")
			
		var move_state : GameState = state.apply_move(move, true)
		var score : float = minimax(move_state, depth - 1, end_pos)
		
		print("Move: ", move.get_class(), " score: ", score)
		if score > best_score:
			best_score = score
			best_move = move
	
	print("Best move: ", best_move.get_class() if best_move != null else "null", " score: ", best_score)
	return best_move
