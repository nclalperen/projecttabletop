extends Node

const FLAGS_SCRIPT: Script = preload("res://prototype/ImportedFeatureFlags.gd")

const MODULE_TABLETOP: StringName = &"tabletop_club"
const MODULE_BUCKSHOT: StringName = &"buckshot"
const MODULE_DOME: StringName = &"dome_keeper"
const MODULE_HALLS: StringName = &"halls_torment"
const MODULE_BROTATO: StringName = &"brotato"
const MODULE_SLAY2: StringName = &"slay2"
const MODULE_CRUELTY: StringName = &"cruelty_squad"

var _singleton_requirements: Dictionary = {
	MODULE_TABLETOP: [],
	MODULE_BUCKSHOT: [],
	MODULE_DOME: [],
	MODULE_HALLS: [],
	MODULE_BROTATO: [],
	MODULE_SLAY2: ["IEOS"],
	MODULE_CRUELTY: [],
}
var _plugin_requirements: Dictionary = {
	MODULE_SLAY2: [
		"res://prototype/imported/slay2/addons/fmod/plugin.cfg",
		"res://prototype/imported/slay2/addons/dev_tools/plugin.cfg",
	],
	MODULE_CRUELTY: [
		"res://prototype/imported/cruelty_squad/addons/qodot/plugin.cfg",
		"res://prototype/imported/cruelty_squad/addons/decals/plugin.cfg",
	],
}

var _feature_flags: Node = null


func _ready() -> void:
	_feature_flags = get_node_or_null("/root/ImportedFeatureFlags")


func is_module_available(module_id: StringName) -> bool:
	if not _is_flag_enabled(module_id):
		return false
	if not _are_plugins_present(module_id):
		return false
	var reqs: Array = _singleton_requirements.get(module_id, [])
	for singleton_name in reqs:
		if not Engine.has_singleton(String(singleton_name)):
			return false
	return true


func availability_reason(module_id: StringName) -> String:
	if not _is_flag_enabled(module_id):
		return "disabled_by_flag"
	var missing_plugin_path: String = _first_missing_plugin(module_id)
	if missing_plugin_path != "":
		return "missing_plugin:%s" % missing_plugin_path
	var reqs: Array = _singleton_requirements.get(module_id, [])
	for singleton_name in reqs:
		if not Engine.has_singleton(String(singleton_name)):
			return "missing_singleton:%s" % String(singleton_name)
	return "ok"


func all_module_status() -> Dictionary:
	return {
		MODULE_TABLETOP: {"available": is_module_available(MODULE_TABLETOP), "reason": availability_reason(MODULE_TABLETOP)},
		MODULE_BUCKSHOT: {"available": is_module_available(MODULE_BUCKSHOT), "reason": availability_reason(MODULE_BUCKSHOT)},
		MODULE_DOME: {"available": is_module_available(MODULE_DOME), "reason": availability_reason(MODULE_DOME)},
		MODULE_HALLS: {"available": is_module_available(MODULE_HALLS), "reason": availability_reason(MODULE_HALLS)},
		MODULE_BROTATO: {"available": is_module_available(MODULE_BROTATO), "reason": availability_reason(MODULE_BROTATO)},
		MODULE_SLAY2: {"available": is_module_available(MODULE_SLAY2), "reason": availability_reason(MODULE_SLAY2)},
		MODULE_CRUELTY: {"available": is_module_available(MODULE_CRUELTY), "reason": availability_reason(MODULE_CRUELTY)},
	}


func _is_flag_enabled(module_id: StringName) -> bool:
	if _feature_flags == null:
		_feature_flags = get_node_or_null("/root/ImportedFeatureFlags")
	if _feature_flags != null and _feature_flags.has_method("is_enabled"):
		return bool(_feature_flags.call("is_enabled", module_id))
	var defaults: Node = FLAGS_SCRIPT.new()
	if defaults != null and defaults.has_method("is_enabled"):
		return bool(defaults.call("is_enabled", module_id))
	return false


func _are_plugins_present(module_id: StringName) -> bool:
	var required_plugins: Array = _plugin_requirements.get(module_id, [])
	for plugin_path in required_plugins:
		if not FileAccess.file_exists(String(plugin_path)):
			return false
	return true


func _first_missing_plugin(module_id: StringName) -> String:
	var required_plugins: Array = _plugin_requirements.get(module_id, [])
	for plugin_path in required_plugins:
		var normalized_path: String = String(plugin_path)
		if not FileAccess.file_exists(normalized_path):
			return normalized_path
	return ""
