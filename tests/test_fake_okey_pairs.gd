extends RefCounted

func run() -> bool:
	return _test_open_by_pairs_accepts_fake_with_represented_okey() and _test_open_by_pairs_rejects_fake_with_wrong_tile()

func _make_state() -> GameState:
	var cfg := RuleConfig.new()
	cfg.allow_open_by_five_pairs = true
	var setup := GameSetup.new()
	var state := setup.new_round(cfg, 9501, 4)
	state.phase = GameState.Phase.TURN_PLAY
	state.current_player_index = 0
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 9999)) # okey RED-6
	state.players[0].has_opened = false
	state.players[0].opened_by_pairs = false
	return state

func _test_open_by_pairs_accepts_fake_with_represented_okey() -> bool:
	var state := _make_state()
	state.players[0].hand = [
		Tile.new(Tile.TileColor.RED, 0, Tile.Kind.FAKE_OKEY, 1),
		Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.BLUE, 1, Tile.Kind.NORMAL, 3),
		Tile.new(Tile.TileColor.BLUE, 1, Tile.Kind.NORMAL, 4),
		Tile.new(Tile.TileColor.BLACK, 2, Tile.Kind.NORMAL, 5),
		Tile.new(Tile.TileColor.BLACK, 2, Tile.Kind.NORMAL, 6),
		Tile.new(Tile.TileColor.YELLOW, 3, Tile.Kind.NORMAL, 7),
		Tile.new(Tile.TileColor.YELLOW, 3, Tile.Kind.NORMAL, 8),
		Tile.new(Tile.TileColor.RED, 4, Tile.Kind.NORMAL, 9),
		Tile.new(Tile.TileColor.RED, 4, Tile.Kind.NORMAL, 10),
	]
	var action := Action.new(Action.ActionType.OPEN_MELDS, {
		"open_by_pairs": true,
		"melds": [
			{"kind": Meld.Kind.PAIRS, "tile_ids": [1, 2]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [3, 4]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [5, 6]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [7, 8]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [9, 10]},
		]
	})
	var validator := Validator.new()
	var res: Dictionary = validator.validate_action(state, 0, action)
	if not bool(res.get("ok", false)):
		push_error("Expected fake+okey pair to be valid, got: %s" % str(res.get("code", "")))
		return false
	return true

func _test_open_by_pairs_rejects_fake_with_wrong_tile() -> bool:
	var state := _make_state()
	state.players[0].hand = [
		Tile.new(Tile.TileColor.RED, 0, Tile.Kind.FAKE_OKEY, 11),
		Tile.new(Tile.TileColor.BLUE, 6, Tile.Kind.NORMAL, 12),
		Tile.new(Tile.TileColor.BLUE, 1, Tile.Kind.NORMAL, 13),
		Tile.new(Tile.TileColor.BLUE, 1, Tile.Kind.NORMAL, 14),
		Tile.new(Tile.TileColor.BLACK, 2, Tile.Kind.NORMAL, 15),
		Tile.new(Tile.TileColor.BLACK, 2, Tile.Kind.NORMAL, 16),
		Tile.new(Tile.TileColor.YELLOW, 3, Tile.Kind.NORMAL, 17),
		Tile.new(Tile.TileColor.YELLOW, 3, Tile.Kind.NORMAL, 18),
		Tile.new(Tile.TileColor.RED, 4, Tile.Kind.NORMAL, 19),
		Tile.new(Tile.TileColor.RED, 4, Tile.Kind.NORMAL, 20),
	]
	var action := Action.new(Action.ActionType.OPEN_MELDS, {
		"open_by_pairs": true,
		"melds": [
			{"kind": Meld.Kind.PAIRS, "tile_ids": [11, 12]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [13, 14]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [15, 16]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [17, 18]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [19, 20]},
		]
	})
	var validator := Validator.new()
	var res: Dictionary = validator.validate_action(state, 0, action)
	if bool(res.get("ok", false)):
		push_error("Expected fake+wrong tile pair to be rejected")
		return false
	return true
