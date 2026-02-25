extends BotHeuristic
class_name BotEasy

## Weaker bot: random usefulness 50% of the time, no exhaustive open search,
## requires 120+ points to open (more conservative).

var _rng := RandomNumberGenerator.new()


func _init(p_seed: int = 0) -> void:
	_rng.seed = p_seed if p_seed != 0 else randi()


func _tile_usefulness(state, player, tile) -> int:
	# 50% chance to return random usefulness instead of calculated value
	if _rng.randf() < 0.5:
		return _rng.randi_range(0, 6)
	return super._tile_usefulness(state, player, tile)


func _should_open(points: int, state, player) -> bool:
	# Require 120+ points instead of the rule minimum
	var min_points: int = 120
	if state != null and state.rule_config != null:
		min_points = maxi(120, int(state.rule_config.open_min_points_initial))
	if points < min_points:
		return false
	return true


func _try_open_exhaustive(_player, _state):
	# Easy bot doesn't use exhaustive search
	return null


func _prefer_take_discard(state, player, discard_tile) -> bool:
	# Less aggressive discard-take: only take when deck is very low
	var deck_remaining = state.deck.size()
	if deck_remaining <= 3:
		return true
	return _discard_value(state, player, discard_tile) >= 6
