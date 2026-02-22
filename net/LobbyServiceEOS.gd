extends Node
class_name LobbyServiceEOS

signal lobby_updated(lobby_model)
signal lobby_list_updated(lobbies)
signal lobby_error(code, reason)

const EOS_RAW_SCRIPT: Script = preload("res://net/eos/EOSRaw.gd")
const BACKEND_MOCK: String = "mock"
const BACKEND_IEOS_RAW: String = "ieos_raw"
const LOBBY_MEMBER_STATUS_JOINED: int = 0
const LOBBY_MEMBER_STATUS_LEFT: int = 1
const LOBBY_MEMBER_STATUS_DISCONNECTED: int = 2
const LOBBY_MEMBER_STATUS_KICKED: int = 3
const LOBBY_MEMBER_STATUS_PROMOTED: int = 4
const LOBBY_MEMBER_STATUS_CLOSED: int = 5

static var _lobbies: Dictionary = {}

var local_puid: String = ""
var current_lobby_id: String = ""
var backend_mode: String = BACKEND_MOCK

var _runtime_ieos = null
var _runtime_bootstrapped: bool = false
var _runtime_inflight_op: String = ""
var _runtime_current_lobby: Dictionary = {}
var _runtime_last_status_by_puid: Dictionary = {}
var _runtime_status_hint_by_puid: Dictionary = {}

func set_backend_mode(mode: String) -> void:
	var normalized: String = String(mode).to_lower().strip_edges()
	if normalized == "":
		normalized = BACKEND_MOCK
	if normalized == "ieos":
		normalized = BACKEND_IEOS_RAW
	backend_mode = normalized

func get_backend_mode() -> String:
	return backend_mode

func set_local_puid(puid: String) -> void:
	local_puid = String(puid)

func create_lobby(options: Dictionary = {}) -> Dictionary:
	if local_puid == "":
		return _fail("not_logged_in", "local_puid missing")
	if _use_runtime():
		var gate: Dictionary = _begin_runtime_op("create_lobby")
		if not bool(gate.get("ok", false)):
			_downgrade_runtime_to_mock("create_lobby", gate)
			return _mock_create_lobby(options)
		call_deferred("_runtime_create_lobby_async", options.duplicate(true))
		return gate
	return _mock_create_lobby(options)

func search_lobbies(filters: Dictionary = {}) -> Dictionary:
	if _use_runtime():
		var gate: Dictionary = _begin_runtime_op("search_lobbies")
		if not bool(gate.get("ok", false)):
			_downgrade_runtime_to_mock("search_lobbies", gate)
			return _mock_search_lobbies(filters)
		call_deferred("_runtime_search_lobbies_async", filters.duplicate(true))
		return gate
	return _mock_search_lobbies(filters)

func join_lobby(lobby_id: String) -> Dictionary:
	if local_puid == "":
		return _fail("not_logged_in", "local_puid missing")
	if _use_runtime():
		var gate: Dictionary = _begin_runtime_op("join_lobby")
		if not bool(gate.get("ok", false)):
			_downgrade_runtime_to_mock("join_lobby", gate)
			return _mock_join_lobby(lobby_id)
		call_deferred("_runtime_join_lobby_async", String(lobby_id))
		return gate
	return _mock_join_lobby(lobby_id)

func leave_lobby() -> Dictionary:
	if _use_runtime():
		var gate: Dictionary = _begin_runtime_op("leave_lobby")
		if not bool(gate.get("ok", false)):
			_downgrade_runtime_to_mock("leave_lobby", gate)
			return _mock_leave_lobby()
		call_deferred("_runtime_leave_lobby_async")
		return gate
	return _mock_leave_lobby()

func set_lobby_attr(key: String, value) -> Dictionary:
	if _use_runtime():
		var gate: Dictionary = _begin_runtime_op("set_lobby_attr")
		if not bool(gate.get("ok", false)):
			_downgrade_runtime_to_mock("set_lobby_attr", gate)
			return _mock_set_lobby_attr(key, value)
		call_deferred("_runtime_set_lobby_attr_async", String(key), value)
		return gate
	return _mock_set_lobby_attr(key, value)

func set_member_attr(key: String, value) -> Dictionary:
	if _use_runtime():
		var gate: Dictionary = _begin_runtime_op("set_member_attr")
		if not bool(gate.get("ok", false)):
			_downgrade_runtime_to_mock("set_member_attr", gate)
			return _mock_set_member_attr(key, value)
		call_deferred("_runtime_set_member_attr_async", String(key), value)
		return gate
	return _mock_set_member_attr(key, value)

func set_ready(ready: bool) -> Dictionary:
	return set_member_attr("ready", bool(ready))

