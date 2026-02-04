extends RefCounted

func run() -> bool:
	return _test_heuristic_bot_action() and _test_bot_heuristic_discard_choice()

func _test_heuristic_bot_action() -> bool:
	var controller = LocalGameController.new()
	var cfg = RuleConfig.new()
	controller.start_new_round(cfg, 1801, 4)

	var bot = BotHeuristic.new()
	var player = controller.state.current_player_index
	var action = bot.choose_action(controller.state, player)
	if action == null:
		push_error("Heuristic bot returned null action")
		return false
	return true

func _test_bot_heuristic_discard_choice() -> bool:
	var cfg = RuleConfig.new()
	var state = GameState.new()
	state.rule_config = cfg
	state.phase = state.Phase.TURN_DISCARD
	state.current_player_index = 0
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 500))
	state.table_melds = []

	var p0 = PlayerState.new()
	var safe = Tile.new(Tile.TileColor.BLUE, 9, Tile.Kind.NORMAL, 1)
	var joker = Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 2)
	p0.hand = [safe, joker]
	state.players = [p0]

	var bot = BotHeuristic.new()
	var action = bot.choose_action(state, 0)
	if action == null or action.type != Action.ActionType.DISCARD:
		push_error("Heuristic bot should discard")
		return false
	if int(action.payload.get("tile_id", -1)) == joker.unique_id:
		push_error("Heuristic bot should avoid joker discard when safe exists")
		return false
	return true
