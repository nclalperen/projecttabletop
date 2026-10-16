extends RefCounted
## Validates that GameTable3D supports dynamic table and chair swapping,
## adhering to the new modular TableConfig / SeatConfig architecture.

const TableConfig = preload("res://core/config/TableConfig.gd")
const SeatConfig = preload("res://core/config/SeatConfig.gd")
const Okey101TableConfig = preload("res://core/config/Okey101TableConfig.gd")
const TabletopGameCatalog = preload("res://gd/config/TabletopGameCatalog.gd")


func run() -> bool:
	return _test_catalog_table_configs() and _test_game_table_3d_table_config() and _test_chair_swapping() and _test_placeholder_table_config()


func _test_catalog_table_configs() -> bool:
	var ok: bool = true

	# Okey 101 default table config
	var okey_cfg: TableConfig = TabletopGameCatalog.default_table_config(TabletopGameCatalog.GAME_OKEY_101)
	ok = _check(okey_cfg != null, "Catalog returned null for okey table config") and ok
	if okey_cfg != null:
		ok = _check(okey_cfg.table_id == &"okey101_classic", "Catalog okey table_id matches") and ok
		ok = _check(okey_cfg.seats.size() == 4, "Catalog okey has 4 seats") and ok

	# Poker table config
	var poker_cfg: TableConfig = TabletopGameCatalog.default_table_config(TabletopGameCatalog.GAME_POKER)
	ok = _check(poker_cfg != null, "Catalog returned null for poker table config") and ok
	if poker_cfg != null:
		ok = _check(poker_cfg.table_id == &"poker_holdem", "Catalog poker table_id is poker_holdem") and ok
		ok = _check(poker_cfg.seat_count == 6, "Catalog poker default seat count is 6") and ok
		ok = _check(poker_cfg.seats.size() == 6, "Catalog poker seats array has 6 chairs") and ok

	# Chess table config
	var chess_cfg: TableConfig = TabletopGameCatalog.default_table_config(TabletopGameCatalog.GAME_CHESS)
	ok = _check(chess_cfg != null, "Catalog returned null for chess table config") and ok
	if chess_cfg != null:
		ok = _check(chess_cfg.table_id == &"chess_classic", "Catalog chess table_id is chess_classic") and ok
		ok = _check(chess_cfg.seat_count == 2, "Catalog chess default seat count is 2") and ok
		ok = _check(chess_cfg.seats.size() == 2, "Catalog chess seats array has 2 chairs") and ok

	if ok:
		print("  PASS  test_catalog_table_configs")
	else:
		print("  FAIL  test_catalog_table_configs")
	return ok


func _test_game_table_3d_table_config() -> bool:
	var ok: bool = true
	var scene: PackedScene = load("res://ui/GameTable3D.tscn")
	if scene == null:
		push_error("Failed to load GameTable3D scene")
		return false

	var table = scene.instantiate()
	if table == null:
		push_error("Failed to instantiate GameTable3D")
		return false

	# Add to tree so _ready runs
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(table)

	# Verify default table config is created
	var default_cfg: TableConfig = table.get_table_config()
	ok = _check(default_cfg != null, "GameTable3D has default table config") and ok
	if default_cfg != null:
		ok = _check(default_cfg.table_id == &"okey101_classic", "Default table config is Okey 101") and ok
		ok = _check(default_cfg.seats.size() == 4, "Default table config has 4 seats") and ok

	# Verify get_session() returns the active session
	var session = table.get_session()
	ok = _check(session != null, "GameTable3D get_session returns active session") and ok

	# Swap to a custom table config (e.g. blue felt, smaller table)
	var custom_cfg := TableConfig.new()
	custom_cfg.table_id = &"blue_lagoon"
	custom_cfg.display_name = "Blue Lagoon Table"
	custom_cfg.felt_color = Color(0.1, 0.3, 0.7)
	custom_cfg.wood_color = Color(0.2, 0.15, 0.1)
	custom_cfg.table_width = 1.2
	custom_cfg.table_depth = 1.2
	custom_cfg.seat_count = 4

	# Setup 4 custom seats with unique positions
	for i in range(4):
		var seat := SeatConfig.create(i, "Player_%d" % i, i == 0,
			Vector2(0.0, 0.50 if i == 0 else -0.50),
			float(i * 90),
			Vector2(0.35, 0.10)
		)
		custom_cfg.seats.append(seat)

	table.set_table_config(custom_cfg)
	var active_cfg: TableConfig = table.get_table_config()
	ok = _check(active_cfg != null and active_cfg.table_id == &"blue_lagoon", "Table config was swapped to blue_lagoon") and ok
	ok = _check(active_cfg.felt_color == Color(0.1, 0.3, 0.7), "Table config felt color updated") and ok

	# Cleanup
	if tree != null and tree.root != null and table.get_parent() != null:
		tree.root.remove_child(table)
	table.free()

	if ok:
		print("  PASS  test_game_table_3d_table_config")
	else:
		print("  FAIL  test_game_table_3d_table_config")
	return ok


