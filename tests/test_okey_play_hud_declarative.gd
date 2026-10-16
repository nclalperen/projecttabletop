extends RefCounted

const SESSION_SCRIPT = preload("res://ui/game_table/OkeySession.gd")
const HUD_SCENE = preload("res://ui/game_table/OkeyPlayHUD.tscn")

func run() -> bool:
	if HUD_SCENE == null:
		push_error("Failed to load OkeyPlayHUD.tscn")
		return false

	var hud = HUD_SCENE.instantiate()
	if hud == null:
		push_error("Failed to instantiate OkeyPlayHUD.tscn")
		return false

	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(hud)

	# Verify required nodes
	var required_nodes: Array[String] = [
		"SafeAreaRoot",
		"SafeAreaRoot/TopBar",
		"SafeAreaRoot/BottomDock",
		"SafeAreaRoot/BottomDock/DraftAndTurnBannerRow/DraftMeterPill",
		"SafeAreaRoot/BottomDock/DraftAndTurnBannerRow/CommitMeldsButton",
		"SafeAreaRoot/BottomDock/RackControlBar/RackUtilityGroup/SortColorButton",
		"SafeAreaRoot/BottomDock/RackControlBar/RackUtilityGroup/SortNumberButton",
		"SafeAreaRoot/BottomDock/RackControlBar/RackUtilityGroup/UndoButton",
		"SafeAreaRoot/BottomDock/RackControlBar/RackUtilityGroup/ReturnDraftButton",
		"SafeAreaRoot/BottomDock/RackControlBar/TurnActionGroup/DrawButton",
		"SafeAreaRoot/BottomDock/RackControlBar/TurnActionGroup/TakeDiscardButton",
		"SafeAreaRoot/BottomDock/RackControlBar/TurnActionGroup/DiscardSelectedButton",
		"SafeAreaRoot/BottomDock/RackControlBar/LocalPlayerBadge",
		"SafeAreaRoot/MiddleSideSeats/SeatBadgeLeft",
		"SafeAreaRoot/MiddleSideSeats/SeatBadgeRight",
		"SafeAreaRoot/TopBar/TopOpponentSlot/SeatBadgeTop",
	]

	for node_path in required_nodes:
		if hud.get_node_or_null(node_path) == null:
			push_error("OkeyPlayHUD missing required node: %s" % node_path)
			_cleanup(hud)
			return false

	# Verify session binding and reactive updates
	var session = SESSION_SCRIPT.new()
	session.bots_enabled = false
	session.configure_game(RuleConfig.new(), 101, 4)
	session._start_round()

	hud.bind_to_session(session)
	hud.refresh(session)

	if hud.is_modal_open():
		push_error("Modal should be closed initially")
		session.free()
		_cleanup(hud)
		return false

	# Simulate rack & draft change
	var val: Dictionary = {
		"valid_points": 105,
		"valid_pairs": 0,
		"opening_threshold": 101,
		"is_player_open": false,
		"can_commit": true,
		"staged_tile_count": 8,
		"reason": ""
	}
	hud._on_rack_and_draft_changed([], [], val)
	if not hud.commit_melds_btn.visible:
		push_error("Commit melds button should be visible when can_commit is true")
		session.free()
		_cleanup(hud)
		return false

	session.free()
	_cleanup(hud)
	print("  PASS  test_okey_play_hud_declarative")
	return true

func _cleanup(hud: Node) -> void:
	if hud != null:
		if hud.get_parent() != null:
			hud.get_parent().remove_child(hud)
		hud.free()
