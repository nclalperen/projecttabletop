extends RefCounted

const PROTOCOL: Script = preload("res://net/Protocol.gd")
const TRANSPORT_SCRIPT: Script = preload("res://net/P2PTransportEOS.gd")
const HOST_MATCH_SCRIPT: Script = preload("res://net/HostMatchController.gd")

func run() -> bool:
	return _test_host_enforces_peer_identity_and_seq()

func _test_host_enforces_peer_identity_and_seq() -> bool:
	TRANSPORT_SCRIPT.clear_mock_registry()
	var host_transport = TRANSPORT_SCRIPT.new()
	var host = HOST_MATCH_SCRIPT.new()
	var seats := {"HOST": 0, "P1": 1, "P2": 2, "P3": 3}
	host.configure_host("HOST", host_transport, seats, "M_AUTH", 9101)
	host.start_new_match(RuleConfig.new(), 9101, 4)

	var core: LocalGameController = host.get("_core") as LocalGameController
	if core == null or core.state == null:
		push_error("Host core state missing")
		return false
	var starter_tiles: int = int(core.state.rule_config.starter_tiles)
	if core.state.players[1].hand.size() >= starter_tiles:
		core.state.players[1].hand.resize(starter_tiles - 1)
	core.state.current_player_index = 1
	core.state.phase = GameState.Phase.TURN_DRAW

	var p1_transport = TRANSPORT_SCRIPT.new()
	p1_transport.open_endpoint("P1")
	var p1_results: Array = []
	p1_transport.packet_received.connect(func(_from: String, msg: Dictionary) -> void:
		if String(msg.get("type", "")) == PROTOCOL.S_ACTION_RESULT:
			p1_results.append(msg)
	)

	var req: Dictionary = PROTOCOL.wrap(PROTOCOL.C_ACTION_REQUEST, {
		"seq": 1,
		"turn_id": 0,
		"action": {"type": "DRAW_FROM_DECK", "player_id": 0, "payload": {}},
	})
	var send_res: Dictionary = p1_transport.send_packet("HOST", req, true)
	if not bool(send_res.get("ok", false)):
		push_error("P1 send failed: %s" % str(send_res))
		return false
	if p1_results.is_empty() or not bool(p1_results[p1_results.size() - 1].get("ok", false)):
		push_error("Expected host to accept first valid seq")
		return false

	# Replay same seq should be rejected.
	p1_transport.send_packet("HOST", req, true)
	if p1_results.size() < 2:
		push_error("Expected second action result for stale seq")
		return false
	if String(p1_results[p1_results.size() - 1].get("code", "")) != "duplicate_or_old_seq":
		push_error("Expected duplicate_or_old_seq, got %s" % str(p1_results[p1_results.size() - 1]))
		return false

	# Unknown peer should be rejected.
	var x_transport = TRANSPORT_SCRIPT.new()
	x_transport.open_endpoint("X")
	var x_results: Array = []
	x_transport.packet_received.connect(func(_from: String, msg: Dictionary) -> void:
		if String(msg.get("type", "")) == PROTOCOL.S_ACTION_RESULT:
			x_results.append(msg)
	)
	var x_req: Dictionary = PROTOCOL.wrap(PROTOCOL.C_ACTION_REQUEST, {
		"seq": 1,
		"turn_id": 0,
		"action": {"type": "DRAW_FROM_DECK", "player_id": 0, "payload": {}},
	})
	x_transport.send_packet("HOST", x_req, true)
	if x_results.is_empty() or String(x_results[x_results.size() - 1].get("code", "")) != "unknown_peer":
		push_error("Expected unknown_peer rejection for non-member")
		return false

	return true
