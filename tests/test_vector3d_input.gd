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

	# 3. Test Smart Group Selection & Manipulation
	var mock_session = RefCounted.new()
	# Create 3 tiles forming a valid run
	var t1: VectorTile3D = registry.ensure(1001, 1, 0, false, true, true)
	var t2: VectorTile3D = registry.ensure(1002, 2, 0, false, true, true)
	var t3: VectorTile3D = registry.ensure(1003, 3, 0, false, true, true)
	registry.set_zone(1001, &"hand")
	registry.set_zone(1002, &"hand")
	registry.set_zone(1003, &"hand")

	# Mock session with find_rack_group_at returning a valid group for slots [0, 1, 2]
	var group_dict := {
		"is_group": true,
		"is_single": false,
		"slots": [0, 1, 2],
		"tile_ids": [1001, 1002, 1003],
		"kind": 0,
		"points": 6
	}
	# Set a fake session object via an inner script or lambda dictionary
	var dummy_sess = Node.new()
	dummy_sess.set_script(load("res://ui/game_table/OkeySession.gd"))
	input.session = dummy_sess
	# Verify that clicking a tile in a valid group highlights all 3 tiles together
	input._selected_slots = [0, 1, 2]
	input._selected_tile_ids = [1001, 1002, 1003]
	input._selected_is_group = true

	# Start group drag from slot 1
	input._start_drag(t2, 1)
	if not input._is_group_drag or input._drag_group_tiles.size() != 3:
		push_error("Group drag not initiated correctly: is_group_drag=%s, count=%d" % [input._is_group_drag, input._drag_group_tiles.size()])
		ok = false

	# All 3 tiles must have lift and dragging flags set
	if not t1.is_dragging or not t2.is_dragging or not t3.is_dragging:
		push_error("All tiles in group must have is_dragging=true during group drag")
		ok = false

	# Cleanup group drag
	input._cleanup_drag()
	if input._is_group_drag or t1.is_dragging or t2.is_dragging or t3.is_dragging:
		push_error("Group drag cleanup failed to reset group tiles")
		ok = false

	dummy_sess.free()
	cam.queue_free()
	input.queue_free()
	registry.queue_free()
	hand_rig.queue_free()

	return ok
