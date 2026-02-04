extends RefCounted

const LocalGameController = preload("res://core/controller/LocalGameController.gd")
const RuleConfig = preload("res://core/rules/RuleConfig.gd")

func run() -> bool:
	return _test_deck_exhausted()

func _test_deck_exhausted() -> bool:
	var controller = LocalGameController.new()
	var cfg = RuleConfig.new()
	controller.start_new_round(cfg, 1701, 4)
	controller.state.phase = controller.state.Phase.TURN_DRAW
	controller.state.deck = []
	controller.state.discard_pile = []

	controller._check_deck_exhausted()
	if controller.state.phase != controller.state.Phase.ROUND_END:
		push_error("Expected ROUND_END when deck exhausted")
		return false
	return true



