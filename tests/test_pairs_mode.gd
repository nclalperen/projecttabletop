extends RefCounted

func run() -> bool:
	return _test_pairs_lock() and _test_pairs_can_add_to_table_melds()

func _test_pairs_lock() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 1201, 4)
	state.phase = state.Phase.TURN_PLAY
	var player = state.current_player_index
	state.players[player].has_opened = true
	state.players[player].opened_by_pairs = true
	state.players[player].opened_mode = "pairs"

	state.players[player].hand = [
		Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 2, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.RED, 3, Tile.Kind.NORMAL, 3),
	]

	var melds = [
		{"kind": Meld.Kind.RUN, "tile_ids": [1, 2, 3]}
	]
	var action = Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds, "open_by_pairs": false})
	var validator = Validator.new()
	var res = validator.validate_action(state, player, action)
	if res.ok:
		push_error("Pairs opener should not be allowed to create new melds")
		return false
	return true

func _test_pairs_can_add_to_table_melds() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 1202, 4)
	state.phase = state.Phase.TURN_PLAY
	var player = state.current_player_index
	state.players[player].has_opened = true
	state.players[player].opened_by_pairs = true
	state.players[player].opened_mode = "pairs"

	# Create a table run BLUE 1-2-3 and ensure a pairs-opener can still lay off a single tile.
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 999))
	var t1 = Tile.new(Tile.TileColor.BLUE, 1, Tile.Kind.NORMAL, 100)
	var t2 = Tile.new(Tile.TileColor.BLUE, 2, Tile.Kind.NORMAL, 101)
	var t3 = Tile.new(Tile.TileColor.BLUE, 3, Tile.Kind.NORMAL, 102)
	state.table_melds = [Meld.new(Meld.Kind.RUN, [100, 101, 102], [t1, t2, t3])]

	state.players[player].hand = [
		Tile.new(Tile.TileColor.BLUE, 4, Tile.Kind.NORMAL, 10),
	]

	var action = Action.new(Action.ActionType.ADD_TO_MELD, {"target_meld_index": 0, "tile_ids": [10]})
	var validator = Validator.new()
	var res = validator.validate_action(state, player, action)
	if not res.ok:
		push_error("Pairs opener should be allowed to add to table melds after opening")
		return false
	return true

