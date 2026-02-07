extends RefCounted


func run() -> bool:
	return _test_player_cannot_discard_twice_in_same_turn()


func _test_player_cannot_discard_twice_in_same_turn() -> bool:
	var cfg := RuleConfig.new()
	var controller := LocalGameController.new()
	controller.start_new_round(cfg, 77, 4)

	var starter: int = controller.state.current_player_index
	var starter_tile = controller.state.players[starter].hand[0]
	var res := controller.starter_discard(starter, starter_tile.unique_id)
	if not res.ok:
		push_error("starter_discard failed: %s" % String(res.code))
		return false

	var p: int = controller.state.current_player_index
	res = controller.draw_from_deck(p)
	if not res.ok:
		push_error("draw_from_deck failed: %s" % String(res.code))
		return false

	res = controller.end_play_turn(p)
	if not res.ok:
		push_error("end_play_turn failed: %s" % String(res.code))
		return false

	var first_tile = controller.state.players[p].hand[0]
	res = controller.discard_tile(p, first_tile.unique_id)
	if not res.ok:
		push_error("first discard failed: %s" % String(res.code))
		return false

	# Attempt another discard immediately (without draw/end-play cycle).
	var second_tile = controller.state.players[p].hand[0]
	res = controller.discard_tile(p, second_tile.unique_id)
	if res.ok:
		push_error("second discard should be rejected but succeeded")
		return false

	return true

