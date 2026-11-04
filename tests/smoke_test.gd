extends SceneTree

const Engine = preload("res://scripts/checkers_engine.gd")
const AI = preload("res://scripts/checkers_ai.gd")
var failures := 0

func _initialize() -> void:
	_test_opening_position()
	_test_english_forced_capture()
	_test_spanish_backward_man_capture()
	_test_spanish_maximum_capture()
	_test_spanish_flying_king()
	_test_promotion()
	_test_ai_returns_legal_move()
	if failures == 0:
		print("ALL CHECKERS SMOKE TESTS PASSED")
		quit(0)
	else:
		push_error(str(failures, " test(s) failed"))
		quit(1)

func _check(ok: bool, name: String) -> void:
	if ok:
		print("PASS: ", name)
	else:
		failures += 1
		push_error("FAIL: " + name)

func _test_opening_position() -> void:
	var board := Engine.initial_board()
	_check(Engine.count_pieces(board, 1) == 12, "opening has 12 player pieces")
	_check(Engine.count_pieces(board, -1) == 12, "opening has 12 opponent pieces")
	_check(Engine.legal_moves(board, 1, Engine.ENGLISH).size() == 7, "English opening legal move count")

func _test_english_forced_capture() -> void:
	var board := Engine.empty_board()
	board[5][2] = 1
	board[4][3] = -1
	board[5][6] = 1
	var moves := Engine.legal_moves(board, 1, Engine.ENGLISH)
	_check(moves.size() == 1 and moves[0]["captures"].size() == 1, "English capture is mandatory")

func _test_spanish_backward_man_capture() -> void:
	var board := Engine.empty_board()
	board[2][2] = 1
	board[3][1] = -1
	var moves := Engine.legal_moves(board, 1, Engine.SPANISH)
	_check(moves.size() == 1 and moves[0]["to"] == Vector2i(0, 4), "Spanish man captures backwards")

func _test_spanish_maximum_capture() -> void:
	var board := Engine.empty_board()
	board[6][0] = 1
	board[5][1] = -1
	board[3][3] = -1
	board[1][5] = -1
	board[6][6] = 1
	board[5][5] = -1
	var moves := Engine.legal_moves(board, 1, Engine.SPANISH)
	var all_max := not moves.is_empty()
	for move in moves:
		if move["captures"].size() != 3:
			all_max = false
	_check(all_max, "Spanish rule selects the maximum capture sequence")

func _test_spanish_flying_king() -> void:
	var board := Engine.empty_board()
	board[4][1] = 2
	board[2][3] = -1
	var moves := Engine.legal_moves(board, 1, Engine.SPANISH)
	var near_landing := false
	var far_landing := false
	for move in moves:
		if move["to"] == Vector2i(4, 1):
			near_landing = true
		if move["to"] == Vector2i(5, 0):
			far_landing = true
	_check(near_landing and far_landing, "Spanish king can land on multiple squares beyond a capture")

func _test_promotion() -> void:
	var board := Engine.empty_board()
	board[1][2] = 1
	var move_found: Dictionary = {}
	for move in Engine.legal_moves(board, 1, Engine.ENGLISH):
		if move["to"] == Vector2i(3, 0):
			move_found = move
			break
	var after := Engine.apply_move(board, move_found, 1) if not move_found.is_empty() else board
	_check(not move_found.is_empty() and int(after[0][3]) == 2, "promotion creates a king")

func _test_ai_returns_legal_move() -> void:
	var board := Engine.initial_board()
	var ai := AI.new()
	var chosen: Dictionary = ai.choose_move(board, -1, Engine.ENGLISH, 2, 5000)
	var valid := false
	for move in Engine.legal_moves(board, -1, Engine.ENGLISH):
		if move.get("from") == chosen.get("from") and move.get("to") == chosen.get("to"):
			valid = true
			break
	_check(valid, "AI selects a legal move")
