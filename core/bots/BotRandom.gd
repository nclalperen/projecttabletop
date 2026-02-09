extends RefCounted
class_name BotRandom

var rng = RandomNumberGenerator.new()

func _init(p_seed: int = 1) -> void:
	rng.seed = p_seed

func choose_action(state, player_index: int):
	var candidates = _build_candidates(state, player_index)
	if candidates.is_empty():
		return null

	var validator = Validator.new()
	var valid_actions: Array = []
	for action in candidates:
		var res = validator.validate_action(state, player_index, action)
		if res.ok:
			valid_actions.append(action)

	if valid_actions.is_empty():
		# Fallback: always draw from deck if no valid actions were found in draw phase.
		if state.phase == state.Phase.TURN_DRAW:
			return Action.new(Action.ActionType.DRAW_FROM_DECK, {})
		return null
	# Prefer finishing immediately if legal.
	if state.phase == state.Phase.TURN_PLAY:
		for action in valid_actions:
			if int(action.type) == int(Action.ActionType.FINISH):
				return action
	# Prefer safer discards when possible.
	if state.phase == state.Phase.TURN_DISCARD:
		var safe_discards: Array = []
		for action in valid_actions:
			if action.type != Action.ActionType.DISCARD:
				continue
			var tile_id = int(action.payload.get("tile_id", -1))
			if tile_id == -1:
				continue
			if not _is_risky_discard(state, player_index, tile_id):
				safe_discards.append(action)
		if not safe_discards.is_empty():
			return safe_discards[rng.randi_range(0, safe_discards.size() - 1)]
	return valid_actions[rng.randi_range(0, valid_actions.size() - 1)]

func _build_candidates(state, player_index: int) -> Array:
	var actions: Array = []
	var player = state.players[player_index]
	match state.phase:
		state.Phase.STARTER_DISCARD:
			for tile in player.hand:
				actions.append(Action.new(Action.ActionType.STARTER_DISCARD, {"tile_id": tile.unique_id}))
		state.Phase.TURN_DRAW:
			actions.append(Action.new(Action.ActionType.DRAW_FROM_DECK, {}))
			if not state.discard_pile.is_empty():
				var discard_tile = state.discard_pile[state.discard_pile.size() - 1]
				# Allow unopened discard-take when it can be consumed immediately (validator enforces strict legality).
				var allow_take: bool = true
				if allow_take and _can_use_discard_tile(state, player, discard_tile):
					actions.append(Action.new(Action.ActionType.TAKE_DISCARD, {}))
		state.Phase.TURN_PLAY:
			if player.has_opened and not player.opened_by_pairs and player.hand.size() <= 10:
				var finish_action = _build_finish_action(state, player_index, player)
				if finish_action != null:
					actions.append(finish_action)
			if state.turn_required_use_tile_id != -1:
				var required_action = _build_required_use_action(state, player)
				if required_action != null:
					actions.append(required_action)
			actions.append(Action.new(Action.ActionType.END_PLAY, {}))
		state.Phase.TURN_DISCARD:
			for tile in player.hand:
				actions.append(Action.new(Action.ActionType.DISCARD, {"tile_id": tile.unique_id}))
			# Optionally try finish (no payload yet) - skip
			# actions.append(Action.new(Action.ActionType.FINISH, {}))
		_:
			pass
	return actions

func _can_use_discard_tile(state, player, discard_tile) -> bool:
	# Simple heuristic: can form a pair (when allowed), add to existing meld,
	# or form a basic run/set with the discard.
	var cfg = state.rule_config
	var pairs_locked = cfg != null and cfg.open_by_pairs_locks_to_pairs
	if player.opened_by_pairs and pairs_locked:
		if _has_pair_for_tile(player, discard_tile, state.okey_context):
			return true
		if _can_add_tile_to_table(state, discard_tile):
			return true
		return false
	else:
		if _has_pair_for_tile(player, discard_tile, state.okey_context) and (not pairs_locked):
			return true
	if _can_add_tile_to_table(state, discard_tile):
		return true
	if _can_form_simple_run_or_set(player, discard_tile, state.okey_context) and not (player.opened_by_pairs and pairs_locked):
		return true
	return false

func _build_required_use_action(state, player):
	var required_id = state.turn_required_use_tile_id
	var required_tile = _find_tile_by_id(player, required_id)
	if required_tile == null:
		return null

	# Prefer adding to table melds if possible.
	var add_action = _build_add_to_meld_action(state, required_tile)
	if add_action != null:
		return add_action

	# When unopened, required tile must be consumed in opening melds this turn.
	# Run a bounded exhaustive search to build a legal OPEN_MELDS payload.
	if not bool(player.has_opened):
		var open_action = _build_open_action_with_required_unopened(state, player, int(required_id))
		if open_action != null:
			return open_action

	# Try to open melds using the required tile.
	var meld_action = _build_open_meld_with_required(player, required_tile, state.okey_context)
	if meld_action != null:
		return meld_action
	return _build_required_use_exhaustive(state, player, required_tile)

