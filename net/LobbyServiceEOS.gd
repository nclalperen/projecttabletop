extends Node
class_name LobbyServiceEOS

signal lobby_updated(lobby_model)
signal lobby_list_updated(lobbies)
signal lobby_error(code, reason)

const EOS_RAW_SCRIPT: Script = preload("res://net/eos/EOSRaw.gd")
const EOS_BACKEND_POLICY_SCRIPT: Script = preload("res://net/EOSBackendPolicy.gd")
const PROTOCOL_SCRIPT: Script = preload("res://net/Protocol.gd")
const BACKEND_MOCK: String = "mock"
const BACKEND_IEOS_RAW: String = "ieos_raw"
const RUNTIME_PLATFORMS: PackedStringArray = ["Windows", "Android"]
const ATTR_PROTOCOL_REV: String = "protocol_rev"
const ATTR_BUILD_FAMILY: String = "build_family"
const ATTR_DISPLAY_NAME: String = "display_name"
const ATTR_GAME_ID: String = "game_id"
const ATTR_SEAT_COUNT: String = "seat_count"
const ATTR_SEAT_PLAN_JSON: String = "seat_plan_json"
const LOBBY_MEMBER_STATUS_JOINED: int = 0
const LOBBY_MEMBER_STATUS_LEFT: int = 1
const LOBBY_MEMBER_STATUS_DISCONNECTED: int = 2
const LOBBY_MEMBER_STATUS_KICKED: int = 3
const LOBBY_MEMBER_STATUS_PROMOTED: int = 4
const LOBBY_MEMBER_STATUS_CLOSED: int = 5

static var _lobbies: Dictionary = {}
static var _test_tracked_instances: Array = []

var local_puid: String = ""
var current_lobby_id: String = ""
var backend_mode: String = BACKEND_MOCK
var backend_policy: String = EOS_BACKEND_POLICY_SCRIPT.current_policy()
var _local_display_name: String = ""
var _local_build_family: String = EOS_BACKEND_POLICY_SCRIPT.build_family()
var _local_protocol_rev: int = int(PROTOCOL_SCRIPT.PROTOCOL_VERSION)
var _local_epic_account_id: String = ""

var _runtime_ieos = null
var _runtime_bootstrapped: bool = false
var _runtime_inflight_op: String = ""
var _runtime_current_lobby: Dictionary = {}
var _runtime_last_status_by_puid: Dictionary = {}
var _runtime_status_hint_by_puid: Dictionary = {}

func _init() -> void:
	backend_policy = EOS_BACKEND_POLICY_SCRIPT.current_policy()
	_local_build_family = EOS_BACKEND_POLICY_SCRIPT.build_family()
	_local_protocol_rev = int(PROTOCOL_SCRIPT.PROTOCOL_VERSION)
	if OS.has_feature("editor"):
		_test_tracked_instances.append(self)

static func free_test_tracked_instances() -> void:
	for i in range(_test_tracked_instances.size() - 1, -1, -1):
		var inst = _test_tracked_instances[i]
		if inst != null and is_instance_valid(inst):
			inst.free()
	_test_tracked_instances.clear()

func set_backend_mode(mode: String) -> void:
	var normalized: String = String(mode).to_lower().strip_edges()
	if normalized == "":
		normalized = BACKEND_MOCK
	if normalized == "ieos":
		normalized = BACKEND_IEOS_RAW
	backend_mode = normalized

func get_backend_mode() -> String:
	return backend_mode

func set_backend_policy(policy: String) -> void:
	var normalized: String = EOS_BACKEND_POLICY_SCRIPT.sanitize(policy)
	if normalized == "":
		backend_policy = EOS_BACKEND_POLICY_SCRIPT.current_policy()
		return
	backend_policy = normalized

func set_local_puid(puid: String) -> void:
	local_puid = String(puid)

