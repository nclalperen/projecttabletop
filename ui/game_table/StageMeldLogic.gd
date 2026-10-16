class_name StageMeldLogic
extends RefCounted

func submit_draft_melds(
	controller,
	state,
	hand: Array,
	slots,
	draft_row_slots: int,
	pair_key_fn: Callable
) -> Dictionary:
	if state == null:
		return {"ok": false, "reason": "No game state"}
	if state.players.is_empty():
		return {"ok": false, "reason": "No players"}

	var player = state.players[0]
	var draft_ids: Array = slots.all_draft_tile_ids()
	if draft_ids.is_empty():
		return {"ok": false, "reason": "No draft tiles"}

	# Opening submission: all draft tiles must be consumed by valid opening melds.
	if not bool(player.has_opened):
		var open_melds: Array = build_melds_from_draft_slots(state, hand, slots.draft_slots, draft_row_slots, pair_key_fn)
		if open_melds.is_empty():
			return {"ok": false, "reason": "Draft groups are invalid (check color/sequence/group gaps)"}

		var open_by_pairs: bool = true
		for meld_dict in open_melds:
			if int(meld_dict.get("kind", -1)) != Meld.Kind.PAIRS:
				open_by_pairs = false
				break

		var used_ids_open: Dictionary = {}
		for meld_dict in open_melds:
			for tid in meld_dict.get("tile_ids", []):
				used_ids_open[int(tid)] = true

		for tid in draft_ids:
			if not used_ids_open.has(int(tid)):
				return {"ok": false, "reason": "Opening draft has extra tiles. Move extras back to rack or complete valid groups."}

		var open_action: Action = Action.new(Action.ActionType.OPEN_MELDS, {
			"melds": open_melds,
			"open_by_pairs": open_by_pairs,
		})
		var open_result: Dictionary = controller.apply_action_if_valid(0, open_action)
		if not bool(open_result.get("ok", false)):
			return {"ok": false, "reason": str(open_result.get("reason", "Draft melds rejected"))}

		slots.clear_draft_slots()
		return {"ok": true, "reason": ""}

	# Opened by pairs cannot create new draft melds; only direct layoff is allowed.
	if bool(player.opened_by_pairs):
		return {"ok": false, "reason": "Opened by pairs: add tiles directly onto table melds instead of draft area."}

	var new_melds: Array = build_new_melds_from_draft_slots_opened(state, hand, slots.draft_slots, draft_row_slots)
	if new_melds.is_empty():
		return {"ok": false, "reason": "No valid new melds in draft area"}

	var used_ids: Dictionary = {}
	for meld_dict in new_melds:
		for tid in meld_dict.get("tile_ids", []):
			used_ids[int(tid)] = true

	for tid in draft_ids:
		if not used_ids.has(int(tid)):
			return {"ok": false, "reason": "Draft area has orphan tiles. Use contiguous groups for new melds."}

	var new_action: Action = Action.new(Action.ActionType.OPEN_MELDS, {
		"melds": new_melds,
		"open_by_pairs": false,
	})
	var new_result: Dictionary = controller.apply_action_if_valid(0, new_action)
	if not bool(new_result.get("ok", false)):
		return {"ok": false, "reason": str(new_result.get("reason", "New melds rejected"))}

	slots.clear_draft_slots()
	return {"ok": true, "reason": ""}

func build_new_melds_from_draft_slots_opened(
	state,
	hand: Array,
	draft_slots: Array[int],
	draft_row_slots: int
) -> Array:
	if state == null:
		return []

	var hand_by_id: Dictionary = {}
	for tile in hand:
		hand_by_id[int(tile.unique_id)] = tile

	var validator: MeldValidator = MeldValidator.new()
	var out: Array = []

	for row_idx in range(2):
		var start_idx: int = row_idx * draft_row_slots
		var end_idx: int = min(draft_slots.size(), start_idx + draft_row_slots)
		var current: Array[int] = []
		for i in range(start_idx, end_idx):
			var tid: int = int(draft_slots[i])
			if tid == -1:
				if current.size() >= 3:
					var meld_dict: Dictionary = _validate_new_meld_candidate(current, hand_by_id, validator, state)
					if not meld_dict.is_empty():
						out.append(meld_dict)
				current = []
				continue
			current.append(tid)
		if current.size() >= 3:
			var tail_meld: Dictionary = _validate_new_meld_candidate(current, hand_by_id, validator, state)
			if not tail_meld.is_empty():
				out.append(tail_meld)

	return out

