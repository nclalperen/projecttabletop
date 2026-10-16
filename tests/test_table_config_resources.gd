extends RefCounted
## Validates the new TableConfig / SeatConfig resource layer and the
## Okey101TableConfig factory against the hardcoded values that GameTable3D
## used to own directly.

const TABLE_CFG = preload("res://core/config/TableConfig.gd")
const SEAT_CFG  = preload("res://core/config/SeatConfig.gd")
const OKEY_CFG  = preload("res://core/config/Okey101TableConfig.gd")


func run() -> bool:
	return _test_okey101_factory() and _test_seat_config_factory() and _test_table_config_helpers()


func _test_okey101_factory() -> bool:
	var ok: bool = true
	var cfg: TableConfig = OKEY_CFG.create()

	ok = _check(cfg.table_id == &"okey101_classic", "table_id") and ok
	ok = _check(cfg.seat_count == 4, "seat_count must be 4") and ok
	ok = _check(cfg.seats.size() == 4, "seats array must have 4 entries") and ok

	# Physical dimensions (frozen from GameTable3D constants)
	ok = _check(is_equal_approx(cfg.table_width, 1.0), "table_width") and ok
	ok = _check(is_equal_approx(cfg.table_depth, 1.0), "table_depth") and ok
	ok = _check(is_equal_approx(cfg.table_height, 0.075), "table_height") and ok
	ok = _check(is_equal_approx(cfg.felt_width, 0.80), "felt_width") and ok
	ok = _check(is_equal_approx(cfg.felt_depth, 0.80), "felt_depth") and ok
	ok = _check(is_equal_approx(cfg.rack_length, 0.82), "rack_length") and ok
	ok = _check(is_equal_approx(cfg.rack_depth, 0.15), "rack_depth") and ok
	ok = _check(is_equal_approx(cfg.rack_height, 0.11), "rack_height") and ok
	ok = _check(is_equal_approx(cfg.tile_width, 0.045), "tile_width") and ok
	ok = _check(is_equal_approx(cfg.tile_height, 0.065), "tile_height") and ok
	ok = _check(is_equal_approx(cfg.tile_depth, 0.009), "tile_depth") and ok

	# Deck position
	ok = _check(cfg.deck_position.is_equal_approx(Vector2(-0.04, -0.22)), "deck_position") and ok

	# Computed helpers
	ok = _check(is_equal_approx(cfg.rack_center(), 0.42), "rack_center()") and ok
	ok = _check(is_equal_approx(cfg.felt_half(), 0.40), "felt_half()") and ok

	# Seat 0 — local player
	var s0: SeatConfig = cfg.get_seat(0)
	ok = _check(s0 != null, "seat 0 exists") and ok
	if s0 != null:
		ok = _check(s0.is_local_player, "seat 0 is_local_player") and ok
		ok = _check(s0.label == "You", "seat 0 label") and ok
		ok = _check(is_equal_approx(s0.rotation_y_deg, 0.0), "seat 0 rotation") and ok
		ok = _check(s0.rack_position.is_equal_approx(Vector2(0.0, 0.42)), "seat 0 rack_position") and ok
		ok = _check(s0.discard_position.is_equal_approx(Vector2(0.40, 0.08)), "seat 0 discard") and ok
		ok = _check(is_equal_approx(s0.camera_fov, 44.0), "seat 0 camera_fov") and ok

	# Seat 1 — East
	var s1: SeatConfig = cfg.get_seat(1)
	ok = _check(s1 != null, "seat 1 exists") and ok
	if s1 != null:
		ok = _check(not s1.is_local_player, "seat 1 not local") and ok
		ok = _check(is_equal_approx(s1.rotation_y_deg, 90.0), "seat 1 rotation") and ok
		ok = _check(s1.rack_position.is_equal_approx(Vector2(0.475, 0.0)), "seat 1 rack_position") and ok

	# Seat 2 — North
	var s2: SeatConfig = cfg.get_seat(2)
	ok = _check(s2 != null, "seat 2 exists") and ok
	if s2 != null:
		ok = _check(is_equal_approx(s2.rotation_y_deg, 180.0), "seat 2 rotation") and ok
		ok = _check(s2.rack_position.is_equal_approx(Vector2(0.0, -0.42)), "seat 2 rack_position") and ok

	# Seat 3 — West
	var s3: SeatConfig = cfg.get_seat(3)
	ok = _check(s3 != null, "seat 3 exists") and ok
	if s3 != null:
		ok = _check(is_equal_approx(s3.rotation_y_deg, -90.0), "seat 3 rotation") and ok
		ok = _check(s3.rack_position.is_equal_approx(Vector2(-0.475, 0.0)), "seat 3 rack_position") and ok

	# Local seat helper
	var local: SeatConfig = cfg.get_local_seat()
	ok = _check(local != null and local.seat_index == 0, "get_local_seat returns seat 0") and ok

	if ok:
		print("  PASS  test_table_config_resources")
	else:
		print("  FAIL  test_table_config_resources")
	return ok


func _test_seat_config_factory() -> bool:
	var ok: bool = true
	var seat := SeatConfig.create(2, "North", false,
		Vector2(0.0, -0.42), 180.0,
		Vector2(-0.40, -0.26),
		Rect2(Vector2(-0.22, -0.36), Vector2(0.44, 0.09)))
	ok = _check(seat.seat_index == 2, "factory seat_index") and ok
	ok = _check(seat.label == "North", "factory label") and ok
	ok = _check(not seat.is_local_player, "factory is_local_player") and ok
	ok = _check(is_equal_approx(seat.rotation_y_deg, 180.0), "factory rotation") and ok
	ok = _check(seat.rack_position.is_equal_approx(Vector2(0.0, -0.42)), "factory rack_position") and ok
	ok = _check(seat.discard_position.is_equal_approx(Vector2(-0.40, -0.26)), "factory discard_position") and ok
	ok = _check(seat.meld_lane.position.is_equal_approx(Vector2(-0.22, -0.36)), "factory meld_lane pos") and ok
	if ok:
		print("  PASS  test_seat_config_factory")
	else:
		print("  FAIL  test_seat_config_factory")
	return ok


func _test_table_config_helpers() -> bool:
	var ok: bool = true
	var cfg := TableConfig.new()
	cfg.table_width = 2.0
	cfg.rack_depth = 0.20
	cfg.rack_gap_to_felt = 0.01
	ok = _check(is_equal_approx(cfg.rack_center(), 0.89), "custom rack_center") and ok
	cfg.felt_width = 1.60
	ok = _check(is_equal_approx(cfg.felt_half(), 0.80), "custom felt_half") and ok
	ok = _check(cfg.get_seat(99) == null, "get_seat out of range returns null") and ok
	ok = _check(cfg.get_local_seat() == null, "get_local_seat with no seats returns null") and ok
	if ok:
		print("  PASS  test_table_config_helpers")
	else:
		print("  FAIL  test_table_config_helpers")
	return ok


func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("table_config_resources: " + message)
	return condition