func set_runtime_profile(profile: Dictionary) -> void:
	_local_display_name = String(profile.get("display_name", _local_display_name)).strip_edges()
	var build_family: String = String(profile.get(ATTR_BUILD_FAMILY, _local_build_family)).strip_edges().to_lower()
	if build_family != "":
		_local_build_family = build_family
	_local_protocol_rev = maxi(1, int(profile.get(ATTR_PROTOCOL_REV, _local_protocol_rev)))
	_local_epic_account_id = String(profile.get("epic_account_id", _local_epic_account_id)).strip_edges()

func create_lobby(options: Dictionary = {}) -> Dictionary:
	if local_puid == "":
		return _fail("not_logged_in", "local_puid missing")
	if _use_runtime():
		var gate: Dictionary = _begin_runtime_op("create_lobby")
		if not bool(gate.get("ok", false)):
			if _can_fallback_to_mock():
				_downgrade_runtime_to_mock("create_lobby", gate)
				return _mock_create_lobby(options)
			return gate
		call_deferred("_runtime_create_lobby_async", options.duplicate(true))
		return gate
	return _mock_create_lobby(options)

func search_lobbies(filters: Dictionary = {}) -> Dictionary:
	if _use_runtime():
		var gate: Dictionary = _begin_runtime_op("search_lobbies")
		if not bool(gate.get("ok", false)):
			if _can_fallback_to_mock():
				_downgrade_runtime_to_mock("search_lobbies", gate)
				return _mock_search_lobbies(filters)
			return gate
		call_deferred("_runtime_search_lobbies_async", filters.duplicate(true))
		return gate
	return _mock_search_lobbies(filters)

func join_lobby(lobby_id: String) -> Dictionary:
	if local_puid == "":
		return _fail("not_logged_in", "local_puid missing")
	if _use_runtime():
		var gate: Dictionary = _begin_runtime_op("join_lobby")
		if not bool(gate.get("ok", false)):
			if _can_fallback_to_mock():
				_downgrade_runtime_to_mock("join_lobby", gate)
				return _mock_join_lobby(lobby_id)
			return gate
		call_deferred("_runtime_join_lobby_async", String(lobby_id))
		return gate
	return _mock_join_lobby(lobby_id)

func leave_lobby() -> Dictionary:
	if _use_runtime():
		var gate: Dictionary = _begin_runtime_op("leave_lobby")
		if not bool(gate.get("ok", false)):
			if _can_fallback_to_mock():
				_downgrade_runtime_to_mock("leave_lobby", gate)
				return _mock_leave_lobby()
			return gate
		call_deferred("_runtime_leave_lobby_async")
		return gate
	return _mock_leave_lobby()

func set_lobby_attr(key: String, value) -> Dictionary:
	if _use_runtime():
		var gate: Dictionary = _begin_runtime_op("set_lobby_attr")
		if not bool(gate.get("ok", false)):
			if _can_fallback_to_mock():
				_downgrade_runtime_to_mock("set_lobby_attr", gate)
				return _mock_set_lobby_attr(key, value)
			return gate
		call_deferred("_runtime_set_lobby_attr_async", String(key), value)
		return gate
	return _mock_set_lobby_attr(key, value)

func set_member_attr(key: String, value) -> Dictionary:
	if _use_runtime():
		var gate: Dictionary = _begin_runtime_op("set_member_attr")
		if not bool(gate.get("ok", false)):
			if _can_fallback_to_mock():
				_downgrade_runtime_to_mock("set_member_attr", gate)
				return _mock_set_member_attr(key, value)
			return gate
		call_deferred("_runtime_set_member_attr_async", String(key), value)
		return gate
	return _mock_set_member_attr(key, value)

func set_ready(ready: bool) -> Dictionary:
	return set_member_attr("ready", bool(ready))


func set_seat_plan(seat_plan: Array) -> Dictionary:
	var lobby: Dictionary = get_current_lobby()
	var seat_count: int = maxi(2, int(lobby.get("attrs", {}).get(ATTR_SEAT_COUNT, seat_plan.size())))
	var sanitized: Array = _sanitize_stored_seat_plan(seat_plan, seat_count)
	return set_lobby_attr(ATTR_SEAT_PLAN_JSON, JSON.stringify(sanitized))


