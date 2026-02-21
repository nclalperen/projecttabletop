extends RefCounted


func run() -> bool:
	return _test_failed_open_applies_deal_penalty() and _test_non_open_reject_does_not_apply_failed_open_penalty()


func _test_failed_open_applies_deal_penalty() -> bool:
	var cfg := RuleConfig.new()
	cfg.penalty_failed_open_attempt = true
	cfg.penalty_value = 101
	var controller := LocalGameController.new()
	controller.start_new_round(cfg, 4501, 4)

	controller.state.phase = GameState.Phase.TURN_PLAY
	controller.state.current_player_index = 0
	var p0 = controller.state.players[0]
	p0.has_opened = false
	p0.hand = [
		Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, 1),
		Tile.new(Tile.TileColor.RED, 2, Tile.Kind.NORMAL, 2),
		Tile.new(Tile.TileColor.RED, 3, Tile.Kind.NORMAL, 3),
	]

	var open_action := Action.new(Action.ActionType.OPEN_MELDS, {
		"melds": [{"kind": Meld.Kind.RUN, "tile_ids": [1, 2, 3]}],
		"open_by_pairs": false,
	})
	var res: Dictionary = controller.apply_action_if_valid(0, open_action)
	if bool(res.get("ok", false)):
		push_error("Open should fail because 1+2+3 < 101")
		return false
	if int(controller.state.players[0].deal_penalty_points) != 101:
		push_error("Expected +101 failed-open penalty, got %s" % int(controller.state.players[0].deal_penalty_points))
		return false
	return true


func _test_non_open_reject_does_not_apply_failed_open_penalty() -> bool:
	var cfg := RuleConfig.new()
	cfg.penalty_failed_open_attempt = true
	cfg.penalty_value = 101
	var controller := LocalGameController.new()
	controller.start_new_round(cfg, 4502, 4)

	controller.state.phase = GameState.Phase.TURN_DRAW
	controller.state.current_player_index = 0
	controller.state.deck = []
	controller.state.discard_pile = []

	var res: Dictionary = controller.draw_from_deck(0)
	if bool(res.get("ok", false)):
		push_error("draw_from_deck should fail")
		return false
	if int(controller.state.players[0].deal_penalty_points) != 0:
		push_error("Non-open reject should not apply failed-open penalty")
		return false
	return true
