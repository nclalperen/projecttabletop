extends Node
class_name LocalGameController

signal state_changed(new_state)
signal action_rejected(reason)
signal round_cancelled
signal action_applied(player_index, action_type)
signal turn_advanced(current_player_index, phase)

const GameSetup = preload("res://core/state/GameSetup.gd")
const Validator = preload("res://core/actions/Validator.gd")

var state
var show_tips: bool = true

func start_new_round(rule_config: RuleConfig, rng_seed: int, player_count: int = 4) -> void:
	var setup = GameSetup.new()
	state = setup.new_round(rule_config, rng_seed, player_count)
	emit_signal("state_changed", state)

func request_action(player_index: int, action: Action) -> Dictionary:
	var validator = Validator.new()
	return validator.validate_action(state, player_index, action)

func apply_action_if_valid(player_index: int, action: Action) -> Dictionary:
	var res = request_action(player_index, action)
	if not res.ok:
		if action.type == Action.ActionType.OPEN_MELDS:
			_apply_failed_opening_penalty_if_needed(player_index)
		emit_signal("action_rejected", res.reason)
		return res

	var reducer = Reducer.new()
	state = reducer.apply_action(state, player_index, action)
	emit_signal("state_changed", state)
	emit_signal("action_applied", player_index, action.type)
	emit_signal("turn_advanced", state.current_player_index, state.phase)
	_check_deck_exhausted()
	if state.round_cancelled:
		emit_signal("round_cancelled")
	return res

func disable_tips() -> void:
	show_tips = false

func _apply_failed_opening_penalty_if_needed(player_index: int) -> void:
	if state == null or state.rule_config == null:
		return
	if not state.rule_config.penalty_failed_opening:
		return
	if state.phase != state.Phase.TURN_PLAY:
		return
	var player = state.players[player_index]
	player.score_round += state.rule_config.penalty_value
	player.score_total += state.rule_config.penalty_value

func apply_illegal_manipulation_penalty(player_index: int) -> void:
	if state == null or state.rule_config == null:
		return
	if not state.rule_config.penalty_illegal_manipulation:
		return
	var player = state.players[player_index]
	player.score_round += state.rule_config.penalty_value
	player.score_total += state.rule_config.penalty_value

func end_round_no_winner() -> void:
	if state == null:
		return
	var scoring = Scoring.new()
	scoring.apply_no_winner_penalties(state)
	state.phase = state.Phase.ROUND_END
	emit_signal("state_changed", state)

func get_discard_penalty_info(player_index: int, tile_id: int) -> Dictionary:
	if state == null:
		return {"discard_joker": false, "extendable": false, "penalty_value": 0}
	var player = state.players[player_index]
	var tile = null
	for t in player.hand:
		if t.unique_id == tile_id:
			tile = t
			break
	if tile == null:
		return {"discard_joker": false, "extendable": false, "penalty_value": 0}

	var discard_joker = tile.kind == tile.Kind.FAKE_OKEY or state.okey_context.is_real_okey(tile)
	var discard_rules = DiscardRules.new()
	var extendable = discard_rules.is_tile_extendable_on_table(state, tile)
	var penalty_value = state.rule_config.penalty_value if state.rule_config != null else 0
	return {
		"discard_joker": discard_joker,
		"extendable": extendable,
		"penalty_value": penalty_value
	}

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


