extends RefCounted

const HOST_MATCH_SCRIPT: Script = preload("res://net/HostMatchController.gd")


func run() -> bool:
	return _test_host_enforces_peer_identity_and_seq()


func _test_host_enforces_peer_identity_and_seq() -> bool:
	var host = HOST_MATCH_SCRIPT.new()
	var cleanup := func() -> void:
		if host != null:
			var host_core = host.get("_core")
			if host_core != null and host_core is Node:
				(host_core as Node).free()
			host.free()

	var seats := {"HOST": 0, "P1": 1, "P2": 2, "P3": 3}
	host.configure_host("HOST", null, seats, "M_AUTH", 9101)
	host.start_new_match(RuleConfig.new(), 9101, 4)

	var core: LocalGameController = host.get("_core") as LocalGameController
	if core == null or core.state == null:
		push_error("Host core state missing")
		cleanup.call()
		return false
	var starter_tiles: int = int(core.state.rule_config.starter_tiles)
	if core.state.players[1].hand.size() >= starter_tiles:
		core.state.players[1].hand.resize(starter_tiles - 1)
	core.state.current_player_index = 1
	core.state.phase = GameState.Phase.TURN_DRAW

	var action: Dictionary = {"type": "DRAW_FROM_DECK", "player_id": 0, "payload": {}}
	var accepted: Dictionary = host.call("_apply_client_action", "P1", action, 1, true)
	if not bool(accepted.get("ok", false)):
		push_error("Expected host to accept first valid seq, got: %s" % str(accepted))
		cleanup.call()
		return false

	var replay: Dictionary = host.call("_apply_client_action", "P1", action, 1, true)
	if String(replay.get("code", "")) != "duplicate_or_old_seq":
		push_error("Expected duplicate_or_old_seq, got %s" % str(replay))
		cleanup.call()
		return false

	var unknown_peer: Dictionary = host.call("_apply_client_action", "X", action, 1, true)
	if String(unknown_peer.get("code", "")) != "unknown_peer":
		push_error("Expected unknown_peer rejection for non-member, got %s" % str(unknown_peer))
		cleanup.call()
		return false

	cleanup.call()
	return true