func get_effective_seat_plan(lobby_model: Dictionary) -> Array:
	if lobby_model.is_empty():
		return []
	var seat_count: int = maxi(2, int(lobby_model.get("attrs", {}).get(ATTR_SEAT_COUNT, 4)))
	var owner_puid: String = String(lobby_model.get("owner_puid", ""))
	var stored: Array = _parse_stored_seat_plan(String(lobby_model.get("attrs", {}).get(ATTR_SEAT_PLAN_JSON, "")), seat_count)
	var effective: Array = _sanitize_stored_seat_plan(stored, seat_count)
	var members_by_puid: Dictionary = {}
	for member in lobby_model.get("members", []):
		if typeof(member) != TYPE_DICTIONARY:
			continue
		var member_dict: Dictionary = member as Dictionary
		var puid: String = String(member_dict.get("puid", "")).strip_edges()
		if puid == "":
			continue
		members_by_puid[puid] = member_dict
	for i in range(effective.size()):
		var slot: Dictionary = effective[i]
		slot["seat"] = i
		if i == 0:
			slot["state"] = "host"
			slot["puid"] = owner_puid
			if members_by_puid.has(owner_puid):
				_apply_member_to_slot(slot, members_by_puid[owner_puid] as Dictionary, true)
			elif String(slot.get("display_name", "")).strip_edges() == "":
				slot["display_name"] = _local_display_name if _local_display_name != "" else "Host"
			effective[i] = slot
			continue
		var state: String = String(slot.get("state", "open")).strip_edges().to_lower()
		var target_puid: String = String(slot.get("target_puid", "")).strip_edges()
		if target_puid != "" and members_by_puid.has(target_puid):
			slot["state"] = "human"
			slot["puid"] = target_puid
			_apply_member_to_slot(slot, members_by_puid[target_puid] as Dictionary, false)
		elif state == "bot":
			slot["display_name"] = String(slot.get("display_name", slot.get("bot_name", "Bot %d" % i))).strip_edges()
			slot["ready"] = true
			slot["status"] = "BOT"
		elif state == "invited":
			slot["display_name"] = String(slot.get("display_name", "Invite Pending")).strip_edges()
			slot["ready"] = false
			slot["status"] = "INVITED"
		else:
			slot["state"] = "open"
			slot["display_name"] = "Empty Seat"
			slot["ready"] = false
			slot["status"] = "OPEN"
		effective[i] = slot
	var assigned: Dictionary = {}
	if owner_puid != "":
		assigned[owner_puid] = true
	for slot in effective:
		var assigned_puid: String = String((slot as Dictionary).get("puid", "")).strip_edges()
		if assigned_puid != "":
			assigned[assigned_puid] = true
	for member in lobby_model.get("members", []):
		if typeof(member) != TYPE_DICTIONARY:
			continue
		var member_dict: Dictionary = member as Dictionary
		var puid: String = String(member_dict.get("puid", "")).strip_edges()
		if puid == "" or assigned.has(puid):
			continue
		for i in range(1, effective.size()):
			var slot: Dictionary = effective[i]
			if String(slot.get("state", "open")) != "open":
				continue
			slot["state"] = "human"
			slot["puid"] = puid
			_apply_member_to_slot(slot, member_dict, false)
			effective[i] = slot
			assigned[puid] = true
			break
	return effective


func list_invitable_friends() -> Dictionary:
	if not _use_runtime():
		return _fail("invite_unavailable", "EOS friend queries require the runtime backend.")
	if _runtime_inflight_op != "":
		return _pending("runtime_busy", {"busy_op": _runtime_inflight_op})
	var boot: Dictionary = _runtime_bootstrap()
	if not bool(boot.get("ok", false)):
		return _fail(String(boot.get("code", "runtime_unavailable")), String(boot.get("reason", "EOS runtime unavailable")))
	return await _runtime_list_invitable_friends_flow()