func get_current_lobby() -> Dictionary:
	if _use_runtime():
		return _runtime_current_lobby.duplicate(true)
	if current_lobby_id == "" or not _lobbies.has(current_lobby_id):
		return {}
	return _clone_lobby(_lobbies[current_lobby_id])

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_disconnect_runtime_callbacks()

func _use_runtime() -> bool:
	if backend_mode != BACKEND_IEOS_RAW:
		return false
	if DisplayServer.get_name() == "headless":
		return false
	if OS.get_name() != "Windows":
		return false
	return true

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
	_connect_runtime_callbacks()
	return EOS_RAW_SCRIPT.ok_with()

func _connect_runtime_callbacks() -> void:
	if _runtime_ieos == null:
		return
	_connect_runtime_signal("lobby_interface_lobby_update_received_callback", _on_runtime_lobby_update_received)
	_connect_runtime_signal("lobby_interface_lobby_member_update_received_callback", _on_runtime_lobby_member_update_received)
	_connect_runtime_signal("lobby_interface_lobby_member_status_received_callback", _on_runtime_lobby_member_status_received)

func _disconnect_runtime_callbacks() -> void:
	if _runtime_ieos == null:
		return
	_disconnect_runtime_signal("lobby_interface_lobby_update_received_callback", _on_runtime_lobby_update_received)
	_disconnect_runtime_signal("lobby_interface_lobby_member_update_received_callback", _on_runtime_lobby_member_update_received)
	_disconnect_runtime_signal("lobby_interface_lobby_member_status_received_callback", _on_runtime_lobby_member_status_received)

func _connect_runtime_signal(signal_name: String, callback: Callable) -> void:
	if _runtime_ieos == null:
		return
	if not _runtime_ieos.has_signal(signal_name):
		return
	if _runtime_ieos.is_connected(signal_name, callback):
		return
	_runtime_ieos.connect(signal_name, callback)

func _disconnect_runtime_signal(signal_name: String, callback: Callable) -> void:
	if _runtime_ieos == null:
		return
	if not _runtime_ieos.has_signal(signal_name):
		return
	if _runtime_ieos.is_connected(signal_name, callback):
		_runtime_ieos.disconnect(signal_name, callback)

func _begin_runtime_op(op_code: String) -> Dictionary:
	var boot: Dictionary = _runtime_bootstrap()
	if not bool(boot.get("ok", false)):
		return _fail(String(boot.get("code", "runtime_unavailable")), String(boot.get("reason", "EOS runtime unavailable")))
	if _runtime_inflight_op != "":
		return _pending("runtime_busy", {"busy_op": _runtime_inflight_op})
	_runtime_inflight_op = op_code
	return _pending("%s_submitted" % op_code)

func _finish_runtime_op() -> void:
	_runtime_inflight_op = ""

func _downgrade_runtime_to_mock(operation: String, gate_result: Dictionary) -> void:
	backend_mode = BACKEND_MOCK
	_runtime_inflight_op = ""
	_runtime_bootstrapped = false
	_runtime_ieos = null
	_runtime_current_lobby = {}
	_runtime_last_status_by_puid.clear()
	_runtime_status_hint_by_puid.clear()
	var reason: String = "Runtime fallback to mock during %s (%s): %s" % [
		operation,
		String(gate_result.get("code", "runtime_unavailable")),
		String(gate_result.get("reason", "unknown")),
	]
	emit_signal("lobby_error", "runtime_fallback", reason)

func _runtime_create_lobby_async(options: Dictionary) -> void:
	var res: Dictionary = await _runtime_create_lobby_flow(options)
	_finish_runtime_op()
	if not bool(res.get("ok", false)):
		_fail(String(res.get("code", "runtime_create_failed")), String(res.get("reason", "Failed to create lobby")))
		return
	emit_signal("lobby_updated", _runtime_current_lobby.duplicate(true))

