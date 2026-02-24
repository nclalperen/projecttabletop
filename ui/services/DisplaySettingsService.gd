extends RefCounted
class_name DisplaySettingsService

const PLATFORM_PROFILE_SCRIPT: Script = preload("res://ui/services/PlatformProfile.gd")

const MODE_WINDOWED: String = "windowed"
const MODE_BORDERLESS: String = "borderless"
const MODE_EXCLUSIVE: String = "exclusive"

const VSYNC_DISABLED: String = "disabled"
const VSYNC_ENABLED: String = "enabled"
const VSYNC_ADAPTIVE: String = "adaptive"
const VSYNC_MAILBOX: String = "mailbox"

const DESKTOP_PLATFORMS: PackedStringArray = ["Windows", "Linux", "macOS"]
const DEFAULT_FPS_CAPS: Array[int] = [0, 30, 60, 90, 120, 144, 165, 240]


static func is_headless() -> bool:
	return DisplayServer.get_name().to_lower().find("headless") != -1


static func supports_desktop_window_controls() -> bool:
	return PLATFORM_PROFILE_SCRIPT.supports_desktop_window_controls()


static func supports_desktop_window_controls_for_platform(platform_name: String) -> bool:
	return PLATFORM_PROFILE_SCRIPT.supports_desktop_window_controls_for_platform(platform_name)


static func default_settings() -> Dictionary:
	if is_headless():
		return {
			"display_mode": MODE_WINDOWED,
			"monitor_index": 0,
			"resolution_width": 1280,
			"resolution_height": 720,
			"refresh_rate_hz": 0,
			"vsync_mode": VSYNC_ENABLED,
			"fps_cap": 0,
		}
	var runtime: Dictionary = current_runtime_settings()
	return sanitize(runtime)


static func sanitize(raw: Dictionary) -> Dictionary:
	var allow_window_controls: bool = supports_desktop_window_controls()
	var monitors: Array[Dictionary] = list_monitors()
	var monitor_count: int = max(1, monitors.size())
	var out: Dictionary = {}
	var display_mode: String = str(raw.get("display_mode", MODE_WINDOWED)).to_lower()
	if not PackedStringArray([MODE_WINDOWED, MODE_BORDERLESS, MODE_EXCLUSIVE]).has(display_mode):
		display_mode = MODE_WINDOWED
	display_mode = safe_mode_for_platform(display_mode)
	var monitor_index: int = clampi(int(raw.get("monitor_index", 0)), 0, monitor_count - 1)
	var resolution_width: int = max(1, int(raw.get("resolution_width", 1280)))
	var resolution_height: int = max(1, int(raw.get("resolution_height", 720)))
	var refresh_rate_hz: int = max(0, int(raw.get("refresh_rate_hz", 0)))
	var vsync_mode: String = str(raw.get("vsync_mode", VSYNC_ENABLED)).to_lower()
	if not PackedStringArray([VSYNC_DISABLED, VSYNC_ENABLED, VSYNC_ADAPTIVE, VSYNC_MAILBOX]).has(vsync_mode):
		vsync_mode = VSYNC_ENABLED
	var fps_cap: int = int(raw.get("fps_cap", 0))
	fps_cap = _sanitize_fps_cap(fps_cap)

	var valid_resolutions: Array[Vector2i] = list_resolutions(monitor_index)
	var requested_res := Vector2i(resolution_width, resolution_height)
	var nearest_res: Vector2i = _nearest_resolution(requested_res, valid_resolutions)
	if nearest_res == Vector2i.ZERO:
		var monitor_size: Vector2i = _monitor_size_for(monitor_index)
		nearest_res = monitor_size if monitor_size != Vector2i.ZERO else Vector2i(1280, 720)

	var valid_rates: PackedInt32Array = list_refresh_rates(monitor_index)
	if refresh_rate_hz != 0 and not valid_rates.has(refresh_rate_hz):
		refresh_rate_hz = 0
	if not allow_window_controls:
		display_mode = MODE_BORDERLESS
		monitor_index = 0
		refresh_rate_hz = 0
		var monitor_size: Vector2i = _monitor_size_for(0)
		if monitor_size != Vector2i.ZERO:
			nearest_res = monitor_size

	out["display_mode"] = display_mode
	out["monitor_index"] = monitor_index
	out["resolution_width"] = nearest_res.x
	out["resolution_height"] = nearest_res.y
	out["refresh_rate_hz"] = refresh_rate_hz
	out["vsync_mode"] = vsync_mode
	out["fps_cap"] = fps_cap
	return out


