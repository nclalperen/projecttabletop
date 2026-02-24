extends SceneTree

const ONLINE_SERVICE_SCRIPT: Script = preload("res://net/OnlineServiceEOS.gd")
const LOBBY_SERVICE_SCRIPT: Script = preload("res://net/LobbyServiceEOS.gd")
const BACKEND_POLICY_SCRIPT: Script = preload("res://net/EOSBackendPolicy.gd")
const PROTOCOL_SCRIPT: Script = preload("res://net/Protocol.gd")

const LOGIN_TIMEOUT_SEC: float = 30.0
const LOBBY_TIMEOUT_SEC: float = 30.0

var _original_policy_env: String = ""
var _host_online = null
var _client_online = null
var _host_lobby = null
var _client_lobby = null


func _init() -> void:
	call_deferred("_run_runtime_lane")


func _run_runtime_lane() -> void:
	if DisplayServer.get_name().to_lower().find("headless") != -1:
		push_error("RUNTIME LANE requires non-headless run. Use: ./tools/godot.cmd --path . -s res://tests/run_tests_runtime_eos.gd")
		quit(1)
		return

	_original_policy_env = OS.get_environment("PROJECT101_EOS_BACKEND_POLICY")
	if _original_policy_env.strip_edges() == "":
		OS.set_environment("PROJECT101_EOS_BACKEND_POLICY", BACKEND_POLICY_SCRIPT.POLICY_RUNTIME_PREFERRED)

	_host_online = ONLINE_SERVICE_SCRIPT.new()
	_client_online = ONLINE_SERVICE_SCRIPT.new()
	_host_lobby = LOBBY_SERVICE_SCRIPT.new()
	_client_lobby = LOBBY_SERVICE_SCRIPT.new()
	get_root().add_child(_host_online)
	get_root().add_child(_client_online)
	get_root().add_child(_host_lobby)
	get_root().add_child(_client_lobby)

	var host_init: Dictionary = _host_online.initialize()
	if not _require_runtime_init(host_init, "host"):
		_cleanup_and_quit(1)
		return
	var client_init: Dictionary = _client_online.initialize()
	if not _require_runtime_init(client_init, "client"):
		_cleanup_and_quit(1)
		return

	var host_credential: String = String(OS.get_environment("EOS_DEV_AUTH_CREDENTIAL_HOST")).strip_edges()
	if host_credential == "":
		host_credential = String(OS.get_environment("EOS_DEV_AUTH_CREDENTIAL")).strip_edges()
	if host_credential == "":
		host_credential = "dev_host"

	var client_credential: String = String(OS.get_environment("EOS_DEV_AUTH_CREDENTIAL_CLIENT")).strip_edges()
	if client_credential == "":
		client_credential = "dev_client"

	var host_login: Dictionary = await _login_runtime_dev_auth(_host_online, host_credential)
	if not bool(host_login.get("ok", false)):
		push_error("RUNTIME LANE host login failed: %s" % str(host_login))
		_cleanup_and_quit(1)
		return
	var client_login: Dictionary = await _login_runtime_dev_auth(_client_online, client_credential)
	if not bool(client_login.get("ok", false)):
		push_error("RUNTIME LANE client login failed: %s" % str(client_login))
		_cleanup_and_quit(1)
		return

	var host_puid: String = String(host_login.get("local_puid", ""))
	var client_puid: String = String(client_login.get("local_puid", ""))
	if host_puid == "" or client_puid == "":
		push_error("RUNTIME LANE missing PUIDs after login")
		_cleanup_and_quit(1)
		return

	_configure_lobby_service(_host_lobby, _host_online)
	_configure_lobby_service(_client_lobby, _client_online)

	var create_res: Dictionary = _host_lobby.create_lobby({
		"ruleset_id": "tr_101_classic",
		"version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"phase": "FILLING",
		"privacy": "INVITE_ONLY",
		"protocol_rev": int(PROTOCOL_SCRIPT.PROTOCOL_VERSION),
		"build_family": BACKEND_POLICY_SCRIPT.build_family(),
	})
	if not bool(create_res.get("ok", false)):
		push_error("RUNTIME LANE host create_lobby failed: %s" % str(create_res))
		_cleanup_and_quit(1)
		return

	var host_lobby_wait: Dictionary = await _wait_for_lobby_members(_host_lobby, 1, LOBBY_TIMEOUT_SEC)
	if not bool(host_lobby_wait.get("ok", false)):
		push_error("RUNTIME LANE host lobby did not materialize: %s" % str(host_lobby_wait))
		_cleanup_and_quit(1)
		return
	var host_lobby_model: Dictionary = _host_lobby.get_current_lobby()
	var lobby_id: String = String(host_lobby_model.get("lobby_id", ""))
	if lobby_id == "":
		push_error("RUNTIME LANE host lobby_id missing")
		_cleanup_and_quit(1)
		return

	var join_res: Dictionary = _client_lobby.join_lobby(lobby_id)
	if not bool(join_res.get("ok", false)):
		push_error("RUNTIME LANE client join_lobby failed: %s" % str(join_res))
		_cleanup_and_quit(1)
		return

	var host_two_members: Dictionary = await _wait_for_lobby_members(_host_lobby, 2, LOBBY_TIMEOUT_SEC)
	if not bool(host_two_members.get("ok", false)):
		push_error("RUNTIME LANE host never observed 2 lobby members: %s" % str(host_two_members))
		_cleanup_and_quit(1)
		return
	var client_two_members: Dictionary = await _wait_for_lobby_members(_client_lobby, 2, LOBBY_TIMEOUT_SEC)
	if not bool(client_two_members.get("ok", false)):
		push_error("RUNTIME LANE client never observed 2 lobby members: %s" % str(client_two_members))
		_cleanup_and_quit(1)
		return

	var host_ready: Dictionary = _host_lobby.set_ready(true)
	var client_ready: Dictionary = _client_lobby.set_ready(true)
	if not bool(host_ready.get("ok", false)) or not bool(client_ready.get("ok", false)):
		push_error("RUNTIME LANE set_ready failed host=%s client=%s" % [str(host_ready), str(client_ready)])
		_cleanup_and_quit(1)
		return

	var all_ready: Dictionary = await _wait_for_all_members_ready(_host_lobby, LOBBY_TIMEOUT_SEC)
	if not bool(all_ready.get("ok", false)):
		push_error("RUNTIME LANE all-ready state did not converge: %s" % str(all_ready))
		_cleanup_and_quit(1)
		return

	var match_id: String = "RUNTIME_%08x" % int(Time.get_unix_time_from_system())
	var set_phase_res: Dictionary = _host_lobby.set_lobby_attr("phase", "MATCH_STARTING")
	var set_match_res: Dictionary = _host_lobby.set_lobby_attr("match_id", match_id)
	if not bool(set_phase_res.get("ok", false)) or not bool(set_match_res.get("ok", false)):
		push_error("RUNTIME LANE failed to publish start attrs phase=%s match=%s" % [str(set_phase_res), str(set_match_res)])
		_cleanup_and_quit(1)
		return

	var phase_wait: Dictionary = await _wait_for_lobby_attr(_host_lobby, "phase", "MATCH_STARTING", LOBBY_TIMEOUT_SEC)
	if not bool(phase_wait.get("ok", false)):
		push_error("RUNTIME LANE phase attr did not converge: %s" % str(phase_wait))
		_cleanup_and_quit(1)
		return

	print("RUNTIME_EOS_LANE: PASS")
	print("host_puid=", host_puid, " client_puid=", client_puid, " lobby_id=", lobby_id, " match_id=", match_id)
	_cleanup_and_quit(0)


