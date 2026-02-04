extends RefCounted
class_name Validator

func validate_action(state: GameState, player_index: int, action: Action) -> Dictionary:
	if player_index != state.current_player_index:
		return _fail("not_current_player", "Not current player")

	match action.type:
		Action.ActionType.STARTER_DISCARD:
			return _validate_starter_discard(state, player_index, action)
		Action.ActionType.DRAW_FROM_DECK:
			return _validate_draw_from_deck(state, player_index)
		Action.ActionType.TAKE_DISCARD:
			return _validate_take_discard(state, player_index)
		Action.ActionType.PEEK_DISCARD:
			return _validate_peek_discard(state, player_index)
		Action.ActionType.OPEN_MELDS:
			return _validate_open_melds(state, player_index, action)
		Action.ActionType.ADD_TO_MELD:
			return _validate_add_to_meld(state, player_index, action)
		Action.ActionType.END_PLAY:
			return _validate_end_play(state, player_index)
		Action.ActionType.DISCARD:
			return _validate_discard(state, player_index, action)
		Action.ActionType.FINISH:
			return _validate_finish(state, player_index, action)
		_:
			return _fail("unknown_action", "Unknown action type")

func _validate_starter_discard(state: GameState, player_index: int, action: Action) -> Dictionary:
	if state.phase != GameState.Phase.STARTER_DISCARD:
		return _fail("phase", "Not in STARTER_DISCARD phase")

	var player = state.players[player_index]
	if player.hand.size() != state.rule_config.starter_tiles:
		return _fail("hand_size", "Starter must have starter_tiles before discard")

	if not action.payload.has("tile_id"):
		return _fail("missing_tile_id", "tile_id required for discard")

	return _ok()

func _validate_draw_from_deck(state: GameState, player_index: int) -> Dictionary:
	if state.phase != GameState.Phase.TURN_DRAW:
		return _fail("phase", "Not in TURN_DRAW phase")

	var player = state.players[player_index]
	if player.hand.size() != state.rule_config.tiles_per_player:
		return _fail("hand_size", "Player must have tiles_per_player before draw")

	if state.deck.is_empty():
		return _fail("deck_empty", "Deck is empty")

	return _ok()

func _validate_take_discard(state: GameState, player_index: int) -> Dictionary:
	if state.phase != GameState.Phase.TURN_DRAW:
		return _fail("phase", "Not in TURN_DRAW phase")

	if state.discard_pile.is_empty():
		return _fail("discard_empty", "Discard pile is empty")

	var player = state.players[player_index]
	if player.hand.size() != state.rule_config.tiles_per_player:
		return _fail("hand_size", "Player must have tiles_per_player before draw")

	# If the player has already opened, only allow taking discard if it can be used immediately.
	if player.has_opened and state.rule_config.require_discard_take_to_be_used:
		var discard_tile = state.discard_pile[state.discard_pile.size() - 1]
		if not _can_use_discard_after_take(state, player, discard_tile):
			return _fail("cannot_use_discard", "Cannot use discard immediately")

	# If the player has not opened and must open with the discard, ensure it can form at least one meld.
	if not player.has_opened and state.rule_config.if_not_opened_discard_take_requires_open_and_includes_tile:
		var discard_tile_unopened = state.discard_pile[state.discard_pile.size() - 1]
		if not _can_open_with_discard_unopened(state, player, discard_tile_unopened):
			return _fail("cannot_use_discard", "Cannot use discard to open")

	return _ok()

func _validate_peek_discard(state: GameState, player_index: int) -> Dictionary:
	if state.phase != GameState.Phase.TURN_DRAW:
		return _fail("phase", "Not in TURN_DRAW phase")
	if state.discard_pile.is_empty():
		return _fail("discard_empty", "Discard pile is empty")
	var player = state.players[player_index]
	if player.hand.size() != state.rule_config.tiles_per_player:
		return _fail("hand_size", "Player must have tiles_per_player before draw")
	return _ok()

