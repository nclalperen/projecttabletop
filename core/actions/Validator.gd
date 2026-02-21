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
		Action.ActionType.PLACE_TILES:
			return _validate_place_tiles(state, player_index, action)
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

func _validate_place_tiles(state: GameState, player_index: int, action: Action) -> Dictionary:
	if state.phase != GameState.Phase.TURN_PLAY:
		return _fail("phase", "Not in TURN_PLAY phase")
	if not action.payload.has("placements"):
		return _fail("missing_placements", "placements required")
	var placements: Array = action.payload["placements"]
	if placements.is_empty():
		return _fail("empty_placements", "At least one placement is required")

	var player = state.players[player_index]
	var create_melds: Array = []
	var add_ops: Array = []
	var used_tile_ids := {}

	var open_mode_raw: String = String(action.payload.get("open_mode", ""))
	var open_mode: String = open_mode_raw.strip_edges().to_upper()
	var open_by_pairs: bool = false
	if open_mode == "DOUBLES":
		open_by_pairs = true
	elif open_mode == "SETS_RUNS":
		open_by_pairs = false

	for placement in placements:
		if typeof(placement) != TYPE_DICTIONARY:
			return _fail("placement_format", "Each placement must be a dictionary")
		var op: String = String(placement.get("op", "")).strip_edges().to_upper()
		if op == "CREATE_MELD":
			var meld_type: String = String(placement.get("meld_type", "")).strip_edges().to_upper()
			var tile_ids: Array = placement.get("tiles", [])
			if tile_ids.is_empty():
				return _fail("empty_tiles", "CREATE_MELD requires tiles")
			var kind: int = -1
			if meld_type == "SET":
				kind = Meld.Kind.SET
			elif meld_type == "RUN":
				kind = Meld.Kind.RUN
			elif meld_type == "PAIRS" or meld_type == "PAIR":
				kind = Meld.Kind.PAIRS
			else:
				return _fail("invalid_meld_type", "Unknown meld_type")
			if kind == Meld.Kind.PAIRS:
				open_by_pairs = true
			for tile_id in tile_ids:
				if used_tile_ids.has(tile_id):
					return _fail("tile_reused", "Tile used in multiple placements")
				used_tile_ids[tile_id] = true
			create_melds.append({"kind": kind, "tile_ids": tile_ids.duplicate()})
		elif op == "ADD_TO_MELD":
			var meld_ref: Dictionary = placement.get("meld_ref", {})
			if typeof(meld_ref) != TYPE_DICTIONARY:
				return _fail("invalid_meld_ref", "ADD_TO_MELD requires meld_ref dictionary")
			if not meld_ref.has("index"):
				return _fail("invalid_meld_ref", "meld_ref.index required")
			var target_index: int = int(meld_ref.get("index", -1))
			var add_tile_ids: Array = placement.get("tiles", [])
			if add_tile_ids.is_empty():
				return _fail("empty_tiles", "ADD_TO_MELD requires tiles")
			for tile_id in add_tile_ids:
				if used_tile_ids.has(tile_id):
					return _fail("tile_reused", "Tile used in multiple placements")
				used_tile_ids[tile_id] = true
			add_ops.append({"target_meld_index": target_index, "tile_ids": add_tile_ids.duplicate()})
		else:
			return _fail("invalid_op", "Unknown placement op")

	var declare_open: bool = bool(action.payload.get("declare_open", false))
	var treat_as_open: bool = declare_open or (not player.has_opened and not create_melds.is_empty())
	if treat_as_open and create_melds.is_empty():
		return _fail("missing_melds", "Opening requires CREATE_MELD placements")

	if not open_mode_raw.is_empty() and open_mode != "SETS_RUNS" and open_mode != "DOUBLES":
		return _fail("invalid_open_mode", "open_mode must be SETS_RUNS or DOUBLES")

	if not create_melds.is_empty():
		var open_action := Action.new(Action.ActionType.OPEN_MELDS, {
			"melds": create_melds,
			"open_by_pairs": open_by_pairs,
		})
		var create_res: Dictionary = _validate_open_melds(state, player_index, open_action)
		if not bool(create_res.get("ok", false)):
			return create_res

	if add_ops.is_empty():
		return _ok()
	return _validate_add_ops_for_place_tiles(state, player_index, add_ops, treat_as_open, open_by_pairs)

func _validate_add_ops_for_place_tiles(state: GameState, player_index: int, add_ops: Array, treat_as_open: bool, open_by_pairs: bool) -> Dictionary:
	var player = state.players[player_index]
	var old_opened: bool = player.has_opened
	var old_opened_by_pairs: bool = player.opened_by_pairs

	if treat_as_open and not player.has_opened:
		player.has_opened = true
		player.opened_by_pairs = open_by_pairs

	for op in add_ops:
		var add_action := Action.new(Action.ActionType.ADD_TO_MELD, op)
		var add_res: Dictionary = _validate_add_to_meld(state, player_index, add_action)
		if not bool(add_res.get("ok", false)):
			player.has_opened = old_opened
			player.opened_by_pairs = old_opened_by_pairs
			return add_res

	player.has_opened = old_opened
	player.opened_by_pairs = old_opened_by_pairs
	return _ok()

