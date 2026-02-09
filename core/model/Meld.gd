extends RefCounted
class_name Meld

enum Kind { RUN, SET, PAIRS }

var kind: int
var tiles: Array = []  # Array[int] unique_ids
var tiles_data: Array = []  # Array[Tile] (optional cache for validation/logic)
var owner_index: int = -1

func _init(p_kind: int = Kind.RUN, p_tiles: Array = [], p_tiles_data: Array = [], p_owner_index: int = -1) -> void:
	kind = p_kind
	tiles = p_tiles
	tiles_data = p_tiles_data
	owner_index = p_owner_index

func min_length() -> int:
	if kind == Kind.PAIRS:
		return 2
	return 3

func size() -> int:
	return tiles.size()

