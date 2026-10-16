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

# Group selection and manipulation state
var _selected_slots: Array[int] = []
var _selected_tile_ids: Array[int] = []
var _selected_is_group: bool = false

var _is_group_drag: bool = false
var _drag_group_slots: Array[int] = []
var _drag_group_tids: Array[int] = []
var _drag_group_tiles: Array[VectorTile3D] = []
var _drag_anchor_tile: VectorTile3D = null
var _drag_anchor_slot: int = -1

var _press_tile: VectorTile3D = null
var _press_slot: int = -1
var _press_pos: Vector2 = Vector2.ZERO
var _press_time_ms: int = 0
var _last_click_time_ms: int = 0
var _last_click_tile_id: int = -1

var _drag_plane: Plane
var _prev_drag_world_pos: Vector3 = Vector3.ZERO
var _drag_vel: Vector3 = Vector3.ZERO
var _last_screen_pos: Vector2 = Vector2.ZERO


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
		_last_screen_pos = event.position
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
		_last_screen_pos = event.position
		if is_dragging and (dragged_tile != null or _is_group_drag):
			_end_drag(event.position)
		elif _press_tile != null:
			var duration_ms: int = Time.get_ticks_msec() - _press_time_ms
			if duration_ms < 300:
				_handle_click(_press_tile, _press_slot)

		_press_tile = null
		_press_slot = -1


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	_last_screen_pos = event.position
	if _press_tile != null and not is_dragging:
		if event.position.distance_to(_press_pos) > 6.0:
			_start_drag(_press_tile, _press_slot)

	if is_dragging and (dragged_tile != null or _is_group_drag):
		_update_drag(event.position)


func _start_drag(tile: VectorTile3D, slot_idx: int) -> void:
	is_dragging = true

	# Check if starting drag from an already selected group
	if _selected_is_group and _selected_slots.has(slot_idx) and _selected_slots.size() > 1:
		_is_group_drag = true
		_drag_group_slots = _selected_slots.duplicate()
		_drag_group_tids = _selected_tile_ids.duplicate()
		_drag_anchor_slot = slot_idx
		_drag_anchor_tile = tile
		_drag_group_tiles.clear()

		for tid in _drag_group_tids:
			var tnode: VectorTile3D = registry.get_node_for(tid) if registry != null else null
			if tnode != null:
				tnode.is_dragging = true
				tnode.set_drag_lift(0.025)
				tnode.set_highlight(&"hover")
				_drag_group_tiles.append(tnode)
		dragged_tile = tile
		drag_source_slot = slot_idx
	else:
		_is_group_drag = false
		dragged_tile = tile
		drag_source_slot = slot_idx
		tile.is_dragging = true
		tile.set_drag_lift(0.025)
		tile.set_highlight(&"hover")

	# Define drag plane parallel to camera screen facing camera, lifted forward towards camera
	var cam_xf: Transform3D = camera.global_transform if camera.is_inside_tree() else camera.transform
	var plane_normal := cam_xf.basis.z.normalized()
	var tile_pos: Vector3 = tile.global_position if tile.is_inside_tree() else tile.position
	var lift_offset := cam_xf.basis.z.normalized() * 0.030
	_drag_plane = Plane(plane_normal, tile_pos + lift_offset)
	_prev_drag_world_pos = tile_pos + lift_offset
	_drag_vel = Vector3.ZERO

	if not _is_group_drag and discard_piles != null and discard_piles.has_method("set_drop_highlight"):
		discard_piles.set_drop_highlight(true)


func _update_drag(screen_pos: Vector2) -> void:
	_last_screen_pos = screen_pos
	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_dir := camera.project_ray_normal(screen_pos)

	var hit_pos = _drag_plane.intersects_ray(ray_origin, ray_dir)
	if hit_pos == null:
		hit_pos = _drag_plane.project(ray_origin + ray_dir * 0.6)

	var new_pos: Vector3 = hit_pos
	var delta_pos := new_pos - _prev_drag_world_pos
	# Filter velocity with spring smoothing to eliminate mouse jitter
	_drag_vel = _drag_vel.lerp(delta_pos * 30.0, 0.45)
	_prev_drag_world_pos = new_pos

	# 6-DOF velocity tilt
	var tilt_deg: Vector3 = SPRING3D.calculate_tilt_3d(_drag_vel, 6.0, 14.0)

	var base_rot := Vector3(-6.0, 0.0, 0.0)
	if hand_rig != null:
		base_rot = hand_rig.global_transform.basis.get_euler() * (180.0 / PI)

	var cam_xf: Transform3D = camera.global_transform if camera.is_inside_tree() else camera.transform

	if _is_group_drag and _drag_anchor_tile != null:
		_drag_anchor_tile.position = new_pos
		_drag_anchor_tile.rotation_degrees = base_rot + tilt_deg

		for i in range(_drag_group_tiles.size()):
			var tnode: VectorTile3D = _drag_group_tiles[i]
			if tnode == _drag_anchor_tile:
				continue
			var s: int = _drag_group_slots[i]
			var col_diff: float = float(s - _drag_anchor_slot)
			var offset: Vector3 = cam_xf.basis.x.normalized() * (col_diff * TUNING.TILE_PITCH)
			tnode.position = new_pos + offset
			tnode.rotation_degrees = base_rot + tilt_deg

		if hand_rig != null:
			var xf := hand_rig.global_transform if hand_rig.is_inside_tree() else hand_rig.transform
			var local_pt: Vector3 = xf.affine_inverse() * new_pos
			hand_rig.apply_push_aside(local_pt, _drag_anchor_slot, 0.026, 0.055)
	elif dragged_tile != null:
		dragged_tile.position = new_pos
		dragged_tile.rotation_degrees = base_rot + tilt_deg

		if hand_rig != null:
			var xf := hand_rig.global_transform if hand_rig.is_inside_tree() else hand_rig.transform
			var local_pt: Vector3 = xf.affine_inverse() * new_pos
			hand_rig.apply_push_aside(local_pt, drag_source_slot, 0.022, 0.040)


