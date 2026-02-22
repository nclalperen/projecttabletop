extends RefCounted

const GEO = preload("res://ui/game_table/TableGeometry.gd")
const TH = preload("res://ui/game_table/TileHelpers.gd")

func run() -> bool:
	var ok: bool = true

	# Verify frozen constants are accessible via preload
	if GEO.RACK_SLOT_COUNT != 30:
		push_error("RACK_SLOT_COUNT expected 30, got %d" % GEO.RACK_SLOT_COUNT)
		ok = false
	if GEO.RACK_ROW_SLOTS != 15:
		push_error("RACK_ROW_SLOTS expected 15, got %d" % GEO.RACK_ROW_SLOTS)
		ok = false
	if GEO.STAGE_SLOT_COUNT != 24:
		push_error("STAGE_SLOT_COUNT expected 24, got %d" % GEO.STAGE_SLOT_COUNT)
		ok = false
	if GEO.STAGE_ROW_SLOTS != 12:
		push_error("STAGE_ROW_SLOTS expected 12, got %d" % GEO.STAGE_ROW_SLOTS)
		ok = false

	# Verify perspective ratios are frozen at expected values
	if not is_equal_approx(GEO.PERSPECTIVE_FAR_WIDTH_RATIO, 0.76):
		push_error("PERSPECTIVE_FAR_WIDTH_RATIO expected 0.76")
		ok = false
	if not is_equal_approx(GEO.PERSPECTIVE_NEAR_WIDTH_RATIO, 0.95):
		push_error("PERSPECTIVE_NEAR_WIDTH_RATIO expected 0.95")
		ok = false
	if not is_equal_approx(GEO.FELT_VERTICAL_BIAS, 0.46):
		push_error("FELT_VERTICAL_BIAS expected 0.46")
		ok = false

	# Verify project_board_footprint returns valid shape
	var proj: Dictionary = GEO.project_board_footprint(100.0, 50.0, 800.0, 600.0)
	if not proj.has("top_left") or not proj.has("bottom_right"):
		push_error("project_board_footprint missing expected keys")
		ok = false
	else:
		var tl: Vector2 = proj["top_left"]
		var br: Vector2 = proj["bottom_right"]
		# Top should be narrower than bottom (perspective)
		var top_w: float = float(proj["top_width"])
		var bottom_w: float = float(proj["bottom_width"])
		if top_w >= bottom_w:
			push_error("Perspective trapezoid: top_width (%.1f) should be < bottom_width (%.1f)" % [top_w, bottom_w])
			ok = false
		# Top-left Y should be above bottom-right Y
		if tl.y >= br.y:
			push_error("Trapezoid: top_left.y (%.1f) should be < bottom_right.y (%.1f)" % [tl.y, br.y])
			ok = false

	# Verify build_table_anchor_contract returns expected keys
	var anchors: Dictionary = GEO.build_table_anchor_contract(
		Vector2(100, 100), Vector2(700, 100),
		Vector2(50, 500), Vector2(750, 500),
		800.0, 600.0, "2d"
	)
	for key in ["center_size", "center_anchor", "opp_rack_rects", "opp_discard_rects", "my_discard_local"]:
		if not anchors.has(key):
			push_error("build_table_anchor_contract missing key: %s" % key)
			ok = false

	# Verify build_meld_owner_zones returns zones for all 4 players
	var zones: Dictionary = GEO.build_meld_owner_zones(600.0, 400.0, 120.0)
	for p in [0, 1, 2, 3]:
		if not zones.has(p):
			push_error("build_meld_owner_zones missing zone for player %d" % p)
			ok = false

	# Verify TileHelpers static functions work
	var phase_str: String = TH.phase_name(GameState.Phase.TURN_PLAY)
	if phase_str != "Play":
		push_error("TileHelpers.phase_name(TURN_PLAY) expected 'Play', got '%s'" % phase_str)
		ok = false

	if TH.color_letter(Tile.TileColor.RED) != "R":
		push_error("TileHelpers.color_letter(RED) expected 'R'")
		ok = false

	if ok:
		print("  PASS  test_table_geometry_constants")
	else:
		print("  FAIL  test_table_geometry_constants")
	return ok
