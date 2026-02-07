extends RefCounted


func run() -> bool:
	return _test_opened_player_cannot_take_unusable_discard()


func _test_opened_player_cannot_take_unusable_discard() -> bool:
	var cfg = RuleConfig.new()
	cfg.require_discard_take_to_be_used = true

	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 9911, 4)
	state.phase = state.Phase.TURN_DRAW
	state.current_player_index = 0

	var player = state.players[0]
	player.has_opened = true
	player.hand = [
		Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.BLUE, 5, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.BLACK, 9, Tile.Kind.NORMAL, 3),
	]

	# Yellow 13 cannot be used immediately with this hand into run/set.
	state.discard_pile = [Tile.new(Tile.TileColor.YELLOW, 13, Tile.Kind.NORMAL, 900)]

	var validator = Validator.new()
	var res = validator.validate_action(state, 0, Action.new(Action.ActionType.TAKE_DISCARD, {}))
	if res.ok:
		push_error("Opened player should not take discard if tile cannot be used immediately")
		return false
	if String(res.code) != "cannot_use_discard":
		push_error("Expected cannot_use_discard, got: %s" % String(res.code))
		return false
	return true
