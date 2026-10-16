extends Node
## Shared Okey presentation state. Only the controller owns authoritative rules.
## Online controllers expose a seat-relative, visibility-filtered state here.

signal changed
signal feedback(reason: String)
signal session_state_updated(snapshot: Dictionary)
signal rack_and_draft_changed(rack_slots: Array, draft_slots: Array, validation: Dictionary)
signal table_melds_updated(meld_groups: Array)
signal valid_drop_targets_highlighted(tile_id: int, targets: Array)

const LOCAL_CONTROLLER = preload("res://core/controller/LocalGameController.gd")
const GEO = preload("res://ui/game_table/TableGeometry.gd")
const HELPERS = preload("res://ui/game_table/TileHelpers.gd")
const SLOTS = preload("res://ui/game_table/RackSlotManager.gd")
const DRAFT = preload("res://ui/game_table/StageMeldLogic.gd")

var _controller = LOCAL_CONTROLLER.new()
var _controller_injected_external: bool = false
var _slots = SLOTS.new()
var _draft_logic = DRAFT.new()
var _rule_config: RuleConfig
var _game_seed: int = -1
var _player_count: int = 4
var _bot_difficulties: Array = []
var _bots: Array = []
var _bot_fallback = BotRandom.new(7007)
var _bot_loop_running: bool = false
var _round_index: int = 0
var _action_in_flight: bool = false
var _pending_snapshot: bool = false
var _pending_result: bool = false
var _round_request_pending: bool = false
var _queued_discard: int = -1
var _selected_tile_id: int = -1
var _message: String = ""
var _history: Array = []
var _hand_signature: Array = []
var _turn_key: String = ""
var _turn_started_ms: int = 0
var _bot_generation: int = 0
var _active_bot_thread: Thread = null
var _pending_action_type: int = -1
var _submit_depth: int = 0
var bots_enabled: bool = true
var _available_cache: Dictionary = {}
var _draft_cache: Dictionary = {}

func _init() -> void:
	_slots.init_rack_slots()
	_slots.init_draft_slots()

func _ready() -> void:
	_bind_controller_signals()
	if not _controller_injected_external and _controller.state == null:
		_start_round()
	else:
		_sync_state()

func _exit_tree() -> void:
	_bot_generation += 1
	_unbind_controller_signals()
	# Never destroy a running Thread when the player leaves the table.
	# The coroutine may still be suspended until the next process frame.
	if _active_bot_thread != null and _active_bot_thread.is_started():
		_active_bot_thread.wait_to_finish()
	_active_bot_thread = null

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and not _controller_injected_external and is_instance_valid(_controller):
		_controller.free()

func configure_game(rule_config: RuleConfig, game_seed: int, _player_count_requested: int, bot_difficulties: Array = []) -> void:
	_rule_config = rule_config
	_game_seed = game_seed
	# Existing 101 setup always deals four seats, including single-player bots.
	_player_count = 4
	_bot_difficulties = bot_difficulties.duplicate()
	_init_bots()
	if is_inside_tree() and not _controller_injected_external:
		_bot_generation += 1
		_round_index = 0
		_controller.state = null
		_start_round()

func inject_controller(controller) -> void:
	if controller == null or controller == _controller:
		return
	_bot_generation += 1
	_unbind_controller_signals()
	if not _controller_injected_external and is_instance_valid(_controller):
		_controller.free()
	_controller = controller
	_controller_injected_external = true
	_round_request_pending = false
	_action_in_flight = false
	_queued_discard = -1
	_history.clear()
	_bind_controller_signals()
	_sync_state()

func get_controller():
	return _controller

func get_hand_tiles() -> Array:
	if _controller.state == null or _controller.state.players.is_empty():
		return []
	return _controller.state.players[0].hand

func get_rack_slots() -> Array[int]:
	return _slots.rack_slots

func get_draft_slots() -> Array[int]:
	return _slots.draft_slots

