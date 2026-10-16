extends SceneTree
## Unit test for FluidRack3D continuous 3D layout and partitioning.

const FluidRack3D = preload("res://ui/vector_table/rack/FluidRack3D.gd")

func _init() -> void:
	var ok: bool = run()
	if ok:
		print("  PASS  test_fluid_rack_3d")
	else:
		print("  FAIL  test_fluid_rack_3d")
	quit(0 if ok else 1)


func run() -> bool:
	var ok: bool = true

	var rack := FluidRack3D.new()
	rack._build_rack_mesh()

	if rack._rack_mesh == null:
		push_error("FluidRack3D mesh not built")
		ok = false

	var sample_hand: Array = []
	for i in range(21):
		sample_hand.append({
			"unique_id": 5000 + i,
			"number": (i % 13) + 1,
			"color": i % 4,
			"kind": 0
		})
	rack.set_tiles(sample_hand)

	if rack._row_tiles[0].size() != 15 or rack._row_tiles[1].size() != 6:
		push_error("Row partition mismatch in 3D rack")
		ok = false

	rack.clear_rack()
	if rack._row_tiles[0].size() != 0 or rack._row_tiles[1].size() != 0:
		push_error("Clear rack failed in 3D rack")
		ok = false

	rack.free()
	return ok
