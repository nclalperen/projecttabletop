class_name RackView3D
extends Node3D

const RACK_SLOT_MANAGER = preload("res://ui/game_table/RackSlotManager.gd")

const TOTAL_SLOTS: int = 30
const SLOTS_PER_ROW: int = 15
const DEFAULT_RACK_LEN: float = 0.82
const DEFAULT_USABLE_LEN: float = 0.748

var row0_anchor: Vector3 = Vector3(0.0, 0.086, -0.033)
var row1_anchor: Vector3 = Vector3(0.0, 0.047, 0.039)
var row0_seat_offset: Vector3 = Vector3.ZERO
var row1_seat_offset: Vector3 = Vector3.ZERO
var row0_tilt_deg: float = -35.0
var row1_tilt_deg: float = -35.0
var usable_length: float = DEFAULT_USABLE_LEN

func configure_rows(
	p_row0_anchor: Vector3,
	p_row1_anchor: Vector3,
	p_row0_tilt_deg: float,
	p_row1_tilt_deg: float,
	p_usable_length: float = DEFAULT_USABLE_LEN,
	p_row0_offset: Vector3 = Vector3.ZERO,
	p_row1_offset: Vector3 = Vector3.ZERO
) -> void:
	row0_anchor = p_row0_anchor
	row1_anchor = p_row1_anchor
	row0_tilt_deg = p_row0_tilt_deg
	row1_tilt_deg = p_row1_tilt_deg
	usable_length = maxf(0.20, p_usable_length)
	row0_seat_offset = p_row0_offset
	row1_seat_offset = p_row1_offset

func get_slot_spacing() -> float:
	return usable_length / float(SLOTS_PER_ROW)

func compute_slot_local_position(slot_index: int, reflow_offset_x: float = 0.0) -> Vector3:
	var clamped: int = clampi(slot_index, 0, TOTAL_SLOTS - 1)
	var is_top_row: bool = clamped < SLOTS_PER_ROW
	var col: int = clamped if is_top_row else (clamped - SLOTS_PER_ROW)
	var spacing: float = get_slot_spacing()
	var start_x: float = -usable_length * 0.5 + spacing * 0.5
	var x: float = start_x + float(col) * spacing + reflow_offset_x
	if is_top_row:
		return Vector3(x, row0_anchor.y, row0_anchor.z) + row0_seat_offset
	return Vector3(x, row1_anchor.y, row1_anchor.z) + row1_seat_offset

func compute_slot_world_position(rack_node: Node3D, slot_index: int, lift_y: float = 0.0, reflow_offset_x: float = 0.0) -> Vector3:
	var local_pos: Vector3 = compute_slot_local_position(slot_index, reflow_offset_x)
	var world_pos: Vector3 = rack_node.to_global(local_pos) if rack_node != null else to_global(local_pos)
	world_pos.y += lift_y
	return world_pos

func get_slot_row_tilt_deg(slot_index: int) -> float:
	return row0_tilt_deg if slot_index < SLOTS_PER_ROW else row1_tilt_deg

func compute_neighbor_reflow_offsets(slots_arr: Array, drag_slot: int, hovered_slot: int) -> Dictionary:
	var raw_shifts: Dictionary = RACK_SLOT_MANAGER.calculate_reflow(slots_arr, drag_slot, hovered_slot)
	var step_x: float = get_slot_spacing()
	var offsets: Dictionary = {}
	for slot_idx in raw_shifts.keys():
		offsets[int(slot_idx)] = float(raw_shifts[slot_idx]) * step_x
	return offsets
