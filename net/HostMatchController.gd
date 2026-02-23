extends "res://core/controller/MatchControllerPort.gd"
class_name HostMatchController

const REJOIN_WINDOW_SEC: int = 90
const PROTOCOL_SCRIPT: Script = preload("res://net/Protocol.gd")
const SEAT_ADAPTER_SCRIPT: Script = preload("res://core/network/SeatViewAdapter.gd")
const STATE_CODEC_SCRIPT: Script = preload("res://core/network/StateCodec.gd")
static var _test_tracked_instances: Array = []

var _core: LocalGameController = LocalGameController.new()
var _transport = null
var _local_puid: String = ""
var _match_id: String = ""
var _match_seed: int = 0
var _seat_by_puid: Dictionary = {}
var _puid_by_seat: Dictionary = {}
var _last_seq_by_puid: Dictionary = {}
var _turn_id: int = 0
var _bot_seats: Dictionary = {}
var _disconnect_expiry_by_puid: Dictionary = {}
var _bot_ai: BotHeuristic = BotHeuristic.new()
var _bot_fallback: BotRandom = BotRandom.new(20260221)
var _bot_loop_running: bool = false

func _init() -> void:
	if OS.has_feature("editor"):
		_test_tracked_instances.append(self)
	_core.state_changed.connect(_on_core_state_changed)
	_core.action_rejected.connect(func(reason: String) -> void:
		emit_signal("action_rejected", reason)
	)
	_core.action_applied.connect(_on_core_action_applied)
	_core.turn_advanced.connect(_on_core_turn_advanced)
	_core.match_finished.connect(_on_core_match_finished)

func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE:
		return
	if OS.has_feature("editor"):
		_test_tracked_instances.erase(self)
	if _transport != null and _transport.packet_received.is_connected(_on_transport_packet):
		_transport.packet_received.disconnect(_on_transport_packet)
	_transport = null
	if _core != null and is_instance_valid(_core):
		_core.free()
	_core = null

static func free_test_tracked_instances() -> void:
	for i in range(_test_tracked_instances.size() - 1, -1, -1):
		var inst = _test_tracked_instances[i]
		if inst != null and is_instance_valid(inst):
			inst.free()
	_test_tracked_instances.clear()

func configure_host(local_puid: String, transport, seat_by_puid: Dictionary, match_id: String = "", match_seed: int = 0) -> void:
	_local_puid = String(local_puid)
	_match_id = match_id if match_id != "" else "M_%08x" % int(abs(hash("%s|%s" % [_local_puid, Time.get_unix_time_from_system()])))
	_match_seed = match_seed
	_set_seat_map(seat_by_puid)
	if _transport != null and _transport.packet_received.is_connected(_on_transport_packet):
		_transport.packet_received.disconnect(_on_transport_packet)
	_transport = transport
	if _transport != null and not _transport.packet_received.is_connected(_on_transport_packet):
		_transport.packet_received.connect(_on_transport_packet)
	if _transport != null and _local_puid != "":
		_transport.open_endpoint(_local_puid)

func start_new_match(rule_config: RuleConfig, rng_seed: int, player_count: int = 4) -> void:
	_match_seed = rng_seed
	_core.start_new_match(rule_config, rng_seed, player_count)
	_turn_id = 0
	_broadcast_welcome_to_all()
	_broadcast_state_snapshot(false)

func start_new_round(rule_config: RuleConfig, rng_seed: int, player_count: int = 4) -> void:
	_match_seed = rng_seed
	_core.start_new_round(rule_config, rng_seed, player_count)
	_broadcast_state_snapshot(false)

func submit_action_envelope(action_dict: Dictionary) -> Dictionary:
	return _apply_client_action(_local_puid, action_dict, -1, false)

func apply_action_if_valid(player_index: int, action: Action) -> Dictionary:
	var envelope: Dictionary = _envelope_from_action(player_index, action)
	if envelope.is_empty():
		return {"ok": false, "code": "unsupported_action", "reason": "unsupported action"}
	return submit_action_envelope(envelope)

