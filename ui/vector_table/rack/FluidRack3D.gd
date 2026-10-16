## Continuous 3D Vector Rack for Okey 101.
## Completely replaces rigid 3D slot grids with continuous mathematical spring layouts
## and 3D Gaussian push-aside kinematics in real world space.
class_name FluidRack3D
extends Node3D

signal tile_action_requested(tile: VectorTile3D, action: StringName)

const SPRING3D = preload("res://ui/vector_table/math/SpringSolver3D.gd")
const TABLE_ART = preload("res://ui/game_table/OkeyTableArt.gd")
const VectorTile3D = preload("res://ui/vector_table/render/VectorTile3D.gd")

const RACK_LENGTH: float = 0.82
const RACK_HEIGHT: float = 0.072
const RACK_DEPTH: float = 0.15

# Continuous 3D Rail Anchors
const ROW_COUNT: int = 2
const MAX_TILES_PER_ROW: int = 15
const TILE_PITCH: float = 0.052 # 52mm pitch along X axis

const ROW_Y: Array[float] = [0.080, 0.033]
const ROW_Z: Array[float] = [-0.028, 0.034]
const ROW_ROT_DEG: Vector3 = Vector3(-28.0, 0.0, 0.0)

var _row_tiles: Array[Array] = [[], []]
var _active_drag_tile: VectorTile3D = null
var _hovered_row: int = -1
var _insertion_index: int = -1

var _rack_mesh: Node3D = null


func _init() -> void:
	pass


func _ready() -> void:
	_build_rack_mesh()


func _build_rack_mesh() -> void:
	if _rack_mesh != null:
		_rack_mesh.queue_free()
	_rack_mesh = TABLE_ART.build_rack(RACK_LENGTH, RACK_HEIGHT, RACK_DEPTH)
	_rack_mesh.name = "SculptedWalnutRack"
	add_child(_rack_mesh)


func clear_rack() -> void:
	for row in _row_tiles:
		for tile in row:
			if is_instance_valid(tile):
				tile.queue_free()
		row.clear()
	_active_drag_tile = null


func set_tiles(tiles_data: Array) -> void:
	clear_rack()
	var row_idx := 0
	for data in tiles_data:
		var tile := VectorTile3D.new()
		tile.setup_tile(
			data.get("unique_id", -1),
			data.get("number", 1),
			data.get("color", 0),
			data.get("kind", 0) != 0,
			true,
			true
		)
		tile.is_valid_meld = bool(data.get("is_valid", false))
		add_child(tile)

		if _row_tiles[row_idx].size() >= MAX_TILES_PER_ROW:
			row_idx = mini(row_idx + 1, ROW_COUNT - 1)
		_row_tiles[row_idx].append(tile)

	layout_tiles_3d(true)


func layout_tiles_3d(snap_immediate: bool = false, held_tile: VectorTile3D = null, pointer_pos: Vector3 = Vector3.ZERO) -> void:
	for row_idx in range(ROW_COUNT):
		var row: Array = _row_tiles[row_idx]
		var count: int = row.size()
		if count == 0:
			continue

		var row_y: float = ROW_Y[row_idx]
		var row_z: float = ROW_Z[row_idx]
		var start_x: float = -((count - 1) * TILE_PITCH) * 0.5

		for i in range(count):
			var tile: VectorTile3D = row[i]
			if tile == held_tile:
				continue

			var base_x: float = start_x + (i * TILE_PITCH)
			var target_pos := Vector3(base_x, row_y, row_z)

			# If a tile is being dragged in this row, apply 3D Gaussian push-aside displacement
			if held_tile != null and _hovered_row == row_idx:
				var push: Vector3 = SPRING3D.gaussian_push_3d(target_pos, pointer_pos, Vector3.RIGHT, 0.038, 0.050)
				target_pos += push

			tile.set_target_position_3d(target_pos, snap_immediate)
			tile.set_target_rotation_3d(ROW_ROT_DEG, snap_immediate)


func notify_drag_motion(held_tile: VectorTile3D, local_hit_pos: Vector3) -> void:
	_active_drag_tile = held_tile
	# Detect row proximity along Z
	var d0: float = absf(local_hit_pos.z - ROW_Z[0])
	var d1: float = absf(local_hit_pos.z - ROW_Z[1])
	_hovered_row = 0 if d0 < d1 else 1

	# Find insertion index along continuous X
	var row: Array = _row_tiles[_hovered_row]
	_insertion_index = row.size()
	for i in range(row.size()):
		var tile: VectorTile3D = row[i]
		if tile != held_tile and local_hit_pos.x < tile.position.x:
			_insertion_index = i
			break

	layout_tiles_3d(false, held_tile, local_hit_pos)


func commit_drag_drop(held_tile: VectorTile3D) -> void:
	if _active_drag_tile == held_tile:
		for row in _row_tiles:
			row.erase(held_tile)

		var target_row: int = clampi(_hovered_row, 0, ROW_COUNT - 1)
		var row: Array = _row_tiles[target_row]
		var idx: int = clampi(_insertion_index, 0, row.size())
		row.insert(idx, held_tile)

		_active_drag_tile = null
		_hovered_row = -1
		_insertion_index = -1
		layout_tiles_3d(false)