func invite_to_current_lobby(target_product_user_id: String) -> Dictionary:
	if current_lobby_id.strip_edges() == "":
		return _fail("no_lobby", "Not in lobby.")
	if not _use_runtime():
		return _fail("invite_unavailable", "Lobby invites require the EOS runtime backend.")
	if _runtime_inflight_op != "":
		return _pending("runtime_busy", {"busy_op": _runtime_inflight_op})
	var boot: Dictionary = _runtime_bootstrap()
	if not bool(boot.get("ok", false)):
		return _fail(String(boot.get("code", "runtime_unavailable")), String(boot.get("reason", "EOS runtime unavailable")))
	return await _runtime_send_invite_flow(String(target_product_user_id).strip_edges())

func get_current_lobby() -> Dictionary:
	if _use_runtime():
		return _runtime_current_lobby.duplicate(true)
	if current_lobby_id == "" or not _lobbies.has(current_lobby_id):
		return {}
	return _clone_lobby(_lobbies[current_lobby_id])


func _runtime_list_invitable_friends_flow() -> Dictionary:
	var epic_account_id: String = _runtime_local_epic_account_id()
	if epic_account_id == "":
		return EOS_RAW_SCRIPT.fail("auth_account_missing", "EOS Epic account id is unavailable for friend queries.")
	if _runtime_ieos == null:
		return EOS_RAW_SCRIPT.fail("singleton_missing", "IEOS singleton unavailable.")
	var query_opts := EOS_RAW_SCRIPT.FriendsQueryFriendsOptions.new()
	query_opts.local_user_id = epic_account_id
	var query_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "friends_interface_query_friends", [query_opts])
	if not bool(query_call.get("ok", false)):
		return query_call
	var query_wait: Dictionary = await EOS_RAW_SCRIPT.await_signal_once(self, _runtime_ieos, "friends_interface_query_friends_callback", 15.0)
	if not bool(query_wait.get("ok", false)):
		return query_wait
	var query_cb: Dictionary = _payload_dict(query_wait)
	if not EOS_RAW_SCRIPT.is_success(query_cb):
		return EOS_RAW_SCRIPT.fail("friends_query_failed", "Failed to query EOS friends.", {"result_code": EOS_RAW_SCRIPT.result_code(query_cb)})
	var count_opts := EOS_RAW_SCRIPT.FriendsGetFriendsCountOptions.new()
	count_opts.local_user_id = epic_account_id
	var count_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "friends_interface_get_friends_count", [count_opts])
	if not bool(count_call.get("ok", false)):
		return count_call
	var friend_count: int = int(count_call.get("result", 0))
	var friend_epic_ids: Array[String] = []
	for index in range(maxi(0, friend_count)):
		var get_opts := EOS_RAW_SCRIPT.FriendsGetFriendAtIndexOptions.new()
		get_opts.local_user_id = epic_account_id
		get_opts.index = index
		var get_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "friends_interface_get_friend_at_index", [get_opts])
		if not bool(get_call.get("ok", false)):
			continue
		var friend_epic_id: String = String(get_call.get("result", "")).strip_edges()
		if friend_epic_id != "":
			friend_epic_ids.append(friend_epic_id)
	if friend_epic_ids.is_empty():
		return _ok_with({"friends": []})
	var mapping_query_opts := EOS_RAW_SCRIPT.ConnectQueryExternalAccountMappingsOptions.new()
	mapping_query_opts.local_user_id = local_puid
	mapping_query_opts.account_id_type = EOS_RAW_SCRIPT.EXTERNAL_ACCOUNT_TYPE_EPIC
	mapping_query_opts.external_account_ids = friend_epic_ids
	var mapping_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "connect_interface_query_external_account_mappings", [mapping_query_opts])
	if not bool(mapping_call.get("ok", false)):
		return mapping_call
	var mapping_wait: Dictionary = await EOS_RAW_SCRIPT.await_signal_once(self, _runtime_ieos, "connect_interface_query_external_account_mappings_callback", 15.0)
	if not bool(mapping_wait.get("ok", false)):
		return mapping_wait
	var mapping_cb: Dictionary = _payload_dict(mapping_wait)
	if not EOS_RAW_SCRIPT.is_success(mapping_cb):
		return EOS_RAW_SCRIPT.fail("account_mapping_failed", "Failed to map EOS friend ids to product user ids.", {"result_code": EOS_RAW_SCRIPT.result_code(mapping_cb)})
	var friend_entries: Array = []
	for epic_id in friend_epic_ids:
		var mapping_opts := EOS_RAW_SCRIPT.ConnectGetExternalAccountMappingsOptions.new()
		mapping_opts.account_id_type = EOS_RAW_SCRIPT.EXTERNAL_ACCOUNT_TYPE_EPIC
		mapping_opts.local_user_id = local_puid
		mapping_opts.target_external_user_id = epic_id
		var mapping_res: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "connect_interface_get_external_account_mapping", [mapping_opts])
		if not bool(mapping_res.get("ok", false)):
			continue
		var product_user_id: String = String(mapping_res.get("result", "")).strip_edges()
		if product_user_id == "":
			continue
		var user_info: Dictionary = await _runtime_query_user_info(epic_account_id, epic_id)
		var display_name: String = String(user_info.get("display_name", user_info.get("nickname", epic_id))).strip_edges()
		if display_name == "":
			display_name = epic_id
		friend_entries.append({
			"epic_account_id": epic_id,
			"product_user_id": product_user_id,
			"display_name": display_name,
			"nickname": String(user_info.get("nickname", "")).strip_edges(),
		})
	friend_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("display_name", "")) < String(b.get("display_name", ""))
	)
	return _ok_with({"friends": friend_entries})