func starter_discard(player_index: int, tile_id: int) -> Dictionary:
	return submit_action_envelope({"type": "STARTER_DISCARD", "player_id": player_index, "payload": {"tile_id": tile_id}})

func draw_from_deck(player_index: int) -> Dictionary:
	return submit_action_envelope({"type": "DRAW_FROM_DECK", "player_id": player_index, "payload": {}})

func take_discard(player_index: int) -> Dictionary:
	return submit_action_envelope({"type": "TAKE_DISCARD", "player_id": player_index, "payload": {}})

func end_play_turn(player_index: int) -> Dictionary:
	return submit_action_envelope({"type": "END_PLAY", "player_id": player_index, "payload": {}})

func discard_tile(player_index: int, tile_id: int) -> Dictionary:
	return submit_action_envelope({"type": "DISCARD", "player_id": player_index, "payload": {"tile_id": tile_id}})

func apply_manual_penalty(player_index: int, points: int) -> void:
	var abs_seat: int = _local_to_abs(player_index)
	_core.apply_manual_penalty(abs_seat, points)

func request_new_round() -> Dictionary:
	if _core.state == null:
		return {"ok": false, "code": "state_missing", "reason": "state is not initialized"}
	if int(_core.state.phase) != int(GameState.Phase.ROUND_END):
		return {"ok": false, "code": "phase", "reason": "round is not finished"}
	var cfg: RuleConfig = _core.state.rule_config if _core.state.rule_config != null else RuleConfig.new()
	var next_seed: int = _match_seed + int(_core.state.round_index)
	_core.start_new_round(cfg, next_seed, _core.state.players.size())
	_broadcast_state_snapshot(false)
	return {"ok": true, "code": "ok", "reason": ""}

func mark_peer_disconnected(puid: String) -> void:
	if not _seat_by_puid.has(puid):
		return
	var seat: int = int(_seat_by_puid[puid])
	_bot_seats[seat] = true
	_disconnect_expiry_by_puid[puid] = int(Time.get_unix_time_from_system()) + REJOIN_WINDOW_SEC
	_maybe_drive_bot_turn()

func mark_peer_reconnected(puid: String) -> void:
	if not _seat_by_puid.has(puid):
		return
	var seat: int = int(_seat_by_puid[puid])
	_bot_seats.erase(seat)
	_disconnect_expiry_by_puid.erase(puid)

func _on_transport_packet(from_puid: String, message: Dictionary) -> void:
	if from_puid == _local_puid:
		return
	var vr: Dictionary = PROTOCOL_SCRIPT.validate_client_message(message)
	if not bool(vr.get("ok", false)):
		_send_action_result(from_puid, int(message.get("seq", -1)), false, String(vr.get("code", "invalid_message")), String(vr.get("reason", "Invalid message")), 0)
		return
	var msg_type: String = String(message.get("type", ""))
	match msg_type:
		PROTOCOL_SCRIPT.C_HELLO:
			_send_welcome(from_puid)
			_send_snapshot(from_puid, false)
		PROTOCOL_SCRIPT.C_PING:
			_send_packet(from_puid, PROTOCOL_SCRIPT.wrap(PROTOCOL_SCRIPT.S_PONG, {
				"t_client_ms": int(message.get("t_client_ms", 0)),
				"t_host_ms": Time.get_ticks_msec(),
			}))
		PROTOCOL_SCRIPT.C_REJOIN_REQUEST:
			mark_peer_reconnected(from_puid)
			_send_snapshot(from_puid, true)
		PROTOCOL_SCRIPT.C_ACTION_REQUEST:
			var seq: int = int(message.get("seq", -1))
			var action: Dictionary = message.get("action", {})
			var res: Dictionary = _apply_client_action(from_puid, action, seq, true)
			_send_action_result(from_puid, seq, bool(res.get("ok", false)), String(res.get("code", "unknown")), String(res.get("reason", "")), int(res.get("state_hash", 0)))
		PROTOCOL_SCRIPT.C_REQUEST_NEW_ROUND:
			_send_action_result(from_puid, int(message.get("seq", -1)), false, "not_host", "only host can start next round", 0)