static func current_runtime_settings() -> Dictionary:
	if is_headless():
		return default_settings()
	var monitor_index: int = 0
	if DisplayServer.has_method("window_get_current_screen"):
		monitor_index = max(0, int(DisplayServer.window_get_current_screen()))
	var mode: String = _display_mode_from_runtime()
	var size: Vector2i = DisplayServer.window_get_size()
	var refresh_rate: int = 0
	var rates: PackedInt32Array = list_refresh_rates(monitor_index)
	if rates.size() > 1:
		refresh_rate = rates[1]
	var vsync_mode: String = _vsync_id_from_enum(int(DisplayServer.window_get_vsync_mode()))
	var fps_cap: int = max(0, int(Engine.max_fps))
	return sanitize({
		"display_mode": mode,
		"monitor_index": monitor_index,
		"resolution_width": size.x,
		"resolution_height": size.y,
		"refresh_rate_hz": refresh_rate,
		"vsync_mode": vsync_mode,
		"fps_cap": fps_cap,
	})


static func list_monitors() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if is_headless():
		out.append({
			"index": 0,
			"label": "Display 1",
			"size": Vector2i(1280, 720),
			"refresh_hz": 0,
		})
		return out
	var count: int = 1
	if DisplayServer.has_method("get_screen_count"):
		count = max(1, int(DisplayServer.get_screen_count()))
	for i in range(count):
		var size: Vector2i = _monitor_size_for(i)
		var hz: int = 0
		if DisplayServer.has_method("screen_get_refresh_rate"):
			hz = max(0, int(round(float(DisplayServer.screen_get_refresh_rate(i)))))
		out.append({
			"index": i,
			"label": "Display %d (%dx%d)" % [i + 1, size.x, size.y],
			"size": size,
			"refresh_hz": hz,
		})
	return out


static func list_resolutions(monitor_index: int) -> Array[Vector2i]:
	var valid_monitor: int = _sanitize_monitor_index(monitor_index)
	var native: Vector2i = _monitor_size_for(valid_monitor)
	var candidates: Array[Vector2i] = [
		Vector2i(1280, 720),
		Vector2i(1366, 768),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
		Vector2i(3840, 2160),
	]
	if native != Vector2i.ZERO:
		candidates.append(native)
	var out: Array[Vector2i] = []
	for res in candidates:
		if native != Vector2i.ZERO:
			if res.x > native.x or res.y > native.y:
				continue
		if res.x < 960 or res.y < 540:
			continue
		if not out.has(res):
			out.append(res)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var area_a: int = a.x * a.y
		var area_b: int = b.x * b.y
		if area_a == area_b:
			return a.x < b.x
		return area_a < area_b
	)
	if out.is_empty():
		out.append(native if native != Vector2i.ZERO else Vector2i(1280, 720))
	return out


static func list_refresh_rates(monitor_index: int) -> PackedInt32Array:
	var out := PackedInt32Array([0])
	var valid_monitor: int = _sanitize_monitor_index(monitor_index)
	if is_headless():
		return out
	if DisplayServer.has_method("screen_get_refresh_rate"):
		var hz: int = max(0, int(round(float(DisplayServer.screen_get_refresh_rate(valid_monitor)))))
		if hz > 0 and not out.has(hz):
			out.append(hz)
	return out


static func apply(settings: Dictionary) -> Dictionary:
	var sanitized: Dictionary = sanitize(settings)
	if is_headless():
		return {"ok": true, "code": "headless_noop", "applied": sanitized}

	var code: String = "applied"
	if supports_desktop_window_controls():
		var monitor_index: int = int(sanitized.get("monitor_index", 0))
		if DisplayServer.has_method("window_set_current_screen"):
			DisplayServer.window_set_current_screen(monitor_index)

		var mode: String = str(sanitized.get("display_mode", MODE_WINDOWED))
		var size := Vector2i(
			int(sanitized.get("resolution_width", 1280)),
			int(sanitized.get("resolution_height", 720))
		)
		if mode == MODE_EXCLUSIVE:
			# Attempt to seed exclusive fullscreen with requested mode.
			DisplayServer.window_set_size(size)
		_apply_window_mode(mode)

		if mode == MODE_WINDOWED:
			DisplayServer.window_set_size(size)
		elif mode == MODE_BORDERLESS:
			# Borderless follows monitor native size.
			var native: Vector2i = _monitor_size_for(monitor_index)
			if native != Vector2i.ZERO:
				DisplayServer.window_set_size(native)
				sanitized["resolution_width"] = native.x
				sanitized["resolution_height"] = native.y
		elif mode == MODE_EXCLUSIVE:
			# Re-apply after mode switch for platforms honoring it.
			DisplayServer.window_set_size(size)
	else:
		code = "limited_apply_non_desktop"
		sanitized["monitor_index"] = 0
		sanitized["display_mode"] = MODE_BORDERLESS
		sanitized["refresh_rate_hz"] = 0
		var native_size: Vector2i = _monitor_size_for(0)
		if native_size != Vector2i.ZERO:
			sanitized["resolution_width"] = native_size.x
			sanitized["resolution_height"] = native_size.y

	DisplayServer.window_set_vsync_mode(_vsync_enum_from_id(str(sanitized.get("vsync_mode", VSYNC_ENABLED))))
	Engine.max_fps = int(sanitized.get("fps_cap", 0))
	return {"ok": true, "code": code, "applied": sanitized}


