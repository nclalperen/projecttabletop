## Frozen 3D coordinates, camera framing, and mathematical animation constants
## for the Okey 101 3D Vector Table.
extends RefCounted

# ─── Table & Felt Dimensions (metres) ───
const TABLE_SURFACE_Y: float = 0.075
const TABLE_WIDTH: float = 1.26
const TABLE_DEPTH: float = 1.04
const FELT_HALF_X: float = 0.579
const FELT_HALF_Z: float = 0.469

# ─── World Positions (D5) ───
const STOCK_POS_3D: Vector3 = Vector3(-0.035, TABLE_SURFACE_Y, -0.030)
const STOCK_ROT_DEG: Vector3 = Vector3(0.0, 8.0, 0.0)

const INDICATOR_POS_3D: Vector3 = Vector3(0.035, TABLE_SURFACE_Y + 0.0045, -0.030)
const INDICATOR_ROT_DEG: Vector3 = Vector3(0.0, 85.0, 0.0)

const OPPONENT_RACK_POS_3D: Dictionary = {
	1: Vector3(0.515, TABLE_SURFACE_Y, -0.040),
	2: Vector3(0.000, TABLE_SURFACE_Y, -0.385),
	3: Vector3(-0.505, TABLE_SURFACE_Y, -0.055),
}

const OPPONENT_RACK_ROT_DEG: Dictionary = {
	1: Vector3(0.0, 90.0, 0.0),
	2: Vector3(0.0, 180.0, 0.0),
	3: Vector3(0.0, -90.0, 0.0),
}
const OPPONENT_RACK_SCALE: float = 0.700

const DISCARD_POS_3D: Dictionary = {
	0: Vector3(0.397, TABLE_SURFACE_Y, 0.245),
	1: Vector3(0.382, TABLE_SURFACE_Y, -0.334),
	2: Vector3(-0.380, TABLE_SURFACE_Y, -0.331),
	3: Vector3(-0.384, TABLE_SURFACE_Y, 0.249),
}

const DISCARD_ROT_DEG: Dictionary = {
	0: Vector3(0.0, -0.0, 0.0),
	1: Vector3(0.0, 90.0, 0.0),
	2: Vector3(0.0, -180.0, 0.0),
	3: Vector3(0.0, -92.0, 0.0),
}

const MELD_ZONE_MIN: Vector2 = Vector2(-0.44, -0.30)
const MELD_ZONE_MAX: Vector2 = Vector2(0.44, 0.20)

const MELD_AREA_POS_3D: Dictionary = {
	0: Vector3(0.000103279948234558, TABLE_SURFACE_Y, 0.172943711280823),
	1: Vector3(0.355, TABLE_SURFACE_Y, -0.020),
	2: Vector3(0.000, TABLE_SURFACE_Y, -0.235),
	3: Vector3(-0.355, TABLE_SURFACE_Y, -0.020),
}

const MELD_AREA_ROT_DEG: Dictionary = {
	0: Vector3(0.0, 0.0, 0.0),
	1: Vector3(0.0, 90.0, 0.0),
	2: Vector3(0.0, 180.0, 0.0),
	3: Vector3(0.0, -90.0, 0.0),
}

const MELD_AREA_SIZE: Dictionary = {
	0: Vector2(0.450, 0.210),
	1: Vector2(0.370, 0.255),
	2: Vector2(0.450, 0.210),
	3: Vector2(0.370, 0.255),
}

# ─── Camera Framing (D6) ───
const CAMERA_FOV: float = 40.0
const CAMERA_POS: Vector3 = Vector3(0.000, 1.070, 0.800)
const CAMERA_LOOK_AT: Vector3 = Vector3(0.000, -0.025, 0.025)

# ─── Hand Rig (Camera-Local Space, D7) ───
const HAND_RIG_ORIGIN: Vector3 = Vector3(0.000, -0.218, -1.010)
const HAND_RIG_ROT_DEG: Vector3 = Vector3(11.0, 0.0, 0.0)

const HAND_RACK_LENGTH: float = 0.80
const HAND_RACK_DEPTH: float = 0.07
const HAND_RACK_BACK_HEIGHT: float = 0.10
const HAND_RACK_SHELF_DEPTH: float = 0.022
const HAND_RACK_FRONT_LIP: float = 0.006

const TILE_PITCH: float = 0.050
const ROW_COUNT: int = 2
const SLOTS_PER_ROW: int = 15
const TOTAL_HAND_SLOTS: int = 30

const ROW_LOCAL_Y: Array[float] = [0.03307, -0.02921]
const ROW_LOCAL_Z: Array[float] = [0.00565, 0.02679]
const ROW_TILT_DEG: Array[float] = [-10.0, -10.0]
const TILE_STAND_TILT_DEG: Vector3 = Vector3(-10.0, 0.0, 0.0)


# ─── Animation & Kinematics Tuning (D8) ───
# Springs
const RACK_SPRING_OMEGA: float = 26.0
const RACK_SPRING_ZETA: float = 0.78

const HOVER_LIFT_Y: float = 0.012
const HOVER_SPRING_OMEGA: float = 30.0
const HOVER_SPRING_ZETA: float = 0.70

const DRAG_SPRING_OMEGA: float = 38.0
const DRAG_SPRING_ZETA: float = 0.85

const DRAG_TILT_SENSITIVITY: float = 6.0
const DRAG_TILT_MAX_DEG: float = 14.0

const PUSH_ASIDE_AMPLITUDE: float = 0.022
const PUSH_ASIDE_SIGMA: float = 0.040

# Bezier flights
const FLIGHT_DRAW_DURATION_SEC: float = 0.42
const FLIGHT_DRAW_APEX_Y: float = 0.12

const FLIGHT_DISCARD_DURATION_SEC: float = 0.36
const FLIGHT_DISCARD_APEX_Y: float = 0.08
const FLIGHT_DISCARD_YAW_JITTER_DEG: float = 6.0

const FLIGHT_OPPONENT_DISCARD_DURATION_SEC: float = 0.40

const FLIGHT_MELD_STAGGER_SEC: float = 0.05
const FLIGHT_MELD_DURATION_SEC: float = 0.32

const INVALID_DROP_SHAKE_CYCLES: int = 3
const INVALID_DROP_SHAKE_AMPLITUDE_M: float = 0.004
