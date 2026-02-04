extends RefCounted

const LocalGameController = preload("res://core/controller/LocalGameController.gd")
const RuleConfig = preload("res://core/rules/RuleConfig.gd")
const BotHeuristic = preload("res://core/bots/BotHeuristic.gd")

func run() -> bool:
	return _test_heuristic_bot_action()

func _test_heuristic_bot_action() -> bool:
	var controller = LocalGameController.new()
	var cfg = RuleConfig.new()
	controller.start_new_round(cfg, 1801, 4)

	var bot = BotHeuristic.new()
	var player = controller.state.current_player_index
	var action = bot.choose_action(controller.state, player)
	if action == null:
		push_error("Heuristic bot returned null action")
		return false
	return true



