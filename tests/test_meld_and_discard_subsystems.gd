extends RefCounted

const MELD_TABLE_ZONE_SCRIPT = preload("res://ui/game_table/MeldTableZone3D.gd")
const DECK_AND_DISCARDS_SCRIPT = preload("res://ui/game_table/DeckAndDiscards3D.gd")
const CAMERA_RIG_SCRIPT = preload("res://ui/game_table/CameraRig.gd")
const SESSION_SCRIPT = preload("res://ui/game_table/OkeySession.gd")

func _expect(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("FAIL: %s" % msg)
		print("FAIL: %s" % msg)
		return false
	return true

class MockTile:
	extends RefCounted
	var unique_id: int
	var number: int
	var color: int
	var kind: int
	func _init(id: int, num: int = 1, col: int = 0) -> void:
		unique_id = id
		number = num
		color = col
		kind = 0

class MockMeld:
	extends RefCounted
	var owner_index: int = 0
	var kind: int = 0
	var tiles_data: Array = []
	var tiles: Array = []
	func _init(owner: int, t_data: Array) -> void:
		owner_index = owner
		tiles_data = t_data
		tiles = []
		for t in t_data:
			tiles.append(t.unique_id)

func run() -> bool:
	var ok: bool = true

	# 1. Test MeldTableZone3D
	var meld_zone = MELD_TABLE_ZONE_SCRIPT.new()
	ok = _expect(meld_zone != null, "MeldTableZone3D should instantiate") and ok
	ok = _expect(meld_zone.has_signal("extension_socket_hovered"), "Signal extension_socket_hovered missing") and ok
	ok = _expect(meld_zone.has_signal("extension_socket_dropped"), "Signal extension_socket_dropped missing") and ok
	ok = _expect(meld_zone.has_signal("fake_okey_swap_requested"), "Signal fake_okey_swap_requested missing") and ok

	var mock_melds: Array = [
		MockMeld.new(0, [MockTile.new(10), MockTile.new(11), MockTile.new(12)]),
		MockMeld.new(1, [MockTile.new(20), MockTile.new(21), MockTile.new(22), MockTile.new(23)])
	]
	meld_zone.sync_melds(mock_melds)
	ok = _expect(meld_zone.get_meld_count() == 2, "Meld count should be 2") and ok

	# Each meld should generate 2 sockets: HEAD and TAIL => 4 total
	var hits: Array[Dictionary] = meld_zone.get_socket_hits()
	ok = _expect(hits.size() == 4, "Expected 4 socket hits (2 per meld), got %d" % hits.size()) and ok

	meld_zone.highlight_valid_sockets(13, [0])
	var node0 = hits[0].get("node") as MeshInstance3D
	var node2 = hits[2].get("node") as MeshInstance3D
	ok = _expect(node0 != null and node0.visible == true, "Socket 0 should be visible when highlighted") and ok
	ok = _expect(node2 != null and node2.visible == false, "Socket 2 should remain invisible when not in valid targets") and ok

	meld_zone.clear_socket_highlights()
	ok = _expect(node0.visible == false, "Socket 0 should be hidden after clear") and ok

	meld_zone.free()

	# 2. Test DeckAndDiscards3D
	var deck_discards = DECK_AND_DISCARDS_SCRIPT.new()
	ok = _expect(deck_discards != null, "DeckAndDiscards3D should instantiate") and ok
	ok = _expect(deck_discards.has_signal("draw_requested"), "Signal draw_requested missing") and ok
	ok = _expect(deck_discards.has_signal("take_discard_requested"), "Signal take_discard_requested missing") and ok
	ok = _expect(deck_discards.has_signal("discard_dropped"), "Signal discard_dropped missing") and ok

	deck_discards._ready()
	deck_discards.configure_layout(0.38)
	var local_discard_pos: Vector3 = deck_discards.get_local_discard_world_pos()
	ok = _expect(local_discard_pos.x > 0.0 and local_discard_pos.z > 0.0, "Seat 0 discard pile should be in positive quadrant") and ok

	deck_discards.free()

	# 3. Test CameraRig tweening contracts
	var cam := Camera3D.new()
	var camera_rig = CAMERA_RIG_SCRIPT.new(cam)
	ok = _expect(camera_rig.has_method("tween_to_inspection"), "tween_to_inspection missing on CameraRig") and ok
	ok = _expect(camera_rig.has_method("tween_to_default"), "tween_to_default missing on CameraRig") and ok
	# Calling in headless without SceneTree falls back safely to instantaneous adaptive apply
	camera_rig.tween_to_inspection(Vector2(1920, 1080))
	ok = _expect(camera_rig.is_inspection(), "CameraRig should be in inspection mode") and ok
	camera_rig.tween_to_default(Vector2(1920, 1080))
	ok = _expect(not camera_rig.is_inspection(), "CameraRig should return to default view") and ok
	cam.free()

	# 4. Test OkeySession request_extend_table_meld
	var session = SESSION_SCRIPT.new()
	ok = _expect(session.has_method("request_extend_table_meld"), "request_extend_table_meld missing on OkeySession") and ok
	session.free()

	print("  PASS  test_meld_and_discard_subsystems")
	return ok
