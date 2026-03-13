extends RefCounted
class_name EOSRaw

const EOSG_EXTENSION_PATH: String = "res://addons/epic-online-services-godot/eosg.gdextension"

const RESULT_SUCCESS: int = 0

const AUTH_SCOPE_NO_FLAGS: int = 0
const AUTH_SCOPE_BASIC_PROFILE: int = 1
const AUTH_SCOPE_FRIENDS_LIST: int = 2
const AUTH_SCOPE_PRESENCE: int = 4
const AUTH_SCOPE_DEFAULT: int = AUTH_SCOPE_BASIC_PROFILE | AUTH_SCOPE_FRIENDS_LIST | AUTH_SCOPE_PRESENCE
const AUTH_LOGIN_FLAGS_NONE: int = 0
const AUTH_LOGIN_CREDENTIAL_DEVELOPER: int = 4
const AUTH_LOGIN_CREDENTIAL_ACCOUNT_PORTAL: int = 6

const EXTERNAL_CREDENTIAL_EPIC: int = 0
const EXTERNAL_ACCOUNT_TYPE_EPIC: int = 0

const LOBBY_PERMISSION_PUBLIC_ADVERTISED: int = 0
const LOBBY_PERMISSION_INVITE_ONLY: int = 2
const LOBBY_ATTRIBUTE_VISIBILITY_PUBLIC: int = 0
const COMPARISON_OP_EQUAL: int = 0

const RTC_ROOM_JOIN_AUTOMATIC: int = 0


class PlatformInitializeOptions:
	extends RefCounted
	var product_name: String = ""
	var product_version: String = ""


class PlatformRTCOptions:
	extends RefCounted
	var background_mode = null


class PlatformCreateOptions:
	extends RefCounted
	var client_id: String = ""
	var client_secret: String = ""
	var deployment_id: String = ""
	var encryption_key: String = ""
	var product_id: String = ""
	var sandbox_id: String = ""
	var cache_directory: String = ""
	var flags: int = 0
	var is_server: bool = false
	var override_country_code: String = ""
	var override_locale_code: String = ""
	var tick_budget_in_milliseconds: int = 2
	var task_network_timeout_seconds = null
	var rtc_options: PlatformRTCOptions = PlatformRTCOptions.new()


class AuthCredentials:
	extends RefCounted
	var external_type: int = -1
	var id: String = ""
	var token: String = ""
	var type: int = -1


class AuthLoginOptions:
	extends RefCounted
	var credentials: AuthCredentials = null
	var login_flags: int = AUTH_LOGIN_FLAGS_NONE
	var scope_flags: int = AUTH_SCOPE_NO_FLAGS
	var client_data = null


class AuthCopyUserAuthTokenOptions:
	extends RefCounted
	pass


class ConnectCredentials:
	extends RefCounted
	var type: int = -1
	var token = null


class ConnectUserLoginInfo:
	extends RefCounted
	var display_name: String = ""
	var nsa_id_token: String = ""


class ConnectLoginOptions:
	extends RefCounted
	var credentials: ConnectCredentials = null
	var user_login_info: ConnectUserLoginInfo = null
	var client_data = null


class ConnectCreateUserOptions:
	extends RefCounted
	var continuance_token = null
	var client_data = null


class ConnectQueryExternalAccountMappingsOptions:
	extends RefCounted
	var local_user_id: String = ""
	var account_id_type: int = EXTERNAL_ACCOUNT_TYPE_EPIC
	var external_account_ids: Array = []


class ConnectGetExternalAccountMappingsOptions:
	extends RefCounted
	var account_id_type: int = EXTERNAL_ACCOUNT_TYPE_EPIC
	var local_user_id: String = ""
	var target_external_user_id: String = ""


class FriendsQueryFriendsOptions:
	extends RefCounted
	var local_user_id: String = ""
	var client_data = null


class FriendsGetFriendsCountOptions:
	extends RefCounted
	var local_user_id: String = ""


class FriendsGetFriendAtIndexOptions:
	extends RefCounted
	var local_user_id: String = ""
	var index: int = 0


class UserInfoQueryUserInfoOptions:
	extends RefCounted
	var local_user_id: String = ""
	var target_user_id: String = ""
	var client_data = null


class UserInfoCopyUserInfoOptions:
	extends RefCounted
	var local_user_id: String = ""
	var target_user_id: String = ""


class LobbyCreateOptions:
	extends RefCounted
	var bucket_id: String = ""
	var lobby_id: String = ""
	var disable_host_migration: bool = false
	var max_lobby_members: int = 4
	var rejoin_after_kick_requires_invite: bool = false
	var crossplay_opt_out: bool = false
	var enable_rtc_room: bool = true
	var allow_invites: bool = true
	var enable_join_by_id: bool = true
	var local_user_id: String = ""
	var permission_level: int = LOBBY_PERMISSION_PUBLIC_ADVERTISED
	var presence_enabled: bool = true
	var local_rtc_options = null
	var rtc_room_join_action_type: int = RTC_ROOM_JOIN_AUTOMATIC
	var client_data = null


class LobbyJoinByIdOptions:
	extends RefCounted
	var local_user_id: String = ""
	var lobby_id: String = ""
	var presence_enabled: bool = true
	var local_rtc_options = null
	var rtc_room_join_action_type: int = RTC_ROOM_JOIN_AUTOMATIC
	var client_data = null


class LobbyLeaveOptions:
	extends RefCounted
	var local_user_id: String = ""
	var lobby_id: String = ""
	var client_data = null


class LobbyCreateSearchOptions:
	extends RefCounted
	var max_results: int = 25


