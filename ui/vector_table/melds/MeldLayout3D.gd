class_name MeldLayout3D
extends Node3D

## 3D Vector Meld Layout & Shelf-Packing.
## Packs table melds into rows inside the D5 meld zone without overlap.
## Generates drop Area3Ds (layer 3 / bitmask 4) and world anchors for HUD pills.

const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")

const MELD_ZONE_MIN := Vector2(-0.44, -0.30)
const MELD_ZONE_MAX := Vector2(0.44, 0.20)
const TILE_W: float = 0.040
const TILE_L: float = 0.0598
const TILE_Y: float = TUNING.TABLE_SURFACE_Y + 0.005
const LAYER_ZONE: int = 4 # collision layer 3 (bitmask 4)

# Runtime layout tuning properties (adjustable live via BoardLayoutTuner3D)
var independent_seat_areas: bool = false
var seat_area_pos: Dictionary = {
	0: TUNING.MELD_AREA_POS_3D[0],
	1: TUNING.MELD_AREA_POS_3D[1],
	2: TUNING.MELD_AREA_POS_3D[2],
	3: TUNING.MELD_AREA_POS_3D[3],
}
var seat_area_rot_deg: Dictionary = {
	0: TUNING.MELD_AREA_ROT_DEG[0],
	1: TUNING.MELD_AREA_ROT_DEG[1],
	2: TUNING.MELD_AREA_ROT_DEG[2],
	3: TUNING.MELD_AREA_ROT_DEG[3],
}
var seat_area_size: Dictionary = {
	0: TUNING.MELD_AREA_SIZE[0],
	1: TUNING.MELD_AREA_SIZE[1],
	2: TUNING.MELD_AREA_SIZE[2],
	3: TUNING.MELD_AREA_SIZE[3],
}
var seat_area_scales: Dictionary = {
	0: 1.0,
	1: 1.0,
	2: 1.0,
	3: 1.0,
}

var zone_offset: Vector3 = Vector3.ZERO
var zone_yaw_deg: float = 0.0
var per_seat_orientation: bool = false
var seat_offsets: Dictionary = {
	0: Vector3.ZERO,
	1: Vector3.ZERO,
	2: Vector3.ZERO,
	3: Vector3.ZERO,
}
var seat_yaw_deg: Dictionary = {
	0: 0.0,
	1: 0.0,
	2: 0.0,
	3: 0.0,
}
var row_pitch_scale: float = 1.0
var tile_pitch_scale: float = 1.0
var group_gap_scale: float = 1.0

# Meld index -> Dictionary of layout metadata
var _melds_data: Array[Dictionary] = []
# Tile unique_id -> Transform3D
var _tile_transforms: Dictionary = {}
# Area3D drop zones
var _drop_areas: Array[Area3D] = []


func get_seat_area_position(seat: int) -> Vector3:
	return seat_area_pos.get(seat, TUNING.MELD_AREA_POS_3D.get(seat, Vector3.ZERO))


func get_seat_area_rotation_deg(seat: int) -> Vector3:
	return seat_area_rot_deg.get(seat, TUNING.MELD_AREA_ROT_DEG.get(seat, Vector3.ZERO))


func get_seat_area_size(seat: int) -> Vector2:
	return seat_area_size.get(seat, TUNING.MELD_AREA_SIZE.get(seat, Vector2(0.50, 0.145)))


func get_seat_area_scale(seat: int) -> float:
	return float(seat_area_scales.get(seat, 1.0))


func set_seat_area_transform(seat: int, pos: Vector3, rot_deg: Vector3, area_size: Vector2 = Vector2.ZERO, area_scale: float = 1.0) -> void:
	seat_area_pos[seat] = pos
	seat_area_rot_deg[seat] = rot_deg
	if area_size != Vector2.ZERO:
		seat_area_size[seat] = area_size
	seat_area_scales[seat] = area_scale


func clear() -> void:
	for area in _drop_areas:
		if is_instance_valid(area):
			area.queue_free()
	_drop_areas.clear()
	_melds_data.clear()
	_tile_transforms.clear()