func build_melds_from_draft_slots(
	state,
	hand: Array,
	draft_slots: Array[int],
	draft_row_slots: int,
	pair_key_fn: Callable
) -> Array:
	if state == null:
		return []

	var hand_by_id: Dictionary = {}
	for tile in hand:
		hand_by_id[int(tile.unique_id)] = tile

	var groups: Array = []
	for row_idx in range(2):
		var start_idx: int = row_idx * draft_row_slots
		var end_idx: int = min(draft_slots.size(), start_idx + draft_row_slots)
		var current: Array[int] = []
		for i in range(start_idx, end_idx):
			var tid: int = int(draft_slots[i])
			if tid == -1:
				if not current.is_empty():
					groups.append(current)
					current = []
				continue
			current.append(tid)
		if not current.is_empty():
			groups.append(current)

	if groups.is_empty():
		return []

	var validator: MeldValidator = MeldValidator.new()
	var out: Array = []
	for ids in groups:
		var tiles: Array = []
		for tid in ids:
			var tile_id: int = int(tid)
			if not hand_by_id.has(tile_id):
				return []
			tiles.append(hand_by_id[tile_id])

		if ids.size() < 2:
			continue
		if ids.size() == 2:
			var pair_chunks: Array = _pair_melds(ids, tiles, pair_key_fn)
			if pair_chunks.is_empty():
				return []
			for pair_meld in pair_chunks:
				out.append(pair_meld)
			continue

		var run_res: Dictionary = validator.validate_run(tiles, state.okey_context)
		if bool(run_res.get("ok", false)):
			out.append({"kind": Meld.Kind.RUN, "tile_ids": ids})
			continue

		var set_res: Dictionary = validator.validate_set(tiles, state.okey_context)
		if bool(set_res.get("ok", false)):
			out.append({"kind": Meld.Kind.SET, "tile_ids": ids})
			continue

		if ids.size() % 2 == 0:
			var pair_melds: Array = _pair_melds(ids, tiles, pair_key_fn)
			if not pair_melds.is_empty():
				for meld_dict in pair_melds:
					out.append(meld_dict)
				continue
		return []

	if out.is_empty():
		return []
	return out

func _validate_new_meld_candidate(
	ids: Array,
	hand_by_id: Dictionary,
	validator: MeldValidator,
	state
) -> Dictionary:
	var tiles: Array = []
	for tid in ids:
		var tile_id: int = int(tid)
		if not hand_by_id.has(tile_id):
			return {}
		tiles.append(hand_by_id[tile_id])

	var run_res: Dictionary = validator.validate_run(tiles, state.okey_context)
	if bool(run_res.get("ok", false)):
		return {"kind": Meld.Kind.RUN, "tile_ids": ids.duplicate()}

	var set_res: Dictionary = validator.validate_set(tiles, state.okey_context)
	if bool(set_res.get("ok", false)):
		return {"kind": Meld.Kind.SET, "tile_ids": ids.duplicate()}

	return {}

func _pair_melds(ids: Array, tiles: Array, pair_key_fn: Callable) -> Array:
	if ids.size() < 2 or ids.size() % 2 != 0:
		return []
	if pair_key_fn == null:
		return []

	var out: Array = []
	for i in range(0, ids.size(), 2):
		var a = tiles[i]
		var b = tiles[i + 1]
		if String(pair_key_fn.call(a)) != String(pair_key_fn.call(b)):
			return []
		out.append({"kind": Meld.Kind.PAIRS, "tile_ids": [ids[i], ids[i + 1]]})
	return out


