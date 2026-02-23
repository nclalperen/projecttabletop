extends RefCounted

const TRANSPORT_SCRIPT: Script = preload("res://net/P2PTransportEOS.gd")
const HOST_MATCH_SCRIPT: Script = preload("res://net/HostMatchController.gd")

func run() -> bool:
	return _test_disconnect_bot_takeover_path()

func _test_disconnect_bot_takeover_path() -> bool:
	TRANSPORT_SCRIPT.clear_mock_registry()
	var host_transport = TRANSPORT_SCRIPT.new()
	var host = HOST_MATCH_SCRIPT.new()
	var cleanup := func() -> void:
		if host != null:
			var host_core = host.get("_core")
			if host_core != null and host_core is Node:
				(host_core as Node).free()
			host.free()
		if host_transport != null:
			host_transport.free()
		TRANSPORT_SCRIPT.clear_mock_registry()
	host.configure_host("HOST", host_transport, {"HOST": 0, "P1": 1, "P2": 2, "P3": 3}, "M_REJOIN", 9201)
	host.start_new_match(RuleConfig.new(), 9201, 4)

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
	var before_phase: int = int(core.state.phase)
	var before_deck: int = core.state.deck.size()

	host.mark_peer_disconnected("P1")

	var after_phase: int = int(core.state.phase)
	var after_deck: int = core.state.deck.size()
	if after_phase == before_phase and after_deck == before_deck:
		push_error("Expected bot takeover to advance phase or consume deck")
		cleanup.call()
		return false

	host.mark_peer_reconnected("P1")
	var bot_map: Dictionary = host.get("_bot_seats")
	if bool(bot_map.get(1, false)):
		push_error("Seat should exit bot mode after reconnect")
		cleanup.call()
		return false

	cleanup.call()
	return true
