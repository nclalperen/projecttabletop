extends "res://core/controller/MatchControllerPort.gd"
class_name LocalGameController

var show_tips: bool = true

func start_new_round(rule_config: RuleConfig, rng_seed: int, player_count: int = 4) -> void:
	if state != null and bool(state.match_finished):
		return
	var setup = GameSetup.new()
	var dealer_override := -1
	var carry_scores: Array = []
	var next_round_index: int = 1
	if state != null and state.dealer_index >= 0:
		dealer_override = (int(state.dealer_index) + 1) % player_count
		carry_scores = _capture_score_totals(state)
		next_round_index = int(state.round_index)
		if not _is_redeal_reason(String(state.round_end_reason)):
			next_round_index += 1
	state = setup.new_round(rule_config, rng_seed, player_count, dealer_override)
	state.round_index = next_round_index
	if not carry_scores.is_empty():
		for i in range(mini(state.players.size(), carry_scores.size())):
			state.players[i].score_total = int(carry_scores[i])
			state.players[i].score_round = 0
	state.match_finished = false
	state.match_winner_indices = []
	emit_signal("state_changed", state)

func start_new_match(rule_config: RuleConfig, rng_seed: int, player_count: int = 4) -> void:
	var setup = GameSetup.new()
	state = setup.new_round(rule_config, rng_seed, player_count, -1)
	state.round_index = 1
	state.match_finished = false
	state.match_winner_indices = []
	emit_signal("state_changed", state)

func request_action(player_index: int, action: Action) -> Dictionary:
	var validator = Validator.new()
	return validator.validate_action(state, player_index, action)

func submit_action_envelope(action_dict: Dictionary) -> Dictionary:
	if state == null:
		return {"ok": false, "code": "state_missing", "reason": "State is not initialized"}
	if typeof(action_dict) != TYPE_DICTIONARY:
		return {"ok": false, "code": "invalid_envelope", "reason": "Action envelope must be a dictionary"}
	var action_type_name: String = String(action_dict.get("type", "")).strip_edges().to_upper()
	if action_type_name == "":
		return {"ok": false, "code": "missing_type", "reason": "Envelope requires type"}
	var player_index: int = int(action_dict.get("player_id", -1))
	if player_index < 0:
		return {"ok": false, "code": "missing_player_id", "reason": "Envelope requires player_id"}
	var payload: Dictionary = {}
	if action_dict.has("payload"):
		if typeof(action_dict["payload"]) != TYPE_DICTIONARY:
			return {"ok": false, "code": "invalid_payload", "reason": "payload must be a dictionary"}
		payload = action_dict["payload"]
	var action: Action = _action_from_envelope(action_type_name, payload)
	if action == null:
		return {"ok": false, "code": "unknown_action", "reason": "Unknown action type"}
	return apply_action_if_valid(player_index, action)

func apply_action_if_valid(player_index: int, action: Action) -> Dictionary:
	if state == null:
		return {"ok": false, "reason": "State is not initialized", "code": "state_missing"}
	if bool(state.match_finished):
		var blocked = {"ok": false, "reason": "Match already finished", "code": "match_finished"}
		emit_signal("action_rejected", blocked.reason)
		return _normalize_result(blocked)

	var res = request_action(player_index, action)
	if not bool(res.get("ok", false)):
		var applied_penalty: bool = _try_apply_failed_open_penalty(player_index, action, res)
		emit_signal("action_rejected", String(res.get("reason", "Action rejected")))
		if applied_penalty:
			emit_signal("state_changed", state)
		_check_deck_exhausted(true)
		return _normalize_result(res)

	var reducer = Reducer.new()
	var before_state = state
	var next_state = reducer.apply_action(state, player_index, action)
	if not _is_reducer_effective(before_state, next_state, player_index, action):
		var fail = {"ok": false, "reason": "Action had no effect", "code": "no_effect"}
		emit_signal("action_rejected", fail.reason)
		return _normalize_result(fail)
	state = next_state

	_check_all_players_opened_by_pairs_cancel_deal(false)
	_check_deck_exhausted(false)
	_evaluate_match_end()

	emit_signal("state_changed", state)
	emit_signal("action_applied", player_index, action.type)
	emit_signal("turn_advanced", state.current_player_index, state.phase)
	return _normalize_result(res)

