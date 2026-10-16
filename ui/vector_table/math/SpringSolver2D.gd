## Mathematical Second-Order Spring Dynamics & Kinematics Solver.
## Powers fluid vector tile animations, velocity-coupled tilt, and Bezier trajectories.
class_name SpringSolver2D
extends RefCounted

const DEFAULT_OMEGA: float = 24.0   # Natural frequency (rad/s)
const DEFAULT_ZETA: float = 0.76    # Damping ratio (0.76 = snappy organic settle, zero jitter)
const SETTLE_EPSILON_POS: float = 0.25
const SETTLE_EPSILON_VEL: float = 0.50
const SETTLE_EPSILON_FLOAT: float = 0.001


## Advances a 2D spring state by delta seconds using semi-implicit Euler integration.
## Returns a Dictionary with keys: position (Vector2), velocity (Vector2), settled (bool).
static func step_vector2(
	current: Vector2,
	velocity: Vector2,
	target: Vector2,
	delta: float,
	omega: float = DEFAULT_OMEGA,
	zeta: float = DEFAULT_ZETA
) -> Dictionary:
	var dt: float = clampf(delta, 0.0001, 0.05)
	var displacement: Vector2 = current - target
	# Second order ODE: a = -2*zeta*omega*v - omega^2 * displacement
	var accel: Vector2 = -2.0 * zeta * omega * velocity - (omega * omega) * displacement
	var new_vel: Vector2 = velocity + accel * dt
	var new_pos: Vector2 = current + new_vel * dt

	var settled: bool = new_pos.distance_to(target) < SETTLE_EPSILON_POS and new_vel.length() < SETTLE_EPSILON_VEL
	if settled:
		new_pos = target
		new_vel = Vector2.ZERO

	return {
		"position": new_pos,
		"velocity": new_vel,
		"settled": settled
	}


## Advances a scalar float spring state by delta seconds.
## Returns a Dictionary with keys: value (float), velocity (float), settled (bool).
static func step_float(
	current: float,
	velocity: float,
	target: float,
	delta: float,
	omega: float = DEFAULT_OMEGA,
	zeta: float = DEFAULT_ZETA
) -> Dictionary:
	var dt: float = clampf(delta, 0.0001, 0.05)
	var displacement: float = current - target
	var accel: float = -2.0 * zeta * omega * velocity - (omega * omega) * displacement
	var new_vel: float = velocity + accel * dt
	var new_val: float = current + new_vel * dt

	var settled: bool = absf(new_val - target) < SETTLE_EPSILON_FLOAT and absf(new_vel) < (SETTLE_EPSILON_FLOAT * 10.0)
	if settled:
		new_val = target
		new_vel = 0.0

	return {
		"value": new_val,
		"velocity": new_vel,
		"settled": settled
	}


## Computes inertial tilt angle (in radians) from lateral velocity.
## Tiles lean into the direction of drag or momentum swings.
static func calculate_tilt(
	velocity_x: float,
	sensitivity: float = 0.00028,
	max_angle_rad: float = 0.26
) -> float:
	return clampf(-velocity_x * sensitivity, -max_angle_rad, max_angle_rad)


## Computes a point on a cubic Bezier curve for organic card/tile deal and discard flight paths.
static func bezier_cubic(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	var tt: float = t * t
	var uu: float = u * u
	var uuu: float = uu * u
	var ttt: float = tt * t

	return (uuu * p0) + (3.0 * uu * t * p1) + (3.0 * u * tt * p2) + (ttt * p3)


## Computes tangent direction (normalized) of a cubic Bezier curve at parameter t.
static func bezier_tangent(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	var tangent: Vector2 = 3.0 * (u * u) * (p1 - p0) + 6.0 * u * t * (p2 - p1) + 3.0 * (t * t) * (p3 - p2)
	return tangent.normalized() if tangent.length_squared() > 0.0001 else Vector2.RIGHT


## Gaussian push-aside force for continuous non-grid rack reordering.
## Returns offset displacement (in pixels) for a tile at tile_x caused by a held tile at drag_x.
static func gaussian_push(
	tile_x: float,
	drag_x: float,
	max_displacement: float = 38.0,
	sigma: float = 42.0
) -> float:
	var diff: float = tile_x - drag_x
	var direction: float = 1.0 if diff >= 0.0 else -1.0
	var factor: float = exp(-(diff * diff) / (2.0 * sigma * sigma))
	return direction * max_displacement * factor
