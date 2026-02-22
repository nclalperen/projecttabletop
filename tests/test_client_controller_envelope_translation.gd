extends RefCounted

const TRANSPORT_SCRIPT: Script = preload("res://net/P2PTransportEOS.gd")
const HOST_MATCH_SCRIPT: Script = preload("res://net/HostMatchController.gd")
const CLIENT_MATCH_SCRIPT: Script = preload("res://net/ClientMatchController.gd")

func run() -> bool:
	return _test_client_envelope_translation_against_host()

func _test_client_envelope_translation_against_host() -> bool:
	TRANSPORT_SCRIPT.clear_mock_registry()
	var host_transport = TRANSPORT_SCRIPT.new()
	var host = HOST_MATCH_SCRIPT.new()
	host.configure_host("HOST", host_transport, {"HOST": 0, "P1": 1, "P2": 2, "P3": 3}, "M_CLIENT", 9301)
	host.start_new_match(RuleConfig.new(), 9301, 4)

	var core: LocalGameController = host.get("_core") as LocalGameController
	if core == null or core.state == null:
		push_error("Host core state missing")
		return false
	var starter_tiles: int = int(core.state.rule_config.starter_tiles)
	if core.state.players[1].hand.size() >= starter_tiles:
		core.state.players[1].hand.resize(starter_tiles - 1)
	core.state.current_player_index = 1
	core.state.phase = GameState.Phase.TURN_DRAW

	var client_transport = TRANSPORT_SCRIPT.new()
	var client = CLIENT_MATCH_SCRIPT.new()
	client.configure_client("P1", "HOST", client_transport, 1, "M_CLIENT")
	if client.state == null:
		push_error("Expected initial snapshot after HELLO")
		return false

	var submit_res: Dictionary = client.draw_from_deck(0)
	if not bool(submit_res.get("ok", false)):
		push_error("Client draw submit failed: %s" % str(submit_res))
		return false

	if core.state.phase != GameState.Phase.TURN_PLAY:
		push_error("Host state not advanced to TURN_PLAY")
		return false
	if client.state == null or int(client.state.phase) != int(GameState.Phase.TURN_PLAY):
		push_error("Client snapshot did not reflect TURN_PLAY after host apply")
		return false

	return true
