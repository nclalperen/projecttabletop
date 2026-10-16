extends RefCounted

const SESSION = preload("res://ui/game_table/OkeySession.gd")

class DeferredController extends MatchControllerPort:
	var requests: Array = []
	var round_requests: int = 0
	func request_new_round() -> Dictionary:
		round_requests += 1
		return {"ok": true}
	func apply_action_if_valid(_seat: int, action: Action) -> Dictionary:
		requests.append(action)
		return {"ok": true, "code": "submitted"}

func run() -> bool:
	return _arrangement_history() and _pending_orders() and _explicit_discard() and _configuration() and _next_round_pending()

func _check(value: bool, message: String) -> bool:
	if not value:
		push_error("Okey session: " + message)
	return value

func _setup_session():
	var session = SESSION.new()
	session.bots_enabled = false
	session.configure_game(RuleConfig.new(), 1701, 4)
	session._bind_controller_signals()
	session._start_round()
	session.get_controller().state.current_player_index = 0
	session.get_controller().state.phase = GameState.Phase.TURN_PLAY
	session._sync_state()
	return session

func _arrangement_history() -> bool:
	var session = _setup_session()
	var initial: Array = session.get_rack_slots().duplicate()
	var controller = session.get_controller()
	var tile_id: int = initial[0]
	var ok: bool = _check(session.overlay_move_rack_to_draft(0, 0).ok, "stage tile")
	var staged: Array = session.get_rack_slots().duplicate()
	var before_hand: Array = session.get_hand_tiles().duplicate()
	var before_score: int = controller.state.players[0].score_total
	for i in range(4):
		session.get_view_snapshot()
	ok = _check(session.get_hand_tiles() == before_hand and controller.state.players[0].score_total == before_score, "previews must not mutate hand or scores") and ok
	controller.state.current_player_index = 1
	ok = _check(session.overlay_sort_rack("number").ok, "allow sorting during opponent turn") and ok
	ok = _check(session.get_draft_slots()[0] == tile_id and not session.get_rack_slots().has(tile_id), "sorting preserves draft partition") and ok
	ok = _check(session.overlay_undo().ok and session.get_rack_slots() == staged, "undo restores exact rack arrangement") and ok
	ok = _check(session.overlay_return_draft().ok and session.get_draft_slots()[0] == -1, "return draft during opponent turn") and ok
	ok = _check(session.overlay_undo().ok and session.get_draft_slots()[0] == tile_id, "undo restores draft partition") and ok
	controller.state.current_player_index = 0
	ok = _check(session.overlay_undo().ok and session.get_rack_slots() == initial, "undo staged move") and ok
	# Authoritative changes invalidate history and stale tile selection.
	session.overlay_move_slot(0, 1)
	session.select_tile(tile_id)
	controller.state.players[0].hand = controller.state.players[0].hand.filter(func(tile): return tile.unique_id != tile_id)
	controller.state_changed.emit(controller.state)
	ok = _check(not session.get_available_actions().undo.ok and session._selected_tile_id == -1, "snapshot removes stale selection and history") and ok
	session.free()
	return ok

func _pending_orders() -> bool:
	var ok: bool = true
	for result_first in [false, true]:
		var session = _setup_session()
		var remote := DeferredController.new()
		remote.state = session.get_controller().state
		remote.state.phase = GameState.Phase.TURN_DRAW
		# Ensure the local hand can draw independently of randomly assigned starter.
		while remote.state.players[0].hand.size() >= remote.state.rule_config.starter_tiles:
			remote.state.players[0].hand.pop_back()
		session.inject_controller(remote)
		ok = _check(session.overlay_draw_from_deck().ok and session.is_action_in_flight(), "submitted request remains pending") and ok
		ok = _check(not session.overlay_draw_from_deck().ok and remote.requests.size() == 1, "duplicate submission blocked") and ok
		if result_first:
			remote.action_applied.emit(0, -1)
		else:
			remote.state_changed.emit(remote.state)
		ok = _check(session.is_action_in_flight(), "requires both result and snapshot") and ok
		if result_first:
			remote.state_changed.emit(remote.state)
		else:
			remote.action_applied.emit(0, -1)
		ok = _check(not session.is_action_in_flight(), "both signal orders unlock") and ok
		session.overlay_draw_from_deck()
		remote.action_rejected.emit("Host rejected draw")
		ok = _check(not session.is_action_in_flight() and session.get_instruction_text() == "Host rejected draw", "rejection unlocks with reason") and ok
		session.free()
		remote.free()
	return ok

func _explicit_discard() -> bool:
	var session = _setup_session()
	var remote := DeferredController.new()
	remote.state = session.get_controller().state
	session.inject_controller(remote)
	var tile_id: int = session.get_rack_slots()[0]
	session.overlay_move_rack_to_draft(0, 0)
	var ok: bool = _check(session.overlay_end_play_then_discard(tile_id).ok, "explicit discard first sends END_PLAY")
	ok = _check(remote.requests.size() == 1 and remote.requests[0].type == Action.ActionType.END_PLAY and session.get_draft_slots()[0] == tile_id, "discard does not commit draft") and ok
	remote.action_applied.emit(0, Action.ActionType.END_PLAY)
	ok = _check(remote.requests.size() == 1, "do not discard before authoritative phase") and ok
	remote.state.phase = GameState.Phase.TURN_DISCARD
	remote.state_changed.emit(remote.state)
	ok = _check(remote.requests.size() == 2 and remote.requests[1].type == Action.ActionType.DISCARD and int(remote.requests[1].payload.tile_id) == tile_id, "follow-up uses exact selected tile") and ok
	remote.action_rejected.emit("Discard rejected")
	ok = _check(not session.is_action_in_flight() and session.get_draft_slots()[0] == tile_id, "failed discard preserves local draft") and ok
	session.free()
	remote.free()
	# Synchronous local signals also complete both actions without nesting submissions.
	session = _setup_session()
	tile_id = session.get_rack_slots()[0]
	ok = _check(session.overlay_end_play_then_discard(tile_id).ok and not session.is_action_in_flight() and not session.get_rack_slots().has(tile_id), "local end/discard finishes synchronously") and ok
	session.free()
	return ok

func _configuration() -> bool:
	var session = SESSION.new()
	session.bots_enabled = false
	var config := RuleConfig.new()
	config.timer_seconds = 45
	session.configure_game(config, 222, 2)
	session._bind_controller_signals()
	session._start_round()
	var ok: bool = _check(session.get_controller().state.rule_config == config and session._bots.size() == 4, "configuration applies rules and bots to all four dealt seats")
	session._turn_started_ms = Time.get_ticks_msec() - 7000
	session.get_controller().state.phase = GameState.Phase.TURN_PLAY
	session._sync_state()
	ok = _check(session.get_turn_seconds_remaining() <= 38, "phase transition must not reset turn timer") and ok
	session.free()
	return ok

func _next_round_pending() -> bool:
	var session = _setup_session()
	var remote := DeferredController.new()
	remote.state = session.get_controller().state
	remote.state.phase = GameState.Phase.ROUND_END
	session.inject_controller(remote)
	session.overlay_new_round()
	session.overlay_new_round()
	var ok: bool = _check(session.is_action_in_flight() and remote.round_requests == 1, "next-round request blocks repeated submissions")
	remote.state.phase = GameState.Phase.STARTER_DISCARD
	remote.state_changed.emit(remote.state)
	ok = _check(not session.is_action_in_flight(), "new-round snapshot unlocks without action result") and ok
	session.free()
	remote.free()
	return ok