func evaluate_rack_melds(
	state,
	hand: Array,
	rack_slots: Array[int],
	rack_row_slots: int,
	pair_key_fn: Callable
) -> Dictionary:
	var empty_res: Dictionary = {
		"series_melds": [],
		"series_points": 0,
		"series_tile_ids": [],
		"pair_melds": [],
		"pair_count": 0,
		"pair_tile_ids": [],
	}
	if state == null or hand.is_empty() or rack_slots.is_empty():
		return empty_res

	var hand_by_id: Dictionary = {}
	for tile in hand:
		hand_by_id[int(tile.unique_id)] = tile

	var groups: Array = []
	var rows: int = maxi(1, int(ceil(float(rack_slots.size()) / float(maxi(1, rack_row_slots)))))
	for row_idx in range(rows):
		var start_idx: int = row_idx * rack_row_slots
		var end_idx: int = mini(rack_slots.size(), start_idx + rack_row_slots)
		var current: Array[int] = []
		for i in range(start_idx, end_idx):
			var tid: int = int(rack_slots[i])
			if tid == -1 or not hand_by_id.has(tid):
				if not current.is_empty():
					groups.append(current)
					current = []
				continue
			current.append(tid)
		if not current.is_empty():
			groups.append(current)

	var validator := MeldValidator.new()
	var series_melds: Array = []
	var series_points: int = 0
	var series_tile_ids: Array[int] = []
	var pair_melds: Array = []
	var pair_tile_ids: Array[int] = []

	for ids in groups:
		if ids.size() < 2:
			continue
		var tiles: Array = []
		for tid in ids:
			tiles.append(hand_by_id[int(tid)])

		if ids.size() >= 3:
			var run_res: Dictionary = validator.validate_run(tiles, state.okey_context)
			if bool(run_res.get("ok", false)):
				series_melds.append({"kind": Meld.Kind.RUN, "tile_ids": ids.duplicate()})
				series_points += int(run_res.get("points_value", 0))
				for tid in ids:
					series_tile_ids.append(int(tid))
				continue

			var set_res: Dictionary = validator.validate_set(tiles, state.okey_context)
			if bool(set_res.get("ok", false)):
				series_melds.append({"kind": Meld.Kind.SET, "tile_ids": ids.duplicate()})
				series_points += int(set_res.get("points_value", 0))
				for tid in ids:
					series_tile_ids.append(int(tid))
				continue

		if ids.size() % 2 == 0:
			var p_melds: Array = _pair_melds(ids, tiles, pair_key_fn)
			if not p_melds.is_empty():
				for pm in p_melds:
					pair_melds.append(pm)
				for tid in ids:
					pair_tile_ids.append(int(tid))

	return {
		"series_melds": series_melds,
		"series_points": series_points,
		"series_tile_ids": series_tile_ids,
		"pair_melds": pair_melds,
		"pair_count": pair_melds.size(),
		"pair_tile_ids": pair_tile_ids,
	}


