extends RefCounted


func run() -> bool:
	return _test_deck_counts() and _test_okey_wraparound()

func _test_deck_counts() -> bool:
	var builder = DeckBuilder.new()
	var deck = builder.build_standard_set()
	if deck.size() != 106:
		push_error("Expected 106 tiles, got %s" % deck.size())
		return false

	var fake_count = 0
	var counts = {}
	for tile in deck:
		if tile.kind == Tile.Kind.FAKE_OKEY:
			fake_count += 1
			continue
		var key = "%s-%s" % [tile.color, tile.number]
		counts[key] = (counts.get(key, 0) + 1)

	if fake_count != 2:
		push_error("Expected 2 fake okey tiles, got %s" % fake_count)
		return false

	for color in [Tile.TileColor.RED, Tile.TileColor.BLUE, Tile.TileColor.BLACK, Tile.TileColor.YELLOW]:
		for number in range(1, 14):
			var key = "%s-%s" % [color, number]
			var count = counts.get(key, 0)
			if count != 2:
				push_error("Expected 2 copies of %s, got %s" % [key, count])
				return false

	return true

func _test_okey_wraparound() -> bool:
	var indicator = Tile.new(Tile.TileColor.RED, 13, Tile.Kind.NORMAL, 0)
	var ctx = OkeyContext.new(indicator)
	if ctx.okey_number != 1:
		push_error("Expected okey number 1 for indicator 13, got %s" % ctx.okey_number)
		return false
	return true




