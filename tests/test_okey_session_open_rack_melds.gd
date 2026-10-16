extends RefCounted

const SESSION = preload("res://ui/game_table/OkeySession.gd")

func run() -> bool:
	var ok: bool = _test_open_rack_melds_valid() and _test_open_rack_melds_below_threshold()
	if ok:
		print("  PASS  test_okey_session_open_rack_melds")
	return ok

func _check(value: bool, message: String) -> bool:
	if not value:
		push_error("test_okey_session_open_rack_melds: " + message)
	return value

func _setup_session():
	var session = SESSION.new()
	session.bots_enabled = false
	session.configure_game(RuleConfig.new(), 1701, 4)
	session._bind_controller_signals()
	session._start_round()
	session.get_controller().state.current_player_index = 0
	session.get_controller().state.phase = GameState.Phase.TURN_PLAY
	session._sync_state()
	return session

func _test_open_rack_melds_valid() -> bool:
	var session = _setup_session()
	var controller = session.get_controller()
	var state: GameState = controller.state

	# Craft hand with 102 points:
	# Red 8, 9, 10 = 27
	# Blue 13, Black 13, Yellow 13 = 39
	# Blue 11, 12, 13 = 36
	var tiles: Array = [
		Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 9, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.RED, 10, Tile.Kind.NORMAL, 3),
		Tile.new(Tile.TileColor.BLUE, 13, Tile.Kind.NORMAL, 4),
		Tile.new(Tile.TileColor.BLACK, 13, Tile.Kind.NORMAL, 5),
		Tile.new(Tile.TileColor.YELLOW, 13, Tile.Kind.NORMAL, 6),
		Tile.new(Tile.TileColor.BLUE, 11, Tile.Kind.NORMAL, 7),
		Tile.new(Tile.TileColor.BLUE, 12, Tile.Kind.NORMAL, 8),
		Tile.new(Tile.TileColor.BLUE, 13, Tile.Kind.NORMAL, 9),
		# Extra random tile
		Tile.new(Tile.TileColor.BLACK, 1, Tile.Kind.NORMAL, 10),
	]
	state.players[0].hand = tiles

	# Arrange rack with spaces between melds
	var rack: Array[int] = []
	for i in range(30):
		rack.append(-1)
	rack[0] = 1
	rack[1] = 2
	rack[2] = 3
	# gap at 3
	rack[4] = 4
	rack[5] = 5
	rack[6] = 6
	# gap at 7
	rack[8] = 7
	rack[9] = 8
	rack[10] = 9
	# gap at 11
	rack[12] = 10
	session._slots.rack_slots.assign(rack)
	session._slots.clear_draft_slots()
	session._emit_changed()

	var ok: bool = true
	var res: Dictionary = session.request_open_rack_melds()
	ok = _check(bool(res.get("ok", false)), "request_open_rack_melds should succeed with 102 points") and ok
	var current_state: GameState = session.get_controller().state
	ok = _check(current_state.players[0].has_opened, "player 0 should be marked opened") and ok
	ok = _check(current_state.table_melds.size() == 3, "table should receive 3 melds") and ok

	session.free()
	return ok

func _test_open_rack_melds_below_threshold() -> bool:
	var session = _setup_session()
	var controller = session.get_controller()
	var state: GameState = controller.state

	# Craft hand with only 18 points (below 101):
	var tiles: Array = [
		Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 2, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.RED, 3, Tile.Kind.NORMAL, 3),
		Tile.new(Tile.TileColor.BLUE, 1, Tile.Kind.NORMAL, 4),
		Tile.new(Tile.TileColor.BLUE, 2, Tile.Kind.NORMAL, 5),
		Tile.new(Tile.TileColor.BLUE, 3, Tile.Kind.NORMAL, 6),
	]
	state.players[0].hand = tiles

	var rack: Array[int] = []
	for i in range(30):
		rack.append(-1)
	rack[0] = 1
	rack[1] = 2
	rack[2] = 3
	# gap at 3
	rack[4] = 4
	rack[5] = 5
	rack[6] = 6
	session._slots.rack_slots.assign(rack)
	session._slots.clear_draft_slots()
	session._emit_changed()

	var initial_rack: Array = session.get_rack_slots().duplicate()

	var ok: bool = true
	var res: Dictionary = session.request_open_rack_melds()
	ok = _check(not bool(res.get("ok", false)), "request_open_rack_melds should fail below threshold") and ok
	ok = _check(not state.players[0].has_opened, "player 0 should not be marked opened") and ok
	ok = _check(session.get_rack_slots() == initial_rack, "rack slots should remain unchanged afterwards") and ok

	session.free()
	return ok
