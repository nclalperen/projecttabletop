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
	# Test fluid place_tile_at (empty slot drop preserves other tiles)
	slots.init_rack_slots(30)
	slots.rack_slots[0] = 101
	slots.rack_slots[1] = 102
	slots.rack_slots[2] = 103
	slots.rack_slots[10] = -1
	ok = _expect(slots.place_tile_at(0, 10), "place_tile_at to empty slot should succeed") and ok
	ok = _expect(slots.rack_slots[0] == -1, "source slot 0 should be empty") and ok
	ok = _expect(slots.rack_slots[1] == 102 and slots.rack_slots[2] == 103, "intervening slots 1 and 2 must NOT be displaced") and ok
	ok = _expect(slots.rack_slots[10] == 101, "tile 101 should be placed in slot 10") and ok

	# Test fluid place_tile_at into occupied slot (shoves adjacent tiles aside towards gap)
	slots.init_rack_slots(30)
	slots.rack_slots[4] = 201
	slots.rack_slots[5] = 202
	slots.rack_slots[6] = 203
	slots.rack_slots[7] = -1
	slots.rack_slots[0] = 999
	ok = _expect(slots.place_tile_at(0, 5), "place_tile_at into occupied slot should succeed") and ok
	ok = _expect(slots.rack_slots[0] == -1, "source slot should be cleared") and ok
	ok = _expect(slots.rack_slots[4] == 201, "slot 4 should remain undisturbed") and ok
	ok = _expect(slots.rack_slots[5] == 999, "slot 5 should now hold tile 999") and ok
	ok = _expect(slots.rack_slots[6] == 202, "slot 5 tile should shove to slot 6") and ok
	ok = _expect(slots.rack_slots[7] == 203, "slot 6 tile should shove into gap at slot 7") and ok

	# Test place_group_at (group move and shove into space)
	slots.init_rack_slots(30)
	slots.rack_slots[0] = 301
	slots.rack_slots[1] = 302
	slots.rack_slots[2] = 303
	slots.rack_slots[8] = 401
	slots.rack_slots[9] = 402
	# Move group [0, 1, 2] into slot 8 (shoving 401, 402 to the right)
	var grp_slots: Array[int] = [0, 1, 2]
	ok = _expect(slots.place_group_at(grp_slots, 8), "place_group_at should succeed") and ok
	ok = _expect(slots.rack_slots[0] == -1 and slots.rack_slots[1] == -1 and slots.rack_slots[2] == -1, "source group slots cleared") and ok
	ok = _expect(slots.rack_slots[8] == 301 and slots.rack_slots[9] == 302 and slots.rack_slots[10] == 303, "group placed at slots 8..10") and ok
	ok = _expect(slots.rack_slots[11] == 401 and slots.rack_slots[12] == 402, "shoved tiles placed after group") and ok

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