func _build_open_action_with_required_unopened(state, player, required_id: int):
	if state == null or player == null:
		return null
	var validator_state = Validator.new()
	var cfg = state.rule_config

	# 1) Pairs lane (>=5 pairs) if enabled.
	if cfg != null and bool(cfg.allow_open_by_five_pairs):
		var pair_action = _build_pairs_open_action_with_required(state, player, required_id)
		if pair_action != null:
			var pair_res: Dictionary = validator_state.validate_action(state, int(state.current_player_index), pair_action)
			if bool(pair_res.get("ok", false)):
				return pair_action

	# 2) Meld lane (RUN/SET) reaching >=101 while including required tile.
	var candidates: Array = _collect_open_meld_candidates(state, player, required_id)
	if candidates.is_empty():
		return null
	candidates.sort_custom(func(a, b): return int(a.get("points", 0)) > int(b.get("points", 0)))

	var suffix_max: Array = []
	suffix_max.resize(candidates.size() + 1)
	suffix_max[candidates.size()] = 0
	for i in range(candidates.size() - 1, -1, -1):
		suffix_max[i] = int(suffix_max[i + 1]) + int(candidates[i].get("points", 0))

	var min_points: int = 101
	if cfg != null:
		min_points = int(cfg.open_min_points_initial)

	var picked: Array = []
	var success: bool = _search_open_meld_combo(candidates, 0, 0, 0, false, min_points, suffix_max, picked)
	if not success:
		return null

	var melds: Array = []
	for entry in picked:
		melds.append({"kind": int(entry.get("kind", -1)), "tile_ids": entry.get("tile_ids", []).duplicate()})
	var action = Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds, "open_by_pairs": false})
	var res: Dictionary = validator_state.validate_action(state, int(state.current_player_index), action)
	if bool(res.get("ok", false)):
		return action
	return null

func _build_pairs_open_action_with_required(state, player, required_id: int):
	var by_key := {}
	for t in player.hand:
		var key: String = _pair_key(t, state.okey_context)
		if not by_key.has(key):
			by_key[key] = []
		by_key[key].append(int(t.unique_id))

	var pair_candidates: Array = []
	for key in by_key.keys():
		var ids: Array = by_key[key]
		for i in range(ids.size()):
			for j in range(i + 1, ids.size()):
				pair_candidates.append({
					"kind": Meld.Kind.PAIRS,
					"tile_ids": [int(ids[i]), int(ids[j])],
					"mask": _ids_mask([int(ids[i]), int(ids[j])], player.hand),
					"includes_required": int(ids[i]) == required_id or int(ids[j]) == required_id,
				})
	if pair_candidates.is_empty():
		return null

	var picked: Array = []
	var success: bool = _search_pair_combo(pair_candidates, 0, 0, false, 0, picked)
	if not success:
		return null
	var melds: Array = []
	for entry in picked:
		melds.append({"kind": Meld.Kind.PAIRS, "tile_ids": entry.get("tile_ids", []).duplicate()})
	return Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds, "open_by_pairs": true})

func _search_pair_combo(candidates: Array, index: int, used_mask: int, has_required: bool, pair_count: int, out_picked: Array) -> bool:
	if has_required and pair_count >= 5:
		return true
	if index >= candidates.size():
		return false
	if pair_count + (candidates.size() - index) < 5:
		return false

	if _search_pair_combo(candidates, index + 1, used_mask, has_required, pair_count, out_picked):
		return true

	var cand: Dictionary = candidates[index]
	var mask: int = int(cand.get("mask", 0))
	if (used_mask & mask) == 0:
		out_picked.append(cand)
		if _search_pair_combo(candidates, index + 1, used_mask | mask, has_required or bool(cand.get("includes_required", false)), pair_count + 1, out_picked):
			return true
		out_picked.pop_back()
	return false

func _collect_open_meld_candidates(state, player, required_id: int) -> Array:
	var candidates: Array = []
	var validator = MeldValidator.new()
	var hand: Array = player.hand
	var has_required: bool = false
	for t in hand:
		if int(t.unique_id) == required_id:
			has_required = true
			break
	if not has_required:
		return candidates

	for size in range(3, min(6, hand.size()) + 1):
		var combo: Array = []
		_collect_meld_candidates_recursive(hand, state.okey_context, validator, required_id, size, 0, combo, candidates)
	return candidates

