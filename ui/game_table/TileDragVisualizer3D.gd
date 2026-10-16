class_name TileDragVisualizer3D
extends Node3D

@export var drag_follow_speed: float = 28.0
@export var max_tilt_angle_rad: float = 0.22
@export var drag_lift_scale: Vector3 = Vector3(1.07, 1.07, 1.07)
@export var snap_duration: float = 0.14

var _active_tile_node: Node3D = null
var _active_tile_id: int = -1
var _target_world_pos: Vector3 = Vector3.ZERO
var _target_base_rotation: Vector3 = Vector3.ZERO
var _current_velocity: Vector3 = Vector3.ZERO
var _is_dragging: bool = false
var _surface_y: float = 0.0

var _shadow_mesh: MeshInstance3D = null
var _ghost_mesh: MeshInstance3D = null
var _focus_reticle: MeshInstance3D = null
var _lift_tween: Tween = null
var _snap_tween: Tween = null

func _ready() -> void:
	_create_contact_shadow()
	_create_ghost_preview()
	_create_focus_reticle()

func _create_contact_shadow() -> void:
	_shadow_mesh = MeshInstance3D.new()
	_shadow_mesh.name = "ContactShadow"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.038, 0.052)
	_shadow_mesh.mesh = quad
	_shadow_mesh.rotation_degrees = Vector3(-90, 0, 0)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.02, 0.02, 0.02, 0.42)
	_shadow_mesh.material_override = mat
	_shadow_mesh.visible = false
	add_child(_shadow_mesh)

func _create_ghost_preview() -> void:
	_ghost_mesh = MeshInstance3D.new()
	_ghost_mesh.name = "SnapGhost"
	var box := BoxMesh.new()
	box.size = Vector3(0.028, 0.008, 0.040)
	_ghost_mesh.mesh = box

	var mat := StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2, 0.85, 0.45, 0.35)
	_ghost_mesh.material_override = mat
	_ghost_mesh.visible = false
	add_child(_ghost_mesh)

func _create_focus_reticle() -> void:
	if _focus_reticle != null and is_instance_valid(_focus_reticle):
		return
	_focus_reticle = MeshInstance3D.new()
	_focus_reticle.name = "FocusReticle"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.024
	torus.outer_radius = 0.028
	torus.rings = 24
	torus.ring_segments = 16
	_focus_reticle.mesh = torus

	var mat := StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.96, 0.82, 0.32, 0.85)
	_focus_reticle.material_override = mat
	_focus_reticle.visible = false
	add_child(_focus_reticle)

