extends SceneTree
## Unit tests for VectorTile2D procedural rendering and input properties.

const VectorTile2D = preload("res://ui/vector_table/render/VectorTile2D.gd")

func _init() -> void:
	var ok: bool = run()
	if ok:
		print("  PASS  test_vector_tile")
	else:
		print("  FAIL  test_vector_tile")
	quit(0 if ok else 1)


func run() -> bool:
	var ok: bool = true

	var tile := VectorTile2D.new()
	if tile.size.x <= 0 or tile.size.y <= 0:
		push_error("VectorTile2D must have positive dimensions")
		ok = false

	# Setup tile data
	tile.setup_tile(101, 7, 0, false, true)
	if tile.unique_id != 101 or tile.number != 7 or tile.color_index != 0:
		push_error("VectorTile2D data mismatch after setup_tile")
		ok = false

	# Setup fake okey
	tile.setup_tile(102, 0, 1, true, true)
	if not tile.is_fake_okey:
		push_error("VectorTile2D fake okey flag not set")
		ok = false

	# Elevation clamping
	tile.set_elevation(2.5)
	if tile.target_elevation != 1.0:
		push_error("Elevation must clamp to 1.0")
		ok = false

	tile.set_elevation(-0.5)
	if tile.target_elevation != 0.0:
		push_error("Elevation must clamp to 0.0")
		ok = false

	# Target position setting
	var target := Vector2(250.0, 140.0)
	tile.set_target_position(target, true)
	if not tile.position.is_equal_approx(target) or not tile.spring_pos.is_equal_approx(target):
		push_error("Snap immediate must instantly set position and spring_pos")
		ok = false

	tile.free()
	return ok
