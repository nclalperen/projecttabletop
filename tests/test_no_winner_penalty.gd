extends RefCounted


func run() -> bool:
	return _test_no_winner_penalty()

func _test_no_winner_penalty() -> bool:
	var controller = LocalGameController.new()
	var cfg = RuleConfig.new()
	controller.start_new_round(cfg, 1601, 4)

	# Force a no-winner state with a joker in hand
	controller.state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 999))
	controller.state.players[0].hand = [Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 100)] # real okey
	controller.state.players[1].hand = []
	controller.state.players[2].hand = []
	controller.state.players[3].hand = []

	controller.end_round_no_winner()
	if controller.state.players[0].score_round != cfg.penalty_value:
		push_error("Expected joker-in-hand penalty on no winner")
		return false

	return true




