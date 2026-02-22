extends SceneTree

const ONLINE_SERVICE_SCRIPT: Script = preload("res://net/OnlineServiceEOS.gd")
const LOBBY_SERVICE_SCRIPT: Script = preload("res://net/LobbyServiceEOS.gd")

const LOGIN_TIMEOUT_SEC: float = 20.0
const LOBBY_TIMEOUT_SEC: float = 20.0

var _online_service = null
var _lobby_service = null
var _login_done: bool = false
var _login_ok: bool = false
var _login_reason: String = ""
var _lobby_done: bool = false
var _lobby_ok: bool = false
var _lobby_reason: String = ""

func _init() -> void:
	call_deferred("_run_smoke")

func _run_smoke() -> void:
	_online_service = ONLINE_SERVICE_SCRIPT.new()
	_lobby_service = LOBBY_SERVICE_SCRIPT.new()
	get_root().add_child(_online_service)
	get_root().add_child(_lobby_service)

	_online_service.login_succeeded.connect(func(local_puid: String) -> void:
		_login_done = true
		_login_ok = true
		_login_reason = "login_succeeded:%s" % local_puid
	)
	_online_service.login_failed.connect(func(reason: String) -> void:
		_login_done = true
		_login_ok = false
		_login_reason = reason
	)
	_lobby_service.lobby_updated.connect(func(lobby_model: Dictionary) -> void:
		if not lobby_model.is_empty():
			_lobby_done = true
			_lobby_ok = true
			_lobby_reason = String(lobby_model.get("lobby_id", ""))
	)
	_lobby_service.lobby_error.connect(func(code: String, reason: String) -> void:
		_lobby_done = true
		_lobby_ok = false
		_lobby_reason = "%s:%s" % [code, reason]
	)

	var init_res: Dictionary = _online_service.initialize()
	print("SMOKE init:", init_res)
	if not bool(init_res.get("ok", false)):
		push_error("SMOKE init failed: %s" % str(init_res))
		quit(1)
		return
	if String(init_res.get("backend_mode", "")) != "ieos_raw":
		push_error("SMOKE runtime backend not active. Set PROJECT101_EOS_RUNTIME=1 with full EOS env.")
		quit(1)
		return

	var login_res: Dictionary = _online_service.login_dev_auth("smoke_player")
	print("SMOKE login request:", login_res)
	if not bool(login_res.get("ok", false)):
		push_error("SMOKE login request failed: %s" % str(login_res))
		quit(1)
		return
	if String(login_res.get("code", "")) == "pending":
		await _wait_for_login()
		if not _login_ok:
			push_error("SMOKE login failed: %s" % _login_reason)
			quit(1)
			return

	_lobby_service.set_backend_mode(_online_service.get_backend_mode())
	_lobby_service.set_local_puid(_online_service.local_puid)
	var create_res: Dictionary = _lobby_service.create_lobby({
		"ruleset_id": "tr_101_classic",
		"version": "v1",
		"phase": "FILLING",
		"privacy": "INVITE_ONLY",
	})
	print("SMOKE create lobby request:", create_res)
	if not bool(create_res.get("ok", false)):
		push_error("SMOKE create lobby request failed: %s" % str(create_res))
		quit(1)
		return
	if String(create_res.get("code", "")) == "pending":
		await _wait_for_lobby()
		if not _lobby_ok:
			push_error("SMOKE create lobby failed: %s" % _lobby_reason)
			quit(1)
			return

	print("SMOKE success local_puid=", _online_service.local_puid, " lobby=", _lobby_reason)
	quit(0)

func _wait_for_login() -> void:
	var timer = create_timer(LOGIN_TIMEOUT_SEC)
	while not _login_done and timer.time_left > 0.0:
		await process_frame
	if not _login_done:
		_login_done = true
		_login_ok = false
		_login_reason = "timeout"

func _wait_for_lobby() -> void:
	var timer = create_timer(LOBBY_TIMEOUT_SEC)
	while not _lobby_done and timer.time_left > 0.0:
		await process_frame
	if not _lobby_done:
		_lobby_done = true
		_lobby_ok = false
		_lobby_reason = "timeout"
