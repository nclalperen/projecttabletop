extends RefCounted


func run() -> bool:
	return _test_target_score_match_end()


func _test_target_score_match_end() -> bool:
	var cfg := RuleConfig.new()
	cfg.match_end_mode = "target_score"
	cfg.match_end_value = 150
	var controller := LocalGameController.new()
	controller.start_new_round(cfg, 4602, 4)

	controller.state.players[0].score_total = 100
	controller.state.players[1].score_total = 0
	controller.state.players[2].score_total = 50
	controller.state.players[3].score_total = 75

	controller.end_round_no_winner("manual", true)
	if not bool(controller.state.match_finished):
		push_error("Expected match to finish when target score threshold is reached")
		return false
	if controller.state.match_winner_indices.size() != 1 or int(controller.state.match_winner_indices[0]) != 1:
		push_error("Expected player 1 to be sole match winner, got %s" % str(controller.state.match_winner_indices))
		return false
	return true
