extends RefCounted


func run() -> bool:
	return _test_peek_discard_no_state_change()

func _test_peek_discard_no_state_change() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 4444, 4)

	# Advance to TURN_DRAW for a non-starter player.
	var validator = Validator.new()
	var reducer = Reducer.new()
	var starter = state.current_player_index
	var starter_tile = state.players[starter].hand[0]
	var discard = Action.new(Action.ActionType.STARTER_DISCARD, {"tile_id": starter_tile.unique_id})
	state = reducer.apply_action(state, starter, discard)

	# Ensure discard pile has one tile and player can peek.
	var player = state.current_player_index
	var peek = Action.new(Action.ActionType.PEEK_DISCARD, {})
	var res = validator.validate_action(state, player, peek)
	if not res.ok:
		push_error("Peek discard should be allowed")
		return false

	var before_count = state.discard_pile.size()
	var before_hand = state.players[player].hand.size()
	var before_phase = state.phase

	state = reducer.apply_action(state, player, peek)
	if state.discard_pile.size() != before_count:
		push_error("Peek should not change discard pile")
		return false
	if state.players[player].hand.size() != before_hand:
		push_error("Peek should not change hand")
		return false
	if state.phase != before_phase:
		push_error("Peek should not change phase")
		return false

	return true
