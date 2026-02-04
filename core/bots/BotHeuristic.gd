extends RefCounted
class_name BotHeuristic

const Action = preload("res://core/actions/Action.gd")
const Validator = preload("res://core/actions/Validator.gd")
const Meld = preload("res://core/model/Meld.gd")
const DiscardRules = preload("res://core/rules/DiscardRules.gd")

func choose_action(state, player_index: int):
	var validator = Validator.new()
	var player = state.players[player_index]

	match state.phase:
		state.Phase.STARTER_DISCARD:
			return _choose_discard(player)
		state.Phase.TURN_DRAW:
			if not state.discard_pile.is_empty():
				var discard_tile = state.discard_pile[state.discard_pile.size() - 1]
				if _can_use_discard_tile(state, player, discard_tile):
					return Action.new(Action.ActionType.TAKE_DISCARD, {})
			return Action.new(Action.ActionType.DRAW_FROM_DECK, {})
		state.Phase.TURN_PLAY:
			if not player.has_opened:
				var open_action = _try_open(player)
				if open_action != null:
					var res = validator.validate_action(state, player_index, open_action)
					if res.ok:
						return open_action
			return Action.new(Action.ActionType.END_PLAY, {})
		state.Phase.TURN_DISCARD:
			return _choose_discard(player)
		_:
			return null

func _choose_discard(player):
	# Discard highest tile by number (simple heuristic)
	var best = null
	for t in player.hand:
		if best == null or t.number > best.number:
			best = t
	if best == null:
		return null
	return Action.new(Action.ActionType.DISCARD, {"tile_id": best.unique_id})

func _try_open(player):
	# Prefer 5 pairs if available
	var pairs_melds = _find_pairs(player)
	if pairs_melds.size() >= 5:
		var melds = pairs_melds.slice(0, 5)
		return Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds, "open_by_pairs": true})

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
			return Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds})

	var runs = _find_runs(player, used_ids)
	for m in runs:
		melds.append(m)
		points += m.get("points", 0)
		for id in m.tile_ids:
			used_ids[id] = true
		if points >= 101:
			return Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds})

	return null

func _can_use_discard_tile(state, player, discard_tile) -> bool:
	# Be conservative for unopened hands: avoid taking discards that force invalid opens.
	if not player.has_opened:
		return false

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

func _can_add_tile_to_table(state, tile) -> bool:
	var discard_rules = DiscardRules.new()
	return discard_rules.is_tile_extendable_on_table(state, tile)

func _can_form_simple_run_or_set(player, required_tile) -> bool:
	return _build_open_meld_with_required(player, required_tile) != null

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
					var sum = 0
					for r in run:
						tile_ids.append(r.unique_id)
						sum += r.number
					melds.append({"kind": Meld.Kind.RUN, "tile_ids": tile_ids, "points": sum})
				run = [t]
		if run.size() >= 3:
			var tile_ids2 = []
			var sum2 = 0
			for r in run:
				tile_ids2.append(r.unique_id)
				sum2 += r.number
			melds.append({"kind": Meld.Kind.RUN, "tile_ids": tile_ids2, "points": sum2})
	return melds


