class_name InteractionTuning
extends RefCounted

# Shared interaction tuning to keep 2D and 3D behavior aligned.
const DRAG_THRESHOLD_MOUSE_PX: float = 6.0
const DRAG_THRESHOLD_TOUCH_PX: float = 12.0
const DRAG_START_DISTANCE_3D_PX: float = 3.0

const DRAFT_LANE_MARGIN_2D_PX: float = 26.0
const DRAFT_LANE_MARGIN_3D: float = 0.040

const DISCARD_DRAG_HIT_MARGIN_3D: float = 0.022
const DISCARD_TAP_HIT_MARGIN_3D: float = 0.020
const DISCARD_TAP_SCREEN_MARGIN_3D_PX: float = 28.0

const DRAW_TAP_HIT_MARGIN_3D: float = 0.020
const DRAW_TAP_SCREEN_MARGIN_3D_PX: float = 26.0

const PICK_RADIUS_3D_PX: float = 42.0
const DRAG_PICK_RADIUS_3D_PX: float = 84.0
const SLOT_PICK_RADIUS_3D_PX: float = 180.0

static func drag_threshold_for_pointer(is_touch: bool) -> float:
	return DRAG_THRESHOLD_TOUCH_PX if is_touch else DRAG_THRESHOLD_MOUSE_PX

static func drag_start_distance_3d_px() -> float:
	return DRAG_START_DISTANCE_3D_PX
