extends Control

const GAME_TABLE_2D_SCENE: PackedScene = preload("res://ui/GameTable.tscn")
const GAME_TABLE_3D_SCENE: PackedScene = preload("res://ui/GameTable3D.tscn")
const ONLINE_SERVICE_SCRIPT: Script = preload("res://net/OnlineServiceEOS.gd")
const LOBBY_SERVICE_SCRIPT: Script = preload("res://net/LobbyServiceEOS.gd")
const P2P_TRANSPORT_SCRIPT: Script = preload("res://net/P2PTransportEOS.gd")
const HOST_MATCH_CONTROLLER_SCRIPT: Script = preload("res://net/HostMatchController.gd")
const CLIENT_MATCH_CONTROLLER_SCRIPT: Script = preload("res://net/ClientMatchController.gd")

@onready var _status_label: Label = $Margin/VBox/Status
@onready var _roster: ItemList = $Margin/VBox/Roster
@onready var _login_btn: Button = $Margin/VBox/Buttons/LoginBtn
@onready var _quick_btn: Button = $Margin/VBox/Buttons/QuickBtn
@onready var _private_btn: Button = $Margin/VBox/Buttons/PrivateBtn
@onready var _ready_btn: Button = $Margin/VBox/Buttons/ReadyBtn
@onready var _start_btn: Button = $Margin/VBox/Buttons/StartBtn
@onready var _back_btn: Button = $Margin/VBox/Buttons/BackBtn

var _online_service = null
var _lobby_service = null
var _rule_config: RuleConfig = RuleConfig.new()
var _game_seed: int = -1
var _player_count: int = 4
var _presentation_mode: String = "3d"

var _quick_match_pending: bool = false
var _start_attr_queue: Array = []
var _launch_started: bool = false
var _active_host_controller = null
var _last_member_connected: Dictionary = {}

func set_start_config(rule_config: RuleConfig, game_seed: int, player_count: int, presentation_mode: String) -> void:
	_rule_config = rule_config
	_game_seed = game_seed
	_player_count = player_count
	_presentation_mode = presentation_mode

func _ready() -> void:
	_online_service = ONLINE_SERVICE_SCRIPT.new()
	_lobby_service = LOBBY_SERVICE_SCRIPT.new()
	add_child(_online_service)
	add_child(_lobby_service)

	_online_service.availability_changed.connect(_on_online_availability_changed)
	_online_service.login_succeeded.connect(_on_login_succeeded)
	_online_service.login_failed.connect(_on_login_failed)
	_lobby_service.lobby_updated.connect(_on_lobby_updated)
	_lobby_service.lobby_list_updated.connect(_on_lobby_list_updated)
	_lobby_service.lobby_error.connect(func(code: String, reason: String) -> void:
		_status_label.text = "Lobby error (%s): %s" % [code, reason]
	)

	_login_btn.pressed.connect(_on_login_pressed)
	_quick_btn.pressed.connect(_on_quick_match_pressed)
	_private_btn.pressed.connect(_on_private_lobby_pressed)
	_ready_btn.pressed.connect(_on_ready_pressed)
	_start_btn.pressed.connect(_on_start_pressed)
	_back_btn.pressed.connect(_on_back_pressed)

	var init_res: Dictionary = _online_service.initialize()
	if _lobby_service.has_method("set_backend_mode"):
		_lobby_service.call("set_backend_mode", _online_service.get_backend_mode())
	if not bool(init_res.get("ok", false)):
		_status_label.text = String(init_res.get("reason", "Online unavailable"))
	else:
		var mode: String = String(init_res.get("backend_mode", "mock"))
		_status_label.text = "Online ready (%s backend)." % mode
	_refresh_button_states()

func _on_online_availability_changed(available: bool, reason: String) -> void:
	if not available:
		_status_label.text = reason
	else:
		var mode: String = _online_service.get_backend_mode()
		_status_label.text = "Online ready (%s backend). Sign in to continue." % mode
	_refresh_button_states()

func _on_login_pressed() -> void:
	if not _online_service.is_available():
		_status_label.text = _online_service.get_unavailable_reason()
		return
	var login_res: Dictionary = _online_service.login_dev_auth("dev_player")
	if not bool(login_res.get("ok", false)):
		_status_label.text = String(login_res.get("reason", "Login failed"))
		return
	if String(login_res.get("code", "")) == "pending":
		_status_label.text = "Signing in via EOS Dev Auth..."
		return
	_status_label.text = "Logged in as %s (%s)." % [String(login_res.get("local_puid", "")), String(login_res.get("backend_mode", _online_service.get_backend_mode()))]