func _runtime_create_lobby_flow(options: Dictionary) -> Dictionary:
	var create_opts := EOS_RAW_SCRIPT.LobbyCreateOptions.new()
	create_opts.local_user_id = local_puid
	var ruleset_id: String = String(options.get("ruleset_id", "tr_101_classic"))
	var version_tag: String = String(options.get("version", "v1"))
	var phase_tag: String = String(options.get("phase", "FILLING"))
	var privacy_tag: String = String(options.get("privacy", "PUBLIC"))
	create_opts.bucket_id = "%s:%s" % [ruleset_id, version_tag]
	create_opts.max_lobby_members = int(options.get("max_lobby_members", 4))
	create_opts.allow_invites = true
	create_opts.enable_join_by_id = true
	create_opts.enable_rtc_room = true
	create_opts.rtc_room_join_action_type = EOS_RAW_SCRIPT.RTC_ROOM_JOIN_AUTOMATIC
	create_opts.permission_level = EOS_RAW_SCRIPT.LOBBY_PERMISSION_INVITE_ONLY if privacy_tag == "INVITE_ONLY" else EOS_RAW_SCRIPT.LOBBY_PERMISSION_PUBLIC_ADVERTISED
	create_opts.presence_enabled = true
	create_opts.local_rtc_options = {
		"flags": 1,
	}

	var create_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "lobby_interface_create_lobby", [create_opts])
	if not bool(create_call.get("ok", false)):
		return create_call
	var wait_res: Dictionary = await EOS_RAW_SCRIPT.await_signal_once(self, _runtime_ieos, "lobby_interface_create_lobby_callback", 15.0)
	if not bool(wait_res.get("ok", false)):
		return wait_res
	var create_cb: Dictionary = _payload_dict(wait_res)
	if not EOS_RAW_SCRIPT.is_success(create_cb):
		return EOS_RAW_SCRIPT.fail("create_lobby_failed", "Create lobby callback returned failure.", {"result_code": EOS_RAW_SCRIPT.result_code(create_cb)})
	var created_lobby_id: String = String(create_cb.get("lobby_id", ""))
	if created_lobby_id.strip_edges() == "":
		return EOS_RAW_SCRIPT.fail("create_lobby_missing_id", "Create lobby callback did not include lobby id.")
	current_lobby_id = created_lobby_id
	var lobby_attrs: Dictionary = {
		"ruleset_id": ruleset_id,
		"version": version_tag,
		"phase": phase_tag,
		"host_puid": local_puid,
		"match_id": String(options.get("match_id", "")),
		"ruleset_hash": String(options.get("ruleset_hash", "")),
		"privacy": privacy_tag,
	}
	var member_attrs: Dictionary = {
		"ready": false,
		"status": "OK",
		"platform": _platform_tag(),
	}
	return await _runtime_update_attrs_flow(lobby_attrs, member_attrs)

func _runtime_search_lobbies_async(filters: Dictionary) -> void:
	var res: Dictionary = await _runtime_search_lobbies_flow(filters)
	_finish_runtime_op()
	if not bool(res.get("ok", false)):
		_fail(String(res.get("code", "runtime_search_failed")), String(res.get("reason", "Search failed")))
		return
	emit_signal("lobby_list_updated", res.get("lobbies", []))

func _runtime_search_lobbies_flow(filters: Dictionary) -> Dictionary:
	var search_opts := EOS_RAW_SCRIPT.LobbyCreateSearchOptions.new()
	search_opts.max_results = int(filters.get("max_results", 25))
	var create_search: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "lobby_interface_create_lobby_search", [search_opts])
	if not bool(create_search.get("ok", false)):
		return create_search
	var search_ret: Dictionary = create_search.get("result", {}) as Dictionary
	if not EOS_RAW_SCRIPT.is_success(search_ret):
		return EOS_RAW_SCRIPT.fail("search_create_failed", "Failed to create lobby search.", {"result_code": EOS_RAW_SCRIPT.result_code(search_ret)})
	var lobby_search = search_ret.get("lobby_search", null)
	if lobby_search == null:
		return EOS_RAW_SCRIPT.fail("search_missing_handle", "Lobby search handle missing.")
	for k in filters.keys():
		var key: String = String(k)
		var value = filters[k]
		if key == "max_results":
			continue
		if key == "open_slots":
			lobby_search.set_parameter("minslotsavailable", int(value), EOS_RAW_SCRIPT.COMPARISON_OP_EQUAL)
			continue
		lobby_search.set_parameter(key, value, EOS_RAW_SCRIPT.COMPARISON_OP_EQUAL)
	lobby_search.find(local_puid)
	var find_wait: Dictionary = await EOS_RAW_SCRIPT.await_signal_once(self, _runtime_ieos, "lobby_search_find_callback", 15.0)
	if not bool(find_wait.get("ok", false)):
		return find_wait
	var find_cb: Dictionary = _payload_dict(find_wait)
	if not EOS_RAW_SCRIPT.is_success(find_cb):
		return EOS_RAW_SCRIPT.fail("search_failed", "Lobby search callback returned failure.", {"result_code": EOS_RAW_SCRIPT.result_code(find_cb)})
	var out: Array = []
	var count: int = int(lobby_search.get_search_result_count())
	for idx in range(maxi(0, count)):
		var copy_ret: Dictionary = lobby_search.copy_search_result_by_index(idx)
		if not EOS_RAW_SCRIPT.is_success(copy_ret):
			continue
		var details = copy_ret.get("lobby_details", null)
		if details == null:
			continue
		var model: Dictionary = _runtime_build_lobby_model_from_details(details)
		if not model.is_empty():
			out.append(model)
	return EOS_RAW_SCRIPT.ok_with({"lobbies": out})

