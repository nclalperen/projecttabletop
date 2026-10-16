extends RefCounted

const MELD_OVERLAY_SCRIPT = preload("res://ui/game_table/MeldInspectionOverlay.gd")
const RACK_NAVIGATOR_SCRIPT = preload("res://ui/game_table/RackFocusNavigator.gd")
const TABLE_AUDIO_SCRIPT = preload("res://ui/game_table/TableAudioController.gd")
const ROUND_SUMMARY_SCENE = preload("res://ui/game_table/OkeyRoundSummaryModal.tscn")
const HUD_SCENE = preload("res://ui/game_table/OkeyPlayHUD.tscn")
const RACK_VIEW_3D_SCRIPT = preload("res://ui/game_table/RackView3D.gd")
const DRAFT_WORKSPACE_VIEW_3D_SCRIPT = preload("res://ui/game_table/DraftWorkspaceView3D.gd")
const PLACEHOLDER_TABLE_SCENE = preload("res://ui/PlaceholderTable.tscn")
const GAME_CATALOG = preload("res://gd/config/TabletopGameCatalog.gd")

func run() -> bool:
	if not _test_meld_inspection_overlay():
		push_error("test_meld_inspection_overlay failed")
		return false
	if not _test_rack_focus_navigator():
		push_error("test_rack_focus_navigator failed")
		return false
	if not _test_table_audio_controller():
		push_error("test_table_audio_controller failed")
		return false
	if not _test_okey_round_summary_modal():
		push_error("test_okey_round_summary_modal failed")
		return false
	if not _test_hud_phase5_integration():
		push_error("test_hud_phase5_integration failed")
		return false
	if not _test_rack_and_draft_view_3d():
		push_error("test_rack_and_draft_view_3d failed")
		return false
	if not _test_placeholder_table_3d_and_badges():
		push_error("test_placeholder_table_3d_and_badges failed")
		return false
	print("  PASS  test_phase5_polish_subsystems")
	return true

func _test_meld_inspection_overlay() -> bool:
	var overlay = MELD_OVERLAY_SCRIPT.new()
	if overlay.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		push_error("MeldInspectionOverlay should ignore mouse input")
		overlay.free()
		return false

	var dummy_melds: Array = [
		{"meld_id": 0, "center_world_pos": Vector3(0.1, 0.0, 0.2), "summary_text": "Run (4)"},
		{"meld_id": 1, "center_world_pos": Vector3(-0.1, 0.0, 0.2), "summary_text": "Set (3)"}
	]
	overlay.sync_meld_groups(dummy_melds, [1])

	if overlay.get_pill_count() != 2:
		push_error("Expected 2 meld pills, got %d" % overlay.get_pill_count())
		overlay.free()
		return false

	var pill0 = overlay.get_child(0) as PanelContainer
	var pill1 = overlay.get_child(1) as PanelContainer
	if pill0 == null or pill1 == null:
		push_error("Meld pill children missing or not PanelContainer")
		overlay.free()
		return false

	if pill0.theme_type_variation != &"HUDGlassPanel":
		push_error("Meld 0 should have HUDGlassPanel variation")
		overlay.free()
		return false

	if pill1.theme_type_variation != &"DraftPillReady":
		push_error("Meld 1 should have DraftPillReady variation as valid target")
		overlay.free()
		return false

	# Test camera projection step
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 1.0, 1.0)
	if tree != null and tree.root != null:
		tree.root.add_child(cam)
		tree.root.add_child(overlay)
	overlay.camera = cam
	overlay._process(0.016)

	if cam.get_parent() != null:
		cam.get_parent().remove_child(cam)
	if overlay.get_parent() != null:
		overlay.get_parent().remove_child(overlay)
	cam.free()
	overlay.free()
	return true