static func apply_safe(settings: Dictionary) -> Dictionary:
	var sanitized: Dictionary = sanitize(settings)
	if is_headless():
		return {"ok": true, "code": "headless_noop", "applied": sanitized}

	var safe: Dictionary = sanitized.duplicate(true)
	safe["display_mode"] = safe_mode_for_platform(str(safe.get("display_mode", MODE_WINDOWED)))

	var result: Dictionary = apply(safe)
	if not bool(result.get("ok", false)):
		return result

	if supports_desktop_window_controls() and str(safe.get("display_mode", MODE_WINDOWED)) == MODE_EXCLUSIVE:
		var runtime_mode: String = str(current_runtime_settings().get("display_mode", MODE_WINDOWED))
		if runtime_mode != MODE_EXCLUSIVE:
			safe["display_mode"] = MODE_BORDERLESS
			result = apply(safe)
			result["code"] = "exclusive_fallback_borderless"
			result["applied"] = safe
			return result
	return result


static func safe_mode_for_platform(requested_mode: String, platform_name: String = "") -> String:
	var mode: String = requested_mode.to_lower()
	if not PackedStringArray([MODE_WINDOWED, MODE_BORDERLESS, MODE_EXCLUSIVE]).has(mode):
		mode = MODE_WINDOWED
	var platform: String = platform_name if platform_name != "" else OS.get_name()
	if mode == MODE_EXCLUSIVE and not supports_desktop_window_controls_for_platform(platform):
		return MODE_BORDERLESS
	return mode


static func _sanitize_monitor_index(index: int) -> int:
	var monitor_count: int = max(1, list_monitors().size())
	return clampi(index, 0, monitor_count - 1)


static func _monitor_size_for(monitor_index: int) -> Vector2i:
	if is_headless():
		return Vector2i(1280, 720)
	var valid_monitor: int = max(0, monitor_index)
	if DisplayServer.has_method("screen_get_size"):
		var size: Vector2i = DisplayServer.screen_get_size(valid_monitor)
		if size != Vector2i.ZERO:
			return size
	var current: Vector2i = DisplayServer.window_get_size()
	return current if current != Vector2i.ZERO else Vector2i(1280, 720)


static func _nearest_resolution(requested: Vector2i, candidates: Array[Vector2i]) -> Vector2i:
	if candidates.is_empty():
		return Vector2i.ZERO
	var nearest: Vector2i = candidates[0]
	var nearest_score: int = abs(nearest.x - requested.x) + abs(nearest.y - requested.y)
	for res in candidates:
		var score: int = abs(res.x - requested.x) + abs(res.y - requested.y)
		if score < nearest_score:
			nearest = res
			nearest_score = score
	return nearest


static func _sanitize_fps_cap(raw_fps: int) -> int:
	if raw_fps <= 0:
		return 0
	if DEFAULT_FPS_CAPS.has(raw_fps):
		return raw_fps
	var nearest: int = 60 if DEFAULT_FPS_CAPS.size() > 1 else 0
	var best_delta: int = abs(nearest - raw_fps)
	for cap in DEFAULT_FPS_CAPS:
		if cap == 0:
			continue
		var delta: int = abs(cap - raw_fps)
		if delta < best_delta:
			best_delta = delta
			nearest = cap
	return nearest


static func _display_mode_from_runtime() -> String:
	var mode: int = int(DisplayServer.window_get_mode())
	var borderless: bool = false
	if DisplayServer.has_method("window_get_flag"):
		borderless = bool(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS))
	match mode:
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			return MODE_EXCLUSIVE
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			return MODE_BORDERLESS
		DisplayServer.WINDOW_MODE_WINDOWED:
			return MODE_BORDERLESS if borderless else MODE_WINDOWED
		_:
			return MODE_WINDOWED


static func _apply_window_mode(mode: String) -> void:
	match mode:
		MODE_BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		MODE_EXCLUSIVE:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)


static func _vsync_id_from_enum(mode: int) -> String:
	match mode:
		DisplayServer.VSYNC_DISABLED:
			return VSYNC_DISABLED
		DisplayServer.VSYNC_ADAPTIVE:
			return VSYNC_ADAPTIVE
		DisplayServer.VSYNC_MAILBOX:
			return VSYNC_MAILBOX
		_:
			return VSYNC_ENABLED


static func _vsync_enum_from_id(mode: String) -> int:
	match mode:
		VSYNC_DISABLED:
			return DisplayServer.VSYNC_DISABLED
		VSYNC_ADAPTIVE:
			return DisplayServer.VSYNC_ADAPTIVE
		VSYNC_MAILBOX:
			return DisplayServer.VSYNC_MAILBOX
		_:
			return DisplayServer.VSYNC_ENABLED
