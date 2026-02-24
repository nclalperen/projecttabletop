extends RefCounted

const ONLINE_SERVICE_SCRIPT: Script = preload("res://net/OnlineServiceEOS.gd")
const BACKEND_POLICY_SCRIPT: Script = preload("res://net/EOSBackendPolicy.gd")

func run() -> bool:
	return (
		_test_default_mock_backend()
		and _test_runtime_request_falls_back_gracefully()
		and _test_runtime_required_policy_hard_fails_without_runtime()
		and _test_supported_platform_matrix()
	)

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
	var original_policy_env: String = OS.get_environment("PROJECT101_EOS_BACKEND_POLICY")
	OS.set_environment("PROJECT101_EOS_BACKEND_POLICY", "")
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

	OS.set_environment("PROJECT101_EOS_BACKEND_POLICY", original_policy_env)
	OS.set_environment("PROJECT101_EOS_RUNTIME", original_runtime_env)
	return ok


func _test_runtime_required_policy_hard_fails_without_runtime() -> bool:
	var original_runtime_env: String = OS.get_environment("PROJECT101_EOS_RUNTIME")
	var original_policy_env: String = OS.get_environment("PROJECT101_EOS_BACKEND_POLICY")
	OS.set_environment("PROJECT101_EOS_RUNTIME", "")
	OS.set_environment("PROJECT101_EOS_BACKEND_POLICY", BACKEND_POLICY_SCRIPT.POLICY_RUNTIME_REQUIRED)

	var service = ONLINE_SERVICE_SCRIPT.new()
	var init_res: Dictionary = service.initialize()
	var ok: bool = true
	if bool(init_res.get("ok", false)):
		push_error("Runtime-required policy should fail availability when runtime cannot initialize in headless tests.")
		ok = false
	if service.is_available():
		push_error("Runtime-required policy should not report service available without runtime.")
		ok = false
	if String(service.get_backend_policy()) != BACKEND_POLICY_SCRIPT.POLICY_RUNTIME_REQUIRED:
		push_error("Runtime-required policy should be reflected by online service backend policy.")
		ok = false
	service.free()

	OS.set_environment("PROJECT101_EOS_BACKEND_POLICY", original_policy_env)
	OS.set_environment("PROJECT101_EOS_RUNTIME", original_runtime_env)
	return ok


func _test_supported_platform_matrix() -> bool:
	if not ONLINE_SERVICE_SCRIPT.is_supported_platform_name("Windows"):
		push_error("Online service should mark Windows as supported runtime platform.")
		return false
	if not ONLINE_SERVICE_SCRIPT.is_supported_platform_name("Android"):
		push_error("Online service should mark Android as supported runtime platform.")
		return false
	if ONLINE_SERVICE_SCRIPT.is_supported_platform_name("Linux"):
		push_error("Online service should not mark Linux as supported runtime platform for EOS runtime.")
		return false
	return true
