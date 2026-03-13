@tool
extends EditorPlugin

func _enter_tree() -> void:
	if not Engine.has_singleton("Steam"):
		print("[Imported/cruelty/godotsteam] Steam singleton missing. Plugin idle.")
		return
	print("[Imported/cruelty/godotsteam] Ready (optional).")

