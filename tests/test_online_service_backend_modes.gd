extends RefCounted

const ONLINE_SERVICE_SCRIPT: Script = preload("res://net/OnlineServiceEOS.gd")

func run() -> bool:
	return _test_default_mock_backend() and _test_runtime_request_falls_back_gracefully()

func _test_default_mock_backend() -> bool:
	var original_runtime_env: String = OS.get_environment("PROJECT101_EOS_RUNTIME")
	OS.set_environment("PROJECT101_EOS_RUNTIME", "0")

	var service = ONLINE_SERVICE_SCRIPT.new()
	var init_res: Dictionary = service.initialize()
	var ok: bool = true
	if not bool(init_res.get("ok", false)):
		push_error("Online service should be available in mock mode.")
		ok = false
	if service.get_backend_mode() != "mock":
		push_error("Expected mock backend with runtime env disabled.")
		ok = false
	if not service.is_available():
		push_error("Service should remain available in mock mode.")
		ok = false
	service.free()

	OS.set_environment("PROJECT101_EOS_RUNTIME", original_runtime_env)
	return ok

func _test_runtime_request_falls_back_gracefully() -> bool:
	var original_runtime_env: String = OS.get_environment("PROJECT101_EOS_RUNTIME")
	OS.set_environment("PROJECT101_EOS_RUNTIME", "1")

	var service = ONLINE_SERVICE_SCRIPT.new()
	var init_res: Dictionary = service.initialize()
	var ok: bool = true
	if not bool(init_res.get("ok", false)):
		push_error("Runtime request should not hard-fail availability.")
		ok = false
	if service.get_backend_mode() != "mock":
		push_error("Headless/runtime-unsupported test environment must downgrade to mock.")
		ok = false
	if not service.is_available():
		push_error("Service should remain available after runtime fallback.")
		ok = false
	var reason: String = String(init_res.get("reason", ""))
	if reason == "":
		push_error("Expected runtime fallback reason to be populated.")
		ok = false
	service.free()

	OS.set_environment("PROJECT101_EOS_RUNTIME", original_runtime_env)
	return ok