func _validate_open_melds(state: GameState, player_index: int, action: Action) -> Dictionary:
	if state.phase != GameState.Phase.TURN_PLAY:
		return _fail("phase", "Not in TURN_PLAY phase")

	if not action.payload.has("melds"):
		return _fail("missing_melds", "melds required")

	var melds: Array = action.payload["melds"]
	if melds.is_empty():
		return _fail("empty_melds", "At least one meld required")

	var player = state.players[player_index]
	var open_by_pairs = bool(action.payload.get("open_by_pairs", false))

	if player.has_opened and state.rule_config.open_by_pairs_locks_to_pairs:
		if player.opened_by_pairs and not open_by_pairs:
			return _fail("pairs_only", "Player opened by pairs and must continue with pairs")
		if (not player.opened_by_pairs) and open_by_pairs:
			return _fail("melds_only", "Player opened by melds and cannot open by pairs")
	var tile_by_id = {}
	for tile in player.hand:
		tile_by_id[tile.unique_id] = tile

	var used_tile_ids = {}
	var total_points = 0
	var validator = MeldValidator.new()

	if open_by_pairs and not state.rule_config.allow_open_by_five_pairs:
		return _fail("pairs_not_allowed", "Opening by pairs not allowed")

	var pair_count = 0
	for meld in melds:
		if typeof(meld) != TYPE_DICTIONARY:
			return _fail("meld_format", "Meld must be a dictionary")
		if not meld.has("kind") or not meld.has("tile_ids"):
			return _fail("meld_format", "Meld requires kind and tile_ids")

		var kind = int(meld["kind"])
		var tile_ids: Array = meld["tile_ids"]
		if tile_ids.is_empty():
			return _fail("meld_empty", "Meld has no tiles")

		for tile_id in tile_ids:
			if used_tile_ids.has(tile_id):
				return _fail("tile_reused", "Tile used in multiple melds")
			if not tile_by_id.has(tile_id):
				return _fail("tile_not_in_hand", "Tile not in hand")
			used_tile_ids[tile_id] = true

		var tiles: Array = []
		for tile_id in tile_ids:
			tiles.append(tile_by_id[tile_id])

		if open_by_pairs:
			if kind != Meld.Kind.PAIRS:
				return _fail("pairs_required", "All melds must be PAIRS when opening by pairs")
			if not _validate_pair_meld(tiles, state.okey_context):
				return _fail("invalid_pair", "Invalid pair meld")
			pair_count += 1
		else:
			if kind == Meld.Kind.PAIRS:
				return _fail("pairs_not_allowed", "Pairs not allowed when opening by melds")
			if kind == Meld.Kind.RUN:
				var res = validator.validate_run(tiles, state.okey_context)
				if not res.ok:
					return _fail(res.reason, "Invalid run meld")
				total_points += int(res.points_value)
			elif kind == Meld.Kind.SET:
				var res2 = validator.validate_set(tiles, state.okey_context)
				if not res2.ok:
					return _fail(res2.reason, "Invalid set meld")
				total_points += int(res2.points_value)
			else:
				return _fail("invalid_kind", "PAIRS not allowed unless opening by pairs")

	if open_by_pairs:
		if (not player.has_opened) and pair_count < 5:
			return _fail("not_enough_pairs", "At least 5 pairs required to open by pairs")
	else:
		if (not player.has_opened) and total_points < state.rule_config.open_min_points_initial:
			return _fail("open_points", "Not enough points to open")

	if state.turn_required_use_tile_id != -1:
		if state.rule_config.discard_take_must_be_used_always:
			if not used_tile_ids.has(state.turn_required_use_tile_id):
				return _fail("must_use_taken_tile", "Must include taken discard in melds")
		elif (not player.has_opened) and state.rule_config.if_not_opened_discard_take_requires_open_and_includes_tile:
			if not used_tile_ids.has(state.turn_required_use_tile_id):
				return _fail("must_use_taken_tile", "Must include taken discard in opening melds")

	return _ok()

