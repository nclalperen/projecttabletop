extends RefCounted


func run() -> bool:
	return _test_unopened_discard_take_blocked() and _test_unopened_discard_take_allowed()

func _test_unopened_discard_take_blocked() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 7777, 4)

	# Starter discards to enter TURN_DRAW
	var starter = state.current_player_index
	var starter_tile = state.players[starter].hand[0]
	state.discard_pile.append(starter_tile)
	state.players[starter].hand.remove_at(0)
	state.current_player_index = (starter + 1) % state.players.size()
	state.phase = state.Phase.TURN_DRAW

	var player = state.current_player_index
	# Make hand unable to open by 101 or 5 pairs (low scattered tiles)
	state.players[player].hand = [
		Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.BLUE, 3, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.BLACK, 5, Tile.Kind.NORMAL, 3),
		Tile.new(Tile.TileColor.YELLOW, 7, Tile.Kind.NORMAL, 4),
		Tile.new(Tile.TileColor.RED, 9, Tile.Kind.NORMAL, 5),
		Tile.new(Tile.TileColor.BLUE, 11, Tile.Kind.NORMAL, 6),
		Tile.new(Tile.TileColor.BLACK, 13, Tile.Kind.NORMAL, 7),
	]
	# Fill to 21 tiles with non-pairing values
	var id = 8
	while state.players[player].hand.size() < cfg.tiles_per_player:
		state.players[player].hand.append(Tile.new(Tile.TileColor.RED, (id % 13) + 1, Tile.Kind.NORMAL, id))
		id += 1

	var validator = Validator.new()
	var res = validator.validate_action(state, player, Action.new(Action.ActionType.TAKE_DISCARD, {}))
	if res.ok:
		push_error("Expected discard take to be blocked for unopened hand")
		return false
	return true

func _test_unopened_discard_take_allowed() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 8888, 4)

	# Starter discards to enter TURN_DRAW
	var starter = state.current_player_index
	var starter_tile = state.players[starter].hand[0]
	state.discard_pile.append(starter_tile)
	state.players[starter].hand.remove_at(0)
	state.current_player_index = (starter + 1) % state.players.size()
	state.phase = state.Phase.TURN_DRAW

	var player = state.current_player_index
	# Prepare a hand that can open to 101 with the discard
	state.players[player].hand = [
		Tile.new(Tile.TileColor.RED, 10, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 11, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.RED, 12, Tile.Kind.NORMAL, 3),
		Tile.new(Tile.TileColor.BLUE, 10, Tile.Kind.NORMAL, 4),
		Tile.new(Tile.TileColor.BLACK, 10, Tile.Kind.NORMAL, 5),
		Tile.new(Tile.TileColor.YELLOW, 10, Tile.Kind.NORMAL, 6),
		Tile.new(Tile.TileColor.BLUE, 11, Tile.Kind.NORMAL, 7),
		Tile.new(Tile.TileColor.BLACK, 11, Tile.Kind.NORMAL, 8),
		Tile.new(Tile.TileColor.YELLOW, 11, Tile.Kind.NORMAL, 9),
	]
	# Add filler tiles
	var id = 10
	while state.players[player].hand.size() < cfg.tiles_per_player:
		state.players[player].hand.append(Tile.new(Tile.TileColor.BLUE, (id % 13) + 1, Tile.Kind.NORMAL, id))
		id += 1

	# Discard is red 13 to complete 10-11-12-13 run (46 points)
	state.discard_pile = [Tile.new(Tile.TileColor.RED, 13, Tile.Kind.NORMAL, 999)]

	var validator = Validator.new()
	var res = validator.validate_action(state, player, Action.new(Action.ActionType.TAKE_DISCARD, {}))
	if not res.ok:
		push_error("Expected discard take to be allowed for unopened hand")
		return false
	return true
