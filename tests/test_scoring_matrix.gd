extends RefCounted


func run() -> bool:
	return _test_scoring_matrix() and _test_all_in_one()

func _test_scoring_matrix() -> bool:
	var cfg = RuleConfig.new()
	cfg.scoring_full_rules = true

	var state = GameState.new()
	state.rule_config = cfg
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 1000))

	var winner = PlayerState.new()
	winner.has_opened = true
	winner.opened_by_pairs = false

	var p1 = PlayerState.new()
	p1.has_opened = true
	p1.opened_by_pairs = true
	p1.hand = [Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 1)]

	var p2 = PlayerState.new()
	p2.has_opened = true
	p2.opened_by_pairs = false
	p2.hand = [Tile.new(Tile.TileColor.RED, 2, Tile.Kind.NORMAL, 2)]

	var p3 = PlayerState.new()
	p3.has_opened = false
	p3.hand = [Tile.new(Tile.TileColor.RED, 3, Tile.Kind.NORMAL, 3)]

	state.players = [winner, p1, p2, p3]
	state.discard_pile = [Tile.new(Tile.TileColor.BLUE, 7, Tile.Kind.NORMAL, 99)]

	var scoring = Scoring.new()
	var scores = scoring.compute_round_scores(state, 0)
	if scores[0] != -101:
		push_error("Winner score mismatch")
		return false
	if scores[1] != 2:
		push_error("Pairs opener should be doubled (1*2)")
		return false
	if scores[2] != 2:
		push_error("Meld opener should be normal (2)")
		return false
	if scores[3] != 202:
		push_error("Non-opener should be 202")
		return false

	# Winner opened by pairs and discarded joker
	winner.opened_by_pairs = true
	state.discard_pile = [Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 1001)] # real okey
	var scores2 = scoring.compute_round_scores(state, 0)
	if scores2[0] != -404:
		push_error("Pairs winner with joker should be -404")
		return false
	if scores2[1] != 8:
		push_error("Pairs opener should be 8x for joker finish")
		return false
	if scores2[2] != 8:
		push_error("Meld opener should be 4x for joker finish")
		return false
	if scores2[3] != 404:
		push_error("Non-opener should be 404")
		return false

	return true

func _test_all_in_one() -> bool:
	var cfg = RuleConfig.new()
	cfg.scoring_full_rules = true

	var state = GameState.new()
	state.rule_config = cfg
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 2000))
	state.last_finish_all_in_one_turn = true

	var winner = PlayerState.new()
	winner.has_opened = true
	winner.opened_by_pairs = false

	var p1 = PlayerState.new()
	var p2 = PlayerState.new()

	state.players = [winner, p1, p2]
	state.discard_pile = [Tile.new(Tile.TileColor.BLUE, 7, Tile.Kind.NORMAL, 77)]

	var scoring = Scoring.new()
	var scores = scoring.compute_round_scores(state, 0)
	if scores[0] != -202:
		push_error("All-in-one winner should be -202")
		return false
	if scores[1] != 404 or scores[2] != 404:
		push_error("All-in-one others should be 404")
		return false

	# All-in-one with joker discard
	state.discard_pile = [Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 78)] # real okey for indicator 5
	var scores_joker = scoring.compute_round_scores(state, 0)
	if scores_joker[0] != -404:
		push_error("All-in-one joker winner should be -404")
		return false
	if scores_joker[1] != 808 or scores_joker[2] != 808:
		push_error("All-in-one joker others should be 808")
		return false

	return true




