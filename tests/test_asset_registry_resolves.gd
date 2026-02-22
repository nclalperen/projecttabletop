extends RefCounted

const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")

func run() -> bool:
	var ids: Array[StringName] = ASSET_REGISTRY.all_ids()
	if ids.is_empty():
		push_error("Asset registry returned no IDs")
		return false

	for id in ids:
		var path: String = ASSET_REGISTRY.path(id)
		if path == "":
			push_error("Asset ID has empty path: %s" % String(id))
			return false
		if not FileAccess.file_exists(path) and not ResourceLoader.exists(path):
			push_error("Asset path does not exist: %s -> %s" % [String(id), path])
			return false
		if not _type_loads(id, path):
			return false
	return true


func _type_loads(id: StringName, path: String) -> bool:
	var ext: String = path.get_extension().to_lower()
	if ext in ["png", "jpg", "jpeg", "webp", "hdr"]:
		var tex: Texture2D = ASSET_REGISTRY.texture(id)
		if tex == null:
			push_error("Texture load failed for %s (%s)" % [String(id), path])
			return false
		return true
	if ext in ["ogg", "wav"]:
		var stream: AudioStream = ASSET_REGISTRY.audio(id)
		if stream == null:
			push_error("Audio load failed for %s (%s)" % [String(id), path])
			return false
		return true
	if ext in ["ttf", "otf"]:
		var font: FontFile = ASSET_REGISTRY.font(id)
		if font == null:
			push_error("Font load failed for %s (%s)" % [String(id), path])
			return false
		return true
	var generic: Resource = load(path)
	if generic == null:
		push_error("Generic resource load failed for %s (%s)" % [String(id), path])
		return false
	return true
