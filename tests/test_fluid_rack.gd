extends SceneTree
## Unit tests for FluidRack2D continuous layout and push-aside kinematics.

const FluidRack2D = preload("res://ui/vector_table/rack/FluidRack2D.gd")

func _init() -> void:
	var ok: bool = run()
	if ok:
		print("  PASS  test_fluid_rack")
	else:
		print("  FAIL  test_fluid_rack")
	quit(0 if ok else 1)


func run() -> bool:
	var ok: bool = true

	var rack := FluidRack2D.new()
	if rack.size.x != FluidRack2D.RACK_WIDTH or rack.size.y != FluidRack2D.RACK_HEIGHT:
		push_error("FluidRack2D dimension mismatch")
		ok = false

	# Populate with sample tiles
	var sample_hand: Array = []
	for i in range(21):
		sample_hand.append({
			"unique_id": 9000 + i,
			"number": (i % 13) + 1,
			"color": i % 4,
			"kind": 0
		})
	rack.set_tiles(sample_hand)

	var row0_count: int = rack._row_tiles[0].size()
	var row1_count: int = rack._row_tiles[1].size()
	if row0_count != 15 or row1_count != 6:
		push_error("Row partition mismatch: expected 15 and 6, got %d and %d" % [row0_count, row1_count])
		ok = false

	# Test clear
	rack.clear_rack()
	if rack._row_tiles[0].size() != 0 or rack._row_tiles[1].size() != 0:
		push_error("Rack not cleared properly")
		ok = false

	rack.free()
	return ok
