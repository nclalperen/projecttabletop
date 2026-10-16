extends SceneTree
## Render fixtures or complete a real two-round match. Captures must be external.
## -- --okey-skip-guide --qa-dir=C:/Temp/okey --qa-fixture=crowded|open|results|match

var board: Node
var session: Node
var capture_dir: String = ""
var fixture: String = "open"
var capture_view: Viewport
var requested_size := Vector2i.ZERO

func _init() -> void:
	call_deferred("_run")

func _frames(count: int = 5) -> void:
	for index in range(count):
		await process_frame

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-dir="): capture_dir = arg.trim_prefix("--qa-dir=")
		if arg.begins_with("--qa-fixture="): fixture = arg.trim_prefix("--qa-fixture=")
		if arg.begins_with("--qa-size="):
			var parts := arg.trim_prefix("--qa-size=").split("x")
			if parts.size() == 2: requested_size = Vector2i(int(parts[0]), int(parts[1]))
	capture_view = root
	if requested_size.x > 0 and requested_size.y > 0:
		var viewport := SubViewport.new()
		viewport.size = requested_size
		viewport.own_world_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		capture_view = viewport
	board = load("res://ui/GameTable3D.tscn").instantiate()
	var config := RuleConfig.new()
	config.timer_seconds = 0
	config.match_end_mode = "rounds"
	config.match_end_value = 2
	board.configure_game(config, 760013, 4)
	capture_view.add_child(board)
	await _frames(8)
	session = board.get("_game_table")
	var controller = session.get_controller()
	if fixture == "match":
		await _match(controller)
	else:
		session.bots_enabled = false
		var state = controller.state
		state.current_player_index = 0
		state.phase = GameState.Phase.TURN_PLAY
		state.players[0].has_opened = true
		state.table_melds.clear()
		for index in range(32 if fixture == "crowded" else 4):
			var tiles: Array = []
			var ids: Array = []
			for number in range(3, 7):
				var tile := Tile.new(index % 4, number, Tile.Kind.NORMAL, 880000 + index * 10 + number)
				tiles.append(tile)
				ids.append(tile.unique_id)
			state.table_melds.append(Meld.new(Meld.Kind.RUN, ids, tiles, index % 4))
		if fixture == "crowded":
			while state.players[0].hand.size() < 30:
				var index: int = state.players[0].hand.size()
				state.players[0].hand.append(Tile.new(index % 4, index % 13 + 1, Tile.Kind.NORMAL, 890000 + index))
		if fixture == "results":
			state.phase = GameState.Phase.ROUND_END
			state.round_end_reason = "stock_empty"
		session._sync_state()
		board._force_sync()
		await _frames(12)
		await _capture(fixture)
	board.queue_free()
	await _frames(6)
	LocalGameController.free_test_tracked_instances()
	quit()

func _capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless": return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	await _frames(120)
	var started: int = Time.get_ticks_usec()
	await _frames(120)
	var fps: float = 120000000.0 / maxf(1, Time.get_ticks_usec() - started)
	await RenderingServer.frame_post_draw
	var dimensions: Vector2 = capture_view.get_visible_rect().size
	var path := capture_dir.path_join("%s-%sx%s.png" % [label, int(dimensions.x), int(dimensions.y)])
	var error := capture_view.get_texture().get_image().save_png(path)
	print("QA_CAPTURE ", path, " error=", error, " measured_120frame_FPS=", fps)

func _match(controller) -> void:
	var bot := BotHeuristic.new()
	var actions: int = 0
	var rounds: int = 0
	var started: int = Time.get_ticks_msec()
	var progress: int = started
	while actions < 6000:
		var state = controller.state
		var now: int = Time.get_ticks_msec()
		if now - started > 180000:
			push_error("QA match timed out: seat=%s phase=%s bot_running=%s actions=%s" % [state.current_player_index, state.phase, session._bot_loop_running, actions])
			quit(1)
			return
		if now - progress > 5000:
			print("QA_MATCH progress seat=", state.current_player_index, " phase=", state.phase, " bot_running=", session._bot_loop_running, " actions=", actions)
			progress = now
		if state.phase == GameState.Phase.ROUND_END:
			rounds += 1
			await _capture("round-%s" % rounds)
			if state.match_finished:
				print("QA_MATCH PASS rounds=", rounds, " actions=", actions)
				return
			session.overlay_new_round()
			await _frames(3)
			continue
		if state.current_player_index != 0 or session._bot_loop_running:
			await process_frame
			continue
		var action = await session._compute_bot_action_async(bot, state, 0)
		if action == null:
			push_error("QA local bot returned no action")
			quit(1)
			return
		var result: Dictionary = session._submit(action)
		if not bool(result.get("ok", false)):
			push_error("QA local action rejected: %s" % result)
			quit(1)
			return
		actions += 1
		await _frames(1)
	push_error("QA match exceeded action limit")
	quit(1)