func get_draft_row_slots() -> int:
	return GEO.STAGE_ROW_SLOTS

func get_rack_tile_id_at(slot_idx: int) -> int:
	var slots: Array[int] = _slots.rack_slots
	if slot_idx >= 0 and slot_idx < slots.size():
		return slots[slot_idx]
	return -1

func get_draft_tile_id_at(slot_idx: int) -> int:
	var slots: Array[int] = _slots.draft_slots
	if slot_idx >= 0 and slot_idx < slots.size():
		return slots[slot_idx]
	return -1

func is_action_in_flight() -> bool:
	return _action_in_flight

func select_tile(tile_id: int) -> void:
	_selected_tile_id = tile_id if HELPERS.is_tile_in_hand(get_hand_tiles(), tile_id) else -1
	_emit_changed()

func cancel_selection() -> void:
	_selected_tile_id = -1
	_emit_changed()

func get_instruction_text() -> String:
	if not _message.is_empty():
		return _message
	if _action_in_flight:
		return "Waiting for the table…"
	var state = _controller.state
	if state == null:
		return "Preparing the table…"
	if state.phase == GameState.Phase.ROUND_END:
		return "Match complete" if state.match_finished else "Round complete — review the scores to continue"
	if state.current_player_index != 0:
		return "Opponent's turn — you can organize your rack"
	match state.phase:
		GameState.Phase.STARTER_DISCARD, GameState.Phase.TURN_DISCARD:
			return "Drag a tile to your right discard pile or double-click a tile to discard"
		GameState.Phase.TURN_DRAW:
			return "Click the center deck to draw, or click the left discard tile"
		GameState.Phase.TURN_PLAY:
			return "Group melds on your rack (or click Seri / Çift Diz), then discard a tile"
	return "Prepare your tiles"

func get_turn_seconds_remaining() -> int:
	if _controller.state == null or _controller.state.rule_config == null:
		return 0
	var seconds: int = _controller.state.rule_config.timer_seconds
	return maxi(0, seconds - int((Time.get_ticks_msec() - _turn_started_ms) / 1000)) if seconds > 0 else 0

func get_view_snapshot() -> Dictionary:
	return {"state": _controller.state, "hand": get_hand_tiles(), "rack_slots": get_rack_slots(),
		"draft_slots": get_draft_slots(), "selected_tile_id": _selected_tile_id,
		"instruction": get_instruction_text(), "pending": _action_in_flight,
		"draft_preview": get_draft_preview(), "available_actions": get_available_actions(),
		"turn_seconds_remaining": get_turn_seconds_remaining()}

func _preview_action(action: Action) -> Dictionary:
	if _controller.state == null or _controller.state.players.is_empty():
		return {"ok": false, "reason": "The table is not ready"}
	if _controller.state.match_finished:
		return {"ok": false, "reason": "The match is complete"}
	if _action_in_flight:
		return {"ok": false, "reason": "Waiting for the previous action"}
	return Validator.new().validate_action(_controller.state, 0, action)

func get_available_actions() -> Dictionary:
	if not _available_cache.is_empty():
		return _available_cache
	var discard_type: int = Action.ActionType.DISCARD
	if _controller.state != null and _controller.state.phase == GameState.Phase.STARTER_DISCARD:
		discard_type = Action.ActionType.STARTER_DISCARD
	var discard: Dictionary = _preview_action(Action.new(discard_type, {"tile_id": _selected_tile_id}))
	if _controller.state != null and _controller.state.phase == GameState.Phase.TURN_PLAY:
		discard = _preview_action(Action.new(Action.ActionType.END_PLAY, {}))
		if bool(discard.get("ok", false)):
			# Validate the exact intended discard against a shallow phase projection.
			# Never change the live snapshot while painting controls.
			var projected = GameState.new()
			projected.players = _controller.state.players
			projected.rule_config = _controller.state.rule_config
			projected.current_player_index = _controller.state.current_player_index
			projected.turn_required_use_tile_id = _controller.state.turn_required_use_tile_id
			projected.phase = GameState.Phase.TURN_DISCARD
			discard = Validator.new().validate_action(projected, 0, Action.new(Action.ActionType.DISCARD, {"tile_id": _selected_tile_id}))
		if _selected_tile_id == -1:
			discard = {"ok": false, "reason": "Select a tile to discard"}
	_available_cache = {"draw": _preview_action(Action.new(Action.ActionType.DRAW_FROM_DECK, {})),
		"take_discard": _preview_action(Action.new(Action.ActionType.TAKE_DISCARD, {})),
		"discard": discard, "commit": get_draft_preview(),
		"undo": {"ok": not _history.is_empty() and not _action_in_flight},
		"return_draft": {"ok": _slots.has_draft_tiles() and not _action_in_flight}}
	return _available_cache

