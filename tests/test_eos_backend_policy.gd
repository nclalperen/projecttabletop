extends RefCounted

const POLICY_SCRIPT: Script = preload("res://net/EOSBackendPolicy.gd")


func run() -> bool:
	return (
		_test_policy_constants_and_sanitize()
		and _test_env_policy_override()
		and _test_legacy_runtime_override()
		and _test_build_family_non_empty()
	)


func _test_policy_constants_and_sanitize() -> bool:
	if POLICY_SCRIPT.sanitize("mock_allowed") != POLICY_SCRIPT.POLICY_MOCK_ALLOWED:
		push_error("sanitize should accept mock_allowed")
		return false
	if POLICY_SCRIPT.sanitize("runtime_preferred") != POLICY_SCRIPT.POLICY_RUNTIME_PREFERRED:
		push_error("sanitize should accept runtime_preferred")
		return false
	if POLICY_SCRIPT.sanitize("runtime_required") != POLICY_SCRIPT.POLICY_RUNTIME_REQUIRED:
		push_error("sanitize should accept runtime_required")
		return false
	if POLICY_SCRIPT.sanitize("invalid") != "":
		push_error("sanitize should reject invalid policy value")
		return false
	return true


func _test_env_policy_override() -> bool:
	var prev_policy: String = OS.get_environment(POLICY_SCRIPT.ENV_POLICY)
	var prev_runtime_env: String = OS.get_environment(POLICY_SCRIPT.ENV_RUNTIME_ENABLE)
	OS.set_environment(POLICY_SCRIPT.ENV_RUNTIME_ENABLE, "")
	OS.set_environment(POLICY_SCRIPT.ENV_POLICY, POLICY_SCRIPT.POLICY_RUNTIME_REQUIRED)
	var resolved: String = POLICY_SCRIPT.current_policy()
	OS.set_environment(POLICY_SCRIPT.ENV_POLICY, prev_policy)
	OS.set_environment(POLICY_SCRIPT.ENV_RUNTIME_ENABLE, prev_runtime_env)
	if resolved != POLICY_SCRIPT.POLICY_RUNTIME_REQUIRED:
		push_error("Explicit backend policy env should override default policy")
		return false
	return true


func _test_legacy_runtime_override() -> bool:
	var prev_policy: String = OS.get_environment(POLICY_SCRIPT.ENV_POLICY)
	var prev_runtime_env: String = OS.get_environment(POLICY_SCRIPT.ENV_RUNTIME_ENABLE)
	OS.set_environment(POLICY_SCRIPT.ENV_POLICY, "")
	OS.set_environment(POLICY_SCRIPT.ENV_RUNTIME_ENABLE, "1")
	var preferred: String = POLICY_SCRIPT.current_policy()
	OS.set_environment(POLICY_SCRIPT.ENV_RUNTIME_ENABLE, "0")
	var mock_allowed: String = POLICY_SCRIPT.current_policy()
	OS.set_environment(POLICY_SCRIPT.ENV_POLICY, prev_policy)
	OS.set_environment(POLICY_SCRIPT.ENV_RUNTIME_ENABLE, prev_runtime_env)
	if preferred != POLICY_SCRIPT.POLICY_RUNTIME_PREFERRED:
		push_error("Legacy PROJECT101_EOS_RUNTIME=1 should imply runtime_preferred policy")
		return false
	if mock_allowed != POLICY_SCRIPT.POLICY_MOCK_ALLOWED:
		push_error("Legacy PROJECT101_EOS_RUNTIME=0 should imply mock_allowed policy")
		return false
	return true


func _test_build_family_non_empty() -> bool:
	var prev_family: String = OS.get_environment(POLICY_SCRIPT.ENV_BUILD_FAMILY)
	OS.set_environment(POLICY_SCRIPT.ENV_BUILD_FAMILY, "")
	var fallback: String = POLICY_SCRIPT.build_family()
	OS.set_environment(POLICY_SCRIPT.ENV_BUILD_FAMILY, "qa")
	var explicit: String = POLICY_SCRIPT.build_family()
	OS.set_environment(POLICY_SCRIPT.ENV_BUILD_FAMILY, prev_family)
	if fallback.strip_edges() == "":
		push_error("build_family fallback should not be empty")
		return false
	if explicit != "qa":
		push_error("build_family should use explicit env override")
		return false
	return true