func _test_rack_focus_navigator() -> bool:
	var nav = RACK_NAVIGATOR_SCRIPT.new()
	if nav.active_zone != &"RACK" or nav.active_slot != 0:
		push_error("Initial navigator focus should be RACK slot 0")
		nav.free()
		return false

	# Step horizontal right
	nav._step_horizontal(1)
	if nav.active_slot != 1:
		push_error("Expected active_slot 1 after right step")
		nav.free()
		return false

	# Step horizontal wrap left
	nav._step_horizontal(-2)
	if nav.active_slot != 14:
		push_error("Expected active_slot 14 after wrap left")
		nav.free()
		return false

	# Step vertical down to bottom rack row
	nav._step_vertical(1)
	if nav.active_slot != 29:
		push_error("Expected active_slot 29 on bottom rack row")
		nav.free()
		return false

	# Step vertical up to top rack row
	nav._step_vertical(-1)
	if nav.active_slot != 14:
		push_error("Expected active_slot 14 on top rack row")
		nav.free()
		return false

	# Step vertical up into DRAFT zone
	nav._step_vertical(-1)
	if nav.active_zone != &"DRAFT" or nav.active_slot != 14:
		push_error("Expected focus to transition to DRAFT zone")
		nav.free()
		return false

	# Step vertical up into TABLE_MELDS zone
	nav._step_vertical(-1)
	if nav.active_zone != &"TABLE_MELDS":
		push_error("Expected focus to transition to TABLE_MELDS zone")
		nav.free()
		return false

	# Test virtual tile pick & drop actions
	nav.set_focus(&"RACK", 5)
	var tracker := {
		"picked_zone": &"",
		"picked_slot": -1,
		"dropped_zone": &"",
		"dropped_slot": -1
	}

	nav.virtual_tile_picked.connect(func(z, s):
		tracker["picked_zone"] = z
		tracker["picked_slot"] = s
	)
	nav.virtual_tile_dropped.connect(func(z, s):
		tracker["dropped_zone"] = z
		tracker["dropped_slot"] = s
	)

	nav._handle_accept()
	if not nav.is_holding_tile() or tracker["picked_zone"] != &"RACK" or tracker["picked_slot"] != 5:
		push_error("Failed to pick virtual tile at RACK slot 5")
		nav.free()
		return false

	nav.set_focus(&"DRAFT", 2)
	nav._handle_accept()
	if nav.is_holding_tile() or tracker["dropped_zone"] != &"DRAFT" or tracker["dropped_slot"] != 2:
		push_error("Failed to drop virtual tile at DRAFT slot 2")
		nav.free()
		return false

	# Test visualizer focus reticle
	var tdv = preload("res://ui/game_table/TileDragVisualizer3D.gd").new()
	tdv.show_focus_reticle(Vector3(0.1, 0.0, 0.2), Vector3(-90, 0, 0))
	if not tdv.is_focus_reticle_visible():
		push_error("Focus reticle should be visible")
		tdv.free()
		nav.free()
		return false
	tdv.hide_focus_reticle()
	if tdv.is_focus_reticle_visible():
		push_error("Focus reticle should be hidden")
		tdv.free()
		nav.free()
		return false
	tdv.free()

	nav.free()
	return true

func _test_table_audio_controller() -> bool:
	var tac = TABLE_AUDIO_SCRIPT.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(tac)
	else:
		tac._ready()

	if tac.get_pool_size() != 6:
		push_error("Expected AudioStreamPlayer pool size 6, got %d" % tac.get_pool_size())
		tac.queue_free()
		return false

	tac.on_tile_picked()
	tac.on_tile_hovered_slot_changed()
	tac.on_tile_snapped_to_rack()
	tac.on_tile_discarded()
	tac.on_melds_committed()
	tac.on_invalid_action()

	if tac.get_parent() != null:
		tac.get_parent().remove_child(tac)
	tac.free()
	return true

