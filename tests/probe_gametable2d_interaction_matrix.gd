extends SceneTree

const OKEY_TILE_SCRIPT: Script = preload("res://ui/widgets/OkeyTile.gd")

var table: Control = null
var controller = null
var failures: int = 0
var passes: int = 0
var _uid_seed: int = 1900000


func _init() -> void:
	await _run()


func _run() -> void:
	var ps := load("res://ui/GameTable.tscn") as PackedScene
	if ps == null:
		print("FATAL: missing GameTable scene")
		quit(1)
		return
	table = ps.instantiate() as Control
	root.add_child(table)
	await _wait_frames(8)

	controller = table.call("get_controller")
	if controller == null or controller.state == null:
		print("FATAL: controller/state missing")
		quit(1)
		return

	# Keep deterministic scripted state.
	table.set("_bot_loop_running", true)
	await _reset_round()

	await _scenario_01_rack_to_draft()
	await _scenario_02_draft_reorder()
	await _scenario_03_draft_to_rack()
	await _scenario_04_rack_to_committed_meld()
	await _scenario_05_starter_discard_drag()
	await _scenario_06_turn_discard_drag()
	await _scenario_07_turn_play_end_then_discard_drag()
	await _scenario_08_drop_outside_valid_zones_noop()
	await _scenario_09_targeted_tap_no_placement_no_discard()

	print("SCENARIO_SUMMARY_2D: pass=%d fail=%d" % [passes, failures])
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
	if table != null and is_instance_valid(table):
		if table.get_parent() != null:
			table.get_parent().remove_child(table)
		table.free()
		table = null
	_free_test_instances()
	await _wait_frames(10)
	quit(exit_code)


func _sync_table() -> void:
	if table == null or not is_instance_valid(table):
		return
	table.call("_render_all")
	await _wait_frames(3)


func _reset_round() -> void:
	if table == null or not is_instance_valid(table):
		return
	table.call("overlay_new_round")
	await _wait_frames(4)
	await _sync_table()


func _set_turn(phase_value: int) -> void:
	var s = controller.state
	s.current_player_index = 0
	s.phase = phase_value
	s.turn_required_use_tile_id = -1
	table.set("_action_in_flight", false)
	await _sync_table()


func _record(idx: int, name: String, ok: bool, note: String) -> void:
	if ok:
		passes += 1
		print("SCENARIO2D_%02d_%s:PASS %s" % [idx, name, note])
	else:
		failures += 1
		print("SCENARIO2D_%02d_%s:FAIL %s" % [idx, name, note])


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


func _array_equal(a: Array, b: Array) -> bool:
	return not _array_changed(a, b)


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
		var draft_slots: Array = table.call("get_draft_slots")
		var from_draft: int = -1
		for i in range(draft_slots.size()):
			if int(draft_slots[i]) != -1:
				from_draft = i
				break
		if from_draft == -1:
			break
		var rack_slots: Array = table.call("get_rack_slots")
		var to_rack: int = rack_slots.find(-1)
		if to_rack == -1:
			break
		table.call("overlay_move_draft_to_rack", from_draft, to_rack)
		await _sync_table()


func _ensure_two_draft_tiles() -> void:
	var tries: int = 0
	while _count_non_empty(table.call("get_draft_slots")) < 2 and tries < 4:
		tries += 1
		await _set_turn(GameState.Phase.TURN_PLAY)
		var src: Dictionary = _first_rack_tile()
		if src.is_empty():
			break
		await _drag_tile_to(src.get("tile"), _draft_target(0.18 + 0.18 * float(tries), 0.45))
		await _sync_table()


func _first_rack_tile() -> Dictionary:
	var rack_slots: Array = table.call("get_rack_slots")
	var slot_controls: Array = table.get("_slot_controls")
	for i in range(mini(rack_slots.size(), slot_controls.size())):
		var tile_id: int = int(rack_slots[i])
		if tile_id == -1:
			continue
		var slot_ctrl: Control = slot_controls[i] as Control
		if slot_ctrl == null:
			continue
		for child in slot_ctrl.get_children():
			if child.get_script() != OKEY_TILE_SCRIPT:
				continue
			return {
				"tile": child,
				"slot": i,
				"tile_id": tile_id,
				"screen": slot_ctrl.get_global_rect().get_center(),
			}
	return {}


