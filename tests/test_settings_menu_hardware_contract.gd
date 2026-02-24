extends RefCounted

const SETTINGS_SCENE_PATH: String = "res://ui/SettingsMenu.tscn"
const DISPLAY_SETTINGS_SCRIPT: Script = preload("res://ui/services/DisplaySettingsService.gd")
const REQUIRED_COMMON_PATHS: PackedStringArray = [
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/ShadowQuality/Value",
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayPresentationMode/Value",
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayVSync/Value",
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayFpsCap/Value",
]
const REQUIRED_DESKTOP_PATHS: PackedStringArray = [
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayMonitor/Value",
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayMode/Value",
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayResolution/Value",
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayRefreshRate/Value",
]


func run() -> bool:
	var packed: PackedScene = load(SETTINGS_SCENE_PATH)
	if packed == null:
		push_error("Failed to load SettingsMenu scene")
		return false

	var root: Node = packed.instantiate()
	if root == null:
		push_error("Failed to instantiate SettingsMenu scene")
		return false

	root.set("settings_list", root.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList"))
	root.set("_ui_settings", {})
	if root.has_method("_ensure_visual_rows"):
		root.call("_ensure_visual_rows")
	if root.has_method("_ensure_display_rows"):
		root.call("_ensure_display_rows")

	for path in REQUIRED_COMMON_PATHS:
		if root.get_node_or_null(path) == null:
			push_error("SettingsMenu missing expected hardware control path: %s" % path)
			root.free()
			return false

	var supports_window_controls: bool = DISPLAY_SETTINGS_SCRIPT.supports_desktop_window_controls()
	if supports_window_controls:
		for path in REQUIRED_DESKTOP_PATHS:
			if root.get_node_or_null(path) == null:
				push_error("SettingsMenu missing desktop display control path: %s" % path)
				root.free()
				return false
		var mode_opt: OptionButton = root.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayMode/Value")
		var res_opt: OptionButton = root.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayResolution/Value")
		var refresh_opt: OptionButton = root.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayRefreshRate/Value")
		root.call("_select_option_by_id", mode_opt, DISPLAY_SETTINGS_SCRIPT.MODE_BORDERLESS)
		root.call("_refresh_display_control_enabled_state")
		if not res_opt.disabled or not refresh_opt.disabled:
			push_error("Display resolution/refresh should be disabled in borderless mode")
			root.free()
			return false
		root.call("_select_option_by_id", mode_opt, DISPLAY_SETTINGS_SCRIPT.MODE_WINDOWED)
		root.call("_refresh_display_control_enabled_state")
		if res_opt.disabled or refresh_opt.disabled:
			push_error("Display resolution/refresh should be enabled in windowed mode")
			root.free()
			return false
	else:
		var mode_opt_nd: OptionButton = root.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayMode/Value")
		var res_opt_nd: OptionButton = root.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayResolution/Value")
		var refresh_opt_nd: OptionButton = root.get_node("Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayRefreshRate/Value")
		root.call("_refresh_display_control_enabled_state")
		if not mode_opt_nd.disabled or not res_opt_nd.disabled or not refresh_opt_nd.disabled:
			push_error("Display mode/resolution/refresh should be disabled when desktop window controls are unsupported")
			root.free()
			return false

	root.free()
	return true
