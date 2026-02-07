extends RefCounted


func run() -> bool:
	return _test_finish_and_scoring()

func _test_finish_and_scoring() -> bool:
	var state = GameState.new()
	state.rule_config = RuleConfig.new()
	state.phase = GameState.Phase.TURN_PLAY
	state.current_player_index = 0
	state.table_melds = []
	state.discard_pile = []
	state.deck = []
	state.turn_required_use_tile_id = -1
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 999))

	var p0 = PlayerState.new()
	p0.has_opened = true
	p0.hand = [
		Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 2, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.RED, 3, Tile.Kind.NORMAL, 3),
		Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 4),
		Tile.new(Tile.TileColor.BLUE, 7, Tile.Kind.NORMAL, 5),
		Tile.new(Tile.TileColor.BLACK, 7, Tile.Kind.NORMAL, 6),
		Tile.new(Tile.TileColor.YELLOW, 9, Tile.Kind.NORMAL, 7),
	]

	var p1 = PlayerState.new()
	p1.has_opened = false
	p1.hand = [
		Tile.new(Tile.TileColor.BLUE, 10, Tile.Kind.NORMAL, 20),
		Tile.new(Tile.TileColor.YELLOW, 12, Tile.Kind.NORMAL, 21),
	]

	state.players = [p0, p1]

	var melds = [
		{"kind": Meld.Kind.RUN, "tile_ids": [1, 2, 3]},
		{"kind": Meld.Kind.SET, "tile_ids": [4, 5, 6]},
	]
	var action = Action.new(Action.ActionType.FINISH, {
		"melds": melds,
		"final_discard_tile_id": 7,
	})

	var validator = Validator.new()
	var res = validator.validate_action(state, 0, action)
	if not res.ok:
		push_error("Finish blocked: %s" % res.code)
		return false

	var reducer = Reducer.new()
	state = reducer.apply_action(state, 0, action)

	if state.phase != GameState.Phase.ROUND_END:
		push_error("Expected ROUND_END after finish")
		return false

	if state.players[0].score_round != 0 or state.players[0].score_total != 0:
		push_error("Winner score incorrect")
		return false

	if state.players[1].score_round != 202 or state.players[1].score_total != 202:
		push_error("Non-opened penalty incorrect")
		return false

	return true