func get_draft_preview() -> Dictionary:
	if not _draft_cache.is_empty():
		return _draft_cache
	var state = _controller.state
	var out: Dictionary = {"ok": false, "reason": "Group runs/sets on your rack with a gap", "melds": [],
		"points": 0, "pairs": 0, "threshold": 101, "required_tile_id": -1, "valid_tile_ids": []}
	if state == null or state.players.is_empty():
		_draft_cache = out
		return out
	out.threshold = int(state.rule_config.open_min_points_initial)
	out.required_tile_id = int(state.turn_required_use_tile_id)
	if not _slots.has_draft_tiles():
		var rack_eval: Dictionary = _draft_logic.evaluate_rack_melds(state, get_hand_tiles(), get_rack_slots(), 15, _pair_key_for_tile)
		var series_melds: Array = rack_eval.get("series_melds", [])
		var series_pts: int = int(rack_eval.get("series_points", 0))
		var pair_melds: Array = rack_eval.get("pair_melds", [])
		var pair_cnt: int = int(rack_eval.get("pair_count", 0))
		out.points = series_pts
		out.pairs = pair_cnt
		if state.players[0].has_opened:
			if not bool(state.players[0].opened_by_pairs) and not series_melds.is_empty():
				var open_val: Dictionary = _preview_action(Action.new(Action.ActionType.OPEN_MELDS, {"melds": series_melds, "open_by_pairs": false}))
				out.melds = series_melds
				out.valid_tile_ids = rack_eval.get("series_tile_ids", [])
				out.ok = bool(open_val.get("ok", false))
				out.reason = str(open_val.get("reason", ""))
		else:
			var series_val: Dictionary = _preview_action(Action.new(Action.ActionType.OPEN_MELDS, {"melds": series_melds, "open_by_pairs": false})) if not series_melds.is_empty() else {"ok": false, "reason": "Need %d points to open" % out.threshold}
			var pairs_val: Dictionary = _preview_action(Action.new(Action.ActionType.OPEN_MELDS, {"melds": pair_melds, "open_by_pairs": true})) if not pair_melds.is_empty() else {"ok": false, "reason": "Need 5 pairs to open"}
			if bool(series_val.get("ok", false)):
				out.melds = series_melds
				out.valid_tile_ids = rack_eval.get("series_tile_ids", [])
				out.ok = true
				out.reason = ""
			elif bool(pairs_val.get("ok", false)):
				out.melds = pair_melds
				out.valid_tile_ids = rack_eval.get("pair_tile_ids", [])
				out.ok = true
				out.reason = ""
			elif pair_cnt >= 3 and series_pts < 60:
				out.melds = pair_melds
				out.valid_tile_ids = rack_eval.get("pair_tile_ids", [])
				out.reason = str(pairs_val.get("reason", "Need 5 pairs to open"))
			else:
				out.melds = series_melds
				out.valid_tile_ids = rack_eval.get("series_tile_ids", [])
				out.reason = str(series_val.get("reason", "Need %d points to open" % out.threshold))
		_draft_cache = out
		return out
	var melds: Array
	if state.players[0].has_opened:
		melds = _draft_logic.build_new_melds_from_draft_slots_opened(state, get_hand_tiles(), get_draft_slots(), get_draft_row_slots())
	else:
		melds = _draft_logic.build_melds_from_draft_slots(state, get_hand_tiles(), get_draft_slots(), get_draft_row_slots(), _pair_key_for_tile)
	var used: Array = []
	var all_pairs: bool = not melds.is_empty()
	var validator := MeldValidator.new()
	for meld in melds:
		var tiles: Array = []
		for tile in get_hand_tiles():
			if meld.tile_ids.has(tile.unique_id):
				tiles.append(tile)
		used.append_array(meld.tile_ids)
		if meld.kind == Meld.Kind.PAIRS:
			out.pairs += 1
		else:
			all_pairs = false
			var validation: Dictionary = validator.validate_run(tiles, state.okey_context) if meld.kind == Meld.Kind.RUN else validator.validate_set(tiles, state.okey_context)
			out.points += int(validation.get("points_value", 0))
	out.melds = melds
	out.valid_tile_ids = used
	if used.size() != _slots.all_draft_tile_ids().size():
		out.reason = "Complete every group; leave a gap between groups"
		_draft_cache = out
		return out
	var validation: Dictionary = _preview_action(Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds, "open_by_pairs": all_pairs}))
	out.ok = bool(validation.get("ok", false))
	out.reason = str(validation.get("reason", ""))
	_draft_cache = out
	return out

