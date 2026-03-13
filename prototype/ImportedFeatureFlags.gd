extends Node

const CONFIG_PATH: String = "user://imported_feature_flags.cfg"
const CONFIG_SECTION: String = "flags"

const FEATURE_PROTOTYPE_TABLE: StringName = &"prototype_table_enabled"
const FEATURE_TABLETOP: StringName = &"tabletop_club"
const FEATURE_BUCKSHOT: StringName = &"buckshot"
const FEATURE_DOME: StringName = &"dome_keeper"
const FEATURE_HALLS: StringName = &"halls_torment"
const FEATURE_BROTATO: StringName = &"brotato"
const FEATURE_SLAY2: StringName = &"slay2"
const FEATURE_CRUELTY: StringName = &"cruelty_squad"

var _flags: Dictionary = {
	FEATURE_PROTOTYPE_TABLE: false,
	FEATURE_TABLETOP: true,
	FEATURE_BUCKSHOT: true,
	FEATURE_DOME: true,
	FEATURE_HALLS: true,
	FEATURE_BROTATO: true,
	FEATURE_SLAY2: true,
	FEATURE_CRUELTY: true,
}


func _ready() -> void:
	_load_from_disk()


func all_flags() -> Dictionary:
	return _flags.duplicate(true)


func is_enabled(feature: StringName) -> bool:
	return bool(_flags.get(feature, false))


func set_enabled(feature: StringName, value: bool) -> void:
	_flags[feature] = value
	_save_to_disk()


func is_prototype_table_enabled() -> bool:
	return is_enabled(FEATURE_PROTOTYPE_TABLE)


func set_prototype_table_enabled(enabled: bool) -> void:
	set_enabled(FEATURE_PROTOTYPE_TABLE, enabled)


func _load_from_disk() -> void:
	var cfg := ConfigFile.new()
	var err: int = cfg.load(CONFIG_PATH)
	if err != OK:
		_save_to_disk()
		return
	for key in _flags.keys():
		_flags[key] = bool(cfg.get_value(CONFIG_SECTION, String(key), _flags[key]))


func _save_to_disk() -> void:
	var cfg := ConfigFile.new()
	for key in _flags.keys():
		cfg.set_value(CONFIG_SECTION, String(key), bool(_flags[key]))
	cfg.save(CONFIG_PATH)

