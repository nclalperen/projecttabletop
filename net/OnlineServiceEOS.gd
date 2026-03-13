extends Node
class_name OnlineServiceEOS

signal availability_changed(available, reason)
signal login_succeeded(local_puid)
signal login_failed(reason)
signal logged_out()

const EOS_RAW_SCRIPT: Script = preload("res://net/eos/EOSRaw.gd")
const EOS_BACKEND_POLICY_SCRIPT: Script = preload("res://net/EOSBackendPolicy.gd")
const BACKEND_MOCK: String = "mock"
const BACKEND_IEOS: String = "ieos_raw"
const SUPPORTED_RUNTIME_PLATFORMS: PackedStringArray = ["Windows", "Android"]
const LOGIN_METHOD_DEV_AUTH: String = "dev_auth"
const LOGIN_METHOD_ACCOUNT_PORTAL: String = "account_portal"

static var _test_tracked_instances: Array = []
static var _session_cache: Dictionary = {}

var initialized: bool = false
var available: bool = false
var unavailable_reason: String = ""
var local_puid: String = ""
var local_display_name: String = ""
var backend_mode: String = BACKEND_MOCK
var backend_policy: String = EOS_BACKEND_POLICY_SCRIPT.POLICY_MOCK_ALLOWED
var backend_details: Dictionary = {}
var _runtime_initialized: bool = false
var _runtime_login_inflight: bool = false
var _runtime_env: Dictionary = {}
var _runtime_epic_account_id: String = ""


