extends RefCounted
class_name ImportedPieceCache

var _entry_path: String = ""
var _is_thumbnail: bool = false


func _init(entry_path: String, thumbnail: bool = false) -> void:
	_entry_path = entry_path
	_is_thumbnail = thumbnail


func cache(piece_scene: PackedScene) -> int:
	if piece_scene == null:
		return ERR_INVALID_PARAMETER
	return ResourceSaver.save(piece_scene, _cache_path() + "." + _scene_ext())


func exists() -> bool:
	return FileAccess.file_exists(_cache_path() + "." + _scene_ext())


func get_scene() -> Node3D:
	if not exists():
		return null
	var res: PackedScene = load(_cache_path() + "." + _scene_ext())
	if res == null:
		return null
	var inst = res.instantiate()
	return inst if inst is Node3D else null


static func should_cache(piece_entry: Dictionary) -> bool:
	return bool(piece_entry.get("cacheable", false))


func _cache_path() -> String:
	var ext := "tmb_cache" if _is_thumbnail else "cache"
	var safe_name: String = _entry_path.replace("/", "_").replace(":", "_")
	return "user://assets/%s.%s" % [safe_name, ext]


func _scene_ext() -> String:
	return "tscn"

