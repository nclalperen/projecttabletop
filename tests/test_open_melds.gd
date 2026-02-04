extends RefCounted


func run() -> bool:
	return _test_open_melds_valid() and _test_open_melds_invalid()

func _test_open_melds_valid() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 777, 4)

	# Move to TURN_PLAY for current player and craft a 101+ open using their hand
	state.phase = state.Phase.TURN_PLAY
	var player = state.current_player_index

	# Force a known hand that sums to 102 points in melds
	state.players[player].hand = [
		Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 9, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.RED, 10, Tile.Kind.NORMAL, 3),
		Tile.new(Tile.TileColor.BLUE, 13, Tile.Kind.NORMAL, 4),
		Tile.new(Tile.TileColor.BLACK, 13, Tile.Kind.NORMAL, 5),
		Tile.new(Tile.TileColor.YELLOW, 13, Tile.Kind.NORMAL, 6),
		Tile.new(Tile.TileColor.BLUE, 11, Tile.Kind.NORMAL, 7),
		Tile.new(Tile.TileColor.BLUE, 12, Tile.Kind.NORMAL, 8),
		Tile.new(Tile.TileColor.BLUE, 13, Tile.Kind.NORMAL, 9),
	]

	var melds = [
		{"kind": Meld.Kind.RUN, "tile_ids": [1, 2, 3]}, # 8+9+10=27
		{"kind": Meld.Kind.SET, "tile_ids": [4, 5, 6]}, # 13*3=39
		{"kind": Meld.Kind.RUN, "tile_ids": [7, 8, 9]}, # 11+12+13=36
	]

	var action = Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds})
	var validator = Validator.new()
	var res = validator.validate_action(state, player, action)
	if not res.ok:
		push_error("Open melds blocked: %s" % res.code)
		return false

	var reducer = Reducer.new()
	state = reducer.apply_action(state, player, action)
	if not state.players[player].has_opened:
		push_error("Player should be marked opened")
		return false

	return true

func _test_open_melds_invalid() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 778, 4)
	state.phase = state.Phase.TURN_PLAY
	var player = state.current_player_index

	state.players[player].hand = [
		Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 2, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.RED, 3, Tile.Kind.NORMAL, 3),
	]

	var melds = [
		{"kind": Meld.Kind.RUN, "tile_ids": [1, 2, 3]},
	]
	var action = Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds})
	var validator = Validator.new()
	var res = validator.validate_action(state, player, action)
	if res.ok:
		push_error("Open melds should fail below 101 points")
		return false

	return true