func sync_melds(table_melds: Array, okey_context = null) -> void:
	clear()
	if table_melds.is_empty():
		return

	if independent_seat_areas:
		_sync_independent_seat_areas(table_melds, okey_context)
		return

	var total_melds := table_melds.size()

	# Adaptive spacing to guarantee zero overlaps across any meld count (up to 32+)
	var tile_pitch: float = 0.046
	var group_gap: float = 0.030
	var row_pitch: float = 0.075
	var num_rows: int = 4

	if total_melds <= 4:
		tile_pitch = 0.046
		group_gap = 0.032
		row_pitch = 0.075
		num_rows = 4
	elif total_melds <= 12:
		tile_pitch = 0.045
		group_gap = 0.024
		row_pitch = 0.070
		num_rows = 4
	elif total_melds <= 20:
		tile_pitch = 0.043
		group_gap = 0.020
		row_pitch = 0.065
		num_rows = 6
	else:
		# 21 to 32+ melds (fixture crowded: 32 melds x 4 tiles)
		tile_pitch = 0.0415 # > TILE_W (0.040), so strictly no tile overlap in X
		group_gap = 0.016
		row_pitch = 0.062 # > TILE_L (0.0598), so strictly no tile overlap in Z
		num_rows = 8

	tile_pitch *= tile_pitch_scale
	group_gap *= group_gap_scale
	row_pitch *= row_pitch_scale

	# Compute row Z centers from South (+Z) to North (-Z)
	var z_start: float = (0.045 if num_rows <= 4 else 0.138) + zone_offset.z
	var row_z_positions: Array[float] = []
	for r in range(num_rows):
		row_z_positions.append(z_start - float(r) * row_pitch)

	# Group melds by owner seat: 0 (South), 1 (East), 2 (North), 3 (West)
	var melds_by_seat: Dictionary = {0: [], 1: [], 2: [], 3: []}
	for i in range(total_melds):
		var meld = table_melds[i]
		var owner: int = 0
		if meld is Dictionary:
			owner = int(meld.get("owner_index", 0)) % 4
		elif "owner_index" in meld:
			owner = int(meld.owner_index) % 4
		melds_by_seat[owner].append({"index": i, "meld": meld})

	# Assign seats to preferred row subsets
	# Seat 0 -> Rows closest to South (r=0, 1)
	# Seat 1 -> Middle East rows (r=2, 3)
	# Seat 3 -> Middle West rows (r=4, 5)
	# Seat 2 -> Rows closest to North (r=6, 7)
	var rows_for_seat: Dictionary = {}
	if num_rows == 4:
		rows_for_seat[0] = [0]
		rows_for_seat[1] = [1]
		rows_for_seat[3] = [2]
		rows_for_seat[2] = [3]
	elif num_rows == 6:
		rows_for_seat[0] = [0, 1]
		rows_for_seat[1] = [2]
		rows_for_seat[3] = [3]
		rows_for_seat[2] = [4, 5]
	else: # 8 rows
		rows_for_seat[0] = [0, 1]
		rows_for_seat[1] = [2, 3]
		rows_for_seat[3] = [4, 5]
		rows_for_seat[2] = [6, 7]

	# Layout melds per seat
	var row_placed_melds: Dictionary = {} # row_idx -> Array of {index, meld, width, tile_ids, tiles}
	for r in range(num_rows):
		row_placed_melds[r] = []

	for seat in [0, 1, 3, 2]:
		var seat_items: Array = melds_by_seat[seat]
		var candidate_rows: Array = rows_for_seat.get(seat, [0])
		var current_row_idx: int = candidate_rows[0]
		var candidate_ptr: int = 0

		for item in seat_items:
			var m = item["meld"]
			var ids: Array = _extract_tile_ids(m)
			var tiles_arr: Array = _extract_tiles(m)
			var count: int = ids.size()
			var meld_width: float = (float(maxi(1, count) - 1) * tile_pitch) + TILE_W

			# Check if fits in current_row_idx
			var current_row_melds: Array = row_placed_melds[current_row_idx]
			var row_width := _calc_row_width(current_row_melds, group_gap)
			var max_row_width: float = 0.84

			if row_width + group_gap + meld_width > max_row_width:
				# Advance to next preferred row for this seat if available
				candidate_ptr += 1
				if candidate_ptr < candidate_rows.size():
					current_row_idx = candidate_rows[candidate_ptr]
				else:
					# Find row with least width
					current_row_idx = _find_least_filled_row(row_placed_melds, num_rows)

			row_placed_melds[current_row_idx].append({
				"index": item["index"],
				"meld": m,
				"width": meld_width,
				"tile_ids": ids,
				"tiles": tiles_arr,
				"owner": seat
			})

	# Position tiles in each row and build Area3Ds
	_melds_data.resize(total_melds)

	for r in range(num_rows):
		var melds_in_row: Array = row_placed_melds[r]
		if melds_in_row.is_empty():
			continue

		var z_pos: float = row_z_positions[r]
		var crosses_stock: bool = (z_pos >= -0.125 and z_pos <= 0.065)

		if crosses_stock:
			if melds_in_row.size() >= 2:
				var half: int = int(ceil(float(melds_in_row.size()) / 2.0))
				var left_melds = melds_in_row.slice(0, half)
				var right_melds = melds_in_row.slice(half)

				var left_w := _calc_row_width(left_melds, group_gap)
				var left_start := -0.10 - left_w
				_position_melds_subrow(left_melds, left_start, z_pos, tile_pitch, group_gap, row_pitch, okey_context)

				var right_start := 0.10
				_position_melds_subrow(right_melds, right_start, z_pos, tile_pitch, group_gap, row_pitch, okey_context)
			else:
				var total_w := _calc_row_width(melds_in_row, group_gap)
				var left_start := -0.10 - total_w
				_position_melds_subrow(melds_in_row, left_start, z_pos, tile_pitch, group_gap, row_pitch, okey_context)
		else:
			var total_w := _calc_row_width(melds_in_row, group_gap)
			var start_x: float = -(total_w * 0.5)
			_position_melds_subrow(melds_in_row, start_x, z_pos, tile_pitch, group_gap, row_pitch, okey_context)


