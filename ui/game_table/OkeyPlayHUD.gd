class_name OkeyPlayHUD
extends CanvasLayer

signal draw_tile_requested
signal take_discard_requested
signal commit_melds_requested
signal discard_selected_requested
signal sort_requested(mode: StringName)
signal undo_requested
signal return_draft_requested
signal camera_toggle_requested
signal back_to_hub_requested

var board: Node = null
var _session: Node = null
var _bound_session: Node = null
var _meter_tween: Tween = null
var _toast_tween: Tween = null
var _last_selected_tile_id: int = -1

var safe_area_root: MarginContainer
var indicator_tile_view: Control
var indicator_label: Label
var facts_label: Label
var draft_meter_pill: PanelContainer
var draft_points_label: Label
var draft_progress_bar: ProgressBar
var commit_melds_btn: Button
var draw_btn: Button
var take_discard_btn: Button
var discard_btn: Button
var undo_btn: Button
var return_draft_btn: Button
var sort_color_btn: Button
var sort_number_btn: Button
var back_to_hub_btn: Button
var camera_toggle_btn: Button
var melds_btn: Button
var help_guide_btn: Button
var instruction_label: Label
var feedback_toast: PanelContainer
var feedback_label: Label
var modal_overlay: ColorRect
var modal_title: Label
var modal_body: VBoxContainer
var _modal_body: VBoxContainer
var modal_close_btn: Button
var round_summary_modal: Control = null
var meld_inspection_overlay: Control = null
var seat_badges: Array[Node] = []

const COLOR_NAMES: Array[String] = ["Red", "Orange", "Blue", "Black"]

func _ensure_nodes() -> void:
	if round_summary_modal == null:
		round_summary_modal = get_node_or_null("RoundSummaryModal") as Control
		if round_summary_modal == null:
			round_summary_modal = get_node_or_null("%RoundSummaryModal") as Control
	if meld_inspection_overlay == null:
		meld_inspection_overlay = get_node_or_null("SafeAreaRoot/WorldSpaceOverlayLayer/MeldInspectionPills") as Control
		if meld_inspection_overlay == null:
			meld_inspection_overlay = get_node_or_null("%MeldInspectionPills") as Control

	if draft_meter_pill != null:
		return
	safe_area_root = get_node_or_null("SafeAreaRoot") as MarginContainer
	indicator_tile_view = get_node_or_null("SafeAreaRoot/TopBar/LeftCluster/IndicatorTileBadge") as Control
	indicator_label = get_node_or_null("SafeAreaRoot/TopBar/LeftCluster/IndicatorTileBadge/IndicatorHBox/IndicatorLabel") as Label
	facts_label = get_node_or_null("SafeAreaRoot/TopBar/LeftCluster/FactsBadge/FactsLabel") as Label
	draft_meter_pill = get_node_or_null("SafeAreaRoot/BottomDock/DraftAndTurnBannerRow/DraftMeterPill") as PanelContainer
	draft_points_label = get_node_or_null("SafeAreaRoot/BottomDock/DraftAndTurnBannerRow/DraftMeterPill/DraftHBox/DraftPointsLabel") as Label
	draft_progress_bar = get_node_or_null("SafeAreaRoot/BottomDock/DraftAndTurnBannerRow/DraftMeterPill/DraftHBox/DraftProgressBar") as ProgressBar
	commit_melds_btn = get_node_or_null("SafeAreaRoot/BottomDock/DraftAndTurnBannerRow/CommitMeldsButton") as Button
	draw_btn = get_node_or_null("SafeAreaRoot/BottomDock/RackControlBar/TurnActionGroup/DrawButton") as Button
	take_discard_btn = get_node_or_null("SafeAreaRoot/BottomDock/RackControlBar/TurnActionGroup/TakeDiscardButton") as Button
	discard_btn = get_node_or_null("SafeAreaRoot/BottomDock/RackControlBar/TurnActionGroup/DiscardSelectedButton") as Button
	undo_btn = get_node_or_null("SafeAreaRoot/BottomDock/RackControlBar/RackUtilityGroup/UndoButton") as Button
	return_draft_btn = get_node_or_null("SafeAreaRoot/BottomDock/RackControlBar/RackUtilityGroup/ReturnDraftButton") as Button
	sort_color_btn = get_node_or_null("SafeAreaRoot/BottomDock/RackControlBar/RackUtilityGroup/SortColorButton") as Button
	sort_number_btn = get_node_or_null("SafeAreaRoot/BottomDock/RackControlBar/RackUtilityGroup/SortNumberButton") as Button
	back_to_hub_btn = get_node_or_null("SafeAreaRoot/TopBar/LeftCluster/BackToHubButton") as Button
	camera_toggle_btn = get_node_or_null("SafeAreaRoot/TopBar/RightCluster/CameraViewToggle") as Button
	melds_btn = get_node_or_null("SafeAreaRoot/TopBar/RightCluster/MeldsButton") as Button
	help_guide_btn = get_node_or_null("SafeAreaRoot/TopBar/RightCluster/HelpGuideButton") as Button
	instruction_label = get_node_or_null("%InstructionLabel") as Label
	if instruction_label == null:
		instruction_label = get_node_or_null("SafeAreaRoot/TopNotificationAnchor/TurnInstructionBanner/InstructionLabel") as Label
	if instruction_label == null:
		instruction_label = get_node_or_null("SafeAreaRoot/BottomDock/TurnInstructionBanner/InstructionLabel") as Label
	feedback_toast = get_node_or_null("SafeAreaRoot/ToastAnchor/FeedbackToast") as PanelContainer
	feedback_label = get_node_or_null("SafeAreaRoot/ToastAnchor/FeedbackToast/FeedbackLabel") as Label
	modal_overlay = get_node_or_null("ModalOverlay") as ColorRect
	modal_title = get_node_or_null("ModalOverlay/ModalCenter/ModalPanel/ModalVBox/ModalTitle") as Label
	modal_body = get_node_or_null("ModalOverlay/ModalCenter/ModalPanel/ModalVBox/ModalScroll/ModalBody") as VBoxContainer
	_modal_body = modal_body
	modal_close_btn = get_node_or_null("ModalOverlay/ModalCenter/ModalPanel/ModalVBox/ModalCloseButton") as Button

	seat_badges = [
		get_node_or_null("SafeAreaRoot/BottomDock/RackControlBar/LocalPlayerBadge"),
		get_node_or_null("SafeAreaRoot/MiddleSideSeats/SeatBadgeRight"),
		get_node_or_null("SafeAreaRoot/TopBar/TopOpponentSlot/SeatBadgeTop"),
		get_node_or_null("SafeAreaRoot/MiddleSideSeats/SeatBadgeLeft")
	]

