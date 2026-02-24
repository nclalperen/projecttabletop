extends Node
class_name P2PTransportEOS

signal endpoint_opened(local_puid)
signal endpoint_closed(local_puid)
signal peer_connected(peer_puid)
signal peer_disconnected(peer_puid)
signal packet_received(from_puid, message)

const EOS_RAW_SCRIPT: Script = preload("res://net/eos/EOSRaw.gd")
const EOS_BACKEND_POLICY_SCRIPT: Script = preload("res://net/EOSBackendPolicy.gd")
const BACKEND_MOCK: String = "mock"
const BACKEND_IEOS_RAW: String = "ieos_raw"
const RUNTIME_PLATFORMS: PackedStringArray = ["Windows", "Android"]
const RTC_ENVELOPE_VERSION: int = 1
const INVALID_NOTIFICATION_ID: int = -1
const RTC_DATA_STATUS_ENABLED: int = 1
const RTC_DATA_STATUS_DISABLED: int = 2

static var _registry: Dictionary = {}
static var _test_tracked_instances: Array = []

var local_puid: String = ""
var opened: bool = false
var channel_name: String = "default"
var backend_mode: String = BACKEND_MOCK
var backend_policy: String = EOS_BACKEND_POLICY_SCRIPT.current_policy()

var _runtime_ieos = null
var _runtime_bootstrapped: bool = false
var _runtime_lobby_id: String = ""
var _runtime_room_name: String = ""
var _runtime_send_seq: int = 0
var _runtime_last_seq_by_puid: Dictionary = {}
var _runtime_known_peers: Dictionary = {}
var _runtime_notif_data_received: int = INVALID_NOTIFICATION_ID
var _runtime_notif_participant_updated: int = INVALID_NOTIFICATION_ID

func _init() -> void:
	backend_policy = EOS_BACKEND_POLICY_SCRIPT.current_policy()
	if OS.has_feature("editor"):
		_test_tracked_instances.append(self)

func set_backend_mode(mode: String) -> void:
	var normalized: String = String(mode).to_lower().strip_edges()
	if normalized == "":
		normalized = BACKEND_MOCK
	if normalized == "ieos":
		normalized = BACKEND_IEOS_RAW
	backend_mode = normalized

func set_backend_policy(policy: String) -> void:
	var normalized: String = EOS_BACKEND_POLICY_SCRIPT.sanitize(policy)
	if normalized == "":
		backend_policy = EOS_BACKEND_POLICY_SCRIPT.current_policy()
		return
	backend_policy = normalized

func get_backend_mode() -> String:
	return backend_mode

func set_runtime_context(lobby_id: String, room_name: String) -> void:
	_runtime_lobby_id = String(lobby_id)
	_runtime_room_name = String(room_name).strip_edges()

func get_runtime_context() -> Dictionary:
	return {
		"lobby_id": _runtime_lobby_id,
		"room_name": _runtime_room_name,
	}

func open_endpoint(puid: String, channel: String = "default") -> Dictionary:
	if String(puid).strip_edges() == "":
		return {
			"ok": false,
			"code": "invalid_puid",
			"reason": "puid is required",
			"backend_mode": backend_mode,
			"backend_policy": backend_policy,
		}
	if opened:
		close_endpoint()
	local_puid = String(puid)
	channel_name = String(channel)

	if _use_runtime():
		var runtime_res: Dictionary = _open_runtime_endpoint()
		if not bool(runtime_res.get("ok", false)):
			if _can_fallback_to_mock():
				var fallback_reason: String = "RTC runtime unavailable (%s): %s" % [
					String(runtime_res.get("code", "runtime_unavailable")),
					String(runtime_res.get("reason", "unknown")),
				]
				backend_mode = BACKEND_MOCK
				_registry[_registry_key(local_puid, channel_name)] = self
				opened = true
				emit_signal("endpoint_opened", local_puid)
				return {
					"ok": true,
					"code": "fallback_mock",
					"reason": fallback_reason,
					"backend_mode": backend_mode,
					"backend_policy": backend_policy,
				}
			local_puid = ""
			return {
				"ok": false,
				"code": String(runtime_res.get("code", "runtime_unavailable")),
				"reason": String(runtime_res.get("reason", "RTC runtime unavailable")),
				"backend_mode": backend_mode,
				"backend_policy": backend_policy,
			}
	else:
		_registry[_registry_key(local_puid, channel_name)] = self
		opened = true
		emit_signal("endpoint_opened", local_puid)
	return {
		"ok": true,
		"code": "ok",
		"reason": "",
		"backend_mode": backend_mode,
		"backend_policy": backend_policy,
	}

