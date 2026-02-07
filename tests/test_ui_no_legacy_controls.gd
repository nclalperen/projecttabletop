extends RefCounted


func run() -> bool:
	return _test_game_table_has_no_legacy_bot_controls()


func _test_game_table_has_no_legacy_bot_controls() -> bool:
	var scene: PackedScene = load("res://ui/GameTable.tscn")
	if scene == null:
		push_error("Failed to load ui/GameTable.tscn")
		return false
	var root = scene.instantiate()
	if root == null:
		push_error("Failed to instantiate ui/GameTable.tscn")
		return false

	var forbidden_paths = [
		"Layout/ActionBar/RoundGroup/GroupContent/Row2/AutoBot",
		"Layout/ActionBar/RoundGroup/GroupContent/Row2/BotTurn",
		"Layout/ActionBar/RoundGroup/GroupContent/Row1/LegacyDiscard",
	]
	for p in forbidden_paths:
		if root.get_node_or_null(p) != null:
			push_error("Legacy control still present in GameTable scene: %s" % p)
			root.queue_free()
			return false

	root.queue_free()
	return true
