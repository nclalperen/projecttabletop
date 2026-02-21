extends RefCounted


func run() -> bool:
	return _test_stock_empty_scores_no_winner() and _test_stock_empty_redeal_mode()


func _test_stock_empty_scores_no_winner() -> bool:
	var cfg := RuleConfig.new()
	cfg.end_on_stock_empty = "score_no_winner"
	var controller := LocalGameController.new()
	controller.start_new_round(cfg, 4401, 4)

	controller.state.phase = GameState.Phase.TURN_DRAW
	controller.state.deck = []
	controller.state.discard_pile = []
	controller.state.current_player_index = 0

	var res: Dictionary = controller.draw_from_deck(0) # rejected draw should trigger stock-empty end
	if bool(res.get("ok", false)):
		push_error("draw_from_deck should fail when deck is empty")
		return false
	if controller.state.phase != GameState.Phase.ROUND_END:
		push_error("Stock-empty should end round in score_no_winner mode")
		return false
	if String(controller.state.round_end_reason) != "stock_empty":
		push_error("Expected round_end_reason stock_empty, got %s" % String(controller.state.round_end_reason))
		return false
	for p in controller.state.players:
		if int(p.score_total) != int(cfg.unopened_penalty):
			push_error("Expected unopened penalty on stock-empty no-winner scoring")
			return false
	return true


func _test_stock_empty_redeal_mode() -> bool:
	var cfg := RuleConfig.new()
	cfg.end_on_stock_empty = "redeal"
	var controller := LocalGameController.new()
	controller.start_new_round(cfg, 4402, 4)

	controller.state.phase = GameState.Phase.TURN_DRAW
	controller.state.deck = []
	controller.state.discard_pile = []
	controller.state.current_player_index = 0

	var res: Dictionary = controller.draw_from_deck(0)
	if bool(res.get("ok", false)):
		push_error("draw_from_deck should fail when deck is empty")
		return false
	if controller.state.phase != GameState.Phase.ROUND_END:
		push_error("Stock-empty should end round in redeal mode")
		return false
	if String(controller.state.round_end_reason) != "stock_empty_redeal":
		push_error("Expected round_end_reason stock_empty_redeal")
		return false
	for p in controller.state.players:
		if int(p.score_total) != 0:
			push_error("Redeal mode must not change score_total")
			return false
	return true
