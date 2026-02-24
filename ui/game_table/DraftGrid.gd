class_name DraftGrid
extends RefCounted

static func row_count(slot_count: int, row_slots: int) -> int:
	var safe_slots: int = maxi(1, slot_count)
	var cols: int = maxi(1, mini(row_slots, safe_slots))
	return maxi(1, int(ceil(float(safe_slots) / float(cols))))

static func point_to_slot(point: Vector2, lane_rect: Rect2, slot_count: int, row_slots: int, margin: float = 0.0) -> int:
	if slot_count <= 0:
		return -1
	var hit_rect: Rect2 = lane_rect.grow(maxf(0.0, margin))
	if not hit_rect.has_point(point):
		return -1
	var cols: int = maxi(1, mini(row_slots, slot_count))
	var rows: int = row_count(slot_count, row_slots)
	var lane_w: float = maxf(0.0001, lane_rect.size.x)
	var lane_h: float = maxf(0.0001, lane_rect.size.y)
	var rel_x: float = clampf((point.x - lane_rect.position.x) / lane_w, 0.0, 0.9999)
	var rel_y: float = clampf((point.y - lane_rect.position.y) / lane_h, 0.0, 0.9999)
	var col: int = clampi(int(floor(rel_x * float(cols))), 0, cols - 1)
	var row: int = clampi(int(floor(rel_y * float(rows))), 0, rows - 1)
	var idx: int = row * cols + col
	return mini(slot_count - 1, idx)

static func slot_to_point(slot_index: int, lane_rect: Rect2, slot_count: int, row_slots: int) -> Vector2:
	if slot_count <= 0:
		return lane_rect.get_center()
	var idx: int = clampi(slot_index, 0, slot_count - 1)
	var cols: int = maxi(1, mini(row_slots, slot_count))
	var rows: int = row_count(slot_count, row_slots)
	var row: int = int(floor(float(idx) / float(cols)))
	var col: int = idx % cols
	var cell_w: float = lane_rect.size.x / float(cols)
	var cell_h: float = lane_rect.size.y / float(rows)
	return lane_rect.position + Vector2(
		cell_w * (float(col) + 0.5),
		cell_h * (float(row) + 0.5)
	)