func _test_okey_round_summary_modal() -> bool:
	var modal = ROUND_SUMMARY_SCENE.instantiate()
	if modal == null:
		push_error("Failed to instantiate OkeyRoundSummaryModal.tscn")
		return false

	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(modal)

	var dummy_state = {
		"winner_player_index": 0,
		"round_end_reason": "Normal finish by completing hand",
		"players": [
			{"has_opened": true, "opened_by_pairs": false, "hand_value": 0, "penalty_points": 0, "score_total": -101},
			{"has_opened": false, "opened_by_pairs": false, "hand_value": 85, "penalty_points": 0, "score_total": 85},
			{"has_opened": true, "opened_by_pairs": true, "hand_value": 30, "penalty_points": 101, "score_total": 131},
			{"has_opened": false, "opened_by_pairs": false, "hand_value": 60, "penalty_points": 0, "score_total": 60}
		]
	}

	# Round complete
	modal.display_summary(dummy_state, false)
	if not modal.visible:
		push_error("Modal should be visible after display_summary")
		_cleanup(modal)
		return false

	if modal.modal_title.text != "ROUND COMPLETE":
		push_error("Expected ROUND COMPLETE title, got '%s'" % modal.modal_title.text)
		_cleanup(modal)
		return false

	if not modal.next_round_btn.visible:
		push_error("Next round button should be visible when match is not finished")
		_cleanup(modal)
		return false

	# 5 column headers + 4 players * 5 columns = 25 children in ScoreGrid
	if modal.score_grid.get_child_count() != 25:
		push_error("Expected 25 score grid children (5 headers + 20 cells), got %d" % modal.score_grid.get_child_count())
		_cleanup(modal)
		return false

	# Match complete
	modal.display_summary(dummy_state, true)
	if modal.modal_title.text != "MATCH COMPLETE":
		push_error("Expected MATCH COMPLETE title, got '%s'" % modal.modal_title.text)
		_cleanup(modal)
		return false

	if modal.next_round_btn.visible:
		push_error("Next round button should be hidden when match is complete")
		_cleanup(modal)
		return false

	# Signal emission
	var modal_tracker := {"next": false, "menu": false}
	modal.next_round_requested.connect(func(): modal_tracker["next"] = true)
	modal.main_menu_requested.connect(func(): modal_tracker["menu"] = true)

	modal.next_round_btn.pressed.emit()
	modal.menu_btn.pressed.emit()

	if not modal_tracker["next"] or not modal_tracker["menu"]:
		push_error("Modal button signals not emitted")
		_cleanup(modal)
		return false

	modal.close()
	if modal.visible:
		push_error("Modal should be hidden after close()")
		_cleanup(modal)
		return false

	_cleanup(modal)
	return true

func _test_hud_phase5_integration() -> bool:
	var hud = HUD_SCENE.instantiate()
	if hud == null:
		push_error("Failed to instantiate OkeyPlayHUD.tscn")
		return false

	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(hud)

	hud._ensure_nodes()
	if hud.round_summary_modal == null:
		push_error("OkeyPlayHUD missing round_summary_modal reference")
		_cleanup(hud)
		return false

	if hud.meld_inspection_overlay == null:
		push_error("OkeyPlayHUD missing meld_inspection_overlay reference")
		_cleanup(hud)
		return false

	if hud.is_modal_open():
		push_error("HUD modal should be closed initially")
		_cleanup(hud)
		return false

	var dummy_state = {
		"match_finished": false,
		"winner_player_index": 0,
		"round_end_reason": "Game ended normally",
		"players": [
			{"has_opened": true, "opened_by_pairs": false, "hand_value": 0, "penalty_points": 0, "score_total": -101}
		]
	}
	hud._show_results(dummy_state)

	if not hud.is_modal_open():
		push_error("HUD should report is_modal_open() == true after _show_results")
		_cleanup(hud)
		return false

	if not hud.round_summary_modal.visible:
		push_error("HUD round_summary_modal should be visible after _show_results")
		_cleanup(hud)
		return false

	hud._close_modal()
	if hud.is_modal_open():
		push_error("HUD modal should be closed after _close_modal")
		_cleanup(hud)
		return false

	_cleanup(hud)
	return true