func _runtime_join_lobby_async(lobby_id: String) -> void:
	var res: Dictionary = await _runtime_join_lobby_flow(lobby_id)
	_finish_runtime_op()
	if not bool(res.get("ok", false)):
		_fail(String(res.get("code", "runtime_join_failed")), String(res.get("reason", "Join failed")))
		return
	emit_signal("lobby_updated", _runtime_current_lobby.duplicate(true))

func _runtime_join_lobby_flow(lobby_id: String) -> Dictionary:
	var join_opts := EOS_RAW_SCRIPT.LobbyJoinByIdOptions.new()
	join_opts.local_user_id = local_puid
	join_opts.lobby_id = lobby_id
	join_opts.presence_enabled = true
	join_opts.rtc_room_join_action_type = EOS_RAW_SCRIPT.RTC_ROOM_JOIN_AUTOMATIC
	join_opts.local_rtc_options = {
		"flags": 1,
	}
	var join_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "lobby_interface_join_lobby_by_id", [join_opts])
	if not bool(join_call.get("ok", false)):
		return join_call
	var join_wait: Dictionary = await EOS_RAW_SCRIPT.await_signal_once(self, _runtime_ieos, "lobby_interface_join_lobby_by_id_callback", 15.0)
	if not bool(join_wait.get("ok", false)):
		return join_wait
	var join_cb: Dictionary = _payload_dict(join_wait)
	if not EOS_RAW_SCRIPT.is_success(join_cb):
		return EOS_RAW_SCRIPT.fail("join_lobby_failed", "Join lobby callback returned failure.", {"result_code": EOS_RAW_SCRIPT.result_code(join_cb)})
	current_lobby_id = String(join_cb.get("lobby_id", lobby_id))
	return await _runtime_update_attrs_flow({}, {
		"ready": false,
		"status": "OK",
		"platform": _platform_tag(),
	})

func _runtime_leave_lobby_async() -> void:
	var res: Dictionary = await _runtime_leave_lobby_flow()
	_finish_runtime_op()
	if not bool(res.get("ok", false)):
		_fail(String(res.get("code", "runtime_leave_failed")), String(res.get("reason", "Leave failed")))
		return
	emit_signal("lobby_updated", {})

func _runtime_leave_lobby_flow() -> Dictionary:
	if current_lobby_id == "":
		_runtime_current_lobby = {}
		return EOS_RAW_SCRIPT.ok_with()
	var leave_opts := EOS_RAW_SCRIPT.LobbyLeaveOptions.new()
	leave_opts.local_user_id = local_puid
	leave_opts.lobby_id = current_lobby_id
	var leave_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "lobby_interface_leave_lobby", [leave_opts])
	if not bool(leave_call.get("ok", false)):
		return leave_call
	var leave_wait: Dictionary = await EOS_RAW_SCRIPT.await_signal_once(self, _runtime_ieos, "lobby_interface_leave_lobby_callback", 15.0)
	if not bool(leave_wait.get("ok", false)):
		return leave_wait
	var leave_cb: Dictionary = _payload_dict(leave_wait)
	if not EOS_RAW_SCRIPT.is_success(leave_cb):
		return EOS_RAW_SCRIPT.fail("leave_lobby_failed", "Leave lobby callback returned failure.", {"result_code": EOS_RAW_SCRIPT.result_code(leave_cb)})
	current_lobby_id = ""
	_runtime_current_lobby = {}
	_runtime_last_status_by_puid.clear()
	_runtime_status_hint_by_puid.clear()
	return EOS_RAW_SCRIPT.ok_with()

func _runtime_set_lobby_attr_async(key: String, value) -> void:
	var res: Dictionary = await _runtime_update_attrs_flow({key: value}, {})
	_finish_runtime_op()
	if not bool(res.get("ok", false)):
		_fail(String(res.get("code", "runtime_lobby_attr_failed")), String(res.get("reason", "Failed to update lobby attr")))
		return
	emit_signal("lobby_updated", _runtime_current_lobby.duplicate(true))

func _runtime_set_member_attr_async(key: String, value) -> void:
	var res: Dictionary = await _runtime_update_attrs_flow({}, {key: value})
	_finish_runtime_op()
	if not bool(res.get("ok", false)):
		_fail(String(res.get("code", "runtime_member_attr_failed")), String(res.get("reason", "Failed to update member attr")))
		return
	emit_signal("lobby_updated", _runtime_current_lobby.duplicate(true))

