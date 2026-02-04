extends RefCounted


func run() -> bool:
	return _test_bot_random_loop()

func _test_bot_random_loop() -> bool:
	var controller = LocalGameController.new()
	var cfg = RuleConfig.new()
	controller.start_new_round(cfg, 333, 4)

	var bot = BotRandom.new(123)
	var steps = 0
	while steps < 6:
		var player = controller.state.current_player_index
		var action = bot.choose_action(controller.state, player)
		if action == null:
			push_error("Bot produced no action")
			return false
		var res = controller.apply_action_if_valid(player, action)
		if not res.ok:
			push_error("Bot action rejected: %s" % res.code)
			return false
		steps += 1

	return true