func _collect_meld_candidates_recursive(hand: Array, okey_context, validator: MeldValidator, required_id: int, target_size: int, start: int, combo: Array, out: Array) -> void:
	if combo.size() == target_size:
		var tiles: Array = []
		var tile_ids: Array = []
		var includes_required: bool = false
		for idx in combo:
			var t = hand[int(idx)]
			tiles.append(t)
			var uid: int = int(t.unique_id)
			tile_ids.append(uid)
			if uid == required_id:
				includes_required = true
		var run_res: Dictionary = validator.validate_run(tiles, okey_context)
		if bool(run_res.get("ok", false)):
			out.append({
				"kind": Meld.Kind.RUN,
				"tile_ids": tile_ids,
				"points": int(run_res.get("points_value", 0)),
				"mask": _ids_mask(tile_ids, hand),
				"includes_required": includes_required,
			})
		var set_res: Dictionary = validator.validate_set(tiles, okey_context)
		if bool(set_res.get("ok", false)):
			out.append({
				"kind": Meld.Kind.SET,
				"tile_ids": tile_ids,
				"points": int(set_res.get("points_value", 0)),
				"mask": _ids_mask(tile_ids, hand),
				"includes_required": includes_required,
			})
		return

	for i in range(start, hand.size()):
		combo.append(i)
		_collect_meld_candidates_recursive(hand, okey_context, validator, required_id, target_size, i + 1, combo, out)
		combo.pop_back()

func _search_open_meld_combo(candidates: Array, index: int, used_mask: int, points: int, has_required: bool, min_points: int, suffix_max: Array, out_picked: Array) -> bool:
	if has_required and points >= min_points:
		return true
	if index >= candidates.size():
		return false
	if points + int(suffix_max[index]) < min_points:
		return false

	if _search_open_meld_combo(candidates, index + 1, used_mask, points, has_required, min_points, suffix_max, out_picked):
		return true

	var cand: Dictionary = candidates[index]
	var mask: int = int(cand.get("mask", 0))
	if (used_mask & mask) == 0:
		out_picked.append(cand)
		if _search_open_meld_combo(
			candidates,
			index + 1,
			used_mask | mask,
			points + int(cand.get("points", 0)),
			has_required or bool(cand.get("includes_required", false)),
			min_points,
			suffix_max,
			out_picked
		):
			return true
		out_picked.pop_back()
	return false

func _ids_mask(ids: Array, hand: Array) -> int:
	var mask: int = 0
	for id in ids:
		for i in range(hand.size()):
			if int(hand[i].unique_id) == int(id):
				mask |= (1 << i)
				break
	return mask

func _build_add_to_meld_action(state, tile):
	var validator = Validator.new()
	for i in range(state.table_melds.size()):
		var meld = state.table_melds[i]
		if meld.kind == Meld.Kind.PAIRS:
			continue
		if meld.tiles_data.is_empty():
			continue
		var action = Action.new(Action.ActionType.ADD_TO_MELD, {"target_meld_index": i, "tile_ids": [tile.unique_id]})
		var res: Dictionary = validator.validate_action(state, int(state.current_player_index), action)
		if bool(res.get("ok", false)):
			return action
	return null

func _build_open_meld_with_required(player, required_tile, okey_context = null):
	# Try pair
	for t in player.hand:
		if t.unique_id == required_tile.unique_id:
			continue
		if _pair_key(t, okey_context) == _pair_key(required_tile, okey_context):
			var melds = [{"kind": Meld.Kind.PAIRS, "tile_ids": [required_tile.unique_id, t.unique_id]}]
			return Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds, "open_by_pairs": true})

	# Try set (same number, distinct colors)
	var set_ids: Array = [required_tile.unique_id]
	var colors = {required_tile.color: true}
	for t in player.hand:
		if t.unique_id == required_tile.unique_id:
			continue
		if t.number == required_tile.number and not colors.has(t.color):
			colors[t.color] = true
			set_ids.append(t.unique_id)
			if set_ids.size() >= 3:
				var melds = [{"kind": Meld.Kind.SET, "tile_ids": set_ids}]
				return Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds})

	# Try run (same color consecutive, simple length 3)
	var run_ids = _build_simple_run_ids(player, required_tile)
	if run_ids.size() >= 3:
		var melds2 = [{"kind": Meld.Kind.RUN, "tile_ids": run_ids}]
		return Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds2})

	return null

func _build_simple_run_ids(player, required_tile) -> Array:
	var numbers = {}
	for t in player.hand:
		if t.color == required_tile.color:
			numbers[t.number] = t.unique_id
	var n = required_tile.number
	var candidates = [
		[n - 2, n - 1, n],
		[n - 1, n, n + 1],
		[n, n + 1, n + 2],
	]
	for seq in candidates:
		var ok = true
		var ids: Array = []
		for num in seq:
			if num < 1 or num > 13 or not numbers.has(num):
				ok = false
				break
			ids.append(numbers[num])
		if ok:
			return ids
	return []

func _can_form_simple_run_or_set(player, required_tile, okey_context = null) -> bool:
	return _build_open_meld_with_required(player, required_tile, okey_context) != null

