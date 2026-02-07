extends RefCounted


func run() -> bool:
	return _test_no_peek_discard_action()


func _test_no_peek_discard_action() -> bool:
	if Action.ActionType.has("PEEK_DISCARD"):
		push_error("PEEK_DISCARD must not exist in canonical SeOkey11 action surface")
		return false
	return true