func _require_runtime_init(init_res: Dictionary, label: String) -> bool:
	if not bool(init_res.get("ok", false)):
		push_error("RUNTIME LANE %s initialize failed: %s" % [label, str(init_res)])
		return false
	if String(init_res.get("backend_mode", "")) != "ieos_raw":
		push_error("RUNTIME LANE %s backend is not runtime ieos_raw: %s" % [label, str(init_res)])
		return false
	return true


func _configure_lobby_service(lobby_service: LobbyServiceEOS, online_service: OnlineServiceEOS) -> void:
	lobby_service.set_backend_mode(online_service.get_backend_mode())
	if lobby_service.has_method("set_backend_policy"):
		lobby_service.set_backend_policy(online_service.get_backend_policy())
	lobby_service.set_local_puid(String(online_service.local_puid))
	if lobby_service.has_method("set_runtime_profile"):
		lobby_service.set_runtime_profile({
			"display_name": online_service.get_local_display_name(),
			"build_family": BACKEND_POLICY_SCRIPT.build_family(),
			"protocol_rev": int(PROTOCOL_SCRIPT.PROTOCOL_VERSION),
		})


func _login_runtime_dev_auth(service: OnlineServiceEOS, credential_name: String) -> Dictionary:
	var login_res: Dictionary = service.login_dev_auth(credential_name)
	if not bool(login_res.get("ok", false)):
		return login_res
	if String(login_res.get("code", "")) != "pending":
		return login_res

	var state := {
		"done": false,
		"ok": false,
		"reason": "",
		"local_puid": "",
	}
	service.login_succeeded.connect(func(local_puid: String) -> void:
		state["done"] = true
		state["ok"] = true
		state["local_puid"] = local_puid
	, CONNECT_ONE_SHOT)
	service.login_failed.connect(func(reason: String) -> void:
		state["done"] = true
		state["ok"] = false
		state["reason"] = reason
	, CONNECT_ONE_SHOT)

	var timer = create_timer(LOGIN_TIMEOUT_SEC)
	while not bool(state.get("done", false)) and timer.time_left > 0.0:
		await process_frame
	if not bool(state.get("done", false)):
		return {
			"ok": false,
			"code": "timeout",
			"reason": "login timeout",
		}
	if not bool(state.get("ok", false)):
		return {
			"ok": false,
			"code": "login_failed",
			"reason": String(state.get("reason", "unknown")),
		}
	return {
		"ok": true,
		"code": "ok",
		"reason": "",
		"local_puid": String(state.get("local_puid", "")),
	}


