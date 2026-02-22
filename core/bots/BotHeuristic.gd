extends RefCounted
class_name BotHeuristic

func choose_action(state, player_index: int):
	var validator = Validator.new()
	var player = state.players[player_index]

	match state.phase:
		state.Phase.STARTER_DISCARD:
			return _choose_starter_discard(state, player)
		state.Phase.TURN_DRAW:
			if not state.discard_pile.is_empty():
				var discard_tile = state.discard_pile[state.discard_pile.size() - 1]
				var can_take = validator.validate_action(state, player_index, Action.new(Action.ActionType.TAKE_DISCARD, {})).ok
				if can_take:
					if player.has_opened:
						var can_layoff_now = _can_add_tile_to_table(state, discard_tile)
						if can_layoff_now and _prefer_take_discard(state, player, discard_tile):
							return Action.new(Action.ActionType.TAKE_DISCARD, {})
					# Unopened discard-take is strategically expensive and can dead-lock weak bot lines.
					# Keep it only as a fallback when deck is exhausted.
					elif state.deck.is_empty() and _prefer_take_discard_unopened(state, player, discard_tile):
						return Action.new(Action.ActionType.TAKE_DISCARD, {})
			return Action.new(Action.ActionType.DRAW_FROM_DECK, {})
		state.Phase.TURN_PLAY:
			if state.turn_required_use_tile_id != -1:
				var required_action = _build_required_use_action(state, player_index, player)
				if required_action != null:
					var req_res = validator.validate_action(state, player_index, required_action)
					if req_res.ok:
						return required_action
				if player.has_opened and not player.opened_by_pairs:
					var opened_required = _build_opened_meld_action(state, player, int(state.turn_required_use_tile_id))
					if opened_required != null:
						var opened_req_res = validator.validate_action(state, player_index, opened_required)
						if opened_req_res.ok:
							return opened_required
			if not player.has_opened:
				var open_action = _try_open(player, state)
				if open_action != null:
					var res = validator.validate_action(state, player_index, open_action)
					if res.ok:
						return open_action
			elif not player.opened_by_pairs:
				if player.hand.size() <= 10:
					var finish_action = _build_finish_action(state, player_index, player)
					if finish_action != null:
						var finish_res = validator.validate_action(state, player_index, finish_action)
						if finish_res.ok:
							return finish_action
				var opened_action = _build_opened_meld_action(state, player, -1)
				if opened_action != null:
					var opened_res = validator.validate_action(state, player_index, opened_action)
					if opened_res.ok:
						return opened_action
			return Action.new(Action.ActionType.END_PLAY, {})
		state.Phase.TURN_DISCARD:
			return _choose_discard(state, player)
		_:
			return null

func _choose_starter_discard(state, player):
	# For starter discard, use same logic but return STARTER_DISCARD action
	var tile = _select_best_discard_tile(state, player)
	if tile == null:
		return null
	return Action.new(Action.ActionType.STARTER_DISCARD, {"tile_id": tile.unique_id})

func _choose_discard(state, player):
	# For regular turn discard
	var tile = _select_best_discard_tile(state, player)
	if tile == null:
		return null
	return Action.new(Action.ActionType.DISCARD, {"tile_id": tile.unique_id})

func _select_best_discard_tile(state, player):
	# Discard least useful tile, avoiding penalties
	var best = null
	var best_penalty = true
	var best_usefulness = 9999
	var discard_rules = DiscardRules.new()
	for t in player.hand:
		var is_joker = state.okey_context.is_real_okey(t)
		var extendable = discard_rules.is_tile_extendable_on_table(state, t)
		var penalty = is_joker or extendable
		var usefulness = _tile_usefulness(state, player, t)
		if best == null:
			best = t
			best_penalty = penalty
			best_usefulness = usefulness
			continue
		if best_penalty and not penalty:
			best = t
			best_penalty = penalty
			best_usefulness = usefulness
			continue
		if best_penalty == penalty:
			if usefulness < best_usefulness:
				best = t
				best_usefulness = usefulness
				continue
			if usefulness == best_usefulness and t.number > best.number:
				best = t
				best_usefulness = usefulness
	return best

