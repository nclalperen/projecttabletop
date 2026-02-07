extends RefCounted
class_name MeldValidator

# SeOkey11 dossier rules:
# - Real okey tiles are wild.
# - Fake okey tiles represent the okey value for the round and are NOT free wilds.
# - Opening points are the sum of represented tile numbers.

func validate_run(tiles: Array, okey_context: OkeyContext) -> Dictionary:
	if tiles.size() < 3:
		return _fail("run_too_short")

	var wild_count := 0
	var color := -1
	var numbers: Array = [] # fixed numbers (non-wild)

	for tile in tiles:
		if _is_wild_tile(tile, okey_context):
			wild_count += 1
			continue

		var eff_color = _effective_color(tile, okey_context)
		var eff_number = _effective_number(tile, okey_context)

		if color == -1:
			color = eff_color
		elif eff_color != color:
			return _fail("run_color_mismatch")

		if numbers.has(eff_number):
			return _fail("run_duplicate_number")
		numbers.append(eff_number)

	var length := tiles.size()
	if numbers.is_empty():
		# All real jokers: choose the max-sum run ending at 13 (no wrap).
		var start = 13 - length + 1
		return _ok(_run_points_for_sequence(start, length))

	numbers.sort()
	var best_sum := -1
	for start in range(1, 14 - length + 1):
		var end = start + length - 1
		var fits = true
		for n in numbers:
			if n < start or n > end:
				fits = false
				break
		if not fits:
			continue

		var missing = length - numbers.size()
		if missing > wild_count:
			continue

		var points = _run_points_for_sequence(start, length)
		if points > best_sum:
			best_sum = points

	if best_sum == -1:
		return _fail("run_not_consecutive")

	return _ok(best_sum)

func validate_set(tiles: Array, okey_context: OkeyContext) -> Dictionary:
	if tiles.size() < 3 or tiles.size() > 4:
		return _fail("set_size")

	var wild_count := 0
	var number := -1
	var colors: Array = []

	for tile in tiles:
		if _is_wild_tile(tile, okey_context):
			wild_count += 1
			continue

		var eff_color = _effective_color(tile, okey_context)
		var eff_number = _effective_number(tile, okey_context)

		if number == -1:
			number = eff_number
		elif eff_number != number:
			return _fail("set_number_mismatch")

		if colors.has(eff_color):
			return _fail("set_duplicate_color")
		colors.append(eff_color)

	if number == -1:
		# All real jokers: choose max value for scoring (should not happen in standard set).
		number = 13

	# Ensure we don't exceed available distinct colors (4 total).
	if colors.size() + wild_count > 4:
		return _fail("set_too_many_tiles")

	return _ok(number * tiles.size())

func _is_wild_tile(tile: Tile, okey_context: OkeyContext) -> bool:
	return okey_context.is_real_okey(tile)

func _effective_color(tile: Tile, okey_context: OkeyContext) -> int:
	if tile.kind == Tile.Kind.FAKE_OKEY:
		return okey_context.okey_color
	return tile.color

func _effective_number(tile: Tile, okey_context: OkeyContext) -> int:
	if tile.kind == Tile.Kind.FAKE_OKEY:
		return okey_context.okey_number
	return tile.number

func _run_points_for_sequence(start: int, length: int) -> int:
	# Dossier scoring: sum of represented tile numbers.
	var total = 0
	for i in range(length):
		total += start + i
	return total

func _ok(points_value: int) -> Dictionary:
	return {"ok": true, "reason": "", "points_value": points_value}

func _fail(code: String) -> Dictionary:
	return {"ok": false, "reason": code, "points_value": 0}
