extends RefCounted


func run() -> bool:
	return _test_deck_exhausted() and _test_deck_empty_unusable_discard_ends_round() and _test_deck_empty_usable_discard_keeps_turn() and _test_rejected_draw_triggers_exhaustion_end()

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

func _test_deck_empty_unusable_discard_ends_round() -> bool:
	var controller = LocalGameController.new()
	var cfg = RuleConfig.new()
	controller.start_new_round(cfg, 1702, 4)
	var p: int = int(controller.state.current_player_index)
	controller.state.phase = controller.state.Phase.TURN_DRAW
	controller.state.current_player_index = p
	controller.state.deck = []
	controller.state.discard_pile = [Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 9100)]
	controller.state.table_melds = []
	# Opened player with empty hand cannot use discard in any immediate way.
	controller.state.players[p].has_opened = true
	controller.state.players[p].hand = []

	controller._check_deck_exhausted()
	if controller.state.phase != controller.state.Phase.ROUND_END:
		push_error("Expected ROUND_END when deck empty and discard unusable")
		return false
	return true

func _test_deck_empty_usable_discard_keeps_turn() -> bool:
	var controller = LocalGameController.new()
	var cfg = RuleConfig.new()
	controller.start_new_round(cfg, 1703, 4)
	var p: int = int(controller.state.current_player_index)
	controller.state.phase = controller.state.Phase.TURN_DRAW
	controller.state.current_player_index = p
	controller.state.deck = []
	controller.state.discard_pile = [Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 9200)]
	controller.state.players[p].has_opened = true
	controller.state.players[p].hand = []
	# Existing table run 5-6-7 red makes discard (red 8) immediately usable.
	var t1 = Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 9201)
	var t2 = Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 9202)
	var t3 = Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 9203)
	controller.state.table_melds = [Meld.new(Meld.Kind.RUN, [9201, 9202, 9203], [t1, t2, t3])]

	controller._check_deck_exhausted()
	if controller.state.phase == controller.state.Phase.ROUND_END:
		push_error("Did not expect ROUND_END when discard is legally usable")
		return false
	return true

func _test_rejected_draw_triggers_exhaustion_end() -> bool:
	var controller = LocalGameController.new()
	var cfg = RuleConfig.new()
	controller.start_new_round(cfg, 1704, 4)
	var p: int = int(controller.state.current_player_index)
	controller.state.phase = controller.state.Phase.TURN_DRAW
	controller.state.current_player_index = p
	controller.state.deck = []
	controller.state.discard_pile = [Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 9300)]
	controller.state.table_melds = []
	controller.state.players[p].has_opened = true
	controller.state.players[p].hand = []

	# This draw is invalid, but controller should still resolve no-legal-draw state into ROUND_END.
	var res: Dictionary = controller.draw_from_deck(p)
	if bool(res.get("ok", false)):
		push_error("Expected draw_from_deck to be rejected when deck is empty")
		return false
	if controller.state.phase != controller.state.Phase.ROUND_END:
		push_error("Expected ROUND_END after rejected draw with no legal discard-take")
		return false
	return true



