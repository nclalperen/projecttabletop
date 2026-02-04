extends RefCounted

const RuleConfig = preload("res://core/rules/RuleConfig.gd")
const GameSetup = preload("res://core/state/GameSetup.gd")
const Reducer = preload("res://core/actions/Reducer.gd")
const Action = preload("res://core/actions/Action.gd")
const Meld = preload("res://core/model/Meld.gd")
const Tile = preload("res://core/model/Tile.gd")

func run() -> bool:
	return _test_round_cancel_if_all_pairs_open()

func _test_round_cancel_if_all_pairs_open() -> bool:
	var cfg = RuleConfig.new()
	cfg.allow_open_by_five_pairs = true
	cfg.cancel_round_if_all_pairs_open = true

	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 1501, 4)
	state.phase = state.Phase.TURN_PLAY

	var reducer = Reducer.new()
	for i in range(4):
		state.current_player_index = i
		state.players[i].hand = [
			Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, i * 100 + 1),
			Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, i * 100 + 2),
			Tile.new(Tile.TileColor.BLUE, 2, Tile.Kind.NORMAL, i * 100 + 3),
			Tile.new(Tile.TileColor.BLUE, 2, Tile.Kind.NORMAL, i * 100 + 4),
			Tile.new(Tile.TileColor.BLACK, 3, Tile.Kind.NORMAL, i * 100 + 5),
			Tile.new(Tile.TileColor.BLACK, 3, Tile.Kind.NORMAL, i * 100 + 6),
			Tile.new(Tile.TileColor.YELLOW, 4, Tile.Kind.NORMAL, i * 100 + 7),
			Tile.new(Tile.TileColor.YELLOW, 4, Tile.Kind.NORMAL, i * 100 + 8),
			Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, i * 100 + 9),
			Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, i * 100 + 10),
		]
		var melds = [
			{"kind": Meld.Kind.PAIRS, "tile_ids": [i * 100 + 1, i * 100 + 2]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [i * 100 + 3, i * 100 + 4]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [i * 100 + 5, i * 100 + 6]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [i * 100 + 7, i * 100 + 8]},
			{"kind": Meld.Kind.PAIRS, "tile_ids": [i * 100 + 9, i * 100 + 10]},
		]
		var action = Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds, "open_by_pairs": true})
		state = reducer.apply_action(state, i, action)

	if not state.round_cancelled:
		push_error("Expected round to be cancelled when all players open with pairs")
		return false
	if state.phase != state.Phase.ROUND_END:
		push_error("Expected ROUND_END on cancelled round")
		return false
	return true




