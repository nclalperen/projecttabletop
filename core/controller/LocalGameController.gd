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
		# Important: rejected draws can still imply "no legal moves" when deck is exhausted.
		# Re-evaluate exhaustion here as well, not only after successful actions.
		_check_deck_exhausted()
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
	var next_state = _clone_state_for_score_mutation(state)
	var p = next_state.players[player_index]
	p.score_round += int(points)
	p.score_total += int(points)
	state = next_state
	emit_signal("state_changed", state)

func _check_deck_exhausted() -> void:
	if state == null:
		return
	if state.phase != state.Phase.TURN_DRAW:
		return
	if not state.deck.is_empty():
		return
	# Deck empty:
	# - if no discard, round ends
	# - if discard exists but current player cannot legally take it, round also ends
	if state.discard_pile.is_empty():
		end_round_no_winner()
		return
	var current_player: int = int(state.current_player_index)
	var validator = Validator.new()
	var take_res: Dictionary = validator.validate_action(state, current_player, Action.new(Action.ActionType.TAKE_DISCARD, {}))
	if not bool(take_res.get("ok", false)):
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
		next.players.append(np)
	return next


