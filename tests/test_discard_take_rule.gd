extends RefCounted

func run() -> bool:
	return _test_discard_take_must_use_before_end_play()

func _test_discard_take_must_use_before_end_play() -> bool:
	var cfg = RuleConfig.new()
	cfg.discard_take_must_be_used_always = true
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 1301, 4)

	# Force into draw phase with a discard available and a player that has already opened.
	state.phase = state.Phase.TURN_DRAW
	state.current_player_index = 0
	var player = state.current_player_index
	state.players[player].has_opened = true

	# Hand can immediately use the discard as a run: 1-2 + discard 3.
	var h1 = Tile.new(Tile.TileColor.BLUE, 1, Tile.Kind.NORMAL, 1)
	var h2 = Tile.new(Tile.TileColor.BLUE, 2, Tile.Kind.NORMAL, 2)
	var extra = Tile.new(Tile.TileColor.BLUE, 9, Tile.Kind.NORMAL, 3)
	state.players[player].hand = [h1, h2, extra]
	state.discard_pile = [Tile.new(Tile.TileColor.BLUE, 3, Tile.Kind.NORMAL, 500)]

	var validator = Validator.new()
	var reducer = Reducer.new()

	var take = Action.new(Action.ActionType.TAKE_DISCARD, {})
	var res = validator.validate_action(state, player, take)
	if not res.ok:
		push_error("Take discard should be valid when it can be used immediately")
		return false
	state = reducer.apply_action(state, player, take)

	var end_play = Action.new(Action.ActionType.END_PLAY, {})
	res = validator.validate_action(state, player, end_play)
	if res.ok:
		push_error("End play should be blocked when taken discard not used")
		return false

	# Use the taken tile in a meld, then end_play should be allowed.
	var required_id = state.turn_required_use_tile_id
	var melds = [
		{"kind": Meld.Kind.RUN, "tile_ids": [required_id, 1, 2]}
	]
	var open = Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds})
	res = validator.validate_action(state, player, open)
	if not res.ok:
		push_error("Open melds should be allowed to use required discard tile")
		return false
	state = reducer.apply_action(state, player, open)

	res = validator.validate_action(state, player, end_play)
	if not res.ok:
		push_error("End play should be allowed after required tile is used")
		return false

	return true
