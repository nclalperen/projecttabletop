extends RefCounted

const UI_SETTINGS_SCRIPT: Script = preload("res://ui/services/UISettings.gd")


func run() -> bool:
	return (
		_test_defaults_include_presentation_mode()
		and _test_presentation_mode_sanitize()
	)


func _test_defaults_include_presentation_mode() -> bool:
	var settings: Dictionary = UI_SETTINGS_SCRIPT.load_from_disk()
	if not settings.has("presentation_mode"):
		push_error("UI settings missing presentation_mode key")
		return false
	var mode: String = str(settings.get("presentation_mode", ""))
	if not PackedStringArray(["2d", "3d"]).has(mode):
		push_error("UI settings presentation_mode should be 2d or 3d")
		return false
	return true


func _test_presentation_mode_sanitize() -> bool:
	if UI_SETTINGS_SCRIPT.sanitize_presentation_mode("2d") != "2d":
		push_error("sanitize_presentation_mode should keep 2d")
		return false
	if UI_SETTINGS_SCRIPT.sanitize_presentation_mode("3d") != "3d":
		push_error("sanitize_presentation_mode should keep 3d")
		return false
	var fallback: String = UI_SETTINGS_SCRIPT.default_presentation_mode()
	if UI_SETTINGS_SCRIPT.sanitize_presentation_mode("invalid") != fallback:
		push_error("sanitize_presentation_mode should fallback to default")
		return false
	return true
