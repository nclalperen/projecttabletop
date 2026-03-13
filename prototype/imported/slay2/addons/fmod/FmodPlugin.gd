@tool
extends EditorPlugin

# SDK-dependent import from Slay the Spire 2. This plugin is optional and guarded.

var _active: bool = false


func _enter_tree() -> void:
	_active = Engine.has_singleton("IEOS") or Engine.has_singleton("EOS")
	if not _active:
		print("[Imported/slay2/fmod] Optional SDK unavailable. Plugin idle.")


func _exit_tree() -> void:
	_active = false

