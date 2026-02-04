extends RefCounted


func run() -> bool:
	return _test_discard_penalty_info()

func _test_discard_penalty_info() -> bool:
	var controller = LocalGameController.new()
	var cfg = RuleConfig.new()
	controller.start_new_round(cfg, 1603, 4)
	controller.state.phase = controller.state.Phase.TURN_DISCARD

	var player = controller.state.current_player_index
	controller.state.players[player].hand = [
		Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 2),
	]

	var t1 = Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 10)
	var t2 = Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 11)
	var t3 = Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 12)
	controller.state.table_melds = [Meld.new(Meld.Kind.RUN, [10, 11, 12], [t1, t2, t3])]

	var info = controller.get_discard_penalty_info(player, 1)
	if not info.extendable:
		push_error("Expected extendable discard info")
		return false

	return true




