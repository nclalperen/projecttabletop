extends RefCounted


func run() -> bool:
	return _test_deck_discard_transitions_no_softlock()


func _test_deck_discard_transitions_no_softlock() -> bool:
	for i in range(20):
		var controller := LocalGameController.new()
		var cfg := RuleConfig.new()
		controller.start_new_round(cfg, 920000 + i, 4)
		var p: int = int(controller.state.current_player_index)
		controller.state.phase = controller.state.Phase.TURN_DRAW
		controller.state.current_player_index = p
		controller.state.deck = []
		controller.state.players[p].has_opened = true
		controller.state.players[p].hand = []

		if i % 2 == 0:
			controller.state.discard_pile = []
			controller._check_deck_exhausted()
			if int(controller.state.phase) != int(controller.state.Phase.ROUND_END):
				push_error("Expected ROUND_END for empty deck+discard at case %d" % i)
				return false
		else:
			var discard_tile := Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 930000 + i)
			controller.state.discard_pile = [discard_tile]
			var t1 := Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 940000 + i * 10 + 1)
			var t2 := Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 940000 + i * 10 + 2)
			var t3 := Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 940000 + i * 10 + 3)
			controller.state.table_melds = [Meld.new(Meld.Kind.RUN, [t1.unique_id, t2.unique_id, t3.unique_id], [t1, t2, t3])]
			controller._check_deck_exhausted()
			if int(controller.state.phase) == int(controller.state.Phase.ROUND_END):
				push_error("Unexpected ROUND_END when discard should be usable at case %d" % i)
				return false
			var take_res: Dictionary = controller.take_discard(p)
			if not bool(take_res.get("ok", false)):
				push_error("Expected TAKE_DISCARD to succeed at case %d, got %s" % [i, str(take_res.get("code", ""))])
				return false
	return true