func _ready() -> void:
	_ensure_nodes()
	_apply_mobile_safe_area_insets()
	var hud_font = AssetRegistry.font(AssetIds.UI_FONT_BARLOW_CONDENSED_BOLD)
	if hud_font != null and safe_area_root != null and safe_area_root.theme != null:
		safe_area_root.theme.default_font = hud_font
	if get_tree() != null and get_tree().root != null:
		get_tree().root.size_changed.connect(_apply_mobile_safe_area_insets)

	for btn in [draw_btn, take_discard_btn, commit_melds_btn, discard_btn, undo_btn, return_draft_btn, sort_color_btn, sort_number_btn, camera_toggle_btn, melds_btn, back_to_hub_btn, help_guide_btn, modal_close_btn]:
		if btn != null:
			btn.focus_mode = Control.FOCUS_NONE

	if draw_btn != null: draw_btn.pressed.connect(_on_draw_pressed)
	if take_discard_btn != null: take_discard_btn.pressed.connect(_on_take_discard_pressed)
	if commit_melds_btn != null: commit_melds_btn.pressed.connect(_on_commit_melds_pressed)
	if discard_btn != null: discard_btn.pressed.connect(_on_discard_pressed)
	if undo_btn != null: undo_btn.pressed.connect(_on_undo_pressed)
	if return_draft_btn != null: return_draft_btn.pressed.connect(_on_return_draft_pressed)
	if sort_color_btn != null: sort_color_btn.pressed.connect(func(): _on_sort_pressed(&"color"))
	if sort_number_btn != null: sort_number_btn.pressed.connect(func(): _on_sort_pressed(&"number"))
	if camera_toggle_btn != null: camera_toggle_btn.pressed.connect(_on_camera_toggle_pressed)
	if melds_btn != null: melds_btn.pressed.connect(_show_melds)
	if back_to_hub_btn != null: back_to_hub_btn.pressed.connect(_on_back_to_hub_pressed)
	if help_guide_btn != null: help_guide_btn.pressed.connect(_show_help)
	if modal_close_btn != null: modal_close_btn.pressed.connect(_close_modal)

	if draw_btn != null: draw_btn.visible = false
	if take_discard_btn != null: take_discard_btn.visible = false
	if discard_btn != null: discard_btn.visible = false
	if return_draft_btn != null: return_draft_btn.visible = false
	if draft_meter_pill != null: draft_meter_pill.visible = false
	if commit_melds_btn != null: commit_melds_btn.visible = false
	if feedback_toast != null: feedback_toast.visible = false
	if modal_overlay != null: modal_overlay.visible = false
	if round_summary_modal != null:
		round_summary_modal.visible = false
		if not round_summary_modal.next_round_requested.is_connected(_on_modal_next_round):
			round_summary_modal.next_round_requested.connect(_on_modal_next_round)
		if not round_summary_modal.main_menu_requested.is_connected(_on_back_to_hub_pressed):
			round_summary_modal.main_menu_requested.connect(_on_back_to_hub_pressed)

	if not OS.get_cmdline_user_args().has("--okey-skip-guide") and not FileAccess.file_exists("user://okey_guide_seen.cfg"):
		call_deferred("_show_help")

