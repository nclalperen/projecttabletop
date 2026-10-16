class_name VectorInput3D
extends Node
## 3D Physics Input System for VectorGameTable3D.
## Manages camera raycast picking (collision layer 2), spring-following 6-DOF drag
## with velocity tilt and continuous Gaussian push-aside on neighboring hand slots.

signal tile_picked(tile: VectorTile3D)
signal tile_moved(from_slot: int, to_slot: int)
signal tile_discarded(tile_id: int)
signal draw_from_stock_requested
signal take_discard_requested

const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")
const SPRING3D = preload("res://ui/vector_table/math/SpringSolver3D.gd")
const HandRig3D = preload("res://ui/vector_table/hand/HandRig3D.gd")
const TileRegistry3D = preload("res://ui/vector_table/TileRegistry3D.gd")
const VectorTile3D = preload("res://ui/vector_table/render/VectorTile3D.gd")
const StockView3D = preload("res://ui/vector_table/table/StockView3D.gd")
const DiscardPiles3D = preload("res://ui/vector_table/table/DiscardPiles3D.gd")

var table: Node3D = null
var camera: Camera3D = null
var hand_rig: HandRig3D = null
var registry: TileRegistry3D = null
var session: Node = null
var stock_view: StockView3D = null
var discard_piles: DiscardPiles3D = null

# Drag & interaction state
var dragged_tile: VectorTile3D = null
var drag_source_slot: int = -1
var is_dragging: bool = false

var _press_tile: VectorTile3D = null
var _press_slot: int = -1
var _press_pos: Vector2 = Vector2.ZERO
var _press_time_ms: int = 0
var _last_click_time_ms: int = 0
var _last_click_tile_id: int = -1

var _drag_plane: Plane
var _prev_drag_world_pos: Vector3 = Vector3.ZERO
var _drag_vel: Vector3 = Vector3.ZERO


func setup(p_table: Node3D, p_cam: Camera3D, p_rig: HandRig3D, p_reg: TileRegistry3D, p_sess: Node, p_stock: StockView3D, p_discards: DiscardPiles3D) -> void:
	table = p_table
	camera = p_cam
	hand_rig = p_rig
	registry = p_reg
	session = p_sess
	stock_view = p_stock
	discard_piles = p_discards


func _unhandled_input(event: InputEvent) -> void:
	if camera == null or not is_instance_valid(camera):
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		_press_pos = event.position
		_press_time_ms = Time.get_ticks_msec()
		_press_tile = null
		_press_slot = -1

		var hit: Dictionary = _raycast_layer2(event.position)
		if hit.is_empty():
			return

		var collider = hit.get("collider")
		if collider == null:
			return

		if collider.has_meta("tile_id"):
			var tid: int = int(collider.get_meta("tile_id"))
			if registry != null and registry.zone_of(tid) == &"hand":
				var tnode: VectorTile3D = registry.get_node_for(tid)
				if tnode != null and not tnode.is_flying:
					_press_tile = tnode
					_press_slot = _find_hand_slot_for_tile(tid)
		elif collider.has_meta("action"):
			var action_name: String = str(collider.get_meta("action"))
			match action_name:
				"draw_stock":
					draw_from_stock_requested.emit()
					if session != null:
						session.overlay_draw_from_deck()
				"take_discard":
					take_discard_requested.emit()
					if session != null:
						session.overlay_take_discard()

	else: # Release
		if is_dragging and dragged_tile != null:
			_end_drag()
		elif _press_tile != null:
			var duration_ms: int = Time.get_ticks_msec() - _press_time_ms
			if duration_ms < 300:
				_handle_click(_press_tile, _press_slot)

		_press_tile = null
		_press_slot = -1


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _press_tile != null and not is_dragging:
		if event.position.distance_to(_press_pos) > 6.0:
			_start_drag(_press_tile, _press_slot)

	if is_dragging and dragged_tile != null:
		_update_drag(event.position)


func _start_drag(tile: VectorTile3D, slot_idx: int) -> void:
	is_dragging = true
	dragged_tile = tile
	drag_source_slot = slot_idx

	tile.is_dragging = true
	tile.set_drag_lift(0.025) # 25mm lift
	tile.set_highlight(&"hover")

	# Define drag plane parallel to camera screen facing camera, lifted forward towards camera
	var cam_xf: Transform3D = camera.global_transform if camera.is_inside_tree() else camera.transform
	var plane_normal := cam_xf.basis.z.normalized()
	var tile_pos: Vector3 = tile.global_position if tile.is_inside_tree() else tile.position
	# Offset plane towards camera (along +camera.basis.z) so lifted tile floats in front of rack
	var lift_offset := cam_xf.basis.z.normalized() * 0.030
	_drag_plane = Plane(plane_normal, tile_pos + lift_offset)
	_prev_drag_world_pos = tile_pos + lift_offset
	_drag_vel = Vector3.ZERO


