class_name OpponentRack3D
extends Node3D
## Procedural 3D Opponent Rack for VectorGameTable3D.
## Authentic Turkish coffeehouse craftsmanship:
## - Rich golden honey-beech wood with natural grain and satin lacquer sheen
## - Solid tall backboard with center brass maker plaque facing the table (Image 2 & 3)
## - Iconic cream enamel end brackets with brass rivets (Image 3)
## - Opponent tiles concealed completely behind the wooden backboard

const TABLE_ART = preload("res://ui/game_table/OkeyTableArt.gd")
const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")

const TILE_PITCH: float = 0.040
const ROW_Y: Array[float] = [0.032, 0.002]
const ROW_Z: Array[float] = [0.010, 0.038]
const TILT_DEG: float = 6.0 # Leans back against the backboard (towards -Z)

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
	var beech_edge := TABLE_ART.material("honey_beech_edge")
	var beech_dark := TABLE_ART.material("honey_beech_dark")
	var bracket_cream := TABLE_ART.material("rack_bracket_cream")
	var brass_screw := TABLE_ART.material("bracket_screw")
	var brass := TABLE_ART.material("brass_inlay")
	var gold := TABLE_ART.material("rack_badge")

	var width: float = 0.65

	# 1. Solid Honey-Beech Backboard (faces -Z into the table, completely hiding tiles)
	# 0.102m tall ensures tiles (0.065m) are 100% concealed from table view
	TABLE_ART.piece(_rack_mesh, "SolidBackboard", Vector3(width - 0.016, 0.102, 0.016), Vector3(0.0, 0.038, -0.016), 0.004, beech)

	# 2. Polished Brass Center Maker Plaque facing table (Image 2 & 3)
	TABLE_ART.piece(_rack_mesh, "BackMakerPlaque", Vector3(0.046, 0.012, 0.002), Vector3(0.0, 0.042, -0.025), 0.0008, gold)

	# 3. Solid Honey-Beech Foundation Base sitting on table
	TABLE_ART.piece(_rack_mesh, "SolidBase", Vector3(width - 0.012, 0.024, 0.076), Vector3(0.0, 0.008, 0.018), 0.005, beech)

	# 4. Shelves facing opponent (+Z)
	TABLE_ART.piece(_rack_mesh, "UpperBed", Vector3(width - 0.024, 0.006, 0.022), Vector3(0.0, 0.028, 0.010), 0.002, beech_dark)
	TABLE_ART.piece(_rack_mesh, "UpperLip", Vector3(width - 0.020, 0.007, 0.005), Vector3(0.0, 0.033, 0.022), 0.0015, beech_edge)
	TABLE_ART.piece(_rack_mesh, "LowerBed", Vector3(width - 0.024, 0.006, 0.022), Vector3(0.0, -0.002, 0.038), 0.002, beech_dark)
	TABLE_ART.piece(_rack_mesh, "LowerLip", Vector3(width - 0.020, 0.007, 0.005), Vector3(0.0, 0.003, 0.050), 0.0015, beech_edge)

	# 5. Iconic Triangular End Caps with Cream Brackets & Brass Screws (Image 3)
	for side in [-1.0, 1.0]:
		var prefix: String = "L" if side < 0.0 else "R"
		var side_x: float = side * (width * 0.5 - 0.007)

		TABLE_ART.piece(_rack_mesh, "EndCap_%s" % prefix, Vector3(0.014, 0.108, 0.082), Vector3(side_x, 0.035, 0.014), 0.005, beech)
		TABLE_ART.piece(_rack_mesh, "Bracket_%s" % prefix, Vector3(0.0025, 0.080, 0.058), Vector3(side_x + side * 0.0082, 0.035, 0.014), 0.0025, bracket_cream)
		TABLE_ART.piece(_rack_mesh, "BracketTop_%s" % prefix, Vector3(0.015, 0.003, 0.038), Vector3(side_x, 0.088, -0.004), 0.0015, bracket_cream)
		TABLE_ART.piece(_rack_mesh, "ScrewTop_%s" % prefix, Vector3(0.003, 0.006, 0.006), Vector3(side_x + side * 0.0094, 0.062, -0.004), 0.002, brass_screw)
		TABLE_ART.piece(_rack_mesh, "ScrewBottom_%s" % prefix, Vector3(0.003, 0.006, 0.006), Vector3(side_x + side * 0.0094, 0.012, 0.028), 0.002, brass_screw)

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
