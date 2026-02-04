extends RefCounted

const RuleConfig = preload("res://core/rules/RuleConfig.gd")
const GameSetup = preload("res://core/state/GameSetup.gd")
const Validator = preload("res://core/actions/Validator.gd")
const Reducer = preload("res://core/actions/Reducer.gd")
const Action = preload("res://core/actions/Action.gd")
const Meld = preload("res://core/model/Meld.gd")
const Tile = preload("res://core/model/Tile.gd")

func run() -> bool:
	return _test_add_to_meld_requires_open() and _test_add_to_meld_valid()

func _test_add_to_meld_requires_open() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 909, 4)
	state.phase = state.Phase.TURN_PLAY
	var player = state.current_player_index

	var validator = Validator.new()
	var action = Action.new(Action.ActionType.ADD_TO_MELD, {"target_meld_index": 0, "tile_ids": []})
	var res = validator.validate_action(state, player, action)
	if res.ok:
		push_error("ADD_TO_MELD should be blocked before opening")
		return false

	state.players[player].has_opened = true
	res = validator.validate_action(state, player, action)
	if res.ok:
		push_error("ADD_TO_MELD should fail with missing meld payload")
		return false

	return true

func _test_add_to_meld_valid() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 910, 4)
	state.phase = state.Phase.TURN_PLAY
	var player = state.current_player_index
	state.players[player].has_opened = true

	# Create a run meld on table: 5-6-7 red
	var t1 = Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 100)
	var t2 = Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 101)
	var t3 = Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 102)
	state.table_melds = [Meld.new(Meld.Kind.RUN, [100, 101, 102], [t1, t2, t3])]

	# Player has 8 red to add
	state.players[player].hand = [
		Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 103)
	]

	var validator = Validator.new()
	var action = Action.new(Action.ActionType.ADD_TO_MELD, {"target_meld_index": 0, "tile_ids": [103]})
	var res = validator.validate_action(state, player, action)
	if not res.ok:
		push_error("ADD_TO_MELD should be valid: %s" % res.code)
		return false

	var reducer = Reducer.new()
	state = reducer.apply_action(state, player, action)
	if state.table_melds[0].tiles.size() != 4:
		push_error("Expected meld size 4 after add")
		return false
	if state.players[player].hand.size() != 0:
		push_error("Expected tile removed from hand")
		return false

	return true