func set_camera(cam: Camera3D) -> void:
	_ensure_nodes()
	if meld_inspection_overlay != null:
		meld_inspection_overlay.camera = cam

func _on_modal_next_round() -> void:
	if round_summary_modal != null:
		round_summary_modal.close()
	if _session != null and _session.has_method("overlay_new_round"):
		_session.overlay_new_round()
	elif board != null and board.has_method("_force_sync"):
		board._force_sync()

func bind_to_session(session: Node) -> void:
	if session == null or _bound_session == session:
		return
	_session = session
	_bound_session = session

	if not session.is_connected("session_state_updated", _on_session_state_updated):
		session.session_state_updated.connect(_on_session_state_updated)
	if not session.is_connected("rack_and_draft_changed", _on_rack_and_draft_changed):
		session.rack_and_draft_changed.connect(_on_rack_and_draft_changed)
	if not session.is_connected("table_melds_updated", _on_table_melds_updated):
		session.table_melds_updated.connect(_on_table_melds_updated)
	if not session.is_connected("feedback", show_feedback):
		session.feedback.connect(show_feedback)

func _on_table_melds_updated(meld_groups: Array) -> void:
	_ensure_nodes()
	if meld_inspection_overlay != null:
		meld_inspection_overlay.sync_meld_groups(meld_groups)

func refresh(session: Node) -> void:
	bind_to_session(session)
	if session == null:
		return
	var snapshot: Dictionary = session.get_view_snapshot() if session.has_method("get_view_snapshot") else {}
	if not snapshot.is_empty():
		var state = snapshot.get("state")
		if state != null:
			_update_from_state(state, session)
			if meld_inspection_overlay != null and "table_melds" in state and state.table_melds != null:
				meld_inspection_overlay.sync_meld_groups(state.table_melds)

func is_modal_open() -> bool:
	_ensure_nodes()
	return (modal_overlay != null and modal_overlay.visible) or (round_summary_modal != null and round_summary_modal.visible)

func _apply_mobile_safe_area_insets() -> void:
	if safe_area_root == null:
		return
	var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	if safe_rect.size == Vector2i.ZERO or window_size == Vector2i.ZERO:
		return
	var left_pad: int = maxi(16, safe_rect.position.x)
	var top_pad: int = maxi(12, safe_rect.position.y)
	var right_pad: int = maxi(16, window_size.x - (safe_rect.position.x + safe_rect.size.x))
	var bottom_pad: int = maxi(12, window_size.y - (safe_rect.position.y + safe_rect.size.y))
	safe_area_root.add_theme_constant_override(&"margin_left", left_pad)
	safe_area_root.add_theme_constant_override(&"margin_top", top_pad)
	safe_area_root.add_theme_constant_override(&"margin_right", right_pad)
	safe_area_root.add_theme_constant_override(&"margin_bottom", bottom_pad)