func _validate_add_to_meld(state: GameState, player_index: int, action: Action) -> Dictionary:
	if state.phase != GameState.Phase.TURN_PLAY:
		return _fail("phase", "Not in TURN_PLAY phase")
	var player = state.players[player_index]
	if not player.has_opened:
		return _fail("not_opened", "Player must have opened before adding to melds")
	if not action.payload.has("target_meld_index") or not action.payload.has("tile_ids"):
		return _fail("missing_payload", "target_meld_index and tile_ids required")

	var target_index = int(action.payload["target_meld_index"])
	if target_index < 0 or target_index >= state.table_melds.size():
		return _fail("invalid_target", "Invalid target_meld_index")

	var tile_ids: Array = action.payload["tile_ids"]
	if tile_ids.is_empty():
		return _fail("empty_tiles", "No tiles provided")

	var meld: Meld = state.table_melds[target_index]
	if meld.kind == Meld.Kind.PAIRS:
		return _fail("pairs_not_extendable", "Cannot add to PAIRS meld")
	if meld.tiles_data.is_empty():
		return _fail("meld_no_tiles", "Target meld missing tile data")

	var tile_by_id = {}
	for tile in player.hand:
		tile_by_id[tile.unique_id] = tile

	var used_ids = {}
	for tile_id in tile_ids:
		if used_ids.has(tile_id):
			return _fail("tile_reused", "Tile used multiple times")
		if not tile_by_id.has(tile_id):
			return _fail("tile_not_in_hand", "Tile not in hand")
		used_ids[tile_id] = true

	var combined_tiles: Array = []
	for t in meld.tiles_data:
		combined_tiles.append(t)
	for tile_id in tile_ids:
		combined_tiles.append(tile_by_id[tile_id])

	var validator = MeldValidator.new()
	if meld.kind == Meld.Kind.RUN:
		var res = validator.validate_run(combined_tiles, state.okey_context)
		if not res.ok:
			return _fail(res.reason, "Invalid run meld")
	elif meld.kind == Meld.Kind.SET:
		var res2 = validator.validate_set(combined_tiles, state.okey_context)
		if not res2.ok:
			return _fail(res2.reason, "Invalid set meld")

	return _ok()

func _validate_end_play(state: GameState, player_index: int) -> Dictionary:
	if state.phase != GameState.Phase.TURN_PLAY:
		return _fail("phase", "Not in TURN_PLAY phase")
	var player = state.players[player_index]
	if player.hand.size() != state.rule_config.starter_tiles:
		return _fail("hand_size", "Player must have starter_tiles before ending play")
	if state.turn_required_use_tile_id != -1 and state.rule_config.discard_take_must_be_used_always:
		return _fail("must_use_taken_tile", "Must use taken discard before ending play")
	return _ok()

func _validate_discard(state: GameState, player_index: int, action: Action) -> Dictionary:
	if state.phase != GameState.Phase.TURN_DISCARD:
		return _fail("phase", "Not in TURN_DISCARD phase")

	var player = state.players[player_index]
	if player.hand.size() != state.rule_config.starter_tiles:
		return _fail("hand_size", "Player must have starter_tiles before discard")

	if not action.payload.has("tile_id"):
		return _fail("missing_tile_id", "tile_id required for discard")

	if state.turn_required_use_tile_id != -1:
		if state.rule_config.discard_take_must_be_used_always:
			return _fail("must_use_taken_tile", "Must use taken discard before discarding")
		if (not player.has_opened) and state.rule_config.if_not_opened_discard_take_requires_open_and_includes_tile:
			return _fail("must_use_taken_tile", "Must open and include taken discard before discarding")

	return _ok()

func _validate_finish(state: GameState, player_index: int, action: Action) -> Dictionary:
	if state.phase != GameState.Phase.TURN_PLAY:
		return _fail("phase", "Not in TURN_PLAY phase")
	var player = state.players[state.current_player_index]
	if player.hand.size() != state.rule_config.starter_tiles:
		return _fail("hand_size", "Player must have starter_tiles before finishing")
	var finish_all_in_one = bool(action.payload.get("finish_all_in_one_turn", false))
	if not player.has_opened and not player.opened_by_pairs and not finish_all_in_one:
		return _fail("not_opened", "Player must have opened before finishing")
	return _validate_finish_melds(state, player_index, action)

func _ok() -> Dictionary:
	return {"ok": true, "reason": "", "code": "ok"}

func _todo() -> Dictionary:
	return {"ok": false, "reason": "TODO", "code": "todo"}

func _fail(code: String, reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "code": code}

func _validate_pair_meld(tiles: Array, _okey_context) -> bool:
	if tiles.size() != 2:
		return false
	var a: Tile = tiles[0]
	var b: Tile = tiles[1]
	return a.color == b.color and a.number == b.number

func _can_use_discard_after_take(state: GameState, player, discard_tile: Tile) -> bool:
	if _can_add_tile_to_table(state, discard_tile):
		return true
	if _can_form_meld_with_tile(player.hand, discard_tile, state.okey_context):
		return true
	return false

func _can_add_tile_to_table(state: GameState, tile: Tile) -> bool:
	var discard_rules = DiscardRules.new()
	return discard_rules.is_tile_extendable_on_table(state, tile)

