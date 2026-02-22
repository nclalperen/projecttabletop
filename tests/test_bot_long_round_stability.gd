extends RefCounted

const ROUNDS_TO_SIMULATE: int = 24
const MAX_ACTIONS_PER_ROUND: int = 2600


func run() -> bool:
	var cfg := RuleConfig.new()
	var completed: int = 0
	var bot_open_rounds: int = 0
	var rejection_total: int = 0

	for round_i in range(ROUNDS_TO_SIMULATE):
		var controller := LocalGameController.new()
		controller.start_new_round(cfg, 810000 + round_i, 4)
		var heuristic := BotHeuristic.new()
		var random_bot := BotRandom.new(910000 + round_i)
		var actions: int = 0
		var rejection_streak: int = 0
		var saw_bot_open: bool = false

		while controller.state != null and int(controller.state.phase) != int(GameState.Phase.ROUND_END) and actions < MAX_ACTIONS_PER_ROUND:
			actions += 1
			for bi in range(1, 4):
				if bool(controller.state.players[bi].has_opened):
					saw_bot_open = true
			var pi: int = int(controller.state.current_player_index)
			var action = heuristic.choose_action(controller.state, pi)
			if action == null:
				action = random_bot.choose_action(controller.state, pi)
			if action == null:
				push_error("Bot returned null action in round %d at step %d" % [round_i, actions])
				return false
			var res: Dictionary = controller.apply_action_if_valid(pi, action)
			if bool(res.get("ok", false)):
				rejection_streak = 0
				continue
			rejection_total += 1
			rejection_streak += 1

			var fallback = random_bot.choose_action(controller.state, pi)
			if fallback != null:
				var fallback_res: Dictionary = controller.apply_action_if_valid(pi, fallback)
				if bool(fallback_res.get("ok", false)):
					rejection_streak = 0
					continue
				rejection_total += 1
				rejection_streak += 1

			if rejection_streak >= 18:
				break

		if controller.state == null:
			push_error("Controller state became null in round %d" % round_i)
			return false
		if int(controller.state.phase) != int(GameState.Phase.ROUND_END):
			push_error("Round %d did not complete (phase=%d, actions=%d)" % [round_i, int(controller.state.phase), actions])
			return false

		completed += 1
		if saw_bot_open:
			bot_open_rounds += 1

	if completed != ROUNDS_TO_SIMULATE:
		push_error("Expected %d completed rounds, got %d" % [ROUNDS_TO_SIMULATE, completed])
		return false
	if bot_open_rounds <= 0:
		push_error("Bots never opened across %d rounds" % ROUNDS_TO_SIMULATE)
		return false

	print("Bot stability: completed=%d/%d bot_open_rounds=%d rejections=%d" % [completed, ROUNDS_TO_SIMULATE, bot_open_rounds, rejection_total])
	return true