func close_endpoint() -> void:
	if not opened:
		return
	if _use_runtime():
		_close_runtime_endpoint()
	else:
		var key: String = _registry_key(local_puid, channel_name)
		if _registry.get(key, null) == self:
			_registry.erase(key)
	opened = false
	emit_signal("endpoint_closed", local_puid)
	local_puid = ""

func send_packet(peer_puid: String, message: Dictionary, reliable: bool = true) -> Dictionary:
	if not opened:
		return {
			"ok": false,
			"code": "endpoint_closed",
			"reason": "endpoint not open",
			"backend_mode": backend_mode,
			"backend_policy": backend_policy,
		}
	if String(peer_puid).strip_edges() == "":
		return {
			"ok": false,
			"code": "invalid_peer",
			"reason": "peer_puid required",
			"backend_mode": backend_mode,
			"backend_policy": backend_policy,
		}
	if typeof(message) != TYPE_DICTIONARY:
		return {
			"ok": false,
			"code": "invalid_message",
			"reason": "message must be dictionary",
			"backend_mode": backend_mode,
			"backend_policy": backend_policy,
		}
	if _use_runtime():
		return _runtime_send_packet(peer_puid, message, reliable)

	var target = _registry.get(_registry_key(String(peer_puid), channel_name), null)
	if target == null:
		return {
			"ok": false,
			"code": "peer_unreachable",
			"reason": "peer endpoint not found",
			"backend_mode": backend_mode,
			"backend_policy": backend_policy,
		}
	var payload: Dictionary = message.duplicate(true)
	# reliable is retained for protocol clarity; mock transport is always reliable.
	if not reliable:
		pass
	target._deliver(local_puid, payload)
	return {
		"ok": true,
		"code": "ok",
		"reason": "",
		"backend_mode": backend_mode,
		"backend_policy": backend_policy,
	}

func _deliver(from_puid: String, payload: Dictionary) -> void:
	emit_signal("packet_received", from_puid, payload)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if OS.has_feature("editor"):
			_test_tracked_instances.erase(self)
		close_endpoint()

static func free_test_tracked_instances() -> void:
	for i in range(_test_tracked_instances.size() - 1, -1, -1):
		var inst = _test_tracked_instances[i]
		if inst != null and is_instance_valid(inst):
			inst.free()
	_test_tracked_instances.clear()

func _use_runtime() -> bool:
	if backend_mode != BACKEND_IEOS_RAW:
		return false
	if not RUNTIME_PLATFORMS.has(OS.get_name()):
		return false
	if DisplayServer.get_name() == "headless":
		return false
	return true

func _can_fallback_to_mock() -> bool:
	return EOS_BACKEND_POLICY_SCRIPT.allows_mock_fallback(backend_policy)

func _open_runtime_endpoint() -> Dictionary:
	var boot: Dictionary = _runtime_bootstrap()
	if not bool(boot.get("ok", false)):
		return boot
	var room_name: String = _runtime_room_name
	if room_name == "":
		room_name = channel_name
	if room_name == "":
		return EOS_RAW_SCRIPT.fail("rtc_room_missing", "RTC room name is missing.")
	_runtime_room_name = room_name

	_connect_runtime_signals()

	var notify_data_opts := EOS_RAW_SCRIPT.RTCDataAddNotifyDataReceivedOptions.new()
	notify_data_opts.local_user_id = local_puid
	notify_data_opts.room_name = _runtime_room_name
	var add_data_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "rtc_data_interface_add_notify_data_received", [notify_data_opts])
	if not bool(add_data_call.get("ok", false)):
		return add_data_call
	_runtime_notif_data_received = _extract_notification_id(add_data_call.get("result", INVALID_NOTIFICATION_ID))

	var notify_participant_opts := EOS_RAW_SCRIPT.RTCDataAddNotifyParticipantUpdatedOptions.new()
	notify_participant_opts.local_user_id = local_puid
	notify_participant_opts.room_name = _runtime_room_name
	var add_part_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "rtc_data_interface_add_notify_participant_updated", [notify_participant_opts])
	if not bool(add_part_call.get("ok", false)):
		return add_part_call
	_runtime_notif_participant_updated = _extract_notification_id(add_part_call.get("result", INVALID_NOTIFICATION_ID))

	_runtime_update_sending(true)
	opened = true
	emit_signal("endpoint_opened", local_puid)
	return EOS_RAW_SCRIPT.ok_with({
		"backend_mode": backend_mode,
		"backend_policy": backend_policy,
	})

