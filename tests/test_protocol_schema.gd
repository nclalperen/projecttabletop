extends RefCounted

const PROTOCOL: Script = preload("res://net/Protocol.gd")

func run() -> bool:
	return _test_validate_client_messages() and _test_validate_host_messages()

func _test_validate_client_messages() -> bool:
	var ok_msg: Dictionary = PROTOCOL.wrap(PROTOCOL.C_ACTION_REQUEST, {
		"seq": 1,
		"turn_id": 0,
		"action": {"type": "DRAW_FROM_DECK", "player_id": 0, "payload": {}},
	})
	var ok_res: Dictionary = PROTOCOL.validate_client_message(ok_msg)
	if not bool(ok_res.get("ok", false)):
		push_error("Expected valid client message")
		return false
	var bad_msg: Dictionary = PROTOCOL.wrap(PROTOCOL.C_ACTION_REQUEST, {
		"seq": 1,
		"turn_id": 0,
	})
	var bad_res: Dictionary = PROTOCOL.validate_client_message(bad_msg)
	if bool(bad_res.get("ok", false)):
		push_error("Expected missing field validation failure")
		return false
	return true

func _test_validate_host_messages() -> bool:
	var ok_msg: Dictionary = PROTOCOL.wrap(PROTOCOL.S_STATE_SNAPSHOT, {
		"turn_id": 10,
		"state": {"phase": 0},
	})
	var ok_res: Dictionary = PROTOCOL.validate_host_message(ok_msg)
	if not bool(ok_res.get("ok", false)):
		push_error("Expected valid host snapshot message")
		return false
	var mismatch: Dictionary = ok_msg.duplicate(true)
	mismatch["protocol"] = 999
	var mismatch_res: Dictionary = PROTOCOL.validate_host_message(mismatch)
	if bool(mismatch_res.get("ok", false)):
		push_error("Expected protocol mismatch failure")
		return false
	return true
