extends RefCounted

const PLATFORM_PROFILE_SCRIPT: Script = preload("res://ui/services/PlatformProfile.gd")


func run() -> bool:
	return (
		_test_platform_name_and_default_mode()
		and _test_desktop_window_control_capability_matrix()
	)


func _test_platform_name_and_default_mode() -> bool:
	var name: String = PLATFORM_PROFILE_SCRIPT.platform_name()
	if name.strip_edges() == "":
		push_error("PlatformProfile returned empty platform name")
		return false
	var default_mode: String = PLATFORM_PROFILE_SCRIPT.default_presentation_mode()
	if not PackedStringArray(["2d", "3d"]).has(default_mode):
		push_error("PlatformProfile returned invalid default presentation mode")
		return false
	if PLATFORM_PROFILE_SCRIPT.is_android() and default_mode != "2d":
		push_error("Android should default to 2d presentation mode")
		return false
	if not PLATFORM_PROFILE_SCRIPT.is_android() and default_mode != "3d":
		push_error("Non-Android platforms should default to 3d presentation mode")
		return false
	return true


func _test_desktop_window_control_capability_matrix() -> bool:
	if not PLATFORM_PROFILE_SCRIPT.supports_desktop_window_controls_for_platform("Windows"):
		push_error("Windows should support desktop window controls")
		return false
	if not PLATFORM_PROFILE_SCRIPT.supports_desktop_window_controls_for_platform("Linux"):
		push_error("Linux should support desktop window controls")
		return false
	if PLATFORM_PROFILE_SCRIPT.supports_desktop_window_controls_for_platform("Android"):
		push_error("Android should not be treated as desktop window controls platform")
		return false
	return true
