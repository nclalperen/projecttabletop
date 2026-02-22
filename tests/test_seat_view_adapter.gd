extends RefCounted

const ADAPTER: Script = preload("res://core/network/SeatViewAdapter.gd")

func run() -> bool:
	return _test_basic_mapping() and _test_rotate_helpers()

func _test_basic_mapping() -> bool:
	if ADAPTER.to_local(2, 1, 4) != 1:
		push_error("to_local mapping mismatch")
		return false
	if ADAPTER.to_abs(1, 1, 4) != 2:
		push_error("to_abs mapping mismatch")
		return false
	if ADAPTER.to_local(0, 3, 4) != 1:
		push_error("wraparound local mapping mismatch")
		return false
	return true

func _test_rotate_helpers() -> bool:
	var src: Array = ["A", "B", "C", "D"]
	var rotated: Array = ADAPTER.rotate_players_to_local(src, 2)
	if rotated != ["C", "D", "A", "B"]:
		push_error("rotate_players_to_local mismatch: %s" % str(rotated))
		return false
	var abs_back: Array = ADAPTER.rotate_players_to_abs(rotated, 2)
	if abs_back != src:
		push_error("rotate_players_to_abs mismatch: %s" % str(abs_back))
		return false
	return true
