class_name Minimax
extends Node


func minimax(state : GameState, depth : int, maximizing : bool) -> int:
	if depth == 0 or is_terminal(state):
		return evaluate(state)

	return INF;
	#if maximizing:
		#var best := -INF
		#for move : Move in state.moves:
		#	var next_state = apply_move(state, move)
		#	best = max(best, minimax(next_state, depth - 1, false))
		#return best
	#else:
		#var best := INF
		#for move in moves:
		#	var next_state = apply_move(state, move)
		#	best = min(best, minimax(next_state, depth - 1, true))
		#return best
	

func evaluate(state : GameState) -> int:
	var score := 0

	for unit in state.units:
		#if unit.owner == ENEMY:
		#	score += unit.hp * 10
		#else:
		#	score -= unit.hp * 10
		pass;

	return score


func is_terminal(state : GameState) -> bool:
	var enemy_alive := false
	var player_alive := false

	for unit in state.units:
		#if unit.owner == ENEMY:
		#	enemy_alive = true
		#else:
		#	player_alive = true
		pass;

	return not enemy_alive or not player_alive
	
func choose_best_move(state : GameState, depth : int) -> Move:
	var best_score := -INF
	var best_move : Move = null

	for move in state.moves:
		#var next_state = apply_move(state, move)
		#var score = minimax(next_state, depth - 1, false)

		#if score > best_score:
		#	best_score = score
			best_move = move

	return best_move

func apply_move(state : GameState, move : Move) -> GameState:
	var new_state := state.duplicate(true);

	# Move unit
	for unit : Character in new_state.units:
		if unit.pos == move.start_pos:
			unit.pos = move.end_pos

	# Handle attack
	if move.is_attack:
		for unit : Character in new_state.units:
			if unit.pos == move.attack_pos:
				unit.hp -= move.damage

	return new_state
