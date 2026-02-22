extends RefCounted
class_name AssetRegistry

const CATALOG: Script = preload("res://gd/assets/AssetCatalog.gd")
const LOADER: Script = preload("res://gd/assets/AssetLoader.gd")


static func texture(id: StringName) -> Texture2D:
	var p: String = path(id)
	if p == "":
		return null
	return LOADER.load_texture(p)


static func audio(id: StringName) -> AudioStream:
	var p: String = path(id)
	if p == "":
		return null
	return LOADER.load_audio(p)


static func font(id: StringName) -> FontFile:
	var p: String = path(id)
	if p == "":
		return null
	return LOADER.load_font(p)


static func path(id: StringName) -> String:
	return CATALOG.path_for(id)


static func has(id: StringName) -> bool:
	if not CATALOG.has_id(id):
		return false
	var p: String = CATALOG.path_for(id)
	return LOADER.has_path(p)


static func clear_cache() -> void:
	LOADER.clear_cache()


static func all_ids() -> Array[StringName]:
	return CATALOG.all_ids()
