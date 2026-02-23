extends RefCounted

const DISPLAY_SETTINGS_SCRIPT: Script = preload("res://ui/services/DisplaySettingsService.gd")


func run() -> bool:
	return (
		_test_defaults_and_sanitize()
		and _test_monitor_and_resolution_listing()
		and _test_apply_headless_contract()
	)


func _test_defaults_and_sanitize() -> bool:
	var defaults: Dictionary = DISPLAY_SETTINGS_SCRIPT.default_settings()
	var required: PackedStringArray = [
		"display_mode",
		"monitor_index",
		"resolution_width",
		"resolution_height",
		"refresh_rate_hz",
		"vsync_mode",
		"fps_cap",
	]
	for key in required:
		if not defaults.has(key):
			push_error("Display settings default missing key: %s" % key)
			return false

	var sanitized: Dictionary = DISPLAY_SETTINGS_SCRIPT.sanitize({
		"display_mode": "bad",
		"monitor_index": 999,
		"resolution_width": 99999,
		"resolution_height": 99999,
		"refresh_rate_hz": 999,
		"vsync_mode": "bad",
		"fps_cap": 177,
	})
	var mode: String = str(sanitized.get("display_mode", ""))
	if not PackedStringArray([
		DISPLAY_SETTINGS_SCRIPT.MODE_WINDOWED,
		DISPLAY_SETTINGS_SCRIPT.MODE_BORDERLESS,
		DISPLAY_SETTINGS_SCRIPT.MODE_EXCLUSIVE,
	]).has(mode):
		push_error("Display sanitize mode failed")
		return false
	if int(sanitized.get("monitor_index", -1)) < 0:
		push_error("Display sanitize monitor index failed")
		return false
	if int(sanitized.get("resolution_width", 0)) <= 0 or int(sanitized.get("resolution_height", 0)) <= 0:
		push_error("Display sanitize resolution failed")
		return false
	return true


func _test_monitor_and_resolution_listing() -> bool:
	var monitors: Array[Dictionary] = DISPLAY_SETTINGS_SCRIPT.list_monitors()
	if monitors.is_empty():
		push_error("Display settings should expose at least one monitor")
		return false
	for monitor in monitors:
		var idx: int = int(monitor.get("index", 0))
		var resolutions: Array[Vector2i] = DISPLAY_SETTINGS_SCRIPT.list_resolutions(idx)
		if resolutions.is_empty():
			push_error("Display settings should expose at least one resolution for monitor %d" % idx)
			return false
	return true


func _test_apply_headless_contract() -> bool:
	var result: Dictionary = DISPLAY_SETTINGS_SCRIPT.apply_safe(DISPLAY_SETTINGS_SCRIPT.default_settings())
	if not bool(result.get("ok", false)):
		push_error("Display apply_safe returned non-ok result")
		return false
	if DISPLAY_SETTINGS_SCRIPT.is_headless() and String(result.get("code", "")) != "headless_noop":
		push_error("Display apply_safe should return headless_noop in headless mode")
		return false
	return true
