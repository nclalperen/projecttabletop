extends RefCounted

const GDEXT_PATH := "res://addons/epic-online-services-godot/eosg.gdextension"
const EOS_ADDON_ROOT := "res://addons/epic-online-services-godot/"
const REQUIRED_WINDOWS_EDITOR_KEYS := [
	"windows.debug.editor.x86_64",
	"windows.release.editor.x86_64",
]


func run() -> bool:
	var file := FileAccess.open(GDEXT_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open EOS gdextension file: %s" % GDEXT_PATH)
		return false
	var text := file.get_as_text()
	file.close()

	var libraries := _parse_libraries(text)
	for key in REQUIRED_WINDOWS_EDITOR_KEYS:
		if not libraries.has(key):
			push_error("Missing required EOS library mapping key: %s" % key)
			return false
		var mapped_path: String = String(libraries[key]).strip_edges()
		if mapped_path == "":
			push_error("EOS editor mapping must not be empty: %s" % key)
			return false
		if not mapped_path.begins_with("bin/windows/") or not mapped_path.ends_with(".dll"):
			push_error("EOS editor mapping should resolve to a Windows DLL under bin/windows: %s -> %s" % [key, mapped_path])
			return false
		var full_path := EOS_ADDON_ROOT + mapped_path
		if not FileAccess.file_exists(full_path):
			push_error("EOS mapped library does not exist: %s -> %s" % [key, full_path])
			return false
	return true


func _parse_libraries(text: String) -> Dictionary:
	var out := {}
	var in_libraries := false
	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line == "" or line.begins_with(";") or line.begins_with("#"):
			continue
		if line.begins_with("[") and line.ends_with("]"):
			in_libraries = line == "[libraries]"
			continue
		if not in_libraries:
			continue
		var eq := line.find("=")
		if eq == -1:
			continue
		var key := line.substr(0, eq).strip_edges()
		var value := line.substr(eq + 1).strip_edges()
		if value.begins_with("\"") and value.ends_with("\"") and value.length() >= 2:
			value = value.substr(1, value.length() - 2)
		out[key] = value
	return out