# Deprecated compatibility shim; retained for external/dynamic callers.
func disable_tips() -> void:
	show_tips = false

func end_round_no_winner(reason: String = "manual", emit_update: bool = true) -> void:
	if state == null:
		return
	var next_state = _clone_state_for_score_mutation(state)
	var scoring = Scoring.new()
	scoring.apply_round_scores_no_winner(next_state, reason)
	next_state.phase = next_state.Phase.ROUND_END
	state = next_state
	_evaluate_match_end()
	if emit_update:
		emit_signal("state_changed", state)

func apply_manual_penalty(player_index: int, points: int) -> void:
	if state == null:
		return
	if player_index < 0 or player_index >= state.players.size():
		return
	var next_state = _clone_state_for_score_mutation(state)
	var p = next_state.players[player_index]
	p.score_round += int(points)
	p.score_total += int(points)
	state = next_state
	emit_signal("state_changed", state)

func _check_deck_exhausted(emit_update: bool = true) -> void:
	if state == null:
		return
	if state.phase != state.Phase.TURN_DRAW:
		return
	if not state.deck.is_empty():
		return
	if state.discard_pile.is_empty():
		_handle_stock_empty_end(emit_update)
		return
	var current_player: int = int(state.current_player_index)
	var validator = Validator.new()
	var take_res: Dictionary = validator.validate_action(state, current_player, Action.new(Action.ActionType.TAKE_DISCARD, {}))
	if not bool(take_res.get("ok", false)):
		_handle_stock_empty_end(emit_update)

func _handle_stock_empty_end(emit_update: bool) -> void:
	if state == null or state.rule_config == null:
		end_round_no_winner("stock_empty", emit_update)
		return
	var mode: String = String(state.rule_config.end_on_stock_empty).to_lower()
	match mode:
		"redeal":
			_end_round_redeal("stock_empty_redeal", emit_update)
		"platform_default":
			end_round_no_winner("stock_empty_platform_default", emit_update)
		_:
			end_round_no_winner("stock_empty", emit_update)

func _end_round_redeal(reason: String, emit_update: bool) -> void:
	if state == null:
		return
	var next_state = _clone_state_for_score_mutation(state)
	next_state.phase = next_state.Phase.ROUND_END
	next_state.round_end_reason = reason
	next_state.last_winner_index = -1
	next_state.last_finish_type = Scoring.FINISH_NO_WINNER
	for p in next_state.players:
		p.deal_penalty_points = 0
		p.score_round = 0
	state = next_state
	if emit_update:
		emit_signal("state_changed", state)

func _check_all_players_opened_by_pairs_cancel_deal(emit_update: bool) -> void:
	if state == null or state.rule_config == null:
		return
	if not bool(state.rule_config.cancel_deal_if_all_open_doubles):
		return
	if state.phase == state.Phase.ROUND_END:
		return
	if state.players.is_empty():
		return
	for p in state.players:
		if not bool(p.has_opened) or not bool(p.opened_by_pairs):
			return
	_end_round_redeal("all_pairs_redeal", emit_update)

func _evaluate_match_end() -> void:
	if state == null or state.rule_config == null:
		return
	if state.phase != state.Phase.ROUND_END:
		return
	if _is_redeal_reason(String(state.round_end_reason)):
		return
	if bool(state.match_finished):
		return

	var cfg: RuleConfig = state.rule_config
	var winners: Array = []
	var reason: String = ""
	if cfg.match_end_mode == "rounds":
		if int(cfg.match_end_value) > 0 and int(state.round_index) >= int(cfg.match_end_value):
			winners = _lowest_score_winners(state)
			reason = "round_limit"
	elif cfg.match_end_mode == "target_score":
		var reached := false
		for p in state.players:
			if int(p.score_total) >= int(cfg.match_end_value):
				reached = true
				break
		if reached:
			winners = _lowest_score_winners(state)
			reason = "target_score_reached"

	if winners.is_empty():
		return
	state.match_finished = true
	state.match_winner_indices = winners.duplicate()
	emit_signal("match_finished", winners, _capture_score_totals(state), reason)

