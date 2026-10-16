class_name DraftWorkspaceView3D
extends Node3D

const DRAFT_GRID = preload("res://ui/game_table/DraftGrid.gd")

const DEFAULT_TOTAL_SLOTS: int = 24
const DEFAULT_ROW_SLOTS: int = 12
const TILE_D: float = 0.009

var lane_rect: Rect2 = Rect2(Vector2(-0.33, 0.11), Vector2(0.66, 0.15))
var total_slots: int = DEFAULT_TOTAL_SLOTS
var row_slots: int = DEFAULT_ROW_SLOTS

func configure_lane(rect: Rect2, p_total_slots: int = DEFAULT_TOTAL_SLOTS, p_row_slots: int = DEFAULT_ROW_SLOTS) -> void:
	lane_rect = rect
	total_slots = maxi(1, p_total_slots)
	row_slots = maxi(1, p_row_slots)

func slot_to_table_point(slot_index: int) -> Vector2:
	var clamped: int = clampi(slot_index, 0, total_slots - 1)
	return DRAFT_GRID.slot_to_point(clamped, lane_rect, total_slots, row_slots)

func slot_to_world_position(slot_index: int, table_surface_y: float = 0.0375, extra_lift: float = 0.0007) -> Vector3:
	var pt: Vector2 = slot_to_table_point(slot_index)
	return Vector3(pt.x, table_surface_y + TILE_D * 0.5 + extra_lift, pt.y)

func point_to_nearest_slot(table_point: Vector2) -> int:
	var best_slot: int = 0
	var best_dist_sq: float = INF
	for i in range(total_slots):
		var cell_pt: Vector2 = slot_to_table_point(i)
		var d2: float = table_point.distance_squared_to(cell_pt)
		if d2 < best_dist_sq:
			best_dist_sq = d2
			best_slot = i
	return best_slot
