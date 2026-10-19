extends RefCounted
## Unit tests for SpringSolver3D mathematical kinematics in 3D space.

const SpringSolver3D = preload("res://ui/vector_table/math/SpringSolver3D.gd")

func run() -> bool:
	var ok: bool = true

	# 1. 3D Position convergence
	var pos := Vector3(0.0, 0.0, 0.0)
	var vel := Vector3.ZERO
	var target := Vector3(0.42, 0.08, -0.22)

	for _i in range(120): # simulate ~2 seconds
		var res: Dictionary = SpringSolver3D.step_vector3(pos, vel, target, 1.0 / 60.0)
		pos = res["position"]
		vel = res["velocity"]
		if res["settled"]:
			break

	if not pos.is_equal_approx(target):
		push_error("SpringSolver3D did not converge in 3D: got %s expected %s" % [pos, target])
		ok = false

	# 2. 3D Rotation convergence
	var rot := Vector3.ZERO
	var rot_vel := Vector3.ZERO
	var target_rot := Vector3(-28.0, 0.0, 0.0)

	for _i in range(120):
		var res_rot: Dictionary = SpringSolver3D.step_rotation3d(rot, rot_vel, target_rot, 1.0 / 60.0)
		rot = res_rot["rotation_deg"]
		rot_vel = res_rot["velocity"]
		if res_rot["settled"]:
			break

	if not rot.is_equal_approx(target_rot):
		push_error("SpringSolver3D rotation did not converge: got %s expected %s" % [rot, target_rot])
		ok = false

	# 3. 3D Tilt calculation
	var tilt := SpringSolver3D.calculate_tilt_3d(Vector3(2.0, 0.0, -1.0))
	if tilt.z >= 0.0 or tilt.x >= 0.0:
		push_error("Tilt roll and pitch signs incorrect for positive vx and negative vz")
		ok = false

	# 4. 3D Cubic Bezier arc
	var b0 := Vector3(0.0, 0.0, 0.0)
	var b1 := Vector3(0.1, 0.2, 0.0) # High arc
	var b2 := Vector3(0.3, 0.2, 0.0)
	var b3 := Vector3(0.4, 0.0, 0.0)

	var mid := SpringSolver3D.bezier_cubic_3d(b0, b1, b2, b3, 0.5)
	if mid.y <= 0.1:
		push_error("Bezier arc midpoint must be elevated above endpoints, got Y=%f" % mid.y)
		ok = false

	# 5. Gaussian push in 3D along Vector3.RIGHT
	var push := SpringSolver3D.gaussian_push_3d(Vector3(0.1, 0.0, 0.0), Vector3(0.1, 0.0, 0.0), Vector3.RIGHT, 0.040, 0.050)
	if push.x < 0.038:
		push_error("3D Gaussian push should be maximum at center, got %f" % push.x)
		ok = false

	return ok
