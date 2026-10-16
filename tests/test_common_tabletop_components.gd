extends RefCounted

const TABLE_ENV_SCRIPT = preload("res://ui/common_tabletop/TableEnvironment3D.gd")
const SEAT_BADGE_SCENE = preload("res://ui/common_tabletop/PlayerSeatBadge.tscn")
const TABLE_CATALOG = preload("res://gd/config/TabletopGameCatalog.gd")
const TABLE_CONFIG = preload("res://core/config/TableConfig.gd")

func _expect(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("FAIL: %s" % msg)
		print("FAIL: %s" % msg)
		return false
	return true

func run() -> bool:
	var ok: bool = true

	# 1. Test TableEnvironment3D default setup
	var env = TABLE_ENV_SCRIPT.new()
	ok = _expect(env != null, "TableEnvironment3D should instantiate") and ok
	env._ready()
	ok = _expect(env.get_surface() != null, "Table surface should be created") and ok
	env.free()

	# 2. Test TableEnvironment3D with Poker Hold'em TableConfig (6 seats)
	var poker_cfg = TABLE_CATALOG.default_table_config(TABLE_CATALOG.GAME_POKER)
	ok = _expect(poker_cfg != null, "Poker table config should be available") and ok
	var poker_env = TABLE_ENV_SCRIPT.new()
	poker_env.table_config = poker_cfg
	poker_env._ready()
	ok = _expect(poker_env.get_seat_anchor_count() == 6, "Poker TableEnvironment3D should have 6 seat anchors") and ok
	var seat0_anchor = poker_env.get_seat_anchor(0)
	var seat5_anchor = poker_env.get_seat_anchor(5)
	ok = _expect(seat0_anchor != null, "SeatAnchor0 should exist") and ok
	ok = _expect(seat5_anchor != null, "SeatAnchor5 should exist") and ok
	poker_env.free()

	# 3. Test TableEnvironment3D with Chess TableConfig (2 seats)
	var chess_cfg = TABLE_CATALOG.default_table_config(TABLE_CATALOG.GAME_CHESS)
	ok = _expect(chess_cfg != null, "Chess table config should be available") and ok
	var chess_env = TABLE_ENV_SCRIPT.new()
	chess_env.table_config = chess_cfg
	chess_env._ready()
	ok = _expect(chess_env.get_seat_anchor_count() == 2, "Chess TableEnvironment3D should have 2 seat anchors") and ok
	chess_env.free()

	# 4. Test PlayerSeatBadge component contracts
	var badge = SEAT_BADGE_SCENE.instantiate()
	ok = _expect(badge != null, "PlayerSeatBadge scene should instantiate") and ok
	badge.configure_seat(1, "Alice", false)
	badge.set_turn_active(true)
	badge.set_score(450)
	var name_lbl = badge.name_label
	var stats_lbl = badge.stats_label
	ok = _expect(name_lbl != null and name_lbl.text.contains("Alice"), "Player name should contain Alice") and ok
	ok = _expect(stats_lbl != null and stats_lbl.text.contains("450"), "Stats label should contain 450") and ok
	badge.free()

	print("  PASS  test_common_tabletop_components")
	return ok
