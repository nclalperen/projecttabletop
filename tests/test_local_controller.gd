extends RefCounted


func run() -> bool:
	return _test_basic_turns()

func _test_basic_turns() -> bool:
	var controller = LocalGameController.new()
	var cfg = RuleConfig.new()
	controller.start_new_round(cfg, 111, 4)

	if controller.state.phase != controller.state.Phase.STARTER_DISCARD:
		push_error("Expected STARTER_DISCARD")
		return false

	var starter = controller.state.current_player_index
	var starter_tile = controller.state.players[starter].hand[0]
	var res = controller.starter_discard(starter, starter_tile.unique_id)
	if not res.ok:
		push_error("Starter discard failed")
		return false

	var player = controller.state.current_player_index
	res = controller.draw_from_deck(player)
	if not res.ok:
		push_error("Draw failed")
		return false

	res = controller.end_play_turn(player)
	if not res.ok:
		push_error("End play failed")
		return false
	var tile = controller.state.players[player].hand[0]
	res = controller.discard_tile(player, tile.unique_id)
	if not res.ok:
		push_error("Discard failed")
		return false

	return true



