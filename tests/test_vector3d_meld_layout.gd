extends RefCounted

const MELD_LAYOUT_SCRIPT = preload("res://ui/vector_table/melds/MeldLayout3D.gd")

func run() -> bool:
	var ok: bool = _test_basic_layout()
	ok = _test_independent_seat_areas() and ok
	ok = _test_crowded_layout_32_melds() and ok
	if ok:
		print("  PASS  test_vector3d_meld_layout")
	return ok

func _check(value: bool, message: String) -> bool:
	if not value:
		push_error("test_vector3d_meld_layout: " + message)
	return value

func _test_basic_layout() -> bool:
	var layout = MELD_LAYOUT_SCRIPT.new()
	var melds: Array = [
		Meld.new(Meld.Kind.RUN, [1, 2, 3], [
			Tile.new(0, 4, Tile.Kind.NORMAL, 1),
			Tile.new(0, 5, Tile.Kind.NORMAL, 2),
			Tile.new(0, 6, Tile.Kind.NORMAL, 3),
		], 0), # Seat 0
		Meld.new(Meld.Kind.RUN, [4, 5, 6], [
			Tile.new(1, 7, Tile.Kind.NORMAL, 4),
			Tile.new(1, 8, Tile.Kind.NORMAL, 5),
			Tile.new(1, 9, Tile.Kind.NORMAL, 6),
		], 2), # Seat 2
	]

	layout.sync_melds(melds)

	var ok: bool = true
	ok = _check(layout.get_meld_count() == 2, "should have 2 melds") and ok
	ok = _check(layout.has_tile(1) and layout.has_tile(4), "all tile IDs tracked") and ok

	var xf1: Transform3D = layout.get_tile_transform(1)
	var xf4: Transform3D = layout.get_tile_transform(4)

	# Flat orientation: local +Z (face normal) points up along world +Y
	ok = _check(xf1.basis.z.dot(Vector3.UP) > 0.99, "tile 1 flat rotation face normal points up") and ok

	# Seat 0 meld should be South of Seat 2 meld (Z coordinate higher)
	var data0 = layout.get_meld_data(0)
	var data1 = layout.get_meld_data(1)
	ok = _check(data0.center_world_pos.z > data1.center_world_pos.z, "Seat 0 meld is south of Seat 2 meld") and ok
	ok = _check(data0.summary_text.begins_with("Run"), "summary text starts with Run: " + data0.summary_text) and ok

	layout.free()
	return ok

func _test_crowded_layout_32_melds() -> bool:
	var layout = MELD_LAYOUT_SCRIPT.new()
	var melds: Array = []

	# Build 32 melds of 4 tiles each (128 tiles total)
	for i in range(32):
		var tiles: Array = []
		var ids: Array = []
		for n in range(3, 7):
			var uid: int = 880000 + i * 10 + n
			tiles.append(Tile.new(i % 4, n, Tile.Kind.NORMAL, uid))
			ids.append(uid)
		melds.append(Meld.new(Meld.Kind.RUN, ids, tiles, i % 4))

	layout.sync_melds(melds)

	var ok: bool = true
	ok = _check(layout.get_meld_count() == 32, "should have 32 melds") and ok

	var all_tile_positions: Array[Vector3] = []
	for m_idx in range(32):
		var m_data = layout.get_meld_data(m_idx)
		for tid in m_data.tile_ids:
			ok = _check(layout.has_tile(tid), "tile %d must be tracked" % tid) and ok
			var pos: Vector3 = layout.get_tile_transform(tid).origin
			all_tile_positions.append(pos)

			# Must be inside meld zone
			ok = _check(pos.x >= -0.45 and pos.x <= 0.45, "tile X %f in bounds" % pos.x) and ok
			ok = _check(pos.z >= -0.31 and pos.z <= 0.21, "tile Z %f in bounds" % pos.z) and ok

			# Must not intersect stock box X [-0.08, 0.08], Z [-0.08, 0.02]
			var in_stock_box: bool = (pos.x >= -0.08 and pos.x <= 0.08 and pos.z >= -0.08 and pos.z <= 0.02)
			ok = _check(not in_stock_box, "tile %d must not intersect stock box" % tid) and ok

	# Verify strictly NO tile overlaps another tile (minimum distance between centers > 0.040 m)
	var overlap_count: int = 0
	for i in range(all_tile_positions.size()):
		for j in range(i + 1, all_tile_positions.size()):
			var p1 := all_tile_positions[i]
			var p2 := all_tile_positions[j]
			var dx: float = abs(p1.x - p2.x)
			var dz: float = abs(p1.z - p2.z)
			# Tile dimensions are 0.040 wide x 0.0598 deep
			if dx < 0.038 and dz < 0.056:
				overlap_count += 1
				push_error("Tile overlap detected between %d and %d: p1=%s p2=%s" % [i, j, str(p1), str(p2)])

	ok = _check(overlap_count == 0, "No tiles should overlap among 128 tiles in crowded mode") and ok

	layout.free()
	return ok

