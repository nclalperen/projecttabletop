extends RefCounted
class_name DiscardRules

func is_tile_extendable_on_table(state, tile) -> bool:
	var validator = MeldValidator.new()
	for meld in state.table_melds:
		if meld.kind == meld.Kind.PAIRS:
			continue
		if meld.tiles_data.is_empty():
			continue
		var combined: Array = []
		for t in meld.tiles_data:
			combined.append(t)
		combined.append(tile)
		if meld.kind == meld.Kind.RUN:
			var res = validator.validate_run(combined, state.okey_context)
			if res.ok:
				return true
		elif meld.kind == meld.Kind.SET:
			var res2 = validator.validate_set(combined, state.okey_context)
			if res2.ok:
				return true
	return false
