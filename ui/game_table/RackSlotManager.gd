class_name RackSlotManager
extends RefCounted

const GEO = preload("res://ui/game_table/TableGeometry.gd")

var rack_slots: Array[int] = []
var draft_slots: Array[int] = []
var last_tile_id: int = -1

func init_rack_slots(count: int = GEO.RACK_SLOT_COUNT) -> void:
	rack_slots.clear()
	for _i in range(maxi(0, count)):
		rack_slots.append(-1)

func init_draft_slots(count: int = GEO.STAGE_SLOT_COUNT) -> void:
	draft_slots.clear()
	for _i in range(maxi(0, count)):
		draft_slots.append(-1)

func sync_slots_with_hand(hand: Array) -> void:
	var in_hand: Dictionary = {}
	for tile in hand:
		in_hand[int(tile.unique_id)] = true

	for i in range(rack_slots.size()):
		var tile_id: int = int(rack_slots[i])
		if tile_id != -1 and not in_hand.has(tile_id):
			rack_slots[i] = -1

	for i in range(draft_slots.size()):
		var tile_id: int = int(draft_slots[i])
		if tile_id != -1 and not in_hand.has(tile_id):
			draft_slots[i] = -1

	for tile in hand:
		var uid: int = int(tile.unique_id)
		if rack_slots.has(uid) or draft_slots.has(uid):
			continue
		var empty_idx: int = rack_slots.find(-1)
		if empty_idx == -1:
			empty_idx = draft_slots.find(-1)
			if empty_idx != -1:
				draft_slots[empty_idx] = uid
			continue
		rack_slots[empty_idx] = uid

func has_draft_tiles() -> bool:
	for tid in draft_slots:
		if int(tid) != -1:
			return true
	return false

func all_draft_tile_ids() -> Array:
	var out: Array = []
	for tid in draft_slots:
		var tile_id: int = int(tid)
		if tile_id != -1:
			out.append(tile_id)
	return out

func clear_draft_slots() -> void:
	for i in range(draft_slots.size()):
		draft_slots[i] = -1

func restore_draft_to_rack() -> void:
	for i in range(draft_slots.size()):
		var tid: int = int(draft_slots[i])
		if tid == -1:
			continue
		var empty_idx: int = rack_slots.find(-1)
		if empty_idx != -1:
			rack_slots[empty_idx] = tid
		draft_slots[i] = -1

func nearest_empty_draft_slot(preferred_slot: int, row_slots: int, total_slots: int) -> int:
	if preferred_slot < 0 or preferred_slot >= draft_slots.size():
		preferred_slot = 0
	if preferred_slot >= 0 and preferred_slot < draft_slots.size() and draft_slots[preferred_slot] == -1:
		return preferred_slot

	var start: int = 0
	var stop: int = min(total_slots, draft_slots.size())
	if preferred_slot >= row_slots:
		start = row_slots
		stop = min(total_slots, draft_slots.size())
	else:
		start = 0
		stop = mini(row_slots, draft_slots.size())

	for radius in range(1, maxi(1, row_slots)):
		var right: int = preferred_slot + radius
		if right >= start and right < stop and draft_slots[right] == -1:
			return right
		var left: int = preferred_slot - radius
		if left >= start and left < stop and draft_slots[left] == -1:
			return left

	for i in range(draft_slots.size()):
		if draft_slots[i] == -1:
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