func _find_rack_tile_by_id(tile_id: int) -> Dictionary:
	var rack_slots: Array = table.call("get_rack_slots")
	var slot_controls: Array = table.get("_slot_controls")
	for i in range(mini(rack_slots.size(), slot_controls.size())):
		if int(rack_slots[i]) != tile_id:
			continue
		var slot_ctrl: Control = slot_controls[i] as Control
		if slot_ctrl == null:
			continue
		for child in slot_ctrl.get_children():
			if child.get_script() != OKEY_TILE_SCRIPT:
				continue
			return {
				"tile": child,
				"slot": i,
				"tile_id": tile_id,
				"screen": slot_ctrl.get_global_rect().get_center(),
			}
	return {}


func _first_draft_tile() -> Dictionary:
	var draft_slots: Array = table.call("get_draft_slots")
	var draft_controls: Array = table.get("_draft_slot_controls")
	if draft_controls.is_empty():
		draft_controls = table.get("_stage_slot_controls")
	for i in range(mini(draft_slots.size(), draft_controls.size())):
		var tile_id: int = int(draft_slots[i])
		if tile_id == -1:
			continue
		var slot_ctrl: Control = draft_controls[i] as Control
		if slot_ctrl == null:
			continue
		for child in slot_ctrl.get_children():
			if child.get_script() != OKEY_TILE_SCRIPT:
				continue
			return {
				"tile": child,
				"slot": i,
				"tile_id": tile_id,
				"screen": slot_ctrl.get_global_rect().get_center(),
			}
	return {}


func _first_empty_rack_slot_center() -> Dictionary:
	var rack_slots: Array = table.call("get_rack_slots")
	var slot_controls: Array = table.get("_slot_controls")
	for i in range(mini(rack_slots.size(), slot_controls.size())):
		if int(rack_slots[i]) != -1:
			continue
		var slot_ctrl: Control = slot_controls[i] as Control
		if slot_ctrl == null:
			continue
		return {"slot": i, "screen": slot_ctrl.get_global_rect().get_center()}
	if slot_controls.size() > 0:
		var first_ctrl: Control = slot_controls[0] as Control
		if first_ctrl != null:
			return {"slot": 0, "screen": first_ctrl.get_global_rect().get_center()}
	return {"slot": -1, "screen": Vector2.ZERO}


func _draft_target(px: float, py: float) -> Vector2:
	var island: Control = table.get("_meld_island") as Control
	if island == null:
		return Vector2(640, 360)
	var rect: Rect2 = island.get_global_rect()
	return rect.position + Vector2(rect.size.x * px, rect.size.y * py)


func _discard_target() -> Vector2:
	var discard_panel: Control = table.get("_my_discard") as Control
	if discard_panel == null:
		return Vector2(920, 560)
	return discard_panel.get_global_rect().get_center()


func _outside_target() -> Vector2:
	return Vector2(-500.0, -500.0)


func _first_meld_cluster_center() -> Vector2:
	var clusters: Array = table.get("_meld_clusters")
	if clusters.is_empty():
		return Vector2.ZERO
	var cluster: Control = clusters[0] as Control
	if cluster == null:
		return Vector2.ZERO
	return cluster.get_global_rect().get_center()


func _drag_tile_to(tile_ctrl, global_target: Vector2) -> void:
	if tile_ctrl == null:
		return
	table.call("_on_tile_drag_started", tile_ctrl)
	table.call("_on_tile_drag_ended", tile_ctrl, global_target)
	await _wait_frames(2)


func _tap_tile(tile_ctrl) -> void:
	if tile_ctrl == null:
		return
	table.call("_on_tile_clicked", tile_ctrl)
	await _wait_frames(1)


func _scenario_01_rack_to_draft() -> void:
	await _reset_round()
	await _set_turn(GameState.Phase.TURN_PLAY)
	await _ensure_draft_empty()
	var src: Dictionary = _first_rack_tile()
	var before_count: int = _count_non_empty(table.call("get_draft_slots"))
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no rack tile"
	else:
		await _drag_tile_to(src.get("tile"), _draft_target(0.34, 0.46))
		await _sync_table()
		var after_count: int = _count_non_empty(table.call("get_draft_slots"))
		ok = after_count > before_count
		note = "draft_count %d->%d" % [before_count, after_count]
	_record(1, "rack_to_draft", ok, note)