func _on_session_state_updated(snapshot: Dictionary) -> void:
	_ensure_nodes()
	var selected_id: int = int(snapshot.get("selected_tile_id", -1))
	_last_selected_tile_id = selected_id

	# Direct 3D table interaction handles draw, take discard, and discard without redundant HUD buttons.
	if draw_btn != null: draw_btn.visible = false
	if take_discard_btn != null: take_discard_btn.visible = false
	if discard_btn != null: discard_btn.visible = false

	var instruction: String = str(snapshot.get("instruction", ""))
	if instruction_label != null:
		instruction_label.text = instruction

	var round_num: int = int(snapshot.get("round_index", 1))
	var deck_size: int = int(snapshot.get("deck_count", 0))
	var seconds: int = int(snapshot.get("turn_seconds_remaining", 0))
	if facts_label != null:
		facts_label.text = "ROUND %d · STOCK %d · %02d:%02d" % [round_num, deck_size, seconds / 60, seconds % 60]

	var indicator = snapshot.get("indicator_tile")
	var okey_ctx = snapshot.get("okey_context")
	_update_indicator_badge(indicator, okey_ctx)

	var seats: Array = snapshot.get("seats", [])
	for i in range(mini(seats.size(), seat_badges.size())):
		if seat_badges[i] != null and seat_badges[i].has_method("update_seat"):
			seat_badges[i].update_seat(seats[i])

func _on_rack_and_draft_changed(_rack: Array, _draft: Array, validation: Dictionary) -> void:
	_ensure_nodes()
	var total_pts: int = int(validation.get("valid_points", 0))
	var pair_count: int = int(validation.get("valid_pairs", 0))
	var threshold: int = int(validation.get("opening_threshold", 101))
	var is_already_open: bool = bool(validation.get("is_player_open", false))
	var can_commit: bool = bool(validation.get("can_commit", false))
	var staged_count: int = int(validation.get("staged_tile_count", 0))
	var has_draft: bool = bool(validation.get("has_draft_tiles", false))
	var has_staged_tiles: bool = staged_count > 0 or total_pts > 0 or pair_count >= 2

	if return_draft_btn != null: return_draft_btn.visible = has_draft
	if draft_meter_pill != null: draft_meter_pill.visible = has_staged_tiles
	if commit_melds_btn != null: commit_melds_btn.visible = has_staged_tiles and can_commit

	if not has_staged_tiles:
		return

	if is_already_open:
		draft_points_label.text = "Rack Melds: +%d pts" % total_pts
		draft_progress_bar.max_value = maxi(1, total_pts)
		_animate_meter_value(total_pts)
	elif pair_count >= 3 and total_pts < 60:
		draft_points_label.text = "Rack Pairs: %d / 5" % pair_count
		draft_progress_bar.max_value = 5
		_animate_meter_value(pair_count)
	else:
		draft_points_label.text = "Rack Melds: %d / %d pts" % [total_pts, threshold]
		draft_progress_bar.max_value = threshold
		_animate_meter_value(total_pts)

	draft_meter_pill.theme_type_variation = &"DraftPillReady" if can_commit else &"DraftPillPending"

func _animate_meter_value(target_value: float) -> void:
	if _meter_tween != null and _meter_tween.is_running():
		_meter_tween.kill()
	_meter_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_meter_tween.tween_property(draft_progress_bar, ^"value", target_value, 0.22)

func _update_indicator_badge(indicator, okey_ctx) -> void:
	if indicator_label == null:
		return
	if indicator == null:
		indicator_label.text = "Indicator: --"
		return

	var ind_col: int = int(indicator.color) if "color" in indicator else 0
	var ind_num: int = int(indicator.number) if "number" in indicator else 0
	var col_name: String = COLOR_NAMES[ind_col] if ind_col < COLOR_NAMES.size() else "Tile"

	var okey_col_name: String = col_name
	var okey_num: int = ind_num + 1 if ind_num < 13 else 1
	if okey_ctx != null:
		var oc: int = int(okey_ctx.okey_color)
		okey_col_name = COLOR_NAMES[oc] if oc < COLOR_NAMES.size() else col_name
		okey_num = int(okey_ctx.okey_number)

	indicator_label.text = "%s %d  ★ Okey: %s %d" % [col_name, ind_num, okey_col_name, okey_num]