func _submit(action: Action) -> Dictionary:
	if _action_in_flight:
		return _reject("Waiting for the previous action")
	# Preview never calls the controller's mutating apply path.
	var preview := _preview_action(action)
	if not bool(preview.get("ok", false)):
		return _reject(str(preview.get("reason", "Action unavailable")))
	_action_in_flight = true
	_pending_action_type = action.type
	_pending_snapshot = false
	_pending_result = false
	_message = ""
	_emit_changed()
	_submit_depth += 1
	var result: Dictionary = _controller.apply_action_if_valid(0, action)
	_submit_depth -= 1
	if not bool(result.get("ok", false)) and _action_in_flight:
		_on_action_rejected(str(result.get("reason", "Action rejected")))
	if _queued_discard != -1 and not _action_in_flight:
		_continue_queued_discard()
	return result

func overlay_draw_from_deck() -> Dictionary:
	return _submit(Action.new(Action.ActionType.DRAW_FROM_DECK, {}))

func overlay_take_discard() -> Dictionary:
	return _submit(Action.new(Action.ActionType.TAKE_DISCARD, {}))

func overlay_discard_tile(tile_id: int) -> Dictionary:
	if _controller.state != null and _controller.state.phase == GameState.Phase.TURN_PLAY:
		return overlay_end_play_then_discard(tile_id)
	var action_type: int = Action.ActionType.STARTER_DISCARD if _controller.state != null and _controller.state.phase == GameState.Phase.STARTER_DISCARD else Action.ActionType.DISCARD
	return _submit(Action.new(action_type, {"tile_id": tile_id}))

func overlay_end_play_then_discard(tile_id: int) -> Dictionary:
	if _action_in_flight:
		return _reject("Waiting for the previous action")
	if not HELPERS.is_tile_in_hand(get_hand_tiles(), tile_id):
		return _reject("Select a tile from your hand")
	_queued_discard = tile_id
	var result := overlay_end_play()
	if not bool(result.get("ok", false)):
		_queued_discard = -1
	return result

func overlay_end_play() -> Dictionary:
	return _submit(Action.new(Action.ActionType.END_PLAY, {}))

func overlay_add_to_meld(tile_ids: Array, meld_index: int) -> Dictionary:
	return _submit(Action.new(Action.ActionType.ADD_TO_MELD, {"target_meld_index": meld_index, "tile_ids": tile_ids}))

