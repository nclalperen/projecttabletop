extends RefCounted


func run() -> bool:
	return _test_run_set() and _test_wild_substitution() and _test_invalid_set_duplicate_color() and _test_run_no_wrap() and _test_fake_okey_not_wild_in_non_okey_color_run()

func _test_run_set() -> bool:
	var indicator = Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 1)
	var ctx = OkeyContext.new(indicator)
	var validator = MeldValidator.new()

	var run_tiles = [
		Tile.new(Tile.TileColor.RED, 4, Tile.Kind.NORMAL, 10),
		Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 11),
		Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 12),
	]
	var res = validator.validate_run(run_tiles, ctx)
	if not res.ok:
		push_error("Expected valid run")
		return false

	var set_tiles = [
		Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 20),
		Tile.new(Tile.TileColor.BLUE, 7, Tile.Kind.NORMAL, 21),
		Tile.new(Tile.TileColor.BLACK, 7, Tile.Kind.NORMAL, 22),
	]
	var res2 = validator.validate_set(set_tiles, ctx)
	if not res2.ok:
		push_error("Expected valid set")
		return false

	return true

func _test_wild_substitution() -> bool:
	var indicator = Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 1)
	var ctx = OkeyContext.new(indicator)
	var validator = MeldValidator.new()

	# Okey is 6 RED
	var okey_tile = Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 30)
	var run_tiles = [
		Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 31),
		okey_tile,
		Tile.new(Tile.TileColor.RED, 7, Tile.Kind.NORMAL, 32),
	]
	var res = validator.validate_run(run_tiles, ctx)
	if not res.ok:
		push_error("Expected valid run with okey substitution")
		return false

	# Fake okey represents the okey value for the round (here: RED 6), not a free wild.
	var fake_okey = Tile.new(Tile.TileColor.RED, 0, Tile.Kind.FAKE_OKEY, 40)
	var set_tiles = [
		Tile.new(Tile.TileColor.BLUE, 6, Tile.Kind.NORMAL, 41),
		Tile.new(Tile.TileColor.BLACK, 6, Tile.Kind.NORMAL, 42),
		fake_okey, # represents RED 6
	]
	var res2 = validator.validate_set(set_tiles, ctx)
	if not res2.ok:
		push_error("Expected valid set with fake okey as represented okey value")
		return false

	return true

func _test_run_no_wrap() -> bool:
	var indicator = Tile.new(Tile.TileColor.YELLOW, 5, Tile.Kind.NORMAL, 1)
	var ctx = OkeyContext.new(indicator)
	var validator = MeldValidator.new()

	# No wrap: 12-13-1 is invalid even if same color.
	var run_tiles = [
		Tile.new(Tile.TileColor.YELLOW, 12, Tile.Kind.NORMAL, 60),
		Tile.new(Tile.TileColor.YELLOW, 13, Tile.Kind.NORMAL, 61),
		Tile.new(Tile.TileColor.YELLOW, 1, Tile.Kind.NORMAL, 62),
	]
	var res = validator.validate_run(run_tiles, ctx)
	if res.ok:
		push_error("Expected invalid run with wrap-around 12-13-1")
		return false
	return true

func _test_invalid_set_duplicate_color() -> bool:
	var indicator = Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 1)
	var ctx = OkeyContext.new(indicator)
	var validator = MeldValidator.new()

	var set_tiles = [
		Tile.new(Tile.TileColor.RED, 9, Tile.Kind.NORMAL, 50),
		Tile.new(Tile.TileColor.RED, 9, Tile.Kind.NORMAL, 51),
		Tile.new(Tile.TileColor.BLUE, 9, Tile.Kind.NORMAL, 52),
	]
	var res = validator.validate_set(set_tiles, ctx)
	if res.ok:
		push_error("Expected invalid set with duplicate color")
		return false

	return true

func _test_fake_okey_not_wild_in_non_okey_color_run() -> bool:
	var indicator = Tile.new(Tile.TileColor.RED, 11, Tile.Kind.NORMAL, 101)
	var ctx = OkeyContext.new(indicator) # okey value is RED-12
	var validator = MeldValidator.new()

	# Fake okey is not free wild; it only represents RED-12 here.
	# Therefore it cannot complete BLACK 11-12-13.
	var fake_okey = Tile.new(Tile.TileColor.RED, 0, Tile.Kind.FAKE_OKEY, 102)
	var run_tiles = [
		Tile.new(Tile.TileColor.BLACK, 11, Tile.Kind.NORMAL, 103),
		fake_okey,
		Tile.new(Tile.TileColor.BLACK, 13, Tile.Kind.NORMAL, 104),
	]
	var res = validator.validate_run(run_tiles, ctx)
	if res.ok:
		push_error("Expected invalid run: fake okey cannot act as wildcard in non-okey-color run")
		return false
	return true




