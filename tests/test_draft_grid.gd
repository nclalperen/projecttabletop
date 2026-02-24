extends RefCounted

const DRAFT_GRID = preload("res://ui/game_table/DraftGrid.gd")

func run() -> bool:
	var ok: bool = true
	var lane := Rect2(100.0, 50.0, 240.0, 120.0)
	var slot_count: int = 24
	var row_slots: int = 12

	ok = _expect(DRAFT_GRID.row_count(slot_count, row_slots) == 2, "row_count expected 2") and ok

	var slot_tl: int = DRAFT_GRID.point_to_slot(Vector2(102.0, 52.0), lane, slot_count, row_slots, 0.0)
	ok = _expect(slot_tl == 0, "top-left point should map to slot 0, got %d" % slot_tl) and ok

	var slot_br: int = DRAFT_GRID.point_to_slot(Vector2(339.0, 169.0), lane, slot_count, row_slots, 0.0)
	ok = _expect(slot_br == 23, "bottom-right point should map to slot 23, got %d" % slot_br) and ok

	var outside: int = DRAFT_GRID.point_to_slot(Vector2(90.0, 40.0), lane, slot_count, row_slots, 0.0)
	ok = _expect(outside == -1, "outside point should map to -1") and ok

	var c0: Vector2 = DRAFT_GRID.slot_to_point(0, lane, slot_count, row_slots)
	var c23: Vector2 = DRAFT_GRID.slot_to_point(23, lane, slot_count, row_slots)
	ok = _expect(c0.x < c23.x and c0.y < c23.y, "slot center ordering mismatch") and ok

	var slot_from_c0: int = DRAFT_GRID.point_to_slot(c0, lane, slot_count, row_slots, 0.0)
	var slot_from_c23: int = DRAFT_GRID.point_to_slot(c23, lane, slot_count, row_slots, 0.0)
	ok = _expect(slot_from_c0 == 0, "slot_to_point/point_to_slot roundtrip failed for slot 0") and ok
	ok = _expect(slot_from_c23 == 23, "slot_to_point/point_to_slot roundtrip failed for slot 23") and ok

	if ok:
		print("  PASS  test_draft_grid")
	else:
		print("  FAIL  test_draft_grid")
	return ok

func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