func show_focus_reticle(world_pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> void:
	if _focus_reticle == null:
		_create_focus_reticle()
	_focus_reticle.visible = true
	if _focus_reticle.is_inside_tree():
		_focus_reticle.global_position = world_pos + Vector3(0.0, 0.005, 0.0)
	else:
		_focus_reticle.position = world_pos + Vector3(0.0, 0.005, 0.0)
	_focus_reticle.rotation_degrees = rot_deg

func hide_focus_reticle() -> void:
	if _focus_reticle != null:
		_focus_reticle.visible = false

func is_focus_reticle_visible() -> bool:
	return _focus_reticle != null and _focus_reticle.visible

func start_drag(tile_node: Node3D, tile_id: int, surface_y: float = 0.0) -> void:
	if _snap_tween != null and _snap_tween.is_running():
		_snap_tween.kill()

	_active_tile_node = tile_node
	_active_tile_id = tile_id
	_surface_y = surface_y
	_is_dragging = true
	var tile_pos: Vector3 = tile_node.global_position if tile_node.is_inside_tree() else tile_node.position
	_target_world_pos = tile_pos
	_target_base_rotation = tile_node.rotation

	if is_inside_tree():
		if _lift_tween != null and _lift_tween.is_running():
			_lift_tween.kill()
		_lift_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_lift_tween.tween_property(_active_tile_node, ^"scale", drag_lift_scale, 0.14)

	if _shadow_mesh != null:
		_shadow_mesh.visible = true
		if _shadow_mesh.is_inside_tree():
			_shadow_mesh.global_position = Vector3(tile_pos.x, surface_y + 0.002, tile_pos.z)
		else:
			_shadow_mesh.position = Vector3(tile_pos.x, surface_y + 0.002, tile_pos.z)

func update_target(world_pos: Vector3, base_rotation_deg: Vector3 = Vector3.ZERO) -> void:
	_target_world_pos = world_pos
	_target_base_rotation = Vector3(
		deg_to_rad(base_rotation_deg.x),
		deg_to_rad(base_rotation_deg.y),
		deg_to_rad(base_rotation_deg.z)
	)

func update_ghost_snap(ghost_pos: Vector3, ghost_rot_deg: Vector3, is_valid: bool) -> void:
	if _ghost_mesh == null:
		return
	if not _is_dragging:
		_ghost_mesh.visible = false
		return
	_ghost_mesh.visible = true
	if _ghost_mesh.is_inside_tree():
		_ghost_mesh.global_position = ghost_pos
	else:
		_ghost_mesh.position = ghost_pos
	_ghost_mesh.rotation_degrees = ghost_rot_deg
	var mat: StandardMaterial3D = _ghost_mesh.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = Color(0.2, 0.85, 0.45, 0.35) if is_valid else Color(0.85, 0.3, 0.3, 0.35)

func hide_ghost_snap() -> void:
	if _ghost_mesh != null:
		_ghost_mesh.visible = false

func _process(delta: float) -> void:
	if not _is_dragging or _active_tile_node == null or not is_instance_valid(_active_tile_node):
		return

	var current_pos: Vector3 = _active_tile_node.global_position if _active_tile_node.is_inside_tree() else _active_tile_node.position
	var weight: float = 1.0 - exp(-drag_follow_speed * delta)
	var next_pos: Vector3 = current_pos.lerp(_target_world_pos, weight)
	_current_velocity = (next_pos - current_pos) / maxf(delta, 0.0001)

	# Physical velocity-based banking and pitching
	var target_pitch: float = clampf(-_current_velocity.z * 0.04, -max_tilt_angle_rad, max_tilt_angle_rad)
	var target_roll: float = clampf(_current_velocity.x * 0.04, -max_tilt_angle_rad, max_tilt_angle_rad)

	if _active_tile_node.is_inside_tree():
		_active_tile_node.global_position = next_pos
	else:
		_active_tile_node.position = next_pos
	_active_tile_node.rotation.x = lerpf(_active_tile_node.rotation.x, _target_base_rotation.x + target_pitch, weight)
	_active_tile_node.rotation.y = lerpf(_active_tile_node.rotation.y, _target_base_rotation.y, weight)
	_active_tile_node.rotation.z = lerpf(_active_tile_node.rotation.z, _target_base_rotation.z + target_roll, weight)

	if _shadow_mesh != null and _shadow_mesh.visible:
		if _shadow_mesh.is_inside_tree():
			_shadow_mesh.global_position = Vector3(next_pos.x, _surface_y + 0.002, next_pos.z)
		else:
			_shadow_mesh.position = Vector3(next_pos.x, _surface_y + 0.002, next_pos.z)

func finish_drag_snap(target_world_pos: Vector3, target_rot_deg: Vector3, on_complete: Callable = Callable()) -> void:
	_is_dragging = false
	hide_ghost_snap()
	if _shadow_mesh != null:
		_shadow_mesh.visible = false

	if _active_tile_node == null or not is_instance_valid(_active_tile_node):
		_active_tile_node = null
		_active_tile_id = -1
		if on_complete.is_valid():
			on_complete.call()
		return

	var node_ref := _active_tile_node
	_active_tile_node = null
	_active_tile_id = -1

	if _snap_tween != null and _snap_tween.is_running():
		_snap_tween.kill()

	if is_inside_tree():
		_snap_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_snap_tween.tween_property(node_ref, "global_position" if node_ref.is_inside_tree() else "position", target_world_pos, snap_duration)
		_snap_tween.tween_property(node_ref, ^"rotation_degrees", target_rot_deg, snap_duration)
		_snap_tween.tween_property(node_ref, ^"scale", Vector3.ONE, snap_duration)

		if on_complete.is_valid():
			_snap_tween.chain().tween_callback(on_complete)
	else:
		if node_ref.is_inside_tree():
			node_ref.global_position = target_world_pos
		else:
			node_ref.position = target_world_pos
		node_ref.rotation_degrees = target_rot_deg
		node_ref.scale = Vector3.ONE
		if on_complete.is_valid():
			on_complete.call()

func cancel_drag(origin_pos: Vector3, origin_rot_deg: Vector3) -> void:
	finish_drag_snap(origin_pos, origin_rot_deg)

func is_dragging() -> bool:
	return _is_dragging

func get_active_tile_id() -> int:
	return _active_tile_id