func _runtime_update_attrs_flow(lobby_attrs: Dictionary, member_attrs: Dictionary) -> Dictionary:
	if current_lobby_id == "":
		return EOS_RAW_SCRIPT.fail("no_lobby", "Not in lobby.")
	var update_mod_opts := EOS_RAW_SCRIPT.LobbyUpdateModificationOptions.new()
	update_mod_opts.local_user_id = local_puid
	update_mod_opts.lobby_id = current_lobby_id
	var mod_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "lobby_interface_update_lobby_modification", [update_mod_opts])
	if not bool(mod_call.get("ok", false)):
		return mod_call
	var mod_ret: Dictionary = mod_call.get("result", {}) as Dictionary
	if not EOS_RAW_SCRIPT.is_success(mod_ret):
		return EOS_RAW_SCRIPT.fail("lobby_modification_failed", "Failed to create lobby modification.", {"result_code": EOS_RAW_SCRIPT.result_code(mod_ret)})
	var lobby_mod = mod_ret.get("lobby_modification", null)
	if lobby_mod == null:
		return EOS_RAW_SCRIPT.fail("lobby_modification_missing", "Lobby modification handle missing.")
	for key in lobby_attrs.keys():
		lobby_mod.add_attribute(String(key), lobby_attrs[key], EOS_RAW_SCRIPT.LOBBY_ATTRIBUTE_VISIBILITY_PUBLIC)
	for key in member_attrs.keys():
		lobby_mod.add_member_attribute(String(key), member_attrs[key], EOS_RAW_SCRIPT.LOBBY_ATTRIBUTE_VISIBILITY_PUBLIC)
	var update_opts := EOS_RAW_SCRIPT.LobbyUpdateOptions.new()
	update_opts.lobby_modification = lobby_mod
	var update_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "lobby_interface_update_lobby", [update_opts])
	if not bool(update_call.get("ok", false)):
		return update_call
	var update_wait: Dictionary = await EOS_RAW_SCRIPT.await_signal_once(self, _runtime_ieos, "lobby_interface_update_lobby_callback", 15.0)
	if not bool(update_wait.get("ok", false)):
		return update_wait
	var update_cb: Dictionary = _payload_dict(update_wait)
	if not EOS_RAW_SCRIPT.is_success(update_cb):
		return EOS_RAW_SCRIPT.fail("lobby_update_failed", "Lobby update callback returned failure.", {"result_code": EOS_RAW_SCRIPT.result_code(update_cb)})
	return _runtime_refresh_current_lobby()

func _runtime_refresh_current_lobby() -> Dictionary:
	if current_lobby_id == "":
		_runtime_current_lobby = {}
		return EOS_RAW_SCRIPT.ok_with()
	var copy_opts := EOS_RAW_SCRIPT.LobbyCopyDetailsOptions.new()
	copy_opts.local_user_id = local_puid
	copy_opts.lobby_id = current_lobby_id
	var copy_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "lobby_interface_copy_lobby_details", [copy_opts])
	if not bool(copy_call.get("ok", false)):
		return copy_call
	var copy_ret: Dictionary = copy_call.get("result", {}) as Dictionary
	if not EOS_RAW_SCRIPT.is_success(copy_ret):
		return EOS_RAW_SCRIPT.fail("copy_lobby_failed", "Failed to copy lobby details.", {"result_code": EOS_RAW_SCRIPT.result_code(copy_ret)})
	var details = copy_ret.get("lobby_details", null)
	if details == null:
		return EOS_RAW_SCRIPT.fail("copy_lobby_missing_details", "Copy lobby details returned no detail handle.")
	var model: Dictionary = _runtime_build_lobby_model_from_details(details)
	if model.is_empty():
		return EOS_RAW_SCRIPT.fail("lobby_model_empty", "Failed to build lobby model from details.")
	_runtime_current_lobby = model
	current_lobby_id = String(model.get("lobby_id", current_lobby_id))
	return EOS_RAW_SCRIPT.ok_with({"lobby": model.duplicate(true)})