## Fluid tile placement: drops onto empty slots cleanly; shoves adjacent tiles aside if occupied.
func place_tile_at(from_slot: int, to_slot: int) -> bool:
	if from_slot < 0 or from_slot >= rack_slots.size() or to_slot < 0 or to_slot >= rack_slots.size():
		return false
	if from_slot == to_slot:
		return true
	var tile_id: int = int(rack_slots[from_slot])
	if tile_id == -1:
		return false

	# 1. Target slot is empty: clean placement without displacing other tiles
	if rack_slots[to_slot] == -1:
		rack_slots[to_slot] = tile_id
		rack_slots[from_slot] = -1
		last_tile_id = tile_id
		return true

	# 2. Target slot is occupied: compute reflow to shove adjacent tiles towards nearest gap in row
	var shifts: Dictionary = calculate_reflow(rack_slots, from_slot, to_slot)
	if not shifts.is_empty():
		rack_slots[from_slot] = -1
		var first_slot: int = shifts.keys()[0]
		var shift_dir: int = shifts[first_slot]

		if shift_dir == 1:
			var max_slot: int = to_slot
			for s in shifts.keys():
				if s > max_slot:
					max_slot = s
			var gap: int = max_slot + 1
			for i in range(gap, to_slot, -1):
				rack_slots[i] = rack_slots[i - 1]
		else:
			var min_slot: int = to_slot
			for s in shifts.keys():
				if s < min_slot:
					min_slot = s
			var gap: int = min_slot - 1
			for i in range(gap, to_slot):
				rack_slots[i] = rack_slots[i + 1]

		rack_slots[to_slot] = tile_id
		last_tile_id = tile_id
		return true

	# 3. Fallback if row is completely full (no gap): swap with target slot
	var target_id: int = rack_slots[to_slot]
	rack_slots[to_slot] = tile_id
	rack_slots[from_slot] = target_id
	last_tile_id = tile_id
	return true

## Move and shove a contiguous group of tiles into target_slot
func place_group_at(from_slots: Array[int], target_slot: int) -> bool:
	if from_slots.is_empty():
		return false
	if from_slots.size() == 1:
		return place_tile_at(from_slots[0], target_slot)

	for s in from_slots:
		if s < 0 or s >= rack_slots.size() or rack_slots[s] == -1:
			return false
	if target_slot < 0 or target_slot >= rack_slots.size():
		return false

	var row_slots: int = 15
	var row_idx: int = int(target_slot / row_slots)
	var row_start: int = row_idx * row_slots
	var row_end: int = mini(rack_slots.size(), row_start + row_slots)
	var K: int = from_slots.size()

	# Clamp target_slot so entire group fits in the row
	if target_slot + K > row_end:
		target_slot = row_end - K
	if target_slot < row_start:
		target_slot = row_start

	# Extract moving tiles and clear source slots
	var moving_tids: Array[int] = []
	for s in from_slots:
		moving_tids.append(rack_slots[s])
		rack_slots[s] = -1

	# Collect other tiles currently in target row
	var left_tiles: Array[int] = []
	var right_tiles: Array[int] = []
	for s in range(row_start, row_end):
		var tid: int = rack_slots[s]
		if tid != -1:
			if s < target_slot:
				left_tiles.append(tid)
			else:
				right_tiles.append(tid)

	# If all tiles fit within the row (15 slots)
	if left_tiles.size() + K + right_tiles.size() <= row_slots:
		# Clear target row slots
		for s in range(row_start, row_end):
			rack_slots[s] = -1

		# Adjust target_slot if right_tiles would overflow row_end
		var right_overflow: int = (target_slot + K + right_tiles.size()) - row_end
		if right_overflow > 0:
			target_slot -= right_overflow
		var left_underflow: int = row_start - (target_slot - left_tiles.size())
		if left_underflow > 0:
			target_slot += left_underflow

		# Place left tiles
		var l_start: int = target_slot - left_tiles.size()
		for i in range(left_tiles.size()):
			rack_slots[l_start + i] = left_tiles[i]

		# Place group tiles
		for i in range(K):
			rack_slots[target_slot + i] = moving_tids[i]

		# Place right tiles
		var r_start: int = target_slot + K
		for i in range(right_tiles.size()):
			rack_slots[r_start + i] = right_tiles[i]

		last_tile_id = moving_tids[0]
		return true

	# Fallback if too many tiles: swap target span with moving tiles
	for i in range(K):
		var s: int = target_slot + i
		var displaced: int = rack_slots[s]
		rack_slots[s] = moving_tids[i]
		if i < from_slots.size():
			rack_slots[from_slots[i]] = displaced

	last_tile_id = moving_tids[0]
	return true

