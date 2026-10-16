extends SceneTree
## QA Capture and test harness for VectorGameTable3D.
## Usage:
##   cmd /c "tools\godot.cmd -s tests/qa_vector3d.gd -- --qa-dir=dev/qa --qa-fixture=opening --qa-size=1920x1080"
##
## Supported fixtures:
##   opening, midgame, crowded, after_discard, dragging, results, match

const SCENE_PATH := "res://ui/vector_table/VectorGameTable3D.tscn"
const TUNING := preload("res://ui/vector_table/VectorTuning3D.gd")
const TileFaceAtlas = preload("res://ui/vector_table/render/TileFaceAtlas.gd")

var board: Node = null
var session: Node = null
var capture_dir: String = "dev/qa"
var fixture: String = "opening"
var capture_view: Viewport = null
var requested_size := Vector2i(1920, 1080)
var delay_sec: float = 0.0


func _init() -> void:
	call_deferred("_run")


func _frames(count: int = 5) -> void:
	for index in range(count):
		await process_frame


func _parse_args() -> void:
	var args: Array = OS.get_cmdline_user_args()
	args.append_array(OS.get_cmdline_args())
	for arg in args:
		if arg.begins_with("--qa-dir="):
			capture_dir = arg.trim_prefix("--qa-dir=")
		elif arg.begins_with("--qa-fixture="):
			fixture = arg.trim_prefix("--qa-fixture=")
		elif arg.begins_with("--qa-delay="):
			delay_sec = float(arg.trim_prefix("--qa-delay="))
		elif arg.begins_with("--qa-size="):
			var parts: PackedStringArray = arg.trim_prefix("--qa-size=").split("x")
			if parts.size() == 2:
				requested_size = Vector2i(int(parts[0]), int(parts[1]))


func _run() -> void:
	_parse_args()

	capture_view = root
	if requested_size.x > 0 and requested_size.y > 0:
		var viewport := SubViewport.new()
		viewport.name = "QASubViewport"
		viewport.size = requested_size
		viewport.own_world_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		capture_view = viewport

	await TileFaceAtlas.ensure_atlas(root.get_tree())

	var scene: PackedScene = load(SCENE_PATH)
	if scene == null:
		push_error("Failed to load scene: %s" % SCENE_PATH)
		quit(1)
		return

	board = scene.instantiate()
	var config := RuleConfig.new()
	config.timer_seconds = 0
	config.match_end_mode = "rounds"
	config.match_end_value = 2
	board.configure_game(config, 1701, 4)
	capture_view.add_child(board)
	await _frames(10)

	session = board.get("_session")
	var controller = session.get_controller() if session != null else null

	if fixture == "match":
		await _match(controller)
	else:
		if session != null:
			session.bots_enabled = false
		if controller != null and controller.state != null:
			var state = controller.state
			state.current_player_index = 0
			state.phase = GameState.Phase.TURN_PLAY
			state.players[0].has_opened = (fixture != "opening")

			if fixture == "crowded" or fixture == "midgame":
				state.table_melds.clear()
				var meld_count := 32 if fixture == "crowded" else 6
				for index in range(meld_count):
					var tiles: Array = []
					var ids: Array = []
					for number in range(3, 7):
						var tile := Tile.new(index % 4, number, Tile.Kind.NORMAL, 880000 + index * 10 + number)
						tiles.append(tile)
						ids.append(tile.unique_id)
					state.table_melds.append(Meld.new(Meld.Kind.RUN, ids, tiles, index % 4))

				if state.players.size() >= 4:
					state.players[1].hand.resize(17)
					state.players[2].hand.resize(14)
					state.players[3].hand.resize(19)

				state.player_discard_stacks = [
					[Tile.new(0, 11, Tile.Kind.NORMAL, 770001), Tile.new(2, 4, Tile.Kind.NORMAL, 770002)],
					[Tile.new(1, 8, Tile.Kind.NORMAL, 770003)],
					[Tile.new(3, 13, Tile.Kind.NORMAL, 770004), Tile.new(0, 6, Tile.Kind.NORMAL, 770005)],
					[Tile.new(2, 9, Tile.Kind.NORMAL, 770006), Tile.new(1, 5, Tile.Kind.NORMAL, 770007), Tile.new(3, 2, Tile.Kind.NORMAL, 770008)],
				]

			if fixture == "crowded":
				while state.players[0].hand.size() < 30:
					var index: int = state.players[0].hand.size()
					state.players[0].hand.append(Tile.new(index % 4, index % 13 + 1, Tile.Kind.NORMAL, 890000 + index))

			if fixture == "results":
				state.phase = GameState.Phase.ROUND_END
				state.round_end_reason = "stock_empty"

			session._sync_state()

		if fixture == "dragging":
			await _frames(15)
			var input = board.get("_input_handler")
			var hand_slots: Dictionary = board.get("_hand_slots_map") if "_hand_slots_map" in board else {}
			var reg = board.get("_registry")
			if input != null and not hand_slots.is_empty() and reg != null:
				var center_tid: int = hand_slots.get(7, hand_slots.values()[0])
				var center_tile = reg.get_node_for(center_tid)
				if center_tile != null:
					input._start_drag(center_tile, 7)
					var drag_screen_pos := Vector2(float(requested_size.x) * 0.5 + 80.0, float(requested_size.y) * 0.65)
					input._update_drag(drag_screen_pos)
			await _frames(10)
		elif fixture == "after_discard" and session != null:
			await _frames(15)
			# Find first tile in hand and discard it
			var controller_state = controller.state if controller != null else null
			var hand: Array = controller_state.players[0].hand if controller_state != null else []
			if not hand.is_empty():
				var tile_to_discard = hand[0]
				var res: Dictionary = session.overlay_discard_tile(tile_to_discard.unique_id)
				print("QA after_discard submit result: ", res)

			var delay_frames := maxi(1, int(delay_sec * 60.0)) if delay_sec > 0.0 else 11 # ~0.18s default
			for _f in range(delay_frames):
				await process_frame
		elif delay_sec > 0.0:
			var delay_frames := int(delay_sec * 60.0)
			await _frames(maxi(1, delay_frames))
		else:
			await _frames(30)

		await _capture(fixture)

	if board != null and is_instance_valid(board):
		board.queue_free()
	await _frames(4)
	LocalGameController.free_test_tracked_instances()
	quit(0)


