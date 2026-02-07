extends Node
class_name LocalGameController

signal state_changed(new_state)
signal action_rejected(reason)
signal action_applied(player_index, action_type)
signal turn_advanced(current_player_index, phase)

var state
var show_tips: bool = true

func start_new_round(rule_config: RuleConfig, rng_seed: int, player_count: int = 4) -> void:
	var setup = GameSetup.new()
	var dealer_override := -1
	if state != null and state.dealer_index >= 0:
		dealer_override = (int(state.dealer_index) + 1) % player_count
	state = setup.new_round(rule_config, rng_seed, player_count, dealer_override)
	emit_signal("state_changed", state)

func request_action(player_index: int, action: Action) -> Dictionary:
	var validator = Validator.new()
	return validator.validate_action(state, player_index, action)

func apply_action_if_valid(player_index: int, action: Action) -> Dictionary:
	var res = request_action(player_index, action)
	if not res.ok:
		emit_signal("action_rejected", res.reason)
		return res

	var reducer = Reducer.new()
	var before_state = state
	var next_state = reducer.apply_action(state, player_index, action)
	if not _is_reducer_effective(before_state, next_state, player_index, action):
		var fail = {"ok": false, "reason": "Action had no effect", "code": "no_effect"}
		emit_signal("action_rejected", fail.reason)
		return fail
	state = next_state
	emit_signal("state_changed", state)
	emit_signal("action_applied", player_index, action.type)
	emit_signal("turn_advanced", state.current_player_index, state.phase)
	_check_deck_exhausted()
	return res

func disable_tips() -> void:
	show_tips = false

func end_round_no_winner() -> void:
	if state == null:
		return
	state.phase = state.Phase.ROUND_END
	emit_signal("state_changed", state)

func apply_manual_penalty(player_index: int, points: int) -> void:
	if state == null:
		return
	if player_index < 0 or player_index >= state.players.size():
		return
	var p = state.players[player_index]
	p.score_round += int(points)
	p.score_total += int(points)
	emit_signal("state_changed", state)

func _check_deck_exhausted() -> void:
	if state == null:
		return
	if state.phase != state.Phase.TURN_DRAW:
		return
	if state.deck.is_empty() and state.discard_pile.is_empty():
		end_round_no_winner()

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


