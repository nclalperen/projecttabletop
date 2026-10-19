class_name OpponentRack3D
extends Node3D
## Procedural 3D Opponent Rack for VectorGameTable3D.
## Faithfully crafted to match the iconic Hedef Okey wooden istaka:
## - Natural blonde beech wood with subtle linear grain and satin sheen
## - Solid flat backboard with centered Hedef maker emblem facing the table
## - Iconic dark brown triangular end cap brackets with flush mounting rivets
## - Concealed opponent tiles sitting on authentic stepped shelves inside the rack

const TABLE_ART = preload("res://ui/game_table/OkeyTableArt.gd")
const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")
const VectorRackBuilder = preload("res://ui/vector_table/render/VectorRackBuilder.gd")

const TILE_PITCH: float = TUNING.TILE_PITCH

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
	# Front/table-facing point of rack in world coordinates for flight animations
	var local_launch := Vector3(0.0, 0.06, -0.03)
	var xf := global_transform if is_inside_tree() else transform
	return Transform3D(xf.basis.orthonormalized(), xf.origin + xf.basis * local_launch)


func _build_mesh() -> void:
	for child in get_children():
		child.queue_free()
	_tile_nodes.clear()

	_rack_mesh = Node3D.new()
	_rack_mesh.name = "RackGeometry"
	add_child(_rack_mesh)

	var beech := TABLE_ART.material("honey_beech")
	var badge_mat := TABLE_ART.material("hedef_badge")
	var gold := TABLE_ART.material("rack_badge")

	var width: float = TUNING.HAND_RACK_LENGTH

	# 1. Pure procedural Vector Rack Mesh
	var rack_mesh: ArrayMesh = VectorRackBuilder.build_mesh(width, beech)
	if rack_mesh != null:
		var rack_inst := MeshInstance3D.new()
		rack_inst.name = "VectorRackMesh"
		rack_inst.mesh = rack_mesh
		rack_inst.set_surface_override_material(0, beech)
		# Base rests directly on table surface at Y = 0
		rack_inst.position = Vector3.ZERO
		_rack_mesh.add_child(rack_inst)

	# 2. Iconic Hedef Centered Oval Maker Badge lying flush on sloped back wall (-Z)
	var plate := TABLE_ART.piece(_rack_mesh, "HedefBadgePlate", Vector3(0.056, 0.018, 0.0015), Vector3(0.0, 0.067, -0.0290), 0.001, badge_mat)
	plate.rotation_degrees.x = 14.0
	var ring := TABLE_ART.piece(_rack_mesh, "HedefBadgeGold", Vector3(0.052, 0.014, 0.002), Vector3(0.0, 0.067, -0.0293), 0.0008, gold)
	ring.rotation_degrees.x = 14.0

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

	# Keep bottom face 100% flush on shelf floor while lowering top edge by 9.75mm below crest
	var u_dir := Vector3(0.0, cos(deg_to_rad(VectorRackBuilder.LEAN_DEG)), -sin(deg_to_rad(VectorRackBuilder.LEAN_DEG)))
	var sy: float = 0.85
	var flush_shift: float = (1.0 - sy) * 0.5 * 0.065

	# Row 0 (top/rear shelf)
	var start_x0 := -(float(row0_count - 1) * 0.5) * TILE_PITCH if row0_count > 0 else 0.0
	for i in range(row0_count):
		var tile := TABLE_ART.build_tile(true, false) # standing, face-down
		tile.name = "OppTile_0_%d" % i
		var xf := VectorRackBuilder.row_transform(0, start_x0 + float(i) * TILE_PITCH)
		xf.origin -= u_dir * flush_shift
		tile.transform = xf
		tile.scale = Vector3(1.0, sy, 1.0)
		_tiles_container.add_child(tile)
		_tile_nodes.append(tile)

	# Row 1 (bottom/front shelf)
	var start_x1 := -(float(row1_count - 1) * 0.5) * TILE_PITCH if row1_count > 0 else 0.0
	for i in range(row1_count):
		var tile := TABLE_ART.build_tile(true, false) # standing, face-down
		tile.name = "OppTile_1_%d" % i
		var xf := VectorRackBuilder.row_transform(1, start_x1 + float(i) * TILE_PITCH)
		xf.origin -= u_dir * flush_shift
		tile.transform = xf
		tile.scale = Vector3(1.0, sy, 1.0)
		_tiles_container.add_child(tile)
		_tile_nodes.append(tile)
