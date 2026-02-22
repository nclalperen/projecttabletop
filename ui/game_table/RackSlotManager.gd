class_name RackSlotManager
extends RefCounted

const GEO = preload("res://ui/game_table/TableGeometry.gd")

var rack_slots: Array[int] = []
var stage_slots: Array[int] = []
var last_tile_id: int = -1

func init_rack_slots(count: int = GEO.RACK_SLOT_COUNT) -> void:
	rack_slots.clear()
	for _i in range(maxi(0, count)):
		rack_slots.append(-1)

func init_stage_slots(count: int = GEO.STAGE_SLOT_COUNT) -> void:
	stage_slots.clear()
	for _i in range(maxi(0, count)):
		stage_slots.append(-1)

func sync_slots_with_hand(hand: Array) -> void:
	var in_hand: Dictionary = {}
	for tile in hand:
		in_hand[int(tile.unique_id)] = true

	for i in range(rack_slots.size()):
		var tile_id: int = int(rack_slots[i])
		if tile_id != -1 and not in_hand.has(tile_id):
			rack_slots[i] = -1

	for i in range(stage_slots.size()):
		var tile_id: int = int(stage_slots[i])
		if tile_id != -1 and not in_hand.has(tile_id):
			stage_slots[i] = -1

	for tile in hand:
		var uid: int = int(tile.unique_id)
		if rack_slots.has(uid) or stage_slots.has(uid):
			continue
		var empty_idx: int = rack_slots.find(-1)
		if empty_idx == -1:
			empty_idx = stage_slots.find(-1)
			if empty_idx != -1:
				stage_slots[empty_idx] = uid
			continue
		rack_slots[empty_idx] = uid

func has_staged_tiles() -> bool:
	for tid in stage_slots:
		if int(tid) != -1:
			return true
	return false

func all_staged_tile_ids() -> Array:
	var out: Array = []
	for tid in stage_slots:
		var tile_id: int = int(tid)
		if tile_id != -1:
			out.append(tile_id)
	return out

func clear_stage_slots() -> void:
	for i in range(stage_slots.size()):
		stage_slots[i] = -1

func restore_staged_to_rack() -> void:
	for i in range(stage_slots.size()):
		var tid: int = int(stage_slots[i])
		if tid == -1:
			continue
		var empty_idx: int = rack_slots.find(-1)
		if empty_idx != -1:
			rack_slots[empty_idx] = tid
		stage_slots[i] = -1

func nearest_empty_stage_slot(preferred_slot: int, row_slots: int, total_slots: int) -> int:
	if preferred_slot < 0 or preferred_slot >= stage_slots.size():
		preferred_slot = 0
	if preferred_slot >= 0 and preferred_slot < stage_slots.size() and stage_slots[preferred_slot] == -1:
		return preferred_slot

	var start: int = 0
	var stop: int = min(total_slots, stage_slots.size())
	if preferred_slot >= row_slots:
		start = row_slots
		stop = min(total_slots, stage_slots.size())
	else:
		start = 0
		stop = mini(row_slots, stage_slots.size())

	for radius in range(1, maxi(1, row_slots)):
		var right: int = preferred_slot + radius
		if right >= start and right < stop and stage_slots[right] == -1:
			return right
		var left: int = preferred_slot - radius
		if left >= start and left < stop and stage_slots[left] == -1:
			return left

	for i in range(stage_slots.size()):
		if stage_slots[i] == -1:
			return i
	return -1

func move_slot(from_slot: int, to_slot: int) -> bool:
	if from_slot < 0 or from_slot >= rack_slots.size():
		return false
	if to_slot < 0 or to_slot >= rack_slots.size():
		return false
	var tile_id: int = int(rack_slots[from_slot])
	if tile_id == -1:
		return false
	var other_id: int = int(rack_slots[to_slot])
	if from_slot == to_slot and other_id == tile_id:
		return false
	rack_slots[to_slot] = tile_id
	rack_slots[from_slot] = other_id
	last_tile_id = tile_id
	return true

func move_rack_to_stage(from_slot: int, to_stage_slot: int, row_slots: int, total_stage_slots: int) -> bool:
	if from_slot < 0 or from_slot >= rack_slots.size():
		return false
	if to_stage_slot < 0 or to_stage_slot >= stage_slots.size():
		return false
	var tile_id: int = int(rack_slots[from_slot])
	if tile_id == -1:
		return false
	var stage_slot: int = nearest_empty_stage_slot(to_stage_slot, row_slots, total_stage_slots)
	if stage_slot == -1:
		return false
	stage_slots[stage_slot] = tile_id
	rack_slots[from_slot] = -1
	last_tile_id = tile_id
	return true

func move_stage_to_rack(from_stage_slot: int, to_slot: int) -> bool:
	if from_stage_slot < 0 or from_stage_slot >= stage_slots.size():
		return false
	if to_slot < 0 or to_slot >= rack_slots.size():
		return false
	var tile_id: int = int(stage_slots[from_stage_slot])
	if tile_id == -1:
		return false
	var other_id: int = int(rack_slots[to_slot])
	stage_slots[from_stage_slot] = other_id
	rack_slots[to_slot] = tile_id
	last_tile_id = tile_id
	return true

func move_stage_slot(from_slot: int, to_slot: int) -> bool:
	if from_slot < 0 or from_slot >= stage_slots.size():
		return false
	if to_slot < 0 or to_slot >= stage_slots.size():
		return false
	var tile_id: int = int(stage_slots[from_slot])
	if tile_id == -1:
		return false
	var other_id: int = int(stage_slots[to_slot])
	stage_slots[to_slot] = tile_id
	stage_slots[from_slot] = other_id
	last_tile_id = tile_id
	return true
