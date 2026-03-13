extends "res://prototype/imported/brotato/save/ProgressDataLoaderV1.gd"

class_name ImportedProgressDataLoaderV2

var run_state: Dictionary = {}
var run_save_path: String = ""


func _init(save_path_value: String = "", run_path_value: String = "") -> void:
	save_path = save_path_value
	run_save_path = run_path_value


func load_game_file() -> void:
	super.load_game_file()
	if run_save_path.strip_edges() == "" or not FileAccess.file_exists(run_save_path):
		return
	var txt: String = FileAccess.get_file_as_string(run_save_path)
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		run_state = parsed


func save() -> int:
	var base_err: int = super.save()
	if base_err != OK:
		return base_err
	if run_save_path.strip_edges() == "":
		return OK
	var f := FileAccess.open(run_save_path, FileAccess.WRITE)
	if f == null:
		return ERR_CANT_OPEN
	f.store_string(JSON.stringify(run_state))
	return OK

