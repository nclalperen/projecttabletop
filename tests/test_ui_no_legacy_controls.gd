extends RefCounted

const SCENE_PATH := "res://ui/GameTable.tscn"

func run() -> bool:
	return _test_game_table_has_no_legacy_bot_controls()


func _test_game_table_has_no_legacy_bot_controls() -> bool:
	var text := _read_scene_text(SCENE_PATH)
	if text == "":
		return false

	var forbidden_paths = [
		"Layout/ActionBar/RoundGroup/GroupContent/Row2/AutoBot",
		"Layout/ActionBar/RoundGroup/GroupContent/Row2/BotTurn",
		"Layout/ActionBar/RoundGroup/GroupContent/Row1/LegacyDiscard",
	]
	for p in forbidden_paths:
		if _scene_has_node_path(text, p):
			push_error("Legacy control still present in GameTable scene: %s" % p)
			return false
	return true


func _read_scene_text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Failed to open scene file: %s" % path)
		return ""
	var text := f.get_as_text()
	f.close()
	return text


func _scene_has_node_path(scene_text: String, node_path: String) -> bool:
	var parts := node_path.split("/")
	if parts.size() == 0:
		return false
	var node_name: String = parts[parts.size() - 1]
	var parent_path := "." if parts.size() == 1 else "/".join(parts.slice(0, parts.size() - 1))
	var search := '[node name="%s"' % node_name
	var cursor := 0
	while true:
		var idx := scene_text.find(search, cursor)
		if idx == -1:
			return false
		var line_end := scene_text.find("]", idx)
		if line_end == -1:
			return false
		var header := scene_text.substr(idx, line_end - idx + 1)
		if header.find('parent="%s"' % parent_path) != -1:
			return true
		cursor = line_end + 1
	return false