func _on_login_succeeded(local_puid: String) -> void:
	_lobby_service.set_local_puid(local_puid)
	_status_label.text = "Signed in: %s" % local_puid
	_refresh_button_states()

func _on_login_failed(reason: String) -> void:
	_status_label.text = reason
	_refresh_button_states()

func _on_quick_match_pressed() -> void:
	if _online_service.local_puid == "":
		_status_label.text = "Sign in first."
		return
	_quick_match_pending = true
	var search: Dictionary = _lobby_service.search_lobbies({
		"ruleset_id": _rule_config.ruleset_name,
		"version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"phase": "FILLING",
		"open_slots": 1,
	})
	if not bool(search.get("ok", false)):
		_quick_match_pending = false
		_status_label.text = String(search.get("reason", "Quick match search failed"))
		return
	if String(search.get("code", "")) == "pending":
		_status_label.text = "Searching lobbies..."
		return
	_handle_quick_search_result(search.get("lobbies", []))

func _on_private_lobby_pressed() -> void:
	if _online_service.local_puid == "":
		_status_label.text = "Sign in first."
		return
	var create_res: Dictionary = _lobby_service.create_lobby({
		"ruleset_id": _rule_config.ruleset_name,
		"version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"phase": "FILLING",
		"privacy": "INVITE_ONLY",
	})
	if not bool(create_res.get("ok", false)):
		_status_label.text = String(create_res.get("reason", "Failed to create lobby"))
		return
	_status_label.text = "Creating private lobby..." if String(create_res.get("code", "")) == "pending" else "Created private lobby."

func _on_ready_pressed() -> void:
	var lobby: Dictionary = _lobby_service.get_current_lobby()
	if lobby.is_empty():
		_status_label.text = "Join or create a lobby first."
		return
	var ready_now: bool = _current_member_ready(lobby)
	var res: Dictionary = _lobby_service.set_ready(not ready_now)
	if not bool(res.get("ok", false)):
		_status_label.text = String(res.get("reason", "Failed to update ready"))
		return
	_status_label.text = "Updating ready..." if String(res.get("code", "")) == "pending" else "Ready updated."

func _on_start_pressed() -> void:
	var lobby: Dictionary = _lobby_service.get_current_lobby()
	if lobby.is_empty():
		_status_label.text = "No active lobby."
		return
	if not _is_local_host(lobby):
		_status_label.text = "Only lobby creator can start."
		return
	if int(lobby.get("members", []).size()) != _player_count:
		_status_label.text = "Need %d players to start." % _player_count
		return
	if not _all_members_ready(lobby):
		_status_label.text = "All players must be ready."
		return
	if _launch_started:
		return
	_start_attr_queue.clear()
	var seat_by_puid: Dictionary = _extract_or_build_seat_map(lobby)
	var match_seed: int = _game_seed if _game_seed >= 0 else randi()
	var match_id: String = String(lobby.get("attrs", {}).get("match_id", ""))
	if match_id == "":
		match_id = "M_%08x" % int(abs(hash("%s|%s" % [_online_service.local_puid, Time.get_unix_time_from_system()])))
	var seat_json: String = JSON.stringify(seat_by_puid)
	_start_attr_queue.append({"key": "host_puid", "value": _online_service.local_puid})
	_start_attr_queue.append({"key": "match_id", "value": match_id})
	_start_attr_queue.append({"key": "match_seed", "value": match_seed})
	_start_attr_queue.append({"key": "seat_map_json", "value": seat_json})
	_start_attr_queue.append({"key": "phase", "value": "MATCH_STARTING"})
	_status_label.text = "Publishing match start..."
	_drain_host_start_attr_queue()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/Main.tscn")

func _on_lobby_list_updated(lobbies: Array) -> void:
	if _quick_match_pending:
		_handle_quick_search_result(lobbies)

