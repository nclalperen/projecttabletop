extends RefCounted

const TILE_INPUT_CONTROLLER_SCRIPT = preload("res://ui/game_table/TileInputController3D.gd")
const TILE_DRAG_VISUALIZER_SCRIPT = preload("res://ui/game_table/TileDragVisualizer3D.gd")
const RACK_SLOT_MANAGER_SCRIPT = preload("res://ui/game_table/RackSlotManager.gd")

func _expect(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("FAIL: %s" % msg)
		print("FAIL: %s" % msg)
		return false
	return true

func run() -> bool:
	var ok: bool = true

	# 1. Test TileInputController3D instantiation & contracts
	var input_ctrl = TILE_INPUT_CONTROLLER_SCRIPT.new()
	ok = _expect(input_ctrl != null, "TileInputController3D should instantiate") and ok
	ok = _expect(input_ctrl.drag_lift_height == 0.024, "drag_lift_height should be 0.024") and ok
	ok = _expect(input_ctrl.touch_vertical_screen_offset_px == -42.0, "touch_vertical_screen_offset_px should be -42.0") and ok
	ok = _expect(input_ctrl.drag_threshold_px == 10.0, "drag_threshold_px should be 10.0") and ok
	ok = _expect(input_ctrl.has_signal("tile_picked"), "Signal tile_picked missing") and ok
	ok = _expect(input_ctrl.has_signal("tile_drag_started"), "Signal tile_drag_started missing") and ok
	ok = _expect(input_ctrl.has_signal("tile_drag_moved"), "Signal tile_drag_moved missing") and ok
	ok = _expect(input_ctrl.has_signal("tile_hovered_slot_changed"), "Signal tile_hovered_slot_changed missing") and ok
	ok = _expect(input_ctrl.has_signal("tile_dropped"), "Signal tile_dropped missing") and ok
	ok = _expect(input_ctrl.has_signal("tile_drag_cancelled"), "Signal tile_drag_cancelled missing") and ok
	ok = _expect(input_ctrl.has_signal("single_tap"), "Signal single_tap missing") and ok

	input_ctrl.cancel_active_drag()
	ok = _expect(not input_ctrl.is_dragging(), "is_dragging should be false after cancel") and ok
	input_ctrl.free()

	# 2. Test TileDragVisualizer3D instantiation & contracts
	var visualizer = TILE_DRAG_VISUALIZER_SCRIPT.new()
	ok = _expect(visualizer != null, "TileDragVisualizer3D should instantiate") and ok
	ok = _expect(visualizer.drag_follow_speed == 28.0, "drag_follow_speed should be 28.0") and ok
	ok = _expect(visualizer.max_tilt_angle_rad == 0.22, "max_tilt_angle_rad should be 0.22") and ok
	ok = _expect(visualizer.snap_duration == 0.14, "snap_duration should be 0.14") and ok

	visualizer._ready()
	var shadow = visualizer.get_node_or_null("ContactShadow")
	var ghost = visualizer.get_node_or_null("SnapGhost")
	ok = _expect(shadow != null, "ContactShadow mesh missing") and ok
	ok = _expect(ghost != null, "SnapGhost mesh missing") and ok

	var dummy_tile := Node3D.new()
	visualizer.start_drag(dummy_tile, 42, 0.0)
	ok = _expect(visualizer.is_dragging(), "Visualizer should be dragging") and ok
	ok = _expect(visualizer.get_active_tile_id() == 42, "Active tile ID should be 42") and ok

	visualizer.update_ghost_snap(Vector3(1, 0, 1), Vector3.ZERO, true)
	ok = _expect(ghost.visible == true, "Ghost should be visible during snap update") and ok

	visualizer.hide_ghost_snap()
	ok = _expect(ghost.visible == false, "Ghost should be hidden after hide_ghost_snap") and ok

	visualizer.cancel_drag(Vector3.ZERO, Vector3.ZERO)
	ok = _expect(not visualizer.is_dragging(), "Visualizer should stop dragging after cancel") and ok

	dummy_tile.free()
	visualizer.free()

	# 3. Test RackSlotManager live reflow computation
	var slots = RACK_SLOT_MANAGER_SCRIPT.new()
	slots.init_rack_slots(30)
	# Set contiguous tiles at slots 4, 5, 6; slot 7 is empty
	slots.rack_slots[4] = 101
	slots.rack_slots[5] = 102
	slots.rack_slots[6] = 103

	# Hovering over slot 5 should shift 5 and 6 rightward by +1
	var shifts: Dictionary = slots.compute_reflow_preview(0, 5)
	ok = _expect(shifts.has(5) and shifts[5] == 1, "Slot 5 should shift right by +1") and ok
	ok = _expect(shifts.has(6) and shifts[6] == 1, "Slot 6 should shift right by +1") and ok
	ok = _expect(not shifts.has(4), "Slot 4 should not shift") and ok

	# Empty slot hover should produce no shifts
	var empty_shifts: Dictionary = slots.compute_reflow_preview(0, 8)
	ok = _expect(empty_shifts.is_empty(), "Empty slot should produce empty shifts") and ok

	# Test static calculate_reflow method
	var static_shifts: Dictionary = RACK_SLOT_MANAGER_SCRIPT.calculate_reflow(slots.rack_slots, 0, 5)
	ok = _expect(static_shifts == shifts, "static calculate_reflow should match compute_reflow_preview") and ok

	# Test leftward shift when left gap is closer
	slots.init_rack_slots(30)
	slots.rack_slots[2] = 201
	slots.rack_slots[3] = 202
	slots.rack_slots[4] = 203
	slots.rack_slots[5] = 204
	slots.rack_slots[6] = 205
	# Gap at 1 (dist 2 from 3), gap at 7 (dist 4 from 3) -> shifts left (-1)
	var left_shifts: Dictionary = slots.compute_reflow_preview(0, 3)
	ok = _expect(left_shifts.has(2) and left_shifts[2] == -1, "Slot 2 should shift left by -1") and ok
	ok = _expect(left_shifts.has(3) and left_shifts[3] == -1, "Slot 3 should shift left by -1") and ok
	ok = _expect(not left_shifts.has(4), "Slot 4 should not shift") and ok

	# 4. Test GameTable3D subsystem mounting
	var table_scene: PackedScene = load("res://ui/GameTable3D.tscn")
	if table_scene != null:
		var main_loop := Engine.get_main_loop() as SceneTree
		var table = table_scene.instantiate()
		if table != null:
			ok = _expect(table.has_method("_apply_rack_reflow_preview"), "_apply_rack_reflow_preview method missing on GameTable3D") and ok
			ok = _expect(table.has_method("_clear_rack_reflow_preview"), "_clear_rack_reflow_preview method missing on GameTable3D") and ok
			if main_loop != null and main_loop.root != null:
				main_loop.root.add_child(table)
				var visualizer_node = table.get_node_or_null("World/TileDragVisualizer")
				var input_node = table.get_node_or_null("TileInputController")
				ok = _expect(visualizer_node != null, "GameTable3D should instantiate TileDragVisualizer under World") and ok
				ok = _expect(input_node != null, "GameTable3D should instantiate TileInputController") and ok
				main_loop.root.remove_child(table)
			table.free()

	print("  PASS  test_tile_drag_and_input_subsystems")
	return ok
