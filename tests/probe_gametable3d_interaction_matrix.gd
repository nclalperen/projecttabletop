extends SceneTree

const ENABLE_CAPTURE: bool = false

var scene_root: Node = null
var game_table: Node = null
var controller = null
var camera: Camera3D = null
var failures: int = 0
var passes: int = 0
var _uid_seed: int = 980000


func _init() -> void:
	await _run()


func _run() -> void:
	var ps := load("res://ui/GameTable3D.tscn") as PackedScene
	if ps == null:
		print("FATAL: missing GameTable3D scene")
		quit(1)
		return
	scene_root = ps.instantiate()
	root.add_child(scene_root)
	await _wait_frames(8)

	game_table = scene_root.get("_game_table")
	if game_table == null:
		print("FATAL: _game_table missing")
		quit(1)
		return
	controller = game_table.call("get_controller")
	if controller == null or controller.state == null:
		print("FATAL: controller/state missing")
		quit(1)
		return
	camera = scene_root.get_node_or_null("World/Camera3D") as Camera3D
	if camera == null:
		print("FATAL: camera missing")
		quit(1)
		return
	var hud_bar = scene_root.get("_hud_bar")
	if hud_bar != null:
		hud_bar.visible = false

	# Freeze bot auto-loop so scripted scenarios stay deterministic.
	game_table.set("_bot_loop_running", true)
	# Apply deterministic seed path and restart round.
	scene_root.call("configure_game", RuleConfig.new(), 101101, 4)
	await _wait_frames(2)
	game_table.call("overlay_new_round")
	await _wait_frames(4)
	await _sync_world()

	await _scenario_01_rack_to_draft()
	await _scenario_02_draft_reorder()
	await _scenario_03_draft_to_rack()
	await _scenario_04_starter_discard_drag()
	await _scenario_05_turn_discard_drag()
	await _scenario_06_turn_play_end_then_discard_drag()
	await _scenario_07_rack_to_committed_meld()
	await _scenario_08_draw_from_deck_tap()
	await _scenario_09_take_discard_legal_tap()
	await _scenario_10_turn_play_tap_selected_tile_to_draft_noop()
	await _scenario_11_turn_discard_tap_selected_tile_to_discard_noop()
	await _scenario_12_committed_meld_reposition_drag()
	await _scenario_13_round_end_click_new_round()

	print("SCENARIO_SUMMARY: pass=%d fail=%d" % [passes, failures])
	await _teardown_and_quit(0 if failures == 0 else 1)


func _alloc_uid() -> int:
	_uid_seed += 1
	return _uid_seed


func _wait_frames(count: int) -> void:
	for _i in range(maxi(1, count)):
		await process_frame
		await physics_frame


func _free_test_instances() -> void:
	LocalGameController.free_test_tracked_instances()
	HostMatchController.free_test_tracked_instances()
	ClientMatchController.free_test_tracked_instances()
	P2PTransportEOS.free_test_tracked_instances()
	OnlineServiceEOS.free_test_tracked_instances()
	LobbyServiceEOS.free_test_tracked_instances()


func _teardown_and_quit(exit_code: int) -> void:
	if scene_root != null and is_instance_valid(scene_root):
		if scene_root.get_parent() != null:
			scene_root.get_parent().remove_child(scene_root)
		scene_root.free()
		scene_root = null
	_free_test_instances()
	await _wait_frames(12)
	quit(exit_code)


func _sync_world() -> void:
	scene_root.call("_force_sync")
	await _wait_frames(4)


func _record(idx: int, name: String, ok: bool, note: String) -> void:
	if ok:
		passes += 1
		print("SCENARIO_%02d_%s:PASS %s" % [idx, name, note])
	else:
		failures += 1
		print("SCENARIO_%02d_%s:FAIL %s" % [idx, name, note])


func _capture(label: String) -> void:
	if not ENABLE_CAPTURE:
		return
	scene_root.call("_capture_viewport_png", label)
	await _wait_frames(3)


func _set_turn(phase_value: int) -> void:
	var s = controller.state
	s.current_player_index = 0
	s.phase = phase_value
	s.turn_required_use_tile_id = -1
	game_table.set("_action_in_flight", false)
	await _sync_world()