func _scenario_02_draft_reorder() -> void:
	await _reset_round()
	await _set_turn(GameState.Phase.TURN_PLAY)
	await _ensure_two_draft_tiles()
	var src: Dictionary = _first_draft_tile()
	var before_slots: Array = (table.call("get_draft_slots") as Array).duplicate()
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no draft tile"
	else:
		await _drag_tile_to(src.get("tile"), _draft_target(0.86, 0.72))
		await _sync_table()
		var after_slots: Array = table.call("get_draft_slots") as Array
		ok = _array_changed(before_slots, after_slots)
		note = "draft_changed=%s" % str(ok)
	_record(2, "draft_reorder", ok, note)


func _scenario_03_draft_to_rack() -> void:
	await _reset_round()
	await _set_turn(GameState.Phase.TURN_PLAY)
	await _ensure_two_draft_tiles()
	var src: Dictionary = _first_draft_tile()
	var dest: Dictionary = _first_empty_rack_slot_center()
	var before_draft: int = _count_non_empty(table.call("get_draft_slots"))
	var before_rack: int = _count_non_empty(table.call("get_rack_slots"))
	var ok: bool = false
	var note: String = ""
	if src.is_empty() or int(dest.get("slot", -1)) == -1:
		note = "draft_or_dest_missing"
	else:
		await _drag_tile_to(src.get("tile"), dest.get("screen", Vector2.ZERO) as Vector2)
		await _sync_table()
		var after_draft: int = _count_non_empty(table.call("get_draft_slots"))
		var after_rack: int = _count_non_empty(table.call("get_rack_slots"))
		ok = after_draft < before_draft and after_rack >= before_rack
		note = "draft %d->%d rack %d->%d" % [before_draft, after_draft, before_rack, after_rack]
	_record(3, "draft_to_rack", ok, note)


func _scenario_04_rack_to_committed_meld() -> void:
	await _reset_round()
	await _set_turn(GameState.Phase.TURN_PLAY)
	await _ensure_draft_empty()
	var s = controller.state
	s.players[0].has_opened = true
	s.players[0].opened_by_pairs = false
	var m5 := Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, _alloc_uid())
	var m6 := Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, _alloc_uid())
	var m7 := Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, _alloc_uid())
	s.table_melds = [Meld.new(Meld.Kind.RUN, [m5.unique_id, m6.unique_id, m7.unique_id], [m5, m6, m7], 1)]
	var fit_tile := Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, _alloc_uid())
	var hand: Array = (s.players[0].hand as Array).duplicate()
	if hand.is_empty():
		hand.append(fit_tile)
	else:
		hand[0] = fit_tile
	s.players[0].hand = hand
	await _sync_table()
	var src: Dictionary = _find_rack_tile_by_id(fit_tile.unique_id)
	var meld_center: Vector2 = _first_meld_cluster_center()
	var before_size: int = ((controller.state.table_melds[0] as Meld).tiles as Array).size()
	var ok: bool = false
	var note: String = ""
	if src.is_empty() or meld_center == Vector2.ZERO:
		note = "src_or_meld_missing"
	else:
		await _drag_tile_to(src.get("tile"), meld_center)
		await _sync_table()
		var after_size: int = ((controller.state.table_melds[0] as Meld).tiles as Array).size()
		ok = after_size == before_size + 1
		note = "meld_tiles %d->%d" % [before_size, after_size]
	_record(4, "rack_to_committed_meld", ok, note)


func _scenario_05_starter_discard_drag() -> void:
	await _reset_round()
	await _set_turn(GameState.Phase.STARTER_DISCARD)
	_ensure_local_hand_size(_rule_starter_tiles())
	await _sync_table()
	var src: Dictionary = _first_rack_tile()
	var before: int = (controller.state.player_discard_stacks[0] as Array).size()
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no rack tile"
	else:
		await _drag_tile_to(src.get("tile"), _discard_target())
		await _sync_table()
		var after: int = (controller.state.player_discard_stacks[0] as Array).size()
		ok = after == before + 1
		note = "discard_stack %d->%d phase=%d" % [before, after, int(controller.state.phase)]
	_record(5, "starter_discard_drag", ok, note)


