extends RefCounted


func run() -> bool:
	return _test_round_limit_match_end()


func _test_round_limit_match_end() -> bool:
	var cfg := RuleConfig.new()
	cfg.match_end_mode = "rounds"
	cfg.match_end_value = 1
	var controller := LocalGameController.new()
	controller.start_new_round(cfg, 4601, 4)

	controller.end_round_no_winner("manual", true)
	if not bool(controller.state.match_finished):
		push_error("Expected match to be finished at round limit")
		return false
	if controller.state.match_winner_indices.is_empty():
		push_error("Expected non-empty match winners at round end")
		return false
	return true
