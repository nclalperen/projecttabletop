class_name MeldTableZone3D
extends Node3D

signal extension_socket_hovered(meld_index: int, socket_pos: StringName, world_pos: Vector3)
signal extension_socket_dropped(tile_id: int, meld_index: int, socket_pos: StringName)
signal fake_okey_swap_requested(tile_id: int, meld_index: int, target_tile_id: int)

const TILE_W: float = 0.038
const TILE_H: float = 0.052
const TILE_D: float = 0.010
const SOCKET_PICK_RADIUS_PX: float = 38.0

var _socket_hits: Array[Dictionary] = [] # {"meld_index": int, "socket_pos": StringName, "world": Vector3, "node": Node3D}
var _table_melds: Array = []
var _okey_context = null

var _socket_mat_normal: StandardMaterial3D = null
var _socket_mat_highlight: StandardMaterial3D = null

func _init() -> void:
	_init_socket_materials()

func _init_socket_materials() -> void:
	_socket_mat_normal = StandardMaterial3D.new()
	_socket_mat_normal.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	_socket_mat_normal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_socket_mat_normal.albedo_color = Color(0.2, 0.6, 0.9, 0.20)

	_socket_mat_highlight = StandardMaterial3D.new()
	_socket_mat_highlight.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	_socket_mat_highlight.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_socket_mat_highlight.albedo_color = Color(0.2, 0.9, 0.45, 0.50)

func sync_melds(table_melds: Array, okey_context = null) -> void:
	_table_melds = table_melds
	_okey_context = okey_context
	_rebuild_meld_zone()

func _rebuild_meld_zone() -> void:
	for child in get_children():
		child.queue_free()
	_socket_hits.clear()

	var cursor := Vector2(-0.33, -0.13)
	for index in range(_table_melds.size()):
		var meld = _table_melds[index]
		if meld == null:
			continue
		var tile_count: int = meld.tiles_data.size() if "tiles_data" in meld else 0
		var span: float = float(tile_count) * 0.047
		if cursor.x + span > 0.33:
			cursor.x = -0.33
			cursor.y += 0.080
		if cursor.y > 0.04:
			break

		var meld_root := Node3D.new()
		meld_root.name = "MeldGroup%d" % index
		add_child(meld_root)

		# Head extension socket (to the left of first tile)
		var head_local := cursor + Vector2(-0.024, 0.0)
		var head_world := Vector3(head_local.x, 0.004, head_local.y)
		var head_socket := _create_socket_quad(index, &"HEAD", head_world)
		meld_root.add_child(head_socket)
		_socket_hits.append({
			"meld_index": index,
			"socket_pos": &"HEAD",
			"world": head_world,
			"node": head_socket
		})

		# Tail extension socket (to the right of last tile)
		var tail_local := cursor + Vector2(0.02 + float(tile_count) * 0.047, 0.0)
		var tail_world := Vector3(tail_local.x, 0.004, tail_local.y)
		var tail_socket := _create_socket_quad(index, &"TAIL", tail_world)
		meld_root.add_child(tail_socket)
		_socket_hits.append({
			"meld_index": index,
			"socket_pos": &"TAIL",
			"world": tail_world,
			"node": tail_socket
		})

		cursor.x += span + 0.048

func _create_socket_quad(meld_index: int, socket_pos: StringName, world_pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Socket_%s_%d" % [String(socket_pos), meld_index]
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(TILE_W * 0.95, TILE_H * 0.95)
	mi.mesh = plane_mesh
	mi.position = world_pos
	mi.material_override = _socket_mat_normal
	mi.visible = false
	return mi

func highlight_valid_sockets(_tile_id: int, valid_targets: Array) -> void:
	for hit in _socket_hits:
		var node = hit.get("node") as MeshInstance3D
		if node == null:
			continue
		var m_idx: int = int(hit.get("meld_index", -1))
		var is_valid: bool = valid_targets.has(m_idx)
		node.visible = is_valid
		if is_valid:
			node.material_override = _socket_mat_highlight

func clear_socket_highlights() -> void:
	for hit in _socket_hits:
		var node = hit.get("node") as MeshInstance3D
		if node != null:
			node.visible = false
			node.material_override = _socket_mat_normal

func evaluate_drop_socket(screen_pos: Vector2, camera: Camera3D) -> Dictionary:
	if camera == null or not is_instance_valid(camera):
		return {}
	var best_dist: float = SOCKET_PICK_RADIUS_PX
	var best_hit: Dictionary = {}
	for hit in _socket_hits:
		var node = hit.get("node") as MeshInstance3D
		if node == null or not node.visible:
			continue
		var world_pos: Vector3 = hit.get("world", Vector3.ZERO) as Vector3
		if camera.is_position_behind(world_pos):
			continue
		var screen_pt: Vector2 = camera.unproject_position(world_pos)
		var dist: float = screen_pt.distance_to(screen_pos)
		if dist < best_dist:
			best_dist = dist
			best_hit = hit
	return best_hit

func get_meld_count() -> int:
	return _table_melds.size()

func get_socket_hits() -> Array[Dictionary]:
	return _socket_hits