func _runtime_build_lobby_model_from_details(details) -> Dictionary:
	if details == null:
		return {}
	var info_ret: Dictionary = details.copy_info()
	if not EOS_RAW_SCRIPT.is_success(info_ret):
		return {}
	var info: Dictionary = info_ret.get("lobby_details", {}) as Dictionary
	var attrs: Dictionary = {
		"ruleset_id": "tr_101_classic",
		"version": "v1",
		"phase": "FILLING",
		"open_slots": int(info.get("available_slots", 0)),
		"host_puid": String(info.get("lobby_owner_user_id", "")),
		"match_id": "",
		"ruleset_hash": "",
		"privacy": "PUBLIC" if int(info.get("permission_level", EOS_RAW_SCRIPT.LOBBY_PERMISSION_PUBLIC_ADVERTISED)) == EOS_RAW_SCRIPT.LOBBY_PERMISSION_PUBLIC_ADVERTISED else "INVITE_ONLY",
	}
	var attr_count: int = int(details.get_attribute_count())
	for ai in range(maxi(0, attr_count)):
		var attr_ret: Dictionary = details.copy_attribute_by_index(ai)
		if not EOS_RAW_SCRIPT.is_success(attr_ret):
			continue
		var attr_obj = attr_ret.get("attribute", null)
		if attr_obj == null:
			continue
		var data = attr_obj.get("data", null) if typeof(attr_obj) == TYPE_DICTIONARY else null
		if data == null and attr_obj.has_method("get"):
			data = attr_obj.get("data")
		if typeof(data) != TYPE_DICTIONARY:
			continue
		var key: String = String(data.get("key", ""))
		if key == "":
			continue
		attrs[key] = data.get("value")
	var lobby_id: String = String(info.get("lobby_id", current_lobby_id))
	var members: Array = []
	var member_count: int = int(details.get_member_count())
	for mi in range(maxi(0, member_count)):
		var puid: String = String(details.get_member_by_index(mi))
		if puid == "":
			continue
		var member_attrs: Dictionary = {
			"seat": -1,
			"ready": false,
			"status": String(_runtime_status_hint_by_puid.get(puid, "OK")),
			"platform": _platform_tag(),
		}
		var join_time: int = 0
		var member_info_ret: Dictionary = details.copy_member_info(puid)
		if EOS_RAW_SCRIPT.is_success(member_info_ret):
			var member_info: Dictionary = member_info_ret.get("member_info", {}) as Dictionary
			join_time = int(member_info.get("joined_at", member_info.get("join_time", 0)))
		var ma_count: int = int(details.get_member_attribute_count(puid))
		for mai in range(maxi(0, ma_count)):
			var ma_ret: Dictionary = details.copy_member_attribute_by_index(puid, mai)
			if not EOS_RAW_SCRIPT.is_success(ma_ret):
				continue
			var ma_attr = ma_ret.get("attribute", null)
			if ma_attr == null:
				continue
			var ma_data = ma_attr.get("data", null) if typeof(ma_attr) == TYPE_DICTIONARY else null
			if ma_data == null and ma_attr.has_method("get"):
				ma_data = ma_attr.get("data")
			if typeof(ma_data) != TYPE_DICTIONARY:
				continue
			var ma_key: String = String(ma_data.get("key", ""))
			if ma_key == "":
				continue
			member_attrs[ma_key] = ma_data.get("value")
		member_attrs["seat"] = int(member_attrs.get("seat", -1))
		member_attrs["ready"] = bool(member_attrs.get("ready", false))
		member_attrs["status"] = String(member_attrs.get("status", "OK"))
		members.append({
			"puid": puid,
			"join_time": join_time,
			"attrs": member_attrs,
		})
	var model: Dictionary = {
		"lobby_id": lobby_id,
		"owner_puid": String(info.get("lobby_owner_user_id", attrs.get("host_puid", ""))),
		"attrs": attrs,
		"members": members,
	}
	_assign_seats(model)
	_update_open_slots(model)
	model["attrs"]["rtc_room_name"] = _runtime_get_rtc_room_name(lobby_id)
	_cache_runtime_member_status(model)
	return model

func _runtime_get_rtc_room_name(lobby_id: String) -> String:
	if lobby_id == "":
		return ""
	var opts := EOS_RAW_SCRIPT.LobbyGetRtcRoomNameOptions.new()
	opts.local_user_id = local_puid
	opts.lobby_id = lobby_id
	var room_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "lobby_interface_get_rtc_room_name", [opts])
	if not bool(room_call.get("ok", false)):
		return ""
	var room_ret: Dictionary = room_call.get("result", {}) as Dictionary
	if not EOS_RAW_SCRIPT.is_success(room_ret):
		return ""
	return String(room_ret.get("rtc_room_name", ""))

func _cache_runtime_member_status(model: Dictionary) -> void:
	_runtime_last_status_by_puid.clear()
	for member in model.get("members", []):
		var puid: String = String(member.get("puid", ""))
		if puid == "":
			continue
		var status: String = String(member.get("attrs", {}).get("status", "OK"))
		_runtime_last_status_by_puid[puid] = status

func _on_runtime_lobby_update_received(data: Dictionary) -> void:
	if current_lobby_id == "":
		return
	if String(data.get("lobby_id", "")) != current_lobby_id:
		return
	call_deferred("_runtime_refresh_from_push")

