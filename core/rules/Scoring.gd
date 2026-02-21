extends RefCounted
class_name Scoring

const FINISH_NORMAL := "normal"
const FINISH_OKEY := "okey_finish"
const FINISH_PAIRS := "pairs_finish"
const FINISH_PAIRS_OKEY := "pairs_okey_finish"
const FINISH_ELDEN := "elden_finish"
const FINISH_ELDEN_OKEY := "elden_okey_finish"
const FINISH_DEVAM := "devam_finish"
const FINISH_ELDEN_DEVAM := "elden_devam_finish"
const FINISH_NO_WINNER := "no_winner_stock_empty"

func apply_round_scores(state: GameState, winner_index: int) -> void:
	var scores = compute_round_scores(state, winner_index)
	for i in range(scores.size()):
		var player = state.players[i]
		player.score_round += int(scores[i])
		player.score_total += int(scores[i])
		player.deal_penalty_points = 0

func apply_round_scores_no_winner(state: GameState, reason: String = "stock_empty") -> void:
	var scores = compute_round_scores(state, -1)
	for i in range(scores.size()):
		var player = state.players[i]
		player.score_round += int(scores[i])
		player.score_total += int(scores[i])
		player.deal_penalty_points = 0
	state.last_winner_index = -1
	state.last_finish_type = FINISH_NO_WINNER
	state.round_end_reason = reason

func compute_round_scores(state: GameState, winner_index: int) -> Array:
	if winner_index < 0:
		return _compute_no_winner_scores(state)
	return _compute_winner_scores(state, winner_index)

func _compute_no_winner_scores(state: GameState) -> Array:
	var cfg: RuleConfig = _cfg(state)
	var scores: Array = []
	for i in range(state.players.size()):
		var player: PlayerState = state.players[i]
		var score: int
		if player.has_opened:
			score = _sum_hand_value(state, player, cfg)
		else:
			score = int(cfg.unopened_penalty)
			if cfg.unopened_gets_extra_joker_penalty:
				score += _count_jokers_in_hand(state, player) * int(cfg.joker_hand_value)
		score += int(player.deal_penalty_points)
		scores.append(score)
	return scores

func _compute_winner_scores(state: GameState, winner_index: int) -> Array:
	var cfg: RuleConfig = _cfg(state)
	var scores: Array = []
	scores.resize(state.players.size())

	var finish_type: String = _resolve_finish_type(state, winner_index)
	var winner_credit: int = _winner_credit_for_finish(finish_type)
	var outcome_multiplier: int = _outcome_multiplier_for_finish(finish_type)
	var winner_player: PlayerState = state.players[winner_index]

	for i in range(state.players.size()):
		var player: PlayerState = state.players[i]
		if i == winner_index:
			scores[i] = winner_credit + int(player.deal_penalty_points)
			continue

		var score := 0
		if finish_type == FINISH_ELDEN:
			score = 404
		elif finish_type == FINISH_ELDEN_OKEY:
			score = 808
		elif finish_type == FINISH_ELDEN_DEVAM:
			score = 1616
		elif not player.has_opened:
			score = _unopened_penalty_for_finish(cfg, finish_type)
			if cfg.unopened_gets_extra_joker_penalty:
				score += _count_jokers_in_hand(state, player) * int(cfg.joker_hand_value)
		else:
			score = _sum_hand_value(state, player, cfg)
			if player.opened_by_pairs:
				score *= 2
			score *= outcome_multiplier

		score += int(player.deal_penalty_points)
		scores[i] = score

	# Persist lightweight per-round debug metadata for UI/replay tooling.
	for pidx in range(state.players.size()):
		var p: PlayerState = state.players[pidx]
		p.last_round_breakdown = {
			"finish_type": finish_type,
			"winner_index": winner_index,
			"round_score": int(scores[pidx]),
			"opened": bool(p.has_opened),
			"opened_by_pairs": bool(p.opened_by_pairs),
		}

	# Keep round-level finish metadata in GameState for deterministic host sync.
	state.last_winner_index = winner_index
	state.last_finish_type = finish_type
	state.round_end_reason = "winner_finished"
	return scores

func _cfg(state: GameState) -> RuleConfig:
	if state != null and state.rule_config != null:
		return state.rule_config
	return RuleConfig.new()

func _resolve_finish_type(state: GameState, winner_index: int) -> String:
	if state != null and state.last_finish_type != "":
		return state.last_finish_type
	if winner_index < 0 or winner_index >= state.players.size():
		return FINISH_NORMAL
	var winner: PlayerState = state.players[winner_index]
	var finished_with_joker := false
	if not state.discard_pile.is_empty():
		var tile: Tile = state.discard_pile[state.discard_pile.size() - 1]
		finished_with_joker = _is_joker_tile(state, tile)
	var anyone_else_opened := false
	for i in range(state.players.size()):
		if i == winner_index:
			continue
		if bool(state.players[i].has_opened):
			anyone_else_opened = true
			break
	var is_elden: bool = bool(state.last_finish_all_in_one_turn) and not anyone_else_opened
	if is_elden:
		return FINISH_ELDEN_OKEY if finished_with_joker else FINISH_ELDEN
	if winner.opened_by_pairs:
		return FINISH_PAIRS_OKEY if finished_with_joker else FINISH_PAIRS
	return FINISH_OKEY if finished_with_joker else FINISH_NORMAL

func _winner_credit_for_finish(finish_type: String) -> int:
	match finish_type:
		FINISH_OKEY:
			return -202
		FINISH_PAIRS:
			return -202
		FINISH_PAIRS_OKEY:
			return -404
		FINISH_ELDEN:
			return -202
		FINISH_ELDEN_OKEY:
			return -404
		FINISH_DEVAM:
			return -404
		FINISH_ELDEN_DEVAM:
			return -808
		_:
			return -101

func _outcome_multiplier_for_finish(finish_type: String) -> int:
	match finish_type:
		FINISH_OKEY:
			return 2
		FINISH_PAIRS:
			return 2
		FINISH_PAIRS_OKEY:
			return 4
		FINISH_DEVAM:
			return 4
		FINISH_ELDEN_DEVAM:
			return 8
		FINISH_ELDEN:
			return 2
		FINISH_ELDEN_OKEY:
			return 4
		_:
			return 1

func _unopened_penalty_for_finish(cfg: RuleConfig, finish_type: String) -> int:
	if finish_type == FINISH_PAIRS_OKEY:
		return int(cfg.pairs_okey_unopened_penalty)
	if finish_type == FINISH_OKEY or finish_type == FINISH_PAIRS or finish_type == FINISH_DEVAM:
		return int(cfg.unopened_penalty) * 2
	return int(cfg.unopened_penalty)

func _sum_hand_value(state: GameState, player: PlayerState, cfg: RuleConfig) -> int:
	var sum := 0
	for tile in player.hand:
		if _is_joker_tile(state, tile):
			sum += int(cfg.joker_hand_value)
		else:
			sum += int(tile.number)
	return sum

func _count_jokers_in_hand(state: GameState, player: PlayerState) -> int:
	var c := 0
	for tile in player.hand:
		if _is_joker_tile(state, tile):
			c += 1
	return c

func _is_joker_tile(state: GameState, tile: Tile) -> bool:
	if tile == null:
		return false
	if tile.kind == Tile.Kind.FAKE_OKEY:
		return true
	if state != null and state.okey_context != null and state.okey_context.is_real_okey(tile):
		return true
	return false
