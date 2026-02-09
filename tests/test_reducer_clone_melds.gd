extends RefCounted


func run() -> bool:
	return _test_add_to_meld_does_not_mutate_source_state()


func _test_add_to_meld_does_not_mutate_source_state() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 1515, 4)
	state.phase = state.Phase.TURN_PLAY
	var player: int = state.current_player_index
	state.players[player].has_opened = true

	var t1 = Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 5001)
	var t2 = Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 5002)
	var t3 = Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 5003)
	state.table_melds = [Meld.new(Meld.Kind.RUN, [5001, 5002, 5003], [t1, t2, t3])]
	state.players[player].hand = [Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 5004)]

	var action = Action.new(Action.ActionType.ADD_TO_MELD, {"target_meld_index": 0, "tile_ids": [5004]})
	var reducer = Reducer.new()
	var next = reducer.apply_action(state, player, action)

	if state.table_melds[0].tiles.size() != 3:
		push_error("Source state meld mutated during reduce")
		return false
	if next.table_melds[0].tiles.size() != 4:
		push_error("Next state meld not updated correctly")
		return false
	return true

