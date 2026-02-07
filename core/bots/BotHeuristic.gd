extends RefCounted
class_name BotHeuristic

func choose_action(state, player_index: int):
	var validator = Validator.new()
	var player = state.players[player_index]

	match state.phase:
		state.Phase.STARTER_DISCARD:
			return _choose_starter_discard(state, player)
		state.Phase.TURN_DRAW:
			# Conservative policy to avoid bot stalls with required-use discard constraints.
			if player.has_opened and not state.discard_pile.is_empty():
				var discard_tile = state.discard_pile[state.discard_pile.size() - 1]
				var can_take = validator.validate_action(state, player_index, Action.new(Action.ActionType.TAKE_DISCARD, {})).ok
				var can_layoff_now = _can_add_tile_to_table(state, discard_tile)
				if can_take and can_layoff_now and _prefer_take_discard(state, player, discard_tile):
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
		var is_joker = t.kind == t.Kind.FAKE_OKEY or state.okey_context.is_real_okey(t)
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
	var pairs_melds = _find_pairs(player)
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

	return null

func _should_open(points: int, state, player) -> bool:
	if points >= 130:
		return true
	var penalty = _estimate_hand_penalty(state, player)
	return penalty >= 60

func _estimate_hand_penalty(state, player) -> int:
	var sum = 0
	for t in player.hand:
		if t.kind == t.Kind.FAKE_OKEY or state.okey_context.is_real_okey(t):
			sum += 101
		else:
			sum += t.number
	return sum

func _can_use_discard_tile(state, player, discard_tile) -> bool:
	if not player.has_opened:
		# Permit taking discard if immediate open is plausible.
		return _can_form_simple_run_or_set(player, discard_tile) or _has_pair_for_tile(player, discard_tile)

	var cfg = state.rule_config
	var pairs_locked = cfg != null and cfg.open_by_pairs_locks_to_pairs
	if player.opened_by_pairs and pairs_locked:
		return _has_pair_for_tile(player, discard_tile) or _can_add_tile_to_table(state, discard_tile)

	if _has_pair_for_tile(player, discard_tile):
		return true
	if _can_add_tile_to_table(state, discard_tile):
		return true
	if _can_form_simple_run_or_set(player, discard_tile):
		return true
	return false

func _prefer_take_discard(state, player, discard_tile) -> bool:
	var deck_remaining = state.deck.size()
	if deck_remaining <= 6:
		return true
	return _discard_value(state, player, discard_tile) >= 4

func _discard_value(state, player, discard_tile) -> int:
	var value = 0
	if discard_tile.kind == discard_tile.Kind.FAKE_OKEY or state.okey_context.is_real_okey(discard_tile):
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

func _can_add_tile_to_table(state, tile) -> bool:
	var discard_rules = DiscardRules.new()
	return discard_rules.is_tile_extendable_on_table(state, tile)

func _can_form_simple_run_or_set(player, required_tile) -> bool:
	return _build_open_meld_with_required(player, required_tile) != null

func _build_required_use_action(state, player_index: int, player):
	var required_id = int(state.turn_required_use_tile_id)
	var required_tile = _find_tile_by_id(player, required_id)
	if required_tile == null:
		return null
	var add_action = _build_add_to_meld_action(state, player_index, required_tile)
	if add_action != null:
		return add_action
	return _build_open_meld_with_required(player, required_tile)

func _build_opened_meld_action(state, player, required_tile_id: int):
	var hand: Array = player.hand
	var n: int = hand.size()
	if n < 3:
		return null

	var validator = MeldValidator.new()
	var best_points: int = -1
	var best_kind: int = -1
	var best_ids: Array = []

	for i in range(n):
		for j in range(i + 1, n):
			for k in range(j + 1, n):
				var ids3: Array = [int(hand[i].unique_id), int(hand[j].unique_id), int(hand[k].unique_id)]
				if required_tile_id != -1 and not ids3.has(required_tile_id):
					continue
				var tiles3: Array = [hand[i], hand[j], hand[k]]
				var run3: Dictionary = validator.validate_run(tiles3, state.okey_context)
				if bool(run3.get("ok", false)):
					var pts3: int = int(run3.get("points_value", 0))
					if pts3 > best_points:
						best_points = pts3
						best_kind = Meld.Kind.RUN
						best_ids = ids3
				var set3: Dictionary = validator.validate_set(tiles3, state.okey_context)
				if bool(set3.get("ok", false)):
					var spts3: int = int(set3.get("points_value", 0))
					if spts3 > best_points:
						best_points = spts3
						best_kind = Meld.Kind.SET
						best_ids = ids3

	for i in range(n):
		for j in range(i + 1, n):
			for k in range(j + 1, n):
				for l in range(k + 1, n):
					var ids4: Array = [int(hand[i].unique_id), int(hand[j].unique_id), int(hand[k].unique_id), int(hand[l].unique_id)]
					if required_tile_id != -1 and not ids4.has(required_tile_id):
						continue
					var tiles4: Array = [hand[i], hand[j], hand[k], hand[l]]
					var run4: Dictionary = validator.validate_run(tiles4, state.okey_context)
					if bool(run4.get("ok", false)):
						var pts4: int = int(run4.get("points_value", 0))
						if pts4 > best_points:
							best_points = pts4
							best_kind = Meld.Kind.RUN
							best_ids = ids4
					var set4: Dictionary = validator.validate_set(tiles4, state.okey_context)
					if bool(set4.get("ok", false)):
						var spts4: int = int(set4.get("points_value", 0))
						if spts4 > best_points:
							best_points = spts4
							best_kind = Meld.Kind.SET
							best_ids = ids4

	if best_kind == -1 or best_ids.is_empty():
		return null
	var melds: Array = [{"kind": best_kind, "tile_ids": best_ids}]
	return Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds, "open_by_pairs": false})

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

func _has_pair_for_tile(player, required_tile) -> bool:
	for t in player.hand:
		if t.unique_id == required_tile.unique_id:
			continue
		if t.color == required_tile.color and t.number == required_tile.number:
			return true
	return false

func _build_open_meld_with_required(player, required_tile):
	for t in player.hand:
		if t.unique_id == required_tile.unique_id:
			continue
		if t.color == required_tile.color and t.number == required_tile.number:
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

func _find_pairs(player) -> Array:
	var seen = {}
	var melds = []
	for t in player.hand:
		var key = "%s-%s" % [t.color, t.number]
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
