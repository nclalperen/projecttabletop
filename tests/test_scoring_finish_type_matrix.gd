extends RefCounted


func run() -> bool:
	return _test_finish_matrix() and _test_pairs_okey_unopened_override()


func _test_finish_matrix() -> bool:
	var scoring := Scoring.new()

	# Normal finish
	var s_normal := _build_state_for_finish(false, false, false)
	var normal_scores: Array = scoring.compute_round_scores(s_normal, 0)
	if int(normal_scores[0]) != -101 or int(normal_scores[1]) != 202 or int(normal_scores[2]) != 9:
		push_error("Normal finish matrix mismatch: %s" % str(normal_scores))
		return false

	# Okey finish
	var s_okey := _build_state_for_finish(false, true, false)
	var okey_scores: Array = scoring.compute_round_scores(s_okey, 0)
	if int(okey_scores[0]) != -202 or int(okey_scores[1]) != 404 or int(okey_scores[2]) != 18:
		push_error("Okey finish matrix mismatch: %s" % str(okey_scores))
		return false

	# Pairs finish
	var s_pairs := _build_state_for_finish(true, false, false)
	var pairs_scores: Array = scoring.compute_round_scores(s_pairs, 0)
	if int(pairs_scores[0]) != -202 or int(pairs_scores[1]) != 404 or int(pairs_scores[2]) != 18:
		push_error("Pairs finish matrix mismatch: %s" % str(pairs_scores))
		return false

	# Pairs + okey finish
	var s_pairs_okey := _build_state_for_finish(true, true, false)
	var pairs_okey_scores: Array = scoring.compute_round_scores(s_pairs_okey, 0)
	if int(pairs_okey_scores[0]) != -404 or int(pairs_okey_scores[1]) != 404 or int(pairs_okey_scores[2]) != 36:
		push_error("Pairs+okey finish matrix mismatch: %s" % str(pairs_okey_scores))
		return false

	# Elden finish
	var s_elden := _build_state_for_finish(false, false, true)
	var elden_scores: Array = scoring.compute_round_scores(s_elden, 0)
	if int(elden_scores[0]) != -202 or int(elden_scores[1]) != 404 or int(elden_scores[2]) != 404:
		push_error("Elden finish matrix mismatch: %s" % str(elden_scores))
		return false

	# Elden + okey finish
	var s_elden_okey := _build_state_for_finish(false, true, true)
	var elden_okey_scores: Array = scoring.compute_round_scores(s_elden_okey, 0)
	if int(elden_okey_scores[0]) != -404 or int(elden_okey_scores[1]) != 808 or int(elden_okey_scores[2]) != 808:
		push_error("Elden+okey finish matrix mismatch: %s" % str(elden_okey_scores))
		return false

	return true


func _test_pairs_okey_unopened_override() -> bool:
	var scoring := Scoring.new()
	var s_pairs_okey := _build_state_for_finish(true, true, false)
	s_pairs_okey.rule_config.pairs_okey_unopened_penalty = 808
	var scores: Array = scoring.compute_round_scores(s_pairs_okey, 0)
	if int(scores[1]) != 808:
		push_error("pairs_okey_unopened_penalty override not applied, got %s" % int(scores[1]))
		return false
	return true


func _build_state_for_finish(winner_pairs: bool, finish_with_joker: bool, elden: bool) -> GameState:
	var state := GameState.new()
	state.rule_config = RuleConfig.new()
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 1000))
	state.last_finish_all_in_one_turn = elden
	state.phase = GameState.Phase.ROUND_END

	var winner := PlayerState.new()
	winner.has_opened = true
	winner.opened_by_pairs = winner_pairs
	winner.hand = []

	var loser_unopened := PlayerState.new()
	loser_unopened.has_opened = false
	loser_unopened.hand = [Tile.new(Tile.TileColor.BLUE, 9, Tile.Kind.NORMAL, 1)]

	var loser_opened := PlayerState.new()
	loser_opened.has_opened = not elden
	loser_opened.opened_by_pairs = false
	loser_opened.hand = [
		Tile.new(Tile.TileColor.BLUE, 4, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.BLUE, 5, Tile.Kind.NORMAL, 3),
	]

	state.players = [winner, loser_unopened, loser_opened]
	if finish_with_joker:
		state.discard_pile = [Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 4)] # real okey for this context
	else:
		state.discard_pile = [Tile.new(Tile.TileColor.YELLOW, 7, Tile.Kind.NORMAL, 5)]
	return state
