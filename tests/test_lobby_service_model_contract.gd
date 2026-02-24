extends RefCounted

const LOBBY_SERVICE_SCRIPT: Script = preload("res://net/LobbyServiceEOS.gd")

func run() -> bool:
	return _test_mock_lobby_model_shape_and_deterministic_seats()

func _test_mock_lobby_model_shape_and_deterministic_seats() -> bool:
	LOBBY_SERVICE_SCRIPT.clear_mock_lobbies()
	var host = LOBBY_SERVICE_SCRIPT.new()
	var client = LOBBY_SERVICE_SCRIPT.new()
	host.set_backend_mode("mock")
	client.set_backend_mode("mock")
	host.set_local_puid("P0")
	client.set_local_puid("P1")

	var create_res: Dictionary = host.create_lobby({
		"ruleset_id": "tr_101_classic",
		"version": "v1",
		"phase": "FILLING",
		"privacy": "PUBLIC",
	})
	if not bool(create_res.get("ok", false)):
		push_error("Host failed to create lobby: %s" % str(create_res))
		return false

	var lobby: Dictionary = host.get_current_lobby()
	if lobby.is_empty():
		push_error("Current lobby missing after create.")
		return false
	if not lobby.has("lobby_id") or not lobby.has("owner_puid") or not lobby.has("attrs") or not lobby.has("members"):
		push_error("Lobby model contract missing required keys.")
		return false
	if String(lobby.get("owner_puid", "")) != "P0":
		push_error("Unexpected owner_puid in created lobby.")
		return false

	var join_res: Dictionary = client.join_lobby(String(lobby.get("lobby_id", "")))
	if not bool(join_res.get("ok", false)):
		push_error("Client failed to join lobby: %s" % str(join_res))
		return false

	var host_view: Dictionary = host.get_current_lobby()
	var seat_by_puid: Dictionary = {}
	for member in host_view.get("members", []):
		var puid: String = String(member.get("puid", ""))
		if puid == "":
			continue
		var attrs: Dictionary = member.get("attrs", {})
		if not attrs.has("seat") or not attrs.has("ready") or not attrs.has("status") or not attrs.has("platform"):
			push_error("Member attrs contract incomplete for %s." % puid)
			return false
		if not attrs.has("display_name") or not attrs.has("build_family") or not attrs.has("protocol_rev"):
			push_error("Member compatibility attrs missing for %s." % puid)
			return false
		seat_by_puid[puid] = int(attrs.get("seat", -1))

	if seat_by_puid.get("P0", -1) != 0 or seat_by_puid.get("P1", -1) != 1:
		push_error("Seat assignment is not deterministic: %s" % str(seat_by_puid))
		return false

	var ready_res: Dictionary = client.set_ready(true)
	if not bool(ready_res.get("ok", false)):
		push_error("Client set_ready failed: %s" % str(ready_res))
		return false
	var refreshed: Dictionary = host.get_current_lobby()
	for member in refreshed.get("members", []):
		if String(member.get("puid", "")) == "P1":
			if not bool(member.get("attrs", {}).get("ready", false)):
				push_error("Expected joined member ready=true after set_ready.")
				return false

	host.free()
	client.free()
	return true