## Detect contiguous touching tiles and check if they form a valid group (run, set, or pair)
func find_contiguous_rack_group(
	state: GameState,
	hand: Array,
	rack_slots: Array,
	slot_idx: int,
	rack_row_slots: int = 15,
	pair_key_fn: Callable = Callable()
) -> Dictionary:
	var empty_res := {
		"is_group": false,
		"is_single": false,
		"slots": [],
		"tile_ids": [],
		"kind": -1,
		"points": 0
	}
	if slot_idx < 0 or slot_idx >= rack_slots.size() or int(rack_slots[slot_idx]) == -1:
		return empty_res

	var hand_by_id: Dictionary = {}
	for tile in hand:
		hand_by_id[int(tile.unique_id)] = tile

	var target_tid: int = int(rack_slots[slot_idx])
	if not hand_by_id.has(target_tid):
		return empty_res

	var row_idx: int = int(slot_idx / rack_row_slots)
	var row_start: int = row_idx * rack_row_slots
	var row_end: int = mini(rack_slots.size(), row_start + rack_row_slots)

	# Expand left and right within the row to find touching tiles
	var left: int = slot_idx
	while left > row_start and int(rack_slots[left - 1]) != -1 and hand_by_id.has(int(rack_slots[left - 1])):
		left -= 1
	var right: int = slot_idx
	while right < row_end - 1 and int(rack_slots[right + 1]) != -1 and hand_by_id.has(int(rack_slots[right + 1])):
		right += 1

	# Case 1: Isolated single tile (no touching neighbors)
	if left == right:
		return {
			"is_group": false,
			"is_single": true,
			"slots": [slot_idx],
			"tile_ids": [target_tid],
			"kind": -1,
			"points": 0
		}

	# Case 2: Touching neighbors exist! Check if touching segment forms a valid group
	var group_slots: Array[int] = []
	var group_ids: Array[int] = []
	var group_tiles: Array = []
	for s in range(left, right + 1):
		var tid: int = int(rack_slots[s])
		group_slots.append(s)
		group_ids.append(tid)
		group_tiles.append(hand_by_id[tid])

	var okey_ctx = state.okey_context if state != null else null
	var validator := MeldValidator.new()

	# Check full segment for RUN
	if group_tiles.size() >= 3 and okey_ctx != null:
		var run_res: Dictionary = validator.validate_run(group_tiles, okey_ctx)
		if bool(run_res.get("ok", false)):
			return {
				"is_group": true,
				"is_single": false,
				"slots": group_slots,
				"tile_ids": group_ids,
				"kind": Meld.Kind.RUN,
				"points": int(run_res.get("points_value", 0))
			}

		# Check full segment for SET
		var set_res: Dictionary = validator.validate_set(group_tiles, okey_ctx)
		if bool(set_res.get("ok", false)):
			return {
				"is_group": true,
				"is_single": false,
				"slots": group_slots,
				"tile_ids": group_ids,
				"kind": Meld.Kind.SET,
				"points": int(set_res.get("points_value", 0))
			}

	# Check PAIR (size == 2)
	if group_tiles.size() == 2 and pair_key_fn.is_valid():
		var k0 = pair_key_fn.call(group_tiles[0])
		var k1 = pair_key_fn.call(group_tiles[1])
		if k0 == k1:
			return {
				"is_group": true,
				"is_single": false,
				"slots": group_slots,
				"tile_ids": group_ids,
				"kind": Meld.Kind.PAIRS,
				"points": 0
			}

	# Check sub-windows containing slot_idx of size >= 3
	for span_len in range(group_tiles.size() - 1, 2, -1):
		for start_offset in range(group_tiles.size() - span_len + 1):
			var sub_left: int = left + start_offset
			var sub_right: int = sub_left + span_len - 1
			if slot_idx < sub_left or slot_idx > sub_right:
				continue
			var sub_tiles: Array = group_tiles.slice(start_offset, start_offset + span_len)
			var sub_ids: Array[int] = group_ids.slice(start_offset, start_offset + span_len)
			var sub_slots: Array[int] = group_slots.slice(start_offset, start_offset + span_len)
			if okey_ctx != null:
				var r_res = validator.validate_run(sub_tiles, okey_ctx)
				if bool(r_res.get("ok", false)):
					return {
						"is_group": true,
						"is_single": false,
						"slots": sub_slots,
						"tile_ids": sub_ids,
						"kind": Meld.Kind.RUN,
						"points": int(r_res.get("points_value", 0))
					}
				var s_res = validator.validate_set(sub_tiles, okey_ctx)
				if bool(s_res.get("ok", false)):
					return {
						"is_group": true,
						"is_single": false,
						"slots": sub_slots,
						"tile_ids": sub_ids,
						"kind": Meld.Kind.SET,
						"points": int(s_res.get("points_value", 0))
					}

	# Touching tiles do NOT form a valid group: return empty per user instruction
	return empty_res


