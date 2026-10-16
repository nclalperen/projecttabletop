class_name TileInputController3D
extends Node

signal tile_picked(tile_id: int, origin_zone: StringName, origin_slot: int)
signal tile_drag_started(tile_id: int, origin_zone: StringName, origin_slot: int)
signal tile_drag_moved(tile_id: int, world_pos: Vector3, screen_pos: Vector2)
signal tile_hovered_slot_changed(target_zone: StringName, target_slot: int, world_pos: Vector3)
signal tile_dropped(tile_id: int, target_zone: StringName, target_slot: int, screen_pos: Vector2)
signal tile_drag_cancelled(tile_id: int)
signal single_tap(screen_pos: Vector2, hit_info: Dictionary)

@export var camera: Camera3D
@export var drag_lift_height: float = 0.024
@export var touch_vertical_screen_offset_px: float = -42.0
@export var drag_threshold_px: float = 10.0
@export var enabled: bool = true

var _active_tile_node: Node3D = null
var _active_tile_id: int = -1
var _origin_zone: StringName = &"NONE"
var _origin_slot: int = -1

var _is_pointer_down: bool = false
var _is_dragging: bool = false
var _is_touch_input: bool = false
var _press_screen_pos: Vector2 = Vector2.ZERO
var _current_screen_pos: Vector2 = Vector2.ZERO
var _drag_plane: Plane = Plane(Vector3.UP, 0.0)

var _hovered_zone: StringName = &"NONE"
var _hovered_slot: int = -1
var _cached_hit_info: Dictionary = {}

# Delegated evaluation callbacks from coordinator
var query_pickable_tile: Callable = Callable()
var evaluate_drop_target: Callable = Callable()

func _unhandled_input(event: InputEvent) -> void:
	if not enabled or camera == null or not is_instance_valid(camera):
		return

	if event is InputEventScreenTouch:
		_is_touch_input = true
		if event.pressed:
			_begin_pointer_press(event.position)
		else:
			_end_pointer_press(event.position)
	elif event is InputEventScreenDrag:
		_is_touch_input = true
		_update_pointer_move(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_is_touch_input = false
		if event.pressed:
			_begin_pointer_press(event.position)
		else:
			_end_pointer_press(event.position)
	elif event is InputEventMouseMotion and _is_pointer_down:
		_is_touch_input = false
		_update_pointer_move(event.position)

func _begin_pointer_press(screen_pos: Vector2) -> void:
	_cached_hit_info.clear()
	var hit: Dictionary = {}
	if query_pickable_tile.is_valid():
		hit = query_pickable_tile.call(screen_pos)
	else:
		hit = _raycast_pickable_tile(screen_pos)

	if hit.is_empty():
		return

	_cached_hit_info = hit
	_is_pointer_down = true
	_is_dragging = false
	_press_screen_pos = screen_pos
	_current_screen_pos = screen_pos
	_active_tile_node = hit.get("node") as Node3D
	_active_tile_id = int(hit.get("tile_id", -1))
	_origin_zone = StringName(hit.get("zone", &"RACK"))
	_origin_slot = int(hit.get("slot", -1))

	var lift_y: float = (_active_tile_node.global_position.y if _active_tile_node != null else 0.0) + drag_lift_height
	_drag_plane = Plane(Vector3.UP, lift_y)

	tile_picked.emit(_active_tile_id, _origin_zone, _origin_slot)

func _update_pointer_move(screen_pos: Vector2) -> void:
	_current_screen_pos = screen_pos
	if not _is_dragging:
		if _press_screen_pos.distance_to(screen_pos) >= drag_threshold_px:
			_start_drag()
		else:
			return

	var effective_screen_pos: Vector2 = screen_pos
	if _is_touch_input:
		effective_screen_pos.y += touch_vertical_screen_offset_px

	var origin: Vector3 = camera.project_ray_origin(effective_screen_pos)
	var dir: Vector3 = camera.project_ray_normal(effective_screen_pos)
	var intersection: Variant = _drag_plane.intersects_ray(origin, dir)
	if intersection != null:
		var world_pos: Vector3 = intersection
		tile_drag_moved.emit(_active_tile_id, world_pos, screen_pos)
		_evaluate_nearest_target(world_pos, screen_pos)

func _start_drag() -> void:
	_is_dragging = true
	tile_drag_started.emit(_active_tile_id, _origin_zone, _origin_slot)

func _evaluate_nearest_target(world_pos: Vector3, screen_pos: Vector2) -> void:
	if evaluate_drop_target.is_valid():
		var target: Dictionary = evaluate_drop_target.call(world_pos, screen_pos)
		var new_zone: StringName = StringName(target.get("zone", &"NONE"))
		var new_slot: int = int(target.get("slot", -1))
		var target_pos: Vector3 = target.get("world_pos", world_pos)
		if new_zone != _hovered_zone or new_slot != _hovered_slot:
			_hovered_zone = new_zone
			_hovered_slot = new_slot
			tile_hovered_slot_changed.emit(_hovered_zone, _hovered_slot, target_pos)

func _end_pointer_press(screen_pos: Vector2) -> void:
	if not _is_pointer_down:
		return
	_is_pointer_down = false

	if _is_dragging:
		_is_dragging = false
		tile_dropped.emit(_active_tile_id, _hovered_zone, _hovered_slot, screen_pos)
	else:
		# Released without exceeding drag threshold: handle as single tap/click
		single_tap.emit(screen_pos, _cached_hit_info)

	_active_tile_node = null
	_active_tile_id = -1
	_hovered_zone = &"NONE"
	_hovered_slot = -1
	_cached_hit_info.clear()

func cancel_active_drag() -> void:
	if _is_pointer_down or _is_dragging:
		var tid: int = _active_tile_id
		_is_pointer_down = false
		_is_dragging = false
		_active_tile_node = null
		_active_tile_id = -1
		_hovered_zone = &"NONE"
		_hovered_slot = -1
		_cached_hit_info.clear()
		tile_drag_cancelled.emit(tid)

func is_dragging() -> bool:
	return _is_dragging

func _raycast_pickable_tile(screen_pos: Vector2) -> Dictionary:
	var world3d: World3D = camera.get_world_3d()
	if world3d == null:
		return {}
	var space_state: PhysicsDirectSpaceState3D = world3d.direct_space_state
	var origin: Vector3 = camera.project_ray_origin(screen_pos)
	var end: Vector3 = origin + camera.project_ray_normal(screen_pos) * 12.0
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return {}
	var collider: Node = result.get("collider") as Node
	if collider != null:
		if collider.has_meta(&"tile_id"):
			return {
				"node": collider.get_parent() as Node3D,
				"tile_id": int(collider.get_meta(&"tile_id")),
				"zone": &"RACK",
				"slot": int(collider.get_meta(&"slot", -1))
			}
	return {}
