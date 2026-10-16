## Mathematical 3D Vector Dynamics & Kinematics Solver.
## Powers continuous 3D spring motion, 6-DOF velocity-coupled tilt, 3D flight arcs,
## and continuous rail push-aside displacement without rigid grids.
class_name SpringSolver3D
extends RefCounted

const DEFAULT_OMEGA: float = 24.0   # Natural frequency (rad/s)
const DEFAULT_ZETA: float = 0.74    # Damping ratio (0.74 = organic physical settle, zero jitter)
const SETTLE_EPSILON_POS: float = 0.0003
const SETTLE_EPSILON_VEL: float = 0.001
const SETTLE_EPSILON_ROT: float = 0.05


## Advances a 3D position spring state by delta seconds using semi-implicit Euler integration.
## Returns a Dictionary with keys: position (Vector3), velocity (Vector3), settled (bool).
static func step_vector3(
	current: Vector3,
	velocity: Vector3,
	target: Vector3,
	delta: float,
	omega: float = DEFAULT_OMEGA,
	zeta: float = DEFAULT_ZETA
) -> Dictionary:
	var dt: float = clampf(delta, 0.0001, 0.05)
	var displacement: Vector3 = current - target
	# Second order ODE in 3D: a = -2*zeta*omega*v - omega^2 * displacement
	var accel: Vector3 = -2.0 * zeta * omega * velocity - (omega * omega) * displacement
	var new_vel: Vector3 = velocity + accel * dt
	var new_pos: Vector3 = current + new_vel * dt

	var settled: bool = new_pos.distance_to(target) < SETTLE_EPSILON_POS and new_vel.length() < SETTLE_EPSILON_VEL
	if settled:
		new_pos = target
		new_vel = Vector3.ZERO

	return {
		"position": new_pos,
		"velocity": new_vel,
		"settled": settled
	}


## Advances a 3D rotation spring state (Euler degrees) by delta seconds.
## Returns a Dictionary with keys: rotation_deg (Vector3), velocity (Vector3), settled (bool).
static func step_rotation3d(
	current_deg: Vector3,
	velocity_deg: Vector3,
	target_deg: Vector3,
	delta: float,
	omega: float = DEFAULT_OMEGA,
	zeta: float = DEFAULT_ZETA
) -> Dictionary:
	var dt: float = clampf(delta, 0.0001, 0.05)
	var displacement: Vector3 = current_deg - target_deg
	var accel: Vector3 = -2.0 * zeta * omega * velocity_deg - (omega * omega) * displacement
	var new_vel: Vector3 = velocity_deg + accel * dt
	var new_rot: Vector3 = current_deg + new_vel * dt

	var settled: bool = new_rot.distance_to(target_deg) < SETTLE_EPSILON_ROT and new_vel.length() < (SETTLE_EPSILON_ROT * 5.0)
	if settled:
		new_rot = target_deg
		new_vel = Vector3.ZERO

	return {
		"rotation_deg": new_rot,
		"velocity": new_vel,
		"settled": settled
	}


## Calculates 3D inertial tilt (pitch, yaw, roll in degrees) coupled to 3D lateral velocity.
## Makes held or flying tiles lean naturally into motion.
static func calculate_tilt_3d(
	velocity_3d: Vector3,
	sensitivity: float = 8.5,
	max_tilt_deg: float = 18.0
) -> Vector3:
	var roll: float = clampf(-velocity_3d.x * sensitivity, -max_tilt_deg, max_tilt_deg)
	var pitch: float = clampf(velocity_3d.z * sensitivity, -max_tilt_deg, max_tilt_deg)
	var yaw: float = clampf(-velocity_3d.x * sensitivity * 0.35, -max_tilt_deg * 0.5, max_tilt_deg * 0.5)
	return Vector3(pitch, yaw, roll)


## Computes a point on a 3D cubic Bezier curve for organic parabolic flight paths.
static func bezier_cubic_3d(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var u: float = 1.0 - t
	var tt: float = t * t
	var uu: float = u * u
	var uuu: float = uu * u
	var ttt: float = tt * t

	return (uuu * p0) + (3.0 * uu * t * p1) + (3.0 * u * tt * p2) + (ttt * p3)


## Computes Gaussian push-aside displacement vector in 3D along a rail direction.
## Displaces tile_pos along rail_dir based on proximity to pointer_pos.
static func gaussian_push_3d(
	tile_pos: Vector3,
	pointer_pos: Vector3,
	rail_dir: Vector3 = Vector3.RIGHT,
	max_disp: float = 0.042,
	sigma: float = 0.055
) -> Vector3:
	var delta: Vector3 = tile_pos - pointer_pos
	var proj_dist: float = delta.dot(rail_dir)
	var sign_dir: float = 1.0 if proj_dist >= 0.0 else -1.0
	var factor: float = exp(-(proj_dist * proj_dist) / (2.0 * sigma * sigma))
	return rail_dir * (sign_dir * max_disp * factor)
