extends "res://prototype/imported/brotato/save/ProgressDataLoaderV2.gd"

class_name ImportedProgressDataLoaderV3

const MAX_BACKUP_FILES: int = 5

var profile_id: int = 0
var backup_dir: String = "user://"


func _init(save_path_value: String = "", run_path_value: String = "", profile: int = 0, backup_root: String = "user://") -> void:
	save_path = save_path_value
	run_save_path = run_path_value
	profile_id = profile
	backup_dir = backup_root


func load_game_file() -> void:
	super.load_game_file()
	if load_status == "save_ok":
		return
	_load_from_backups()


func save() -> int:
	var err: int = super.save()
	if err != OK:
		return err
	_write_backup(save_path, "save_v3_%d" % profile_id)
	if run_save_path.strip_edges() != "":
		_write_backup(run_save_path, "run_v3_%d" % profile_id)
	return OK


func _load_from_backups() -> void:
	var best_path: String = ""
	var best_mtime: int = -1
	var dir := DirAccess.open(backup_dir)
	if dir == null:
		return
	var files: PackedStringArray = dir.get_files()
	for file_name in files:
		if not file_name.begins_with("save_v3_%d_backup_" % profile_id):
			continue
		var full_path: String = backup_dir.path_join(file_name)
		var mtime: int = FileAccess.get_modified_time(full_path)
		if mtime > best_mtime:
			best_mtime = mtime
			best_path = full_path
	if best_path == "":
		return
	var txt: String = FileAccess.get_file_as_string(best_path)
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		data = parsed
		load_status = "save_ok"


func _write_backup(source_path: String, basename: String) -> void:
	if source_path.strip_edges() == "" or not FileAccess.file_exists(source_path):
		return
	var txt: String = FileAccess.get_file_as_string(source_path)
	var ts: int = Time.get_unix_time_from_system()
	var out_path: String = backup_dir.path_join("%s_backup_%d.json" % [basename, ts])
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(txt)
	_trim_old_backups(basename)


func _trim_old_backups(basename: String) -> void:
	var dir := DirAccess.open(backup_dir)
	if dir == null:
		return
	var pairs: Array[Dictionary] = []
	for file_name in dir.get_files():
		if not file_name.begins_with("%s_backup_" % basename):
			continue
		var full_path: String = backup_dir.path_join(file_name)
		pairs.append({"path": full_path, "mtime": FileAccess.get_modified_time(full_path)})
	pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("mtime", 0)) > int(b.get("mtime", 0))
	)
	for i in range(MAX_BACKUP_FILES, pairs.size()):
		DirAccess.remove_absolute(String(pairs[i].get("path", "")))