func _sync_independent_seat_areas(table_melds: Array, okey_context = null) -> void:
	var total_melds := table_melds.size()
	_melds_data.resize(total_melds)

	var melds_by_seat: Dictionary = {0: [], 1: [], 2: [], 3: []}
	for i in range(total_melds):
		var meld = table_melds[i]
		var owner: int = 0
		if meld is Dictionary:
			owner = int(meld.get("owner_index", 0)) % 4
		elif "owner_index" in meld:
			owner = int(meld.owner_index) % 4
		if owner < 0:
			owner = 0
		melds_by_seat[owner].append({"index": i, "meld": meld})

	for seat in range(4):
		var seat_items: Array = melds_by_seat[seat]
		if seat_items.is_empty():
			continue

		var area_pos: Vector3 = get_seat_area_position(seat)
		var area_rot: Vector3 = get_seat_area_rotation_deg(seat)
		var area_sz: Vector2 = get_seat_area_size(seat)
		var area_sc: float = get_seat_area_scale(seat)
		var yaw_deg: float = area_rot.y

		var tile_pitch: float = 0.044 * tile_pitch_scale * area_sc
		var group_gap: float = 0.022 * group_gap_scale * area_sc
		var row_pitch: float = 0.066 * row_pitch_scale * area_sc
		var max_row_w: float = maxf(0.22, area_sz.x * area_sc)

		# Pack this seat's melds into local rows within its own independent area box
		var local_rows: Array = [[]]
		for item in seat_items:
			var m = item["meld"]
			var ids: Array = _extract_tile_ids(m)
			var tiles_arr: Array = _extract_tiles(m)
			var count: int = ids.size()
			var meld_w: float = (float(maxi(1, count) - 1) * tile_pitch) + (TILE_W * area_sc)

			var cur_row: Array = local_rows[local_rows.size() - 1]
			var cur_w: float = _calc_row_width(cur_row, group_gap)
			if not cur_row.is_empty() and (cur_w + group_gap + meld_w > max_row_w):
				local_rows.append([])
				cur_row = local_rows[local_rows.size() - 1]

			cur_row.append({
				"index": item["index"],
				"meld": m,
				"width": meld_w,
				"tile_ids": ids,
				"tiles": tiles_arr,
				"owner": seat,
			})

		var num_seat_rows: int = local_rows.size()
		var seat_basis := Basis.from_euler(Vector3(0.0, deg_to_rad(yaw_deg), 0.0))
		var tile_basis := seat_basis * Basis.from_euler(Vector3(deg_to_rad(-90.0), 0.0, 0.0))

		for r_idx in range(num_seat_rows):
			var row_melds: Array = local_rows[r_idx]
			if row_melds.is_empty():
				continue
			var total_row_w: float = _calc_row_width(row_melds, group_gap)
			var local_x: float = -total_row_w * 0.5
			var local_z: float = (float(r_idx) - float(num_seat_rows - 1) * 0.5) * row_pitch

			for m_info in row_melds:
				var m_idx: int = m_info["index"]
				var m_w: float = m_info["width"]
				var ids: Array = m_info["tile_ids"]
				var count: int = ids.size()

				var local_group_center := Vector3(local_x + m_w * 0.5, 0.0, local_z)
				var center_pos: Vector3 = Vector3(area_pos.x, TILE_Y, area_pos.z) + (seat_basis * local_group_center)

				for k in range(count):
					var tid: int = ids[k]
					var local_dx: float = (float(k) - float(count - 1) * 0.5) * tile_pitch
					var t_pos: Vector3 = center_pos + (seat_basis * Vector3(local_dx, 0.0, 0.0))
					_tile_transforms[tid] = Transform3D(tile_basis, t_pos)

				var summary_text := format_summary(m_info["meld"], okey_context)

				var area := Area3D.new()
				area.name = "MeldArea_%d" % m_idx
				area.collision_layer = LAYER_ZONE
				area.collision_mask = 0
				area.monitoring = false
				area.monitorable = true
				area.set_meta("drop_target", "meld")
				area.set_meta("meld_index", m_idx)
				area.position = center_pos
				area.rotation_degrees = Vector3(0.0, yaw_deg, 0.0)

				var c_shape := CollisionShape3D.new()
				var box := BoxShape3D.new()
				box.size = Vector3(m_w + 0.02, 0.03, row_pitch * 0.90)
				c_shape.shape = box
				area.add_child(c_shape)
				add_child(area)
				_drop_areas.append(area)

				_melds_data[m_idx] = {
					"meld_id": m_idx,
					"center_world_pos": center_pos,
					"summary_text": summary_text,
					"owner_index": seat,
					"width": m_w,
					"tile_ids": ids,
					"tiles": m_info["tiles"],
				}

				local_x += m_w + group_gap


