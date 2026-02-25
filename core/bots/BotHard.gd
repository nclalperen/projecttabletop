extends BotHeuristic
class_name BotHard

## Stronger bot: tracks opponent discard history for safer discards,
## more aggressive discard-take, better run-building with adjacency awareness.

var _opponent_discards: Dictionary = {}  # color-number -> count of times seen discarded


func choose_action(state, player_index: int):
	# Track discards from all players for safer discard selection
	_update_discard_tracking(state)
	return super.choose_action(state, player_index)


func _update_discard_tracking(state) -> void:
	if state == null or state.discard_pile.is_empty():
		return
	# Rebuild tracking from the full discard pile each turn (simple approach)
	_opponent_discards.clear()
	for tile in state.discard_pile:
		var key: String = "%d-%d" % [int(tile.color), int(tile.number)]
		_opponent_discards[key] = int(_opponent_discards.get(key, 0)) + 1


func _tile_usefulness(state, player, tile) -> int:
	var base: int = super._tile_usefulness(state, player, tile)
	# Bonus: tiles adjacent to frequently discarded tiles are less likely
	# to be needed by opponents, so they're safer to keep (lower discard priority)
	var adj_discarded: int = 0
	for offset in [-1, 1]:
		var adj_num: int = tile.number + offset
		if adj_num >= 1 and adj_num <= 13:
			var key: String = "%d-%d" % [int(tile.color), adj_num]
			adj_discarded += int(_opponent_discards.get(key, 0))
	# More adjacent discards = opponents less likely to need our tile's neighbors
	# So these tiles form safer runs — boost usefulness
	base += adj_discarded
	return base


func _select_best_discard_tile(state, player):
	# Prefer discarding tiles that opponents have already discarded (safer)
	var best = null
	var best_penalty: bool = true
	var best_usefulness: int = 9999
	var best_safety: int = -1
	var discard_rules = DiscardRules.new()
	for t in player.hand:
		var is_joker = state.okey_context.is_real_okey(t)
		var extendable = discard_rules.is_tile_extendable_on_table(state, t)
		var penalty = is_joker or extendable
		var usefulness = _tile_usefulness(state, player, t)
		var key: String = "%d-%d" % [int(t.color), int(t.number)]
		var safety: int = int(_opponent_discards.get(key, 0))
		if best == null:
			best = t
			best_penalty = penalty
			best_usefulness = usefulness
			best_safety = safety
			continue
		# Prefer non-penalty tiles
		if best_penalty and not penalty:
			best = t; best_penalty = penalty; best_usefulness = usefulness; best_safety = safety
			continue
		if best_penalty != penalty:
			continue
		# Among equal penalty, prefer lower usefulness (discard less useful tiles)
		# With safety as tiebreaker (prefer tiles already discarded by others)
		if usefulness < best_usefulness or (usefulness == best_usefulness and safety > best_safety):
			best = t; best_usefulness = usefulness; best_safety = safety
			continue
		if usefulness == best_usefulness and safety == best_safety and t.number > best.number:
			best = t; best_usefulness = usefulness
	return best


func _prefer_take_discard(state, player, discard_tile) -> bool:
	# More aggressive: take discard more readily
	var deck_remaining = state.deck.size()
	if deck_remaining <= 10:
		return true
	return _discard_value(state, player, discard_tile) >= 3


func _should_open(points: int, state, player) -> bool:
	# Open as soon as legally possible (same as base, but explicit)
	var min_points: int = 101
	if state != null and state.rule_config != null:
		min_points = int(state.rule_config.open_min_points_initial)
	if points < min_points:
		return false
	return true
