extends RefCounted
class_name MeldValidator

func validate_run(tiles: Array, okey_context: OkeyContext) -> Dictionary:
	if tiles.size() < 3:
		return _fail("run_too_short")

	var wild_count = 0
	var color = -1
	var numbers: Array = []

	for tile in tiles:
		if _is_wild(tile, okey_context):
			wild_count += 1
			continue
		if color == -1:
			color = tile.color
		elif tile.color != color:
			return _fail("run_color_mismatch")
		if numbers.has(tile.number):
			return _fail("run_duplicate_number")
		numbers.append(tile.number)

	var length = tiles.size()
	if numbers.is_empty():
		# All wilds: choose max points per canonical run scoring.
		var start = 13 - length + 1
		var max_points = _run_points_for_sequence(start, length)
		return _ok(max_points)

	numbers.sort()
	var best_sum = -1
	for start in range(1, 14 - length + 1):
		var end = start + length - 1
		var fits = true
		for n in numbers:
			if n < start or n > end:
				fits = false
				break
			# duplicates already checked
		if not fits:
			continue
		var missing = length - numbers.size()
		# number of missing slots equals wild_count
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

	var wild_count = 0
	var number = -1
	var colors: Array = []

	for tile in tiles:
		if _is_wild(tile, okey_context):
			wild_count += 1
			continue
		if number == -1:
			number = tile.number
		elif tile.number != number:
			return _fail("set_number_mismatch")
		if colors.has(tile.color):
			return _fail("set_duplicate_color")
		colors.append(tile.color)

	if number == -1:
		# All wilds: pick okey number for points.
		number = okey_context.okey_number

	# Ensure we don't exceed available distinct colors (4 total)
	if colors.size() + wild_count > 4:
		return _fail("set_too_many_tiles")

	var points = number * tiles.size()
	return _ok(points)

func _is_wild(tile: Tile, okey_context: OkeyContext) -> bool:
	return tile.kind == Tile.Kind.FAKE_OKEY or okey_context.is_real_okey(tile)

func _run_points_for_sequence(start: int, length: int) -> int:
	# Canonical rule: 3-tile run counts as middle * 3.
	# For 4+ tiles, add tiles sequentially (sum of run).
	if length == 3:
		return (start + 1) * 3
	var total = 0
	for i in range(length):
		total += start + i
	return total

func _ok(points_value: int) -> Dictionary:
	return {"ok": true, "reason": "", "points_value": points_value}

func _fail(code: String) -> Dictionary:
	return {"ok": false, "reason": code, "points_value": 0}