func _tile_usefulness(state, player, tile) -> int:
	# Lower is better for discard.
	if tile.kind == tile.Kind.FAKE_OKEY or state.okey_context.is_real_okey(tile):
		return 1000
	var score = 0
	for t in player.hand:
		if t.unique_id == tile.unique_id:
			continue
		if t.number == tile.number and t.color != tile.color:
			score += 2
		if t.color == tile.color and (t.number == tile.number - 1 or t.number == tile.number + 1):
			score += 2
	return score

func _try_open(player, state):
	# Prefer 5 pairs if available
	var pairs_melds = _find_pairs(player, state.okey_context)
	if pairs_melds.size() >= 5:
		var open_melds = pairs_melds.slice(0, 5)
		return Action.new(Action.ActionType.OPEN_MELDS, {"melds": open_melds, "open_by_pairs": true})

	# Otherwise try sets/runs to reach 101 using greedy melds
	var melds = []
	var points = 0
	var used_ids = {}

	var sets = _find_sets(player, used_ids)
	for m in sets:
		melds.append(m)
		points += m.get("points", 0)
		for id in m.tile_ids:
			used_ids[id] = true
		if points >= 101:
			if _should_open(points, state, player):
				return Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds})
			return null

	var runs = _find_runs(player, used_ids)
	for m in runs:
		melds.append(m)
		points += m.get("points", 0)
		for id in m.tile_ids:
			used_ids[id] = true
		if points >= 101:
			if _should_open(points, state, player):
				return Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds})
			return null

	var exhaustive_action = _try_open_exhaustive(player, state)
	if exhaustive_action != null:
		return exhaustive_action

	return null

func _should_open(points: int, state, _player) -> bool:
	var min_points: int = 101
	if state != null and state.rule_config != null:
		min_points = int(state.rule_config.open_min_points_initial)
	if points < min_points:
		return false
	# Open as soon as legal; previous conservative gating made bots appear inert.
	return true

func _try_open_exhaustive(player, state):
	if player == null or state == null:
		return null
	var hand: Array = player.hand
	if hand.size() < 3:
		return null
	var min_points: int = 101
	if state.rule_config != null:
		min_points = int(state.rule_config.open_min_points_initial)
	var candidates: Array = _collect_open_candidates_all(hand, state.okey_context)
	if candidates.is_empty():
		return null
	candidates.sort_custom(func(a, b): return int(a.get("points", 0)) > int(b.get("points", 0)))
	var suffix_max: Array = []
	suffix_max.resize(candidates.size() + 1)
	suffix_max[candidates.size()] = 0
	for i in range(candidates.size() - 1, -1, -1):
		suffix_max[i] = int(suffix_max[i + 1]) + int(candidates[i].get("points", 0))
	var picked: Array = []
	if not _search_open_combo_all(candidates, 0, 0, 0, min_points, suffix_max, picked):
		return null
	var melds: Array = []
	for entry in picked:
		melds.append({"kind": int(entry.get("kind", -1)), "tile_ids": entry.get("tile_ids", []).duplicate()})
	if melds.is_empty():
		return null
	return Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds, "open_by_pairs": false})

func _collect_open_candidates_all(hand: Array, okey_context) -> Array:
	var out: Array = []
	if hand.is_empty():
		return out
	var id_to_idx: Dictionary = {}
	for i in range(hand.size()):
		id_to_idx[int(hand[i].unique_id)] = i
	var validator := MeldValidator.new()
	for size in range(3, min(6, hand.size()) + 1):
		var combos: Array = []
		_collect_index_combos(hand.size(), size, 0, [], combos)
		for combo in combos:
			var tiles: Array = []
			var tile_ids: Array = []
			for idx in combo:
				var t = hand[int(idx)]
				tiles.append(t)
				tile_ids.append(int(t.unique_id))
			var run_res: Dictionary = validator.validate_run(tiles, okey_context)
			if bool(run_res.get("ok", false)):
				out.append({
					"kind": Meld.Kind.RUN,
					"tile_ids": tile_ids,
					"points": int(run_res.get("points_value", 0)),
					"mask": _ids_mask_for_open(tile_ids, id_to_idx),
				})
			var set_res: Dictionary = validator.validate_set(tiles, okey_context)
			if bool(set_res.get("ok", false)):
				out.append({
					"kind": Meld.Kind.SET,
					"tile_ids": tile_ids,
					"points": int(set_res.get("points_value", 0)),
					"mask": _ids_mask_for_open(tile_ids, id_to_idx),
				})
	return out