func _lowest_score_winners(src_state: GameState) -> Array:
	var winners: Array = []
	if src_state == null or src_state.players.is_empty():
		return winners
	var min_score: int = 2147483647
	for i in range(src_state.players.size()):
		min_score = mini(min_score, int(src_state.players[i].score_total))
	for j in range(src_state.players.size()):
		if int(src_state.players[j].score_total) == min_score:
			winners.append(j)
	return winners

func _capture_score_totals(src_state: GameState) -> Array:
	var scores: Array = []
	if src_state == null:
		return scores
	for p in src_state.players:
		scores.append(int(p.score_total))
	return scores

func _is_redeal_reason(reason: String) -> bool:
	return reason == "stock_empty_redeal" or reason == "all_pairs_redeal"

func _try_apply_failed_open_penalty(player_index: int, action: Action, validation_res: Dictionary) -> bool:
	if state == null or state.rule_config == null:
		return false
	if not bool(state.rule_config.penalty_failed_open_attempt):
		return false
	if player_index < 0 or player_index >= state.players.size():
		return false
	var player = state.players[player_index]
	if bool(player.has_opened):
		return false
	if not _is_open_attempt_action(action):
		return false
	var code: String = String(validation_res.get("code", ""))
	if code == "" or code == "ok":
		return false
	if _is_non_penalized_open_reject(code):
		return false
	var next_state = _clone_state_for_score_mutation(state)
	next_state.players[player_index].deal_penalty_points += int(state.rule_config.penalty_value)
	state = next_state
	return true

func _is_open_attempt_action(action: Action) -> bool:
	if action == null:
		return false
	if action.type == Action.ActionType.OPEN_MELDS:
		return action.payload.has("melds")
	if action.type == Action.ActionType.PLACE_TILES:
		if not action.payload.has("placements"):
			return false
		for placement in action.payload["placements"]:
			if typeof(placement) != TYPE_DICTIONARY:
				continue
			if String(placement.get("op", "")).strip_edges().to_upper() == "CREATE_MELD":
				return true
		return false
	if action.type == Action.ActionType.FINISH:
		return action.payload.has("melds")
	return false

func _is_non_penalized_open_reject(code: String) -> bool:
	return code == "not_current_player" \
		or code == "phase" \
		or code == "missing_melds" \
		or code == "missing_placements" \
		or code == "empty_placements" \
		or code == "missing_payload" \
		or code == "unknown_action"

# Convenience helpers for common actions
func starter_discard(player_index: int, tile_id: int) -> Dictionary:
	return apply_action_if_valid(player_index, Action.new(Action.ActionType.STARTER_DISCARD, {"tile_id": tile_id}))

func draw_from_deck(player_index: int) -> Dictionary:
	return apply_action_if_valid(player_index, Action.new(Action.ActionType.DRAW_FROM_DECK, {}))

func take_discard(player_index: int) -> Dictionary:
	return apply_action_if_valid(player_index, Action.new(Action.ActionType.TAKE_DISCARD, {}))

func end_play_turn(player_index: int) -> Dictionary:
	return apply_action_if_valid(player_index, Action.new(Action.ActionType.END_PLAY, {}))

func discard_tile(player_index: int, tile_id: int) -> Dictionary:
	return apply_action_if_valid(player_index, Action.new(Action.ActionType.DISCARD, {"tile_id": tile_id}))

func _action_from_envelope(action_type_name: String, payload: Dictionary) -> Action:
	match action_type_name:
		"STARTER_DISCARD":
			return Action.new(Action.ActionType.STARTER_DISCARD, payload)
		"DRAW_FROM_STOCK", "DRAW_FROM_DECK":
			return Action.new(Action.ActionType.DRAW_FROM_DECK, payload)
		"TAKE_DISCARD":
			return Action.new(Action.ActionType.TAKE_DISCARD, payload)
		"PLACE_TILES":
			return Action.new(Action.ActionType.PLACE_TILES, payload)
		"OPEN_MELDS":
			return Action.new(Action.ActionType.OPEN_MELDS, payload)
		"ADD_TO_MELD":
			return Action.new(Action.ActionType.ADD_TO_MELD, payload)
		"END_PLAY":
			return Action.new(Action.ActionType.END_PLAY, payload)
		"DISCARD":
			return Action.new(Action.ActionType.DISCARD, payload)
		"FINISH", "DECLARE_FINISH":
			return Action.new(Action.ActionType.FINISH, payload)
		_:
			return null

