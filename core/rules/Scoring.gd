extends RefCounted
class_name Scoring

# SeOkey11 dossier scoring (simplified):
# - Winner: 0
# - Never opened: 202
# - Opened: sum of leftover tiles
#   - Real okey (wild) in hand after opening: 101 each
#   - Fake okey: represented value (okey number)
# - Opened by pairs: penalty doubled

func apply_round_scores(state: GameState, winner_index: int) -> void:
	var scores = compute_round_scores(state, winner_index)
	for i in range(scores.size()):
		var player = state.players[i]
		player.score_round += scores[i]
		player.score_total += scores[i]

func compute_round_scores(state: GameState, winner_index: int) -> Array:
	return _compute_seokey11_scores(state, winner_index)

func _compute_seokey11_scores(state: GameState, winner_index: int) -> Array:
	var scores: Array = []
	for i in range(state.players.size()):
		if i == winner_index:
			scores.append(0)
			continue

		var player = state.players[i]
		if not player.has_opened:
			scores.append(202)
			continue

		var sum = _sum_hand_seokey11(state, player)
		if player.opened_by_pairs:
			sum *= 2
		scores.append(sum)

	return scores

func _sum_hand_seokey11(state: GameState, player: PlayerState) -> int:
	var sum := 0
	for tile in player.hand:
		if state.okey_context != null and state.okey_context.is_real_okey(tile):
			sum += 101
		elif tile.kind == Tile.Kind.FAKE_OKEY:
			sum += state.okey_context.okey_number if state.okey_context != null else 0
		else:
			sum += tile.number
	return sum
