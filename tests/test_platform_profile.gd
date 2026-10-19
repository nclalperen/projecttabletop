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
	if default_mode != "vector3d":
		push_error("All platforms should default to vector3d presentation")
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
