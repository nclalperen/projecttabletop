extends SceneTree
## Unit test for VectorInput3D physics input, drag lift, and HandRig3D Gaussian push-aside.

const VectorInput3D = preload("res://ui/vector_table/input/VectorInput3D.gd")
const HandRig3D = preload("res://ui/vector_table/hand/HandRig3D.gd")
const TileRegistry3D = preload("res://ui/vector_table/TileRegistry3D.gd")
const VectorTile3D = preload("res://ui/vector_table/render/VectorTile3D.gd")
const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")

func _init() -> void:
	var ok := run()
	if ok:
		print("  PASS  test_vector3d_input")
	else:
		print("  FAIL  test_vector3d_input")
	quit(0 if ok else 1)


func run() -> bool:
	var ok: bool = true

	# 1. Test HandRig3D Gaussian push-aside
	var hand_rig := HandRig3D.new()
	root.add_child(hand_rig)

	# Apply push-aside at center slot (col 7 on row 0)
	var center_local := Vector3(0.0, TUNING.ROW_LOCAL_Y[0], 0.0)
	hand_rig.apply_push_aside(center_local, 7, 0.022, 0.040)

	var xf_left: Transform3D = hand_rig.slot_local_transform(6)  # Left neighbor
	var xf_right: Transform3D = hand_rig.slot_local_transform(8) # Right neighbor

	var base_left_x := (float(6) - 7.0) * TUNING.TILE_PITCH
	var base_right_x := (float(8) - 7.0) * TUNING.TILE_PITCH

	if xf_left.origin.x >= base_left_x:
		push_error("Left neighbor expected to be pushed left: got %.4f vs base %.4f" % [xf_left.origin.x, base_left_x])
		ok = false

	if xf_right.origin.x <= base_right_x:
		push_error("Right neighbor expected to be pushed right: got %.4f vs base %.4f" % [xf_right.origin.x, base_right_x])
		ok = false

	hand_rig.clear_push_aside()
	var xf_left_rest: Transform3D = hand_rig.slot_local_transform(6)
	if not is_equal_approx(xf_left_rest.origin.x, base_left_x):
		push_error("Push aside not cleared back to rest position")
		ok = false

	# 2. Test VectorInput3D drag lift and cleanup
	var registry := TileRegistry3D.new()
	root.add_child(registry)

	var input := VectorInput3D.new()
	root.add_child(input)
	input.hand_rig = hand_rig
	input.registry = registry

	var tile: VectorTile3D = registry.ensure(99123, 7, 0, false, true, true)
	registry.set_zone(99123, &"hand")

	# Mock camera
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = TUNING.CAMERA_POS
	input.camera = cam

	# Start drag
	input._start_drag(tile, 7)
	if not input.is_dragging or input.dragged_tile != tile:
		push_error("VectorInput3D _start_drag did not set dragging state")
		ok = false

	if not tile.is_dragging or tile.target_lift_y <= 0.0:
		push_error("Tile lift not set on drag start")
		ok = false

	# Cleanup drag
	input._cleanup_drag()
	if input.is_dragging or input.dragged_tile != null:
		push_error("VectorInput3D _cleanup_drag did not reset dragging state")
		ok = false

	if tile.is_dragging or tile.target_lift_y != 0.0:
		push_error("Tile lift not cleared on cleanup")
		ok = false

	cam.queue_free()
	input.queue_free()
	registry.queue_free()
	hand_rig.queue_free()

	return ok
