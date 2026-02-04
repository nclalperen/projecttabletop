extends RefCounted


func run() -> bool:
	return _test_discard_take_must_use()

func _test_discard_take_must_use() -> bool:
	var cfg = RuleConfig.new()
	cfg.discard_take_must_be_used_always = true
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 1301, 4)

	# Force into draw phase with a discard available
	state.phase = state.Phase.TURN_DRAW
	state.discard_pile = [Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 500)]
	var player = state.current_player_index
	state.players[player].hand = state.players[player].hand.slice(0, cfg.tiles_per_player)

	var validator = Validator.new()
	var reducer = Reducer.new()

	var take = Action.new(Action.ActionType.TAKE_DISCARD, {})
	var res = validator.validate_action(state, player, take)
	if not res.ok:
		push_error("Take discard should be valid")
		return false
	state = reducer.apply_action(state, player, take)

	var end_play = Action.new(Action.ActionType.END_PLAY, {})
	res = validator.validate_action(state, player, end_play)
	if res.ok:
		push_error("End play should be blocked when taken discard not used")
		return false

	return true