func _scenario_06_turn_discard_drag() -> void:
	await _reset_round()
	await _set_turn(GameState.Phase.TURN_DISCARD)
	var src: Dictionary = _first_rack_tile()
	var before: int = (controller.state.player_discard_stacks[0] as Array).size()
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no rack tile"
	else:
		await _drag_tile_to(src.get("tile"), _discard_target())
		await _sync_table()
		var after: int = (controller.state.player_discard_stacks[0] as Array).size()
		ok = after == before + 1
		note = "discard_stack %d->%d phase=%d" % [before, after, int(controller.state.phase)]
	_record(6, "turn_discard_drag", ok, note)


func _scenario_07_turn_play_end_then_discard_drag() -> void:
	await _reset_round()
	await _set_turn(GameState.Phase.TURN_PLAY)
	await _ensure_draft_empty()
	controller.state.players[0].has_opened = true
	controller.state.players[0].opened_by_pairs = false
	await _sync_table()
	var src: Dictionary = _first_rack_tile()
	var before: int = (controller.state.player_discard_stacks[0] as Array).size()
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no rack tile"
	else:
		await _drag_tile_to(src.get("tile"), _discard_target())
		await _sync_table()
		var after: int = (controller.state.player_discard_stacks[0] as Array).size()
		ok = after == before + 1
		note = "discard_stack %d->%d phase=%d" % [before, after, int(controller.state.phase)]
	_record(7, "turn_play_end_then_discard_drag", ok, note)


func _scenario_08_drop_outside_valid_zones_noop() -> void:
	await _reset_round()
	await _set_turn(GameState.Phase.TURN_PLAY)
	await _ensure_draft_empty()
	var src: Dictionary = _first_rack_tile()
	var before_rack: Array = (table.call("get_rack_slots") as Array).duplicate()
	var before_draft: Array = (table.call("get_draft_slots") as Array).duplicate()
	var before_discard: int = (controller.state.player_discard_stacks[0] as Array).size()
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no rack tile"
	else:
		await _drag_tile_to(src.get("tile"), _outside_target())
		await _sync_table()
		var after_rack: Array = table.call("get_rack_slots") as Array
		var after_draft: Array = table.call("get_draft_slots") as Array
		var after_discard: int = (controller.state.player_discard_stacks[0] as Array).size()
		ok = _array_equal(before_rack, after_rack) and _array_equal(before_draft, after_draft) and after_discard == before_discard
		note = "rack_unchanged=%s draft_unchanged=%s discard=%d->%d" % [
			str(_array_equal(before_rack, after_rack)),
			str(_array_equal(before_draft, after_draft)),
			before_discard,
			after_discard,
		]
	_record(8, "drop_outside_valid_zones_noop", ok, note)


func _scenario_09_targeted_tap_no_placement_no_discard() -> void:
	await _reset_round()
	await _set_turn(GameState.Phase.TURN_DISCARD)
	await _ensure_draft_empty()
	var src: Dictionary = _first_rack_tile()
	var before_rack: Array = (table.call("get_rack_slots") as Array).duplicate()
	var before_draft: Array = (table.call("get_draft_slots") as Array).duplicate()
	var before_discard: int = (controller.state.player_discard_stacks[0] as Array).size()
	var ok: bool = false
	var note: String = ""
	if src.is_empty():
		note = "no rack tile"
	else:
		await _tap_tile(src.get("tile"))
		var tap := InputEventMouseButton.new()
		tap.button_index = MOUSE_BUTTON_LEFT
		tap.pressed = true
		table.call("_on_my_discard_input", tap)
		await _sync_table()
		var after_rack: Array = table.call("get_rack_slots") as Array
		var after_draft: Array = table.call("get_draft_slots") as Array
		var after_discard: int = (controller.state.player_discard_stacks[0] as Array).size()
		var selected_id: int = int(table.get("_slots").last_tile_id)
		ok = _array_equal(before_rack, after_rack) \
			and _array_equal(before_draft, after_draft) \
			and after_discard == before_discard \
			and selected_id == int(src.get("tile_id", -1))
		note = "rack/draft unchanged, discard %d->%d selected=%d" % [before_discard, after_discard, selected_id]
	_record(9, "targeted_tap_no_placement_no_discard", ok, note)