class LobbyCopyDetailsOptions:
	extends RefCounted
	var local_user_id: String = ""
	var lobby_id: String = ""


class LobbyUpdateModificationOptions:
	extends RefCounted
	var local_user_id: String = ""
	var lobby_id: String = ""
	var client_data = null


class LobbyUpdateOptions:
	extends RefCounted
	var lobby_modification = null
	var client_data = null


class LobbyGetRtcRoomNameOptions:
	extends RefCounted
	var local_user_id: String = ""
	var lobby_id: String = ""


class LobbySendInviteOptions:
	extends RefCounted
	var local_user_id: String = ""
	var target_user_id: String = ""
	var lobby_id: String = ""
	var client_data = null


class UIShowFriendsOptions:
	extends RefCounted
	var local_user_id: String = ""
	var client_data = null


class RTCDataAddNotifyDataReceivedOptions:
	extends RefCounted
	var local_user_id: String = ""
	var room_name: String = ""


class RTCDataAddNotifyParticipantUpdatedOptions:
	extends RefCounted
	var local_user_id: String = ""
	var room_name: String = ""


class RTCDataSendDataOptions:
	extends RefCounted
	var local_user_id: String = ""
	var room_name: String = ""
	var data: PackedByteArray = PackedByteArray()


class RTCDataUpdateSendingOptions:
	extends RefCounted
	var local_user_id: String = ""
	var room_name: String = ""
	var data_enabled: bool = true


class RTCDataUpdateReceivingOptions:
	extends RefCounted
	var local_user_id: String = ""
	var room_name: String = ""
	var participant_id: String = ""
	var data_enabled: bool = true


static func ensure_extension_loaded() -> Dictionary:
	var ext = load(EOSG_EXTENSION_PATH)
	if ext == null:
		return fail("extension_missing", "Failed to load EOSG extension resource.")
	if not Engine.has_singleton("IEOS"):
		return fail("singleton_missing", "IEOS singleton not available after extension load.")
	return ok_with({
		"extension_path": EOSG_EXTENSION_PATH,
	})


static func get_ieos():
	if not Engine.has_singleton("IEOS"):
		return null
	return Engine.get_singleton("IEOS")


static func is_success(result) -> bool:
	if typeof(result) == TYPE_BOOL:
		return bool(result)
	if typeof(result) == TYPE_DICTIONARY:
		return int(result.get("result_code", -1)) == RESULT_SUCCESS
	return int(result) == RESULT_SUCCESS


static func result_code(result) -> int:
	if typeof(result) == TYPE_DICTIONARY:
		return int(result.get("result_code", -1))
	return int(result)


static func ok_with(extra: Dictionary = {}) -> Dictionary:
	var out: Dictionary = {"ok": true, "code": "ok", "reason": ""}
	for k in extra.keys():
		out[k] = extra[k]
	return out


static func fail(code: String, reason: String, extra: Dictionary = {}) -> Dictionary:
	var out: Dictionary = {"ok": false, "code": code, "reason": reason}
	for k in extra.keys():
		out[k] = extra[k]
	return out


static func env_or(key: String, fallback: String = "") -> String:
	var raw: String = String(OS.get_environment(key))
	if raw.strip_edges() == "":
		return fallback
	return raw


static func bool_env_enabled(key: String, fallback: bool = false) -> bool:
	var raw: String = String(OS.get_environment(key)).strip_edges().to_lower()
	if raw == "":
		return fallback
	return raw == "1" or raw == "true" or raw == "yes" or raw == "on"


static func missing_env_keys(keys: Array) -> Array:
	var missing: Array = []
	for k in keys:
		var name: String = String(k)
		if env_or(name, "").strip_edges() == "":
			missing.append(name)
	return missing


static func call_ieos(ieos, method_name: String, args: Array = []) -> Dictionary:
	if ieos == null:
		return fail("ieos_missing", "IEOS singleton is not available.")
	if not ieos.has_method(method_name):
		return fail("method_missing", "IEOS method not found: %s" % method_name)
	var result = ieos.callv(method_name, args)
	return ok_with({"result": result})


static func await_signal_once(host: Node, emitter: Object, signal_name: String, timeout_sec: float = 10.0) -> Dictionary:
	if host == null or host.get_tree() == null:
		return fail("host_missing", "Signal wait host is invalid.")
	if emitter == null:
		return fail("emitter_missing", "Signal emitter is null.")
	if not emitter.has_signal(signal_name):
		return fail("signal_missing", "Emitter does not expose signal: %s" % signal_name)
	var state: Dictionary = {
		"fired": false,
		"args": [],
	}
	var callback := func(a = null, b = null, c = null, d = null, e = null, f = null, g = null, h = null):
		state["fired"] = true
		state["args"] = [a, b, c, d, e, f, g, h]
	var connect_err: int = emitter.connect(signal_name, callback, CONNECT_ONE_SHOT)
	if connect_err != OK:
		return fail("signal_connect_failed", "Failed to connect signal: %s" % signal_name, {"error": connect_err})
	var timer = host.get_tree().create_timer(maxf(0.05, timeout_sec))
	while not bool(state.get("fired", false)) and timer.time_left > 0.0:
		await host.get_tree().process_frame
	if bool(state.get("fired", false)):
		var args: Array = state.get("args", []) as Array
		var payload = args[0] if args.size() > 0 else {}
		if payload == null:
			payload = {}
		return ok_with({"payload": payload, "args": args.duplicate(true)})
	return fail("signal_timeout", "Timed out waiting for signal: %s" % signal_name)
