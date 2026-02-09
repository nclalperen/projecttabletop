extends RefCounted


func run() -> bool:
	return _test_heuristic_attempts_finish_when_possible() \
		and _test_random_attempts_finish_when_possible() \
		and _test_random_can_take_discard_unopened_if_usable() \
		and _test_random_plays_required_open_when_unopened()


func _test_heuristic_attempts_finish_when_possible() -> bool:
	var state = GameState.new()
	state.rule_config = RuleConfig.new()
	state.phase = state.Phase.TURN_PLAY
	state.current_player_index = 0
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 3, Tile.Kind.NORMAL, 900))
	state.table_melds = []
	state.deck = []
	state.discard_pile = []

	var p0 = PlayerState.new()
	p0.has_opened = true
	p0.opened_by_pairs = false
	p0.hand = [
		Tile.new(Tile.TileColor.BLUE, 5, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.BLUE, 6, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.BLUE, 7, Tile.Kind.NORMAL, 3),
		Tile.new(Tile.TileColor.YELLOW, 9, Tile.Kind.NORMAL, 4),
	]
	state.players = [p0]

	var bot = BotHeuristic.new()
	var action = bot.choose_action(state, 0)
	if action == null:
		push_error("Heuristic bot returned null with finishable hand")
		return false
	if int(action.type) != int(Action.ActionType.FINISH):
		push_error("Expected FINISH action, got %s" % str(action.type))
		return false
	return true


func _test_random_can_take_discard_unopened_if_usable() -> bool:
	var state = GameState.new()
	state.rule_config = RuleConfig.new()
	state.phase = state.Phase.TURN_DRAW
	state.current_player_index = 0
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 700))
	state.deck = [Tile.new(Tile.TileColor.BLACK, 1, Tile.Kind.NORMAL, 88)]
	state.discard_pile = [Tile.new(Tile.TileColor.BLUE, 5, Tile.Kind.NORMAL, 99)]
	state.table_melds = []

	var p0 = PlayerState.new()
	p0.has_opened = false
	# Discard can be used to complete the 5th pair opening (>=5 pairs).
	p0.hand = [
		Tile.new(Tile.TileColor.BLUE, 5, Tile.Kind.NORMAL, 100),
		Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 101),
		Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 102),
		Tile.new(Tile.TileColor.BLUE, 2, Tile.Kind.NORMAL, 103),
		Tile.new(Tile.TileColor.BLUE, 2, Tile.Kind.NORMAL, 104),
		Tile.new(Tile.TileColor.BLACK, 3, Tile.Kind.NORMAL, 105),
		Tile.new(Tile.TileColor.BLACK, 3, Tile.Kind.NORMAL, 106),
		Tile.new(Tile.TileColor.YELLOW, 4, Tile.Kind.NORMAL, 107),
		Tile.new(Tile.TileColor.YELLOW, 4, Tile.Kind.NORMAL, 108),
	]
	state.players = [p0]

	var bot = BotRandom.new(12345)
	var action = bot.choose_action(state, 0)
	if action == null:
		push_error("Random bot returned null in TURN_DRAW")
		return false
	# Candidate set should include TAKE_DISCARD for unopened players when usable.
	# RNG may still choose DRAW, so we only enforce that TAKE_DISCARD validates and is available path.
	var validator = Validator.new()
	var take_res: Dictionary = validator.validate_action(state, 0, Action.new(Action.ActionType.TAKE_DISCARD, {}))
	if not bool(take_res.get("ok", false)):
		push_error("Expected TAKE_DISCARD to be legal for unopened usable case")
		return false
	return true


func _test_random_attempts_finish_when_possible() -> bool:
	var state = GameState.new()
	state.rule_config = RuleConfig.new()
	state.phase = state.Phase.TURN_PLAY
	state.current_player_index = 0
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 3, Tile.Kind.NORMAL, 901))
	state.table_melds = []
	state.deck = []
	state.discard_pile = []

	var p0 = PlayerState.new()
	p0.has_opened = true
	p0.opened_by_pairs = false
	p0.hand = [
		Tile.new(Tile.TileColor.BLUE, 5, Tile.Kind.NORMAL, 11),
		Tile.new(Tile.TileColor.BLUE, 6, Tile.Kind.NORMAL, 12),
		Tile.new(Tile.TileColor.BLUE, 7, Tile.Kind.NORMAL, 13),
		Tile.new(Tile.TileColor.YELLOW, 9, Tile.Kind.NORMAL, 14),
	]
	state.players = [p0]

	var bot = BotRandom.new(98765)
	var action = bot.choose_action(state, 0)
	if action == null:
		push_error("Random bot returned null with finishable hand")
		return false
	if int(action.type) != int(Action.ActionType.FINISH):
		push_error("Expected Random bot FINISH action, got %s" % str(action.type))
		return false
	return true

func _test_random_plays_required_open_when_unopened() -> bool:
	var state = GameState.new()
	state.rule_config = RuleConfig.new()
	state.phase = state.Phase.TURN_PLAY
	state.current_player_index = 0
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 4, Tile.Kind.NORMAL, 800))
	state.table_melds = []
	state.deck = []
	state.discard_pile = []

	var p0 = PlayerState.new()
	p0.has_opened = false
	p0.opened_by_pairs = false
	# Required tile comes from a prior TAKE_DISCARD; opening requires >=101 and must include it.
	var req = Tile.new(Tile.TileColor.RED, 13, Tile.Kind.NORMAL, 901)
	p0.hand = [
		req,
		Tile.new(Tile.TileColor.BLUE, 13, Tile.Kind.NORMAL, 902),
		Tile.new(Tile.TileColor.BLACK, 13, Tile.Kind.NORMAL, 903),
		Tile.new(Tile.TileColor.YELLOW, 13, Tile.Kind.NORMAL, 904),
		Tile.new(Tile.TileColor.RED, 10, Tile.Kind.NORMAL, 905),
		Tile.new(Tile.TileColor.RED, 11, Tile.Kind.NORMAL, 906),
		Tile.new(Tile.TileColor.RED, 12, Tile.Kind.NORMAL, 907),
		Tile.new(Tile.TileColor.BLUE, 5, Tile.Kind.NORMAL, 908),
		Tile.new(Tile.TileColor.BLUE, 6, Tile.Kind.NORMAL, 909),
		Tile.new(Tile.TileColor.BLUE, 7, Tile.Kind.NORMAL, 910),
	]
	state.players = [p0]
	state.turn_required_use_tile_id = int(req.unique_id)

	var bot = BotRandom.new(4242)
	var action = bot.choose_action(state, 0)
	if action == null:
		push_error("Random bot returned null in required unopened TURN_PLAY")
		return false
	if int(action.type) != int(Action.ActionType.OPEN_MELDS):
		push_error("Expected OPEN_MELDS for required unopened action, got %s" % str(action.type))
		return false
	var validator = Validator.new()
	var res: Dictionary = validator.validate_action(state, 0, action)
	if not bool(res.get("ok", false)):
		push_error("Random bot produced invalid required OPEN_MELDS: %s" % str(res.get("reason", "")))
		return false
	return true