func _handle_quick_search_result(lobbies: Array) -> void:
	_quick_match_pending = false
	if not lobbies.is_empty():
		var lobby_id: String = String(lobbies[0].get("lobby_id", ""))
		if lobby_id == "":
			_status_label.text = "Search returned invalid lobby id."
			return
		var join_res: Dictionary = _lobby_service.join_lobby(lobby_id)
		if not bool(join_res.get("ok", false)):
			_status_label.text = String(join_res.get("reason", "Failed to join lobby"))
			return
		_status_label.text = "Joining lobby %s..." % lobby_id if String(join_res.get("code", "")) == "pending" else "Joined lobby %s" % lobby_id
		return

	var create_res: Dictionary = _lobby_service.create_lobby({
		"ruleset_id": _rule_config.ruleset_name,
		"version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"phase": "FILLING",
		"privacy": "PUBLIC",
	})
	if not bool(create_res.get("ok", false)):
		_status_label.text = String(create_res.get("reason", "Failed to create lobby"))
		return
	_status_label.text = "Creating public lobby..." if String(create_res.get("code", "")) == "pending" else "Created public lobby."

func _on_lobby_updated(lobby_model: Dictionary) -> void:
	_roster.clear()
	if lobby_model.is_empty():
		_last_member_connected.clear()
		_refresh_button_states()
		return
	for member in lobby_model.get("members", []):
		var puid: String = String(member.get("puid", ""))
		var attrs: Dictionary = member.get("attrs", {})
		var seat: int = int(attrs.get("seat", -1))
		var ready: bool = bool(attrs.get("ready", false))
		var status: String = String(attrs.get("status", "OK"))
		_roster.add_item("seat %d | %s | ready=%s | %s" % [seat, puid, "yes" if ready else "no", status])

	if not _start_attr_queue.is_empty() and _is_local_host(lobby_model):
		while not _start_attr_queue.is_empty():
			var head: Dictionary = _start_attr_queue[0]
			var key: String = String(head.get("key", ""))
			if key == "":
				_start_attr_queue.remove_at(0)
				continue
			if String(lobby_model.get("attrs", {}).get(key, "")) == String(head.get("value", "")):
				_start_attr_queue.remove_at(0)
				continue
			break
		if not _start_attr_queue.is_empty():
			call_deferred("_drain_host_start_attr_queue")

	_bridge_member_presence_to_host(lobby_model)
	_maybe_launch_match_from_lobby(lobby_model)
	_refresh_button_states()

func _drain_host_start_attr_queue() -> void:
	if _start_attr_queue.is_empty():
		return
	if _launch_started:
		return
	var lobby: Dictionary = _lobby_service.get_current_lobby()
	if lobby.is_empty():
		return
	var head: Dictionary = _start_attr_queue[0]
	var key: String = String(head.get("key", ""))
	var value = head.get("value")
	var set_res: Dictionary = _lobby_service.set_lobby_attr(key, value)
	if not bool(set_res.get("ok", false)):
		_start_attr_queue.clear()
		_status_label.text = String(set_res.get("reason", "Failed to update lobby attrs"))
		return
	if String(set_res.get("code", "")) == "pending":
		_status_label.text = "Updating lobby: %s..." % key
		return
	_start_attr_queue.remove_at(0)
	call_deferred("_drain_host_start_attr_queue")

func _maybe_launch_match_from_lobby(lobby: Dictionary) -> void:
	if _launch_started:
		return
	var attrs: Dictionary = lobby.get("attrs", {})
	if String(attrs.get("phase", "")) != "MATCH_STARTING":
		return
	var seat_by_puid: Dictionary = _extract_or_build_seat_map(lobby)
	if not seat_by_puid.has(_online_service.local_puid):
		_status_label.text = "Seat map missing local player."
		return
	var host_puid: String = String(attrs.get("host_puid", lobby.get("owner_puid", "")))
	if host_puid == "":
		_status_label.text = "Match start missing host."
		return
	var match_seed: int = int(attrs.get("match_seed", _game_seed if _game_seed >= 0 else randi()))
	var match_id: String = String(attrs.get("match_id", ""))

	var scene: PackedScene = GAME_TABLE_3D_SCENE if _presentation_mode == "3d" else GAME_TABLE_2D_SCENE
	var game_table: Node = scene.instantiate()
	var transport = P2P_TRANSPORT_SCRIPT.new()
	if transport.has_method("set_backend_mode"):
		transport.call("set_backend_mode", _online_service.get_backend_mode())
	if transport.has_method("set_runtime_context"):
		transport.call("set_runtime_context", String(lobby.get("lobby_id", "")), String(attrs.get("rtc_room_name", "")))

	var controller = null
	if _online_service.local_puid == host_puid:
		controller = HOST_MATCH_CONTROLLER_SCRIPT.new()
		controller.configure_host(_online_service.local_puid, transport, seat_by_puid, match_id, match_seed)
		controller.start_new_match(_rule_config, match_seed, _player_count)
		_active_host_controller = controller
		_sync_member_presence_baseline(lobby)
	else:
		controller = CLIENT_MATCH_CONTROLLER_SCRIPT.new()
		controller.configure_client(_online_service.local_puid, host_puid, transport, int(seat_by_puid.get(_online_service.local_puid, 0)), match_id)
		_active_host_controller = null

	game_table.add_child(transport)
	game_table.add_child(controller)
	if game_table.has_method("inject_controller"):
		game_table.call("inject_controller", controller)
	if game_table.has_method("configure_game"):
		game_table.call("configure_game", _rule_config, match_seed, _player_count)

	_launch_started = true
	get_tree().root.add_child(game_table)
	queue_free()