func _capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		print("QA_CAPTURE skipped: headless or empty dir")
		return

	DirAccess.make_dir_recursive_absolute(capture_dir)
	await _frames(30)

	var started: int = Time.get_ticks_usec()
	await _frames(60)
	var elapsed_usec: int = Time.get_ticks_usec() - started
	var fps: float = 60000000.0 / maxf(1.0, float(elapsed_usec))

	await RenderingServer.frame_post_draw
	var dimensions: Vector2 = capture_view.get_visible_rect().size
	var file_name := "%s-%sx%s.png" % [label, int(dimensions.x), int(dimensions.y)]
	var path := capture_dir.path_join(file_name)

	var img: Image = capture_view.get_texture().get_image()
	if img == null or img.is_empty():
		push_error("Failed to capture image from viewport texture")
		return

	var error := img.save_png(path)
	print("QA_CAPTURE ", path, " error=", error, " measured_60frame_FPS=", fps)


func _match(controller) -> void:
	if controller == null or session == null:
		push_error("QA match controller is null")
		quit(1)
		return

	var bot := BotHeuristic.new()
	var actions: int = 0
	var rounds: int = 0
	var started: int = Time.get_ticks_msec()
	var progress: int = started

	while actions < 6000:
		var state = controller.state
		var now: int = Time.get_ticks_msec()
		if now - started > 180000:
			push_error("QA match timed out: seat=%s phase=%s" % [state.current_player_index, state.phase])
			quit(1)
			return

		if now - progress > 5000:
			print("QA_MATCH progress seat=", state.current_player_index, " phase=", state.phase, " actions=", actions)
			progress = now

		if state.phase == GameState.Phase.ROUND_END:
			rounds += 1
			print("QA_MATCH completed round ", rounds)
			if state.match_finished or rounds >= 2:
				print("QA_MATCH PASS rounds=", rounds, " actions=", actions)
				return
			session.overlay_new_round()
			await _frames(5)
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
