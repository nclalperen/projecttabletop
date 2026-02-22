class_name StageMeldLogic
extends RefCounted

func submit_staged_melds(
	controller,
	state,
	hand: Array,
	slots,
	stage_row_slots: int,
	pair_key_fn: Callable
) -> Dictionary:
	if state == null:
		return {"ok": false, "reason": "No game state"}
	if state.players.is_empty():
		return {"ok": false, "reason": "No players"}

	var player = state.players[0]
	var staged_ids: Array = slots.all_staged_tile_ids()
	if staged_ids.is_empty():
		return {"ok": false, "reason": "No staged tiles"}

	# Opening submission: all staged tiles must be consumed by valid opening melds.
	if not bool(player.has_opened):
		var open_melds: Array = build_melds_from_stage_slots(state, hand, slots.stage_slots, stage_row_slots, pair_key_fn)
		if open_melds.is_empty():
			return {"ok": false, "reason": "Staged groups are invalid (check color/sequence/group gaps)"}

		var open_by_pairs: bool = true
		for meld_dict in open_melds:
			if int(meld_dict.get("kind", -1)) != Meld.Kind.PAIRS:
				open_by_pairs = false
				break

		var used_ids_open: Dictionary = {}
		for meld_dict in open_melds:
			for tid in meld_dict.get("tile_ids", []):
				used_ids_open[int(tid)] = true

		for tid in staged_ids:
			if not used_ids_open.has(int(tid)):
				return {"ok": false, "reason": "Opening stage has extra tiles. Move extras back to rack or complete valid groups."}

		var open_action: Action = Action.new(Action.ActionType.OPEN_MELDS, {
			"melds": open_melds,
			"open_by_pairs": open_by_pairs,
		})
		var open_result: Dictionary = controller.apply_action_if_valid(0, open_action)
		if not bool(open_result.get("ok", false)):
			return {"ok": false, "reason": str(open_result.get("reason", "Staged melds rejected"))}

		slots.clear_stage_slots()
		return {"ok": true, "reason": ""}

	# Opened by pairs cannot create new staged melds; only direct layoff is allowed.
	if bool(player.opened_by_pairs):
		return {"ok": false, "reason": "Opened by pairs: add tiles directly onto table melds instead of staging."}

	var new_melds: Array = build_new_melds_from_stage_slots_opened(state, hand, slots.stage_slots, stage_row_slots)
	if new_melds.is_empty():
		return {"ok": false, "reason": "No valid new melds in staging"}

	var used_ids: Dictionary = {}
	for meld_dict in new_melds:
		for tid in meld_dict.get("tile_ids", []):
			used_ids[int(tid)] = true

	for tid in staged_ids:
		if not used_ids.has(int(tid)):
			return {"ok": false, "reason": "Staging has orphan tiles. Use contiguous groups for new melds."}

	var new_action: Action = Action.new(Action.ActionType.OPEN_MELDS, {
		"melds": new_melds,
		"open_by_pairs": false,
	})
	var new_result: Dictionary = controller.apply_action_if_valid(0, new_action)
	if not bool(new_result.get("ok", false)):
		return {"ok": false, "reason": str(new_result.get("reason", "New melds rejected"))}

	slots.clear_stage_slots()
	return {"ok": true, "reason": ""}

func build_new_melds_from_stage_slots_opened(
	state,
	hand: Array,
	stage_slots: Array[int],
	stage_row_slots: int
) -> Array:
	if state == null:
		return []

	var hand_by_id: Dictionary = {}
	for tile in hand:
		hand_by_id[int(tile.unique_id)] = tile

	var validator: MeldValidator = MeldValidator.new()
	var out: Array = []

	for row_idx in range(2):
		var start_idx: int = row_idx * stage_row_slots
		var end_idx: int = min(stage_slots.size(), start_idx + stage_row_slots)
		var current: Array[int] = []
		for i in range(start_idx, end_idx):
			var tid: int = int(stage_slots[i])
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

func build_melds_from_stage_slots(
	state,
	hand: Array,
	stage_slots: Array[int],
	stage_row_slots: int,
	pair_key_fn: Callable
) -> Array:
	if state == null:
		return []

	var hand_by_id: Dictionary = {}
	for tile in hand:
		hand_by_id[int(tile.unique_id)] = tile

	var groups: Array = []
	for row_idx in range(2):
		var start_idx: int = row_idx * stage_row_slots
		var end_idx: int = min(stage_slots.size(), start_idx + stage_row_slots)
		var current: Array[int] = []
		for i in range(start_idx, end_idx):
			var tid: int = int(stage_slots[i])
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