func _close_runtime_endpoint() -> void:
	_runtime_update_sending(false)
	if _runtime_notif_data_received != INVALID_NOTIFICATION_ID:
		EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "rtc_data_interface_remove_notify_data_received", [_runtime_notif_data_received])
	if _runtime_notif_participant_updated != INVALID_NOTIFICATION_ID:
		EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "rtc_data_interface_remove_notify_participant_updated", [_runtime_notif_participant_updated])
	_runtime_notif_data_received = INVALID_NOTIFICATION_ID
	_runtime_notif_participant_updated = INVALID_NOTIFICATION_ID
	_disconnect_runtime_signals()
	_runtime_last_seq_by_puid.clear()
	_runtime_known_peers.clear()
	_runtime_send_seq = 0

func _runtime_bootstrap() -> Dictionary:
	if _runtime_bootstrapped and _runtime_ieos != null:
		return EOS_RAW_SCRIPT.ok_with()
	var ensure_res: Dictionary = EOS_RAW_SCRIPT.ensure_extension_loaded()
	if not bool(ensure_res.get("ok", false)):
		return ensure_res
	_runtime_ieos = EOS_RAW_SCRIPT.get_ieos()
	if _runtime_ieos == null:
		return EOS_RAW_SCRIPT.fail("singleton_missing", "IEOS singleton unavailable.")
	_runtime_bootstrapped = true
	return EOS_RAW_SCRIPT.ok_with()

func _connect_runtime_signals() -> void:
	if _runtime_ieos == null:
		return
	if _runtime_ieos.has_signal("rtc_data_data_received") and not _runtime_ieos.is_connected("rtc_data_data_received", _on_runtime_data_received):
		_runtime_ieos.connect("rtc_data_data_received", _on_runtime_data_received)
	if _runtime_ieos.has_signal("rtc_data_participant_updated") and not _runtime_ieos.is_connected("rtc_data_participant_updated", _on_runtime_participant_updated):
		_runtime_ieos.connect("rtc_data_participant_updated", _on_runtime_participant_updated)

func _disconnect_runtime_signals() -> void:
	if _runtime_ieos == null:
		return
	if _runtime_ieos.has_signal("rtc_data_data_received") and _runtime_ieos.is_connected("rtc_data_data_received", _on_runtime_data_received):
		_runtime_ieos.disconnect("rtc_data_data_received", _on_runtime_data_received)
	if _runtime_ieos.has_signal("rtc_data_participant_updated") and _runtime_ieos.is_connected("rtc_data_participant_updated", _on_runtime_participant_updated):
		_runtime_ieos.disconnect("rtc_data_participant_updated", _on_runtime_participant_updated)

func _runtime_update_sending(enabled: bool) -> void:
	if _runtime_ieos == null or _runtime_room_name == "" or local_puid == "":
		return
	var update_opts := EOS_RAW_SCRIPT.RTCDataUpdateSendingOptions.new()
	update_opts.local_user_id = local_puid
	update_opts.room_name = _runtime_room_name
	update_opts.data_enabled = enabled
	EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "rtc_data_interface_update_sending", [update_opts])

func _runtime_update_receiving(participant_id: String, enabled: bool) -> void:
	if _runtime_ieos == null or _runtime_room_name == "" or local_puid == "" or participant_id == "":
		return
	var update_opts := EOS_RAW_SCRIPT.RTCDataUpdateReceivingOptions.new()
	update_opts.local_user_id = local_puid
	update_opts.room_name = _runtime_room_name
	update_opts.participant_id = participant_id
	update_opts.data_enabled = enabled
	EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "rtc_data_interface_update_receiving", [update_opts])

