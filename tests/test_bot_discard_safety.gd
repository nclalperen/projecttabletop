extends RefCounted

func run() -> bool:
	return _test_bot_discard_avoids_joker()

func _test_bot_discard_avoids_joker() -> bool:
	var cfg = RuleConfig.new()
	var state = GameState.new()
	state.rule_config = cfg
	state.phase = state.Phase.TURN_DISCARD
	state.current_player_index = 0
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 500))
	state.table_melds = []

	var p0 = PlayerState.new()
	var safe = Tile.new(Tile.TileColor.BLUE, 9, Tile.Kind.NORMAL, 1)
	var joker = Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 2) # real okey for indicator 5
	p0.hand = [safe, joker]
	state.players = [p0]

	var bot_random = BotRandom.new(123)
	var action_r = bot_random.choose_action(state, 0)
	if action_r == null or action_r.type != Action.ActionType.DISCARD:
		push_error("BotRandom should choose discard")
		return false
	if int(action_r.payload.get("tile_id", -1)) == joker.unique_id:
		push_error("BotRandom should avoid joker discard when safe exists")
		return false

	var bot_h = BotHeuristic.new()
	var action_h = bot_h.choose_action(state, 0)
	if action_h == null or action_h.type != Action.ActionType.DISCARD:
		push_error("BotHeuristic should choose discard")
		return false
	if int(action_h.payload.get("tile_id", -1)) == joker.unique_id:
		push_error("BotHeuristic should avoid joker discard when safe exists")
		return false

	return true
