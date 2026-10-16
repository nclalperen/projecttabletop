extends SceneTree
## Unit tests for VectorTableFelt2D table geometry and deck updates.

const VectorTableFelt2D = preload("res://ui/vector_table/table/VectorTableFelt2D.gd")

func _init() -> void:
	var ok: bool = run()
	if ok:
		print("  PASS  test_vector_felt_table")
	else:
		print("  FAIL  test_vector_felt_table")
	quit(0 if ok else 1)


func run() -> bool:
	var ok: bool = true

	var felt := VectorTableFelt2D.new()
	felt.size = Vector2(1920.0, 1080.0)
	felt._update_anchors()

	if felt.deck_pos == Vector2.ZERO or felt.indicator_pos == Vector2.ZERO:
		push_error("Felt anchors not initialized")
		ok = false

	if felt.discard_positions.size() != 4:
		push_error("Must have 4 discard anchors")
		ok = false

	# Update deck
	felt.update_deck(48, {"unique_id": 999, "number": 11, "color": 3, "kind": 0})
	if felt._deck_remaining != 48 or felt._indicator_tile == null:
		push_error("Deck or indicator not updated properly")
		ok = false

	# Update discard
	felt.update_discard(3, {"unique_id": 888, "number": 5, "color": 1, "kind": 0})
	if not felt._discard_tiles.has(3) or felt._discard_tiles[3] == null:
		push_error("Discard tile not registered for seat 3")
		ok = false

	felt.free()
	return ok
