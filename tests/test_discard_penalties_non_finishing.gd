extends RefCounted


func run() -> bool:
	return _test_non_finishing_discard_joker_penalty() and _test_non_finishing_discard_playable_penalty()


func _test_non_finishing_discard_joker_penalty() -> bool:
	var state := GameState.new()
	state.rule_config = RuleConfig.new()
	state.rule_config.penalty_discard_joker = true
	state.rule_config.penalty_discard_playable_tile = false
	state.rule_config.penalty_value = 101
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 900))
	state.phase = GameState.Phase.TURN_DISCARD
	state.current_player_index = 0
	state.players = [PlayerState.new()]
	state.players[0].has_opened = true
	state.players[0].hand = [
		Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 1), # real okey
		Tile.new(Tile.TileColor.BLUE, 1, Tile.Kind.NORMAL, 2),
	]

	var reducer := Reducer.new()
	var next_state = reducer.apply_action(state, 0, Action.new(Action.ActionType.DISCARD, {"tile_id": 1}))
	if int(next_state.players[0].deal_penalty_points) != 101:
		push_error("Expected +101 non-finishing joker discard penalty")
		return false
	return true


func _test_non_finishing_discard_playable_penalty() -> bool:
	var state := GameState.new()
	state.rule_config = RuleConfig.new()
	state.rule_config.penalty_discard_joker = false
	state.rule_config.penalty_discard_playable_tile = true
	state.rule_config.penalty_value = 101
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.YELLOW, 9, Tile.Kind.NORMAL, 901))
	state.phase = GameState.Phase.TURN_DISCARD
	state.current_player_index = 0
	state.players = [PlayerState.new()]
	state.players[0].has_opened = true
	state.players[0].hand = [
		Tile.new(Tile.TileColor.RED, 4, Tile.Kind.NORMAL, 10),
		Tile.new(Tile.TileColor.BLUE, 1, Tile.Kind.NORMAL, 11),
	]
	var t1 = Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 20)
	var t2 = Tile.new(Tile.TileColor.RED, 2, Tile.Kind.NORMAL, 21)
	var t3 = Tile.new(Tile.TileColor.RED, 3, Tile.Kind.NORMAL, 22)
	state.table_melds = [Meld.new(Meld.Kind.RUN, [20, 21, 22], [t1, t2, t3])]

	var reducer := Reducer.new()
	var next_state = reducer.apply_action(state, 0, Action.new(Action.ActionType.DISCARD, {"tile_id": 10}))
	if int(next_state.players[0].deal_penalty_points) != 101:
		push_error("Expected +101 non-finishing playable discard penalty")
		return false
	return true
