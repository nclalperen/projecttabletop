extends RefCounted
class_name EOSBackendPolicy

const POLICY_MOCK_ALLOWED: String = "mock_allowed"
const POLICY_RUNTIME_PREFERRED: String = "runtime_preferred"
const POLICY_RUNTIME_REQUIRED: String = "runtime_required"

const ENV_POLICY: String = "PROJECT101_EOS_BACKEND_POLICY"
const ENV_RUNTIME_ENABLE: String = "PROJECT101_EOS_RUNTIME"
const ENV_BUILD_FAMILY: String = "PROJECT101_BUILD_FAMILY"


static func current_policy() -> String:
	var explicit_policy: String = sanitize(String(OS.get_environment(ENV_POLICY)))
	if explicit_policy != "":
		return explicit_policy
	var legacy_policy: String = _legacy_runtime_policy_override()
	if legacy_policy != "":
		return legacy_policy
	if OS.has_feature("editor"):
		return POLICY_MOCK_ALLOWED
	var build_tag: String = _normalized_build_tag(String(ProjectSettings.get_setting("application/config/build", "dev")))
	if not OS.is_debug_build() and _is_release_build(build_tag):
		return POLICY_RUNTIME_REQUIRED
	return POLICY_RUNTIME_PREFERRED


static func sanitize(raw: String) -> String:
	var policy: String = String(raw).to_lower().strip_edges()
	if policy == "":
		return ""
	if policy == "preferred":
		policy = POLICY_RUNTIME_PREFERRED
	elif policy == "required":
		policy = POLICY_RUNTIME_REQUIRED
	elif policy == "mock":
		policy = POLICY_MOCK_ALLOWED
	if not PackedStringArray([
		POLICY_MOCK_ALLOWED,
		POLICY_RUNTIME_PREFERRED,
		POLICY_RUNTIME_REQUIRED,
	]).has(policy):
		return ""
	return policy


static func allows_mock_fallback(policy: String = "") -> bool:
	var normalized: String = _resolve_policy(policy)
	return normalized != POLICY_RUNTIME_REQUIRED


static func runtime_preferred(policy: String = "") -> bool:
	var normalized: String = _resolve_policy(policy)
	return normalized == POLICY_RUNTIME_PREFERRED


static func runtime_required(policy: String = "") -> bool:
	var normalized: String = _resolve_policy(policy)
	return normalized == POLICY_RUNTIME_REQUIRED


static func should_attempt_runtime(policy: String = "") -> bool:
	var normalized: String = _resolve_policy(policy)
	return normalized == POLICY_RUNTIME_PREFERRED or normalized == POLICY_RUNTIME_REQUIRED


static func build_family() -> String:
	var explicit_family: String = String(OS.get_environment(ENV_BUILD_FAMILY)).strip_edges()
	if explicit_family != "":
		return explicit_family.to_lower()
	var build_tag: String = _normalized_build_tag(String(ProjectSettings.get_setting("application/config/build", "dev")))
	return build_tag if build_tag != "" else "dev"


static func _legacy_runtime_policy_override() -> String:
	var raw_runtime: String = String(OS.get_environment(ENV_RUNTIME_ENABLE)).strip_edges().to_lower()
	if raw_runtime == "":
		return ""
	if raw_runtime == "1" or raw_runtime == "true" or raw_runtime == "yes" or raw_runtime == "on":
		return POLICY_RUNTIME_PREFERRED
	return POLICY_MOCK_ALLOWED


static func _resolve_policy(policy: String) -> String:
	var normalized: String = sanitize(policy)
	if normalized != "":
		return normalized
	return current_policy()


static func _normalized_build_tag(raw_build: String) -> String:
	return String(raw_build).to_lower().strip_edges()


static func _is_release_build(build_tag: String) -> bool:
	return PackedStringArray([
		"release",
		"shipping",
		"public",
		"store",
	]).has(build_tag)