func _has_pair_for_tile(player, required_tile, okey_context = null) -> bool:
	for t in player.hand:
		if t.unique_id == required_tile.unique_id:
			continue
		if _pair_key(t, okey_context) == _pair_key(required_tile, okey_context):
			return true
	return false

func _can_add_tile_to_table(state, tile) -> bool:
	var discard_rules = DiscardRules.new()
	return discard_rules.is_tile_extendable_on_table(state, tile)

func _find_tile_by_id(player, tile_id: int):
	for t in player.hand:
		if t.unique_id == tile_id:
			return t
	return null

func _build_required_use_exhaustive(state, player, required_tile):
	var validator = MeldValidator.new()
	var n: int = player.hand.size()
	for i in range(n):
		var a = player.hand[i]
		if int(a.unique_id) == int(required_tile.unique_id):
			continue
		for j in range(i + 1, n):
			var b = player.hand[j]
			if int(b.unique_id) == int(required_tile.unique_id):
				continue
			var tiles: Array = [required_tile, a, b]
			var ids: Array = [int(required_tile.unique_id), int(a.unique_id), int(b.unique_id)]
			var run_res: Dictionary = validator.validate_run(tiles, state.okey_context)
			if bool(run_res.get("ok", false)):
				return Action.new(Action.ActionType.OPEN_MELDS, {"melds": [{"kind": Meld.Kind.RUN, "tile_ids": ids}], "open_by_pairs": false})
			var set_res: Dictionary = validator.validate_set(tiles, state.okey_context)
			if bool(set_res.get("ok", false)):
				return Action.new(Action.ActionType.OPEN_MELDS, {"melds": [{"kind": Meld.Kind.SET, "tile_ids": ids}], "open_by_pairs": false})
	return null

func _pair_key(tile, okey_context) -> String:
	if tile.kind == Tile.Kind.FAKE_OKEY and okey_context != null:
		return "%d-%d" % [int(okey_context.okey_color), int(okey_context.okey_number)]
	return "%d-%d" % [int(tile.color), int(tile.number)]

func _is_risky_discard(state, player_index: int, tile_id: int) -> bool:
	var player = state.players[player_index]
	var tile = _find_tile_by_id(player, tile_id)
	if tile == null:
		return false
	var discard_joker = state.okey_context.is_real_okey(tile)
	var discard_rules = DiscardRules.new()
	var extendable = discard_rules.is_tile_extendable_on_table(state, tile)
	return discard_joker or extendable

func _build_finish_action(state, _player_index: int, player):
	if not player.has_opened:
		return null
	if player.opened_by_pairs:
		return null
	if player.hand.size() < 2:
		return null

	for discard_tile in player.hand:
		var remaining: Array = []
		for t in player.hand:
			if int(t.unique_id) != int(discard_tile.unique_id):
				remaining.append(t)
		var melds: Array = []
		if _partition_finish_melds(remaining, state.okey_context, melds):
			return Action.new(Action.ActionType.FINISH, {
				"melds": melds,
				"final_discard_tile_id": int(discard_tile.unique_id),
				"finish_all_in_one_turn": false,
			})
	return null

func _partition_finish_melds(tiles: Array, okey_context, out_melds: Array) -> bool:
	if tiles.is_empty():
		return true
	if tiles.size() < 3:
		return false
	var validator = MeldValidator.new()
	var n: int = tiles.size()
	for size in range(3, min(6, n) + 1):
		var combos: Array = []
		_collect_index_combos_including_first(n, size, 1, [0], combos)
		for combo in combos:
			var group_tiles: Array = []
			var group_ids: Array = []
			for idx in combo:
				var t = tiles[int(idx)]
				group_tiles.append(t)
				group_ids.append(int(t.unique_id))
			var run_res: Dictionary = validator.validate_run(group_tiles, okey_context)
			var set_res: Dictionary = validator.validate_set(group_tiles, okey_context)
			var kind: int = -1
			if bool(run_res.get("ok", false)):
				kind = Meld.Kind.RUN
			elif bool(set_res.get("ok", false)):
				kind = Meld.Kind.SET
			if kind == -1:
				continue
			var rest: Array = []
			for t in tiles:
				if not group_ids.has(int(t.unique_id)):
					rest.append(t)
			out_melds.append({"kind": kind, "tile_ids": group_ids})
			if _partition_finish_melds(rest, okey_context, out_melds):
				return true
			out_melds.pop_back()
	return false

func _collect_index_combos_including_first(n: int, size: int, start: int, current: Array, out: Array) -> void:
	if current.size() == size:
		out.append(current.duplicate())
		return
	for i in range(start, n):
		current.append(i)
		_collect_index_combos_including_first(n, size, i + 1, current, out)
		current.pop_back()


