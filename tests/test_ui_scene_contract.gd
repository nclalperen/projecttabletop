extends RefCounted

const SCENE_PATH := "res://ui/GameTable.tscn"
const REQUIRED_NODES := ["TableArea", "RackPanel", "ActionBar"]


func run() -> bool:
	return _test_game_table_anchor_contract()


func _test_game_table_anchor_contract() -> bool:
	var text := _read_scene_text(SCENE_PATH)
	if text == "":
		return false

	for node_name in REQUIRED_NODES:
		if text.find('[node name="%s"' % node_name) == -1:
			push_error("Missing expected layout node in GameTable scene: %s" % node_name)
			return false
	var table_area_block := _extract_node_block(text, "TableArea")
	if table_area_block == "":
		push_error("Missing TableArea node block in GameTable scene")
		return false
	if table_area_block.find("anchor_right = 1.0") == -1:
		push_error("TableArea must be full-width anchored")
		return false
	var action_bar_block := _extract_node_block(text, "ActionBar")
	if action_bar_block == "":
		push_error("Missing ActionBar node block in GameTable scene")
		return false
	if action_bar_block.find("anchor_right = 1.0") == -1:
		push_error("ActionBar must be full-width anchored")
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


func _extract_node_block(scene_text: String, node_name: String) -> String:
	var marker := '[node name="%s"' % node_name
	var start := scene_text.find(marker)
	if start == -1:
		return ""
	var next := scene_text.find("\n[node ", start + marker.length())
	if next == -1:
		next = scene_text.length()
	return scene_text.substr(start, next - start)