func overlay_commit_draft() -> Dictionary:
	var preview := get_draft_preview()
	if not preview.ok:
		return _reject(str(preview.reason))
	var all_pairs: bool = true
	for meld in preview.melds:
		if meld.kind != Meld.Kind.PAIRS:
			all_pairs = false
	return _submit(Action.new(Action.ActionType.OPEN_MELDS, {"melds": preview.melds, "open_by_pairs": all_pairs}))

func overlay_return_draft() -> Dictionary:
	if _action_in_flight or not _slots.has_draft_tiles():
		return {"ok": false, "reason": "No draft to return"}
	_save_arrangement()
	_slots.restore_draft_to_rack()
	_emit_changed()
	return {"ok": true}

func _save_arrangement() -> void:
	_history.append({"rack": get_rack_slots().duplicate(), "draft": get_draft_slots().duplicate()})
	if _history.size() > 30:
		_history.pop_front()

func overlay_undo() -> Dictionary:
	if _action_in_flight or _history.is_empty():
		return {"ok": false, "reason": "No arrangement to undo"}
	var previous: Dictionary = _history.pop_back()
	_slots.rack_slots.assign(previous.rack)
	_slots.draft_slots.assign(previous.draft)
	_slots.sync_slots_with_hand(get_hand_tiles())
	_emit_changed()
	return {"ok": true}

func overlay_sort_rack(mode: String = "color") -> Dictionary:
	if _action_in_flight:
		return {"ok": false, "reason": "Waiting for the previous action"}
	_save_arrangement()
	var tiles: Array = []
	for tile in get_hand_tiles():
		if get_rack_slots().has(tile.unique_id):
			tiles.append(tile)
	var okey_ctx = _controller.state.okey_context if _controller.state != null else null
	var sorted_slots: Array = _draft_logic.smart_sort_rack_tiles(
		tiles,
		okey_ctx,
		mode,
		func(t): return _pair_key_for_tile(t)
	)
	_slots.rack_slots.assign(sorted_slots)
	_emit_changed()
	return {"ok": true}

func _move(kind: String, source: int, destination: int) -> Dictionary:
	if _action_in_flight or _controller.state == null:
		return {"ok": false, "reason": "Table busy"}
	if kind != "rack" and (_controller.state.current_player_index != 0 or _controller.state.phase != GameState.Phase.TURN_PLAY):
		return {"ok": false, "reason": "Build melds after drawing on your turn"}
	var previous: Dictionary = {"rack": get_rack_slots().duplicate(), "draft": get_draft_slots().duplicate()}
	var moved: bool = false
	match kind:
		"rack": moved = _slots.insert_rack_slot(source, destination)
		"to_draft": moved = _slots.move_rack_to_draft(source, destination, GEO.STAGE_ROW_SLOTS, GEO.STAGE_SLOT_COUNT)
		"to_rack": moved = _slots.move_draft_to_rack(source, destination)
		"draft": moved = _slots.move_draft_slot(source, destination)
	if not moved:
		return {"ok": false, "reason": "Choose a valid destination"}
	_history.append(previous)
	if _history.size() > 30:
		_history.pop_front()
	_message = ""
	_emit_changed()
	return {"ok": true}

func overlay_move_slot(source: int, destination: int) -> Dictionary:
	return _move("rack", source, destination)

func overlay_move_rack_to_draft(source: int, destination: int) -> Dictionary:
	return _move("to_draft", source, destination)

func overlay_move_draft_to_rack(source: int, destination: int) -> Dictionary:
	return _move("to_rack", source, destination)

func overlay_move_draft_slot(source: int, destination: int) -> Dictionary:
	return _move("draft", source, destination)

