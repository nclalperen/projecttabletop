## FROZEN: Geometry constants and projection math for the 2D GameTable.
## Do NOT modify values without a migration plan. See docs/README_DEV.md.
##
## All board composition — perspective trapezoid, felt sizing, opponent badges,
## center zone, discard placement — derives from the constants below.
class_name TableGeometry
extends RefCounted

# ─── Slot counts ───
const RACK_SLOT_COUNT: int = 30
const RACK_ROW_SLOTS: int = 15
const STAGE_SLOT_COUNT: int = 24
const STAGE_ROW_SLOTS: int = 12

# ─── UI dimension bounds ───
const DISCARD_ZONE_SIZE: Vector2 = Vector2(66, 90)
const TOP_BAR_HEIGHT: float = 58.0
const OUTER_MARGIN: float = 14.0
const RACK_MIN_HEIGHT: float = 122.0
const RACK_MAX_HEIGHT: float = 248.0
const TABLE_MIN_HEIGHT: float = 340.0
const TABLE_MAX_HEIGHT: float = 980.0
const BOTTOM_RACK_GAP: float = 14.0
const BOTTOM_PADDING: float = 18.0
const SHOW_TABLE_RAILS: bool = false
const SHOW_WALL_RING: bool = false

# ─── Perspective trapezoid (pseudo-3D seated POV) ───
const PERSPECTIVE_FAR_WIDTH_RATIO: float = 0.76
const PERSPECTIVE_NEAR_WIDTH_RATIO: float = 0.95
const PERSPECTIVE_TOP_Y_RATIO: float = 0.12
const PERSPECTIVE_BOTTOM_Y_RATIO: float = 0.95

# ─── Felt sizing contract ───
const FELT_WIDTH_RATIO: float = 0.86
const FELT_HEIGHT_RATIO: float = 0.86
const FELT_MIN_WIDTH: float = 700.0
const FELT_MIN_HEIGHT: float = 360.0
const FELT_MIN_SIDE: float = 360.0
const FELT_SIDE_INSET_MAX: float = 150.0
const FELT_BOTTOM_INSET_MAX: float = 92.0
const FELT_TOP_MARGIN_MIN: float = 12.0
const FELT_BOTTOM_MARGIN_MIN: float = 12.0
const FELT_VERTICAL_BIAS: float = 0.46

# ─── Meld island insets ───
const MELD_ISLAND_INSET_X: float = 14.0
const MELD_ISLAND_INSET_TOP: float = 20.0
const MELD_ISLAND_INSET_BOTTOM: float = 10.0

# ─── Center zone (draw deck + indicator) ───
const CENTER_ZONE_WIDTH_RATIO: float = 0.20
const CENTER_ZONE_HEIGHT_RATIO: float = 0.15
const CENTER_ZONE_MIN_WIDTH: float = 184.0
const CENTER_ZONE_MAX_WIDTH: float = 286.0
const CENTER_ZONE_MIN_HEIGHT: float = 70.0
const CENTER_ZONE_MAX_HEIGHT: float = 104.0
const CENTER_ZONE_ANCHOR_X: float = 0.58
const CENTER_ZONE_ANCHOR_Y: float = 0.40

# ─── Opponent badge sizing ───
const OPP_BADGE_SIDE_WIDTH_RATIO: float = 0.16
const OPP_BADGE_SIDE_HEIGHT_RATIO: float = 0.138
const OPP_BADGE_SIDE_MIN_WIDTH: float = 170.0
const OPP_BADGE_SIDE_MAX_WIDTH: float = 238.0
const OPP_BADGE_SIDE_MIN_HEIGHT: float = 72.0
const OPP_BADGE_SIDE_MAX_HEIGHT: float = 106.0
const OPP_BADGE_TOP_WIDTH_RATIO: float = 1.06
const OPP_BADGE_TOP_HEIGHT_RATIO: float = 0.96
const OPP_BADGE_SIDE_ANCHOR_T: float = 0.60
const OPP_BADGE_TOP_MARGIN: float = 12.0

