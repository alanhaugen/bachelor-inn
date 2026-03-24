class_name MinimaxAI
extends RefCounted

func minimax(state : GameState, depth : int, specific_character_pos : NullablePosition = null) -> float:
	if depth == 0:
		return evaluate(state) * 1.0

	var moves : Array[Command] = state.get_legal_moves(specific_character_pos)
	if moves.is_empty():
		return evaluate(state) * 1.0

	var enemy_turn := state.is_current_player_enemy
	
	
	if enemy_turn:
		var best_enemy : float = -999999.0
		for move : Command in moves:
			var end_pos : NullablePosition = null
			if specific_character_pos != null:
				if move is Attack:
					end_pos = NullablePosition.new(move.end_pos)
				elif move is Move:
					end_pos = NullablePosition.new(move.end_pos)
				else:
					push_error("UNHANDLED COMMAND TYPE")
			best_enemy = max(best_enemy, minimax(state.apply_move(move, true), depth - 1, end_pos))
		return best_enemy
	else:
		var best_player : float = 999999.0
		for move : Command in moves:
			var end_pos : NullablePosition = null
			if specific_character_pos != null:
				if move is Attack:
					end_pos = NullablePosition.new(move.end_pos)
				elif move is Move:
					end_pos = NullablePosition.new(move.end_pos)
				else:
					push_error("UNHANDLED COMMAND TYPE")
			best_player = min(best_player, minimax(state.apply_move(move, true), depth - 1, end_pos))
		return best_player


func evaluate(state : GameState) -> int:
	var score := 0
	
	# Collect all player units and their positions
	var player_units : Array[Character] = []
	for unit in state.units:
		if unit.state.is_alive and not unit.state.is_enemy():
			player_units.append(unit)
	
	for unit : Character in state.units:
		if not unit.state.is_alive:
			continue

		var unit_value := unit.state.current_health * 10

		if unit.state.is_enemy():
			# Basic value
			score += unit_value
			score += 50 # Bonus for being alive
			
			# Find closest player
			var closest_dist := 999
			var closest_player : Character = null
			for player : Character in player_units:
				var dist : int = abs(player.state.grid_position.x - unit.state.grid_position.x) + abs(player.state.grid_position.z - unit.state.grid_position.z)
				if dist < closest_dist:
					closest_dist = dist
					closest_player = player
			
			# Distance incentive: closer to player = better
			if closest_player:
				score += max(0, 20 - closest_dist)
				
				# If we can attack THIS turn (dist <= weapon range from CURRENT pos)
				if unit.state.weapon:
					if closest_dist <= unit.state.weapon.max_range:
						score += 50
			
		else:
			# Player units reduce total score
			score -= unit_value
			score -= 50 # Penalty for players being alive

	return score


func choose_best_move(state : GameState, depth : int, specific_character : Character = null) -> Command:
	var best_score : float = -999999.0
	var best_move : Command = null
	var start_pos : NullablePosition = null
	
	if(specific_character != null):
		start_pos = NullablePosition.new(specific_character.state.grid_position)
		
	for move in state.get_legal_moves(start_pos):
		var end_pos : NullablePosition = null
		if(specific_character != null):
			if move is Attack:
				end_pos = NullablePosition.new(move.end_pos)
			elif move is Move:
				end_pos = NullablePosition.new(move.end_pos)
			else:
				push_error("UNHANDLED COMMAND TYPE")
			
		var move_state : GameState = state.apply_move(move, true)
		var score : float = minimax(move_state, depth, end_pos)

		if score > best_score:
			best_score = score
			best_move = move

	return best_move
