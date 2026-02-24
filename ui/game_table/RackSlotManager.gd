class_name RackSlotManager
extends RefCounted

const GEO = preload("res://ui/game_table/TableGeometry.gd")

var rack_slots: Array[int] = []
var draft_slots: Array[int] = []
var _compat_stage_api_warned: Dictionary = {}
var stage_slots:
	get:
		_warn_stage_api_once("stage_slots(get)", "draft_slots")
		return draft_slots
	set(value):
		_warn_stage_api_once("stage_slots(set)", "draft_slots")
		draft_slots.clear()
		for v in value:
			draft_slots.append(int(v))
var last_tile_id: int = -1

func _warn_stage_api_once(stage_api: String, draft_api: String) -> void:
	if _compat_stage_api_warned.has(stage_api):
		return
	_compat_stage_api_warned[stage_api] = true
	push_warning("%s is deprecated; use %s instead." % [stage_api, draft_api])

func init_rack_slots(count: int = GEO.RACK_SLOT_COUNT) -> void:
	rack_slots.clear()
	for _i in range(maxi(0, count)):
		rack_slots.append(-1)

func init_draft_slots(count: int = GEO.STAGE_SLOT_COUNT) -> void:
	draft_slots.clear()
	for _i in range(maxi(0, count)):
		draft_slots.append(-1)

# Compatibility wrapper. Remove after stage API deprecation window.
func init_stage_slots(count: int = GEO.STAGE_SLOT_COUNT) -> void:
	_warn_stage_api_once("init_stage_slots()", "init_draft_slots()")
	init_draft_slots(count)

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

# Compatibility wrapper. Remove after stage API deprecation window.
func has_staged_tiles() -> bool:
	_warn_stage_api_once("has_staged_tiles()", "has_draft_tiles()")
	return has_draft_tiles()

func all_draft_tile_ids() -> Array:
	var out: Array = []
	for tid in draft_slots:
		var tile_id: int = int(tid)
		if tile_id != -1:
			out.append(tile_id)
	return out

# Compatibility wrapper. Remove after stage API deprecation window.
func all_staged_tile_ids() -> Array:
	_warn_stage_api_once("all_staged_tile_ids()", "all_draft_tile_ids()")
	return all_draft_tile_ids()

func clear_draft_slots() -> void:
	for i in range(draft_slots.size()):
		draft_slots[i] = -1

# Compatibility wrapper. Remove after stage API deprecation window.
func clear_stage_slots() -> void:
	_warn_stage_api_once("clear_stage_slots()", "clear_draft_slots()")
	clear_draft_slots()

func restore_draft_to_rack() -> void:
	for i in range(draft_slots.size()):
		var tid: int = int(draft_slots[i])
		if tid == -1:
			continue
		var empty_idx: int = rack_slots.find(-1)
		if empty_idx != -1:
			rack_slots[empty_idx] = tid
		draft_slots[i] = -1

# Compatibility wrapper. Remove after stage API deprecation window.
func restore_staged_to_rack() -> void:
	_warn_stage_api_once("restore_staged_to_rack()", "restore_draft_to_rack()")
	restore_draft_to_rack()

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

# Compatibility wrapper. Remove after stage API deprecation window.
func nearest_empty_stage_slot(preferred_slot: int, row_slots: int, total_slots: int) -> int:
	_warn_stage_api_once("nearest_empty_stage_slot()", "nearest_empty_draft_slot()")
	return nearest_empty_draft_slot(preferred_slot, row_slots, total_slots)

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

# Compatibility wrappers. Remove after stage API deprecation window.
func move_rack_to_stage(from_slot: int, to_stage_slot: int, row_slots: int, total_stage_slots: int) -> bool:
	_warn_stage_api_once("move_rack_to_stage()", "move_rack_to_draft()")
	return move_rack_to_draft(from_slot, to_stage_slot, row_slots, total_stage_slots)

func move_stage_to_rack(from_stage_slot: int, to_slot: int) -> bool:
	_warn_stage_api_once("move_stage_to_rack()", "move_draft_to_rack()")
	return move_draft_to_rack(from_stage_slot, to_slot)

func move_stage_slot(from_slot: int, to_slot: int) -> bool:
	_warn_stage_api_once("move_stage_slot()", "move_draft_slot()")
	return move_draft_slot(from_slot, to_slot)
