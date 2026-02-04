extends RefCounted

const RuleConfig = preload("res://core/rules/RuleConfig.gd")
const GameState = preload("res://core/state/GameState.gd")
const PlayerState = preload("res://core/state/PlayerState.gd")
const OkeyContext = preload("res://core/model/OkeyContext.gd")
const Tile = preload("res://core/model/Tile.gd")
const Meld = preload("res://core/model/Meld.gd")
const Reducer = preload("res://core/actions/Reducer.gd")
const Action = preload("res://core/actions/Action.gd")

func run() -> bool:
	return _test_discard_penalties()

func _test_discard_penalties() -> bool:
	var cfg = RuleConfig.new()
	cfg.penalty_discard_joker = true
	cfg.penalty_discard_extendable_tile = true
	cfg.penalty_value = 101

	var state = GameState.new()
	state.rule_config = cfg
	state.phase = state.Phase.TURN_DISCARD
	state.current_player_index = 0
	state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 900))

	var p0 = PlayerState.new()
	p0.hand = [
		Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 2),
	]
	state.players = [p0]

	# Table meld: 5-6-7 red, so 8 red is extendable
	var t1 = Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 10)
	var t2 = Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 11)
	var t3 = Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 12)
	state.table_melds = [Meld.new(Meld.Kind.RUN, [10, 11, 12], [t1, t2, t3])]

	var reducer = Reducer.new()
	var discard = Action.new(Action.ActionType.DISCARD, {"tile_id": 1})
	state = reducer.apply_action(state, 0, discard)
	if state.players[0].score_round != 101:
		push_error("Expected extendable discard penalty")
		return false

	# Discard a real okey tile for joker penalty
	state.phase = state.Phase.TURN_DISCARD
	state.table_melds = []
	var okey_tile = Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 3)
	state.players[0].hand = [okey_tile]
	var discard2 = Action.new(Action.ActionType.DISCARD, {"tile_id": 3})
	state = reducer.apply_action(state, 0, discard2)
	if state.players[0].score_round != 202:
		push_error("Expected joker discard penalty")
		return false

	return true




