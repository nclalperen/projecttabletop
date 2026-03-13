extends RigidBody3D

signal client_set_hover_position(piece)
signal scale_changed()

const HOVER_FOLLOW_ALPHA: float = 0.32
const HOVER_ROTATION_ALPHA: float = 0.36
const SHAKE_WAIT_DURATION_MS: int = 500
const SHAKE_THRESHOLD: float = 1200.0

@export var piece_entry: Dictionary = {}
@export var expose_albedo_color: bool = true

var hover_player: int = 0
var hover_position: Vector3 = Vector3.ZERO
var hover_quat: Quaternion = Quaternion.IDENTITY
var hover_offset: Vector3 = Vector3.ZERO
var hover_start_time: int = 0

var _last_velocity: Vector3 = Vector3.ZERO
var _new_velocity: Vector3 = Vector3.ZERO
var _outline_material: StandardMaterial3D = null


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 8


func _physics_process(_delta: float) -> void:
	_new_velocity = linear_velocity
	if is_hovering():
		global_position = global_position.lerp(hover_position + hover_offset, HOVER_FOLLOW_ALPHA)
		var basis_now: Basis = global_transform.basis
		var basis_target: Basis = Basis(hover_quat)
		global_transform.basis = basis_now.slerp(basis_target, HOVER_ROTATION_ALPHA)
		emit_signal("client_set_hover_position", self)
	_last_velocity = _new_velocity


func get_collision_shapes() -> Array[CollisionShape3D]:
	var out: Array[CollisionShape3D] = []
	for child in get_children():
		if child is CollisionShape3D:
			out.append(child as CollisionShape3D)
	return out


func get_mesh_instances() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for child in get_children():
		if child is MeshInstance3D:
			out.append(child as MeshInstance3D)
		for nested in child.get_children():
			if nested is MeshInstance3D:
				out.append(nested as MeshInstance3D)
	return out


func get_size() -> Vector3:
	if piece_entry.has("scale"):
		var scale_value = piece_entry.get("scale")
		if scale_value is Vector3:
			return scale_value
		if scale_value is Vector2:
			var v2: Vector2 = scale_value
			return Vector3(v2.x, 0.01, v2.y)
	var mesh_size: Vector3 = _infer_mesh_size()
	return mesh_size if mesh_size != Vector3.ZERO else Vector3.ONE * 0.1


func _infer_mesh_size() -> Vector3:
	var out: Vector3 = Vector3.ZERO
	for mesh_instance in get_mesh_instances():
		if mesh_instance.mesh == null:
			continue
		var local_size: Vector3 = mesh_instance.mesh.get_aabb().size
		local_size.x *= absf(mesh_instance.scale.x)
		local_size.y *= absf(mesh_instance.scale.y)
		local_size.z *= absf(mesh_instance.scale.z)
		out = out.max(local_size)
	return out


func get_radius() -> float:
	var s: Vector3 = get_size()
	return maxf(s.x, maxf(s.y, s.z)) * 0.5


func is_hovering() -> bool:
	return hover_player > 0


func hovering_duration() -> int:
	if hover_player <= 0:
		return 0
	return Time.get_ticks_msec() - hover_start_time


func is_being_shaked() -> bool:
	if not is_hovering():
		return false
	if hovering_duration() < SHAKE_WAIT_DURATION_MS:
		return false
	if _last_velocity.length_squared() <= 1.0:
		return false
	if _new_velocity.dot(_last_velocity) >= 0.0:
		return false
	return (_new_velocity - _last_velocity).length_squared() > SHAKE_THRESHOLD


func set_outline_color(color: Color) -> void:
	for mesh in get_mesh_instances():
		if mesh.get_surface_override_material_count() == 0:
			continue
		var mat: Material = mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			var dup := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			dup.emission_enabled = color.a > 0.0
			dup.emission = color
			mesh.set_surface_override_material(0, dup)


func get_albedo_color() -> Color:
	if not expose_albedo_color:
		return Color.WHITE
	for mesh in get_mesh_instances():
		var mat: Material = mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			return (mat as StandardMaterial3D).albedo_color
	return Color.WHITE


func set_albedo_color(color: Color) -> void:
	if not expose_albedo_color:
		return
	for mesh in get_mesh_instances():
		var mat: Material = mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			var dup := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
			dup.albedo_color = color
			mesh.set_surface_override_material(0, dup)


func start_hovering(player_id: int, init_pos: Vector3, offset_pos: Vector3 = Vector3.ZERO) -> bool:
	if player_id <= 0:
		return false
	hover_player = player_id
	hover_start_time = Time.get_ticks_msec()
	hover_position = init_pos
	hover_offset = offset_pos
	hover_quat = global_transform.basis.get_rotation_quaternion()
	freeze = false
	sleeping = false
	return true


func stop_hovering() -> void:
	hover_player = 0
	hover_offset = Vector3.ZERO


func set_hover_position(new_hover_position: Vector3) -> void:
	hover_position = new_hover_position
	emit_signal("client_set_hover_position", self)


func set_hover_rotation(new_hover_quat: Quaternion) -> void:
	hover_quat = new_hover_quat.normalized()


@rpc("any_peer", "call_local")
func rpc_set_hover_position(new_hover_position: Vector3) -> void:
	set_hover_position(new_hover_position)


@rpc("any_peer", "call_local")
func rpc_set_hover_rotation(new_hover_quat: Quaternion) -> void:
	set_hover_rotation(new_hover_quat)


@rpc("any_peer", "call_local")
func rpc_start_hovering(player_id: int, init_pos: Vector3, offset_pos: Vector3) -> void:
	start_hovering(player_id, init_pos, offset_pos)


@rpc("any_peer", "call_local")
func rpc_stop_hovering() -> void:
	stop_hovering()