func _init() -> void:
	if OS.has_feature("editor"):
		_test_tracked_instances.append(self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and OS.has_feature("editor"):
		_test_tracked_instances.erase(self)


static func free_test_tracked_instances() -> void:
	for i in range(_test_tracked_instances.size() - 1, -1, -1):
		var inst = _test_tracked_instances[i]
		if inst != null and is_instance_valid(inst):
			inst.free()
	_test_tracked_instances.clear()


func _process(_delta: float) -> void:
	if backend_mode != BACKEND_IEOS:
		return
	if not _runtime_initialized:
		return
	var ieos = EOS_RAW_SCRIPT.get_ieos()
	if ieos == null:
		return
	if ieos.has_method("tick"):
		ieos.call("tick")


func initialize() -> Dictionary:
	initialized = true
	_runtime_initialized = false
	_runtime_login_inflight = false
	_runtime_epic_account_id = String(_session_cache.get("epic_account_id", "")).strip_edges()
	local_puid = String(_session_cache.get("local_puid", "")).strip_edges()
	local_display_name = String(_session_cache.get("display_name", "")).strip_edges()
	_runtime_env = _collect_runtime_env()
	backend_policy = EOS_BACKEND_POLICY_SCRIPT.current_policy()
	backend_mode = _detect_backend_mode_for_policy()

	backend_details = {
		"os": OS.get_name(),
		"headless": _is_headless_runtime(),
		"policy": backend_policy,
		"runtime_attempt_enabled": EOS_BACKEND_POLICY_SCRIPT.should_attempt_runtime(backend_policy),
		"runtime_supported_platform": _is_supported_platform(),
		"has_ieos": Engine.has_singleton("IEOS"),
		"has_eos_singleton": Engine.has_singleton("EOS"),
		"has_eosg_singleton": Engine.has_singleton("EOSG"),
		"has_eosg_extension_resource": _has_runtime_extension_resource(),
		"backend_mode": backend_mode,
	}

	if not _is_supported_platform():
		available = false
		unavailable_reason = "Online EOS runtime is supported on Windows and Android in v1."
	else:
		available = true
		unavailable_reason = ""
		if backend_mode == BACKEND_IEOS:
			var runtime_init: Dictionary = _initialize_runtime_backend()
			if not bool(runtime_init.get("ok", false)):
				if EOS_BACKEND_POLICY_SCRIPT.allows_mock_fallback(backend_policy):
					_downgrade_to_mock("EOS runtime unavailable (%s): %s" % [String(runtime_init.get("code", "init_failed")), String(runtime_init.get("reason", ""))])
				else:
					available = false
					unavailable_reason = "EOS runtime required but unavailable (%s): %s" % [String(runtime_init.get("code", "init_failed")), String(runtime_init.get("reason", ""))]
			else:
				unavailable_reason = ""
		else:
			if EOS_BACKEND_POLICY_SCRIPT.runtime_required(backend_policy):
				available = false
				unavailable_reason = "EOS runtime is required by backend policy, but runtime is not available in this environment."
			elif EOS_BACKEND_POLICY_SCRIPT.runtime_preferred(backend_policy):
				unavailable_reason = "EOS runtime unavailable. Using mock backend for development." if _is_runtime_environment_blocked_reason() != "" else "Using mock backend."
			else:
				unavailable_reason = "Using mock backend."

	backend_details["backend_mode"] = backend_mode
	backend_details["runtime_initialized"] = _runtime_initialized
	backend_details["available"] = available
	backend_details["reason"] = unavailable_reason
	backend_details["supports_overlay"] = supports_eos_overlay()
	backend_details["supports_friend_queries"] = supports_friend_queries()

	emit_signal("availability_changed", available, unavailable_reason)
	return {
		"ok": available,
		"code": "ok" if available else "unavailable",
		"reason": unavailable_reason,
		"backend_mode": backend_mode,
		"backend_policy": backend_policy,
		"backend_details": backend_details.duplicate(true),
	}


func is_available() -> bool:
	if not initialized:
		initialize()
	return available


func is_runtime_backend() -> bool:
	if not initialized:
		initialize()
	return backend_mode == BACKEND_IEOS


func get_backend_mode() -> String:
	if not initialized:
		initialize()
	return backend_mode


func get_backend_policy() -> String:
	if not initialized:
		initialize()
	return backend_policy


func get_backend_details() -> Dictionary:
	if not initialized:
		initialize()
	return backend_details.duplicate(true)


func get_local_display_name() -> String:
	return local_display_name


func get_epic_account_id() -> String:
	return _runtime_epic_account_id


func supports_eos_overlay() -> bool:
	if not initialized:
		initialize()
	if backend_mode != BACKEND_IEOS or not _runtime_initialized:
		return false
	var ieos = EOS_RAW_SCRIPT.get_ieos()
	if ieos == null:
		return false
	return ieos.has_method("ui_interface_show_friends")


func supports_friend_queries() -> bool:
	if not initialized:
		initialize()
	if backend_mode != BACKEND_IEOS or not _runtime_initialized:
		return false
	if local_puid.strip_edges() == "" or _runtime_epic_account_id.strip_edges() == "":
		return false
	var ieos = EOS_RAW_SCRIPT.get_ieos()
	if ieos == null:
		return false
	return ieos.has_method("friends_interface_query_friends") \
		and ieos.has_method("connect_interface_query_external_account_mappings") \
		and ieos.has_method("connect_interface_get_external_account_mapping") \
		and ieos.has_method("user_info_interface_query_user_info")


func open_friends_overlay() -> Dictionary:
	if not supports_eos_overlay():
		return {
			"ok": false,
			"code": "overlay_unavailable",
			"reason": "EOS friends overlay is unavailable.",
		}
	var ieos = EOS_RAW_SCRIPT.get_ieos()
	if ieos == null:
		return {
			"ok": false,
			"code": "singleton_missing",
			"reason": "IEOS singleton unavailable.",
		}
	var opts := EOS_RAW_SCRIPT.UIShowFriendsOptions.new()
	opts.local_user_id = _runtime_epic_account_id
	var call_res: Dictionary = EOS_RAW_SCRIPT.call_ieos(ieos, "ui_interface_show_friends", [opts])
	if not bool(call_res.get("ok", false)):
		return call_res
	return {
		"ok": true,
		"code": "ok",
		"reason": "",
	}


func login_account_portal(display_name_hint: String = "") -> Dictionary:
	return _login_with_method(LOGIN_METHOD_ACCOUNT_PORTAL, display_name_hint)


func login_dev_auth(display_name: String = "dev_player") -> Dictionary:
	return _login_with_method(LOGIN_METHOD_DEV_AUTH, display_name)


func logout() -> void:
	if local_puid == "":
		return
	_runtime_login_inflight = false
	_runtime_epic_account_id = ""
	local_puid = ""
	local_display_name = ""
	_session_cache.clear()
	emit_signal("logged_out")


func get_unavailable_reason() -> String:
	if not initialized:
		initialize()
	return unavailable_reason


func _login_with_method(method: String, display_name_hint: String) -> Dictionary:
	if not is_available():
		emit_signal("login_failed", unavailable_reason)
		return {
			"ok": false,
			"code": "unavailable",
			"reason": unavailable_reason,
			"backend_mode": backend_mode,
			"backend_policy": backend_policy,
		}
	if local_puid != "":
		return {
			"ok": true,
			"code": "ok",
			"reason": "",
			"local_puid": local_puid,
			"display_name": local_display_name,
			"backend_mode": backend_mode,
			"backend_policy": backend_policy,
		}
	if backend_mode == BACKEND_IEOS:
		if not _runtime_initialized:
			var reason: String = "EOS runtime is not initialized."
			if EOS_BACKEND_POLICY_SCRIPT.allows_mock_fallback(backend_policy):
				_downgrade_to_mock(reason + " Falling back to mock backend.")
				return _login_with_method(method, display_name_hint)
			emit_signal("login_failed", reason)
			return {
				"ok": false,
				"code": "runtime_not_initialized",
				"reason": reason,
				"backend_mode": backend_mode,
				"backend_policy": backend_policy,
			}
		if _runtime_login_inflight:
			return {
				"ok": true,
				"code": "pending",
				"reason": "login_in_progress",
				"backend_mode": backend_mode,
				"backend_policy": backend_policy,
			}
		_runtime_login_inflight = true
		var credential_name: String = String(_runtime_env.get("EOS_DEV_AUTH_CREDENTIAL", "")).strip_edges()
		if credential_name == "":
			credential_name = display_name_hint
		call_deferred("_runtime_login_async", method, display_name_hint, credential_name)
		return {
			"ok": true,
			"code": "pending",
			"reason": "runtime_login_started",
			"backend_mode": backend_mode,
			"backend_policy": backend_policy,
		}

	# Mock identity path for deterministic local development and tests.
	var mock_display_name: String = String(display_name_hint).strip_edges()
	if mock_display_name == "":
		mock_display_name = "Player"
	var seed_src: String = "%s|%s|%s" % [mock_display_name, OS.get_unique_id(), Time.get_unix_time_from_system()]
	local_puid = "PUID_%08x" % int(abs(hash(seed_src)))
	local_display_name = mock_display_name
	_persist_session_cache()
	emit_signal("login_succeeded", local_puid)
	return {
		"ok": true,
		"code": "ok",
		"reason": "",
		"local_puid": local_puid,
		"display_name": local_display_name,
		"backend_mode": backend_mode,
		"backend_policy": backend_policy,
	}


func _runtime_login_async(method: String, display_name_hint: String, credential_name: String) -> void:
	var runtime_result: Dictionary = {}
	if method == LOGIN_METHOD_ACCOUNT_PORTAL:
		runtime_result = await _runtime_login_account_portal_flow(display_name_hint)
	else:
		runtime_result = await _runtime_login_dev_auth_flow(display_name_hint, credential_name)
	_runtime_login_inflight = false
	if not bool(runtime_result.get("ok", false)):
		var reason: String = String(runtime_result.get("reason", "Runtime login failed."))
		var code: String = String(runtime_result.get("code", "login_failed"))
		if EOS_BACKEND_POLICY_SCRIPT.allows_mock_fallback(backend_policy):
			_downgrade_to_mock("Runtime login failed (%s): %s" % [code, reason])
			var fallback_res: Dictionary = _login_with_method(method, display_name_hint)
			if bool(fallback_res.get("ok", false)):
				return
		emit_signal("login_failed", reason)
		return
	local_puid = String(runtime_result.get("local_puid", ""))
	if local_puid == "":
		var puid_reason: String = "Runtime login did not return a product user id."
		if EOS_BACKEND_POLICY_SCRIPT.allows_mock_fallback(backend_policy):
			_downgrade_to_mock(puid_reason + " Falling back to mock backend.")
			var fallback_puid_res: Dictionary = _login_with_method(method, display_name_hint)
			if bool(fallback_puid_res.get("ok", false)):
				return
		emit_signal("login_failed", puid_reason)
		return
	local_display_name = String(runtime_result.get("display_name", "")).strip_edges()
	if local_display_name == "":
		local_display_name = local_puid
	_persist_session_cache()
	emit_signal("login_succeeded", local_puid)


func _runtime_login_account_portal_flow(display_name_hint: String) -> Dictionary:
	var auth_creds := EOS_RAW_SCRIPT.AuthCredentials.new()
	auth_creds.type = EOS_RAW_SCRIPT.AUTH_LOGIN_CREDENTIAL_ACCOUNT_PORTAL
	auth_creds.id = ""
	auth_creds.token = ""
	return await _runtime_auth_to_connect_flow(auth_creds, display_name_hint)


func _runtime_login_dev_auth_flow(display_name_hint: String, credential_name: String) -> Dictionary:
	var auth_creds := EOS_RAW_SCRIPT.AuthCredentials.new()
	auth_creds.type = EOS_RAW_SCRIPT.AUTH_LOGIN_CREDENTIAL_DEVELOPER
	auth_creds.id = String(_runtime_env.get("EOS_DEV_AUTH_HOST", "localhost:4545"))
	auth_creds.token = credential_name
	return await _runtime_auth_to_connect_flow(auth_creds, display_name_hint)


func _runtime_auth_to_connect_flow(auth_creds: RefCounted, display_name_hint: String) -> Dictionary:
	if not _runtime_initialized:
		return EOS_RAW_SCRIPT.fail("runtime_not_initialized", "Runtime backend is not initialized.")
	var ieos = EOS_RAW_SCRIPT.get_ieos()
	if ieos == null:
		return EOS_RAW_SCRIPT.fail("singleton_missing", "IEOS singleton unavailable.")

	var auth_opts := EOS_RAW_SCRIPT.AuthLoginOptions.new()
	auth_opts.credentials = auth_creds
	auth_opts.login_flags = EOS_RAW_SCRIPT.AUTH_LOGIN_FLAGS_NONE
	auth_opts.scope_flags = EOS_RAW_SCRIPT.AUTH_SCOPE_DEFAULT
	var auth_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(ieos, "auth_interface_login", [auth_opts])
	if not bool(auth_call.get("ok", false)):
		return auth_call
	var auth_wait: Dictionary = await EOS_RAW_SCRIPT.await_signal_once(self, ieos, "auth_interface_login_callback", 15.0)
	if not bool(auth_wait.get("ok", false)):
		return auth_wait
	var auth_cb: Dictionary = _payload_dict(auth_wait)
	if not EOS_RAW_SCRIPT.is_success(auth_cb):
		return EOS_RAW_SCRIPT.fail("auth_login_failed", "Auth login failed.", {"result_code": EOS_RAW_SCRIPT.result_code(auth_cb)})

	_runtime_epic_account_id = String(auth_cb.get("selected_account_id", auth_cb.get("local_user_id", "")))
	if _runtime_epic_account_id.strip_edges() == "":
		_runtime_epic_account_id = String(auth_cb.get("account_id", ""))
	if _runtime_epic_account_id.strip_edges() == "":
		return EOS_RAW_SCRIPT.fail("auth_account_missing", "Auth callback did not return an account id.")

	var resolved_display_name: String = _resolve_display_name(auth_cb, display_name_hint)

	var copy_opts := EOS_RAW_SCRIPT.AuthCopyUserAuthTokenOptions.new()
	var copy_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(ieos, "auth_interface_copy_user_auth_token", [copy_opts, _runtime_epic_account_id])
	if not bool(copy_call.get("ok", false)):
		return copy_call
	var token_result: Dictionary = copy_call.get("result", {}) as Dictionary
	if not EOS_RAW_SCRIPT.is_success(token_result):
		return EOS_RAW_SCRIPT.fail("auth_token_copy_failed", "Failed to copy auth token.", {"result_code": EOS_RAW_SCRIPT.result_code(token_result)})
	var token_dict: Dictionary = token_result.get("token", {}) as Dictionary
	var access_token: String = String(token_dict.get("access_token", ""))
	if access_token.strip_edges() == "":
		return EOS_RAW_SCRIPT.fail("auth_token_missing", "Auth token did not include access_token.")

	var connect_creds := EOS_RAW_SCRIPT.ConnectCredentials.new()
	connect_creds.type = EOS_RAW_SCRIPT.EXTERNAL_CREDENTIAL_EPIC
	connect_creds.token = access_token
	var connect_opts := EOS_RAW_SCRIPT.ConnectLoginOptions.new()
	connect_opts.credentials = connect_creds
	var connect_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(ieos, "connect_interface_login", [connect_opts])
	if not bool(connect_call.get("ok", false)):
		return connect_call
	var connect_wait: Dictionary = await EOS_RAW_SCRIPT.await_signal_once(self, ieos, "connect_interface_login_callback", 15.0)
	if not bool(connect_wait.get("ok", false)):
		return connect_wait
	var connect_cb: Dictionary = _payload_dict(connect_wait)
	if EOS_RAW_SCRIPT.is_success(connect_cb):
		var local_user: String = String(connect_cb.get("local_user_id", ""))
		if local_user.strip_edges() == "":
			return EOS_RAW_SCRIPT.fail("connect_user_missing", "Connect login succeeded without local_user_id.")
		resolved_display_name = _resolve_display_name(connect_cb, resolved_display_name)
		return EOS_RAW_SCRIPT.ok_with({"local_puid": local_user, "display_name": resolved_display_name})

	var continuance_token = connect_cb.get("continuance_token", null)
	if continuance_token == null:
		return EOS_RAW_SCRIPT.fail("connect_login_failed", "Connect login failed.", {"result_code": EOS_RAW_SCRIPT.result_code(connect_cb)})
	var create_opts := EOS_RAW_SCRIPT.ConnectCreateUserOptions.new()
	create_opts.continuance_token = continuance_token
	var create_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(ieos, "connect_interface_create_user", [create_opts])
	if not bool(create_call.get("ok", false)):
		return create_call
	var create_wait: Dictionary = await EOS_RAW_SCRIPT.await_signal_once(self, ieos, "connect_interface_create_user_callback", 15.0)
	if not bool(create_wait.get("ok", false)):
		return create_wait
	var create_cb: Dictionary = _payload_dict(create_wait)
	if not EOS_RAW_SCRIPT.is_success(create_cb):
		return EOS_RAW_SCRIPT.fail("connect_create_user_failed", "Failed to create connect user.", {"result_code": EOS_RAW_SCRIPT.result_code(create_cb)})
	var created_puid: String = String(create_cb.get("local_user_id", ""))
	if created_puid.strip_edges() == "":
		return EOS_RAW_SCRIPT.fail("connect_user_missing", "Create user callback did not include local_user_id.")
	resolved_display_name = _resolve_display_name(create_cb, resolved_display_name)
	return EOS_RAW_SCRIPT.ok_with({"local_puid": created_puid, "display_name": resolved_display_name})


func _payload_dict(wait_result: Dictionary) -> Dictionary:
	var payload = wait_result.get("payload", {})
	if typeof(payload) != TYPE_DICTIONARY:
		return {}
	return payload


func _resolve_display_name(source: Dictionary, fallback: String = "") -> String:
	for key in ["display_name", "displayname", "account_display_name", "selected_display_name", "nickname"]:
		var value: String = String(source.get(String(key), "")).strip_edges()
		if value != "":
			return value
	var trimmed_fallback: String = String(fallback).strip_edges()
	if trimmed_fallback != "":
		return trimmed_fallback
	return ""


func _is_supported_platform() -> bool:
	return is_supported_platform_name(OS.get_name())


static func is_supported_platform_name(platform_name: String) -> bool:
	return SUPPORTED_RUNTIME_PLATFORMS.has(platform_name)


func _detect_backend_mode_for_policy() -> String:
	if EOS_BACKEND_POLICY_SCRIPT.should_attempt_runtime(backend_policy) and _is_runtime_environment_ready_for_attempt():
		return BACKEND_IEOS
	return BACKEND_MOCK


func _is_headless_runtime() -> bool:
	return DisplayServer.get_name() == "headless"


func _is_runtime_environment_ready_for_attempt() -> bool:
	if _is_headless_runtime():
		return false
	if not _is_supported_platform():
		return false
	return _has_runtime_extension_resource()


func _is_runtime_environment_blocked_reason() -> String:
	if _is_headless_runtime():
		return "headless"
	if not _is_supported_platform():
		return "unsupported_platform"
	if not _has_runtime_extension_resource():
		return "extension_missing"
	return ""


func _has_runtime_extension_resource() -> bool:
	return ResourceLoader.exists(EOS_RAW_SCRIPT.EOSG_EXTENSION_PATH)


func _collect_runtime_env() -> Dictionary:
	return {
		"EOS_PRODUCT_NAME": EOS_RAW_SCRIPT.env_or("EOS_PRODUCT_NAME", "project101"),
		"EOS_PRODUCT_VERSION": EOS_RAW_SCRIPT.env_or("EOS_PRODUCT_VERSION", str(ProjectSettings.get_setting("application/config/version", "0.0.0"))),
		"EOS_PRODUCT_ID": EOS_RAW_SCRIPT.env_or("EOS_PRODUCT_ID", ""),
		"EOS_SANDBOX_ID": EOS_RAW_SCRIPT.env_or("EOS_SANDBOX_ID", ""),
		"EOS_DEPLOYMENT_ID": EOS_RAW_SCRIPT.env_or("EOS_DEPLOYMENT_ID", ""),
		"EOS_CLIENT_ID": EOS_RAW_SCRIPT.env_or("EOS_CLIENT_ID", ""),
		"EOS_CLIENT_SECRET": EOS_RAW_SCRIPT.env_or("EOS_CLIENT_SECRET", ""),
		"EOS_ENCRYPTION_KEY": EOS_RAW_SCRIPT.env_or("EOS_ENCRYPTION_KEY", ""),
		"EOS_DEV_AUTH_HOST": EOS_RAW_SCRIPT.env_or("EOS_DEV_AUTH_HOST", "localhost:4545"),
		"EOS_DEV_AUTH_CREDENTIAL": EOS_RAW_SCRIPT.env_or("EOS_DEV_AUTH_CREDENTIAL", ""),
	}


func _initialize_runtime_backend() -> Dictionary:
	var ensure_ext: Dictionary = EOS_RAW_SCRIPT.ensure_extension_loaded()
	if not bool(ensure_ext.get("ok", false)):
		return ensure_ext
	var required_keys: Array = [
		"EOS_PRODUCT_ID",
		"EOS_SANDBOX_ID",
		"EOS_DEPLOYMENT_ID",
		"EOS_CLIENT_ID",
		"EOS_CLIENT_SECRET",
	]
	var missing: Array = EOS_RAW_SCRIPT.missing_env_keys(required_keys)
	if not missing.is_empty():
		return EOS_RAW_SCRIPT.fail("config_missing", "Missing EOS env config: %s" % ", ".join(missing))
	var ieos = EOS_RAW_SCRIPT.get_ieos()
	if ieos == null:
		return EOS_RAW_SCRIPT.fail("singleton_missing", "IEOS singleton unavailable.")

	var init_opts := EOS_RAW_SCRIPT.PlatformInitializeOptions.new()
	init_opts.product_name = String(_runtime_env.get("EOS_PRODUCT_NAME", "project101"))
	init_opts.product_version = String(_runtime_env.get("EOS_PRODUCT_VERSION", "0.0.0"))
	var init_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(ieos, "platform_interface_initialize", [init_opts])
	if not bool(init_call.get("ok", false)):
		return init_call
	var init_res = init_call.get("result")
	if not EOS_RAW_SCRIPT.is_success(init_res):
		return EOS_RAW_SCRIPT.fail("platform_initialize_failed", "EOS platform initialization failed.", {"result_code": EOS_RAW_SCRIPT.result_code(init_res)})

	var create_opts := EOS_RAW_SCRIPT.PlatformCreateOptions.new()
	create_opts.product_id = String(_runtime_env.get("EOS_PRODUCT_ID", ""))
	create_opts.sandbox_id = String(_runtime_env.get("EOS_SANDBOX_ID", ""))
	create_opts.deployment_id = String(_runtime_env.get("EOS_DEPLOYMENT_ID", ""))
	create_opts.client_id = String(_runtime_env.get("EOS_CLIENT_ID", ""))
	create_opts.client_secret = String(_runtime_env.get("EOS_CLIENT_SECRET", ""))
	create_opts.encryption_key = String(_runtime_env.get("EOS_ENCRYPTION_KEY", ""))
	create_opts.cache_directory = ProjectSettings.globalize_path("user://eosg-cache")
	create_opts.flags = 0
	create_opts.is_server = false
	create_opts.override_country_code = ""
	create_opts.override_locale_code = ""
	create_opts.tick_budget_in_milliseconds = 2
	create_opts.task_network_timeout_seconds = null
	create_opts.rtc_options = EOS_RAW_SCRIPT.PlatformRTCOptions.new()

	var create_call: Dictionary = EOS_RAW_SCRIPT.call_ieos(ieos, "platform_interface_create", [create_opts])
	if not bool(create_call.get("ok", false)):
		return create_call
	var create_res = create_call.get("result")
	if not EOS_RAW_SCRIPT.is_success(create_res):
		return EOS_RAW_SCRIPT.fail("platform_create_failed", "EOS platform create failed.", {"result_code": EOS_RAW_SCRIPT.result_code(create_res)})

	_runtime_initialized = true
	return EOS_RAW_SCRIPT.ok_with({"code": "runtime_ready"})


func _downgrade_to_mock(reason: String) -> void:
	backend_mode = BACKEND_MOCK
	_runtime_initialized = false
	unavailable_reason = reason


func _persist_session_cache() -> void:
	if local_puid.strip_edges() == "":
		_session_cache.clear()
		return
	_session_cache = {
		"local_puid": local_puid,
		"display_name": local_display_name,
		"epic_account_id": _runtime_epic_account_id,
	}
