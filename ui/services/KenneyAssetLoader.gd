extends RefCounted
class_name KenneyAssetLoader

static var _texture_cache: Dictionary = {}
static var _font_cache: Dictionary = {}

static func texture(path: String) -> Texture2D:
	if path == "":
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	if not FileAccess.file_exists(path):
		return null
	var image: Image = Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	var tex: Texture2D = ImageTexture.create_from_image(image)
	_texture_cache[path] = tex
	return tex


static func font(path: String) -> FontFile:
	if path == "":
		return null
	if _font_cache.has(path):
		return _font_cache[path] as FontFile
	if not FileAccess.file_exists(path):
		return null
	var font_file := FontFile.new()
	var err: int = font_file.load_dynamic_font(path)
	if err != OK:
		return null
	_font_cache[path] = font_file
	return font_file