func _can_form_meld_with_tile(hand: Array, tile: Tile, okey_context) -> bool:
	# Pairs
	for t in hand:
		if t.color == tile.color and t.number == tile.number:
			return true

	# Check any 3-tile run or set including the discard.
	var validator = MeldValidator.new()
	for i in range(hand.size()):
		for j in range(i + 1, hand.size()):
			var tiles = [tile, hand[i], hand[j]]
			var res_run = validator.validate_run(tiles, okey_context)
			if res_run.ok:
				return true
			var res_set = validator.validate_set(tiles, okey_context)
			if res_set.ok:
				return true
	return false

func _can_form_any_meld_with_tile(hand: Array, tile: Tile, okey_context) -> bool:
	# For unopened hands we only ensure the discard can be included in at least one meld.
	return _can_form_meld_with_tile(hand, tile, okey_context)

func _can_open_with_discard_unopened(state: GameState, player, discard_tile: Tile) -> bool:
	# Opening can be by five pairs (if allowed) or by 101+ points with melds.
	if state.rule_config.allow_open_by_five_pairs:
		if _can_open_by_pairs_with_discard(player.hand, discard_tile):
			return true
	return _can_open_by_meld_points_with_discard(player.hand, discard_tile, state.okey_context, state.rule_config.open_min_points_initial)

func _can_open_by_pairs_with_discard(hand: Array, discard_tile: Tile) -> bool:
	var counts = {}
	for t in hand:
		var key = "%s-%s" % [t.color, t.number]
		counts[key] = int(counts.get(key, 0)) + 1
	var discard_key = "%s-%s" % [discard_tile.color, discard_tile.number]
	counts[discard_key] = int(counts.get(discard_key, 0)) + 1

	var discard_can_pair = int(counts.get(discard_key, 0)) >= 2
	if not discard_can_pair:
		return false

	var pair_count = 0
	for key in counts.keys():
		pair_count += int(counts[key] / 2.0)
	return pair_count >= 5

func _can_open_by_meld_points_with_discard(hand: Array, discard_tile: Tile, okey_context, min_points: int) -> bool:
	var tiles: Array = hand.duplicate()
	tiles.append(discard_tile)
	var discard_index = tiles.size() - 1

	var melds = _collect_melds_for_open(tiles, discard_index, okey_context)
	if melds.is_empty():
		return false
	# Sort by points descending to reach thresholds faster.
	melds.sort_custom(func(a, b): return int(a.points) > int(b.points))
	var suffix_max: Array = []
	suffix_max.resize(melds.size() + 1)
	suffix_max[melds.size()] = 0
	for i in range(melds.size() - 1, -1, -1):
		suffix_max[i] = int(suffix_max[i + 1]) + int(melds[i].points)
	var memo = {}
	return _can_reach_points_with_melds(melds, 0, 0, 0, false, min_points, memo, suffix_max)

func _collect_melds_for_open(tiles: Array, discard_index: int, okey_context) -> Array:
	var melds: Array = []
	var validator = MeldValidator.new()

	for size in range(3, 7):
		_collect_melds_of_size(tiles, discard_index, okey_context, size, 0, [], melds, validator)

	return melds

func _collect_melds_of_size(tiles: Array, discard_index: int, okey_context, size: int, start: int, combo: Array, out: Array, validator: MeldValidator) -> void:
	if combo.size() == size:
		var tile_list: Array = []
		var mask = 0
		var includes_discard = false
		for idx in combo:
			tile_list.append(tiles[idx])
			mask |= (1 << idx)
			if idx == discard_index:
				includes_discard = true

		var res_run = validator.validate_run(tile_list, okey_context)
		if res_run.ok:
			out.append({"mask": mask, "points": int(res_run.points_value), "includes_discard": includes_discard})
		var res_set = validator.validate_set(tile_list, okey_context)
		if res_set.ok:
			out.append({"mask": mask, "points": int(res_set.points_value), "includes_discard": includes_discard})
		return

	for i in range(start, tiles.size()):
		combo.append(i)
		_collect_melds_of_size(tiles, discard_index, okey_context, size, i + 1, combo, out, validator)
		combo.pop_back()

