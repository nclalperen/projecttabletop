extends RefCounted

const ROOTS: PackedStringArray = [
	"res://ui",
	"res://core",
	"res://net",
	"res://bots",
]
const FORBIDDEN_LITERALS: PackedStringArray = [
	"res://assets/",
	"res://Kenney_c0/",
]
const ALLOWLIST_PREFIXES: PackedStringArray = [
	"res://ui/backup/",
]


func run() -> bool:
	var files: Array[String] = []
	for root in ROOTS:
		_collect_gd_files(root, files)

	for file_path in files:
		if _is_allowlisted(file_path):
			continue
		var f := FileAccess.open(file_path, FileAccess.READ)
		if f == null:
			push_error("Failed to open script for literal guard: %s" % file_path)
			return false
		var text: String = f.get_as_text()
		f.close()
		for pattern in FORBIDDEN_LITERALS:
			if text.find(pattern) != -1:
				push_error("Forbidden asset literal '%s' found in %s" % [pattern, file_path])
				return false
	return true


func _collect_gd_files(root: String, out_files: Array[String]) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name == "":
			break
		if name == "." or name == "..":
			continue
		var full_path: String = "%s/%s" % [root, name]
		if dir.current_is_dir():
			_collect_gd_files(full_path, out_files)
		elif name.ends_with(".gd"):
			out_files.append(full_path)
	dir.list_dir_end()


func _is_allowlisted(path: String) -> bool:
	for prefix in ALLOWLIST_PREFIXES:
		if path.begins_with(prefix):
			return true
	return false