func _apply_client_action(from_puid: String, envelope: Dictionary, seq: int, require_seq: bool) -> Dictionary:
	if not _seat_by_puid.has(from_puid):
		return {"ok": false, "code": "unknown_peer", "reason": "peer not in seat map"}
	if require_seq:
		var last_seq: int = int(_last_seq_by_puid.get(from_puid, -1))
		if seq <= last_seq:
			return {"ok": false, "code": "duplicate_or_old_seq", "reason": "stale seq"}
		_last_seq_by_puid[from_puid] = seq

	if typeof(envelope) != TYPE_DICTIONARY:
		return {"ok": false, "code": "invalid_envelope", "reason": "envelope must be dictionary"}
	var local_player_id: int = int(envelope.get("player_id", -1))
	if local_player_id < 0:
		return {"ok": false, "code": "missing_player_id", "reason": "player_id required"}
	var abs_seat: int = int(_seat_by_puid[from_puid])
	var player_count: int = _seat_by_puid.size()
	var abs_player_id: int = SEAT_ADAPTER_SCRIPT.to_abs(local_player_id, abs_seat, player_count)

	var abs_envelope: Dictionary = envelope.duplicate(true)
	abs_envelope["player_id"] = abs_player_id
	var res: Dictionary = _core.submit_action_envelope(abs_envelope)
	if bool(res.get("ok", false)):
		_turn_id += 1
		_broadcast_state_snapshot(false)
	return res

func _on_core_state_changed(new_state) -> void:
	if new_state == null:
		state = null
		emit_signal("state_changed", state)
		return
	state = STATE_CODEC_SCRIPT.decode_client_snapshot(STATE_CODEC_SCRIPT.encode_for_client(new_state, _host_abs_seat()))
	emit_signal("state_changed", state)
	_maybe_drive_bot_turn()

func _on_core_action_applied(abs_player_index: int, action_type: int) -> void:
	emit_signal("action_applied", _abs_to_local(int(abs_player_index)), action_type)

func _on_core_turn_advanced(abs_current_player: int, phase: int) -> void:
	emit_signal("turn_advanced", _abs_to_local(int(abs_current_player)), phase)

func _on_core_match_finished(abs_winners: Array, final_scores: Array, reason: String) -> void:
	var player_count: int = _seat_by_puid.size()
	var local_winners: Array = []
	for idx in abs_winners:
		local_winners.append(SEAT_ADAPTER_SCRIPT.to_local(int(idx), _host_abs_seat(), player_count))
	emit_signal("match_finished", local_winners, final_scores.duplicate(true), reason)
	_broadcast_match_event("match_finished", {
		"winner_indices": local_winners,
		"final_scores": final_scores.duplicate(true),
		"reason": reason,
	})

func _maybe_drive_bot_turn() -> void:
	if _bot_loop_running:
		return
	if _core.state == null:
		return
	if int(_core.state.phase) == int(GameState.Phase.ROUND_END):
		return
	_bot_loop_running = true
	var safety: int = 0
	while _core.state != null and int(_core.state.phase) != int(GameState.Phase.ROUND_END) and safety < 96:
		safety += 1
		var seat: int = int(_core.state.current_player_index)
		if not bool(_bot_seats.get(seat, false)):
			break
		var action: Action = _bot_ai.choose_action(_core.state, seat)
		if action == null:
			action = _bot_fallback.choose_action(_core.state, seat)
		if action == null:
			break
		var res: Dictionary = _core.apply_action_if_valid(seat, action)
		if not bool(res.get("ok", false)):
			break
	_bot_loop_running = false

func _broadcast_welcome_to_all() -> void:
	for puid in _seat_by_puid.keys():
		if String(puid) == _local_puid:
			continue
		_send_welcome(String(puid))

func _send_welcome(peer_puid: String) -> void:
	_send_packet(peer_puid, PROTOCOL_SCRIPT.wrap(PROTOCOL_SCRIPT.S_WELCOME, {
		"match_id": _match_id,
		"host_puid": _local_puid,
		"ruleset_id": _core.state.rule_config.ruleset_name if _core.state != null and _core.state.rule_config != null else "tr_101_classic",
		"seats": _seat_by_puid.duplicate(true),
		"match_seed": _match_seed,
		"seat": int(_seat_by_puid.get(peer_puid, 0)),
	}))

