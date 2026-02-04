extends RefCounted
class_name BotRandom

const BotBase = preload("res://core/bots/BotBase.gd")
const Action = preload("res://core/actions/Action.gd")
const Validator = preload("res://core/actions/Validator.gd")
const Meld = preload("res://core/model/Meld.gd")
const DiscardRules = preload("res://core/rules/DiscardRules.gd")

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
				if player.has_opened:
					var discard_tile = state.discard_pile[state.discard_pile.size() - 1]
					if _can_use_discard_tile(state, player, discard_tile):
						actions.append(Action.new(Action.ActionType.TAKE_DISCARD, {}))
		state.Phase.TURN_PLAY:
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
		if _has_pair_for_tile(player, discard_tile):
			return true
	else:
		if _has_pair_for_tile(player, discard_tile) and (not pairs_locked):
			return true
	if _can_add_tile_to_table(state, discard_tile):
		return true
	if _can_form_simple_run_or_set(player, discard_tile) and not (player.opened_by_pairs and pairs_locked):
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

	# Try to open melds using the required tile.
	var meld_action = _build_open_meld_with_required(player, required_tile)
	return meld_action

func _build_add_to_meld_action(state, tile):
	var discard_rules = DiscardRules.new()
	for i in range(state.table_melds.size()):
		var meld = state.table_melds[i]
		if meld.kind == Meld.Kind.PAIRS:
			continue
		if meld.tiles_data.is_empty():
			continue
		if discard_rules.is_tile_extendable_on_table(state, tile):
			return Action.new(Action.ActionType.ADD_TO_MELD, {"target_meld_index": i, "tile_ids": [tile.unique_id]})
	return null

func _build_open_meld_with_required(player, required_tile):
	# Try pair
	for t in player.hand:
		if t.unique_id == required_tile.unique_id:
			continue
		if t.color == required_tile.color and t.number == required_tile.number:
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

func _can_form_simple_run_or_set(player, required_tile) -> bool:
	return _build_open_meld_with_required(player, required_tile) != null

func _has_pair_for_tile(player, required_tile) -> bool:
	for t in player.hand:
		if t.unique_id == required_tile.unique_id:
			continue
		if t.color == required_tile.color and t.number == required_tile.number:
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


