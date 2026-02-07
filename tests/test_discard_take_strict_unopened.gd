extends RefCounted

func run() -> bool:
	return _test_unopened_discard_take_blocked() and _test_unopened_discard_take_allowed()

func _test_unopened_discard_take_blocked() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 7777, 4)

	# Enter TURN_DRAW for a non-starter player.
	var starter = state.current_player_index
	var starter_tile = state.players[starter].hand[0]
	state.discard_pile.append(starter_tile)
	state.players[starter].hand.remove_at(0)
	state.current_player_index = (starter + 1) % state.players.size()
	state.phase = state.Phase.TURN_DRAW

	var player = state.current_player_index
	state.players[player].has_opened = false

	# Hand: 21 unique low-value tiles; even with discard, total sum < 101 and no pairs exist.
	var hand: Array = []
	var id := 1
	for n in range(1, 6): # 1..5 across 4 colors = 20 tiles (sum 60)
		hand.append(Tile.new(Tile.TileColor.RED, n, Tile.Kind.NORMAL, id)); id += 1
		hand.append(Tile.new(Tile.TileColor.BLUE, n, Tile.Kind.NORMAL, id)); id += 1
		hand.append(Tile.new(Tile.TileColor.BLACK, n, Tile.Kind.NORMAL, id)); id += 1
		hand.append(Tile.new(Tile.TileColor.YELLOW, n, Tile.Kind.NORMAL, id)); id += 1
	hand.append(Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, id)); id += 1 # total sum 66
	state.players[player].hand = hand

	# Discard is a unique low tile; still cannot reach 101, still no 5 pairs.
	state.discard_pile = [Tile.new(Tile.TileColor.BLUE, 7, Tile.Kind.NORMAL, 999)]

	var validator = Validator.new()
	var res = validator.validate_action(state, player, Action.new(Action.ActionType.TAKE_DISCARD, {}))
	if res.ok:
		push_error("Expected discard take to be blocked for unopened hand that cannot open")
		return false
	return true

func _test_unopened_discard_take_allowed() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 8888, 4)

	# Enter TURN_DRAW for a non-starter player.
	var starter = state.current_player_index
	var starter_tile = state.players[starter].hand[0]
	state.discard_pile.append(starter_tile)
	state.players[starter].hand.remove_at(0)
	state.current_player_index = (starter + 1) % state.players.size()
	state.phase = state.Phase.TURN_DRAW

	var player = state.current_player_index
	state.players[player].has_opened = false

	# Prepare a hand that can open to >=101 with the discard.
	# Sets: 10*3=30, 11*3=33. Run: 10-11-12-13 = 46. Total = 109.
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
	# Add filler tiles to reach 21.
	var fid := 10
	while state.players[player].hand.size() < cfg.tiles_per_player:
		state.players[player].hand.append(Tile.new(Tile.TileColor.BLUE, (fid % 13) + 1, Tile.Kind.NORMAL, fid))
		fid += 1

	# Discard is red 13 to complete the 10-11-12-13 run.
	state.discard_pile = [Tile.new(Tile.TileColor.RED, 13, Tile.Kind.NORMAL, 999)]

	var validator = Validator.new()
	var res = validator.validate_action(state, player, Action.new(Action.ActionType.TAKE_DISCARD, {}))
	if not res.ok:
		push_error("Expected discard take to be allowed for unopened hand that can open with it")
		return false
	return true

