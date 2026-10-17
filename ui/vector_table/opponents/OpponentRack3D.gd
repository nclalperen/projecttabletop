class_name OpponentRack3D
extends Node3D
## Procedural 3D Opponent Rack for VectorGameTable3D.
## Built directly from authentic Turkish coffeehouse Okey istaka CAD geometry (AssetIds.GAMEPLAY_MODEL_AUTHENTIC_STAKA):
## - Rich golden honey-beech wood with natural grain rings and satin lacquer sheen
## - Solid tall backboard with center brass maker plaque facing the table
## - Concealed opponent tiles sitting on authentic stepped shelves inside the rack
## - Delicate brass mounting rivets on solid wooden end caps

const TABLE_ART = preload("res://ui/game_table/OkeyTableArt.gd")
const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")

const TILE_PITCH: float = 0.040
const ROW_Y: Array[float] = [0.0835, 0.0357]
const ROW_Z: Array[float] = [-0.0100, 0.0200]
const ROW_TILT: Array[float] = [-20.0, -33.4]

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
	var local_launch := Vector3(0.0, 0.05, -0.04)
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
	var brass_screw := TABLE_ART.material("bracket_screw")
	var gold := TABLE_ART.material("rack_badge")

	var width: float = 0.65

	# 1. Authentic Turkish Istaka CAD Mesh
	var staka_mesh: Mesh = AssetRegistry.mesh(AssetIds.GAMEPLAY_MODEL_AUTHENTIC_STAKA)
	if staka_mesh != null:
		var staka_inst := MeshInstance3D.new()
		staka_inst.name = "AuthenticStakaMesh"
		staka_inst.mesh = staka_mesh
		staka_inst.set_surface_override_material(0, beech)
		# Mesh natural length is 0.376362. Scale X to desired width (0.65) while preserving CAD height & profile
		staka_inst.scale = Vector3(width / 0.376362, 1.0, 1.0)
		# Base rests directly on table surface at Y = 0
		staka_inst.position = Vector3.ZERO
		_rack_mesh.add_child(staka_inst)

	# 2. Solid Furniture-Grade Honey-Beech Backboard facing table (-Z)
	TABLE_ART.piece(_rack_mesh, "SolidBackboard", Vector3(width - 0.004, 0.086, 0.010), Vector3(0.0, 0.043, -0.033), 0.003, beech)

	# 3. Polished Brass Center Maker Plaque facing table (-Z)
	TABLE_ART.piece(_rack_mesh, "BackMakerPlaque", Vector3(0.046, 0.012, 0.002), Vector3(0.0, 0.045, -0.0385), 0.0008, gold)

	# 4. Delicate Brass Mounting Rivets on Solid Wooden End Caps
	for side in [-1.0, 1.0]:
		var prefix: String = "L" if side < 0.0 else "R"
		var side_x: float = side * (width * 0.5 - 0.001)

		TABLE_ART.piece(_rack_mesh, "ScrewTop_%s" % prefix, Vector3(0.002, 0.004, 0.004), Vector3(side_x + side * 0.0008, 0.068, -0.015), 0.001, brass_screw)
		TABLE_ART.piece(_rack_mesh, "ScrewBottom_%s" % prefix, Vector3(0.002, 0.004, 0.004), Vector3(side_x + side * 0.0008, 0.020, 0.022), 0.001, brass_screw)

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
		tile.rotation_degrees = Vector3(ROW_TILT[0], 0.0, 0.0)
		_tiles_container.add_child(tile)
		_tile_nodes.append(tile)

	# Row 1 (bottom/front shelf)
	var start_x1 := -(float(row1_count - 1) * 0.5) * TILE_PITCH if row1_count > 0 else 0.0
	for i in range(row1_count):
		var tile := TABLE_ART.build_tile(true, false) # standing, face-down
		tile.name = "OppTile_1_%d" % i
		tile.position = Vector3(start_x1 + float(i) * TILE_PITCH, ROW_Y[1], ROW_Z[1])
		tile.rotation_degrees = Vector3(ROW_TILT[1], 0.0, 0.0)
		_tiles_container.add_child(tile)
		_tile_nodes.append(tile)
