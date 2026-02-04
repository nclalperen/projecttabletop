extends RefCounted
class_name OkeyContext

var indicator_tile: Tile
var okey_number: int
var okey_color: int

func _init(p_indicator_tile: Tile) -> void:
	indicator_tile = p_indicator_tile
	okey_color = indicator_tile.color
	okey_number = indicator_tile.number + 1
	if okey_number == 14:
		okey_number = 1

func is_real_okey(tile: Tile) -> bool:
	return tile.kind == Tile.Kind.NORMAL and tile.color == okey_color and tile.number == okey_number

func interpret_fake_okey(tile: Tile) -> Tile:
	if tile.kind != Tile.Kind.FAKE_OKEY:
		return tile
	return Tile.new(okey_color, okey_number, Tile.Kind.NORMAL, tile.unique_id)

func get_fake_okey_value() -> int:
	return okey_number


