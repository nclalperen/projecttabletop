extends RefCounted


func run() -> bool:
	return _test_game_table_anchor_contract()


func _test_game_table_anchor_contract() -> bool:
	var scene: PackedScene = load("res://ui/GameTable.tscn")
	if scene == null:
		push_error("Failed to load ui/GameTable.tscn")
		return false

	var root = scene.instantiate()
	if root == null:
		push_error("Failed to instantiate ui/GameTable.tscn")
		return false

	var table_area = root.get_node_or_null("TableArea")
	var rack_panel = root.get_node_or_null("RackPanel")
	var action_bar = root.get_node_or_null("ActionBar")
	if table_area == null or rack_panel == null or action_bar == null:
		push_error("Missing expected layout nodes in GameTable scene")
		root.queue_free()
		return false

	if table_area.anchor_right != 1.0:
		push_error("TableArea must be full-width anchored")
		root.queue_free()
		return false
	if action_bar.anchor_right != 1.0:
		push_error("ActionBar must be full-width anchored")
		root.queue_free()
		return false

	root.queue_free()
	return true