# ─── Discard and presentation ───
const DISCARD_ZONE_MARGIN: float = 14.0
const OPP_3D_SIDE_RACK_ROTATION_DEG: float = 28.0
const CLOTH_TEXTURE_PATH: String = "res://assets/cloth-texture.png"

# ─── Visual styling ───
const OPP_COLORS: Array[Color] = [
	Color(0.65, 0.22, 0.18),  # P1 - reddish
	Color(0.18, 0.42, 0.65),  # P2 - blue
	Color(0.55, 0.45, 0.18),  # P3 - amber
]
const AMBIENT_PULSE_SPEED: float = 1.35
const AMBIENT_DRIFT_SPEED: float = 0.58
const TABLE_GRAIN_LINES: int = 14

# ═══════════════════════════════════════════
# PROJECTION MATH (pure functions)
# ═══════════════════════════════════════════

static func project_board_footprint(felt_x: float, felt_y: float, felt_w: float, felt_h: float) -> Dictionary:
	var proj_top_y: float = felt_y + felt_h * PERSPECTIVE_TOP_Y_RATIO
	var proj_bottom_y: float = felt_y + felt_h * PERSPECTIVE_BOTTOM_Y_RATIO
	var proj_top_w: float = felt_w * PERSPECTIVE_FAR_WIDTH_RATIO
	var proj_bottom_w: float = felt_w * PERSPECTIVE_NEAR_WIDTH_RATIO
	var proj_top_x: float = felt_x + (felt_w - proj_top_w) * 0.5
	var proj_bottom_x: float = felt_x + (felt_w - proj_bottom_w) * 0.5
	return {
		"top_left": Vector2(proj_top_x, proj_top_y),
		"top_right": Vector2(proj_top_x + proj_top_w, proj_top_y),
		"bottom_left": Vector2(proj_bottom_x, proj_bottom_y),
		"bottom_right": Vector2(proj_bottom_x + proj_bottom_w, proj_bottom_y),
		"top_width": proj_top_w,
		"bottom_width": proj_bottom_w,
	}

