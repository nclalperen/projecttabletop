extends RefCounted


func run() -> bool:
	return _test_round_does_not_end_immediately_after_first_discard()


func _test_round_does_not_end_immediately_after_first_discard() -> bool:
	var cfg := RuleConfig.new()
	var controller := LocalGameController.new()
	controller.start_new_round(cfg, 314159, 4)

	var starter: int = int(controller.state.current_player_index)
	var first_tile = controller.state.players[starter].hand[0]
	var res: Dictionary = controller.starter_discard(starter, int(first_tile.unique_id))
	if not bool(res.get("ok", false)):
		push_error("starter_discard failed: %s" % str(res.get("code", "")))
		return false

	var heuristic := BotHeuristic.new()
	var random_bot := BotRandom.new(8080)
	var safety: int = 0

	while controller.state != null and int(controller.state.current_player_index) != 0 and int(controller.state.phase) != int(GameState.Phase.ROUND_END) and safety < 18:
		safety += 1
		var pi: int = int(controller.state.current_player_index)
		var action = heuristic.choose_action(controller.state, pi)
		if action == null:
			action = random_bot.choose_action(controller.state, pi)
		if action == null:
			push_error("Bot produced null action")
			return false
		res = controller.apply_action_if_valid(pi, action)
		if bool(res.get("ok", false)):
			continue

		var fallback = random_bot.choose_action(controller.state, pi)
		if fallback == null:
			push_error("Bot fallback produced null action")
			return false
		res = controller.apply_action_if_valid(pi, fallback)
		if not bool(res.get("ok", false)):
			push_error("Bot fallback failed: %s" % str(res.get("code", "")))
			return false

	if controller.state == null:
		push_error("State became null unexpectedly")
		return false
	if int(controller.state.phase) == int(GameState.Phase.ROUND_END):
		push_error("Round ended immediately after first discard/bot progression")
		return false
	return true

