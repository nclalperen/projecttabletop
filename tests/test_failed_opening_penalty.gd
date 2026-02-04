extends RefCounted


func run() -> bool:
	return _test_failed_opening_penalty()

func _test_failed_opening_penalty() -> bool:
	var cfg = RuleConfig.new()
	cfg.penalty_failed_opening = true

	var controller = LocalGameController.new()
	controller.start_new_round(cfg, 1401, 4)
	controller.state.phase = controller.state.Phase.TURN_PLAY

	var player = controller.state.current_player_index
	var action = Action.new(Action.ActionType.OPEN_MELDS, {"melds": []})
	var res = controller.apply_action_if_valid(player, action)
	if res.ok:
		push_error("Open melds should fail")
		return false
	if controller.state.players[player].score_round != cfg.penalty_value:
		push_error("Expected failed opening penalty")
		return false
	return true