func _test_independent_seat_areas() -> bool:
	var layout = MELD_LAYOUT_SCRIPT.new()
	layout.independent_seat_areas = true
	var melds: Array = []
	# Legal, disjoint three-tile runs, deliberately supplied out of seat order.
	var seats := [2, 0, 3, 1]
	for seat in seats:
		var ids: Array = []
		var tiles: Array = []
		for number in range(4, 7):
			var uid: int = seat * 13 + number
			ids.append(uid)
			tiles.append(Tile.new(seat, number, Tile.Kind.NORMAL, uid))
		melds.append(Meld.new(Meld.Kind.RUN, ids, tiles, seat))
	layout.sync_melds(melds)
	var ok: bool = _check(layout.get_meld_count() == 4, "independent areas must retain four melds")
	for index in range(seats.size()):
		var seat: int = seats[index]
		var data: Dictionary = layout.get_meld_data(index)
		var anchor: Vector3 = layout.get_seat_area_position(seat)
		var expected_center := Vector3(anchor.x, MELD_LAYOUT_SCRIPT.TILE_Y, anchor.z)
		ok = _check(data.owner_index == seat, "independent meld must preserve owner and source index") and ok
		ok = _check(data.center_world_pos.is_equal_approx(expected_center), "seat %d meld must be centered at its own anchor" % seat) and ok
		var area: Area3D = layout.get_node("MeldArea_%d" % index)
		ok = _check(area.get_meta("meld_index") == index and area.get_meta("drop_target") == "meld", "drop target must identify matching meld") and ok
		ok = _check(area.position.is_equal_approx(data.center_world_pos), "drop area center must match rendered meld") and ok
		ok = _check(area.collision_layer == MELD_LAYOUT_SCRIPT.LAYER_ZONE, "meld drop target must be raycastable on zone layer") and ok
		var expected_basis := Basis.from_euler(Vector3(0.0, deg_to_rad(layout.get_seat_area_rotation_deg(seat).y), 0.0))
		ok = _check(area.basis.is_equal_approx(expected_basis), "drop target must follow seat orientation") and ok
		var box := (area.get_child(0) as CollisionShape3D).shape as BoxShape3D
		var positions: Array[Vector3] = []
		for tid in data.tile_ids:
			var xf: Transform3D = layout.get_tile_transform(tid)
			positions.append(xf.origin)
			ok = _check(xf.basis.x.is_equal_approx(expected_basis.x) and xf.basis.z.dot(Vector3.UP) > 0.99, "tile orientation must follow owner while lying face-up") and ok
			var local_pos: Vector3 = area.transform.affine_inverse() * xf.origin
			ok = _check(absf(local_pos.x) <= box.size.x * 0.5 and absf(local_pos.z) <= box.size.z * 0.5, "rendered tile center must lie inside its drop area") and ok
		var center: Vector3 = (positions[0] + positions[2]) * 0.5
		ok = _check(center.is_equal_approx(expected_center), "tile positions must straddle the owner anchor") and ok
		ok = _check((positions[2] - positions[0]).normalized().is_equal_approx(expected_basis.x), "run order must follow the seat's horizontal axis") and ok
	layout.free()
	return ok
