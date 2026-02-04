extends RefCounted

func run() -> bool:
	return _test_joker_discard_penalty() and _test_extendable_discard_penalty()

func _test_joker_discard_penalty() -> bool:
	var cfg = RuleConfig.new()
	cfg.penalty_discard_joker = true
	cfg.penalty_value = 101

	var state = GameState.new()
	state.rule_config = cfg
	state.phase = state.Phase.TURN_DISCARD
	state.current_player_index = 0
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 500))

	var p0 = PlayerState.new()
	var joker = Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 1)
	p0.hand = [joker]
	state.players = [p0]

	var reducer = Reducer.new()
	var action = Action.new(Action.ActionType.DISCARD, {"tile_id": 1})
	state = reducer.apply_action(state, 0, action)
	if state.players[0].score_round != 101:
		push_error("Expected joker discard penalty")
		return false
	return true

func _test_extendable_discard_penalty() -> bool:
	var cfg = RuleConfig.new()
	cfg.penalty_discard_extendable_tile = true
	cfg.penalty_value = 101

	var state = GameState.new()
	state.rule_config = cfg
	state.phase = state.Phase.TURN_DISCARD
	state.current_player_index = 0
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 900))

	var p0 = PlayerState.new()
	var tile = Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 2)
	p0.hand = [tile]
	state.players = [p0]

	var t1 = Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 10)
	var t2 = Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 11)
	var t3 = Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 12)
	state.table_melds = [Meld.new(Meld.Kind.RUN, [10, 11, 12], [t1, t2, t3])]

	var reducer = Reducer.new()
	var action = Action.new(Action.ActionType.DISCARD, {"tile_id": 2})
	state = reducer.apply_action(state, 0, action)
	if state.players[0].score_round != 101:
		push_error("Expected extendable discard penalty")
		return false
	return true
