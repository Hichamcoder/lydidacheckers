extends RefCounted
class_name CheckersAI

const Engine = preload("res://scripts/checkers_engine.gd")
const INF := 10000000
const WIN_SCORE := 100000

var _nodes := 0
var _node_limit := 30000
var _table: Dictionary = {}

func choose_move(board: Array, side: int, rules: int, max_depth: int = 6,
		node_limit: int = 30000) -> Dictionary:
	_nodes = 0
	_node_limit = maxi(1000, node_limit)
	_table.clear()
	var moves := Engine.legal_moves(board, side, rules)
	if moves.is_empty():
		return {}
	moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _order_score(a) > _order_score(b)
	)
	var best := moves[0]
	for depth in range(1, maxi(1, max_depth) + 1):
		var iteration_best: Dictionary = best
		var iteration_score := -INF
		var alpha := -INF
		for move in moves:
			var next_board := Engine.apply_move(board, move, side)
			var score := _search(next_board, -side, side, rules, depth - 1, alpha, INF, 1)
			if score > iteration_score:
				iteration_score = score
				iteration_best = move
			alpha = maxi(alpha, iteration_score)
			if _nodes >= _node_limit:
				break
		best = iteration_best
		if _nodes >= _node_limit:
			break
	return best

func _search(board: Array, side: int, root: int, rules: int, depth: int,
		alpha_in: int, beta_in: int, ply: int) -> int:
	if _nodes >= _node_limit:
		return Engine.evaluate(board, root)
	_nodes += 1
	var moves := Engine.legal_moves(board, side, rules)
	if moves.is_empty():
		return -WIN_SCORE + ply if side == root else WIN_SCORE - ply

	var alpha := alpha_in
	var beta := beta_in
	var original_alpha := alpha
	var original_beta := beta
	var key := _key(board, side, rules)
	if _table.has(key):
		var item: Dictionary = _table[key]
		if int(item.depth) >= depth:
			var cached := int(item.score)
			match int(item.flag):
				0:
					return cached
				1:
					alpha = maxi(alpha, cached)
				-1:
					beta = mini(beta, cached)
			if alpha >= beta:
				return cached

	if depth <= 0:
		return Engine.evaluate(board, root)

	moves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _order_score(a) > _order_score(b)
	)
	var maximizing := side == root
	var best_score := -INF if maximizing else INF
	for move in moves:
		var child := Engine.apply_move(board, move, side)
		var score := _search(child, -side, root, rules, depth - 1, alpha, beta, ply + 1)
		if maximizing:
			best_score = maxi(best_score, score)
			alpha = maxi(alpha, best_score)
		else:
			best_score = mini(best_score, score)
			beta = mini(beta, best_score)
		if beta <= alpha or _nodes >= _node_limit:
			break

	var flag := 0
	if best_score <= original_alpha:
		flag = -1
	elif best_score >= original_beta:
		flag = 1
	_table[key] = {"depth": depth, "score": best_score, "flag": flag}
	return best_score

func _order_score(move: Dictionary) -> int:
	return move["captures"].size() * 1000

func _key(board: Array, side: int, rules: int) -> String:
	var key := str(side, ":", rules, ":")
	for row in board:
		for piece in row:
			key += str(int(piece) + 2)
	return key
