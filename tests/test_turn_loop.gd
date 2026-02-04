extends RefCounted

const RuleConfig = preload("res://core/rules/RuleConfig.gd")
const GameSetup = preload("res://core/state/GameSetup.gd")
const Validator = preload("res://core/actions/Validator.gd")
const Reducer = preload("res://core/actions/Reducer.gd")
const Action = preload("res://core/actions/Action.gd")

func run() -> bool:
	return _test_turn_loop() and _test_illegal_phase()

func _test_turn_loop() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 101, 4)

	var validator = Validator.new()
	var reducer = Reducer.new()

	# Starter discard
	var starter = state.current_player_index
	var starter_tile = state.players[starter].hand[0]
	var action = Action.new(Action.ActionType.STARTER_DISCARD, {"tile_id": starter_tile.unique_id})
	var res = validator.validate_action(state, starter, action)
	if not res.ok:
		push_error("Starter discard blocked: %s" % res.code)
		return false
	state = reducer.apply_action(state, starter, action)

	# Next player draw
	var player = state.current_player_index
	var draw = Action.new(Action.ActionType.DRAW_FROM_DECK, {})
	res = validator.validate_action(state, player, draw)
	if not res.ok:
		push_error("Draw blocked: %s" % res.code)
		return false
	state = reducer.apply_action(state, player, draw)

	# End play -> discard phase
	var end_play = Action.new(Action.ActionType.END_PLAY, {})
	res = validator.validate_action(state, player, end_play)
	if not res.ok:
		push_error("End play blocked: %s" % res.code)
		return false
	state = reducer.apply_action(state, player, end_play)

	# Discard
	var tile = state.players[player].hand[0]
	var discard = Action.new(Action.ActionType.DISCARD, {"tile_id": tile.unique_id})
	res = validator.validate_action(state, player, discard)
	if not res.ok:
		push_error("Discard blocked: %s" % res.code)
		return false
	state = reducer.apply_action(state, player, discard)

	if state.phase != state.Phase.TURN_DRAW:
		push_error("Expected TURN_DRAW after discard")
		return false

	return true

func _test_illegal_phase() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 202, 4)
	var validator = Validator.new()

	var player = state.current_player_index
	var draw = Action.new(Action.ActionType.DRAW_FROM_DECK, {})
	var res = validator.validate_action(state, player, draw)
	if res.ok:
		push_error("Draw should be blocked during STARTER_DISCARD")
		return false
	return true



