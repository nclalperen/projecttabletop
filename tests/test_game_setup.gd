extends RefCounted


func run() -> bool:
	return _test_dealing_counts()

func _test_dealing_counts() -> bool:
	var cfg = RuleConfig.new()
	var setup = GameSetup.new()
	var state = setup.new_round(cfg, 12345, 4)

	if state.phase != state.Phase.STARTER_DISCARD:
		push_error("Expected phase STARTER_DISCARD")
		return false

	var starter = state.current_player_index
	for i in range(state.players.size()):
		var expected = 21
		if i == starter:
			expected = 22
		var count = state.players[i].hand.size()
		if count != expected:
			push_error("Player %s expected %s tiles, got %s" % [i, expected, count])
			return false

	# SeOkey11 15-stack method leaves 3 draw stacks => 20 tiles in deck (indicator removed).
	if state.deck.size() != 20:
		push_error("Expected deck size 20, got %s" % state.deck.size())
		return false
	if state.discard_pile.size() != 0:
		push_error("Expected empty discard pile at round start")
		return false
	if state.draw_stack_indices.size() != 3:
		push_error("Expected 3 draw stacks, got %s" % state.draw_stack_indices.size())
		return false

	# Starter is dealer's right (CCW): starter = dealer + 1 mod 4.
	var expected_dealer = (starter - 1 + state.players.size()) % state.players.size()
	if state.dealer_index != expected_dealer:
		push_error("Expected dealer %s from starter %s, got %s" % [expected_dealer, starter, state.dealer_index])
		return false

	# Total tile accounting: hands (85) + deck (20) + indicator (1) = 106, all unique_ids.
	var seen := {}
	var total := 0
	for p in state.players:
		for tile in p.hand:
			if seen.has(tile.unique_id):
				push_error("Duplicate tile id in hands: %s" % tile.unique_id)
				return false
			seen[tile.unique_id] = true
			total += 1
	for tile in state.deck:
		if seen.has(tile.unique_id):
			push_error("Duplicate tile id between deck and hands: %s" % tile.unique_id)
			return false
		seen[tile.unique_id] = true
		total += 1
	var indicator = state.okey_context.indicator_tile
	if seen.has(indicator.unique_id):
		push_error("Indicator tile appears in deck/hands: %s" % indicator.unique_id)
		return false
	seen[indicator.unique_id] = true
	total += 1
	if total != 106:
		push_error("Expected total tiles accounted 106, got %s" % total)
		return false

	return true