func _runtime_send_invite_flow(target_product_user_id: String) -> Dictionary:
	if target_product_user_id == "":
		return EOS_RAW_SCRIPT.fail("invite_target_missing", "Target product user id is required.")
	if _runtime_ieos == null:
		return EOS_RAW_SCRIPT.fail("singleton_missing", "IEOS singleton unavailable.")
	var invite_opts := EOS_RAW_SCRIPT.LobbySendInviteOptions.new()
	invite_opts.local_user_id = local_puid
	invite_opts.target_user_id = target_product_user_id
	invite_opts.lobby_id = current_lobby_id
	var invite_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "lobby_interface_send_invite", [invite_opts])
	if not bool(invite_call.get("ok", false)):
		return invite_call
	var invite_wait: Dictionary = await EOS_RAW_SCRIPT.await_signal_once(self, _runtime_ieos, "lobby_interface_send_invite_callback", 15.0)
	if not bool(invite_wait.get("ok", false)):
		return invite_wait
	var invite_cb: Dictionary = _payload_dict(invite_wait)
	if not EOS_RAW_SCRIPT.is_success(invite_cb):
		return EOS_RAW_SCRIPT.fail("invite_failed", "Failed to send EOS lobby invite.", {"result_code": EOS_RAW_SCRIPT.result_code(invite_cb)})
	return _ok_with({"target_product_user_id": target_product_user_id})


func _runtime_query_user_info(local_epic_account_id: String, target_epic_account_id: String) -> Dictionary:
	if local_epic_account_id == "" or target_epic_account_id == "" or _runtime_ieos == null:
		return {}
	var query_opts := EOS_RAW_SCRIPT.UserInfoQueryUserInfoOptions.new()
	query_opts.local_user_id = local_epic_account_id
	query_opts.target_user_id = target_epic_account_id
	var query_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "user_info_interface_query_user_info", [query_opts])
	if not bool(query_call.get("ok", false)):
		return {}
	var query_wait: Dictionary = await EOS_RAW_SCRIPT.await_signal_once(self, _runtime_ieos, "user_info_interface_query_user_info_callback", 15.0)
	if not bool(query_wait.get("ok", false)):
		return {}
	var query_cb: Dictionary = _payload_dict(query_wait)
	if not EOS_RAW_SCRIPT.is_success(query_cb):
		return {}
	var copy_opts := EOS_RAW_SCRIPT.UserInfoCopyUserInfoOptions.new()
	copy_opts.local_user_id = local_epic_account_id
	copy_opts.target_user_id = target_epic_account_id
	var copy_ret: Dictionary = EOS_RAW_SCRIPT.call_ieos(_runtime_ieos, "user_info_interface_copy_user_info", [copy_opts])
	if not bool(copy_ret.get("ok", false)):
		return {}
	var copy_res = copy_ret.get("result", {})
	if not EOS_RAW_SCRIPT.is_success(copy_res):
		return {}
	var user_info = copy_res.get("user_info", {}) if typeof(copy_res) == TYPE_DICTIONARY else {}
	return user_info if typeof(user_info) == TYPE_DICTIONARY else {}

