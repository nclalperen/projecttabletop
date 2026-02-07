extends RefCounted

func run() -> bool:
	return _test_heuristic_prefers_discard_when_deck_low()

func _test_heuristic_prefers_discard_when_deck_low() -> bool:
	var cfg = RuleConfig.new()
	var state = GameState.new()
	state.rule_config = cfg
	state.phase = state.Phase.TURN_DRAW
	state.current_player_index = 0
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 500))
	# Low deck forces prefer take discard
	state.deck = [Tile.new(Tile.TileColor.BLUE, 1, Tile.Kind.NORMAL, 100)]

	var p0 = PlayerState.new()
	p0.has_opened = true
	p0.hand = [
		Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 2),
	]
	state.players = [p0]
	state.discard_pile = [Tile.new(Tile.TileColor.RED, 9, Tile.Kind.NORMAL, 999)]

	var bot = BotHeuristic.new()
	var action = bot.choose_action(state, 0)
	if action == null or action.type != Action.ActionType.TAKE_DISCARD:
		push_error("Heuristic bot should take discard when deck is low and discard is usable")
		return false
	return true
