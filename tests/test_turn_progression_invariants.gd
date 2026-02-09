extends RefCounted

func run() -> bool:
	return _test_round_does_not_end_after_first_nonfinishing_discard()

func _test_round_does_not_end_after_first_nonfinishing_discard() -> bool:
	var cfg := RuleConfig.new()
	var controller := LocalGameController.new()
	controller.start_new_round(cfg, 11111, 4)

	var starter: int = int(controller.state.current_player_index)
	var starter_tile = controller.state.players[starter].hand[0]
	var res: Dictionary = controller.starter_discard(starter, int(starter_tile.unique_id))
	if not bool(res.get("ok", false)):
		push_error("starter_discard failed")
		return false

	# First normal player turn: draw -> end_play -> discard
	var p1: int = int(controller.state.current_player_index)
	res = controller.draw_from_deck(p1)
	if not bool(res.get("ok", false)):
		push_error("draw_from_deck failed")
		return false
	res = controller.end_play_turn(p1)
	if not bool(res.get("ok", false)):
		push_error("end_play failed")
		return false
	var d1 = controller.state.players[p1].hand[0]
	res = controller.discard_tile(p1, int(d1.unique_id))
	if not bool(res.get("ok", false)):
		push_error("discard failed")
		return false

	if controller.state.phase == GameState.Phase.ROUND_END:
		push_error("Round ended prematurely after first non-finishing discard")
		return false
	if controller.state.phase != GameState.Phase.TURN_DRAW:
		push_error("Expected TURN_DRAW after discard")
		return false

	# Next player must still be able to act.
	var p2: int = int(controller.state.current_player_index)
	res = controller.draw_from_deck(p2)
	if not bool(res.get("ok", false)):
		push_error("next player could not draw; turn progression broken")
		return false
	return true
