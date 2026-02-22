extends RefCounted

const UI_SETTINGS_SCRIPT: Script = preload("res://ui/services/UISettings.gd")


func run() -> bool:
	return _test_default_keys_present() and _test_visual_sanitize_bounds()


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
	return true
