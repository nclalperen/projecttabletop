extends RefCounted

const ONLINE_SERVICE_SCRIPT: Script = preload("res://net/OnlineServiceEOS.gd")
const LOBBY_SERVICE_SCRIPT: Script = preload("res://net/LobbyServiceEOS.gd")
const TRANSPORT_SCRIPT: Script = preload("res://net/P2PTransportEOS.gd")
const HOST_MATCH_SCRIPT: Script = preload("res://net/HostMatchController.gd")

func run() -> bool:
	return _test_mock_online_lobby_flow()

func _test_mock_online_lobby_flow() -> bool:
	var original_runtime_env: String = OS.get_environment("PROJECT101_EOS_RUNTIME")
	OS.set_environment("PROJECT101_EOS_RUNTIME", "0")

	LOBBY_SERVICE_SCRIPT.clear_mock_lobbies()
	TRANSPORT_SCRIPT.clear_mock_registry()

	var online_services: Array = []
	var lobby_services: Array = []
	var puids: Array = []
	var match_id: String = "M_ONLINE_FLOW"
	var match_seed: int = 777001
	var ok: bool = true

	for i in range(4):
		var service = ONLINE_SERVICE_SCRIPT.new()
		online_services.append(service)
		var init_res: Dictionary = service.initialize()
		if not bool(init_res.get("ok", false)):
			push_error("OnlineService initialize failed for player %d: %s" % [i, str(init_res)])
			ok = false
			break
		if service.get_backend_mode() != "mock":
			push_error("Expected mock backend for player %d, got %s" % [i, service.get_backend_mode()])
			ok = false
			break
		var login_res: Dictionary = service.login_dev_auth("DEV_%d" % i)
		if not bool(login_res.get("ok", false)):
			push_error("OnlineService login failed for player %d: %s" % [i, str(login_res)])
			ok = false
			break
		var puid: String = String(login_res.get("local_puid", ""))
		if puid.strip_edges() == "":
			push_error("Login returned empty local_puid for player %d" % i)
			ok = false
			break
		puids.append(puid)

		var lobby_service = LOBBY_SERVICE_SCRIPT.new()
		lobby_service.set_backend_mode("mock")
		lobby_service.set_local_puid(puid)
		lobby_services.append(lobby_service)

	if not ok:
		_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
		return false

	var host_lobby = lobby_services[0] as LobbyServiceEOS
	var create_res: Dictionary = host_lobby.create_lobby({
		"ruleset_id": "tr_101_classic",
		"version": "v1",
		"phase": "FILLING",
		"privacy": "PUBLIC",
	})
	if not bool(create_res.get("ok", false)):
		push_error("Host failed to create lobby: %s" % str(create_res))
		_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
		return false

	var host_view: Dictionary = host_lobby.get_current_lobby()
	var lobby_id: String = String(host_view.get("lobby_id", ""))
	if lobby_id == "":
		push_error("Lobby ID missing after create_lobby.")
		_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
		return false

	for i in range(1, 4):
		var join_res: Dictionary = lobby_services[i].join_lobby(lobby_id)
		if not bool(join_res.get("ok", false)):
			push_error("Join failed for player %d: %s" % [i, str(join_res)])
			_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
			return false

	for i in range(4):
		var ready_res: Dictionary = lobby_services[i].set_ready(true)
		if not bool(ready_res.get("ok", false)):
			push_error("set_ready failed for player %d: %s" % [i, str(ready_res)])
			_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
			return false

	host_view = host_lobby.get_current_lobby()
	var members: Array = host_view.get("members", [])
	if members.size() != 4:
		push_error("Expected 4 lobby members, got %d" % members.size())
		_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
		return false

	var ready_count: int = 0
	var seat_by_puid: Dictionary = {}
	for member in members:
		var member_puid: String = String(member.get("puid", ""))
		if member_puid == "":
			continue
		var attrs: Dictionary = member.get("attrs", {})
		seat_by_puid[member_puid] = int(attrs.get("seat", -1))
		if bool(attrs.get("ready", false)):
			ready_count += 1

	if seat_by_puid.size() != 4:
		push_error("Seat map incomplete after joins: %s" % str(seat_by_puid))
		_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
		return false
	if ready_count != 4:
		push_error("Expected 4 ready members, got %d" % ready_count)
		_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
		return false

	var set_phase_res: Dictionary = host_lobby.set_lobby_attr("phase", "MATCH_STARTING")
	if not bool(set_phase_res.get("ok", false)):
		push_error("Failed to set lobby phase: %s" % str(set_phase_res))
		_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
		return false
	var set_match_id_res: Dictionary = host_lobby.set_lobby_attr("match_id", match_id)
	if not bool(set_match_id_res.get("ok", false)):
		push_error("Failed to set lobby match_id: %s" % str(set_match_id_res))
		_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
		return false
	var set_hash_res: Dictionary = host_lobby.set_lobby_attr("ruleset_hash", "hash_mock_777001")
	if not bool(set_hash_res.get("ok", false)):
		push_error("Failed to set lobby ruleset_hash: %s" % str(set_hash_res))
		_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
		return false

	host_view = host_lobby.get_current_lobby()
	var attrs: Dictionary = host_view.get("attrs", {})
	if String(attrs.get("phase", "")) != "MATCH_STARTING":
		push_error("Lobby phase was not updated to MATCH_STARTING.")
		_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
		return false
	if String(attrs.get("match_id", "")) != match_id:
		push_error("Lobby match_id mismatch after update.")
		_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
		return false

	var host_transport = TRANSPORT_SCRIPT.new()
	host_transport.set_backend_mode("mock")
	var host_match = HOST_MATCH_SCRIPT.new()
	host_match.configure_host(String(puids[0]), host_transport, seat_by_puid, match_id, match_seed)
	host_match.start_new_match(RuleConfig.new(), match_seed, 4)

	var host_core: LocalGameController = host_match.get("_core") as LocalGameController
	if host_core == null or host_core.state == null:
		push_error("HostMatchController core state missing after start_new_match.")
		_free_host_runtime(host_match, host_transport)
		_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
		return false
	if host_match.state == null:
		push_error("HostMatchController state missing after start_new_match.")
		_free_host_runtime(host_match, host_transport)
		_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
		return false
	if host_match.state.players.size() != 4:
		push_error("HostMatchController state did not start with 4 players.")
		_free_host_runtime(host_match, host_transport)
		_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
		return false

	_free_host_runtime(host_match, host_transport)
	_cleanup_online_lobby_flow(online_services, lobby_services, original_runtime_env)
	return true

func _cleanup_online_lobby_flow(online_services: Array, lobby_services: Array, original_runtime_env: String) -> void:
	for i in range(lobby_services.size() - 1, -1, -1):
		var lobby_service = lobby_services[i] as LobbyServiceEOS
		if lobby_service != null:
			lobby_service.leave_lobby()
			lobby_service.free()
	for service in online_services:
		var online_service = service as OnlineServiceEOS
		if online_service != null:
			online_service.logout()
			online_service.free()
	LOBBY_SERVICE_SCRIPT.clear_mock_lobbies()
	TRANSPORT_SCRIPT.clear_mock_registry()
	OS.set_environment("PROJECT101_EOS_RUNTIME", original_runtime_env)

func _free_host_runtime(host_match: HostMatchController, host_transport: P2PTransportEOS) -> void:
	if host_match != null:
		var host_core = host_match.get("_core")
		if host_core != null and host_core is Node:
			(host_core as Node).free()
		host_match.free()
	if host_transport != null:
		host_transport.free()
