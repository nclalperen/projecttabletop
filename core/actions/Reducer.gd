extends RefCounted
class_name Reducer

func apply_action(state: GameState, player_index: int, action: Action) -> GameState:
	var next = _clone_state(state)

	match action.type:
		Action.ActionType.STARTER_DISCARD:
			if _apply_discard(next, player_index, action):
				next.phase = GameState.Phase.TURN_DRAW
				next.current_player_index = _next_player_index(next, player_index)
		Action.ActionType.DRAW_FROM_DECK:
			_apply_draw_from_deck(next, player_index)
			next.phase = GameState.Phase.TURN_PLAY
		Action.ActionType.TAKE_DISCARD:
			_apply_take_discard(next, player_index)
			next.phase = GameState.Phase.TURN_PLAY
		Action.ActionType.OPEN_MELDS:
			_apply_open_melds(next, player_index, action)
		Action.ActionType.ADD_TO_MELD:
			_apply_add_to_meld(next, player_index, action)
		Action.ActionType.END_PLAY:
			next.phase = GameState.Phase.TURN_DISCARD
		Action.ActionType.DISCARD:
			if _apply_discard(next, player_index, action):
				# SeOkey11 dossier: finishing is by discarding the last tile.
				if next.players[player_index].hand.is_empty():
					var scoring = Scoring.new()
					scoring.apply_round_scores(next, player_index)
					next.phase = GameState.Phase.ROUND_END
				else:
					next.phase = GameState.Phase.TURN_DRAW
					next.current_player_index = _next_player_index(next, player_index)
		Action.ActionType.FINISH:
			_apply_finish(next, player_index, action)
			next.phase = GameState.Phase.ROUND_END

	return next

func _apply_draw_from_deck(state: GameState, player_index: int) -> void:
	var tile = state.deck.pop_back()
	state.players[player_index].hand.append(tile)

func _apply_take_discard(state: GameState, player_index: int) -> void:
	var tile = state.discard_pile.pop_back()
	state.players[player_index].hand.append(tile)
	if player_index >= 0 and player_index < state.player_discard_stacks.size():
		var prev_index: int = _prev_player_index(state, player_index)
		if prev_index >= 0 and prev_index < state.player_discard_stacks.size():
			var prev_stack: Array = state.player_discard_stacks[prev_index]
			if not prev_stack.is_empty():
				prev_stack.pop_back()
	state.turn_required_use_tile_id = tile.unique_id

func _apply_discard(state: GameState, player_index: int, action: Action) -> bool:
	var tile_id = int(action.payload.get("tile_id", -1))
	var hand = state.players[player_index].hand
	var index = _find_tile_index_by_id(hand, tile_id)
	if index == -1:
		return false
	var tile = hand[index]
	hand.remove_at(index)
	state.discard_pile.append(tile)
	if player_index >= 0 and player_index < state.player_discard_stacks.size():
		var player_stack: Array = state.player_discard_stacks[player_index]
		player_stack.append(tile)
	state.turn_required_use_tile_id = -1
	return true

func _apply_open_melds(state: GameState, player_index: int, action: Action) -> void:
	if not state.players[player_index].has_opened:
		state.players[player_index].has_opened = true
		if action.payload.has("open_by_pairs"):
			state.players[player_index].opened_by_pairs = bool(action.payload.get("open_by_pairs", false))
		if state.players[player_index].opened_by_pairs:
			state.players[player_index].opened_mode = "pairs"
		else:
			state.players[player_index].opened_mode = "melds"

	if not action.payload.has("melds"):
		return

	var melds: Array = action.payload["melds"]
	var used_ids: Array = []
	for meld in melds:
		if typeof(meld) != TYPE_DICTIONARY:
			continue
		if not meld.has("kind") or not meld.has("tile_ids"):
			continue
		var kind = int(meld["kind"])
		var tile_ids: Array = meld["tile_ids"]
		var tiles_data = _resolve_tiles_from_hand(state.players[player_index], tile_ids)
		state.table_melds.append(Meld.new(kind, tile_ids.duplicate(), tiles_data, player_index))
		for tile_id in tile_ids:
			used_ids.append(tile_id)

	_remove_tiles_from_hand(state.players[player_index], used_ids)
	# Validator guarantees that taken discard was included when required.
	if state.turn_required_use_tile_id != -1:
		state.turn_required_use_tile_id = -1

func _apply_add_to_meld(state: GameState, player_index: int, action: Action) -> void:
	if not action.payload.has("target_meld_index") or not action.payload.has("tile_ids"):
		return
	var target_index = int(action.payload["target_meld_index"])
	if target_index < 0 or target_index >= state.table_melds.size():
		return
	var tile_ids: Array = action.payload["tile_ids"]
	var meld: Meld = state.table_melds[target_index]
	var tiles_data = _resolve_tiles_from_hand(state.players[player_index], tile_ids)
	for tile_id in tile_ids:
		meld.tiles.append(tile_id)
	for t in tiles_data:
		meld.tiles_data.append(t)
	_remove_tiles_from_hand(state.players[player_index], tile_ids)
	if state.turn_required_use_tile_id != -1:
		for tile_id in tile_ids:
			if tile_id == state.turn_required_use_tile_id:
				state.turn_required_use_tile_id = -1
				break