func _position_melds_subrow(sub_melds: Array, start_x: float, z_pos: float, tile_pitch: float, group_gap: float, row_pitch: float, okey_context) -> void:
	var cur_x: float = start_x + zone_offset.x
	var zone_rot := Basis.from_euler(Vector3(0.0, deg_to_rad(zone_yaw_deg), 0.0))

	for m_info in sub_melds:
		var m_idx: int = m_info["index"]
		var m_w: float = m_info["width"]
		var ids: Array = m_info["tile_ids"]
		var count: int = ids.size()
		var owner_seat: int = int(m_info.get("owner", 0))

		var seat_off: Vector3 = seat_offsets.get(owner_seat, Vector3.ZERO)
		var auto_seat_yaw: float = 0.0
		if per_seat_orientation:
			match owner_seat:
				0: auto_seat_yaw = 0.0
				1: auto_seat_yaw = -90.0
				2: auto_seat_yaw = 180.0
				3: auto_seat_yaw = 90.0
		var total_yaw_deg: float = zone_yaw_deg + auto_seat_yaw + float(seat_yaw_deg.get(owner_seat, 0.0))
		var group_yaw_basis := Basis.from_euler(Vector3(0.0, deg_to_rad(auto_seat_yaw + float(seat_yaw_deg.get(owner_seat, 0.0))), 0.0))
		var tile_basis := Basis.from_euler(Vector3(0.0, deg_to_rad(total_yaw_deg), 0.0)) * Basis.from_euler(Vector3(deg_to_rad(-90.0), 0.0, 0.0))

		var local_center := Vector3(cur_x + (m_w * 0.5) - zone_offset.x, 0.0, z_pos - zone_offset.z)
		var rotated_center: Vector3 = zone_rot * local_center
		var center_pos := Vector3(rotated_center.x + zone_offset.x + seat_off.x, TILE_Y + zone_offset.y + seat_off.y, rotated_center.z + zone_offset.z + seat_off.z)

		for k in range(count):
			var tid: int = ids[k]
			var local_tile_dx: float = (float(k) - float(count - 1) * 0.5) * tile_pitch
			var offset_vec: Vector3 = (zone_rot * group_yaw_basis) * Vector3(local_tile_dx, 0.0, 0.0)
			var t_pos := center_pos + offset_vec
			_tile_transforms[tid] = Transform3D(tile_basis, t_pos)

		var summary_text := format_summary(m_info["meld"], okey_context)

		var area := Area3D.new()
		area.name = "MeldArea_%d" % m_idx
		area.collision_layer = LAYER_ZONE
		area.collision_mask = 0
		area.monitoring = false
		area.monitorable = true
		area.set_meta("drop_target", "meld")
		area.set_meta("meld_index", m_idx)
		area.position = center_pos
		area.rotation_degrees = Vector3(0.0, total_yaw_deg, 0.0)

		var c_shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(m_w + 0.02, 0.03, row_pitch * 0.90)
		c_shape.shape = box
		area.add_child(c_shape)
		add_child(area)
		_drop_areas.append(area)

		_melds_data[m_idx] = {
			"meld_id": m_idx,
			"center_world_pos": center_pos,
			"summary_text": summary_text,
			"owner_index": owner_seat,
			"width": m_w,
			"tile_ids": ids,
			"tiles": m_info["tiles"],
		}

		cur_x += m_w + group_gap




