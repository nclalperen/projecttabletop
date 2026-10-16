## Configuration resource defining a single seat at a game table.
## Each seat describes its physical position, camera angle, rack placement,
## discard zone, and meld workspace area.
extends Resource
class_name SeatConfig

## Index of this seat (0 = local player by convention).
@export var seat_index: int = 0

## Human-readable label ("You", "East", "North", "West").
@export var label: String = "Player"

## Whether this seat is the local player's seat.
@export var is_local_player: bool = false

# ─── 3D World Placement ───

## Table-local 2D position of this seat's rack center (X, Z in world space).
@export var rack_position: Vector2 = Vector2.ZERO

## Y-axis rotation of the rack in degrees.
@export var rotation_y_deg: float = 0.0

## Scale multiplier for the rack model.
@export var rack_scale: Vector3 = Vector3.ONE

## Extra X-axis tilt for the local player's rack (readability).
@export var rack_tilt_x_deg: float = 0.0

# ─── Camera (used when this seat is the local player) ───

## Camera field of view in degrees.
@export var camera_fov: float = 44.0

## Camera near clip plane.
@export var camera_near: float = 0.015

## Camera far clip plane.
@export var camera_far: float = 20.0

## Camera look-at target point.
@export var camera_focus: Vector3 = Vector3(0.0, 0.015, 0.06)

# ─── Discard Zone ───

## Table-local 2D position of this seat's discard pile.
@export var discard_position: Vector2 = Vector2.ZERO

## Hit radius for discard zone detection.
@export var discard_hit_radius: float = 0.105

# ─── Meld Lane ───

## Table-local Rect2 defining this seat's meld/workspace area.
@export var meld_lane: Rect2 = Rect2()


static func create(p_index: int, p_label: String, p_is_local: bool,
		p_rack_pos: Vector2, p_rot_y: float,
		p_discard_pos: Vector2,
		p_meld_lane: Rect2 = Rect2()) -> SeatConfig:
	var cfg := SeatConfig.new()
	cfg.seat_index = p_index
	cfg.label = p_label
	cfg.is_local_player = p_is_local
	cfg.rack_position = p_rack_pos
	cfg.rotation_y_deg = p_rot_y
	cfg.discard_position = p_discard_pos
	cfg.meld_lane = p_meld_lane
	return cfg