func _on_runtime_lobby_member_update_received(data: Dictionary) -> void:
	if current_lobby_id == "":
		return
	if String(data.get("lobby_id", "")) != current_lobby_id:
		return
	call_deferred("_runtime_refresh_from_push")

func _on_runtime_lobby_member_status_received(data: Dictionary) -> void:
	if current_lobby_id == "":
		return
	if String(data.get("lobby_id", "")) != current_lobby_id:
		return
	var target_puid: String = String(data.get("target_user_id", ""))
	if target_puid != "":
		var current_status: int = int(data.get("current_status", -1))
		_runtime_status_hint_by_puid[target_puid] = _status_from_runtime_member_code(current_status)
	call_deferred("_runtime_refresh_from_push")

func _runtime_refresh_from_push() -> void:
	if not _use_runtime():
		return
	if _runtime_inflight_op != "":
		return
	var gate: Dictionary = _begin_runtime_op("push_refresh")
	if not bool(gate.get("ok", false)):
		return
	call_deferred("_runtime_push_refresh_async")

func _runtime_push_refresh_async() -> void:
	var res: Dictionary = _runtime_refresh_current_lobby()
	_finish_runtime_op()
	if not bool(res.get("ok", false)):
		return
	emit_signal("lobby_updated", _runtime_current_lobby.duplicate(true))

func _payload_dict(wait_result: Dictionary) -> Dictionary:
	var payload = wait_result.get("payload", {})
	if typeof(payload) == TYPE_DICTIONARY:
		return payload
	return {}

func _matches_filters(lobby: Dictionary, filters: Dictionary) -> bool:
	for k in filters.keys():
		var want = filters[k]
		if k == "open_slots":
			if int(lobby["attrs"].get("open_slots", 0)) < int(want):
				return false
		elif String(lobby["attrs"].get(String(k), "")) != String(want):
			return false
	return true

func _new_member(puid: String) -> Dictionary:
	return {
		"puid": puid,
		"join_time": int(Time.get_unix_time_from_system()),
		"attrs": {
			"seat": -1,
			"ready": false,
			"status": "OK",
			"platform": _platform_tag(),
		},
	}

func _assign_seats(lobby: Dictionary) -> void:
	var members: Array = lobby.get("members", [])
	members.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ja: int = int(a.get("join_time", 0))
		var jb: int = int(b.get("join_time", 0))
		if ja == jb:
			return String(a.get("puid", "")) < String(b.get("puid", ""))
		return ja < jb
	)
	for i in range(members.size()):
		members[i]["attrs"]["seat"] = i
	lobby["members"] = members

func _reset_ready(lobby: Dictionary) -> void:
	for m in lobby.get("members", []):
		m["attrs"]["ready"] = false

func _update_open_slots(lobby: Dictionary) -> void:
	var open_slots: int = maxi(0, 4 - int(lobby.get("members", []).size()))
	lobby["attrs"]["open_slots"] = open_slots

func _platform_tag() -> String:
	if OS.get_name() == "Windows":
		return "pc"
	return "unknown"

func _clone_lobby(lobby: Dictionary) -> Dictionary:
	return lobby.duplicate(true)

func _status_from_runtime_member_code(code: int) -> String:
	match code:
		LOBBY_MEMBER_STATUS_JOINED:
			return "OK"
		LOBBY_MEMBER_STATUS_LEFT:
			return "LEFT"
		LOBBY_MEMBER_STATUS_DISCONNECTED:
			return "DISCONNECTED"
		LOBBY_MEMBER_STATUS_KICKED:
			return "KICKED"
		LOBBY_MEMBER_STATUS_PROMOTED:
			return "OK"
		LOBBY_MEMBER_STATUS_CLOSED:
			return "CLOSED"
		_:
			return "OK"

func _ok_with(extra: Dictionary) -> Dictionary:
	var out: Dictionary = {"ok": true, "code": "ok", "reason": "", "backend_mode": backend_mode}
	for k in extra.keys():
		out[k] = extra[k]
	return out

func _pending(reason: String, extra: Dictionary = {}) -> Dictionary:
	var out: Dictionary = {"ok": true, "code": "pending", "reason": reason, "backend_mode": backend_mode}
	for k in extra.keys():
		out[k] = extra[k]
	return out

func _fail(code: String, reason: String) -> Dictionary:
	emit_signal("lobby_error", code, reason)
	return {"ok": false, "code": code, "reason": reason, "backend_mode": backend_mode}