func _ids_mask_for_open(tile_ids: Array, id_to_idx: Dictionary) -> int:
	var mask: int = 0
	for tid in tile_ids:
		var idx: int = int(id_to_idx.get(int(tid), -1))
		if idx >= 0 and idx < 31:
			mask |= (1 << idx)
	return mask

func _search_open_combo_all(candidates: Array, index: int, used_mask: int, points: int, min_points: int, suffix_max: Array, out_picked: Array) -> bool:
	if points >= min_points:
		return true
	if index >= candidates.size():
		return false
	if points + int(suffix_max[index]) < min_points:
		return false
	if _search_open_combo_all(candidates, index + 1, used_mask, points, min_points, suffix_max, out_picked):
		return true
	var cand: Dictionary = candidates[index]
	var mask: int = int(cand.get("mask", 0))
	if (used_mask & mask) == 0:
		out_picked.append(cand)
		if _search_open_combo_all(
			candidates,
			index + 1,
			used_mask | mask,
			points + int(cand.get("points", 0)),
			min_points,
			suffix_max,
			out_picked
		):
			return true
		out_picked.pop_back()
	return false

func _can_use_discard_tile(state, player, discard_tile) -> bool:
	if not player.has_opened:
		# Permit taking discard if immediate open is plausible.
		return _can_form_simple_run_or_set(player, discard_tile, state.okey_context) or _has_pair_for_tile(player, discard_tile, state.okey_context)

	var cfg = state.rule_config
	var pairs_locked = cfg != null and cfg.open_by_pairs_locks_to_pairs
	if player.opened_by_pairs and pairs_locked:
		return _has_pair_for_tile(player, discard_tile, state.okey_context) or _can_add_tile_to_table(state, discard_tile)

	if _has_pair_for_tile(player, discard_tile, state.okey_context):
		return true
	if _can_add_tile_to_table(state, discard_tile):
		return true
	if _can_form_simple_run_or_set(player, discard_tile, state.okey_context):
		return true
	return false

func _prefer_take_discard(state, player, discard_tile) -> bool:
	var deck_remaining = state.deck.size()
	if deck_remaining <= 6:
		return true
	return _discard_value(state, player, discard_tile) >= 4

func _discard_value(state, player, discard_tile) -> int:
	var value = 0
	if state.okey_context.is_real_okey(discard_tile):
		value += 3
	for t in player.hand:
		if t.unique_id == discard_tile.unique_id:
			continue
		if t.number == discard_tile.number and t.color == discard_tile.color:
			value += 3
		elif t.number == discard_tile.number and t.color != discard_tile.color:
			value += 2
		elif t.color == discard_tile.color and (t.number == discard_tile.number - 1 or t.number == discard_tile.number + 1):
			value += 1
	return value

func _prefer_take_discard_unopened(state, player, discard_tile) -> bool:
	var deck_remaining: int = state.deck.size()
	if deck_remaining <= 10:
		return true
	var value: int = _discard_value(state, player, discard_tile)
	return value >= 3

func _can_add_tile_to_table(state, tile) -> bool:
	var discard_rules = DiscardRules.new()
	return discard_rules.is_tile_extendable_on_table(state, tile)

func _can_form_simple_run_or_set(player, required_tile, okey_context = null) -> bool:
	return _build_open_meld_with_required(player, required_tile, okey_context) != null