func _rule_starter_tiles() -> int:
	var s = controller.state
	if s == null or s.rule_config == null:
		return 22
	return int(s.rule_config.starter_tiles)


func _ensure_local_hand_size(target_count: int) -> void:
	var s = controller.state
	if s == null or s.players.is_empty():
		return
	var hand: Array = (s.players[0].hand as Array).duplicate()
	while hand.size() > target_count:
		hand.pop_back()
	while hand.size() < target_count:
		hand.append(Tile.new(Tile.TileColor.BLUE, 1 + int(hand.size() % 13), Tile.Kind.NORMAL, _alloc_uid()))
	s.players[0].hand = hand


func _ensure_draft_empty() -> void:
	await _set_turn(GameState.Phase.TURN_PLAY)
	var safety: int = 0
	while safety < 48:
		safety += 1
		var draft_slots: Array = game_table.call("get_draft_slots")
		var from_draft: int = -1
		for i in range(draft_slots.size()):
			if int(draft_slots[i]) != -1:
				from_draft = i
				break
		if from_draft == -1:
			break
		var rack_slots: Array = game_table.call("get_rack_slots")
		var to_rack: int = rack_slots.find(-1)
		if to_rack == -1:
			break
		game_table.call("overlay_move_draft_to_rack", from_draft, to_rack)
		await _sync_world()


func _prepare_turn_draw_with_legal_hand() -> void:
	await _set_turn(GameState.Phase.TURN_DRAW)
	_ensure_local_hand_size(maxi(0, _rule_starter_tiles() - 1))
	game_table.set("_action_in_flight", false)
	await _sync_world()


func _prepare_legal_take_discard_state() -> int:
	await _prepare_turn_draw_with_legal_hand()
	var s = controller.state
	s.players[0].has_opened = true
	s.players[0].opened_by_pairs = false
	var m5 := Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, _alloc_uid())
	var m6 := Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, _alloc_uid())
	var m7 := Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, _alloc_uid())
	s.table_melds = [Meld.new(Meld.Kind.RUN, [m5.unique_id, m6.unique_id, m7.unique_id], [m5, m6, m7], 1)]
	var d_tile := Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, _alloc_uid())
	s.discard_pile = [d_tile]
	while s.player_discard_stacks.size() < s.players.size():
		s.player_discard_stacks.append([])
	var prev_idx: int = (int(s.current_player_index) + s.players.size() - 1) % s.players.size()
	s.player_discard_stacks[prev_idx] = [d_tile]
	s.turn_required_use_tile_id = -1
	game_table.set("_action_in_flight", false)
	await _sync_world()
	return prev_idx


func _count_non_empty(slots: Array) -> int:
	var c: int = 0
	for v in slots:
		if int(v) != -1:
			c += 1
	return c