func _broadcast_state_snapshot(is_rejoin: bool) -> void:
	for puid in _seat_by_puid.keys():
		if String(puid) == _local_puid:
			continue
		_send_snapshot(String(puid), is_rejoin)

func _send_snapshot(peer_puid: String, is_rejoin: bool) -> void:
	if _core.state == null:
		return
	var peer_abs_seat: int = int(_seat_by_puid.get(peer_puid, 0))
	var state_payload: Dictionary = STATE_CODEC_SCRIPT.encode_for_client(_core.state, peer_abs_seat)
	var msg_type: String = PROTOCOL_SCRIPT.S_REJOIN_SNAPSHOT if is_rejoin else PROTOCOL_SCRIPT.S_STATE_SNAPSHOT
	_send_packet(peer_puid, PROTOCOL_SCRIPT.wrap(msg_type, {
		"turn_id": _turn_id,
		"state": state_payload,
	}))

func _broadcast_match_event(event_name: String, payload: Dictionary) -> void:
	for puid in _seat_by_puid.keys():
		if String(puid) == _local_puid:
			continue
		_send_packet(String(puid), PROTOCOL_SCRIPT.wrap(PROTOCOL_SCRIPT.S_MATCH_EVENT, {
			"event": event_name,
			"payload": payload.duplicate(true),
		}))

func _send_action_result(peer_puid: String, seq: int, ok: bool, code: String, reason: String, state_hash: int) -> void:
	_send_packet(peer_puid, PROTOCOL_SCRIPT.wrap(PROTOCOL_SCRIPT.S_ACTION_RESULT, {
		"seq": seq,
		"ok": ok,
		"code": code,
		"reason": reason,
		"state_hash": state_hash,
	}))

func _send_packet(peer_puid: String, message: Dictionary) -> void:
	if _transport == null:
		return
	_transport.send_packet(peer_puid, message, true)

func _set_seat_map(seat_by_puid: Dictionary) -> void:
	_seat_by_puid = seat_by_puid.duplicate(true)
	_puid_by_seat.clear()
	for puid in _seat_by_puid.keys():
		_puid_by_seat[int(_seat_by_puid[puid])] = String(puid)

func _host_abs_seat() -> int:
	return int(_seat_by_puid.get(_local_puid, 0))

func _abs_to_local(abs_idx: int) -> int:
	return SEAT_ADAPTER_SCRIPT.to_local(abs_idx, _host_abs_seat(), _seat_by_puid.size())

func _local_to_abs(local_idx: int) -> int:
	return SEAT_ADAPTER_SCRIPT.to_abs(local_idx, _host_abs_seat(), _seat_by_puid.size())

func _envelope_from_action(player_index: int, action: Action) -> Dictionary:
	if action == null:
		return {}
	var action_type_name: String = ""
	match int(action.type):
		Action.ActionType.STARTER_DISCARD:
			action_type_name = "STARTER_DISCARD"
		Action.ActionType.DRAW_FROM_DECK:
			action_type_name = "DRAW_FROM_DECK"
		Action.ActionType.TAKE_DISCARD:
			action_type_name = "TAKE_DISCARD"
		Action.ActionType.PLACE_TILES:
			action_type_name = "PLACE_TILES"
		Action.ActionType.OPEN_MELDS:
			action_type_name = "OPEN_MELDS"
		Action.ActionType.ADD_TO_MELD:
			action_type_name = "ADD_TO_MELD"
		Action.ActionType.END_PLAY:
			action_type_name = "END_PLAY"
		Action.ActionType.DISCARD:
			action_type_name = "DISCARD"
		Action.ActionType.FINISH:
			action_type_name = "FINISH"
		_:
			return {}
	return {
		"type": action_type_name,
		"player_id": player_index,
		"payload": action.payload.duplicate(true),
	}