func _test_rack_and_draft_view_3d() -> bool:
	var rack_view = RACK_VIEW_3D_SCRIPT.new()
	rack_view.configure_rows(Vector3(0.0, 0.086, -0.033), Vector3(0.0, 0.047, 0.039), -35.0, -32.0, 0.75)
	var pos0: Vector3 = rack_view.compute_slot_local_position(0)
	var pos14: Vector3 = rack_view.compute_slot_local_position(14)
	var pos15: Vector3 = rack_view.compute_slot_local_position(15)
	if pos0.x >= pos14.x or pos0.y <= pos15.y:
		push_error("RackView3D slot positions invalid: slot0=%s slot14=%s slot15=%s" % [str(pos0), str(pos14), str(pos15)])
		rack_view.free()
		return false
	if absf(rack_view.get_slot_row_tilt_deg(0) - (-35.0)) > 0.01 or absf(rack_view.get_slot_row_tilt_deg(15) - (-32.0)) > 0.01:
		push_error("RackView3D row tilt mismatch")
		rack_view.free()
		return false
	var slots: Array = []
	for i in range(30):
		slots.append(100 + i if i < 5 else -1)
	var reflow: Dictionary = rack_view.compute_neighbor_reflow_offsets(slots, 0, 2)
	if reflow.is_empty():
		push_error("Expected non-empty neighbor reflow offsets when hovering occupied rack slot")
		rack_view.free()
		return false
	rack_view.free()

	var draft_view = DRAFT_WORKSPACE_VIEW_3D_SCRIPT.new()
	draft_view.configure_lane(Rect2(Vector2(-0.33, 0.11), Vector2(0.66, 0.15)), 24, 12)
	var pt3: Vector2 = draft_view.slot_to_table_point(3)
	var nearest: int = draft_view.point_to_nearest_slot(pt3)
	if nearest != 3:
		push_error("DraftWorkspaceView3D expected nearest slot 3, got %d" % nearest)
		draft_view.free()
		return false
	var world3: Vector3 = draft_view.slot_to_world_position(3)
	if absf(world3.x - pt3.x) > 0.001 or absf(world3.z - pt3.y) > 0.001:
		push_error("DraftWorkspaceView3D world position mismatch")
		draft_view.free()
		return false
	draft_view.free()
	return true

func _test_placeholder_table_3d_and_badges() -> bool:
	var table = PLACEHOLDER_TABLE_SCENE.instantiate()
	if table == null:
		push_error("Failed to instantiate PlaceholderTable.tscn")
		return false
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(table)
	else:
		table._ready()

	table.configure_table(GAME_CATALOG.GAME_POKER, {}, "local_puid", {}, "match_poker", 77)
	var env3d = table.get_table_environment_3d()
	if env3d == null or env3d.get_seat_anchor_count() != 6:
		push_error("PlaceholderTable Poker should have TableEnvironment3D with 6 seat anchors")
		_cleanup(table)
		return false
	if table.get_seat_badges().size() != 6:
		push_error("PlaceholderTable Poker should instantiate 6 PlayerSeatBadge widgets, got %d" % table.get_seat_badges().size())
		_cleanup(table)
		return false

	table.configure_table(GAME_CATALOG.GAME_BACKGAMMON, {}, "local_puid", {}, "match_bg", 88)
	if env3d.get_seat_anchor_count() != 2 or table.get_seat_badges().size() != 2:
		push_error("PlaceholderTable Backgammon should update to 2 seat anchors and 2 PlayerSeatBadge widgets")
		_cleanup(table)
		return false

	# Test Backgammon simulated dice action
	var bg_res = table.simulate_game_action()
	if str(bg_res.get("action")) != "roll_dice" or not bg_res.has("dice"):
		push_error("Backgammon simulation should produce roll_dice with dice array")
		_cleanup(table)
		return false
	if table.get_active_seat_index() != 1:
		push_error("Turn should advance to seat 1 after roll")
		_cleanup(table)
		return false

	# Test Blackjack simulated deal action
	table.configure_table(GAME_CATALOG.GAME_BLACKJACK, {}, "local_puid", {}, "match_bj", 99)
	var bj_res = table.simulate_game_action()
	if str(bj_res.get("action")) != "deal_card":
		push_error("Blackjack simulation should produce deal_card action")
		_cleanup(table)
		return false

	_cleanup(table)
	return true

func _cleanup(node: Node) -> void:
	if node != null:
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.free()
