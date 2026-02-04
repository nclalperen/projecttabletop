extends RefCounted

const Tile = preload("res://core/model/Tile.gd")
const OkeyContext = preload("res://core/model/OkeyContext.gd")
const MeldValidator = preload("res://core/rules/MeldValidator.gd")

func run() -> bool:
	return _test_run_set() and _test_wild_substitution() and _test_invalid_set_duplicate_color()

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

	var fake_okey = Tile.new(Tile.TileColor.RED, 0, Tile.Kind.FAKE_OKEY, 40)
	var set_tiles = [
		Tile.new(Tile.TileColor.RED, 8, Tile.Kind.NORMAL, 41),
		Tile.new(Tile.TileColor.BLUE, 8, Tile.Kind.NORMAL, 42),
		fake_okey,
	]
	var res2 = validator.validate_set(set_tiles, ctx)
	if not res2.ok:
		push_error("Expected valid set with fake okey substitution")
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




