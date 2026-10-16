extends SceneTree
## Unit test for VectorGameTable scene initialization and OkeySession binding.

const VectorGameTable = preload("res://ui/vector_table/VectorGameTable.gd")

func _init() -> void:
	var ok: bool = run()
	if ok:
		print("  PASS  test_vector_game_table")
	else:
		print("  FAIL  test_vector_game_table")
	quit(0 if ok else 1)


func run() -> bool:
	var ok: bool = true

	var table := VectorGameTable.new()
	table.size = Vector2(1920.0, 1080.0)
	root.add_child(table)
	table.configure_game(RuleConfig.new(), 1701, 4)

	if table._felt == null or table._rack == null or table._session == null:
		push_error("VectorGameTable core subsystems not initialized")
		ok = false

	# Verify rack received tiles from OkeySession
	var rack_tile_count: int = table._rack._row_tiles[0].size() + table._rack._row_tiles[1].size()
	if rack_tile_count < 14:
		push_error("Vector rack expected >=14 initial tiles, got %d" % rack_tile_count)
		ok = false

	table.queue_free()
	return ok
