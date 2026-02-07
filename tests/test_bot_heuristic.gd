extends RefCounted

func run() -> bool:
	return _test_heuristic_bot_action() and _test_bot_heuristic_discard_choice() and _test_heuristic_uses_taken_discard_on_turn_play() and _test_heuristic_builds_open_meld_for_required_tile()

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

func _test_heuristic_uses_taken_discard_on_turn_play() -> bool:
	var cfg = RuleConfig.new()
	var state = GameState.new()
	state.rule_config = cfg
	state.phase = state.Phase.TURN_PLAY
	state.current_player_index = 0
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 4, Tile.Kind.NORMAL, 500))

	var p0 = PlayerState.new()
	p0.has_opened = true
	var required = Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 101)
	p0.hand = [required]
	state.players = [p0]
	state.turn_required_use_tile_id = required.unique_id

	var meld_tiles = [
		Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 201),
		Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 202),
		Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 203),
	]
	var meld_ids: Array = []
	for t in meld_tiles:
		meld_ids.append(t.unique_id)
	state.table_melds = [Meld.new(Meld.Kind.RUN, meld_ids, meld_tiles)]

	var bot = BotHeuristic.new()
	var action = bot.choose_action(state, 0)
	if action == null:
		push_error("Heuristic bot returned null while required tile must be used")
		return false
	if int(action.type) != int(Action.ActionType.ADD_TO_MELD) and int(action.type) != int(Action.ActionType.OPEN_MELDS):
		push_error("Heuristic bot should use required taken discard, got action=%s" % str(action.type))
		return false
	return true

func _test_heuristic_builds_open_meld_for_required_tile() -> bool:
	var cfg = RuleConfig.new()
	var state = GameState.new()
	state.rule_config = cfg
	state.phase = state.Phase.TURN_PLAY
	state.current_player_index = 0
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 4, Tile.Kind.NORMAL, 900))
	state.table_melds = []

	var p0 = PlayerState.new()
	p0.has_opened = true
	p0.opened_by_pairs = false
	var req = Tile.new(Tile.TileColor.BLUE, 5, Tile.Kind.NORMAL, 11)
	var a = Tile.new(Tile.TileColor.BLUE, 6, Tile.Kind.NORMAL, 12)
	var b = Tile.new(Tile.TileColor.BLUE, 7, Tile.Kind.NORMAL, 13)
	p0.hand = [req, a, b]
	state.players = [p0]
	state.turn_required_use_tile_id = req.unique_id

	var bot = BotHeuristic.new()
	var action = bot.choose_action(state, 0)
	if action == null:
		push_error("Heuristic bot returned null when required tile can form a run")
		return false
	if int(action.type) != int(Action.ActionType.OPEN_MELDS):
		push_error("Heuristic bot should OPEN_MELDS to consume required tile, got action=%s" % str(action.type))
		return false
	var melds: Array = action.payload.get("melds", [])
	if melds.is_empty():
		push_error("OPEN_MELDS payload is empty")
		return false
	var ids: Array = melds[0].get("tile_ids", [])
	if not ids.has(req.unique_id):
		push_error("Required tile not included in bot OPEN_MELDS payload")
		return false
	return true
