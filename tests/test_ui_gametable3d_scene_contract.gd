extends RefCounted


func run() -> bool:
	var scene: PackedScene = load("res://ui/GameTable3D.tscn")
	if scene == null:
		push_error("Failed to load ui/GameTable3D.tscn")
		return false

	var root = scene.instantiate()
	if root == null:
		push_error("Failed to instantiate ui/GameTable3D.tscn")
		return false

	var required_nodes: PackedStringArray = [
		"World",
		"World/Camera3D",
		"World/TableBody",
		"World/TableSurface",
		"GameViewport",
	]
	for p in required_nodes:
		if root.get_node_or_null(p) == null:
			push_error("GameTable3D missing required node: %s" % p)
			root.free()
			return false

	root.free()
	return true