func overlay_new_round() -> void:
	if _action_in_flight:
		_reject("Waiting for the previous action")
		return
	if _controller.state != null and _controller.state.match_finished:
		_reject("Match complete — return to the menu to start a new match")
		return
	if _controller.state != null and _controller.state.phase != GameState.Phase.ROUND_END:
		_reject("Finish this round before continuing")
		return
	if _controller_injected_external:
		_round_request_pending = true
		_action_in_flight = true
		_emit_changed()
		var result: Dictionary = _controller.request_new_round()
		if not bool(result.get("ok", false)):
			_on_action_rejected(str(result.get("reason", "Only the host can start the next round")))
		return
	_start_round()

func _start_round() -> void:
	if _controller_injected_external:
		return
	_bot_generation += 1
	_turn_key = ""
	_message = ""
	_slots.init_rack_slots()
	_slots.init_draft_slots()
	_history.clear()
	_selected_tile_id = -1
	_queued_discard = -1
	_round_request_pending = false
	_action_in_flight = false
	_controller.start_new_round(_rule_config if _rule_config != null else RuleConfig.new(), GEO.compute_round_seed(_game_seed, _round_index), _player_count)
	_round_index += 1
	_sync_state()
	if is_inside_tree():
		call_deferred("_maybe_auto_bot_turn")

func _pair_key_for_tile(tile) -> String:
	return HELPERS.pair_key_for_tile(tile, _controller.state.okey_context if _controller.state != null else null)

func _reject(reason: String) -> Dictionary:
	_message = reason
	feedback.emit(reason)
	_emit_changed()
	return {"ok": false, "reason": reason}

func _sync_state() -> void:
	var signature: Array = []
	for tile in get_hand_tiles():
		signature.append(int(tile.unique_id))
	signature.sort()
	if signature != _hand_signature:
		_history.clear()
		_hand_signature = signature
	_slots.sync_slots_with_hand(get_hand_tiles())
	if not signature.has(_selected_tile_id):
		_selected_tile_id = -1
	if _controller.state != null:
		var key: String = "%d:%d" % [_controller.state.round_index, _controller.state.current_player_index]
		if key != _turn_key:
			_turn_started_ms = Time.get_ticks_msec()
			_turn_key = key
	_emit_changed()

func _on_state_changed(_state) -> void:
	if _round_request_pending and _controller.state != null and _controller.state.phase != GameState.Phase.ROUND_END:
		_round_request_pending = false
		_action_in_flight = false
	_pending_snapshot = true
	_message = ""
	_sync_state()
	_finish_pending()
	if is_inside_tree():
		call_deferred("_maybe_auto_bot_turn")

func _on_action_applied(player_index: int, action_type: int) -> void:
	if player_index == 0 and _action_in_flight and action_type in [-1, _pending_action_type]:
		_pending_result = true
		_history.clear()
		_finish_pending()

func _finish_pending() -> void:
	if not _action_in_flight or not _pending_snapshot or not _pending_result:
		return
	_action_in_flight = false
	_emit_changed()
	if _submit_depth == 0:
		_continue_queued_discard()

func _continue_queued_discard() -> void:
	if _queued_discard != -1:
		var tile_id: int = _queued_discard
		_queued_discard = -1
		if _controller.state != null and _controller.state.current_player_index == 0 and _controller.state.phase == GameState.Phase.TURN_DISCARD:
			overlay_discard_tile(tile_id)

func _on_action_rejected(reason: String) -> void:
	_round_request_pending = false
	_action_in_flight = false
	_queued_discard = -1
	_reject(reason)

func _bind_controller_signals() -> void:
	for binding in [["state_changed", _on_state_changed], ["action_rejected", _on_action_rejected], ["action_applied", _on_action_applied]]:
		if not _controller.is_connected(binding[0], binding[1]):
			_controller.connect(binding[0], binding[1])

func _unbind_controller_signals() -> void:
	if not is_instance_valid(_controller):
		return
	for binding in [["state_changed", _on_state_changed], ["action_rejected", _on_action_rejected], ["action_applied", _on_action_applied]]:
		if _controller.is_connected(binding[0], binding[1]):
			_controller.disconnect(binding[0], binding[1])

