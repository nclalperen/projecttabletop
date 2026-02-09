extends RefCounted

func run() -> bool:
	return _test_discard_stack_tracks_owner_and_take()

func _test_discard_stack_tracks_owner_and_take() -> bool:
	var cfg := RuleConfig.new()
	cfg.require_discard_take_to_be_used = false
	cfg.discard_take_must_be_used_always = false
	cfg.if_not_opened_discard_take_requires_open_and_includes_tile = false

	var controller := LocalGameController.new()
	controller.start_new_round(cfg, 8080, 4)

	var starter: int = int(controller.state.current_player_index)
	var starter_tile = controller.state.players[starter].hand[0]
	var res: Dictionary = controller.starter_discard(starter, int(starter_tile.unique_id))
	if not bool(res.get("ok", false)):
		push_error("starter_discard failed: %s" % str(res.get("code", "")))
		return false

	if controller.state.player_discard_stacks[starter].size() != 1:
		push_error("starter discard stack not updated")
		return false
	if controller.state.discard_pile.size() != 1:
		push_error("global discard pile not updated")
		return false

	var taker: int = int(controller.state.current_player_index)
	controller.state.players[taker].has_opened = true
	res = controller.take_discard(taker)
	if not bool(res.get("ok", false)):
		push_error("take_discard failed: %s" % str(res.get("code", "")))
		return false

	if controller.state.player_discard_stacks[starter].size() != 0:
		push_error("starter discard stack not popped on take")
		return false
	if controller.state.discard_pile.size() != 0:
		push_error("global discard pile not popped on take")
		return false
	return true