func _update_drag(screen_pos: Vector2) -> void:
	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_dir := camera.project_ray_normal(screen_pos)

	var hit_pos = _drag_plane.intersects_ray(ray_origin, ray_dir)
	if hit_pos == null:
		hit_pos = _drag_plane.project(ray_origin + ray_dir * 0.6)

	var new_pos: Vector3 = hit_pos
	var delta_pos := new_pos - _prev_drag_world_pos
	_drag_vel = delta_pos * 30.0
	_prev_drag_world_pos = new_pos

	# 6-DOF velocity tilt
	var tilt_deg: Vector3 = SPRING3D.calculate_tilt_3d(_drag_vel, 8.0, 16.0)
	dragged_tile.position = new_pos

	var base_rot := Vector3(-6.0, 0.0, 0.0)
	if hand_rig != null:
		base_rot = hand_rig.global_transform.basis.get_euler() * (180.0 / PI)
	dragged_tile.rotation_degrees = base_rot + tilt_deg

	# Gaussian push-aside on neighboring hand slots
	if hand_rig != null:
		var xf := hand_rig.global_transform if hand_rig.is_inside_tree() else hand_rig.transform
		var local_pt: Vector3 = xf.affine_inverse() * new_pos
		hand_rig.apply_push_aside(local_pt, drag_source_slot, 0.022, 0.040)


func _end_drag() -> void:
	var drop_pos := dragged_tile.global_position
	var tile_id := dragged_tile.unique_id

	# 1. Check drop on player's discard pile (SE)
	var discard_pos: Vector3 = TUNING.DISCARD_POS_3D.get(0, Vector3.ZERO)
	var dist_to_discard: float = drop_pos.distance_to(discard_pos)

	if dist_to_discard < 0.14:
		if session != null:
			var res: Dictionary = session.overlay_discard_tile(tile_id)
			if bool(res.get("ok", false)):
				tile_discarded.emit(tile_id)
				_cleanup_drag()
				return

	# 2. Check drop onto table melds
	if table != null and table.has_node("MeldLayout"):
		var meld_layout = table.get_node("MeldLayout")
		for m_idx in range(meld_layout.get_meld_count()):
			var m_data: Dictionary = meld_layout.get_meld_data(m_idx)
			var c_pos: Vector3 = m_data.get("center_world_pos", Vector3.ZERO)
			var m_w: float = float(m_data.get("width", 0.15))
			if abs(drop_pos.x - c_pos.x) <= (m_w * 0.55) and abs(drop_pos.z - c_pos.z) <= 0.045:
				if session != null:
					var res: Dictionary = session.overlay_add_to_meld([tile_id], m_idx)
					if bool(res.get("ok", false)):
						_cleanup_drag()
						return

	# 3. Check drop onto hand rack
	if hand_rig != null:
		var target_slot: int = hand_rig.nearest_slot(drop_pos)
		if target_slot != drag_source_slot and drag_source_slot >= 0:
			if session != null:
				session.overlay_move_slot(drag_source_slot, target_slot)
				tile_moved.emit(drag_source_slot, target_slot)

	_cleanup_drag()


func _cleanup_drag() -> void:
	if dragged_tile != null:
		dragged_tile.is_dragging = false
		dragged_tile.set_drag_lift(0.0)
		dragged_tile.set_highlight(&"none")

	if hand_rig != null:
		hand_rig.clear_push_aside()

	is_dragging = false
	dragged_tile = null
	drag_source_slot = -1


func _handle_click(tile: VectorTile3D, slot_idx: int) -> void:
	var now_ms := Time.get_ticks_msec()
	var is_double: bool = (now_ms - _last_click_time_ms < 350) and (_last_click_tile_id == tile.unique_id)
	_last_click_time_ms = now_ms
	_last_click_tile_id = tile.unique_id

	if is_double:
		# Double-click: discard tile
		if session != null:
			session.overlay_discard_tile(tile.unique_id)
		tile_picked.emit(tile)
	else:
		tile.set_highlight(&"selected" if tile.current_highlight != &"selected" else &"none")
		tile_picked.emit(tile)


func _raycast_layer2(screen_pos: Vector2) -> Dictionary:
	if camera == null or not is_inside_tree():
		return {}

	var space_state = camera.get_world_3d().direct_space_state
	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_dir := camera.project_ray_normal(screen_pos)
	var ray_end := ray_origin + ray_dir * 10.0

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 2)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	return space_state.intersect_ray(query)


func _find_hand_slot_for_tile(tid: int) -> int:
	if table == null:
		return -1
	var hand_slots: Dictionary = table.get("_hand_slots_map") if "_hand_slots_map" in table else {}
	for s in hand_slots.keys():
		if hand_slots[s] == tid:
			return s
	return -1