func _init_bots() -> void:
	_bots = [null]
	for seat in range(1, _player_count):
		_bots.append(BotBase.create(str(_bot_difficulties[seat - 1]) if seat - 1 < _bot_difficulties.size() else "Normal", _game_seed + seat))

func _compute_bot_action_async(bot, state, bot_index: int):
	var scene_tree = get_tree()
	if scene_tree == null or (_active_bot_thread != null and _active_bot_thread.is_started()):
		return null
	var result: Array = [null]
	var thread := Thread.new()
	_active_bot_thread = thread
	var started: Error = thread.start(func(): result[0] = bot.choose_action(state, bot_index))
	if started != OK:
		_active_bot_thread = null
		return null
	while thread.is_alive():
		await scene_tree.process_frame
		if not is_inside_tree():
			break
	# _exit_tree may already have joined this thread while we were suspended.
	if thread.is_started():
		thread.wait_to_finish()
	if _active_bot_thread == thread:
		_active_bot_thread = null
	return result[0] if is_inside_tree() else null

func _maybe_auto_bot_turn() -> void:
	if not bots_enabled or _controller_injected_external or _bot_loop_running or _controller.state == null:
		return
	if _bots.is_empty():
		_init_bots()
	_bot_loop_running = true
	var generation: int = _bot_generation
	var safety: int = 0
	while bots_enabled and generation == _bot_generation and is_inside_tree() and _controller.state != null and _controller.state.phase != GameState.Phase.ROUND_END and _controller.state.current_player_index != 0 and safety < 96:
		safety += 1
		await get_tree().create_timer(0.18).timeout
		if not bots_enabled or generation != _bot_generation or not is_inside_tree() or _controller_injected_external or _controller.state == null or _controller.state.phase == GameState.Phase.ROUND_END or _controller.state.current_player_index == 0:
			break
		var seat: int = _controller.state.current_player_index
		var state_before = _controller.state
		var action = await _compute_bot_action_async(_bots[seat], state_before, seat)
		if not bots_enabled or generation != _bot_generation or not is_inside_tree() or _controller.state != state_before:
			break
		if action == null:
			action = await _compute_bot_action_async(_bot_fallback, state_before, seat)
		if not bots_enabled or generation != _bot_generation or not is_inside_tree() or _controller.state != state_before:
			break
		if action == null:
			_reject("Opponent could not find a legal action")
			break
		var result: Dictionary = _controller.apply_action_if_valid(seat, action)
		if not bool(result.get("ok", false)):
			var fallback_state = _controller.state
			var fallback = await _compute_bot_action_async(_bot_fallback, fallback_state, seat)
			if not bots_enabled or generation != _bot_generation or not is_inside_tree() or _controller.state != fallback_state:
				break
			if fallback == null or not bool(_controller.apply_action_if_valid(seat, fallback).get("ok", false)):
				_reject("Opponent could not continue: %s" % result.get("reason", "unknown action"))
				break
	_bot_loop_running = false
	if is_inside_tree() and generation != _bot_generation:
		call_deferred("_maybe_auto_bot_turn")

func request_draw_from_deck() -> Dictionary:
	return overlay_draw_from_deck()

func request_take_discard() -> Dictionary:
	return overlay_take_discard()

func request_move_tile(from_zone: StringName, from_idx: int, to_zone: StringName, to_idx: int) -> Dictionary:
	if from_zone == &"RACK" and to_zone == &"RACK":
		return overlay_move_slot(from_idx, to_idx)
	elif from_zone == &"RACK" and to_zone == &"DRAFT":
		return overlay_move_rack_to_draft(from_idx, to_idx)
	elif from_zone == &"DRAFT" and to_zone == &"RACK":
		return overlay_move_draft_to_rack(from_idx, to_idx)
	elif from_zone == &"DRAFT" and to_zone == &"DRAFT":
		return overlay_move_draft_slot(from_idx, to_idx)
	return _reject("Invalid zone transition")

