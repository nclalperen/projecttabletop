extends RefCounted
class_name PlayerProfile

const SAVE_PATH: String = "user://player_profile.cfg"
const SECTION: String = "profile"

static var display_name: String = "Player"
static var avatar_index: int = 0
static var hdri_id: StringName = &""
static var table_wood_set: String = ""
static var felt_set: String = ""

static var _loaded: bool = false


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	display_name = str(cfg.get_value(SECTION, "display_name", display_name))
	avatar_index = int(cfg.get_value(SECTION, "avatar_index", avatar_index))
	hdri_id = StringName(str(cfg.get_value(SECTION, "hdri_id", hdri_id)))
	table_wood_set = str(cfg.get_value(SECTION, "table_wood_set", table_wood_set))
	felt_set = str(cfg.get_value(SECTION, "felt_set", felt_set))


static func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "display_name", display_name)
	cfg.set_value(SECTION, "avatar_index", avatar_index)
	cfg.set_value(SECTION, "hdri_id", String(hdri_id))
	cfg.set_value(SECTION, "table_wood_set", table_wood_set)
	cfg.set_value(SECTION, "felt_set", felt_set)
	cfg.save(SAVE_PATH)
