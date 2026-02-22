extends RefCounted
class_name AssetLoader

static var _texture_cache: Dictionary = {}
static var _audio_cache: Dictionary = {}
static var _font_cache: Dictionary = {}
static var _path_cache: Dictionary = {}


static func load_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	if tex == null and FileAccess.file_exists(path):
		var image: Image = Image.load_from_file(path)
		if image != null and not image.is_empty():
			tex = ImageTexture.create_from_image(image)
	if tex != null:
		_texture_cache[path] = tex
	return tex


static func load_audio(path: String) -> AudioStream:
	if path == "":
		return null
	if _audio_cache.has(path):
		return _audio_cache[path] as AudioStream
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	if stream == null and FileAccess.file_exists(path):
		var lowered: String = path.to_lower()
		if lowered.ends_with(".ogg"):
			stream = AudioStreamOggVorbis.load_from_file(path)
		elif lowered.ends_with(".wav"):
			stream = AudioStreamWAV.load_from_file(path)
	if stream != null:
		_audio_cache[path] = stream
	return stream


static func load_font(path: String) -> FontFile:
	if path == "":
		return null
	if _font_cache.has(path):
		return _font_cache[path] as FontFile
	var font: FontFile = null
	if ResourceLoader.exists(path):
		font = load(path) as FontFile
	if font == null and FileAccess.file_exists(path):
		font = FontFile.new()
		var err: int = font.load_dynamic_font(path)
		if err != OK:
			font = null
	if font != null:
		_font_cache[path] = font
	return font


static func has_path(path: String) -> bool:
	if path == "":
		return false
	if _path_cache.has(path):
		return bool(_path_cache[path])
	var exists: bool = FileAccess.file_exists(path) or ResourceLoader.exists(path)
	_path_cache[path] = exists
	return exists


static func clear_cache() -> void:
	_texture_cache.clear()
	_audio_cache.clear()
	_font_cache.clear()
	_path_cache.clear()
