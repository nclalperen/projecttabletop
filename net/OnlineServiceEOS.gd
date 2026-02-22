extends Node
class_name OnlineServiceEOS

signal availability_changed(available, reason)
signal login_succeeded(local_puid)
signal login_failed(reason)
signal logged_out()

const EOS_RAW_SCRIPT: Script = preload("res://net/eos/EOSRaw.gd")
const BACKEND_MOCK: String = "mock"
const BACKEND_IEOS: String = "ieos_raw"
const RUNTIME_ENABLE_ENV: String = "PROJECT101_EOS_RUNTIME"

var initialized: bool = false
var available: bool = false
var unavailable_reason: String = ""
var local_puid: String = ""
var backend_mode: String = BACKEND_MOCK
var backend_details: Dictionary = {}
var _runtime_initialized: bool = false
var _runtime_login_inflight: bool = false
var _runtime_env: Dictionary = {}
var _runtime_epic_account_id: String = ""

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
	_runtime_epic_account_id = ""
	_runtime_env = _collect_runtime_env()
	backend_mode = _detect_backend_mode()
	backend_details = {
		"os": OS.get_name(),
		"headless": _is_headless_runtime(),
		"runtime_requested": _wants_runtime_backend(),
		"has_ieos": Engine.has_singleton("IEOS"),
		"has_eos_singleton": Engine.has_singleton("EOS"),
		"has_eosg_singleton": Engine.has_singleton("EOSG"),
		"has_eosg_extension_resource": _has_runtime_extension_resource(),
		"backend_mode": backend_mode,
	}

	if not _is_supported_platform():
		available = false
		unavailable_reason = "Online EOS is supported on Windows desktop in v1."
	else:
		available = true
		unavailable_reason = ""
		if backend_mode == BACKEND_IEOS:
			var runtime_init: Dictionary = _initialize_runtime_backend()
			if not bool(runtime_init.get("ok", false)):
				_downgrade_to_mock("EOS runtime unavailable (%s): %s" % [String(runtime_init.get("code", "init_failed")), String(runtime_init.get("reason", ""))])
			else:
				unavailable_reason = ""
		elif _wants_runtime_backend():
			_downgrade_to_mock("EOS runtime requested but not available in this environment.")
		else:
			unavailable_reason = "Using mock backend."
	backend_details["backend_mode"] = backend_mode
	backend_details["runtime_initialized"] = _runtime_initialized

	emit_signal("availability_changed", available, unavailable_reason)
	return {
		"ok": available,
		"code": "ok" if available else "unavailable",
		"reason": unavailable_reason,
		"backend_mode": backend_mode,
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

func get_backend_details() -> Dictionary:
	if not initialized:
		initialize()
	return backend_details.duplicate(true)

func login_dev_auth(display_name: String = "dev_player") -> Dictionary:
	if not is_available():
		emit_signal("login_failed", unavailable_reason)
		return {"ok": false, "code": "unavailable", "reason": unavailable_reason}
	if local_puid != "":
		return {"ok": true, "code": "ok", "reason": "", "local_puid": local_puid, "backend_mode": backend_mode}
	if backend_mode == BACKEND_IEOS:
		if not _runtime_initialized:
			_downgrade_to_mock("EOS runtime not initialized. Falling back to mock backend.")
			return login_dev_auth(display_name)
		if _runtime_login_inflight:
			return {"ok": true, "code": "pending", "reason": "login_in_progress", "backend_mode": backend_mode}
		_runtime_login_inflight = true
		var credential_name: String = String(_runtime_env.get("EOS_DEV_AUTH_CREDENTIAL", "")).strip_edges()
		if credential_name == "":
			credential_name = display_name
		call_deferred("_runtime_login_dev_auth_async", display_name, credential_name)
		return {"ok": true, "code": "pending", "reason": "runtime_login_started", "backend_mode": backend_mode}

	# Mock identity fallback path.
	var seed_src: String = "%s|%s|%s" % [display_name, OS.get_unique_id(), Time.get_unix_time_from_system()]
	local_puid = "PUID_%08x" % int(abs(hash(seed_src)))
	emit_signal("login_succeeded", local_puid)
	return {
		"ok": true,
		"code": "ok",
		"reason": "",
		"local_puid": local_puid,
		"backend_mode": backend_mode,
	}

func logout() -> void:
	if local_puid == "":
		return
	_runtime_login_inflight = false
	_runtime_epic_account_id = ""
	local_puid = ""
	emit_signal("logged_out")

func get_unavailable_reason() -> String:
	if not initialized:
		initialize()
	return unavailable_reason

func _is_supported_platform() -> bool:
	return OS.get_name() == "Windows"

func _detect_backend_mode() -> String:
	if _is_runtime_supported_environment():
		return BACKEND_IEOS
	return BACKEND_MOCK

func _is_headless_runtime() -> bool:
	return DisplayServer.get_name() == "headless"

func _wants_runtime_backend() -> bool:
	return EOS_RAW_SCRIPT.bool_env_enabled(RUNTIME_ENABLE_ENV, false)

func _is_runtime_supported_environment() -> bool:
	if not _wants_runtime_backend():
		return false
	if _is_headless_runtime():
		return false
	if not _is_supported_platform():
		return false
	return _has_runtime_extension_resource()

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

func _runtime_login_dev_auth_async(display_name: String, credential_name: String) -> void:
	var runtime_result: Dictionary = await _runtime_login_dev_auth_flow(display_name, credential_name)
	_runtime_login_inflight = false
	if not bool(runtime_result.get("ok", false)):
		var reason: String = String(runtime_result.get("reason", "Runtime login failed."))
		_downgrade_to_mock("Runtime login failed (%s): %s" % [String(runtime_result.get("code", "login_failed")), reason])
		emit_signal("login_failed", reason)
		return
	local_puid = String(runtime_result.get("local_puid", ""))
	if local_puid == "":
		_downgrade_to_mock("Runtime login returned empty product user id. Falling back to mock backend.")
		emit_signal("login_failed", "Runtime login did not return a product user id.")
		return
	emit_signal("login_succeeded", local_puid)

func _runtime_login_dev_auth_flow(_display_name: String, credential_name: String) -> Dictionary:
	if not _runtime_initialized:
		return EOS_RAW_SCRIPT.fail("runtime_not_initialized", "Runtime backend is not initialized.")
	var ieos = EOS_RAW_SCRIPT.get_ieos()
	if ieos == null:
		return EOS_RAW_SCRIPT.fail("singleton_missing", "IEOS singleton unavailable.")

	var auth_creds := EOS_RAW_SCRIPT.AuthCredentials.new()
	auth_creds.type = EOS_RAW_SCRIPT.AUTH_LOGIN_CREDENTIAL_DEVELOPER
	auth_creds.id = String(_runtime_env.get("EOS_DEV_AUTH_HOST", "localhost:4545"))
	auth_creds.token = credential_name
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
		return EOS_RAW_SCRIPT.ok_with({"local_puid": local_user})

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
	return EOS_RAW_SCRIPT.ok_with({"local_puid": created_puid})

func _payload_dict(wait_result: Dictionary) -> Dictionary:
	var payload = wait_result.get("payload", {})
	if typeof(payload) != TYPE_DICTIONARY:
		return {}
	return payload

func _downgrade_to_mock(reason: String) -> void:
	backend_mode = BACKEND_MOCK
	_runtime_initialized = false
	unavailable_reason = reason
