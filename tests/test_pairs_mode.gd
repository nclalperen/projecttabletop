extends RefCounted


func run() -> bool:
	return _test_pairs_lock() and _test_pairs_additional_meld()

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
		push_error("Pairs opener should not be allowed to open melds")
		return false
	return true

func _test_pairs_additional_meld() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 1202, 4)
	state.phase = state.Phase.TURN_PLAY
	var player = state.current_player_index
	state.players[player].has_opened = true
	state.players[player].opened_by_pairs = true
	state.players[player].opened_mode = "pairs"

	state.players[player].hand = [
		Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 10),
		Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 11),
	]

	var melds = [
		{"kind": Meld.Kind.PAIRS, "tile_ids": [10, 11]}
	]
	var action = Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds, "open_by_pairs": true})
	var validator = Validator.new()
	var res = validator.validate_action(state, player, action)
	if not res.ok:
		push_error("Pairs opener should be allowed to add pairs after opening")
		return false
	return true




