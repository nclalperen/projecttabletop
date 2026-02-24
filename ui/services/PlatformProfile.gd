extends RefCounted
class_name PlatformProfile

const DESKTOP_PLATFORMS: PackedStringArray = ["Windows", "Linux", "macOS"]


static func platform_name() -> String:
	return OS.get_name()


static func is_android() -> bool:
	return platform_name() == "Android"


static func is_desktop() -> bool:
	return DESKTOP_PLATFORMS.has(platform_name())


static func default_presentation_mode() -> String:
	return "2d" if is_android() else "3d"


static func supports_desktop_window_controls() -> bool:
	if DisplayServer.get_name().to_lower().find("headless") != -1:
		return false
	return is_desktop()


static func supports_desktop_window_controls_for_platform(platform: String) -> bool:
	return DESKTOP_PLATFORMS.has(platform)
