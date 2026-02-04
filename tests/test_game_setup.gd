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

	return true