static func build_table_anchor_contract(
	top_left: Vector2,
	top_right: Vector2,
	bottom_left: Vector2,
	bottom_right: Vector2,
	felt_w: float,
	felt_h: float,
	presentation_mode: String
) -> Dictionary:
	var center_w: float = clamp(felt_w * CENTER_ZONE_WIDTH_RATIO, CENTER_ZONE_MIN_WIDTH, CENTER_ZONE_MAX_WIDTH)
	var center_h: float = clamp(felt_h * CENTER_ZONE_HEIGHT_RATIO, CENTER_ZONE_MIN_HEIGHT, CENTER_ZONE_MAX_HEIGHT)
	if presentation_mode == "3d":
		center_w *= 0.84
		center_h *= 0.82
	var center_anchor: Vector2 = Vector2(
		lerpf(top_left.x, top_right.x, CENTER_ZONE_ANCHOR_X),
		lerpf(top_left.y, bottom_left.y, CENTER_ZONE_ANCHOR_Y - 0.02) if presentation_mode == "3d" else lerpf(top_left.y, bottom_left.y, CENTER_ZONE_ANCHOR_Y)
	)

	var side_badge_w: float = clamp(felt_w * OPP_BADGE_SIDE_WIDTH_RATIO, OPP_BADGE_SIDE_MIN_WIDTH, OPP_BADGE_SIDE_MAX_WIDTH)
	var side_badge_h: float = clamp(felt_h * OPP_BADGE_SIDE_HEIGHT_RATIO, OPP_BADGE_SIDE_MIN_HEIGHT, OPP_BADGE_SIDE_MAX_HEIGHT)
	var top_badge_w: float = side_badge_w * OPP_BADGE_TOP_WIDTH_RATIO
	var top_badge_h: float = side_badge_h * OPP_BADGE_TOP_HEIGHT_RATIO
	var top_badge_y: float = top_left.y + OPP_BADGE_TOP_MARGIN
	if presentation_mode == "3d":
		side_badge_w = clamp(side_badge_w * 1.04, 152.0, 214.0)
		side_badge_h = clamp(side_badge_h * 0.52, 42.0, 60.0)
		top_badge_w = clamp(top_badge_w * 1.02, 220.0, 300.0)
		top_badge_h = clamp(top_badge_h * 0.70, 42.0, 58.0)
		top_badge_y += 10.0

	var opp_rack_rects: Array = [
		Rect2(
			lerpf(top_right.x, bottom_right.x, OPP_BADGE_SIDE_ANCHOR_T) - side_badge_w * 0.5,
			lerpf(top_right.y, bottom_right.y, OPP_BADGE_SIDE_ANCHOR_T) - side_badge_h * 0.5,
			side_badge_w,
			side_badge_h
		),
		Rect2(
			(top_left.x + top_right.x) * 0.5 - top_badge_w * 0.5,
			top_badge_y,
			top_badge_w,
			top_badge_h
		),
		Rect2(
			lerpf(top_left.x, bottom_left.x, OPP_BADGE_SIDE_ANCHOR_T) - side_badge_w * 0.5,
			lerpf(top_left.y, bottom_left.y, OPP_BADGE_SIDE_ANCHOR_T) - side_badge_h * 0.5,
			side_badge_w,
			side_badge_h
		),
	]

	var discard_size: Vector2 = DISCARD_ZONE_SIZE
	if presentation_mode == "3d":
		discard_size *= 0.80

	var opp_discard_rects: Array = [
		Rect2(top_left.x + DISCARD_ZONE_MARGIN, top_left.y + DISCARD_ZONE_MARGIN, discard_size.x, discard_size.y),
		Rect2(top_right.x - discard_size.x - DISCARD_ZONE_MARGIN, top_right.y + DISCARD_ZONE_MARGIN, discard_size.x, discard_size.y),
		Rect2(bottom_left.x + DISCARD_ZONE_MARGIN, bottom_left.y - discard_size.y - DISCARD_ZONE_MARGIN, discard_size.x, discard_size.y),
	]

	var my_discard_local := Rect2(
		bottom_right.x - discard_size.x - DISCARD_ZONE_MARGIN,
		bottom_right.y - discard_size.y - DISCARD_ZONE_MARGIN,
		discard_size.x,
		discard_size.y
	)

	return {
		"center_size": Vector2(center_w, center_h),
		"center_anchor": center_anchor,
		"opp_rack_rects": opp_rack_rects,
		"opp_discard_rects": opp_discard_rects,
		"my_discard_local": my_discard_local,
	}

static func build_meld_owner_zones(max_w: float, max_h: float, pending_band_height: float) -> Dictionary:
	var pad: float = 8.0
	var far_inset: float = clamp(max_w * 0.22, 120.0, 240.0)
	var near_inset: float = clamp(max_w * 0.06, 28.0, 84.0)
	var top_h: float = clamp(max_h * 0.14, 58.0, 92.0)
	var mid_h: float = clamp(max_h * 0.12, 56.0, 90.0)
	var bottom_h: float = clamp(max_h * 0.15, 62.0, 98.0)
	var center_top_w: float = max(180.0, max_w - far_inset * 2.0)
	var center_bottom_w: float = max(220.0, max_w - near_inset * 2.0)
	var left_w: float = clamp(max_w * 0.16, 96.0, 160.0)

	var zones := {}
	zones[2] = Rect2((max_w - center_top_w) * 0.5, pad, center_top_w, top_h)
	zones[3] = Rect2(near_inset * 0.42, max_h * 0.44 - mid_h * 0.5, left_w, mid_h)
	zones[1] = Rect2(max_w - left_w - near_inset * 0.42, max_h * 0.44 - mid_h * 0.5, left_w, mid_h)
	var bottom_y: float = max_h - bottom_h - pending_band_height - 14.0
	bottom_y = clamp(bottom_y, top_h + 18.0, max_h - bottom_h - 8.0)
	zones[0] = Rect2((max_w - center_bottom_w) * 0.5, bottom_y, center_bottom_w, bottom_h)
	return zones

static func compute_round_seed(game_seed: int, round_index: int) -> int:
	if game_seed < 0:
		return int(randi()) + round_index
	return game_seed + round_index
