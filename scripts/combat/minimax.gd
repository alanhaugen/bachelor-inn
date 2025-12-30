class_name MinimaxAI
extends RefCounted


func minimax(state : GameState, depth : int, maximizing : bool) -> int:
	if depth == 0 or is_terminal(state):
		return evaluate(state);

	if maximizing:
		var best := -INF;
		for move : Move in state.moves:
			var next_state : GameState = state.apply_move(move);
			best = max(best, minimax(next_state, depth - 1, false));
		return best
	else:
		var best := INF;
		for move : Move in state.moves:
			var next_state : GameState = state.apply_move(move);
			best = min(best, minimax(next_state, depth - 1, true));
		return best;
	

func evaluate(state : GameState) -> int:
	var score := 0;

	for unit in state.units:
		if unit.is_playable == false:
			score += unit.hp * 10;
		else:
			score -= unit.hp * 10;
		pass;

	return score;


func is_terminal(state : GameState) -> bool:
	var enemy_alive := false;
	var player_alive := false;

	for unit in state.units:
		if unit.is_playable == false:
			enemy_alive = true;
		else:
			player_alive = true;
		pass;

	return not enemy_alive or not player_alive;


func choose_best_move(state : GameState, depth : int) -> Move:
	var best_score := -INF;
	var best_move : Command = null;

	for move : Command in state.moves:
		var next_state : GameState = state.apply_move(move);
		var score : int = minimax(next_state, depth - 1, false);

		if score > best_score:
			best_score = score;
			best_move = move;

	return best_move;