func request_commit_staged_melds() -> Dictionary:
	return overlay_commit_draft()

func request_extend_table_meld(tile_id: int, meld_index: int, _insert_position: int = 0) -> Dictionary:
	return overlay_add_to_meld([tile_id], meld_index)

func request_discard_tile(tile_id: int) -> Dictionary:
	return overlay_discard_tile(tile_id)

func request_sort_rack(mode: StringName = &"color") -> Dictionary:
	return overlay_sort_rack(String(mode))

func request_undo() -> Dictionary:
	return overlay_undo()

func request_return_draft() -> Dictionary:
	return overlay_return_draft()

func _get_turn_phase_name() -> StringName:
	if _controller.state == null:
		return &"WAIT"
	match _controller.state.phase:
		GameState.Phase.TURN_DRAW:
			return &"DRAW"
		GameState.Phase.TURN_PLAY:
			return &"PLAY_AND_DISCARD"
		GameState.Phase.TURN_DISCARD, GameState.Phase.STARTER_DISCARD:
			return &"PLAY_AND_DISCARD"
		GameState.Phase.ROUND_END:
			return &"ROUND_END"
		_:
			return &"WAIT"

func _get_seats_snapshot() -> Array:
	var seats: Array = []
	if _controller.state == null:
		return seats
	for i in range(_controller.state.players.size()):
		var p = _controller.state.players[i]
		seats.append({
			"seat_index": i,
			"name": "YOU" if i == 0 else "Player %d" % (i + 1),
			"is_local": i == 0,
			"is_turn": i == _controller.state.current_player_index,
			"tile_count": p.hand.size(),
			"has_opened": bool(p.has_opened),
			"score": int(p.score_total)
		})
	return seats

func _emit_changed() -> void:
	_available_cache = {}
	_draft_cache = {}
	changed.emit()

	var state = _controller.state
	var is_local_turn: bool = state != null and state.current_player_index == 0
	var phase_name: StringName = _get_turn_phase_name()
	var can_take: bool = bool(get_available_actions().get("take_discard", {}).get("ok", false))

	var indicator = state.okey_context.indicator_tile if state != null and state.okey_context != null else null
	var snapshot: Dictionary = {
		"is_local_turn": is_local_turn,
		"turn_phase": phase_name,
		"round_index": state.round_index if state != null else 0,
		"deck_count": state.deck.size() if state != null else 0,
		"indicator_tile": indicator,
		"okey_context": state.okey_context if state != null else null,
		"can_take_discard": can_take,
		"selected_tile_id": _selected_tile_id,
		"instruction": get_instruction_text(),
		"turn_seconds_remaining": get_turn_seconds_remaining(),
		"seats": _get_seats_snapshot(),
	}
	session_state_updated.emit(snapshot)

	var draft_preview := get_draft_preview()
	var valid_ids: Array = draft_preview.get("valid_tile_ids", [])
	var draft_count: int = _slots.all_draft_tile_ids().size()
	var staged_count: int = draft_count if draft_count > 0 else valid_ids.size()
	var validation: Dictionary = {
		"valid_points": int(draft_preview.get("points", 0)),
		"valid_pairs": int(draft_preview.get("pairs", 0)),
		"opening_threshold": int(draft_preview.get("threshold", 101)),
		"is_player_open": state != null and not state.players.is_empty() and bool(state.players[0].has_opened),
		"can_commit": bool(draft_preview.get("ok", false)),
		"staged_tile_count": staged_count,
		"has_draft_tiles": draft_count > 0,
		"valid_tile_ids": valid_ids,
		"reason": str(draft_preview.get("reason", ""))
	}
	rack_and_draft_changed.emit(get_rack_slots(), get_draft_slots(), validation)

	if state != null and "table_melds" in state and state.table_melds is Array:
		table_melds_updated.emit(state.table_melds)