func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE:
		return
	if OS.has_feature("editor"):
		_test_tracked_instances.erase(self)
	_disconnect_runtime_callbacks()

func _use_runtime() -> bool:
	if backend_mode != BACKEND_IEOS_RAW:
		return false
	if DisplayServer.get_name() == "headless":
		return false
	if not RUNTIME_PLATFORMS.has(OS.get_name()):
		return false
	return true

func _can_fallback_to_mock() -> bool:
	return EOS_BACKEND_POLICY_SCRIPT.allows_mock_fallback(backend_policy)

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
	var game_id: String = String(options.get(ATTR_GAME_ID, ruleset_id)).strip_edges().to_lower()
	var version_tag: String = String(options.get("version", "v1"))
	var phase_tag: String = String(options.get("phase", "FILLING"))
	var privacy_tag: String = String(options.get("privacy", "PUBLIC"))
	var seat_count: int = maxi(2, int(options.get(ATTR_SEAT_COUNT, options.get("max_lobby_members", 4))))
	var build_family: String = String(options.get(ATTR_BUILD_FAMILY, _local_build_family)).strip_edges().to_lower()
	if build_family == "":
		build_family = EOS_BACKEND_POLICY_SCRIPT.build_family()
	var protocol_rev: int = maxi(1, int(options.get(ATTR_PROTOCOL_REV, _local_protocol_rev)))
	_local_build_family = build_family
	_local_protocol_rev = protocol_rev
	create_opts.bucket_id = "%s:%s" % [ruleset_id, version_tag]
	create_opts.max_lobby_members = maxi(seat_count, int(options.get("max_lobby_members", seat_count)))
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
		ATTR_GAME_ID: game_id,
		ATTR_SEAT_COUNT: seat_count,
		"ruleset_id": ruleset_id,
		"version": version_tag,
		"phase": phase_tag,
		"host_puid": local_puid,
		"match_id": String(options.get("match_id", "")),
		"ruleset_hash": String(options.get("ruleset_hash", "")),
		"privacy": privacy_tag,
		ATTR_BUILD_FAMILY: build_family,
		ATTR_PROTOCOL_REV: protocol_rev,
	}
	var seat_plan_json: String = String(options.get(ATTR_SEAT_PLAN_JSON, "")).strip_edges()
	if seat_plan_json != "":
		lobby_attrs[ATTR_SEAT_PLAN_JSON] = seat_plan_json
	var member_attrs: Dictionary = _default_member_attrs()
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
		ATTR_DISPLAY_NAME: _resolved_local_display_name(),
		ATTR_BUILD_FAMILY: _local_build_family,
		ATTR_PROTOCOL_REV: _local_protocol_rev,
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
		ATTR_GAME_ID: "okey101",
		ATTR_SEAT_COUNT: int(info.get("max_members", 4)),
		"ruleset_id": "tr_101_classic",
		"version": "v1",
		"phase": "FILLING",
		"open_slots": int(info.get("available_slots", 0)),
		"host_puid": String(info.get("lobby_owner_user_id", "")),
		"match_id": "",
		"ruleset_hash": "",
		"privacy": "PUBLIC" if int(info.get("permission_level", EOS_RAW_SCRIPT.LOBBY_PERMISSION_PUBLIC_ADVERTISED)) == EOS_RAW_SCRIPT.LOBBY_PERMISSION_PUBLIC_ADVERTISED else "INVITE_ONLY",
		ATTR_BUILD_FAMILY: _local_build_family,
		ATTR_PROTOCOL_REV: _local_protocol_rev,
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
	attrs[ATTR_BUILD_FAMILY] = String(attrs.get(ATTR_BUILD_FAMILY, _local_build_family)).to_lower()
	attrs[ATTR_PROTOCOL_REV] = maxi(1, int(attrs.get(ATTR_PROTOCOL_REV, _local_protocol_rev)))
	var lobby_id: String = String(info.get("lobby_id", current_lobby_id))
	var members: Array = []
	var member_count: int = int(details.get_member_count())
	for mi in range(maxi(0, member_count)):
		var puid: String = String(details.get_member_by_index(mi))
		if puid == "":
			continue
		var member_attrs: Dictionary = _default_member_attrs(puid)
		member_attrs["status"] = String(_runtime_status_hint_by_puid.get(puid, "OK"))
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
		member_attrs["platform"] = String(member_attrs.get("platform", _platform_tag())).to_lower()
		member_attrs[ATTR_DISPLAY_NAME] = String(member_attrs.get(ATTR_DISPLAY_NAME, puid))
		member_attrs[ATTR_BUILD_FAMILY] = String(member_attrs.get(ATTR_BUILD_FAMILY, attrs.get(ATTR_BUILD_FAMILY, _local_build_family))).to_lower()
		member_attrs[ATTR_PROTOCOL_REV] = maxi(1, int(member_attrs.get(ATTR_PROTOCOL_REV, attrs.get(ATTR_PROTOCOL_REV, _local_protocol_rev))))
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
		"attrs": _default_member_attrs(),
	}

