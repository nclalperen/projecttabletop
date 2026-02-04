extends RefCounted
class_name Scoring

func apply_round_scores(state, winner_index: int) -> void:
	var scores = compute_round_scores(state, winner_index)
	for i in range(scores.size()):
		var player = state.players[i]
		player.score_round += scores[i]
		player.score_total += scores[i]

func compute_round_scores(state, winner_index: int) -> Array:
	var cfg = state.rule_config
	if cfg != null and not cfg.scoring_full_rules:
		return _compute_basic_scores(state, winner_index)
	return _compute_full_scores(state, winner_index)

func _compute_basic_scores(state, winner_index: int) -> Array:
	var scores: Array = []
	for i in range(state.players.size()):
		if i == winner_index:
			scores.append(-101)
			continue
		var player = state.players[i]
		if not player.has_opened:
			scores.append(202)
			continue
		var sum = _sum_hand_for_scoring(state, player)
		scores.append(sum)
	return scores

func _compute_full_scores(state, winner_index: int) -> Array:
	var scores: Array = []
	var winner = state.players[winner_index]
	var winner_opened_by_pairs = winner.opened_by_pairs
	var winner_discarded_joker = _winner_discarded_joker(state, winner_index)
	var finish_all_in_one = _winner_finished_all_in_one_turn(state, winner_index)

	if finish_all_in_one:
		return _compute_all_in_one_scores(state, winner_index, winner_discarded_joker)

	var multipliers = _get_multiplier_matrix(winner_opened_by_pairs, winner_discarded_joker)

	for i in range(state.players.size()):
		if i == winner_index:
			scores.append(multipliers.winner)
			continue

		var player = state.players[i]
		if not player.has_opened:
			scores.append(multipliers.not_opened)
			continue

		var sum = _sum_hand_for_scoring(state, player)
		if player.opened_by_pairs:
			scores.append(sum * multipliers.opened_pairs)
		else:
			scores.append(sum * multipliers.opened_melds)

	return scores

func _compute_all_in_one_scores(state, winner_index: int, discarded_joker: bool) -> Array:
	var scores: Array = []
	var winner_score = -202
	var others_score = 404
	if discarded_joker:
		winner_score = -404
		others_score = 808
	for i in range(state.players.size()):
		if i == winner_index:
			scores.append(winner_score)
		else:
			scores.append(others_score)
	return scores

func _sum_hand_for_scoring(state, player) -> int:
	var sum = 0
	for tile in player.hand:
		if tile.kind == Tile.Kind.FAKE_OKEY or state.okey_context.is_real_okey(tile):
			sum += 101
		else:
			sum += tile.number
	return sum

func _winner_discarded_joker(state, _winner_index: int) -> bool:
	if state.discard_pile.is_empty():
		return false
	var tile = state.discard_pile[state.discard_pile.size() - 1]
	return tile.kind == Tile.Kind.FAKE_OKEY or state.okey_context.is_real_okey(tile)

func _winner_finished_all_in_one_turn(state, _winner_index: int) -> bool:
	return bool(state.last_finish_all_in_one_turn)

func _get_multiplier_matrix(winner_opened_by_pairs: bool, winner_discarded_joker: bool):
	var result = {
		"winner": -101,
		"opened_melds": 1,
		"opened_pairs": 2,
		"not_opened": 202,
	}

	if not winner_opened_by_pairs and not winner_discarded_joker:
		return result

	if not winner_opened_by_pairs and winner_discarded_joker:
		result.winner = -202
		result.opened_melds = 2
		result.opened_pairs = 4
		result.not_opened = 404
		return result

	if winner_opened_by_pairs and not winner_discarded_joker:
		result.winner = -202
		result.opened_melds = 2
		result.opened_pairs = 4
		result.not_opened = 404
		return result

	# winner_opened_by_pairs and winner_discarded_joker
	result.winner = -404
	result.opened_melds = 4
	result.opened_pairs = 8
	result.not_opened = 404
	return result

func apply_no_winner_penalties(state) -> void:
	if state.rule_config == null or not state.rule_config.penalty_joker_in_hand_when_no_winner:
		return
	for player in state.players:
		var penalty = 0
		for tile in player.hand:
			if tile.kind == Tile.Kind.FAKE_OKEY or state.okey_context.is_real_okey(tile):
				penalty += state.rule_config.penalty_value
		if penalty > 0:
			player.score_round += penalty
			player.score_total += penalty