func smart_sort_rack_tiles(
	tiles: Array,
	okey_context,
	mode: String,
	pair_key_fn: Callable
) -> Array[int]:
	var out_slots: Array[int] = []
	out_slots.resize(30)
	out_slots.fill(-1)
	if tiles.is_empty():
		return out_slots

	var used_ids: Dictionary = {}
	var meld_groups: Array = [] # Array of Array[int]

	if mode == "number" or mode == "pairs":
		# Group by pair key to extract clean pairs
		var by_key: Dictionary = {}
		for t in tiles:
			if okey_context != null and okey_context.is_real_okey(t):
				continue
			var k: String = String(pair_key_fn.call(t)) if pair_key_fn.is_valid() else "%d-%d" % [int(t.color), int(t.number)]
			if not by_key.has(k):
				by_key[k] = []
			by_key[k].append(t)
		var keys: Array = by_key.keys()
		keys.sort()
		for k in keys:
			var bucket: Array = by_key[k]
			while bucket.size() >= 2:
				var a = bucket.pop_front()
				var b = bucket.pop_front()
				used_ids[int(a.unique_id)] = true
				used_ids[int(b.unique_id)] = true
				meld_groups.append([int(a.unique_id), int(b.unique_id)])
	else:
		# Series mode ("color" / "series"): extract valid Runs first, then Sets
		var validator := MeldValidator.new()
		for col in range(4):
			var by_num: Dictionary = {}
			for t in tiles:
				if used_ids.has(int(t.unique_id)):
					continue
				if okey_context != null and okey_context.is_real_okey(t):
					continue
				var eff_col: int = int(okey_context.okey_color) if (okey_context != null and int(t.kind) == Tile.Kind.FAKE_OKEY) else int(t.color)
				var eff_num: int = int(okey_context.okey_number) if (okey_context != null and int(t.kind) == Tile.Kind.FAKE_OKEY) else int(t.number)
				if eff_col != col:
					continue
				if not by_num.has(eff_num):
					by_num[eff_num] = []
				by_num[eff_num].append(t)

			# Extract up to 2 passes of consecutive runs in this color
			for _pass in range(2):
				var n: int = 1
				while n <= 13:
					if not by_num.has(n) or (by_num[n] as Array).is_empty():
						n += 1
						continue
					var run_tiles: Array = []
					var cur: int = n
					while cur <= 13 and by_num.has(cur) and not (by_num[cur] as Array).is_empty():
						run_tiles.append((by_num[cur] as Array)[0])
						cur += 1
					if run_tiles.size() >= 3 and bool(validator.validate_run(run_tiles, okey_context).get("ok", false)):
						var grp: Array[int] = []
						for rt in run_tiles:
							var r_num: int = int(okey_context.okey_number) if (okey_context != null and int(rt.kind) == Tile.Kind.FAKE_OKEY) else int(rt.number)
							(by_num[r_num] as Array).pop_front()
							used_ids[int(rt.unique_id)] = true
							grp.append(int(rt.unique_id))
						meld_groups.append(grp)
						n = cur
					else:
						n += 1

		# Extract Sets (3 or 4 different colors of the same number, highest numbers first)
		for num in range(13, 0, -1):
			var by_col: Dictionary = {}
			for t in tiles:
				if used_ids.has(int(t.unique_id)):
					continue
				if okey_context != null and okey_context.is_real_okey(t):
					continue
				var eff_col: int = int(okey_context.okey_color) if (okey_context != null and int(t.kind) == Tile.Kind.FAKE_OKEY) else int(t.color)
				var eff_num: int = int(okey_context.okey_number) if (okey_context != null and int(t.kind) == Tile.Kind.FAKE_OKEY) else int(t.number)
				if eff_num != num:
					continue
				if not by_col.has(eff_col):
					by_col[eff_col] = t
			if by_col.size() >= 3:
				var set_tiles: Array = by_col.values()
				if bool(validator.validate_set(set_tiles, okey_context).get("ok", false)):
					var grp: Array[int] = []
					for st in set_tiles:
						used_ids[int(st.unique_id)] = true
						grp.append(int(st.unique_id))
					meld_groups.append(grp)

	var leftovers: Array = []
	for t in tiles:
		if not used_ids.has(int(t.unique_id)):
			leftovers.append(t)

	leftovers.sort_custom(func(a, b):
		var a_key: int = int(a.number) * 10 + int(a.color) if (mode == "number" or mode == "pairs") else int(a.color) * 20 + int(a.number)
		var b_key: int = int(b.number) * 10 + int(b.color) if (mode == "number" or mode == "pairs") else int(b.color) * 20 + int(b.number)
		return int(a.unique_id) < int(b.unique_id) if a_key == b_key else a_key < b_key
	)

	# Pack meld_groups into row 0 (0..14) and row 1 (15..29) without splitting a meld across row boundary
	var cursor: int = 0
	for grp in meld_groups:
		var g_size: int = grp.size()
		if cursor < 15 and cursor + g_size > 15:
			cursor = 15
		if cursor + g_size + leftovers.size() > 30:
			# Not enough room for extra gaps; return all remaining tiles to leftovers
			for tid in grp:
				for t in tiles:
					if int(t.unique_id) == int(tid):
						leftovers.append(t)
			continue
		for tid in grp:
			if cursor < 30:
				out_slots[cursor] = int(tid)
				cursor += 1
		# Leave a 1-slot gap after the group if it doesn't hit row end and leaves room for leftovers
		if cursor != 15 and cursor < 30 and (30 - (cursor + 1)) >= leftovers.size():
			cursor += 1

	# Place leftovers in remaining slots (prefer starting on row 1 if melds are on row 0 and leftovers fit on row 1)
	if not meld_groups.is_empty() and cursor > 0 and cursor < 15 and leftovers.size() <= 15:
		cursor = 15
	for lt in leftovers:
		while cursor < 30 and out_slots[cursor] != -1:
			cursor += 1
		if cursor < 30:
			out_slots[cursor] = int(lt.unique_id)
			cursor += 1
		else:
			# Fallback: find any empty slot
			var fallback_idx: int = out_slots.find(-1)
			if fallback_idx != -1:
				out_slots[fallback_idx] = int(lt.unique_id)

	return out_slots

