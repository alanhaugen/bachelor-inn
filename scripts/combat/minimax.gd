class_name MinimaxAI
extends RefCounted


func minimax(state : GameState, depth : int) -> int:
	if depth == 0:
		return evaluate(state)

	var moves : Array[Command] = state.get_legal_moves()
	if moves.is_empty():
		return evaluate(state)

	var enemy_turn := state.is_current_player_enemy

	if enemy_turn:
		var best := -INF
		for move : Command in moves:
			best = max(best, minimax(state.apply_move(move, true), depth - 1))
		return best
	else:
		var best := INF
		for move : Command in moves:
			best = min(best, minimax(state.apply_move(move, true), depth - 1))
		return best


func evaluate(state : GameState) -> int:
	var score := 0

	# Collect player positions
	var player_positions := []
	for unit in state.units:
		if not unit.is_enemy:
			player_positions.append(unit.grid_position) # or unit.position if using world pos

	for unit : Character in state.units:
		var value : int = unit.current_health * 10

		if unit.is_enemy:
			score += value
			if not unit.is_moved:
				score += 2 # mobility bonus
			
			# Proximity bonus: closer to player is better
			var closest_dist := INF
			for player_pos : Vector3i in player_positions:
				var dist : int = abs(player_pos.x - unit.grid_position.x) + abs(player_pos.z - unit.grid_position.z)
				if dist < closest_dist:
					closest_dist = dist
			# Inverse distance: closer = higher score
			score += max(0, 10 - closest_dist)  # tweak 10 to adjust weight
		else:
			score -= value
			if not unit.is_moved:
				score -= 2

	return score


func choose_best_move(state : GameState, depth : int) -> Command:
	var best_score := -INF
	var best_move : Command = null
	
	for move in state.get_legal_moves():
		var score : int = minimax(state.apply_move(move, true), depth - 1)

		if score > best_score:
			best_score = score
			best_move = move

	return best_move
