extends Control

const Engine = preload("res://scripts/checkers_engine.gd")
const AI = preload("res://scripts/checkers_ai.gd")

const BG := Color("#101820")
const PANEL := Color("#1A2832")
const ACTIVE := Color("#2A414C")
const LIGHT := Color("#E7D8BD")
const DARK := Color("#526C63")
const HUMAN := Color("#F2E8D5")
const COMPUTER := Color("#202A31")
const GOLD := Color("#D5A45B")
const MUTED := Color("#A6B4B7")

var screen := "home"
var rules := Engine.ENGLISH
var difficulty := 5
var board: Array = []
var side_to_move := 1
var selected := Vector2i(-1, -1)
var candidate_moves: Array[Dictionary] = []
var route_step := 1
var is_ai_thinking := false
var game_finished := false
var message := ""
var history: Array[Dictionary] = []
var board_rect := Rect2()
var english_rect := Rect2()
var spanish_rect := Rect2()
var tactical_rect := Rect2()
var strong_rect := Rect2()
var elite_rect := Rect2()
var undo_rect := Rect2()
var restart_rect := Rect2()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	if screen == "home":
		_draw_home()
	else:
		_draw_game()

func _draw_home() -> void:
	_text("LYDIDA", Vector2(28, 116), 24, GOLD)
	_text("CHECKERS", Vector2(28, 184), 52, Color("#F3EEE5"))
	_text("A focused checkers experience", Vector2(31, 222), 18, MUTED)
	_text("CHOOSE YOUR RULESET", Vector2(28, size.y * 0.34), 16, GOLD)

	english_rect = Rect2(Vector2(22, size.y * 0.39), Vector2(size.x - 44, 94))
	spanish_rect = Rect2(Vector2(22, size.y * 0.52), Vector2(size.x - 44, 94))
	_button(english_rect, "ENGLISH CHECKERS", rules == Engine.ENGLISH)
	_text("Short-range kings · mandatory captures", english_rect.position + Vector2(18, 68), 14, MUTED)
	_button(spanish_rect, "SPANISH DRAUGHTS", rules == Engine.SPANISH)
	_text("Flying kings · maximum capture", spanish_rect.position + Vector2(18, 68), 14, MUTED)

	_text("AI LEVEL", Vector2(28, size.y * 0.69), 16, GOLD)
	var gap := 10.0
	var width := (size.x - 44.0 - gap * 2.0) / 3.0
	var y := size.y * 0.735
	tactical_rect = Rect2(Vector2(22, y), Vector2(width, 58))
	strong_rect = Rect2(Vector2(22 + width + gap, y), Vector2(width, 58))
	elite_rect = Rect2(Vector2(22 + (width + gap) * 2.0, y), Vector2(width, 58))
	_button(tactical_rect, "TACTICAL", difficulty == 3)
	_button(strong_rect, "STRONG", difficulty == 5)
	_button(elite_rect, "ELITE", difficulty == 7)
	_text("Search depth and node budget are limited for mobile devices.", Vector2(28, size.y * 0.84), 13, MUTED)
	_text("OFFLINE PLAY · NO ACCOUNT REQUIRED", Vector2(28, size.y - 34), 13, MUTED)

func _draw_game() -> void:
	_text("LYDIDA CHECKERS", Vector2(22, 54), 22, GOLD)
	_text("ENGLISH CHECKERS" if rules == Engine.ENGLISH else "SPANISH DRAUGHTS",
		Vector2(22, 84), 14, MUTED)
	var turn := message
	if not game_finished and not is_ai_thinking:
		turn = "YOUR TURN" if side_to_move > 0 else "AI TURN"
	_text(turn, Vector2(22, 122), 18, Color("#F3EEE5"))

	board_rect = _board_layout()
	var cell := board_rect.size.x / 8.0
	var targets: Array[Vector2i] = []
	for move in candidate_moves:
		var path: Array = move["path"]
		if path.size() > route_step:
			targets.append(path[route_step])

	for y in range(8):
		for x in range(8):
			var rect := Rect2(board_rect.position + Vector2(x * cell, y * cell), Vector2(cell, cell))
			draw_rect(rect, DARK if (x + y) % 2 == 1 else LIGHT)
			if selected == Vector2i(x, y):
				draw_rect(rect, Color(GOLD, 0.40))
			if Vector2i(x, y) in targets:
				draw_circle(rect.get_center(), cell * 0.13, GOLD)

	for y in range(8):
		for x in range(8):
			var piece := int(board[y][x])
			if piece != 0:
				_draw_piece(board_rect.position + Vector2((x + 0.5) * cell, (y + 0.5) * cell),
					cell * 0.39, piece)

	var controls_y := board_rect.position.y + board_rect.size.y + 18.0
	var gap := 12.0
	var width := (size.x - 44.0 - gap) / 2.0
	undo_rect = Rect2(Vector2(22, controls_y), Vector2(width, 52))
	restart_rect = Rect2(Vector2(22 + width + gap, controls_y), Vector2(width, 52))
	_button(undo_rect, "UNDO TURN", false)
	_button(restart_rect, "NEW GAME", false)
	_text("Tap a piece, then follow the highlighted capture path.", Vector2(22, controls_y + 80), 13, MUTED)

func _draw_piece(center: Vector2, radius: float, piece: int) -> void:
	var fill := HUMAN if piece > 0 else COMPUTER
	var rim := GOLD if piece > 0 else Color("#82949A")
	draw_circle(center + Vector2(0, radius * 0.10), radius, Color(0, 0, 0, 0.30))
	draw_circle(center, radius * 0.91, rim)
	draw_circle(center, radius * 0.78, fill)
	draw_arc(center, radius * 0.60, 0.0, TAU, 40, rim, 2.0, true)
	if abs(piece) == 2:
		draw_circle(center, radius * 0.24, GOLD)
		_center_text("K", center + Vector2(0, radius * 0.12), 18, Color("#172128"))

