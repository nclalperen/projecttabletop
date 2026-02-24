extends RefCounted

const RACK_SLOT_MANAGER = preload("res://ui/game_table/RackSlotManager.gd")

class FakeTile:
	extends RefCounted
	var unique_id: int

	func _init(id: int) -> void:
		unique_id = id

func run() -> bool:
	var ok: bool = true
	var slots = RACK_SLOT_MANAGER.new()

	slots.init_rack_slots(6)
	slots.init_draft_slots(4)
	ok = _expect(slots.rack_slots.size() == 6, "init_rack_slots size mismatch") and ok
	ok = _expect(slots.draft_slots.size() == 4, "init_draft_slots size mismatch") and ok

	slots.rack_slots[0] = 11
	slots.rack_slots[1] = 22
	ok = _expect(slots.move_slot(0, 1), "move_slot should succeed") and ok
	ok = _expect(slots.rack_slots == [22, 11, -1, -1, -1, -1], "move_slot should swap rack slots") and ok
	ok = _expect(slots.last_tile_id == 11, "move_slot should update last_tile_id") and ok

	ok = _expect(slots.move_rack_to_draft(1, 2, 2, 4), "move_rack_to_draft should succeed") and ok
	ok = _expect(slots.rack_slots[1] == -1, "move_rack_to_draft should clear source rack slot") and ok
	ok = _expect(slots.draft_slots[2] == 11, "move_rack_to_draft should place tile into draft") and ok
	ok = _expect(not slots.move_rack_to_draft(1, 0, 2, 4), "move_rack_to_draft should fail for empty source") and ok

	slots.rack_slots[3] = 33
	ok = _expect(slots.move_draft_to_rack(2, 3), "move_draft_to_rack should succeed") and ok
	ok = _expect(slots.rack_slots[3] == 11, "move_draft_to_rack should place draft tile to rack") and ok
	ok = _expect(slots.draft_slots[2] == 33, "move_draft_to_rack should swap into draft") and ok

	slots.draft_slots[0] = 44
	slots.draft_slots[1] = 55
	ok = _expect(slots.move_draft_slot(0, 1), "move_draft_slot should succeed") and ok
	ok = _expect(slots.draft_slots[0] == 55 and slots.draft_slots[1] == 44, "move_draft_slot should swap draft tiles") and ok

	var hand: Array = [FakeTile.new(11), FakeTile.new(66)]
	slots.sync_slots_with_hand(hand)
	ok = _expect(slots.rack_slots.has(11), "sync_slots_with_hand should keep existing hand tile") and ok
	ok = _expect(slots.rack_slots.has(66), "sync_slots_with_hand should insert new hand tile") and ok
	ok = _expect(not slots.draft_slots.has(33), "sync_slots_with_hand should remove draft tile not in hand") and ok
	ok = _expect(not slots.rack_slots.has(22), "sync_slots_with_hand should remove rack tile not in hand") and ok

	slots.draft_slots[0] = 77
	slots.draft_slots[1] = 88
	slots.restore_draft_to_rack()
	ok = _expect(not slots.draft_slots.has(77) and not slots.draft_slots.has(88), "restore_draft_to_rack should clear moved draft tiles") and ok
	ok = _expect(slots.rack_slots.has(77) and slots.rack_slots.has(88), "restore_draft_to_rack should move tiles into rack") and ok

	slots.draft_slots[2] = 99
	slots.draft_slots[3] = 100
	slots.clear_draft_slots()
	ok = _expect(
		slots.draft_slots[0] == -1 and slots.draft_slots[1] == -1 and slots.draft_slots[2] == -1 and slots.draft_slots[3] == -1,
		"clear_draft_slots should reset draft"
	) and ok
	ok = _expect(not slots.has_draft_tiles(), "has_draft_tiles should be false after clear_draft_slots") and ok

	if ok:
		print("  PASS  test_rack_slot_manager")
	else:
		print("  FAIL  test_rack_slot_manager")
	return ok

func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