func _mock_create_lobby(options: Dictionary = {}) -> Dictionary:
	var lobby_id: String = "L_%08x" % int(abs(hash("%s|%s" % [local_puid, Time.get_unix_time_from_system()])))
	var lobby: Dictionary = {
		"lobby_id": lobby_id,
		"owner_puid": local_puid,
		"attrs": {
			"ruleset_id": String(options.get("ruleset_id", "tr_101_classic")),
			"version": String(options.get("version", "v1")),
			"phase": String(options.get("phase", "FILLING")),
			"open_slots": int(options.get("open_slots", 3)),
			"host_puid": local_puid,
			"match_id": String(options.get("match_id", "")),
			"ruleset_hash": String(options.get("ruleset_hash", "")),
			"privacy": String(options.get("privacy", "PUBLIC")),
		},
		"members": [
			_new_member(local_puid)
		],
	}
	_assign_seats(lobby)
	_update_open_slots(lobby)
	_lobbies[lobby_id] = lobby
	current_lobby_id = lobby_id
	emit_signal("lobby_updated", _clone_lobby(lobby))
	return _ok_with({"lobby": _clone_lobby(lobby)})

func _mock_search_lobbies(filters: Dictionary = {}) -> Dictionary:
	var out: Array = []
	for lobby in _lobbies.values():
		if _matches_filters(lobby, filters):
			out.append(_clone_lobby(lobby))
	emit_signal("lobby_list_updated", out)
	return _ok_with({"lobbies": out})

func _mock_join_lobby(lobby_id: String) -> Dictionary:
	if not _lobbies.has(lobby_id):
		return _fail("not_found", "lobby not found")
	var lobby: Dictionary = _lobbies[lobby_id]
	for m in lobby["members"]:
		if String(m.get("puid", "")) == local_puid:
			current_lobby_id = lobby_id
			emit_signal("lobby_updated", _clone_lobby(lobby))
			return _ok_with({"lobby": _clone_lobby(lobby)})
	lobby["members"].append(_new_member(local_puid))
	_reset_ready(lobby)
	_assign_seats(lobby)
	_update_open_slots(lobby)
	_lobbies[lobby_id] = lobby
	current_lobby_id = lobby_id
	emit_signal("lobby_updated", _clone_lobby(lobby))
	return _ok_with({"lobby": _clone_lobby(lobby)})

func _mock_leave_lobby() -> Dictionary:
	if current_lobby_id == "" or not _lobbies.has(current_lobby_id):
		current_lobby_id = ""
		return _ok_with({})
	var lobby: Dictionary = _lobbies[current_lobby_id]
	var members: Array = []
	for m in lobby["members"]:
		if String(m.get("puid", "")) != local_puid:
			members.append(m)
	lobby["members"] = members
	if members.is_empty():
		_lobbies.erase(current_lobby_id)
		current_lobby_id = ""
		emit_signal("lobby_updated", {})
		return _ok_with({})
	if String(lobby.get("owner_puid", "")) == local_puid:
		lobby["owner_puid"] = String(members[0].get("puid", ""))
		lobby["attrs"]["host_puid"] = lobby["owner_puid"]
	_reset_ready(lobby)
	_assign_seats(lobby)
	_update_open_slots(lobby)
	_lobbies[current_lobby_id] = lobby
	current_lobby_id = ""
	emit_signal("lobby_updated", {})
	return _ok_with({})

func _mock_set_lobby_attr(key: String, value) -> Dictionary:
	var lobby: Dictionary = _mock_require_current_lobby()
	if lobby.is_empty():
		return _fail("no_lobby", "not in lobby")
	if String(lobby.get("owner_puid", "")) != local_puid:
		return _fail("not_host", "only owner can set lobby attrs")
	lobby["attrs"][String(key)] = value
	if key == "ruleset_id" or key == "version" or key == "phase":
		_reset_ready(lobby)
	_update_open_slots(lobby)
	_lobbies[current_lobby_id] = lobby
	emit_signal("lobby_updated", _clone_lobby(lobby))
	return _ok_with({"lobby": _clone_lobby(lobby)})

func _mock_set_member_attr(key: String, value) -> Dictionary:
	var lobby: Dictionary = _mock_require_current_lobby()
	if lobby.is_empty():
		return _fail("no_lobby", "not in lobby")
	for m in lobby["members"]:
		if String(m.get("puid", "")) == local_puid:
			m["attrs"][String(key)] = value
			_lobbies[current_lobby_id] = lobby
			emit_signal("lobby_updated", _clone_lobby(lobby))
			return _ok_with({"lobby": _clone_lobby(lobby)})
	return _fail("not_member", "local member not found")

func _mock_require_current_lobby() -> Dictionary:
	if current_lobby_id == "" or not _lobbies.has(current_lobby_id):
		return {}
	return _lobbies[current_lobby_id]

static func clear_mock_lobbies() -> void:
	_lobbies.clear()
