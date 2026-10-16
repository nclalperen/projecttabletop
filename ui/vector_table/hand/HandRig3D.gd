## Camera-attached Hand Rig for Okey 101.
## Houses the 2-shelf walnut rack mesh and calculates slot transforms in 3D camera-relative space.
## Slots 0..14: Row 0 (Top Shelf).
## Slots 15..29: Row 1 (Bottom Shelf).
class_name HandRig3D
extends Node3D

const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")
const HandRackMesh = preload("res://ui/vector_table/hand/HandRackMesh.gd")

var _rack_mesh: HandRackMesh = null
var _row_tiles: Array = [[], []]


func _init() -> void:
	name = "HandRig"
	position = TUNING.HAND_RIG_ORIGIN
	rotation_degrees = TUNING.HAND_RIG_ROT_DEG

	_rack_mesh = HandRackMesh.new()
	add_child(_rack_mesh)


func slot_local_transform(slot: int) -> Transform3D:
	var s: int = clampi(slot, 0, TUNING.TOTAL_HAND_SLOTS - 1)
	var row_idx: int = 0 if s < TUNING.SLOTS_PER_ROW else 1
	var col: int = s % TUNING.SLOTS_PER_ROW

	# Symmetric about x = 0 (col 7 is center: x = 0.0)
	var x: float = (float(col) - 7.0) * TUNING.TILE_PITCH
	var y: float = TUNING.ROW_LOCAL_Y[row_idx]
	var z: float = -0.012 if row_idx == 0 else 0.012

	var rot_basis := Basis.from_euler(Vector3(deg_to_rad(TUNING.TILE_STAND_TILT_DEG.x), 0.0, 0.0))
	return Transform3D(rot_basis, Vector3(x, y, z))


func slot_global_transform(slot: int) -> Transform3D:
	var xform: Transform3D = global_transform if is_inside_tree() else transform
	return xform * slot_local_transform(slot)


func nearest_slot(global_point: Vector3) -> int:
	var xform: Transform3D = global_transform if is_inside_tree() else transform
	var local_pt: Vector3 = xform.affine_inverse() * global_point

	# Determine row based on closest Y
	var d0: float = absf(local_pt.y - TUNING.ROW_LOCAL_Y[0])
	var d1: float = absf(local_pt.y - TUNING.ROW_LOCAL_Y[1])
	var row_idx: int = 0 if d0 <= d1 else 1

	# Determine column based on X
	var col_float: float = (local_pt.x / TUNING.TILE_PITCH) + 7.0
	var col: int = clampi(int(roundf(col_float)), 0, TUNING.SLOTS_PER_ROW - 1)

	return row_idx * TUNING.SLOTS_PER_ROW + col