func get_tile_transform(tile_id: int) -> Transform3D:
	return _tile_transforms.get(tile_id, Transform3D.IDENTITY)


func has_tile(tile_id: int) -> bool:
	return _tile_transforms.has(tile_id)


func get_meld_data(meld_index: int) -> Dictionary:
	if meld_index >= 0 and meld_index < _melds_data.size():
		return _melds_data[meld_index]
	return {}


func get_all_meld_data() -> Array[Dictionary]:
	return _melds_data


func get_meld_count() -> int:
	return _melds_data.size()


static func _calc_row_width(melds_in_row: Array, gap: float) -> float:
	if melds_in_row.is_empty():
		return 0.0
	var sum: float = 0.0
	for m in melds_in_row:
		sum += float(m.get("width", 0.0))
	sum += float(maxi(0, melds_in_row.size() - 1)) * gap
	return sum


static func _find_least_filled_row(row_placed_melds: Dictionary, num_rows: int) -> int:
	var best_r: int = 0
	var min_w: float = 999.0
	for r in range(num_rows):
		var w := _calc_row_width(row_placed_melds[r], 0.02)
		if w < min_w:
			min_w = w
			best_r = r
	return best_r


static func _extract_tile_ids(meld) -> Array:
	if meld is Dictionary:
		if meld.has("tile_ids"):
			return meld.get("tile_ids", [])
		if meld.has("tiles"):
			var raw = meld.get("tiles", [])
			var ids: Array = []
			for t in raw:
				if t is int:
					ids.append(t)
				elif t is Tile:
					ids.append(t.unique_id)
				elif t is Dictionary:
					ids.append(int(t.get("unique_id", -1)))
			return ids
	elif meld is Object:
		if "tile_ids" in meld and meld.tile_ids != null:
			return meld.tile_ids
		if "tiles" in meld and meld.tiles != null:
			var ids: Array = []
			for t in meld.tiles:
				if t is int:
					ids.append(t)
				elif t is Tile:
					ids.append(t.unique_id)
				elif t is Dictionary:
					ids.append(int(t.get("unique_id", -1)))
			return ids
	return []


static func _extract_tiles(meld) -> Array:
	if meld is Dictionary:
		return meld.get("tiles", [])
	elif meld is Object:
		if "tiles_data" in meld and meld.tiles_data != null and not meld.tiles_data.is_empty():
			return meld.tiles_data
		if "tiles" in meld and meld.tiles != null:
			return meld.tiles
	return []



static func format_summary(meld, okey_context = null) -> String:
	var kind_str := "Run"
	var kind_val := 0
	if meld is Dictionary:
		kind_val = int(meld.get("kind", 0))
	elif "kind" in meld:
		kind_val = int(meld.kind)

	if kind_val == Meld.Kind.RUN:
		kind_str = "Run"
	elif kind_val == Meld.Kind.SET:
		kind_str = "Set"
	elif kind_val == Meld.Kind.PAIRS:
		kind_str = "Pairs"

	var tiles_arr: Array = _extract_tiles(meld)
	var count: int = tiles_arr.size()
	if count == 0:
		count = _extract_tile_ids(meld).size()

	var pts: int = 0
	var nums: Array[String] = []
	for t in tiles_arr:
		if t is Tile:
			pts += t.points_value(okey_context)
			nums.append(str(t.number))
		elif t is Dictionary:
			pts += int(t.get("number", 0))
			nums.append(str(t.get("number", 0)))

	if not nums.is_empty() and kind_val != Meld.Kind.PAIRS:
		var seq := "-".join(nums)
		if pts > 0:
			return "%s %s · %d pts" % [kind_str, seq, pts]
		return "%s %s" % [kind_str, seq]
	elif pts > 0:
		return "%s (%d) · %d pts" % [kind_str, count, pts]
	return "%s (%d)" % [kind_str, count]
