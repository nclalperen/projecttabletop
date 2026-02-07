extends RefCounted

func run() -> bool:
	return _test_finish_requires_opened() and _test_finish_requires_taken_tile_used()

func _test_finish_requires_opened() -> bool:
	var state = GameState.new()
	state.rule_config = RuleConfig.new()
	state.phase = GameState.Phase.TURN_PLAY
	state.current_player_index = 0
	state.table_melds = []
	state.discard_pile = []
	state.deck = []
	state.turn_required_use_tile_id = -1
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 999))

	var p0 = PlayerState.new()
	p0.has_opened = false
	p0.hand = [
		Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 2, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.RED, 3, Tile.Kind.NORMAL, 3),
		Tile.new(Tile.TileColor.BLUE, 9, Tile.Kind.NORMAL, 4),
	]
	state.players = [p0]

	var action = Action.new(Action.ActionType.FINISH, {
		"melds": [{"kind": Meld.Kind.RUN, "tile_ids": [1, 2, 3]}],
		"final_discard_tile_id": 4,
	})
	var validator = Validator.new()
	var res = validator.validate_action(state, 0, action)
	if res.ok:
		push_error("Finish should require player to have opened")
		return false
	return true

func _test_finish_requires_taken_tile_used() -> bool:
	var state = GameState.new()
	state.rule_config = RuleConfig.new()
	state.phase = GameState.Phase.TURN_PLAY
	state.current_player_index = 0
	state.table_melds = []
	state.discard_pile = []
	state.deck = []
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 999))

	var p0 = PlayerState.new()
	p0.has_opened = true
	p0.hand = [
		Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 2, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.RED, 3, Tile.Kind.NORMAL, 3),
		Tile.new(Tile.TileColor.BLUE, 9, Tile.Kind.NORMAL, 4),
	]
	state.players = [p0]

	# Force a required discard-take tile id.
	state.turn_required_use_tile_id = 1

	# Meld does NOT include required tile -> should fail.
	var action_bad = Action.new(Action.ActionType.FINISH, {
		"melds": [{"kind": Meld.Kind.RUN, "tile_ids": [2, 3, 4]}],
		"final_discard_tile_id": 1,
	})
	var validator = Validator.new()
	var res = validator.validate_action(state, 0, action_bad)
	if res.ok:
		push_error("Finish should fail when required taken tile is not used in melds")
		return false

	# Meld includes required tile; discard is different.
	var action_ok = Action.new(Action.ActionType.FINISH, {
		"melds": [{"kind": Meld.Kind.RUN, "tile_ids": [1, 2, 3]}],
		"final_discard_tile_id": 4,
	})
	res = validator.validate_action(state, 0, action_ok)
	if not res.ok:
		push_error("Finish should allow when required tile is used in melds")
		return false

	return true

