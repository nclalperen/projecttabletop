extends RefCounted


func run() -> bool:
	return _test_envelope_translation_happy_path() and _test_unknown_envelope_action()


func _test_envelope_translation_happy_path() -> bool:
	var controller := LocalGameController.new()
	controller.start_new_round(RuleConfig.new(), 4701, 4)

	var starter: int = int(controller.state.current_player_index)
	var starter_tile_id: int = int(controller.state.players[starter].hand[0].unique_id)
	var discard_res: Dictionary = controller.submit_action_envelope({
		"type": "STARTER_DISCARD",
		"player_id": starter,
		"payload": {"tile_id": starter_tile_id},
	})
	if not bool(discard_res.get("ok", false)):
		push_error("STARTER_DISCARD envelope failed: %s" % str(discard_res))
		return false
	if not discard_res.has("state_hash"):
		push_error("Envelope response missing state_hash")
		return false

	var next_player: int = int(controller.state.current_player_index)
	var draw_res: Dictionary = controller.submit_action_envelope({
		"type": "draw_from_stock",
		"player_id": next_player,
		"payload": {},
	})
	if not bool(draw_res.get("ok", false)):
		push_error("DRAW_FROM_STOCK envelope failed: %s" % str(draw_res))
		return false
	if int(controller.state.phase) != int(GameState.Phase.TURN_PLAY):
		push_error("Expected TURN_PLAY after draw envelope")
		return false
	return true


func _test_unknown_envelope_action() -> bool:
	var controller := LocalGameController.new()
	controller.start_new_round(RuleConfig.new(), 4702, 4)
	var res: Dictionary = controller.submit_action_envelope({
		"type": "NO_SUCH_ACTION",
		"player_id": 0,
		"payload": {},
	})
	if bool(res.get("ok", false)):
		push_error("Unknown envelope action should fail")
		return false
	if String(res.get("code", "")) != "unknown_action":
		push_error("Expected unknown_action code, got %s" % String(res.get("code", "")))
		return false
	return true
