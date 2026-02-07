extends RefCounted

func run() -> bool:
	return _test_discard_allowed_after_laying_tiles()

func _test_discard_allowed_after_laying_tiles() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 9191, 4)

	# Simulate a player who has already played tiles this turn and is now in discard phase
	# with a reduced hand size (< starter_tiles).
	state.current_player_index = 0
	state.phase = state.Phase.TURN_DISCARD
	state.players[0].has_opened = true
	state.players[0].hand = [
		Tile.new(Tile.TileColor.RED, 4, Tile.Kind.NORMAL, 101),
		Tile.new(Tile.TileColor.BLUE, 9, Tile.Kind.NORMAL, 102),
		Tile.new(Tile.TileColor.BLACK, 12, Tile.Kind.NORMAL, 103),
	]

	var action = Action.new(Action.ActionType.DISCARD, {"tile_id": 102})
	var validator = Validator.new()
	var res = validator.validate_action(state, 0, action)
	if not res.ok:
		push_error("Discard should be allowed with reduced hand size, got: %s" % str(res.code))
		return false

	var reducer = Reducer.new()
	var next = reducer.apply_action(state, 0, action)
	if next.players[0].hand.size() != 2:
		push_error("Discard did not remove exactly one tile")
		return false
	if next.discard_pile.is_empty():
		push_error("Discard pile should contain the discarded tile")
		return false
	if next.phase != next.Phase.TURN_DRAW:
		push_error("Expected TURN_DRAW after normal discard")
		return false

	return true