func _build_required_use_action(state, player_index: int, player):
	var required_id = int(state.turn_required_use_tile_id)
	var required_tile = _find_tile_by_id(player, required_id)
	if required_tile == null:
		return null
	var add_action = _build_add_to_meld_action(state, player_index, required_tile)
	if add_action != null:
		return add_action
	return _build_open_meld_with_required(player, required_tile, state.okey_context)

func _build_opened_meld_action(state, player, required_tile_id: int):
	var hand: Array = player.hand
	var n: int = hand.size()
	if n < 3:
		return null
	var required_index: int = -1
	if required_tile_id != -1:
		for i in range(n):
			if int(hand[i].unique_id) == required_tile_id:
				required_index = i
				break
		if required_index == -1:
			return null

	var validator = MeldValidator.new()
	var best_points: int = -1
	var best_kind: int = -1
	var best_ids: Array = []
	var max_size: int = min(6, n) if required_index != -1 else min(4, n)
	for size in range(3, max_size + 1):
		var combos: Array = []
		if required_index != -1:
			_collect_index_combos_with_anchor(n, size, required_index, 0, [], combos)
		else:
			_collect_index_combos(n, size, 0, [], combos)
		for combo in combos:
			var ids: Array = []
			var tiles: Array = []
			for idx in combo:
				var t = hand[int(idx)]
				ids.append(int(t.unique_id))
				tiles.append(t)
			var run_res: Dictionary = validator.validate_run(tiles, state.okey_context)
			if bool(run_res.get("ok", false)):
				var run_points: int = int(run_res.get("points_value", 0))
				if run_points > best_points:
					best_points = run_points
					best_kind = Meld.Kind.RUN
					best_ids = ids
			var set_res: Dictionary = validator.validate_set(tiles, state.okey_context)
			if bool(set_res.get("ok", false)):
				var set_points: int = int(set_res.get("points_value", 0))
				if set_points > best_points:
					best_points = set_points
					best_kind = Meld.Kind.SET
					best_ids = ids

	if best_kind == -1 or best_ids.is_empty():
		return null
	var melds: Array = [{"kind": best_kind, "tile_ids": best_ids}]
	return Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds, "open_by_pairs": false})

func _collect_index_combos(n: int, target: int, start: int, current: Array, out: Array) -> void:
	if current.size() == target:
		out.append(current.duplicate())
		return
	for i in range(start, n):
		current.append(i)
		_collect_index_combos(n, target, i + 1, current, out)
		current.pop_back()

func _collect_index_combos_with_anchor(n: int, target: int, anchor: int, start: int, current: Array, out: Array) -> void:
	if current.is_empty():
		current.append(anchor)
		_collect_index_combos_with_anchor(n, target, anchor, 0, current, out)
		current.pop_back()
		return
	if current.size() == target:
		out.append(current.duplicate())
		return
	for i in range(start, n):
		if i == anchor:
			continue
		if current.has(i):
			continue
		current.append(i)
		_collect_index_combos_with_anchor(n, target, anchor, i + 1, current, out)
		current.pop_back()

func _build_add_to_meld_action(state, player_index: int, tile):
	if state.table_melds.is_empty():
		return null
	var validator = Validator.new()
	for i in range(state.table_melds.size()):
		var meld = state.table_melds[i]
		if meld.kind == Meld.Kind.PAIRS:
			continue
		var action = Action.new(Action.ActionType.ADD_TO_MELD, {"target_meld_index": i, "tile_ids": [tile.unique_id]})
		var res = validator.validate_action(state, player_index, action)
		if bool(res.get("ok", false)):
			return action
	return null

func _find_tile_by_id(player, tile_id: int):
	for t in player.hand:
		if int(t.unique_id) == tile_id:
			return t
	return null

func _has_pair_for_tile(player, required_tile, okey_context = null) -> bool:
	for t in player.hand:
		if t.unique_id == required_tile.unique_id:
			continue
		if _pair_key(t, okey_context) == _pair_key(required_tile, okey_context):
			return true
	return false

