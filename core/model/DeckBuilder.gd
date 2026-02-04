extends RefCounted
class_name DeckBuilder

func build_standard_set(rng: RandomNumberGenerator = null) -> Array:
	var tiles: Array = []
	var id = 0

	for color in [Tile.TileColor.RED, Tile.TileColor.BLUE, Tile.TileColor.BLACK, Tile.TileColor.YELLOW]:
		for number in range(1, 14):
			# Two copies of each normal tile
			for copy in range(2):
				var tile = Tile.new(color, number, Tile.Kind.NORMAL, id)
				tiles.append(tile)
				id += 1

	# Add two fake okey tiles
	for i in range(2):
		var fake = Tile.new(Tile.TileColor.RED, 0, Tile.Kind.FAKE_OKEY, id)
		tiles.append(fake)
		id += 1

	if rng != null:
		shuffle_with_rng(tiles, rng)

	return tiles

func shuffle_with_rng(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp


