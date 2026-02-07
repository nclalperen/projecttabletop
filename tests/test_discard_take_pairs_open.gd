extends RefCounted

func run() -> bool:
	return _test_unopened_discard_take_allows_pairs_open()

func _test_unopened_discard_take_allows_pairs_open() -> bool:
	var cfg = RuleConfig.new()
	cfg.allow_open_by_five_pairs = true
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 9101, 4)

	# Starter discard to enter TURN_DRAW
	var starter = state.current_player_index
	var starter_tile = state.players[starter].hand[0]
	state.discard_pile.append(starter_tile)
	state.players[starter].hand.remove_at(0)
	state.current_player_index = (starter + 1) % state.players.size()
	state.phase = state.Phase.TURN_DRAW

	var player = state.current_player_index
	state.players[player].hand = [
		Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.BLUE, 2, Tile.Kind.NORMAL, 3),
		Tile.new(Tile.TileColor.BLUE, 2, Tile.Kind.NORMAL, 4),
		Tile.new(Tile.TileColor.BLACK, 3, Tile.Kind.NORMAL, 5),
		Tile.new(Tile.TileColor.BLACK, 3, Tile.Kind.NORMAL, 6),
		Tile.new(Tile.TileColor.YELLOW, 4, Tile.Kind.NORMAL, 7),
		Tile.new(Tile.TileColor.YELLOW, 4, Tile.Kind.NORMAL, 8),
		Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 9),
	]
	# Fill to 21 with junk
	var id = 10
	while state.players[player].hand.size() < cfg.tiles_per_player:
		state.players[player].hand.append(Tile.new(Tile.TileColor.BLUE, (id % 13) + 1, Tile.Kind.NORMAL, id))
		id += 1

	# Discard is a matching RED 5 to complete 5th pair
	state.discard_pile = [Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 999)]

	var validator = Validator.new()
	var res = validator.validate_action(state, player, Action.new(Action.ActionType.TAKE_DISCARD, {}))
	if not res.ok:
		push_error("Expected discard take to be allowed for 5-pairs opening")
		return false
	return true
