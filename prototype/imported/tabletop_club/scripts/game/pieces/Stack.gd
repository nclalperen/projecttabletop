extends "res://prototype/imported/tabletop_club/scripts/game/pieces/StackablePiece.gd"

const STACK_AUTO: int = 0
const STACK_BOTTOM: int = 1
const STACK_TOP: int = 2

const FLIP_AUTO: int = 0
const FLIP_NO: int = 1
const FLIP_YES: int = 2

var _pieces: Array[Dictionary] = []


func add_piece(piece_entry: Dictionary, piece_transform: Transform3D, on: int = STACK_AUTO, flip: int = FLIP_AUTO) -> void:
	var on_top: bool = true
	match on:
		STACK_BOTTOM:
			on_top = false
		STACK_TOP:
			on_top = true
		_:
			on_top = true
	var should_flip: bool = false
	match flip:
		FLIP_YES:
			should_flip = true
		FLIP_NO:
			should_flip = false
		_:
			should_flip = false
	var meta: Dictionary = {
		"piece_entry": piece_entry.duplicate(true),
		"transform": piece_transform,
		"flip_y": should_flip,
	}
	if on_top:
		_pieces.append(meta)
	else:
		_pieces.push_front(meta)


func empty() -> bool:
	return _pieces.is_empty()


func get_piece_count() -> int:
	return _pieces.size()


func get_pieces() -> Array:
	return _pieces.duplicate(true)


func get_total_height() -> float:
	var unit_h: float = 0.004
	if piece_entry.has("scale"):
		var sc = piece_entry["scale"]
		if sc is Vector3:
			unit_h = maxf(0.001, float(sc.y))
	return unit_h * max(1, get_piece_count())


func get_size() -> Vector3:
	var s: Vector3 = super.get_size()
	return Vector3(s.x, get_total_height(), s.z)


func is_card_stack() -> bool:
	if _pieces.is_empty():
		return false
	var entry: Dictionary = _pieces[0].get("piece_entry", {})
	return String(entry.get("scene_path", "")).to_lower().contains("card")


func pop_index(from: int = STACK_AUTO) -> int:
	if _pieces.is_empty():
		return -1
	match from:
		STACK_BOTTOM:
			return 0
		STACK_TOP:
			return _pieces.size() - 1
		_:
			return _pieces.size() - 1


func remove_piece(index: int) -> Dictionary:
	if index < 0 or index >= _pieces.size():
		return {}
	var item: Dictionary = _pieces[index]
	_pieces.remove_at(index)
	return item


func pop_piece(from: int = STACK_AUTO) -> Dictionary:
	var idx: int = pop_index(from)
	if idx < 0:
		return {}
	return remove_piece(idx)


func request_shuffle() -> void:
	_pieces.shuffle()


func request_sort(key: String) -> void:
	_pieces.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var av = a.get("piece_entry", {}).get(key, "")
		var bv = b.get("piece_entry", {}).get(key, "")
		return String(av) < String(bv)
	)

