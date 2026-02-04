extends RefCounted


var _cancelled = false

func run() -> bool:
	return _test_round_cancel_signal()

func _test_round_cancel_signal() -> bool:
	var controller = LocalGameController.new()
	controller.round_cancelled.connect(func(): _cancelled = true)

	var cfg = RuleConfig.new()
	cfg.allow_open_by_five_pairs = true
	cfg.cancel_round_if_all_pairs_open = true
	controller.start_new_round(cfg, 1602, 4)
	controller.state.phase = controller.state.Phase.TURN_PLAY

	for i in range(4):
		controller.state.current_player_index = i
		controller.state.players[i].hand = [
			Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, i * 100 + 1),
			Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, i * 100 + 2),
			Tile.new(Tile.TileColor.BLUE, 2, Tile.Kind.NORMAL, i * 100 + 3),
			Tile.new(Tile.TileColor.BLUE, 2, Tile.Kind.NORMAL, i * 100 + 4),
			Tile.new(Tile.TileColor.BLACK, 3, Tile.Kind.NORMAL, i * 100 + 5),
			Tile.new(Tile.TileColor.BLACK, 3, Tile.Kind.NORMAL, i * 100 + 6),
			Tile.new(Tile.TileColor.YELLOW, 4, Tile.Kind.NORMAL, i * 100 + 7),
			Tile.new(Tile.TileColor.YELLOW, 4, Tile.Kind.NORMAL, i * 100 + 8),
			Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, i * 100 + 9),
			Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, i * 100 + 10),
		]
		var melds = [
			{"kind": Meld.Kind.PAIRS, "tile_ids": [i * 100 + 1, i * 100 + 2]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [i * 100 + 3, i * 100 + 4]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [i * 100 + 5, i * 100 + 6]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [i * 100 + 7, i * 100 + 8]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [i * 100 + 9, i * 100 + 10]},
		]
		var action = Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds, "open_by_pairs": true})
		controller.apply_action_if_valid(i, action)

	if not _cancelled:
		push_error("Expected round_cancelled signal")
		return false

	return true