func _can_reach_points_with_melds(melds: Array, index: int, used_mask: int, points: int, included_discard: bool, min_points: int, memo: Dictionary, suffix_max: Array) -> bool:
	if included_discard and points >= min_points:
		return true
	if index >= melds.size():
		return false
	# Upper bound prune.
	if points + int(suffix_max[index]) < min_points and included_discard:
		return false

	var memo_key = str(index) + "|" + str(used_mask) + "|"
	if included_discard:
		memo_key += "1"
	else:
		memo_key += "0"
	if memo.has(memo_key):
		var best = int(memo[memo_key])
		if points <= best:
			return false
	memo[memo_key] = points

	# Skip meld
	if _can_reach_points_with_melds(melds, index + 1, used_mask, points, included_discard, min_points, memo, suffix_max):
		return true

	# Take meld if no overlap
	var meld = melds[index]
	var mask = int(meld.mask)
	if (used_mask & mask) == 0:
		var new_points = points + int(meld.points)
		var new_included = included_discard or bool(meld.includes_discard)
		if _can_reach_points_with_melds(melds, index + 1, used_mask | mask, new_points, new_included, min_points, memo, suffix_max):
			return true

	return false

func _validate_finish_melds(state: GameState, player_index: int, action: Action) -> Dictionary:
	if not action.payload.has("melds") or not action.payload.has("final_discard_tile_id"):
		return _fail("missing_payload", "melds and final_discard_tile_id required")

	var melds: Array = action.payload["melds"]
	var final_discard_tile_id = int(action.payload["final_discard_tile_id"])
	var finish_all_in_one = bool(action.payload.get("finish_all_in_one_turn", false))

	var player = state.players[player_index]
	var tile_by_id = {}
	for tile in player.hand:
		tile_by_id[tile.unique_id] = tile

	if not tile_by_id.has(final_discard_tile_id):
		return _fail("discard_not_in_hand", "Final discard tile not in hand")

	var used_tile_ids = {}
	var validator = MeldValidator.new()
	var saw_pairs = false
	var saw_melds = false

	for meld in melds:
		if typeof(meld) != TYPE_DICTIONARY:
			return _fail("meld_format", "Meld must be a dictionary")
		if not meld.has("kind") or not meld.has("tile_ids"):
			return _fail("meld_format", "Meld requires kind and tile_ids")

		var kind = int(meld["kind"])
		var tile_ids: Array = meld["tile_ids"]
		if tile_ids.is_empty():
			return _fail("meld_empty", "Meld has no tiles")

		for tile_id in tile_ids:
			if used_tile_ids.has(tile_id):
				return _fail("tile_reused", "Tile used in multiple melds")
			if tile_id == final_discard_tile_id:
				return _fail("discard_in_meld", "Final discard tile cannot be in melds")
			if not tile_by_id.has(tile_id):
				return _fail("tile_not_in_hand", "Tile not in hand")
			used_tile_ids[tile_id] = true

		var tiles: Array = []
		for tile_id in tile_ids:
			tiles.append(tile_by_id[tile_id])

		if kind == Meld.Kind.RUN:
			saw_melds = true
			var res = validator.validate_run(tiles, state.okey_context)
			if not res.ok:
				return _fail(res.reason, "Invalid run meld")
		elif kind == Meld.Kind.SET:
			saw_melds = true
			var res2 = validator.validate_set(tiles, state.okey_context)
			if not res2.ok:
				return _fail(res2.reason, "Invalid set meld")
		elif kind == Meld.Kind.PAIRS:
			saw_pairs = true
			if not _validate_pair_meld(tiles, state.okey_context):
				return _fail("invalid_pair", "Invalid pair meld")
		else:
			return _fail("invalid_kind", "Unknown meld kind")

	# Enforce pairs/melds lane restrictions
	if state.rule_config.open_by_pairs_locks_to_pairs:
		if player.has_opened:
			if player.opened_by_pairs and saw_melds:
				return _fail("pairs_only", "Player opened by pairs and must continue with pairs")
			if (not player.opened_by_pairs) and saw_pairs:
				return _fail("melds_only", "Player opened by melds and cannot use pairs")
		elif finish_all_in_one:
			if saw_pairs and saw_melds:
				return _fail("mixed_modes", "Cannot mix pairs with melds in finish")

	var total_used = used_tile_ids.size() + 1 # plus final discard
	if total_used != player.hand.size():
		return _fail("not_all_tiles_used", "All tiles must be melded or discarded to finish")

	# Enforce discard-take must be used in melds (cannot finish by discarding it).
	if state.turn_required_use_tile_id != -1:
		if not used_tile_ids.has(state.turn_required_use_tile_id):
			return _fail("must_use_taken_tile", "Must include taken discard in melds to finish")
		if int(state.turn_required_use_tile_id) == final_discard_tile_id:
			return _fail("must_use_taken_tile", "Taken discard cannot be the final discard")

	return _ok()
