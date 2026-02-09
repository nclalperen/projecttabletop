extends RefCounted


func run() -> bool:
	return _test_open_then_add_then_discard_persists_table_melds()


func _test_open_then_add_then_discard_persists_table_melds() -> bool:
	var cfg := RuleConfig.new()
	var controller := LocalGameController.new()
	controller.start_new_round(cfg, 424242, 4)

	var starter: int = controller.state.current_player_index
	var starter_tile = controller.state.players[starter].hand[0]
	var res := controller.starter_discard(starter, starter_tile.unique_id)
	if not res.ok:
		push_error("starter_discard failed: %s" % String(res.code))
		return false

	var p: int = controller.state.current_player_index
	# Force deterministic TURN_PLAY hand with a 101+ open and one extra tile for layoff.
	controller.state.phase = GameState.Phase.TURN_PLAY
	controller.state.current_player_index = p
	controller.state.players[p].hand = [
		Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 1001),
		Tile.new(Tile.TileColor.RED, 9, Tile.Kind.NORMAL, 1002),
		Tile.new(Tile.TileColor.RED, 10, Tile.Kind.NORMAL, 1003),
		Tile.new(Tile.TileColor.BLUE, 13, Tile.Kind.NORMAL, 1004),
		Tile.new(Tile.TileColor.BLACK, 13, Tile.Kind.NORMAL, 1005),
		Tile.new(Tile.TileColor.YELLOW, 13, Tile.Kind.NORMAL, 1006),
		Tile.new(Tile.TileColor.BLUE, 11, Tile.Kind.NORMAL, 1007),
		Tile.new(Tile.TileColor.BLUE, 12, Tile.Kind.NORMAL, 1008),
		Tile.new(Tile.TileColor.BLUE, 13, Tile.Kind.NORMAL, 1009),
		Tile.new(Tile.TileColor.RED, 11, Tile.Kind.NORMAL, 1010), # layoff onto run 8-9-10
		Tile.new(Tile.TileColor.BLACK, 1, Tile.Kind.NORMAL, 1011), # final discard
		Tile.new(Tile.TileColor.YELLOW, 2, Tile.Kind.NORMAL, 1012), # remains in hand after discard
	]

	var open_action := Action.new(Action.ActionType.OPEN_MELDS, {
		"melds": [
			{"kind": Meld.Kind.RUN, "tile_ids": [1001, 1002, 1003]},
			{"kind": Meld.Kind.SET, "tile_ids": [1004, 1005, 1006]},
			{"kind": Meld.Kind.RUN, "tile_ids": [1007, 1008, 1009]}
		]
	})
	res = controller.apply_action_if_valid(p, open_action)
	if not res.ok:
		push_error("OPEN_MELDS failed: %s" % String(res.code))
		return false

	if controller.state.table_melds.size() != 3:
		push_error("Expected 3 table melds after open, got %d" % controller.state.table_melds.size())
		return false
	for meld in controller.state.table_melds:
		if int(meld.owner_index) != int(p):
			push_error("Expected meld owner_index=%d after open, got %d" % [p, int(meld.owner_index)])
			return false

	var add_action := Action.new(Action.ActionType.ADD_TO_MELD, {
		"target_meld_index": 0,
		"tile_ids": [1010]
	})
	res = controller.apply_action_if_valid(p, add_action)
	if not res.ok:
		push_error("ADD_TO_MELD failed: %s" % String(res.code))
		return false

	if controller.state.table_melds[0].tiles.size() != 4:
		push_error("Expected first meld size 4 after layoff, got %d" % controller.state.table_melds[0].tiles.size())
		return false
	if int(controller.state.table_melds[0].owner_index) != int(p):
		push_error("Expected meld owner_index to remain %d after layoff, got %d" % [p, int(controller.state.table_melds[0].owner_index)])
		return false

	res = controller.end_play_turn(p)
	if not res.ok:
		push_error("END_PLAY failed: %s" % String(res.code))
		return false

	res = controller.discard_tile(p, 1011)
	if not res.ok:
		push_error("DISCARD failed: %s" % String(res.code))
		return false

	if controller.state.phase != GameState.Phase.TURN_DRAW:
		push_error("Expected TURN_DRAW after discard, got %d" % controller.state.phase)
		return false
	if controller.state.table_melds.size() != 3:
		push_error("Table melds should persist after discard")
		return false

	return true