func _update_from_state(state, session: Node) -> void:
	if state == null:
		return
	if state.phase == GameState.Phase.ROUND_END and not is_modal_open():
		_show_results(state)

	var seats: Array = []
	for i in range(state.players.size()):
		var p = state.players[i]
		seats.append({
			"seat_index": i,
			"name": "YOU" if i == 0 else "Player %d" % (i + 1),
			"is_local": i == 0,
			"is_turn": i == state.current_player_index,
			"tile_count": p.hand.size(),
			"has_opened": bool(p.has_opened),
			"score": int(p.score_total)
		})
	for i in range(mini(seats.size(), seat_badges.size())):
		if seat_badges[i] != null and seat_badges[i].has_method("update_seat"):
			seat_badges[i].update_seat(seats[i])

	if instruction_label != null:
		instruction_label.text = session.get_instruction_text()

	var seconds: int = session.get_turn_seconds_remaining()
	if facts_label != null:
		facts_label.text = "ROUND %d · STOCK %d · %02d:%02d" % [state.round_index, state.deck.size(), seconds / 60, seconds % 60]

	var okey_ctx = state.okey_context if ("okey_context" in state and state.okey_context != null) else null
	var indicator = okey_ctx.indicator_tile if (okey_ctx != null and "indicator_tile" in okey_ctx) else null
	_update_indicator_badge(indicator, okey_ctx)