func _end_drag(screen_pos: Vector2 = Vector2.ZERO) -> void:
	var anchor_node: VectorTile3D = _drag_anchor_tile if _is_group_drag else dragged_tile
	if anchor_node == null:
		_cleanup_drag()
		return

	var drop_pos := anchor_node.global_position
	var tile_id := anchor_node.unique_id
	var pos_to_use: Vector2 = screen_pos if screen_pos != Vector2.ZERO else _last_screen_pos

	# Raycast from camera through drop screen coordinate to table surface plane
	var table_plane := Plane(Vector3.UP, TUNING.TABLE_SURFACE_Y)
	var ray_origin := camera.project_ray_origin(pos_to_use)
	var ray_dir := camera.project_ray_normal(pos_to_use)
	var table_hit = table_plane.intersects_ray(ray_origin, ray_dir)
	var table_pt: Vector3 = table_hit if table_hit != null else drop_pos

	# 1. Check drop on player's discard pile (SE corner / tray)
	var discard_pos: Vector3 = TUNING.DISCARD_POS_3D.get(0, Vector3.ZERO)
	var discard_screen := camera.unproject_position(discard_pos)
	var screen_dist: float = pos_to_use.distance_to(discard_screen) if pos_to_use != Vector2.ZERO else 999.0
	var table_dist: float = table_pt.distance_to(discard_pos)
	var in_se_zone: bool = (table_pt.x > 0.20 and table_pt.z > -0.08 and table_pt.z < 0.45)

	var is_off_rack_right: bool = false
	if hand_rig != null:
		var local_pt: Vector3 = hand_rig.global_transform.affine_inverse() * drop_pos
		if local_pt.x > 0.35:
			is_off_rack_right = true

	if screen_dist < 160.0 or table_dist < 0.24 or in_se_zone or is_off_rack_right:
		if _is_group_drag:
			_notify_player("Cannot discard multiple tiles at once")
			_cleanup_drag()
			return
		if session != null:
			var res: Dictionary = session.overlay_discard_tile(tile_id)
			if bool(res.get("ok", false)):
				tile_discarded.emit(tile_id)
				_cleanup_drag()
				return
			else:
				var reason: String = str(res.get("reason", "Cannot discard tile now"))
				_notify_player(reason)
				_cleanup_drag()
				return

	# 2. Check drop onto table melds or open felt (Meld to table!)
	var is_over_table_felt: bool = (table_pt.z < 0.26 and absf(table_pt.x) < 0.52 and absf(table_pt.z) < 0.42)

	# 2a. Check drop onto existing table melds
	if table != null and table.has_node("MeldLayout"):
		var meld_layout = table.get_node("MeldLayout")
		for m_idx in range(meld_layout.get_meld_count()):
			var m_data: Dictionary = meld_layout.get_meld_data(m_idx)
			var c_pos: Vector3 = m_data.get("center_world_pos", Vector3.ZERO)
			var m_w: float = float(m_data.get("width", 0.15))
			if absf(table_pt.x - c_pos.x) <= (m_w * 0.60) and absf(table_pt.z - c_pos.z) <= 0.055:
				if session != null:
					var tile_ids_to_add: Array = _drag_group_tids if _is_group_drag else [tile_id]
					var res: Dictionary = session.overlay_add_to_meld(tile_ids_to_add, m_idx)
					if bool(res.get("ok", false)):
						_cleanup_drag()
						return
					else:
						_notify_player(str(res.get("reason", "Tile cannot be added to this meld")))
						_cleanup_drag()
						return

	# 2b. Check drop onto open table area (Open melds to table!)
	if is_over_table_felt and session != null:
		if _is_group_drag:
			var res: Dictionary = session.overlay_open_single_meld(_drag_group_tids)
			if bool(res.get("ok", false)):
				_cleanup_drag()
				return
			else:
				var reason: String = str(res.get("reason", "Need at least 101 points to open melds"))
				_notify_player(reason)
				_cleanup_drag()
				return
		elif session.has_method("find_rack_group_at"):
			var grp: Dictionary = session.find_rack_group_at(drag_source_slot)
			if grp.get("is_group", false):
				var res: Dictionary = session.overlay_open_single_meld(grp.get("tile_ids", []))
				if bool(res.get("ok", false)):
					_cleanup_drag()
					return
				else:
					var reason: String = str(res.get("reason", "Need at least 101 points to open melds"))
					_notify_player(reason)
					_cleanup_drag()
					return
			else:
				_notify_player("Drag a valid group of 3+ tiles to open melds, or drop on existing meld")
				_cleanup_drag()
				return

	# 3. Check drop onto hand rack (Move on rack, shove into space!)
	if hand_rig != null:
		var target_slot: int = hand_rig.nearest_slot(drop_pos)
		if _is_group_drag:
			var anchor_idx: int = _drag_group_slots.find(_drag_anchor_slot)
			if anchor_idx == -1:
				anchor_idx = 0
			var target_start_slot: int = target_slot - anchor_idx
			if session != null:
				session.overlay_move_group(_drag_group_slots, target_start_slot)
				tile_moved.emit(_drag_group_slots[0], target_start_slot)
		else:
			if target_slot != drag_source_slot and drag_source_slot >= 0:
				if session != null:
					session.overlay_move_slot(drag_source_slot, target_slot)
					tile_moved.emit(drag_source_slot, target_slot)

	_cleanup_drag()