func _build_open_meld_with_required(player, required_tile, okey_context = null):
	for t in player.hand:
		if t.unique_id == required_tile.unique_id:
			continue
		if _pair_key(t, okey_context) == _pair_key(required_tile, okey_context):
			var melds = [{"kind": Meld.Kind.PAIRS, "tile_ids": [required_tile.unique_id, t.unique_id]}]
			return Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds, "open_by_pairs": true})

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

func _find_pairs(player, okey_context = null) -> Array:
	var seen = {}
	var melds = []
	for t in player.hand:
		var key = _pair_key(t, okey_context)
		if not seen.has(key):
			seen[key] = t.unique_id
		else:
			var meld = {"kind": Meld.Kind.PAIRS, "tile_ids": [seen[key], t.unique_id]}
			melds.append(meld)
			seen.erase(key)
	return melds

func _find_sets(player, used_ids: Dictionary) -> Array:
	var by_number = {}
	for t in player.hand:
		if used_ids.has(t.unique_id):
			continue
		if not by_number.has(t.number):
			by_number[t.number] = []
		by_number[t.number].append(t)

	var melds = []
	for number in by_number.keys():
		var tiles: Array = by_number[number]
		var colors = {}
		var tile_ids = []
		for t in tiles:
			if colors.has(t.color):
				continue
			colors[t.color] = true
			tile_ids.append(t.unique_id)
			if tile_ids.size() == 4:
				break
		if tile_ids.size() >= 3:
			var points = number * tile_ids.size()
			melds.append({"kind": Meld.Kind.SET, "tile_ids": tile_ids, "points": points})
	return melds

func _find_runs(player, used_ids: Dictionary) -> Array:
	var by_color = {}
	for t in player.hand:
		if used_ids.has(t.unique_id):
			continue
		if not by_color.has(t.color):
			by_color[t.color] = []
		by_color[t.color].append(t)

	var melds = []
	for color in by_color.keys():
		var tiles: Array = by_color[color]
		tiles.sort_custom(func(a, b): return a.number < b.number)
		var run: Array = []
		for t in tiles:
			if run.is_empty():
				run = [t]
				continue
			var last = run[run.size() - 1]
			if t.number == last.number + 1:
				run.append(t)
			elif t.number != last.number:
				if run.size() >= 3:
					var tile_ids = []
					for r in run:
						tile_ids.append(r.unique_id)
					var points = _run_points(tile_ids.size(), run[0].number)
					melds.append({"kind": Meld.Kind.RUN, "tile_ids": tile_ids, "points": points})
				run = [t]
		if run.size() >= 3:
			var tile_ids2 = []
			for r in run:
				tile_ids2.append(r.unique_id)
			var points2 = _run_points(tile_ids2.size(), run[0].number)
			melds.append({"kind": Meld.Kind.RUN, "tile_ids": tile_ids2, "points": points2})
	return melds

func _run_points(length: int, start_number: int) -> int:
	if length <= 0:
		return 0
	var end_number = start_number + length - 1
	return int((start_number + end_number) * length / 2.0)

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

	# Anchor on the first tile to reduce permutation branches.
	var first = tiles[0]
	var first_id: int = int(first.unique_id)
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

	# Failsafe: ensure the anchor is referenced so warnings won't fire on some analyzer settings.
	if first_id == -1:
		return false
	return false

func _collect_index_combos_including_first(n: int, size: int, start: int, current: Array, out: Array) -> void:
	if current.size() == size:
		out.append(current.duplicate())
		return
	for i in range(start, n):
		current.append(i)
		_collect_index_combos_including_first(n, size, i + 1, current, out)
		current.pop_back()

func _pair_key(tile, okey_context) -> String:
	if tile.kind == Tile.Kind.FAKE_OKEY and okey_context != null:
		return "%d-%d" % [int(okey_context.okey_color), int(okey_context.okey_number)]
	return "%d-%d" % [int(tile.color), int(tile.number)]