func _button(rect: Rect2, label: String, active: bool) -> void:
	draw_rect(rect, ACTIVE if active else PANEL, true, 12.0)
	draw_rect(rect, GOLD if active else Color("#3A4B53"), false, 1.5, true)
	_center_text(label, rect.get_center() + Vector2(0, 7), 16, Color("#F3EEE5"))

func _text(value: String, position: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _center_text(value: String, center: Vector2, font_size: int, color: Color) -> void:
	var measured := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	draw_string(ThemeDB.fallback_font, Vector2(center.x - measured.x / 2.0, center.y),
		value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)

func _board_layout() -> Rect2:
	var board_size := minf(size.x - 32.0, size.y * 0.64)
	var top := maxf(132.0, (size.y - board_size - 175.0) * 0.5)
	return Rect2(Vector2((size.x - board_size) / 2.0, top), Vector2(board_size, board_size))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)
		accept_event()

func _handle_tap(point: Vector2) -> void:
	if screen == "home":
		if english_rect.has_point(point):
			rules = Engine.ENGLISH
			_start_game()
		elif spanish_rect.has_point(point):
			rules = Engine.SPANISH
			_start_game()
		elif tactical_rect.has_point(point):
			difficulty = 3
			queue_redraw()
		elif strong_rect.has_point(point):
			difficulty = 5
			queue_redraw()
		elif elite_rect.has_point(point):
			difficulty = 7
			queue_redraw()
		return

	if undo_rect.has_point(point):
		_undo_turn()
		return
	if restart_rect.has_point(point):
		_start_game()
		return
	if is_ai_thinking or game_finished or side_to_move != 1:
		return
	if board_rect.has_point(point):
		var cell := board_rect.size.x / 8.0
		var x := clampi(int((point.x - board_rect.position.x) / cell), 0, 7)
		var y := clampi(int((point.y - board_rect.position.y) / cell), 0, 7)
		_handle_board_square(Vector2i(x, y))

func _start_game() -> void:
	board = Engine.initial_board()
	side_to_move = 1
	selected = Vector2i(-1, -1)
	candidate_moves.clear()
	route_step = 1
	is_ai_thinking = false
	game_finished = false
	message = "YOUR TURN"
	history.clear()
	screen = "game"
	_save_position()
	queue_redraw()

func _handle_board_square(square: Vector2i) -> void:
	if not candidate_moves.is_empty():
		var matching: Array[Dictionary] = []
		for move in candidate_moves:
			var path: Array = move["path"]
			if path.size() > route_step and path[route_step] == square:
				matching.append(move)
		if not matching.is_empty():
			var completed: Dictionary = {}
			for move in matching:
				if move["path"].size() == route_step + 1:
					completed = move
					break
			if not completed.is_empty():
				_commit_human_move(completed)
			else:
				candidate_moves = matching
				route_step += 1
				selected = square
				queue_redraw()
			return

	var piece := int(board[square.y][square.x])
	if piece > 0:
		candidate_moves.clear()
		for move in Engine.legal_moves(board, 1, rules):
			if move["from"] == square:
				candidate_moves.append(move)
		selected = square if not candidate_moves.is_empty() else Vector2i(-1, -1)
		route_step = 1
	else:
		selected = Vector2i(-1, -1)
		candidate_moves.clear()
	queue_redraw()

func _commit_human_move(move: Dictionary) -> void:
	board = Engine.apply_move(board, move, 1)
	selected = Vector2i(-1, -1)
	candidate_moves.clear()
	route_step = 1
	side_to_move = -1
	if Engine.legal_moves(board, -1, rules).is_empty():
		game_finished = true
		message = "YOU WIN"
		_save_position()
		queue_redraw()
		return
	message = "AI THINKING"
	queue_redraw()
	call_deferred("_run_ai_turn")

func _run_ai_turn() -> void:
	is_ai_thinking = true
	queue_redraw()
	var ai := AI.new()
	var worker := Thread.new()
	var snapshot := Engine.copy_board(board)
	var start_error := worker.start(Callable(ai, "choose_move").bind(snapshot, -1, rules, difficulty, 30000))
	if start_error != OK:
		is_ai_thinking = false
		message = "AI COULD NOT START"
		queue_redraw()
		return
	while worker.is_alive():
		await get_tree().create_timer(0.04).timeout
	var move: Dictionary = worker.wait_to_finish()
	is_ai_thinking = false
	if move.is_empty():
		game_finished = true
		message = "YOU WIN"
	else:
		board = Engine.apply_move(board, move, -1)
		side_to_move = 1
		if Engine.legal_moves(board, 1, rules).is_empty():
			game_finished = true
			message = "AI WINS"
		else:
			message = "YOUR TURN"
	_save_position()
	queue_redraw()

func _save_position() -> void:
	history.append({"board": Engine.copy_board(board), "side": side_to_move})

func _undo_turn() -> void:
	if is_ai_thinking or history.size() < 2:
		return
	history.pop_back()
	var previous: Dictionary = history[history.size() - 1]
	board = Engine.copy_board(previous["board"])
	side_to_move = int(previous["side"])
	selected = Vector2i(-1, -1)
	candidate_moves.clear()
	route_step = 1
	game_finished = false
	message = "YOUR TURN"
	queue_redraw()
