extends RefCounted
class_name KenneyAssetLoader

const ASSET_LOADER: Script = preload("res://gd/assets/AssetLoader.gd")
const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")

static func texture(path: String) -> Texture2D:
	return ASSET_LOADER.load_texture(path)


static func font(path: String) -> FontFile:
	return ASSET_LOADER.load_font(path)


static func audio(path: String) -> AudioStream:
	return ASSET_LOADER.load_audio(path)


static func texture_id(id: StringName) -> Texture2D:
	return ASSET_REGISTRY.texture(id)


static func font_id(id: StringName) -> FontFile:
	return ASSET_REGISTRY.font(id)


static func audio_id(id: StringName) -> AudioStream:
	return ASSET_REGISTRY.audio(id)