func show_feedback(message: String) -> void:
	if feedback_toast == null or feedback_label == null:
		return
	feedback_label.text = message
	feedback_toast.visible = true
	feedback_toast.modulate.a = 1.0

	if _toast_tween != null and _toast_tween.is_running():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.5)
	_toast_tween.tween_property(feedback_toast, ^"modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func(): feedback_toast.visible = false)

# --- Button Handlers ---

func _on_draw_pressed() -> void:
	draw_tile_requested.emit()
	if _session != null:
		var res: Dictionary = _session.request_draw_from_deck()
		if not bool(res.get("ok", false)):
			show_feedback(str(res.get("reason", "Cannot draw tile")))
		elif board != null and "SFX_DRAW_FROM_DECK" in board:
			board._play_sfx(board.SFX_DRAW_FROM_DECK)
			board._force_sync()

func _on_take_discard_pressed() -> void:
	take_discard_requested.emit()
	if _session != null:
		var res: Dictionary = _session.request_take_discard()
		if not bool(res.get("ok", false)):
			show_feedback(str(res.get("reason", "Cannot take discard")))
		elif board != null and "SFX_TAKE_DISCARD" in board:
			board._play_sfx(board.SFX_TAKE_DISCARD)
			board._force_sync()

func _on_commit_melds_pressed() -> void:
	commit_melds_requested.emit()
	if _session != null:
		var res: Dictionary = _session.request_commit_staged_melds()
		if not bool(res.get("ok", false)):
			show_feedback(str(res.get("reason", "Cannot commit melds")))
		elif board != null:
			if "SFX_ADD_TO_MELD" in board:
				board._play_sfx(board.SFX_ADD_TO_MELD)
			if board.has_method("_spawn_feedback_pulse"):
				board._spawn_feedback_pulse(board._table_local_to_world(Vector2.ZERO), Color(0.4, 1.0, 0.8, 0.35), 0.12, 0.30, 0.22)
			board._force_sync()

func _on_discard_pressed() -> void:
	discard_selected_requested.emit()
	var tile_id: int = _last_selected_tile_id
	if board != null and "_last_selected_tile_id" in board and board._last_selected_tile_id >= 0:
		tile_id = board._last_selected_tile_id
	if tile_id < 0:
		show_feedback("Select a tile from your rack first")
		return
	if _session != null:
		var res: Dictionary = _session.request_discard_tile(tile_id)
		if not bool(res.get("ok", false)):
			show_feedback(str(res.get("reason", "Cannot discard selected tile")))
		else:
			if board != null:
				board._last_selected_tile_id = -1
				if "SFX_DISCARD" in board:
					board._play_sfx(board.SFX_DISCARD)
				board._force_sync()

func _on_sort_pressed(mode: StringName) -> void:
	sort_requested.emit(mode)
	if _session != null:
		_session.request_sort_rack(mode)
		if board != null and "SFX_RACK_MOVE" in board:
			board._play_sfx(board.SFX_RACK_MOVE)
			board._force_sync()

func _on_undo_pressed() -> void:
	undo_requested.emit()
	if _session != null:
		var res: Dictionary = _session.request_undo()
		if not bool(res.get("ok", false)):
			show_feedback(str(res.get("reason", "Nothing to undo")))
		elif board != null and "SFX_RACK_MOVE" in board:
			board._play_sfx(board.SFX_RACK_MOVE)
			board._force_sync()

func _on_return_draft_pressed() -> void:
	return_draft_requested.emit()
	if _session != null:
		var res: Dictionary = _session.request_return_draft()
		if not bool(res.get("ok", false)):
			show_feedback(str(res.get("reason", "No staged draft tiles")))
		elif board != null and "SFX_DRAFT_MOVE" in board:
			board._play_sfx(board.SFX_DRAFT_MOVE)
			board._force_sync()

func _on_camera_toggle_pressed() -> void:
	camera_toggle_requested.emit()
	if board != null and board.has_method("toggle_inspection"):
		board.toggle_inspection()

func _on_back_to_hub_pressed() -> void:
	back_to_hub_requested.emit()
	if board != null and board.has_method("_on_hud_menu_pressed"):
		board._on_hud_menu_pressed()
	else:
		get_tree().change_scene_to_file("res://ui/Main.tscn")

# --- Modals ---

func _open_modal(title: String) -> void:
	if board != null and board.has_method("_clear_drag_state"):
		board._clear_drag_state()
	modal_title.text = title
	for child in modal_body.get_children():
		child.queue_free()
	modal_overlay.visible = true

func _close_modal() -> void:
	if modal_overlay != null:
		modal_overlay.visible = false
	if round_summary_modal != null:
		round_summary_modal.close()
	if modal_body != null:
		for child in modal_body.get_children():
			child.queue_free()

func _show_help() -> void:
	_open_modal("Welcome to Okey 101")
	var help_text := Label.new()
	help_text.text = """1  DRAW by tapping the central stock pile or taking the discard tile from the player on your left.
2  SORT & GROUP runs (3+ consecutive numbers of the same color) or sets (3-4 identical numbers of different colors) directly on your 2-row rack. Use 'Seri Diz (Runs)' or 'Çift Diz (Pairs)'.
3  OPEN MELDS when your rack groups total 101+ points or 5+ pairs by clicking 'Open Melds'.
4  DISCARD by double-clicking a tile on your rack or dragging it to your right-hand discard area to end your turn.

• Real Okey: Wild tile, one number above the indicator.
• Fake Okey: Represents the real Okey's printed number.
• Taken Discards: Must be played into an opening meld immediately."""
	help_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_text.add_theme_font_size_override("font_size", 14)
	help_text.add_theme_color_override("font_color", Color("#ede4d8"))
	modal_body.add_child(help_text)

	if board != null:
		var prefs := HBoxContainer.new()
		prefs.add_theme_constant_override("separation", 16)
		modal_body.add_child(prefs)

		if "reduced_motion" in board:
			var motion := CheckButton.new()
			motion.text = "Reduced motion"
			motion.button_pressed = board.reduced_motion
			motion.toggled.connect(func(v: bool): board.reduced_motion = v)
			prefs.add_child(motion)

		if "sound_enabled" in board:
			var audio := CheckButton.new()
			audio.text = "Sound effects"
			audio.button_pressed = board.sound_enabled
			audio.toggled.connect(func(v: bool):
				board.sound_enabled = v
				if "_audio_service" in board and board._audio_service != null:
					board._audio_service.set_levels_linear(0.8 if v else 0.0, 0.08 if v else 0.0)
			)
			prefs.add_child(audio)

	var seen := FileAccess.open("user://okey_guide_seen.cfg", FileAccess.WRITE)
	if seen != null:
		seen.store_string("seen")

func _show_melds() -> void:
	if _session == null:
		return
	var controller = _session.get_controller()
	if controller == null or controller.state == null:
		return
	var state = controller.state
	_open_modal("Melds on the Table")

	if state.table_melds.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No players have opened melds yet. Build yours in the workspace!"
		empty_lbl.add_theme_font_size_override("font_size", 14)
		modal_body.add_child(empty_lbl)
		return

	var meld_colors := [Color("#d64545"), Color("#e09f3e"), Color("#3b82f6"), Color("#2b2d42")]
	for index in range(state.table_melds.size()):
		var meld = state.table_melds[index]
		var group := VBoxContainer.new()
		group.add_theme_constant_override("separation", 6)
		modal_body.add_child(group)

		var kind_str: String = ["Run", "Set", "Pairs"][mini(int(meld.kind), 2)]
		var title_lbl := Label.new()
		title_lbl.text = "Player %d · %s" % [meld.owner_index + 1, kind_str]
		title_lbl.add_theme_font_size_override("font_size", 15)
		group.add_child(title_lbl)

		var tiles_flow := HFlowContainer.new()
		group.add_child(tiles_flow)

		if "tiles_data" in meld and meld.tiles_data is Array:
			for tile in meld.tiles_data:
				var chip := Label.new()
				chip.text = " F " if tile.kind == Tile.Kind.FAKE_OKEY else " %s " % tile.number
				if state.okey_context != null and state.okey_context.is_real_okey(tile):
					chip.text += "★"
				chip.add_theme_font_size_override("font_size", 18)
				var c_idx: int = mini(int(tile.color), meld_colors.size() - 1)
				chip.add_theme_color_override("font_color", meld_colors[c_idx])
				tiles_flow.add_child(chip)

		var extend_btn := Button.new()
		var selected_id: int = _last_selected_tile_id
		if board != null and "_last_selected_tile_id" in board:
			selected_id = board._last_selected_tile_id
		extend_btn.text = "Extend with selected tile" if selected_id >= 0 else "Select a tile to extend"
		extend_btn.custom_minimum_size.y = 36
		extend_btn.theme_type_variation = &"RackUtilityButton"
		extend_btn.disabled = selected_id < 0 or state.current_player_index != 0 or state.phase != GameState.Phase.TURN_PLAY or not state.players[0].has_opened
		extend_btn.pressed.connect(func():
			var res: Dictionary = _session.overlay_add_to_meld([selected_id], index)
			if bool(res.get("ok", false)):
				if board != null:
					board._last_selected_tile_id = -1
				_close_modal()
			else:
				show_feedback(str(res.get("reason", "Cannot extend this meld.")))
		)
		group.add_child(extend_btn)

func _show_results(state) -> void:
	_ensure_nodes()
	var is_match_finished: bool = bool(state.match_finished) if (state != null and "match_finished" in state) else false
	
	_open_modal("Match Complete" if is_match_finished else "Round Complete")
	var reason_lbl := Label.new()
	var reason_txt: String = state.round_end_reason if (state != null and "round_end_reason" in state) else ""
	reason_lbl.text = reason_txt.replace("_", " ").capitalize()
	reason_lbl.add_theme_font_size_override("font_size", 16)
	modal_body.add_child(reason_lbl)

	if state != null and "players" in state and state.players != null:
		for i in range(state.players.size()):
			var p = state.players[i]
			var score_lbl := Label.new()
			var r_pts: int = int(p.get("score_round", 0)) if p is Dictionary else int(p.score_round if "score_round" in p else 0)
			var t_pts: int = int(p.get("score_total", 0)) if p is Dictionary else int(p.score_total if "score_total" in p else 0)
			var p_name: String = str(p.get("name", "")) if p is Dictionary else str(p.name if "name" in p else "")
			if p_name.is_empty():
				p_name = "YOU" if i == 0 else "Player %d" % (i + 1)
			score_lbl.text = "%s  ·  Round: %d  ·  Total: %d" % [p_name, r_pts, t_pts]
			score_lbl.add_theme_font_size_override("font_size", 14)
			modal_body.add_child(score_lbl)

	if not is_match_finished:
		var next_btn := Button.new()
		next_btn.text = "Next round"
		next_btn.custom_minimum_size.y = 40
		next_btn.theme_type_variation = &"PrimaryActionButton"
		next_btn.pressed.connect(func():
			_close_modal()
			if _session != null:
				_session.overlay_new_round()
		)
		modal_body.add_child(next_btn)

	var menu_btn := Button.new()
	menu_btn.text = "Return to Menu"
	menu_btn.custom_minimum_size.y = 40
	menu_btn.theme_type_variation = &"RackUtilityButton"
	menu_btn.pressed.connect(_on_back_to_hub_pressed)
	modal_body.add_child(menu_btn)

	if round_summary_modal != null:
		round_summary_modal.display_summary(state, is_match_finished)