func _validate_starter_discard(state: GameState, player_index: int, action: Action) -> Dictionary:
	if state.phase != GameState.Phase.STARTER_DISCARD:
		return _fail("phase", "Not in STARTER_DISCARD phase")

	var player = state.players[player_index]
	if player.hand.size() != state.rule_config.starter_tiles:
		return _fail("hand_size", "Starter must have starter_tiles before discard")

	if not action.payload.has("tile_id"):
		return _fail("missing_tile_id", "tile_id required for discard")
	var tile_id = int(action.payload.get("tile_id", -1))
	var found = false
	for t in player.hand:
		if t.unique_id == tile_id:
			found = true
			break
	if not found:
		return _fail("tile_not_in_hand", "Discard tile not in hand")

	return _ok()

func _validate_draw_from_deck(state: GameState, player_index: int) -> Dictionary:
	if state.phase != GameState.Phase.TURN_DRAW:
		return _fail("phase", "Not in TURN_DRAW phase")

	var player = state.players[player_index]
	if player.hand.size() >= state.rule_config.starter_tiles:
		return _fail("hand_size", "Player cannot draw with starter_tiles or more tiles in hand")

	if state.deck.is_empty():
		return _fail("deck_empty", "Deck is empty")

	return _ok()

func _validate_take_discard(state: GameState, player_index: int) -> Dictionary:
	if state.phase != GameState.Phase.TURN_DRAW:
		return _fail("phase", "Not in TURN_DRAW phase")

	if state.discard_pile.is_empty():
		return _fail("discard_empty", "Discard pile is empty")

	var player = state.players[player_index]
	if player.hand.size() >= state.rule_config.starter_tiles:
		return _fail("hand_size", "Player cannot take discard with starter_tiles or more tiles in hand")

	# If the player has already opened, only allow taking discard if it can be used immediately.
	if player.has_opened and _must_use_taken_discard_always(state):
		var discard_tile = state.discard_pile[state.discard_pile.size() - 1]
		if not _can_use_discard_after_take(state, player, discard_tile):
			return _fail("cannot_use_discard", "Cannot use discard immediately")

	# If the player has not opened and must open with the discard, ensure it can form at least one meld.
	if not player.has_opened and state.rule_config.if_not_opened_discard_take_requires_open_and_includes_tile:
		var discard_tile_unopened = state.discard_pile[state.discard_pile.size() - 1]
		if not _can_open_with_discard_unopened(state, player, discard_tile_unopened):
			return _fail("cannot_use_discard", "Cannot use discard to open")

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

	# SeOkey11 dossier: opening by pairs is a one-time opening lane; after that, no new meld creation.
	if player.has_opened and player.opened_by_pairs:
		return _fail("pairs_locked", "Player opened by pairs and cannot create new melds")
	if player.has_opened and open_by_pairs:
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
		if _must_use_taken_discard_always(state):
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
	if player.hand.is_empty():
		return _fail("hand_empty", "Player must have at least one tile to discard")
	if state.turn_required_use_tile_id != -1 and _must_use_taken_discard_always(state):
		return _fail("must_use_taken_tile", "Must use taken discard before ending play")
	if state.turn_required_use_tile_id != -1 and (not player.has_opened) and state.rule_config.if_not_opened_discard_take_requires_open_and_includes_tile:
		return _fail("must_use_taken_tile", "Must open and include taken discard before ending play")
	return _ok()

func _validate_discard(state: GameState, player_index: int, action: Action) -> Dictionary:
	if state.phase != GameState.Phase.TURN_DISCARD:
		return _fail("phase", "Not in TURN_DISCARD phase")

	var player = state.players[player_index]
	if player.hand.is_empty():
		return _fail("hand_empty", "Player must have at least one tile to discard")

	if not action.payload.has("tile_id"):
		return _fail("missing_tile_id", "tile_id required for discard")
	var tile_id = int(action.payload.get("tile_id", -1))
	var found = false
	for t in player.hand:
		if t.unique_id == tile_id:
			found = true
			break
	if not found:
		return _fail("tile_not_in_hand", "Discard tile not in hand")

	# Finishing is by discarding the last tile; require the player to have opened.
	if player.hand.size() == 1 and not player.has_opened:
		return _fail("not_opened", "Player must have opened before finishing by discard")

	if state.turn_required_use_tile_id != -1:
		if _must_use_taken_discard_always(state):
			return _fail("must_use_taken_tile", "Must use taken discard before discarding")
		if (not player.has_opened) and state.rule_config.if_not_opened_discard_take_requires_open_and_includes_tile:
			return _fail("must_use_taken_tile", "Must open and include taken discard before discarding")

	return _ok()

