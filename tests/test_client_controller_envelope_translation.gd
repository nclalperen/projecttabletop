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
	var client_transport: P2PTransportEOS = null
	var client: ClientMatchController = null
	var cleanup := func() -> void:
		if client != null:
			client.free()
		if client_transport != null:
			client_transport.free()
		if host != null:
			var host_core = host.get("_core")
			if host_core != null and host_core is Node:
				(host_core as Node).free()
			host.free()
		if host_transport != null:
			host_transport.free()
		TRANSPORT_SCRIPT.clear_mock_registry()
	host.configure_host("HOST", host_transport, {"HOST": 0, "P1": 1, "P2": 2, "P3": 3}, "M_CLIENT", 9301)
	host.start_new_match(RuleConfig.new(), 9301, 4)

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

	client_transport = TRANSPORT_SCRIPT.new()
	client = CLIENT_MATCH_SCRIPT.new()
	client.configure_client("P1", "HOST", client_transport, 1, "M_CLIENT")
	if client.state == null:
		push_error("Expected initial snapshot after HELLO")
		cleanup.call()
		return false

	var submit_res: Dictionary = client.draw_from_deck(0)
	if not bool(submit_res.get("ok", false)):
		push_error("Client draw submit failed: %s" % str(submit_res))
		cleanup.call()
		return false

	if core.state.phase != GameState.Phase.TURN_PLAY:
		push_error("Host state not advanced to TURN_PLAY")
		cleanup.call()
		return false
	if client.state == null or int(client.state.phase) != int(GameState.Phase.TURN_PLAY):
		push_error("Client snapshot did not reflect TURN_PLAY after host apply")
		cleanup.call()
		return false

	# Exercise the real transport gate for meld actions, which have no imported item_id.
	core.state.rule_config.open_min_points_initial = 1
	core.state.okey_context = OkeyContext.new(Tile.new(Tile.TileColor.YELLOW, 12, Tile.Kind.NORMAL, 70000))
	core.state.players[1].has_opened = false
	core.state.players[1].hand = [
		Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 70001),
		Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 70002),
		Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 70003),
		Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 70004),
		Tile.new(Tile.TileColor.BLUE, 12, Tile.Kind.NORMAL, 70005)]
	client.submit_action_envelope({"type": "OPEN_MELDS", "player_id": 0, "payload": {"melds": [{"kind": Meld.Kind.RUN, "tile_ids": [70001, 70002, 70003]}]}})
	if core.state.table_melds.size() != 1:
		push_error("Client opening must reach the Okey validator through transport")
		cleanup.call()
		return false
	client.submit_action_envelope({"type": "ADD_TO_MELD", "player_id": 0, "payload": {"target_meld_index": 0, "tile_ids": [70004]}})
	if core.state.table_melds[0].tiles.size() != 4:
		push_error("Client extension must reach the Okey validator through transport")
		cleanup.call()
		return false
	var before: int = core.state.players[1].hand.size()
	client.draw_from_deck(0)
	if core.state.players[1].hand.size() != before:
		push_error("Host must reject a second draw in TURN_PLAY")
		cleanup.call()
		return false
	core.state.current_player_index = 2
	client.submit_action_envelope({"type": "END_PLAY", "player_id": 0, "payload": {}})
	if core.state.phase != GameState.Phase.TURN_PLAY:
		push_error("Host must reject out-of-turn actions")
		cleanup.call()
		return false

	cleanup.call()
	return true