func _test_chair_swapping() -> bool:
	var ok: bool = true
	var scene: PackedScene = load("res://ui/GameTable3D.tscn")
	var table = scene.instantiate()

	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(table)

	# Verify chair 1 (East) can be repositioned / rotated independently
	var original_seat1: SeatConfig = table.get_seat_config(1)
	ok = _check(original_seat1 != null, "Original seat 1 exists") and ok
	ok = _check(is_equal_approx(original_seat1.rotation_y_deg, 90.0), "Original seat 1 is at 90 deg") and ok

	# Create a customized chair 1 configuration
	var custom_chair := SeatConfig.create(1, "VIP East", false,
		Vector2(0.60, 0.10), 105.0,
		Vector2(0.45, -0.20)
	)
	custom_chair.rack_scale = Vector3(0.6, 0.6, 0.6)

	table.set_seat_config(1, custom_chair)
	var updated_seat1: SeatConfig = table.get_seat_config(1)
	ok = _check(updated_seat1 != null, "Updated seat 1 exists") and ok
	if updated_seat1 != null:
		ok = _check(updated_seat1.label == "VIP East", "Seat 1 label was updated") and ok
		ok = _check(is_equal_approx(updated_seat1.rotation_y_deg, 105.0), "Seat 1 rotation updated to 105 deg") and ok
		ok = _check(updated_seat1.rack_position.is_equal_approx(Vector2(0.60, 0.10)), "Seat 1 rack position updated") and ok
		ok = _check(updated_seat1.rack_scale.is_equal_approx(Vector3(0.6, 0.6, 0.6)), "Seat 1 rack scale updated") and ok

	# Cleanup
	if tree != null and tree.root != null and table.get_parent() != null:
		tree.root.remove_child(table)
	table.free()

	if ok:
		print("  PASS  test_chair_swapping")
	else:
		print("  FAIL  test_chair_swapping")
	return ok


func _test_placeholder_table_config() -> bool:
	var ok: bool = true
	var scene: PackedScene = load("res://ui/PlaceholderTable.tscn")
	if scene == null:
		push_error("Failed to load PlaceholderTable.tscn")
		return false
	var table = scene.instantiate()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(table)

	# Configure for Poker
	table.configure_table(TabletopGameCatalog.GAME_POKER, {}, "test_puid", {}, "match_123", 42)
	var cfg = table.get_table_config()
	ok = _check(cfg != null and cfg.table_id == &"poker_holdem", "PlaceholderTable uses poker table config") and ok
	ok = _check(cfg.seat_count == 6, "PlaceholderTable poker seat count is 6") and ok

	# Swap to custom table config
	var custom_cfg := TableConfig.new()
	custom_cfg.table_id = &"custom_poker"
	custom_cfg.seat_count = 8
	table.set_table_config(custom_cfg)
	var active = table.get_table_config()
	ok = _check(active != null and active.table_id == &"custom_poker", "PlaceholderTable config was swapped") and ok
	ok = _check(active.seat_count == 8, "PlaceholderTable seat count updated to 8") and ok

	if tree != null and tree.root != null and table.get_parent() != null:
		tree.root.remove_child(table)
	table.free()

	if ok:
		print("  PASS  test_placeholder_table_config")
	else:
		print("  FAIL  test_placeholder_table_config")
	return ok


func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("game_table_config_swapping: " + message)
	return condition
