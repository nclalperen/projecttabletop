extends RefCounted


func run() -> bool:
	return _test_opened_scoring_real_okey_fake_okey_and_pairs_double()


func _test_opened_scoring_real_okey_fake_okey_and_pairs_double() -> bool:
	var state = GameState.new()
	state.rule_config = RuleConfig.new()
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 999))
	# Okey value is RED-6 for this round.

	var winner = PlayerState.new()
	winner.has_opened = true
	winner.hand = []

	var opened_normal = PlayerState.new()
	opened_normal.has_opened = true
	opened_normal.opened_by_pairs = false
	opened_normal.hand = [
		Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 1),   # real okey => 101
		Tile.new(Tile.TileColor.RED, 0, Tile.Kind.FAKE_OKEY, 2), # fake okey => represented value 6
		Tile.new(Tile.TileColor.BLUE, 7, Tile.Kind.NORMAL, 3),   # 7
	]

	var opened_pairs = PlayerState.new()
	opened_pairs.has_opened = true
	opened_pairs.opened_by_pairs = true
	opened_pairs.hand = [
		Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 4),   # real okey => 101
		Tile.new(Tile.TileColor.RED, 0, Tile.Kind.FAKE_OKEY, 5), # fake okey => 6
		Tile.new(Tile.TileColor.BLACK, 3, Tile.Kind.NORMAL, 6),  # 3
	]

	var unopened = PlayerState.new()
	unopened.has_opened = false
	unopened.hand = [
		Tile.new(Tile.TileColor.YELLOW, 13, Tile.Kind.NORMAL, 7),
	]

	state.players = [winner, opened_normal, opened_pairs, unopened]

	var scoring = Scoring.new()
	var scores = scoring.compute_round_scores(state, 0)

	if int(scores[0]) != -101:
		push_error("Winner must score -101")
		return false
	if int(scores[1]) != 209:
		push_error("Opened normal score mismatch. Expected 209, got %s" % int(scores[1]))
		return false
	if int(scores[2]) != 410:
		push_error("Opened-by-pairs score mismatch. Expected 410, got %s" % int(scores[2]))
		return false
	if int(scores[3]) != 202:
		push_error("Unopened player score mismatch. Expected 202, got %s" % int(scores[3]))
		return false

	return true
