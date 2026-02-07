extends RefCounted


func run() -> bool:
	return _test_end_play_blocked_for_unopened_required_tile()


func _test_end_play_blocked_for_unopened_required_tile() -> bool:
	var cfg = RuleConfig.new()
	cfg.discard_take_must_be_used_always = false
	cfg.if_not_opened_discard_take_requires_open_and_includes_tile = true

	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 14141, 4)
	state.phase = state.Phase.TURN_PLAY
	state.current_player_index = 0
	state.turn_required_use_tile_id = 12345
	state.players[0].has_opened = false
	state.players[0].hand = [
		Tile.new(Tile.TileColor.RED, 3, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.BLUE, 4, Tile.Kind.NORMAL, 2),
	]

	var validator = Validator.new()
	var res = validator.validate_action(state, 0, Action.new(Action.ActionType.END_PLAY, {}))
	if res.ok:
		push_error("END_PLAY should be blocked when unopened player still must use taken discard")
		return false
	if String(res.code) != "must_use_taken_tile":
		push_error("Expected must_use_taken_tile, got: %s" % String(res.code))
		return false
	return true

