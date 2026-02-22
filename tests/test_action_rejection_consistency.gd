extends RefCounted


func run() -> bool:
	return _test_rejection_codes_consistent()


func _test_rejection_codes_consistent() -> bool:
	var cfg := RuleConfig.new()
	var controller := LocalGameController.new()
	controller.start_new_round(cfg, 931111, 4)
	var p: int = int(controller.state.current_player_index)

	var draw_res_1: Dictionary = controller.draw_from_deck(p)
	var draw_res_2: Dictionary = controller.draw_from_deck(p)
	if bool(draw_res_1.get("ok", false)) or bool(draw_res_2.get("ok", false)):
		push_error("Expected draw_from_deck to fail during STARTER_DISCARD")
		return false
	if str(draw_res_1.get("code", "")) == "" or str(draw_res_1.get("code", "")) != str(draw_res_2.get("code", "")):
		push_error("Inconsistent draw rejection codes: %s vs %s" % [str(draw_res_1.get("code", "")), str(draw_res_2.get("code", ""))])
		return false

	var sample_tile_id: int = int(controller.state.players[p].hand[0].unique_id)
	controller.state.phase = controller.state.Phase.TURN_PLAY
	var discard_res_1: Dictionary = controller.discard_tile(p, sample_tile_id)
	var discard_res_2: Dictionary = controller.discard_tile(p, sample_tile_id)
	if bool(discard_res_1.get("ok", false)) or bool(discard_res_2.get("ok", false)):
		push_error("Expected discard_tile to fail outside TURN_DISCARD")
		return false
	if str(discard_res_1.get("code", "")) == "" or str(discard_res_1.get("code", "")) != str(discard_res_2.get("code", "")):
		push_error("Inconsistent discard rejection codes: %s vs %s" % [str(discard_res_1.get("code", "")), str(discard_res_2.get("code", ""))])
		return false

	controller.state.players[p].has_opened = true
	var bad_add := Action.new(Action.ActionType.ADD_TO_MELD, {})
	var add_res_1: Dictionary = controller.apply_action_if_valid(p, bad_add)
	var add_res_2: Dictionary = controller.apply_action_if_valid(p, bad_add)
	if bool(add_res_1.get("ok", false)) or bool(add_res_2.get("ok", false)):
		push_error("Expected invalid ADD_TO_MELD payload to be rejected")
		return false
	if str(add_res_1.get("code", "")) == "" or str(add_res_1.get("code", "")) != str(add_res_2.get("code", "")):
		push_error("Inconsistent add-to-meld rejection codes: %s vs %s" % [str(add_res_1.get("code", "")), str(add_res_2.get("code", ""))])
		return false

	return true
