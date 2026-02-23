extends "res://core/controller/MatchControllerPort.gd"
class_name ClientMatchController

const PROTOCOL_SCRIPT: Script = preload("res://net/Protocol.gd")
const STATE_CODEC_SCRIPT: Script = preload("res://core/network/StateCodec.gd")
static var _test_tracked_instances: Array = []

var _transport = null
var _local_puid: String = ""
var _host_puid: String = ""
var _match_id: String = ""
var _local_abs_seat: int = 0
var _seq: int = 0
var _last_turn_id_seen: int = 0
var _pending_action_type_by_seq: Dictionary = {}

func _init() -> void:
	if OS.has_feature("editor"):
		_test_tracked_instances.append(self)

func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE:
		return
	if OS.has_feature("editor"):
		_test_tracked_instances.erase(self)
	if _transport != null and _transport.packet_received.is_connected(_on_transport_packet):
		_transport.packet_received.disconnect(_on_transport_packet)
	if _transport != null and _transport.has_method("close_endpoint"):
		_transport.close_endpoint()
	_transport = null

static func free_test_tracked_instances() -> void:
	for i in range(_test_tracked_instances.size() - 1, -1, -1):
		var inst = _test_tracked_instances[i]
		if inst != null and is_instance_valid(inst):
			inst.free()
	_test_tracked_instances.clear()

func configure_client(local_puid: String, host_puid: String, transport, local_abs_seat: int = 0, match_id: String = "") -> void:
	_local_puid = String(local_puid)
	_host_puid = String(host_puid)
	_local_abs_seat = int(local_abs_seat)
	_match_id = String(match_id)
	if _transport != null and _transport.packet_received.is_connected(_on_transport_packet):
		_transport.packet_received.disconnect(_on_transport_packet)
	_transport = transport
	if _transport != null:
		_transport.open_endpoint(_local_puid)
		if not _transport.packet_received.is_connected(_on_transport_packet):
			_transport.packet_received.connect(_on_transport_packet)
	_send_hello()

func start_new_round(_rule_config: RuleConfig, _rng_seed: int, _player_count: int = 4) -> void:
	push_warning("ClientMatchController.start_new_round is host-controlled")

func start_new_match(_rule_config: RuleConfig, _rng_seed: int, _player_count: int = 4) -> void:
	push_warning("ClientMatchController.start_new_match is host-controlled")

func submit_action_envelope(action_dict: Dictionary) -> Dictionary:
	if _transport == null:
		return {"ok": false, "code": "transport_missing", "reason": "transport missing"}
	if _host_puid == "":
		return {"ok": false, "code": "host_missing", "reason": "host puid missing"}
	if typeof(action_dict) != TYPE_DICTIONARY:
		return {"ok": false, "code": "invalid_envelope", "reason": "envelope must be dictionary"}
	_seq += 1
	_pending_action_type_by_seq[_seq] = String(action_dict.get("type", ""))
	var packet: Dictionary = PROTOCOL_SCRIPT.wrap(PROTOCOL_SCRIPT.C_ACTION_REQUEST, {
		"seq": _seq,
		"turn_id": _last_turn_id_seen,
		"action": action_dict.duplicate(true),
	})
	var send_res: Dictionary = _transport.send_packet(_host_puid, packet, true)
	if not bool(send_res.get("ok", false)):
		_pending_action_type_by_seq.erase(_seq)
		emit_signal("action_rejected", String(send_res.get("reason", "send failed")))
		return send_res
	return {
		"ok": true,
		"code": "submitted",
		"reason": "submitted",
		"state_hash": int(hash(JSON.stringify(STATE_CODEC_SCRIPT.encode_host_state(state)))) if state != null else 0,
	}

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

func apply_manual_penalty(_player_index: int, _points: int) -> void:
	push_warning("apply_manual_penalty not supported on client controller")

func request_new_round() -> Dictionary:
	if _transport == null or _host_puid == "":
		return {"ok": false, "code": "transport_missing", "reason": "transport missing"}
	_seq += 1
	var packet: Dictionary = PROTOCOL_SCRIPT.wrap(PROTOCOL_SCRIPT.C_REQUEST_NEW_ROUND, {
		"seq": _seq,
		"match_id": _match_id,
	})
	return _transport.send_packet(_host_puid, packet, true)

func _on_transport_packet(from_puid: String, packet: Dictionary) -> void:
	if from_puid != _host_puid:
		return
	var vr: Dictionary = PROTOCOL_SCRIPT.validate_host_message(packet)
	if not bool(vr.get("ok", false)):
		emit_signal("action_rejected", "Protocol error: %s" % String(vr.get("reason", "invalid host message")))
		return
	var msg_type: String = String(packet.get("type", ""))
	match msg_type:
		PROTOCOL_SCRIPT.S_WELCOME:
			_match_id = String(packet.get("match_id", _match_id))
			_local_abs_seat = int(packet.get("seat", _local_abs_seat))
		PROTOCOL_SCRIPT.S_STATE_SNAPSHOT, PROTOCOL_SCRIPT.S_REJOIN_SNAPSHOT:
			_last_turn_id_seen = int(packet.get("turn_id", _last_turn_id_seen))
			state = STATE_CODEC_SCRIPT.decode_client_snapshot(packet.get("state", {}))
			emit_signal("state_changed", state)
			if state != null:
				emit_signal("turn_advanced", int(state.current_player_index), int(state.phase))
		PROTOCOL_SCRIPT.S_ACTION_RESULT:
			var seq: int = int(packet.get("seq", -1))
			var ok: bool = bool(packet.get("ok", false))
			if _pending_action_type_by_seq.has(seq):
				_pending_action_type_by_seq.erase(seq)
			if ok:
				emit_signal("action_applied", 0, -1)
			else:
				emit_signal("action_rejected", String(packet.get("reason", "Action rejected")))
		PROTOCOL_SCRIPT.S_MATCH_EVENT:
			var event_name: String = String(packet.get("event", ""))
			if event_name == "match_finished":
				var payload: Dictionary = packet.get("payload", {})
				emit_signal("match_finished", payload.get("winner_indices", []), payload.get("final_scores", []), String(payload.get("reason", "")))
		PROTOCOL_SCRIPT.S_PONG:
			pass

func _send_hello() -> void:
	if _transport == null or _host_puid == "":
		return
	_transport.send_packet(_host_puid, PROTOCOL_SCRIPT.wrap(PROTOCOL_SCRIPT.C_HELLO, {
		"match_id": _match_id,
		"puid": _local_puid,
		"client_version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
	}), true)

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
