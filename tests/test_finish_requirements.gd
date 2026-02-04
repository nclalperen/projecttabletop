extends RefCounted

const RuleConfig = preload("res://core/rules/RuleConfig.gd")
const GameSetup = preload("res://core/state/GameSetup.gd")
const Validator = preload("res://core/actions/Validator.gd")
const Reducer = preload("res://core/actions/Reducer.gd")
const Action = preload("res://core/actions/Action.gd")
const Tile = preload("res://core/model/Tile.gd")
const Meld = preload("res://core/model/Meld.gd")

func run() -> bool:
	return _test_finish_requires_discard_and_used_tile() and _test_finish_requires_starter_tiles()

func _test_finish_requires_discard_and_used_tile() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 5555, 4)
	# Move to TURN_PLAY with 22 tiles
	state.phase = state.Phase.TURN_PLAY
	var player = state.current_player_index

	# Force a required discard take tile
	var required = state.players[player].hand[0]
	state.turn_required_use_tile_id = required.unique_id

	# Build a simple meld that does NOT include required tile
	var t1 = state.players[player].hand[1]
	var t2 = state.players[player].hand[2]
	var t3 = state.players[player].hand[3]
	var melds = [
		{"kind": Meld.Kind.RUN, "tile_ids": [t1.unique_id, t2.unique_id, t3.unique_id]}
	]

	var final_discard = state.players[player].hand[4]
	var action = Action.new(Action.ActionType.FINISH, {
		"melds": melds,
		"final_discard_tile_id": final_discard.unique_id,
		"finish_all_in_one_turn": false
	})

	var validator = Validator.new()
	var res = validator.validate_action(state, player, action)
	if res.ok:
		push_error("Finish should fail when required discard tile is not used in melds")
		return false

	# Now include required tile in meld and ensure discard is different
	melds = [
		{"kind": Meld.Kind.RUN, "tile_ids": [required.unique_id, t2.unique_id, t3.unique_id]}
	]
	final_discard = state.players[player].hand[4]
	if final_discard.unique_id == required.unique_id:
		final_discard = state.players[player].hand[5]
	var action2 = Action.new(Action.ActionType.FINISH, {
		"melds": melds,
		"final_discard_tile_id": final_discard.unique_id,
		"finish_all_in_one_turn": false
	})
	res = validator.validate_action(state, player, action2)
	if not res.ok:
		push_error("Finish should allow when required tile is used in melds")
		return false

	return true

func _test_finish_requires_starter_tiles() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 6666, 4)
	state.phase = state.Phase.TURN_PLAY
	var player = state.current_player_index

	# Force hand to 21 tiles (invalid for finish)
	while state.players[player].hand.size() > cfg.tiles_per_player:
		state.players[player].hand.pop_back()

	var t1 = state.players[player].hand[0]
	var t2 = state.players[player].hand[1]
	var t3 = state.players[player].hand[2]
	var melds = [
		{"kind": Meld.Kind.RUN, "tile_ids": [t1.unique_id, t2.unique_id, t3.unique_id]}
	]
	var final_discard = state.players[player].hand[3]
	var action = Action.new(Action.ActionType.FINISH, {
		"melds": melds,
		"final_discard_tile_id": final_discard.unique_id,
		"finish_all_in_one_turn": false
	})
	var validator = Validator.new()
	var res = validator.validate_action(state, player, action)
	if res.ok:
		push_error("Finish should require starter_tiles (22)")
		return false
	return true
