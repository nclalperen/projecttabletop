extends SceneTree
## Unit test for VectorGameTable3D scene hierarchy, 3D fluid rack, and session binding.

const VectorGameTable3D = preload("res://ui/vector_table/VectorGameTable3D.gd")

func _init() -> void:
	var ok: bool = run()
	if ok:
		print("  PASS  test_vector_game_table_3d")
	else:
		print("  FAIL  test_vector_game_table_3d")
	quit(0 if ok else 1)


func run() -> bool:
	var ok: bool = true

	var table := VectorGameTable3D.new()
	root.add_child(table)
	table.configure_game(RuleConfig.new(), 1701, 4)

	if table._world == null or table._camera == null or table._rack == null or table._session == null:
		push_error("VectorGameTable3D core 3D subsystems not initialized")
		ok = false

	# Verify 3D rack received tiles
	var total_tiles: int = table._rack._row_tiles[0].size() + table._rack._row_tiles[1].size()
	if total_tiles < 14:
		push_error("3D fluid rack expected >=14 initial tiles, got %d" % total_tiles)
		ok = false

	table.queue_free()
	return ok
