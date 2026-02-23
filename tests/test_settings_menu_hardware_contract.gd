extends RefCounted

const SETTINGS_SCENE_PATH: String = "res://ui/SettingsMenu.tscn"
const REQUIRED_PATHS: PackedStringArray = [
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/ShadowQuality/Value",
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayMonitor/Value",
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayMode/Value",
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayResolution/Value",
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayRefreshRate/Value",
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayVSync/Value",
	"Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/DisplayFpsCap/Value",
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

	for path in REQUIRED_PATHS:
		if root.get_node_or_null(path) == null:
			push_error("SettingsMenu missing expected hardware control path: %s" % path)
			root.free()
			return false

	root.free()
	return true