func _wait_for_lobby_members(service: LobbyServiceEOS, count: int, timeout_sec: float) -> Dictionary:
	var timer = create_timer(timeout_sec)
	while timer.time_left > 0.0:
		var lobby: Dictionary = service.get_current_lobby()
		if not lobby.is_empty() and int(lobby.get("members", []).size()) >= count:
			return {"ok": true, "code": "ok", "reason": "", "lobby": lobby}
		await process_frame
	return {"ok": false, "code": "timeout", "reason": "lobby member wait timeout"}


func _wait_for_all_members_ready(service: LobbyServiceEOS, timeout_sec: float) -> Dictionary:
	var timer = create_timer(timeout_sec)
	while timer.time_left > 0.0:
		var lobby: Dictionary = service.get_current_lobby()
		if not lobby.is_empty():
			var all_ready: bool = true
			for member in lobby.get("members", []):
				if not bool(member.get("attrs", {}).get("ready", false)):
					all_ready = false
					break
			if all_ready:
				return {"ok": true, "code": "ok", "reason": "", "lobby": lobby}
		await process_frame
	return {"ok": false, "code": "timeout", "reason": "ready convergence timeout"}


func _wait_for_lobby_attr(service: LobbyServiceEOS, key: String, expected_value, timeout_sec: float) -> Dictionary:
	var timer = create_timer(timeout_sec)
	while timer.time_left > 0.0:
		var lobby: Dictionary = service.get_current_lobby()
		if not lobby.is_empty() and lobby.get("attrs", {}).get(key) == expected_value:
			return {"ok": true, "code": "ok", "reason": "", "lobby": lobby}
		await process_frame
	return {"ok": false, "code": "timeout", "reason": "attr wait timeout", "key": key}


func _cleanup_and_quit(exit_code: int) -> void:
	if _host_lobby != null:
		_host_lobby.leave_lobby()
	if _client_lobby != null:
		_client_lobby.leave_lobby()
	if _host_online != null:
		_host_online.logout()
	if _client_online != null:
		_client_online.logout()
	if _host_lobby != null:
		_host_lobby.free()
	if _client_lobby != null:
		_client_lobby.free()
	if _host_online != null:
		_host_online.free()
	if _client_online != null:
		_client_online.free()
	if _original_policy_env != "":
		OS.set_environment("PROJECT101_EOS_BACKEND_POLICY", _original_policy_env)
	quit(exit_code)
