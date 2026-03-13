extends RefCounted

class_name ImportedProgressDataLoaderV1

var save_path: String = ""
var load_status: String = "save_missing"
var data: Dictionary = {}


func _init(path: String = "") -> void:
	save_path = path


func load_game_file() -> void:
	if save_path.strip_edges() == "" or not FileAccess.file_exists(save_path):
		load_status = "save_missing"
		return
	var txt: String = FileAccess.get_file_as_string(save_path)
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		load_status = "corrupted_save"
		return
	data = parsed
	load_status = "save_ok"


func save() -> int:
	if save_path.strip_edges() == "":
		return ERR_INVALID_PARAMETER
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		return ERR_CANT_OPEN
	f.store_string(JSON.stringify(data))
	load_status = "save_ok"
	return OK

