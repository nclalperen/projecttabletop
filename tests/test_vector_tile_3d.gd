extends RefCounted
## Unit tests for VectorTile3D physical dimensions and kinematics in 3D.

const VectorTile3D = preload("res://ui/vector_table/render/VectorTile3D.gd")

func run() -> bool:
	var ok: bool = true

	var tile := VectorTile3D.new()
	tile.setup_tile(7001, 10, 2, false, true, true)

	if tile.unique_id != 7001 or tile.number != 10 or tile.color_index != 2:
		push_error("VectorTile3D data mismatch")
		ok = false

	if tile._visual_body == null or tile._number_label == null or tile._pip_label == null:
		push_error("VectorTile3D visual nodes not created")
		ok = false

	# Test 3D position setting
	var target := Vector3(0.12, 0.08, -0.05)
	tile.set_target_position_3d(target, true)
	if not tile.position.is_equal_approx(target) or not tile.spring_pos.is_equal_approx(target):
		push_error("VectorTile3D target snap failed")
		ok = false

	# Test lift
	tile.set_drag_lift(0.040)
	if tile.target_lift_y != 0.040:
		push_error("Lift target mismatch")
		ok = false

	tile.free()
	return ok
