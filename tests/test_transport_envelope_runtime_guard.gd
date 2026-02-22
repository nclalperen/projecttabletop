extends RefCounted

const TRANSPORT_SCRIPT: Script = preload("res://net/P2PTransportEOS.gd")

func run() -> bool:
	return _test_mock_delivery_contract() and _test_runtime_guard_stays_mock_safe()

func _test_mock_delivery_contract() -> bool:
	TRANSPORT_SCRIPT.clear_mock_registry()
	var a = TRANSPORT_SCRIPT.new()
	var b = TRANSPORT_SCRIPT.new()
	a.set_backend_mode("mock")
	b.set_backend_mode("mock")
	var packets: Array = []
	b.packet_received.connect(func(from_puid: String, message: Dictionary) -> void:
		packets.append({"from": from_puid, "message": message.duplicate(true)})
	)
	var open_a: Dictionary = a.open_endpoint("A")
	var open_b: Dictionary = b.open_endpoint("B")
	if not bool(open_a.get("ok", false)) or not bool(open_b.get("ok", false)):
		push_error("Mock open_endpoint failed.")
		return false
	var payload: Dictionary = {"type": "PING", "value": 7}
	var send_res: Dictionary = a.send_packet("B", payload, true)
	if not bool(send_res.get("ok", false)):
		push_error("Mock send_packet failed: %s" % str(send_res))
		return false
	if packets.is_empty():
		push_error("Mock packet was not delivered.")
		return false
	var pkt: Dictionary = packets[0]
	if String(pkt.get("from", "")) != "A":
		push_error("Unexpected sender for delivered packet.")
		return false
	var msg: Dictionary = pkt.get("message", {})
	if String(msg.get("type", "")) != "PING" or int(msg.get("value", -1)) != 7:
		push_error("Delivered payload mismatch: %s" % str(msg))
		return false
	a.close_endpoint()
	b.close_endpoint()
	a.free()
	b.free()
	return true

func _test_runtime_guard_stays_mock_safe() -> bool:
	var original_runtime_env: String = OS.get_environment("PROJECT101_EOS_RUNTIME")
	OS.set_environment("PROJECT101_EOS_RUNTIME", "1")

	TRANSPORT_SCRIPT.clear_mock_registry()
	var a = TRANSPORT_SCRIPT.new()
	var b = TRANSPORT_SCRIPT.new()
	a.set_backend_mode("ieos_raw")
	b.set_backend_mode("ieos_raw")
	var packets: Array = []
	b.packet_received.connect(func(from_puid: String, message: Dictionary) -> void:
		packets.append({"from": from_puid, "message": message.duplicate(true)})
	)
	var open_a: Dictionary = a.open_endpoint("A")
	var open_b: Dictionary = b.open_endpoint("B")
	if not bool(open_a.get("ok", false)) or not bool(open_b.get("ok", false)):
		push_error("Guarded runtime path should still open endpoints in headless tests.")
		OS.set_environment("PROJECT101_EOS_RUNTIME", original_runtime_env)
		return false
	var send_res: Dictionary = a.send_packet("B", {"type": "RUNTIME_GUARD"}, true)
	if not bool(send_res.get("ok", false)):
		push_error("Guarded runtime send failed: %s" % str(send_res))
		OS.set_environment("PROJECT101_EOS_RUNTIME", original_runtime_env)
		return false
	if packets.is_empty():
		push_error("Guarded runtime test did not deliver packet via mock-safe path.")
		OS.set_environment("PROJECT101_EOS_RUNTIME", original_runtime_env)
		return false
	a.close_endpoint()
	b.close_endpoint()
	a.free()
	b.free()
	OS.set_environment("PROJECT101_EOS_RUNTIME", original_runtime_env)
	return true