func _array_changed(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return true
	for i in range(a.size()):
		if int(a[i]) != int(b[i]):
			return true
	return false


func _first_rack_tile_screen() -> Dictionary:
	var hits: Array = scene_root.get("_local_rack_tile_hits")
	for h in hits:
		var d: Dictionary = h as Dictionary
		var tid: int = int(d.get("tile_id", -1))
		if tid == -1:
			continue
		var world: Vector3 = d.get("world", Vector3.ZERO) as Vector3
		return {
			"tile_id": tid,
			"slot": int(d.get("slot", -1)),
			"screen": camera.unproject_position(world)
		}
	return {}


func _screen_for_lane(px: float, py: float) -> Vector2:
	var lanes: Array = scene_root.get("_table_local_meld_lanes")
	if lanes.is_empty():
		return Vector2(640, 360)
	var lane: Rect2 = lanes[0] as Rect2
	var local_p: Vector2 = lane.position + Vector2(lane.size.x * px, lane.size.y * py)
	var world: Vector3 = scene_root.call("_table_local_to_world", local_p, 0.014) as Vector3
	return camera.unproject_position(world)


func _screen_for_discard(player_idx: int) -> Vector2:
	var points: Array = scene_root.get("_table_local_discard_points")
	if player_idx < 0 or player_idx >= points.size():
		return Vector2(900, 560)
	var local_p: Vector2 = points[player_idx] as Vector2
	var world: Vector3 = scene_root.call("_table_local_to_world", local_p, 0.014) as Vector3
	return camera.unproject_position(world)


func _screen_for_draw() -> Vector2:
	var local_p: Vector2 = scene_root.get("_draw_hotspot_center") as Vector2
	var world: Vector3 = scene_root.call("_table_local_to_world", local_p, 0.014) as Vector3
	return camera.unproject_position(world)


func _screen_for_draw_pick_area() -> Vector2:
	var draw_pick: Area3D = scene_root.get("_draw_pick_area") as Area3D
	if draw_pick != null and is_instance_valid(draw_pick):
		return camera.unproject_position(draw_pick.global_position)
	return _screen_for_draw()


func _screen_for_discard_pick_area(player_idx: int) -> Vector2:
	var discard_picks: Array = scene_root.get("_discard_pick_areas")
	if player_idx >= 0 and player_idx < discard_picks.size():
		var pick_area: Area3D = discard_picks[player_idx] as Area3D
		if pick_area != null and is_instance_valid(pick_area):
			return camera.unproject_position(pick_area.global_position)
	return _screen_for_discard(player_idx)


func _screen_for_rack_slot(prefer_empty: bool = true) -> Vector2:
	var slot_hits: Array = scene_root.get("_local_rack_slot_hits")
	var rack_slots: Array = game_table.call("get_rack_slots")
	for h in slot_hits:
		var d: Dictionary = h as Dictionary
		var slot_idx: int = int(d.get("slot", -1))
		if slot_idx < 0:
			continue
		if prefer_empty and slot_idx < rack_slots.size() and int(rack_slots[slot_idx]) != -1:
			continue
		var world: Vector3 = d.get("world", Vector3.ZERO) as Vector3
		return camera.unproject_position(world)
	if not slot_hits.is_empty():
		var d0: Dictionary = slot_hits[0] as Dictionary
		return camera.unproject_position(d0.get("world", Vector3.ZERO) as Vector3)
	return Vector2(640, 640)


func _first_draft_tile_screen() -> Dictionary:
	var hits: Array = scene_root.get("_draft_tile_hits")
	if hits.is_empty():
		return {}
	var d: Dictionary = hits[0] as Dictionary
	var world: Vector3 = d.get("world", Vector3.ZERO) as Vector3
	return {
		"slot": int(d.get("slot", -1)),
		"tile_id": int(d.get("tile_id", -1)),
		"screen": camera.unproject_position(world)
	}


func _first_table_meld_tile_screen() -> Dictionary:
	var hits: Array = scene_root.get("_table_meld_tile_hits")
	if hits.is_empty():
		return {}
	var d: Dictionary = hits[0] as Dictionary
	var world: Vector3 = d.get("world", Vector3.ZERO) as Vector3
	return {
		"meld_index": int(d.get("meld_index", -1)),
		"tile_id": int(d.get("tile_id", -1)),
		"screen": camera.unproject_position(world)
	}


func _send_left_press(pos: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = pos
	scene_root.call("_unhandled_input", e)


func _send_left_release(pos: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	e.position = pos
	scene_root.call("_unhandled_input", e)


func _send_motion(pos: Vector2, rel: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.relative = rel
	scene_root.call("_unhandled_input", e)


func _tap(pos: Vector2) -> void:
	_send_left_press(pos)
	await _wait_frames(1)
	_send_left_release(pos)
	await _wait_frames(2)


func _drag(start_pos: Vector2, end_pos: Vector2) -> void:
	_send_left_press(start_pos)
	await _wait_frames(1)
	var mid: Vector2 = start_pos.lerp(end_pos, 0.5)
	_send_motion(mid, mid - start_pos)
	await _wait_frames(1)
	_send_motion(end_pos, end_pos - mid)
	await _wait_frames(1)
	_send_left_release(end_pos)
	await _wait_frames(2)


func _ensure_two_draft_tiles() -> void:
	var tries: int = 0
	while _count_non_empty(game_table.call("get_draft_slots")) < 2 and tries < 4:
		tries += 1
		await _set_turn(GameState.Phase.TURN_PLAY)
		var src: Dictionary = _first_rack_tile_screen()
		if src.is_empty():
			break
		var target: Vector2 = _screen_for_lane(0.20 + 0.15 * float(tries), 0.40)
		await _drag(src.get("screen", Vector2.ZERO) as Vector2, target)
		await _sync_world()


func _ensure_committed_meld() -> void:
	var s = controller.state
	var m1 := Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, _alloc_uid())
	var m2 := Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, _alloc_uid())
	var m3 := Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, _alloc_uid())
	var meld := Meld.new(Meld.Kind.RUN, [m1.unique_id, m2.unique_id, m3.unique_id], [m1, m2, m3], 0)
	s.table_melds = [meld]
	await _sync_world()


func _scenario_01_rack_to_draft() -> void:
	await _set_turn(GameState.Phase.TURN_PLAY)
	var src: Dictionary = _first_rack_tile_screen()
	var before_count: int = _count_non_empty(game_table.call("get_draft_slots"))
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no local rack tile hit"
	else:
		await _drag(src.get("screen", Vector2.ZERO) as Vector2, _screen_for_lane(0.34, 0.46))
		await _sync_world()
		var after_count: int = _count_non_empty(game_table.call("get_draft_slots"))
		ok = after_count > before_count
		note = "draft_count %d -> %d" % [before_count, after_count]
	await _capture("s01_rack_draft")
	_record(1, "rack_to_draft", ok, note)


func _scenario_02_draft_reorder() -> void:
	await _ensure_two_draft_tiles()
	await _set_turn(GameState.Phase.TURN_PLAY)
	var src: Dictionary = _first_draft_tile_screen()
	var before_slots: Array = (game_table.call("get_draft_slots") as Array).duplicate()
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no draft tile hit"
	else:
		await _drag(src.get("screen", Vector2.ZERO) as Vector2, _screen_for_lane(0.88, 0.74))
		await _sync_world()
		var after_slots: Array = game_table.call("get_draft_slots") as Array
		ok = _array_changed(before_slots, after_slots)
		note = "draft_slots_changed=%s" % str(ok)
	await _capture("s02_draft_reorder")
	_record(2, "draft_reorder", ok, note)


func _scenario_03_draft_to_rack() -> void:
	await _set_turn(GameState.Phase.TURN_PLAY)
	var src: Dictionary = _first_draft_tile_screen()
	var before_draft: int = _count_non_empty(game_table.call("get_draft_slots"))
	var before_rack: int = _count_non_empty(game_table.call("get_rack_slots"))
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no draft tile hit"
	else:
		await _drag(src.get("screen", Vector2.ZERO) as Vector2, _screen_for_rack_slot(true))
		await _sync_world()
		var after_draft: int = _count_non_empty(game_table.call("get_draft_slots"))
		var after_rack: int = _count_non_empty(game_table.call("get_rack_slots"))
		ok = after_draft < before_draft and after_rack >= before_rack
		note = "draft %d->%d rack %d->%d" % [before_draft, after_draft, before_rack, after_rack]
	await _capture("s03_draft_to_rack")
	_record(3, "draft_to_rack", ok, note)


func _scenario_04_starter_discard_drag() -> void:
	await _ensure_draft_empty()
	await _set_turn(GameState.Phase.STARTER_DISCARD)
	_ensure_local_hand_size(_rule_starter_tiles())
	game_table.set("_action_in_flight", false)
	await _sync_world()
	var src: Dictionary = _first_rack_tile_screen()
	var before: int = (controller.state.player_discard_stacks[0] as Array).size()
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no rack tile hit"
	else:
		await _drag(src.get("screen", Vector2.ZERO) as Vector2, _screen_for_discard(0))
		await _sync_world()
		var after: int = (controller.state.player_discard_stacks[0] as Array).size()
		ok = after == before + 1
		note = "discard_stack %d->%d phase=%d" % [before, after, int(controller.state.phase)]
	await _capture("s04_starter_discard")
	_record(4, "starter_discard_drag", ok, note)


func _scenario_05_turn_discard_drag() -> void:
	await _set_turn(GameState.Phase.TURN_DISCARD)
	var src: Dictionary = _first_rack_tile_screen()
	var before: int = (controller.state.player_discard_stacks[0] as Array).size()
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no rack tile hit"
	else:
		await _drag(src.get("screen", Vector2.ZERO) as Vector2, _screen_for_discard(0))
		await _sync_world()
		var after: int = (controller.state.player_discard_stacks[0] as Array).size()
		ok = after == before + 1
		note = "discard_stack %d->%d phase=%d" % [before, after, int(controller.state.phase)]
	await _capture("s05_turn_discard")
	_record(5, "turn_discard_drag", ok, note)


func _scenario_06_turn_play_end_then_discard_drag() -> void:
	await _ensure_draft_empty()
	await _set_turn(GameState.Phase.TURN_PLAY)
	controller.state.players[0].has_opened = true
	controller.state.players[0].opened_by_pairs = false
	await _sync_world()
	var src: Dictionary = _first_rack_tile_screen()
	var before: int = (controller.state.player_discard_stacks[0] as Array).size()
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no rack tile hit"
	else:
		await _drag(src.get("screen", Vector2.ZERO) as Vector2, _screen_for_discard(0))
		await _sync_world()
		var after: int = (controller.state.player_discard_stacks[0] as Array).size()
		ok = after == before + 1
		note = "discard_stack %d->%d phase=%d" % [before, after, int(controller.state.phase)]
	await _capture("s06_end_play_discard")
	_record(6, "turn_play_end_then_discard", ok, note)


func _scenario_07_rack_to_committed_meld() -> void:
	await _set_turn(GameState.Phase.TURN_PLAY)
	await _ensure_committed_meld()
	var src: Dictionary = _first_rack_tile_screen()
	var meld_hit: Dictionary = _first_table_meld_tile_screen()
	var before_size: int = 0
	if controller.state.table_melds.size() > 0:
		before_size = (controller.state.table_melds[0] as Meld).tiles.size()
	var ok: bool = false
	var note: String = ""
	if src.is_empty() or meld_hit.is_empty():
		note = "src_or_meld_hit_missing"
	else:
		var src_tid: int = int(src.get("tile_id", -1))
		await _drag(src.get("screen", Vector2.ZERO) as Vector2, meld_hit.get("screen", Vector2.ZERO) as Vector2)
		await _sync_world()
		var after_size: int = before_size
		if controller.state.table_melds.size() > 0:
			after_size = (controller.state.table_melds[0] as Meld).tiles.size()
		var invalid_tid: int = int(scene_root.get("_invalid_feedback_tile_id"))
		ok = after_size > before_size or invalid_tid == src_tid
		note = "meld_tiles %d->%d invalid_tid=%d" % [before_size, after_size, invalid_tid]
	await _capture("s07_add_to_meld")
	_record(7, "rack_to_committed_meld", ok, note)


func _scenario_08_draw_from_deck_tap() -> void:
	await _prepare_turn_draw_with_legal_hand()
	if controller.state.deck.is_empty():
		game_table.call("overlay_new_round")
		await _wait_frames(3)
		await _prepare_turn_draw_with_legal_hand()
	var before_hand: int = (controller.state.players[0].hand as Array).size()
	var draw_screen: Vector2 = _screen_for_draw_pick_area()
	await _tap(draw_screen)
	await _sync_world()
	var after_hand: int = (controller.state.players[0].hand as Array).size()
	var ok: bool = after_hand == before_hand + 1
	var note: String = "hand %d->%d phase=%d" % [before_hand, after_hand, int(controller.state.phase)]
	await _capture("s08_draw_from_deck")
	_record(8, "draw_from_deck_tap", ok, note)


func _scenario_09_take_discard_legal_tap() -> void:
	var prev_idx: int = await _prepare_legal_take_discard_state()
	var before_hand: int = (controller.state.players[0].hand as Array).size()
	var before_discard: int = (controller.state.discard_pile as Array).size()
	await _tap(_screen_for_discard_pick_area(prev_idx))
	await _sync_world()
	var after_hand: int = (controller.state.players[0].hand as Array).size()
	var after_discard: int = (controller.state.discard_pile as Array).size()
	var ok: bool = after_hand == before_hand + 1 and after_discard == maxi(0, before_discard - 1)
	var note: String = "hand %d->%d discard_size=%d->%d phase=%d" % [
		before_hand, after_hand, before_discard, after_discard, int(controller.state.phase)
	]
	await _capture("s09_take_discard")
	_record(9, "take_discard_legal_tap", ok, note)


func _scenario_10_turn_play_tap_selected_tile_to_draft_noop() -> void:
	await _ensure_draft_empty()
	await _set_turn(GameState.Phase.TURN_PLAY)
	var src: Dictionary = _first_rack_tile_screen()
	var before_draft: Array = (game_table.call("get_draft_slots") as Array).duplicate()
	var before_discard: int = (controller.state.player_discard_stacks[0] as Array).size()
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no rack tile hit"
	else:
		await _tap(src.get("screen", Vector2.ZERO) as Vector2)
		await _wait_frames(1)
		await _tap(_screen_for_lane(0.65, 0.42))
		await _sync_world()
		var after_draft: Array = game_table.call("get_draft_slots") as Array
		var after_discard: int = (controller.state.player_discard_stacks[0] as Array).size()
		ok = not _array_changed(before_draft, after_draft) and after_discard == before_discard
		note = "draft_unchanged=%s discard=%d->%d" % [str(not _array_changed(before_draft, after_draft)), before_discard, after_discard]
	await _capture("s10_tap_no_draft_place")
	_record(10, "turn_play_tap_selected_tile_to_draft_noop", ok, note)


func _scenario_11_turn_discard_tap_selected_tile_to_discard_noop() -> void:
	await _set_turn(GameState.Phase.TURN_DISCARD)
	var src: Dictionary = _first_rack_tile_screen()
	var before_discard: int = (controller.state.player_discard_stacks[0] as Array).size()
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no rack tile hit"
	else:
		await _tap(src.get("screen", Vector2.ZERO) as Vector2)
		await _wait_frames(1)
		await _tap(_screen_for_discard_pick_area(0))
		await _sync_world()
		var after_discard: int = (controller.state.player_discard_stacks[0] as Array).size()
		ok = after_discard == before_discard
		note = "discard_stack %d->%d" % [before_discard, after_discard]
	await _capture("s11_tap_no_discard")
	_record(11, "turn_discard_tap_selected_tile_to_discard_noop", ok, note)


func _scenario_12_committed_meld_reposition_drag() -> void:
	await _set_turn(GameState.Phase.TURN_PLAY)
	await _ensure_draft_empty()
	await _ensure_committed_meld()
	var before_offsets: Dictionary = (scene_root.get("_table_meld_drag_offsets") as Dictionary).duplicate(true)
	var meld_hit: Dictionary = _first_table_meld_tile_screen()
	var ok: bool = false
	var note: String = ""
	if meld_hit.is_empty():
		note = "no committed meld tile hit"
	else:
		await _drag(meld_hit.get("screen", Vector2.ZERO) as Vector2, _screen_for_lane(0.62, 0.58))
		await _sync_world()
		var after_offsets: Dictionary = scene_root.get("_table_meld_drag_offsets") as Dictionary
		var moved: bool = false
		for k in after_offsets.keys():
			var v: Vector2 = after_offsets[k] as Vector2
			if v.length() > 0.001:
				moved = true
				break
		ok = moved and (before_offsets.size() != after_offsets.size() or before_offsets != after_offsets)
		note = "offsets_before=%d offsets_after=%d moved=%s" % [before_offsets.size(), after_offsets.size(), str(moved)]
	await _capture("s12_committed_meld_reposition")
	_record(12, "committed_meld_reposition_drag", ok, note)


func _scenario_13_round_end_click_new_round() -> void:
	controller.state.phase = GameState.Phase.ROUND_END
	controller.state.current_player_index = 0
	await _sync_world()
	await _tap(Vector2(64, 64))
	await _wait_frames(3)
	var phase_now: int = int(controller.state.phase)
	var ok: bool = phase_now != int(GameState.Phase.ROUND_END)
	var note: String = "phase_after_click=%d" % phase_now
	await _capture("s13_round_end_click")
	_record(13, "round_end_click_new_round", ok, note)


