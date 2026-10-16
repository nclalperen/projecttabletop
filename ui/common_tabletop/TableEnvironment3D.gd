class_name TableEnvironment3D
extends Node3D

const TABLE_CONFIG_SCRIPT: Script = preload("res://core/config/TableConfig.gd")

@export var table_config: Resource = null

var _table_body: MeshInstance3D = null
var _table_surface: MeshInstance3D = null
var _seat_anchors: Array[Node3D] = []

func _ready() -> void:
	if table_config == null:
		table_config = TABLE_CONFIG_SCRIPT.new()
	rebuild_environment()

func set_config(config: Resource) -> void:

	table_config = config
	rebuild_environment()

func rebuild_environment() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	_seat_anchors.clear()

	if table_config == null:
		return

	# Build table body
	_table_body = MeshInstance3D.new()
	_table_body.name = "TableBody"
	var body_box := BoxMesh.new()
	var w: float = float(table_config.get("table_width")) if table_config.get("table_width") != null else 1.2
	var l: float = float(table_config.get("table_length")) if table_config.get("table_length") != null else 1.2
	body_box.size = Vector3(w, 0.05, l)
	_table_body.mesh = body_box
	_table_body.position = Vector3(0.0, -0.025, 0.0)
	add_child(_table_body)

	# Build table felt surface
	_table_surface = MeshInstance3D.new()
	_table_surface.name = "TableSurface"
	var surface_box := BoxMesh.new()
	var fw: float = float(table_config.get("felt_width")) if table_config.get("felt_width") != null else 0.82
	var fl: float = float(table_config.get("felt_length")) if table_config.get("felt_length") != null else 0.82
	surface_box.size = Vector3(fw, 0.003, fl)
	_table_surface.mesh = surface_box
	_table_surface.position = Vector3(0.0, 0.0015, 0.0)
	var mat := StandardMaterial3D.new()
	var felt_col: Color = table_config.get("felt_color") if table_config.get("felt_color") != null else Color(0.12, 0.42, 0.22)
	mat.albedo_color = felt_col
	var felt_rough: float = float(table_config.get("felt_roughness")) if table_config.get("felt_roughness") != null else 0.88
	mat.roughness = felt_rough
	_table_surface.material_override = mat
	add_child(_table_surface)

	# Build seat anchors from config
	var seats: Array = table_config.get("seats") as Array if table_config.get("seats") != null else []
	if not seats.is_empty():
		for i in range(seats.size()):
			var seat = seats[i]
			if seat == null:
				continue
			var anchor := Node3D.new()
			var s_idx: int = int(seat.get("seat_index")) if seat.get("seat_index") != null else i
			anchor.name = "SeatAnchor%d" % s_idx
			var s_pos: Vector3 = seat.get("seat_position") if seat.get("seat_position") != null else Vector3.ZERO
			var s_rot: Vector3 = seat.get("seat_rotation") if seat.get("seat_rotation") != null else Vector3.ZERO
			anchor.position = s_pos
			anchor.rotation_degrees = s_rot
			add_child(anchor)
			_seat_anchors.append(anchor)
	else:
		var count: int = int(table_config.get("seat_count")) if table_config.get("seat_count") != null else 0
		for i in range(maxi(0, count)):
			var anchor := Node3D.new()
			anchor.name = "SeatAnchor%d" % i
			add_child(anchor)
			_seat_anchors.append(anchor)

func get_seat_anchor(seat_index: int) -> Node3D:
	for anchor in _seat_anchors:
		if anchor.name == "SeatAnchor%d" % seat_index:
			return anchor
	return null

func get_seat_anchor_count() -> int:
	return _seat_anchors.size()

func get_surface() -> MeshInstance3D:
	return _table_surface
