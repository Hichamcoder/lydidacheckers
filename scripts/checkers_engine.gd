extends RefCounted
class_name CheckersEngine

const ENGLISH := 0
const SPANISH := 1
const BOARD_SIZE := 8

static func empty_board() -> Array:
	var board: Array = []
	for _y in range(BOARD_SIZE):
		var row: Array[int] = []
		for _x in range(BOARD_SIZE):
			row.append(0)
		board.append(row)
	return board

static func initial_board() -> Array:
	var board := empty_board()
	for y in range(3):
		for x in range(BOARD_SIZE):
			if _playable(y, x):
				board[y][x] = -1
	for y in range(5, BOARD_SIZE):
		for x in range(BOARD_SIZE):
			if _playable(y, x):
				board[y][x] = 1
	return board

static func copy_board(board: Array) -> Array:
	var result: Array = []
	for row in board:
		result.append(row.duplicate())
	return result

static func count_pieces(board: Array, side: int) -> int:
	var total := 0
	for row in board:
		for piece in row:
			if int(piece) != 0 and (int(piece) > 0) == (side > 0):
				total += 1
	return total

static func legal_moves(board: Array, side: int, rules: int) -> Array[Dictionary]:
	var captures: Array[Dictionary] = []
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var piece := int(board[y][x])
			if piece == 0 or (piece > 0) != (side > 0):
				continue
			var origin := Vector2i(x, y)
			_collect_captures(board, origin, origin, piece, side, rules, [origin], [], captures)

	if not captures.is_empty():
		if rules == SPANISH:
			var best_count := 0
			for move in captures:
				best_count = maxi(best_count, move["captures"].size())
			var maximum_lines: Array[Dictionary] = []
			for move in captures:
				if move["captures"].size() == best_count:
					maximum_lines.append(move)
			return maximum_lines
		return captures

	var quiet: Array[Dictionary] = []
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var piece := int(board[y][x])
			if piece == 0 or (piece > 0) != (side > 0):
				continue
			var from := Vector2i(x, y)
			for to in _quiet_destinations(board, from, piece, side, rules):
				quiet.append({
					"from": from, "to": to, "path": [from, to],
					"captures": [], "captured_kings": 0
				})
	return quiet

static func apply_move(board: Array, move: Dictionary, side: int) -> Array:
	var result := copy_board(board)
	var from: Vector2i = move["from"]
	var to: Vector2i = move["to"]
	var piece := int(result[from.y][from.x])
	result[from.y][from.x] = 0
	for captured_square in move["captures"]:
		var square: Vector2i = captured_square
		result[square.y][square.x] = 0
	if abs(piece) == 1 and _promotion_row(to.y, side):
		piece = side * 2
	result[to.y][to.x] = piece
	return result

static func evaluate(board: Array, perspective: int) -> int:
	var score := 0
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var piece := int(board[y][x])
			if piece == 0:
				continue
			var side := 1 if piece > 0 else -1
			var value := 100 if abs(piece) == 1 else 325
			if abs(piece) == 1:
				value += ((7 - y) if side > 0 else y) * 4
			else:
				value += 10
			value += (6 - absi(x * 2 - 7) - absi(y * 2 - 7)) * 2
			score += side * value
	return score * perspective

static func _collect_captures(board: Array, origin: Vector2i, current: Vector2i,
		piece: int, side: int, rules: int, path: Array, captured: Array,
		output: Array[Dictionary]) -> void:
	var options := _capture_options(board, current, piece, side, rules)
	if options.is_empty():
		if not captured.is_empty():
			output.append({
				"from": origin, "to": current, "path": path.duplicate(),
				"captures": captured.duplicate(),
				"captured_kings": _count_captured_kings(board, captured)
			})
		return

	for option in options:
		var landing: Vector2i = option["to"]
		var victim: Vector2i = option["captured"]
		var victim_piece := int(board[victim.y][victim.x])
		board[current.y][current.x] = 0
		board[victim.y][victim.x] = 0
		board[landing.y][landing.x] = piece

		var next_path: Array = path.duplicate()
		next_path.append(landing)
		var next_captured: Array = captured.duplicate()
		next_captured.append(victim)

		# A man reaching the promotion row completes its move before becoming a king.
		if abs(piece) == 1 and _promotion_row(landing.y, side):
			output.append({
				"from": origin, "to": landing, "path": next_path,
				"captures": next_captured,
				"captured_kings": _count_captured_kings_from_list(board, next_captured, victim_piece)
			})
		else:
			_collect_captures(board, origin, landing, piece, side, rules,
				next_path, next_captured, output)

		board[landing.y][landing.x] = 0
		board[victim.y][victim.x] = victim_piece
		board[current.y][current.x] = piece

static func _capture_options(board: Array, current: Vector2i, piece: int,
		side: int, rules: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var directions := _directions(piece, side, rules, true)

	# Spanish kings are flying kings: one opposing piece may be captured at range,
	# and the king may land on any empty square immediately beyond it.
	if rules == SPANISH and abs(piece) == 2:
		for direction in directions:
			var cursor: Vector2i = current + direction
			while _inside(cursor) and int(board[cursor.y][cursor.x]) == 0:
				cursor += direction
			if not _inside(cursor):
				continue
			var target := int(board[cursor.y][cursor.x])
			if target == 0 or (target > 0) == (side > 0):
				continue
			var landing: Vector2i = cursor + direction
			while _inside(landing) and int(board[landing.y][landing.x]) == 0:
				result.append({"to": landing, "captured": cursor})
				landing += direction
		return result

	for direction in directions:
		var victim := current + direction
		var landing := current + direction * 2
		if not _inside(victim) or not _inside(landing):
			continue
		var target := int(board[victim.y][victim.x])
		if target == 0 or (target > 0) == (side > 0):
			continue
		if int(board[landing.y][landing.x]) == 0:
			result.append({"to": landing, "captured": victim})
	return result

static func _quiet_destinations(board: Array, from: Vector2i, piece: int,
		side: int, rules: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction in _directions(piece, side, rules, false):
		var cursor: Vector2i = from + direction
		if rules == SPANISH and abs(piece) == 2:
			while _inside(cursor) and int(board[cursor.y][cursor.x]) == 0:
				result.append(cursor)
				cursor += direction
		elif _inside(cursor) and int(board[cursor.y][cursor.x]) == 0:
			result.append(cursor)
	return result

static func _directions(piece: int, side: int, rules: int, is_capture: bool) -> Array[Vector2i]:
	if abs(piece) == 2 or (rules == SPANISH and is_capture):
		return [
			Vector2i(-1, -1), Vector2i(1, -1),
			Vector2i(-1, 1), Vector2i(1, 1)
		]
	var forward := -1 if side > 0 else 1
	return [Vector2i(-1, forward), Vector2i(1, forward)]

static func _count_captured_kings(board: Array, captured: Array) -> int:
	# Captured pieces have already been removed from the search board. This helper
	# is retained for the list-based tally fallback used by promotion termination.
	return 0

static func _count_captured_kings_from_list(board: Array, captured: Array, last_piece: int) -> int:
	# Captured-piece priority is not used in Spanish rules in this implementation.
	return 0

static func _playable(y: int, x: int) -> bool:
	return (y + x) % 2 == 1

static func _promotion_row(y: int, side: int) -> bool:
	return y == 0 if side > 0 else y == BOARD_SIZE - 1

static func _inside(square: Vector2i) -> bool:
	return square.x >= 0 and square.x < BOARD_SIZE and square.y >= 0 and square.y < BOARD_SIZE