func _validate_finish(state: GameState, player_index: int, action: Action) -> Dictionary:
	if state.phase != GameState.Phase.TURN_PLAY:
		return _fail("phase", "Not in TURN_PLAY phase")
	var player = state.players[player_index]
	# SeOkey11 dossier: finishing requires having opened, and is done by discarding the last tile.
	if not player.has_opened:
		return _fail("not_opened", "Player must have opened before finishing")
	# Players who opened by pairs cannot create new melds; they finish via layoffs + final discard.
	if player.opened_by_pairs:
		return _fail("pairs_locked", "Player opened by pairs and cannot finish by creating melds")
	return _validate_finish_melds(state, player_index, action)

func _ok() -> Dictionary:
	return {"ok": true, "reason": "", "code": "ok"}

func _fail(code: String, reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "code": code}

func _validate_pair_meld(tiles: Array, _okey_context) -> bool:
	if tiles.size() != 2:
		return false
	var a: Tile = tiles[0]
	var b: Tile = tiles[1]
	var a_key: String = _effective_pair_key(a, _okey_context)
	var b_key: String = _effective_pair_key(b, _okey_context)
	return a_key == b_key

func _can_use_discard_after_take(state: GameState, player, discard_tile: Tile) -> bool:
	if _can_add_tile_to_table(state, discard_tile):
		return true
	# Players who opened by pairs cannot create new melds; only layoffs are allowed.
	if player.opened_by_pairs:
		return false
	return _can_form_meld_with_tile(player.hand, discard_tile, state.okey_context)

func _can_add_tile_to_table(state: GameState, tile: Tile) -> bool:
	var discard_rules = DiscardRules.new()
	return discard_rules.is_tile_extendable_on_table(state, tile)

func _can_form_meld_with_tile(hand: Array, tile: Tile, okey_context) -> bool:
	# Check any 3-tile run or set including the tile.
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

func _can_open_with_discard_unopened(state: GameState, player, discard_tile: Tile) -> bool:
	# Opening can be by five pairs (if allowed) or by 101+ points with melds.
	if state.rule_config.allow_open_by_five_pairs:
		if _can_open_by_pairs_with_discard(player.hand, discard_tile, state.okey_context):
			return true
	return _can_open_by_meld_points_with_discard(player.hand, discard_tile, state.okey_context, state.rule_config.open_min_points_initial)

func _can_open_by_pairs_with_discard(hand: Array, discard_tile: Tile, okey_context) -> bool:
	var counts = {}
	for t in hand:
		var key: String = _effective_pair_key(t, okey_context)
		counts[key] = int(counts.get(key, 0)) + 1
	var discard_key: String = _effective_pair_key(discard_tile, okey_context)
	counts[discard_key] = int(counts.get(discard_key, 0)) + 1

	var discard_can_pair = int(counts.get(discard_key, 0)) >= 2
	if not discard_can_pair:
		return false

	var pair_count = 0
	for key in counts.keys():
		pair_count += int(counts[key] / 2.0)
	return pair_count >= 5

func _effective_pair_key(tile: Tile, okey_context) -> String:
	if tile.kind == Tile.Kind.FAKE_OKEY and okey_context != null:
		return "%s-%s" % [int(okey_context.okey_color), int(okey_context.okey_number)]
	return "%s-%s" % [int(tile.color), int(tile.number)]

func _can_open_by_meld_points_with_discard(hand: Array, discard_tile: Tile, okey_context, min_points: int) -> bool:
	var tiles: Array = hand.duplicate()
	tiles.append(discard_tile)
	var discard_index = tiles.size() - 1

	var melds = _collect_melds_for_open(tiles, discard_index, okey_context)
	if melds.is_empty():
		return false
	var has_discard_meld = false
	for m in melds:
		if bool(m.includes_discard):
			has_discard_meld = true
			break
	if not has_discard_meld:
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
		if _must_use_taken_discard_always(state) and not used_tile_ids.has(state.turn_required_use_tile_id):
			return _fail("must_use_taken_tile", "Must include taken discard in melds to finish")
		if int(state.turn_required_use_tile_id) == final_discard_tile_id:
			return _fail("must_use_taken_tile", "Taken discard cannot be the final discard")

	return _ok()

func _must_use_taken_discard_always(state: GameState) -> bool:
	if state == null or state.rule_config == null:
		return true
	return bool(state.rule_config.require_discard_take_to_be_used) and bool(state.rule_config.discard_take_must_be_used_always)