## Insertion uses fluid placement; preserves gaps and reflows occupied slots cleanly.
func insert_rack_slot(from_slot: int, to_slot: int) -> bool:
	return place_tile_at(from_slot, to_slot)

func move_rack_to_draft(from_slot: int, to_draft_slot: int, row_slots: int, total_draft_slots: int) -> bool:
	if from_slot < 0 or from_slot >= rack_slots.size():
		return false
	if to_draft_slot < 0 or to_draft_slot >= draft_slots.size():
		return false
	var tile_id: int = int(rack_slots[from_slot])
	if tile_id == -1:
		return false
	var draft_slot: int = nearest_empty_draft_slot(to_draft_slot, row_slots, total_draft_slots)
	if draft_slot == -1:
		return false
	draft_slots[draft_slot] = tile_id
	rack_slots[from_slot] = -1
	last_tile_id = tile_id
	return true

func move_draft_to_rack(from_draft_slot: int, to_slot: int) -> bool:
	if from_draft_slot < 0 or from_draft_slot >= draft_slots.size():
		return false
	if to_slot < 0 or to_slot >= rack_slots.size():
		return false
	var tile_id: int = int(draft_slots[from_draft_slot])
	if tile_id == -1:
		return false
	var other_id: int = int(rack_slots[to_slot])
	draft_slots[from_draft_slot] = other_id
	rack_slots[to_slot] = tile_id
	last_tile_id = tile_id
	return true

func move_draft_slot(from_slot: int, to_slot: int) -> bool:
	if from_slot < 0 or from_slot >= draft_slots.size():
		return false
	if to_slot < 0 or to_slot >= draft_slots.size():
		return false
	var tile_id: int = int(draft_slots[from_slot])
	if tile_id == -1:
		return false
	var other_id: int = int(draft_slots[to_slot])
	draft_slots[to_slot] = tile_id
	draft_slots[from_slot] = other_id
	last_tile_id = tile_id
	return true

## Calculates temporary preview shifts for a target rack slot hover during drag.
## Returns a Dictionary mapping slot_idx (int) -> preview_shift_int (-1 or 1).
func compute_reflow_preview(drag_slot: int, target_slot: int) -> Dictionary:
	return calculate_reflow(rack_slots, drag_slot, target_slot)

static func calculate_reflow(slots_arr: Array, drag_slot: int, target_slot: int) -> Dictionary:
	var shifts: Dictionary = {}
	if target_slot < 0 or target_slot >= slots_arr.size():
		return shifts
	if slots_arr[target_slot] == -1 or drag_slot == target_slot:
		return shifts

	# Determine row boundaries (0..14 or 15..29)
	var row_start: int = 0 if target_slot < 15 else 15
	var row_end: int = 15 if target_slot < 15 else 30

	# Find nearest gap to the right in this row
	var gap_right: int = -1
	for i in range(target_slot, row_end):
		if slots_arr[i] == -1 or i == drag_slot:
			gap_right = i
			break

	# Find nearest gap to the left in this row
	var gap_left: int = -1
	for i in range(target_slot, row_start - 1, -1):
		if slots_arr[i] == -1 or i == drag_slot:
			gap_left = i
			break

	var shift_dir: int = 0
	if gap_right != -1 and gap_left != -1:
		shift_dir = 1 if (gap_right - target_slot) <= (target_slot - gap_left) else -1
	elif gap_right != -1:
		shift_dir = 1
	elif gap_left != -1:
		shift_dir = -1
	else:
		return shifts

	if shift_dir == 1:
		for i in range(target_slot, gap_right):
			shifts[i] = 1
	else:
		for i in range(gap_left + 1, target_slot + 1):
			shifts[i] = -1

	return shifts