func _resolved_local_display_name() -> String:
	if _local_display_name.strip_edges() != "":
		return _local_display_name
	if local_puid.strip_edges() != "":
		return local_puid
	return "Player"

func _default_member_attrs(member_puid: String = "") -> Dictionary:
	var resolved_puid: String = member_puid if member_puid.strip_edges() != "" else local_puid
	var resolved_display: String = _resolved_local_display_name() if resolved_puid == local_puid else resolved_puid
	return {
		"seat": -1,
		"ready": false,
		"status": "OK",
		"platform": _platform_tag(),
		ATTR_DISPLAY_NAME: resolved_display,
		ATTR_BUILD_FAMILY: _local_build_family,
		ATTR_PROTOCOL_REV: _local_protocol_rev,
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
	var seat_count: int = maxi(2, int(lobby.get("attrs", {}).get(ATTR_SEAT_COUNT, 4)))
	var open_slots: int = maxi(0, seat_count - int(lobby.get("members", []).size()))
	lobby["attrs"]["open_slots"] = open_slots

func _platform_tag() -> String:
	if OS.get_name() == "Windows":
		return "pc"
	if OS.get_name() == "Android":
		return "android"
	return "unknown"


func _runtime_local_epic_account_id() -> String:
	if _local_epic_account_id.strip_edges() != "":
		return _local_epic_account_id
	var runtime_root: Node = get_node_or_null("/root/EOSGRuntime")
	if runtime_root != null:
		var epic_account_id: String = String(runtime_root.get("local_epic_account_id")).strip_edges()
		if epic_account_id != "":
			return epic_account_id
	return ""


func _parse_stored_seat_plan(raw_json: String, seat_count: int) -> Array:
	var parsed = JSON.parse_string(raw_json)
	if typeof(parsed) == TYPE_ARRAY:
		return _sanitize_stored_seat_plan(parsed as Array, seat_count)
	return _sanitize_stored_seat_plan([], seat_count)


func _sanitize_stored_seat_plan(seat_plan: Array, seat_count: int) -> Array:
	var out: Array = []
	for seat_index in range(maxi(2, seat_count)):
		var source: Dictionary = {}
		if seat_index < seat_plan.size() and typeof(seat_plan[seat_index]) == TYPE_DICTIONARY:
			source = (seat_plan[seat_index] as Dictionary).duplicate(true)
		var state: String = String(source.get("state", "open")).strip_edges().to_lower()
		if seat_index == 0:
			state = "host"
		elif state != "bot" and state != "invited":
			state = "open"
		var slot: Dictionary = {
			"seat": seat_index,
			"state": state,
		}
		if state == "host":
			var host_display_name: String = String(source.get("display_name", _local_display_name if _local_display_name != "" else "You")).strip_edges()
			slot["display_name"] = host_display_name if host_display_name != "" else "You"
		elif state == "bot":
			var bot_name: String = String(source.get("bot_name", source.get("display_name", "Bot %d" % seat_index))).strip_edges()
			slot["bot_name"] = bot_name if bot_name != "" else "Bot %d" % seat_index
			slot["display_name"] = slot["bot_name"]
		elif state == "invited":
			slot["target_puid"] = String(source.get("target_puid", "")).strip_edges()
			slot["epic_account_id"] = String(source.get("epic_account_id", "")).strip_edges()
			slot["display_name"] = String(source.get("display_name", "Invite Pending")).strip_edges()
		out.append(slot)
	return out


func _apply_member_to_slot(slot: Dictionary, member: Dictionary, is_host: bool) -> void:
	var puid: String = String(member.get("puid", "")).strip_edges()
	var attrs: Dictionary = member.get("attrs", {})
	var display_name: String = String(attrs.get(ATTR_DISPLAY_NAME, puid)).strip_edges()
	if display_name == "":
		display_name = puid
	slot["puid"] = puid
	slot["target_puid"] = puid
	slot["display_name"] = display_name
	slot["ready"] = bool(attrs.get("ready", false))
	slot["status"] = String(attrs.get("status", "OK")).strip_edges().to_upper()
	slot["platform"] = String(attrs.get("platform", _platform_tag())).strip_edges().to_lower()
	slot["state"] = "host" if is_host else "human"

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
	var out: Dictionary = {
		"ok": true,
		"code": "ok",
		"reason": "",
		"backend_mode": backend_mode,
		"backend_policy": backend_policy,
	}
	for k in extra.keys():
		out[k] = extra[k]
	return out

func _pending(reason: String, extra: Dictionary = {}) -> Dictionary:
	var out: Dictionary = {
		"ok": true,
		"code": "pending",
		"reason": reason,
		"backend_mode": backend_mode,
		"backend_policy": backend_policy,
	}
	for k in extra.keys():
		out[k] = extra[k]
	return out

func _fail(code: String, reason: String) -> Dictionary:
	emit_signal("lobby_error", code, reason)
	return {
		"ok": false,
		"code": code,
		"reason": reason,
		"backend_mode": backend_mode,
		"backend_policy": backend_policy,
	}

func _mock_create_lobby(options: Dictionary = {}) -> Dictionary:
	var lobby_id: String = "L_%08x" % int(abs(hash("%s|%s" % [local_puid, Time.get_unix_time_from_system()])))
	var lobby: Dictionary = {
		"lobby_id": lobby_id,
		"owner_puid": local_puid,
		"attrs": {
			ATTR_GAME_ID: String(options.get(ATTR_GAME_ID, options.get("ruleset_id", "tr_101_classic"))).strip_edges().to_lower(),
			ATTR_SEAT_COUNT: maxi(2, int(options.get(ATTR_SEAT_COUNT, options.get("max_lobby_members", 4)))),
			"ruleset_id": String(options.get("ruleset_id", "tr_101_classic")),
			"version": String(options.get("version", "v1")),
			"phase": String(options.get("phase", "FILLING")),
			"open_slots": int(options.get("open_slots", 3)),
			"host_puid": local_puid,
			"match_id": String(options.get("match_id", "")),
			"ruleset_hash": String(options.get("ruleset_hash", "")),
			"privacy": String(options.get("privacy", "PUBLIC")),
			ATTR_BUILD_FAMILY: String(options.get(ATTR_BUILD_FAMILY, _local_build_family)).strip_edges().to_lower(),
			ATTR_PROTOCOL_REV: maxi(1, int(options.get(ATTR_PROTOCOL_REV, _local_protocol_rev))),
			ATTR_SEAT_PLAN_JSON: String(options.get(ATTR_SEAT_PLAN_JSON, "")),
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
	if key == "ruleset_id" or key == "version" or key == "phase" or key == ATTR_BUILD_FAMILY or key == ATTR_PROTOCOL_REV or key == ATTR_GAME_ID or key == ATTR_SEAT_COUNT:
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
			if String(key) == ATTR_DISPLAY_NAME:
				_local_display_name = String(value).strip_edges()
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
