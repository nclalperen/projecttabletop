extends RefCounted

const SAVE_PATH: String = "user://ui_settings.cfg"
const SECTION_AUDIO: String = "audio"
const SECTION_VISUAL: String = "visual"
const SECTION_DISPLAY: String = "display"
const VISUAL_QUALITY_SCRIPT: Script = preload("res://ui/services/VisualQualityService.gd")
const DISPLAY_SETTINGS_SCRIPT: Script = preload("res://ui/services/DisplaySettingsService.gd")
const DEFAULT_SFX_VOLUME: float = 0.82
const DEFAULT_MUSIC_VOLUME: float = 0.30


static func load_from_disk() -> Dictionary:
	var out: Dictionary = VISUAL_QUALITY_SCRIPT.default_settings()
	var out_display: Dictionary = DISPLAY_SETTINGS_SCRIPT.default_settings()
	for key in out_display.keys():
		out[key] = out_display[key]
	out["sfx_volume"] = DEFAULT_SFX_VOLUME
	out["music_volume"] = DEFAULT_MUSIC_VOLUME
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return out
	out["sfx_volume"] = clampf(float(cfg.get_value(SECTION_AUDIO, "sfx_volume", DEFAULT_SFX_VOLUME)), 0.0, 1.0)
	out["music_volume"] = clampf(float(cfg.get_value(SECTION_AUDIO, "music_volume", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	var raw_visual: Dictionary = {
		"graphics_profile": str(cfg.get_value(SECTION_VISUAL, "graphics_profile", out["graphics_profile"])),
		"aa_mode": str(cfg.get_value(SECTION_VISUAL, "aa_mode", out["aa_mode"])),
		"ssao_quality": int(cfg.get_value(SECTION_VISUAL, "ssao_quality", out["ssao_quality"])),
		"ssr_enabled": bool(cfg.get_value(SECTION_VISUAL, "ssr_enabled", out["ssr_enabled"])),
		"resolution_scale": float(cfg.get_value(SECTION_VISUAL, "resolution_scale", out["resolution_scale"])),
		"postfx_strength": float(cfg.get_value(SECTION_VISUAL, "postfx_strength", out["postfx_strength"])),
		"shadow_quality": int(cfg.get_value(SECTION_VISUAL, "shadow_quality", out["shadow_quality"])),
	}
	var sanitized_visual: Dictionary = VISUAL_QUALITY_SCRIPT.sanitize(raw_visual)
	for key in sanitized_visual.keys():
		out[key] = sanitized_visual[key]
	var raw_display: Dictionary = {
		"display_mode": str(cfg.get_value(SECTION_DISPLAY, "display_mode", out["display_mode"])),
		"monitor_index": int(cfg.get_value(SECTION_DISPLAY, "monitor_index", out["monitor_index"])),
		"resolution_width": int(cfg.get_value(SECTION_DISPLAY, "resolution_width", out["resolution_width"])),
		"resolution_height": int(cfg.get_value(SECTION_DISPLAY, "resolution_height", out["resolution_height"])),
		"refresh_rate_hz": int(cfg.get_value(SECTION_DISPLAY, "refresh_rate_hz", out["refresh_rate_hz"])),
		"vsync_mode": str(cfg.get_value(SECTION_DISPLAY, "vsync_mode", out["vsync_mode"])),
		"fps_cap": int(cfg.get_value(SECTION_DISPLAY, "fps_cap", out["fps_cap"])),
	}
	var sanitized_display: Dictionary = DISPLAY_SETTINGS_SCRIPT.sanitize(raw_display)
	for key in sanitized_display.keys():
		out[key] = sanitized_display[key]
	return out


static func save_to_disk(
	sfx_volume: float,
	music_volume: float,
	visual_settings: Dictionary = {},
	display_settings: Dictionary = {}
) -> void:
	var cfg := ConfigFile.new()
	var loaded: Dictionary = load_from_disk()
	var merged_visual: Dictionary = {}
	var merged_display: Dictionary = {}
	for key in VISUAL_QUALITY_SCRIPT.default_settings().keys():
		merged_visual[key] = loaded.get(key)
	for key in DISPLAY_SETTINGS_SCRIPT.default_settings().keys():
		merged_display[key] = loaded.get(key)
	for key in visual_settings.keys():
		merged_visual[key] = visual_settings[key]
	for key in display_settings.keys():
		merged_display[key] = display_settings[key]
	var visual: Dictionary = VISUAL_QUALITY_SCRIPT.sanitize(merged_visual)
	var display: Dictionary = DISPLAY_SETTINGS_SCRIPT.sanitize(merged_display)
	cfg.set_value(SECTION_AUDIO, "sfx_volume", clampf(sfx_volume, 0.0, 1.0))
	cfg.set_value(SECTION_AUDIO, "music_volume", clampf(music_volume, 0.0, 1.0))
	cfg.set_value(SECTION_VISUAL, "graphics_profile", str(visual["graphics_profile"]))
	cfg.set_value(SECTION_VISUAL, "aa_mode", str(visual["aa_mode"]))
	cfg.set_value(SECTION_VISUAL, "ssao_quality", int(visual["ssao_quality"]))
	cfg.set_value(SECTION_VISUAL, "ssr_enabled", bool(visual["ssr_enabled"]))
	cfg.set_value(SECTION_VISUAL, "resolution_scale", float(visual["resolution_scale"]))
	cfg.set_value(SECTION_VISUAL, "postfx_strength", float(visual["postfx_strength"]))
	cfg.set_value(SECTION_VISUAL, "shadow_quality", int(visual["shadow_quality"]))
	cfg.set_value(SECTION_DISPLAY, "display_mode", str(display["display_mode"]))
	cfg.set_value(SECTION_DISPLAY, "monitor_index", int(display["monitor_index"]))
	cfg.set_value(SECTION_DISPLAY, "resolution_width", int(display["resolution_width"]))
	cfg.set_value(SECTION_DISPLAY, "resolution_height", int(display["resolution_height"]))
	cfg.set_value(SECTION_DISPLAY, "refresh_rate_hz", int(display["refresh_rate_hz"]))
	cfg.set_value(SECTION_DISPLAY, "vsync_mode", str(display["vsync_mode"]))
	cfg.set_value(SECTION_DISPLAY, "fps_cap", int(display["fps_cap"]))
	cfg.save(SAVE_PATH)


static func default_visual_settings() -> Dictionary:
	return VISUAL_QUALITY_SCRIPT.default_settings()


static func sanitize_visual_settings(raw: Dictionary) -> Dictionary:
	return VISUAL_QUALITY_SCRIPT.sanitize(raw)


static func default_display_settings() -> Dictionary:
	return DISPLAY_SETTINGS_SCRIPT.default_settings()


static func sanitize_display_settings(raw: Dictionary) -> Dictionary:
	return DISPLAY_SETTINGS_SCRIPT.sanitize(raw)


static func linear_to_db_safe(level: float) -> float:
	var clamped: float = clampf(level, 0.0, 1.0)
	if clamped <= 0.001:
		return -60.0
	return linear_to_db(clamped)
