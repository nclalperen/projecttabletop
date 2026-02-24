extends RefCounted

const UI_SETTINGS_SCRIPT: Script = preload("res://ui/services/UISettings.gd")
const DISPLAY_SETTINGS_SCRIPT: Script = preload("res://ui/services/DisplaySettingsService.gd")


func run() -> bool:
	return (
		_test_default_keys_present()
		and _test_visual_sanitize_bounds()
		and _test_display_sanitize_bounds()
	)


func _test_default_keys_present() -> bool:
	var settings: Dictionary = UI_SETTINGS_SCRIPT.load_from_disk()
	var required_keys: PackedStringArray = [
		"sfx_volume",
		"music_volume",
		"graphics_profile",
		"aa_mode",
		"ssao_quality",
		"ssr_enabled",
		"resolution_scale",
		"postfx_strength",
		"shadow_quality",
		"display_mode",
		"monitor_index",
		"resolution_width",
		"resolution_height",
		"refresh_rate_hz",
		"vsync_mode",
		"fps_cap",
		"presentation_mode",
	]
	for key in required_keys:
		if not settings.has(key):
			push_error("UI settings missing key: %s" % key)
			return false
	return true


func _test_visual_sanitize_bounds() -> bool:
	var sanitized: Dictionary = UI_SETTINGS_SCRIPT.sanitize_visual_settings({
		"graphics_profile": "unknown",
		"aa_mode": "bad",
		"ssao_quality": 99,
		"ssr_enabled": true,
		"resolution_scale": 9.0,
		"postfx_strength": -4.0,
		"shadow_quality": 99,
	})
	if int(sanitized.get("ssao_quality", -1)) < 0 or int(sanitized.get("ssao_quality", -1)) > 3:
		push_error("UI settings ssao_quality sanitize bounds failed")
		return false
	var rs: float = float(sanitized.get("resolution_scale", 0.0))
	if rs < 0.55 or rs > 1.20:
		push_error("UI settings resolution_scale sanitize bounds failed")
		return false
	var pf: float = float(sanitized.get("postfx_strength", 0.0))
	if pf < 0.0 or pf > 1.0:
		push_error("UI settings postfx_strength sanitize bounds failed")
		return false
	var sq: int = int(sanitized.get("shadow_quality", -1))
	if sq < 0 or sq > 3:
		push_error("UI settings shadow_quality sanitize bounds failed")
		return false
	return true


func _test_display_sanitize_bounds() -> bool:
	var sanitized: Dictionary = UI_SETTINGS_SCRIPT.sanitize_display_settings({
		"display_mode": "invalid_mode",
		"monitor_index": -99,
		"resolution_width": 99999,
		"resolution_height": 99999,
		"refresh_rate_hz": 1000,
		"vsync_mode": "broken",
		"fps_cap": 777,
	})
	var modes: PackedStringArray = [
		DISPLAY_SETTINGS_SCRIPT.MODE_WINDOWED,
		DISPLAY_SETTINGS_SCRIPT.MODE_BORDERLESS,
		DISPLAY_SETTINGS_SCRIPT.MODE_EXCLUSIVE,
	]
	if not modes.has(String(sanitized.get("display_mode", ""))):
		push_error("Display settings display_mode sanitize failed")
		return false
	var monitor_index: int = int(sanitized.get("monitor_index", -1))
	if monitor_index < 0:
		push_error("Display settings monitor_index sanitize failed")
		return false
	if int(sanitized.get("resolution_width", 0)) <= 0 or int(sanitized.get("resolution_height", 0)) <= 0:
		push_error("Display settings resolution sanitize failed")
		return false
	var vsync: String = String(sanitized.get("vsync_mode", ""))
	var vsync_modes: PackedStringArray = [
		DISPLAY_SETTINGS_SCRIPT.VSYNC_DISABLED,
		DISPLAY_SETTINGS_SCRIPT.VSYNC_ENABLED,
		DISPLAY_SETTINGS_SCRIPT.VSYNC_ADAPTIVE,
		DISPLAY_SETTINGS_SCRIPT.VSYNC_MAILBOX,
	]
	if not vsync_modes.has(vsync):
		push_error("Display settings vsync sanitize failed")
		return false
	var fps_cap: int = int(sanitized.get("fps_cap", -1))
	if fps_cap < 0:
		push_error("Display settings fps_cap sanitize failed")
		return false
	return true
