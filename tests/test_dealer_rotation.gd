extends RefCounted

func run() -> bool:
	var cfg = RuleConfig.new()

	var controller = LocalGameController.new()
	controller.start_new_round(cfg, 555, 4)
	var first_dealer = controller.state.dealer_index

	controller.start_new_round(cfg, 556, 4)
	var second_dealer = controller.state.dealer_index
	var expected = (first_dealer + 1) % 4
	if second_dealer != expected:
		push_error("Dealer did not rotate CCW: expected %s got %s" % [expected, second_dealer])
		return false

	controller.start_new_round(cfg, 557, 4)
	var third_dealer = controller.state.dealer_index
	var expected2 = (second_dealer + 1) % 4
	if third_dealer != expected2:
		push_error("Dealer did not rotate CCW on third round: expected %s got %s" % [expected2, third_dealer])
		return false

	return true