func _cleanup_drag() -> void:
	if discard_piles != null and discard_piles.has_method("set_drop_highlight"):
		discard_piles.set_drop_highlight(false)

	if _is_group_drag:
		for tnode in _drag_group_tiles:
			if is_instance_valid(tnode):
				tnode.is_dragging = false
				tnode.set_drag_lift(0.0)
				tnode.set_highlight(&"none")
		_drag_group_tiles.clear()
		_drag_group_slots.clear()
		_drag_group_tids.clear()
		_drag_anchor_tile = null
		_drag_anchor_slot = -1
		_is_group_drag = false
	elif dragged_tile != null:
		dragged_tile.is_dragging = false
		dragged_tile.set_drag_lift(0.0)
		dragged_tile.set_highlight(&"none")

	if hand_rig != null:
		hand_rig.clear_push_aside()

	_clear_selection()
	is_dragging = false
	dragged_tile = null
	drag_source_slot = -1


func _notify_player(message: String) -> void:
	if table != null and table.has_method("show_feedback"):
		table.show_feedback(message)
	elif table != null and table.has_node("PlayHUD"):
		var hud = table.get_node("PlayHUD")
		if hud != null and hud.has_method("show_feedback"):
			hud.show_feedback(message)


func _clear_selection() -> void:
	for tid in _selected_tile_ids:
		if registry != null:
			var tnode: VectorTile3D = registry.get_node_for(tid)
			if tnode != null and not tnode.is_dragging:
				tnode.set_highlight(&"none")
				tnode.set_drag_lift(0.0)
	_selected_slots.clear()
	_selected_tile_ids.clear()
	_selected_is_group = false


func _handle_click(tile: VectorTile3D, slot_idx: int) -> void:
	var now_ms := Time.get_ticks_msec()
	var is_double: bool = (now_ms - _last_click_time_ms < 350) and (_last_click_tile_id == tile.unique_id)
	_last_click_time_ms = now_ms
	_last_click_tile_id = tile.unique_id

	if is_double:
		# Double-click: discard tile
		if session != null:
			var res: Dictionary = session.overlay_discard_tile(tile.unique_id)
			if bool(res.get("ok", false)):
				tile_discarded.emit(tile.unique_id)
			else:
				_notify_player(str(res.get("reason", "Cannot discard tile now")))
		tile_picked.emit(tile)
		return

	# Smart group selection: touching tiles highlight together if they form a group;
	# if touching tiles do NOT form a group, nothing gets highlighted!
	if session != null and session.has_method("find_rack_group_at"):
		var grp: Dictionary = session.find_rack_group_at(slot_idx)
		if grp.get("is_group", false):
			var slots: Array[int] = grp.get("slots", [])
			var tids: Array[int] = grp.get("tile_ids", [])
			if _selected_is_group and _selected_slots == slots:
				# Toggle off
				_clear_selection()
			else:
				_clear_selection()
				_selected_slots = slots.duplicate()
				_selected_tile_ids = tids.duplicate()
				_selected_is_group = true
				for tid in _selected_tile_ids:
					var tnode: VectorTile3D = registry.get_node_for(tid) if registry != null else null
					if tnode != null:
						tnode.set_highlight(&"selected")
						tnode.set_drag_lift(0.006) # 6mm tactile pop-up
			tile_picked.emit(tile)
			return
		elif grp.get("is_single", false):
			# Isolated single tile
			if not _selected_is_group and _selected_slots == [slot_idx]:
				_clear_selection()
			else:
				_clear_selection()
				_selected_slots = [slot_idx]
				_selected_tile_ids = [tile.unique_id]
				_selected_is_group = false
				tile.set_highlight(&"selected")
				tile.set_drag_lift(0.006)
			tile_picked.emit(tile)
			return
		else:
			# Touching tiles that do NOT form a valid group:
			# "if they dont form a group even if they touch eachother nothing it doesnt get highlighted"
			_clear_selection()
			return

	# Fallback selection
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