func _apply_finish(state: GameState, player_index: int, action: Action) -> void:
	state.last_finish_all_in_one_turn = bool(action.payload.get("finish_all_in_one_turn", false))
	if not state.players[player_index].has_opened:
		var finish_by_pairs = bool(action.payload.get("finish_open_by_pairs", false))
		if action.payload.has("melds") and not action.payload.has("finish_open_by_pairs"):
			var saw_pairs = false
			var saw_melds = false
			var melds: Array = action.payload["melds"]
			for meld in melds:
				if typeof(meld) != TYPE_DICTIONARY:
					continue
				var kind = int(meld.get("kind", -1))
				if kind == Meld.Kind.PAIRS:
					saw_pairs = true
				elif kind == Meld.Kind.RUN or kind == Meld.Kind.SET:
					saw_melds = true
			if saw_pairs and not saw_melds:
				finish_by_pairs = true
		state.players[player_index].has_opened = true
		state.players[player_index].opened_by_pairs = finish_by_pairs
		if finish_by_pairs:
			state.players[player_index].opened_mode = "pairs"
		else:
			state.players[player_index].opened_mode = "melds"

	if action.payload.has("melds"):
		_apply_open_melds(state, player_index, action)

	if action.payload.has("final_discard_tile_id"):
		var tile_id = int(action.payload["final_discard_tile_id"])
		var discard_action = Action.new(Action.ActionType.DISCARD, {"tile_id": tile_id})
		if not _apply_discard(state, player_index, discard_action):
			return

	var scoring = Scoring.new()
	scoring.apply_round_scores(state, player_index)

func _remove_tiles_from_hand(player: PlayerState, tile_ids: Array) -> void:
	for tile_id in tile_ids:
		var index = _find_tile_index_by_id(player.hand, int(tile_id))
		if index != -1:
			player.hand.remove_at(index)

func _resolve_tiles_from_hand(player: PlayerState, tile_ids: Array) -> Array:
	var tiles: Array = []
	for tile_id in tile_ids:
		var index = _find_tile_index_by_id(player.hand, int(tile_id))
		if index != -1:
			tiles.append(player.hand[index])
	return tiles

func _find_tile_index_by_id(hand: Array, tile_id: int) -> int:
	for i in range(hand.size()):
		var tile = hand[i]
		if tile.unique_id == tile_id:
			return i
	return -1

func _next_player_index(state: GameState, current: int) -> int:
	return (current + 1) % state.players.size()

func _prev_player_index(state: GameState, current: int) -> int:
	return (current - 1 + state.players.size()) % state.players.size()

func _clone_state(state: GameState) -> GameState:
	var next = GameState.new()
	next.rule_config = state.rule_config
	next.okey_context = state.okey_context
	next.phase = state.phase
	next.current_player_index = state.current_player_index
	next.turn_required_use_tile_id = state.turn_required_use_tile_id
	next.last_finish_all_in_one_turn = state.last_finish_all_in_one_turn
	next.dealer_index = state.dealer_index
	next.indicator_stack_index = state.indicator_stack_index
	next.indicator_tile_index = state.indicator_tile_index
	next.draw_stack_indices = state.draw_stack_indices.duplicate(true)

	next.deck = state.deck.duplicate(true)
	next.discard_pile = state.discard_pile.duplicate(true)
	next.player_discard_stacks = []
	for stack in state.player_discard_stacks:
		var cloned_stack: Array = []
		for t in stack:
			cloned_stack.append(_clone_tile(t))
		next.player_discard_stacks.append(cloned_stack)
	next.table_melds = []
	for meld in state.table_melds:
		var cloned_ids: Array = meld.tiles.duplicate()
		var cloned_tiles: Array = []
		for t in meld.tiles_data:
			cloned_tiles.append(_clone_tile(t))
		next.table_melds.append(Meld.new(int(meld.kind), cloned_ids, cloned_tiles, int(meld.owner_index)))

	next.players = []
	for p in state.players:
		var np = PlayerState.new()
		np.hand = p.hand.duplicate(true)
		np.has_opened = p.has_opened
		np.opened_by_pairs = p.opened_by_pairs
		np.opened_mode = p.opened_mode
		np.score_total = p.score_total
		np.score_round = p.score_round
		next.players.append(np)

	return next

func _clone_tile(tile: Tile) -> Tile:
	return Tile.new(int(tile.color), int(tile.number), int(tile.kind), int(tile.unique_id))


