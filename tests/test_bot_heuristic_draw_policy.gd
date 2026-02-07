extends RefCounted


func run() -> bool:
	return _test_unopened_bot_prefers_draw_over_discard_take()


func _test_unopened_bot_prefers_draw_over_discard_take() -> bool:
	var cfg = RuleConfig.new()
	var state = GameState.new()
	state.rule_config = cfg
	state.phase = state.Phase.TURN_DRAW
	state.current_player_index = 0
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 500))
	state.deck = [Tile.new(Tile.TileColor.BLUE, 1, Tile.Kind.NORMAL, 700)]
	state.discard_pile = [Tile.new(Tile.TileColor.RED, 9, Tile.Kind.NORMAL, 999)]

	var p0 = PlayerState.new()
	p0.has_opened = false
	p0.hand = [
		Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.BLUE, 3, Tile.Kind.NORMAL, 3),
	]
	state.players = [p0]

	var bot = BotHeuristic.new()
	var action = bot.choose_action(state, 0)
	if action == null:
		push_error("Heuristic bot returned null in TURN_DRAW")
		return false
	if int(action.type) != int(Action.ActionType.DRAW_FROM_DECK):
		push_error("Unopened bot should draw from deck, got action=%s" % str(action.type))
		return false
	return true

