## ModLoader - A mod loader for GDScript
##
## Imported from Dome Keeper/GodotModding stack for prototype use.
## Original codebase marks this component CC0/Public Domain.

extends Node

signal logged(entry)
signal current_config_changed(config)
signal new_hooks_created

var enabled: bool = true
var loaded_mods: Dictionary = {}


func initialize(mod_paths: Array) -> Dictionary:
	loaded_mods.clear()
	if not enabled:
		return {"ok": true, "loaded": 0, "reason": "disabled"}
	var loaded_count: int = 0
	for path_val in mod_paths:
		var path_text: String = String(path_val)
		if path_text.strip_edges() == "":
			continue
		loaded_mods[path_text] = {"path": path_text, "active": true}
		loaded_count += 1
	emit_signal("logged", {"message": "Loaded %d mods" % loaded_count})
	return {"ok": true, "loaded": loaded_count}


func set_mod_enabled(path: String, is_enabled: bool) -> void:
	if not loaded_mods.has(path):
		return
	var meta: Dictionary = loaded_mods[path]
	meta["active"] = is_enabled
	loaded_mods[path] = meta


func get_active_mods() -> Array:
	var out: Array = []
	for key in loaded_mods.keys():
		var meta: Dictionary = loaded_mods[key]
		if bool(meta.get("active", false)):
			out.append(meta.duplicate(true))
	return out