func _bridge_member_presence_to_host(lobby: Dictionary) -> void:
	if _active_host_controller == null:
		return
	if not _active_host_controller.has_method("mark_peer_disconnected"):
		return
	var current_connected: Dictionary = {}
	for member in lobby.get("members", []):
		var puid: String = String(member.get("puid", ""))
		if puid == "" or puid == _online_service.local_puid:
			continue
		var status: String = String(member.get("attrs", {}).get("status", "OK")).to_upper()
		var connected: bool = not (status == "DISCONNECTED" or status == "LEFT" or status == "CLOSED" or status == "KICKED" or status == "BOT_ACTIVE")
		current_connected[puid] = connected
		var was_connected: bool = bool(_last_member_connected.get(puid, true))
		if was_connected and not connected:
			_active_host_controller.call("mark_peer_disconnected", puid)
		elif not was_connected and connected:
			_active_host_controller.call("mark_peer_reconnected", puid)
	_last_member_connected = current_connected

func _sync_member_presence_baseline(lobby: Dictionary) -> void:
	_last_member_connected.clear()
	for member in lobby.get("members", []):
		var puid: String = String(member.get("puid", ""))
		if puid == "" or puid == _online_service.local_puid:
			continue
		var status: String = String(member.get("attrs", {}).get("status", "OK")).to_upper()
		_last_member_connected[puid] = not (status == "DISCONNECTED" or status == "LEFT" or status == "CLOSED" or status == "KICKED" or status == "BOT_ACTIVE")

func _extract_or_build_seat_map(lobby: Dictionary) -> Dictionary:
	var attrs: Dictionary = lobby.get("attrs", {})
	var seat_map_json: String = String(attrs.get("seat_map_json", ""))
	if seat_map_json.strip_edges() != "":
		var parsed = JSON.parse_string(seat_map_json)
		if typeof(parsed) == TYPE_DICTIONARY:
			var out: Dictionary = {}
			for key in (parsed as Dictionary).keys():
				out[String(key)] = int((parsed as Dictionary)[key])
			if not out.is_empty():
				return out
	var out_map: Dictionary = {}
	for member in lobby.get("members", []):
		var puid: String = String(member.get("puid", ""))
		if puid == "":
			continue
		out_map[puid] = int(member.get("attrs", {}).get("seat", out_map.size()))
	return out_map

func _refresh_button_states() -> void:
	var online_ok: bool = _online_service != null and _online_service.is_available()
	var logged_in: bool = online_ok and _online_service.local_puid != ""
	var lobby: Dictionary = _lobby_service.get_current_lobby() if _lobby_service != null else {}
	var in_lobby: bool = not lobby.is_empty()
	var local_host: bool = in_lobby and _is_local_host(lobby)
	_login_btn.disabled = not online_ok
	_quick_btn.disabled = not logged_in
	_private_btn.disabled = not logged_in
	_ready_btn.disabled = not in_lobby
	_start_btn.disabled = not (in_lobby and local_host)

func _is_local_host(lobby: Dictionary) -> bool:
	return String(lobby.get("owner_puid", "")) == _online_service.local_puid

func _all_members_ready(lobby: Dictionary) -> bool:
	for member in lobby.get("members", []):
		if not bool(member.get("attrs", {}).get("ready", false)):
			return false
	return true

func _current_member_ready(lobby: Dictionary) -> bool:
	for member in lobby.get("members", []):
		if String(member.get("puid", "")) == _online_service.local_puid:
			return bool(member.get("attrs", {}).get("ready", false))
	return false
