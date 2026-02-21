extends RefCounted


func run() -> bool:
	return _test_unopened_is_always_202()


func _test_unopened_is_always_202() -> bool:
	var state = GameState.new()
	state.rule_config = RuleConfig.new()
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.BLACK, 13, Tile.Kind.NORMAL, 900))

	var winner = PlayerState.new()
	winner.has_opened = true
	winner.hand = []

	var unopened = PlayerState.new()
	unopened.has_opened = false
	unopened.hand = [
		Tile.new(Tile.TileColor.BLACK, 1, Tile.Kind.NORMAL, 1), # real okey in this context
		Tile.new(Tile.TileColor.RED, 0, Tile.Kind.FAKE_OKEY, 2),
		Tile.new(Tile.TileColor.YELLOW, 13, Tile.Kind.NORMAL, 3),
	]

	state.players = [winner, unopened]

	var scoring = Scoring.new()
	var scores = scoring.compute_round_scores(state, 0)
	if int(scores[0]) != -101:
		push_error("Winner score must be -101 for normal finish, got %s" % int(scores[0]))
		return false
	if int(scores[1]) != 202:
		push_error("Unopened score must be 202 regardless of hand, got %s" % int(scores[1]))
		return false
	return true
