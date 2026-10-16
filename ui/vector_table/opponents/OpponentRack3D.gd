class_name OpponentRack3D
extends Node3D
## Procedural 3D Opponent Rack for VectorGameTable3D.
## Represents an opponent seat (East, North, West) with realistic walnut rack geometry,
## face-down ivory tiles matching their current hand count, and smooth count updates.

const TABLE_ART = preload("res://ui/game_table/OkeyTableArt.gd")
const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")

const TILE_PITCH: float = 0.046
const ROW_Y: Array[float] = [0.038, 0.006]
const ROW_Z: Array[float] = [-0.020, 0.020]
const TILT_DEG: float = -6.0

var seat_index: int = 1
var tile_count: int = 21
var player_name: String = ""

var _rack_mesh: Node3D = null
var _tiles_container: Node3D = null
var _tile_nodes: Array[Node3D] = []


func setup(seat: int, name: String = "") -> void:
	seat_index = seat
	player_name = name
	name = "OpponentRack_%d" % seat

	position = TUNING.OPPONENT_RACK_POS_3D.get(seat, Vector3.ZERO)
	rotation_degrees = TUNING.OPPONENT_RACK_ROT_DEG.get(seat, Vector3.ZERO)
	scale = Vector3.ONE * TUNING.OPPONENT_RACK_SCALE

	_build_mesh()
	set_tile_count(21)


func set_tile_count(count: int) -> void:
	var target_count := clampi(count, 0, 30)
	if target_count == tile_count and _tile_nodes.size() == target_count:
		return
	tile_count = target_count
	_rebuild_tiles()


func get_launch_transform() -> Transform3D:
	# Front-center of rack in world coordinates for flight animations
	var local_launch := Vector3(0.0, 0.05, 0.06)
	var xf := global_transform if is_inside_tree() else transform
	return Transform3D(xf.basis.orthonormalized(), xf.origin + xf.basis * local_launch)


func _build_mesh() -> void:
	for child in get_children():
		child.queue_free()
	_tile_nodes.clear()

	_rack_mesh = TABLE_ART.build_rack(0.72, 0.042, 0.11)
	_rack_mesh.name = "RackGeometry"
	add_child(_rack_mesh)

	_tiles_container = Node3D.new()
	_tiles_container.name = "Tiles"
	add_child(_tiles_container)


func _rebuild_tiles() -> void:
	for node in _tile_nodes:
		if node != null and is_instance_valid(node):
			node.queue_free()
	_tile_nodes.clear()

	if _tiles_container == null:
		return

	# Distribute tiles across 2 rows (max 15 per row)
	var row0_count := mini(tile_count, 15)
	var row1_count := maxi(0, tile_count - 15)

	# Row 0 (top/rear shelf)
	var start_x0 := -(float(row0_count - 1) * 0.5) * TILE_PITCH if row0_count > 0 else 0.0
	for i in range(row0_count):
		var tile := TABLE_ART.build_tile(true, false) # standing, face-down
		tile.name = "OppTile_0_%d" % i
		tile.position = Vector3(start_x0 + float(i) * TILE_PITCH, ROW_Y[0], ROW_Z[0])
		tile.rotation_degrees = Vector3(TILT_DEG, 0.0, 0.0)
		_tiles_container.add_child(tile)
		_tile_nodes.append(tile)

	# Row 1 (bottom/front shelf)
	var start_x1 := -(float(row1_count - 1) * 0.5) * TILE_PITCH if row1_count > 0 else 0.0
	for i in range(row1_count):
		var tile := TABLE_ART.build_tile(true, false) # standing, face-down
		tile.name = "OppTile_1_%d" % i
		tile.position = Vector3(start_x1 + float(i) * TILE_PITCH, ROW_Y[1], ROW_Z[1])
		tile.rotation_degrees = Vector3(TILT_DEG, 0.0, 0.0)
		_tiles_container.add_child(tile)
		_tile_nodes.append(tile)