func _runtime_send_packet(peer_puid: String, message: Dictionary, reliable: bool) -> Dictionary:
	if _runtime_ieos == null:
		return EOS_RAW_SCRIPT.fail("runtime_missing", "IEOS runtime is not initialized.", {
			"backend_mode": backend_mode,
			"backend_policy": backend_policy,
		})
	if _runtime_room_name == "":
		return EOS_RAW_SCRIPT.fail("rtc_room_missing", "RTC room name is missing.", {
			"backend_mode": backend_mode,
			"backend_policy": backend_policy,
		})
	_runtime_send_seq += 1
	var envelope: Dictionary = {
		"v": RTC_ENVELOPE_VERSION,
		"ch": channel_name,
		"from": local_puid,
		"to": String(peer_puid),
		"seq": _runtime_send_seq,
		"reliable": reliable,
		"payload": message.duplicate(true),
	}
	var payload_text: String = JSON.stringify(envelope)
	var payload_bytes: PackedByteArray = payload_text.to_utf8_buffer()
	var send_opts := EOS_RAW_SCRIPT.RTCDataSendDataOptions.new()
	send_opts.local_user_id = local_puid
	send_opts.room_name = _runtime_room_name
	send_opts.data = payload_bytes
	var send_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "rtc_data_interface_send_data", [send_opts])
	if not bool(send_call.get("ok", false)):
		return send_call
	var send_ret = send_call.get("result")
	if not EOS_RAW_SCRIPT.is_success(send_ret):
		return EOS_RAW_SCRIPT.fail("send_failed", "RTC data send failed.", {
			"result_code": EOS_RAW_SCRIPT.result_code(send_ret),
			"backend_mode": backend_mode,
			"backend_policy": backend_policy,
		})
	return {
		"ok": true,
		"code": "ok",
		"reason": "",
		"backend_mode": backend_mode,
		"backend_policy": backend_policy,
	}

func _on_runtime_participant_updated(data: Dictionary) -> void:
	if not opened:
		return
	if String(data.get("room_name", "")) != _runtime_room_name:
		return
	var participant_id: String = String(data.get("participant_id", ""))
	if participant_id == "" or participant_id == local_puid:
		return
	var status_code: int = int(data.get("data_status", RTC_DATA_STATUS_ENABLED))
	if status_code == RTC_DATA_STATUS_ENABLED:
		_runtime_update_receiving(participant_id, true)
		if not bool(_runtime_known_peers.get(participant_id, false)):
			_runtime_known_peers[participant_id] = true
			emit_signal("peer_connected", participant_id)
		return
	if status_code == RTC_DATA_STATUS_DISABLED:
		if bool(_runtime_known_peers.get(participant_id, false)):
			_runtime_known_peers.erase(participant_id)
			emit_signal("peer_disconnected", participant_id)

func _on_runtime_data_received(data: Dictionary) -> void:
	if not opened:
		return
	if String(data.get("room_name", "")) != _runtime_room_name:
		return
	var raw_data = data.get("data", PackedByteArray())
	if typeof(raw_data) != TYPE_PACKED_BYTE_ARRAY:
		return
	var json_text: String = (raw_data as PackedByteArray).get_string_from_utf8()
	var parsed = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var envelope: Dictionary = parsed
	if int(envelope.get("v", -1)) != RTC_ENVELOPE_VERSION:
		return
	if String(envelope.get("ch", "")) != channel_name:
		return
	var to_puid: String = String(envelope.get("to", ""))
	if to_puid != "" and to_puid != local_puid:
		return
	var from_puid: String = String(envelope.get("from", ""))
	if from_puid == "" or from_puid == local_puid:
		return
	var seq: int = int(envelope.get("seq", -1))
	if seq < 0:
		return
	var last_seq: int = int(_runtime_last_seq_by_puid.get(from_puid, -1))
	if seq <= last_seq:
		return
	_runtime_last_seq_by_puid[from_puid] = seq
	if not bool(_runtime_known_peers.get(from_puid, false)):
		_runtime_known_peers[from_puid] = true
		emit_signal("peer_connected", from_puid)
	var payload = envelope.get("payload", {})
	if typeof(payload) != TYPE_DICTIONARY:
		payload = {}
	emit_signal("packet_received", from_puid, (payload as Dictionary).duplicate(true))

func _extract_notification_id(value) -> int:
	if typeof(value) == TYPE_INT:
		return int(value)
	if typeof(value) == TYPE_DICTIONARY:
		var dict_value: Dictionary = value
		if dict_value.has("notification_id"):
			return int(dict_value.get("notification_id", INVALID_NOTIFICATION_ID))
	return INVALID_NOTIFICATION_ID

static func clear_mock_registry() -> void:
	_registry.clear()

static func _registry_key(puid: String, channel: String) -> String:
	return "%s::%s" % [channel, puid]