func _normalize_result(res: Dictionary) -> Dictionary:
	var out: Dictionary = {
		"ok": bool(res.get("ok", false)),
		"code": String(res.get("code", "unknown")),
		"reason": String(res.get("reason", "")),
	}
	if state != null:
		out["state_hash"] = _state_hash(state)
	return out

func _state_hash(src_state: GameState) -> int:
	var payload := {
		"phase": int(src_state.phase),
		"turn": int(src_state.current_player_index),
		"round_index": int(src_state.round_index),
		"scores": _capture_score_totals(src_state),
		"discard_size": src_state.discard_pile.size(),
		"deck_size": src_state.deck.size(),
		"required_tile_id": int(src_state.turn_required_use_tile_id),
		"match_finished": bool(src_state.match_finished),
	}
	return hash(JSON.stringify(payload))

func _is_reducer_effective(before_state, after_state, player_index: int, action: Action) -> bool:
	if before_state == null or after_state == null:
		return false
	if action.type == Action.ActionType.STARTER_DISCARD or action.type == Action.ActionType.DISCARD:
		if player_index < 0 or player_index >= before_state.players.size():
			return false
		if player_index >= after_state.players.size():
			return false
		var before_hand = before_state.players[player_index].hand.size()
		var after_hand = after_state.players[player_index].hand.size()
		var before_discard = before_state.discard_pile.size()
		var after_discard = after_state.discard_pile.size()
		return after_hand == before_hand - 1 and after_discard == before_discard + 1
	return true

func _clone_state_for_score_mutation(src: GameState) -> GameState:
	var next = GameState.new()
	next.rule_config = src.rule_config
	next.okey_context = src.okey_context
	next.phase = src.phase
	next.current_player_index = src.current_player_index
	next.turn_required_use_tile_id = src.turn_required_use_tile_id
	next.last_finish_all_in_one_turn = src.last_finish_all_in_one_turn
	next.dealer_index = src.dealer_index
	next.indicator_stack_index = src.indicator_stack_index
	next.indicator_tile_index = src.indicator_tile_index
	next.draw_stack_indices = src.draw_stack_indices.duplicate(true)
	next.round_index = src.round_index
	next.round_end_reason = src.round_end_reason
	next.last_winner_index = src.last_winner_index
	next.last_finish_type = src.last_finish_type
	next.match_finished = src.match_finished
	next.match_winner_indices = src.match_winner_indices.duplicate(true)
	next.deck = src.deck.duplicate(true)
	next.discard_pile = src.discard_pile.duplicate(true)
	next.player_discard_stacks = src.player_discard_stacks.duplicate(true)
	next.table_melds = []
	for meld in src.table_melds:
		var cloned_ids: Array = meld.tiles.duplicate()
		var cloned_tiles: Array = []
		for t in meld.tiles_data:
			cloned_tiles.append(Tile.new(int(t.color), int(t.number), int(t.kind), int(t.unique_id)))
		next.table_melds.append(Meld.new(int(meld.kind), cloned_ids, cloned_tiles, int(meld.owner_index)))
	next.players = []
	for p in src.players:
		var np = PlayerState.new()
		np.hand = p.hand.duplicate(true)
		np.has_opened = p.has_opened
		np.opened_by_pairs = p.opened_by_pairs
		np.opened_mode = p.opened_mode
		np.score_total = p.score_total
		np.score_round = p.score_round
		np.deal_penalty_points = p.deal_penalty_points
		np.last_round_breakdown = p.last_round_breakdown.duplicate(true)
		next.players.append(np)
	return next
