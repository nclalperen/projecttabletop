extends SceneTree
## Unit tests for SpringSolver2D mathematical kinematics and spring dynamics.

const SpringSolver2D = preload("res://ui/vector_table/math/SpringSolver2D.gd")

func _init() -> void:
	var ok: bool = run()
	if ok:
		print("  PASS  test_vector_spring_solver")
	else:
		print("  FAIL  test_vector_spring_solver")
	quit(0 if ok else 1)

func run() -> bool:
	var ok: bool = true

	# 1. Spring step towards target converges
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var target := Vector2(100.0, 50.0)

	for _i in range(120): # simulate ~2 seconds at 60 fps
		var res: Dictionary = SpringSolver2D.step_vector2(pos, vel, target, 1.0 / 60.0)
		pos = res["position"]
		vel = res["velocity"]
		if res["settled"]:
			break

	if not pos.is_equal_approx(target):
		push_error("SpringSolver2D did not converge to target: got %s expected %s" % [pos, target])
		ok = false

	# 2. Velocity tilt calculation clamps appropriately
	var tilt_fast: float = SpringSolver2D.calculate_tilt(5000.0, 0.00028, 0.26)
	if tilt_fast != -0.26:
		push_error("Tilt did not clamp to max negative angle: got %f" % tilt_fast)
		ok = false

	var tilt_reverse: float = SpringSolver2D.calculate_tilt(-5000.0, 0.00028, 0.26)
	if tilt_reverse != 0.26:
		push_error("Tilt did not clamp to max positive angle: got %f" % tilt_reverse)
		ok = false

	var tilt_zero: float = SpringSolver2D.calculate_tilt(0.0)
	if not is_zero_approx(tilt_zero):
		push_error("Zero velocity should yield zero tilt")
		ok = false

	# 3. Cubic Bezier boundary values
	var p0 := Vector2(10.0, 20.0)
	var p1 := Vector2(50.0, -100.0)
	var p2 := Vector2(150.0, -100.0)
	var p3 := Vector2(200.0, 40.0)

	var b_start: Vector2 = SpringSolver2D.bezier_cubic(p0, p1, p2, p3, 0.0)
	var b_end: Vector2 = SpringSolver2D.bezier_cubic(p0, p1, p2, p3, 1.0)
	if not b_start.is_equal_approx(p0):
		push_error("Bezier t=0 must equal p0")
		ok = false
	if not b_end.is_equal_approx(p3):
		push_error("Bezier t=1 must equal p3")
		ok = false

	# 4. Gaussian push repulsion
	var push_center: float = SpringSolver2D.gaussian_push(100.0, 100.0, 40.0, 40.0)
	if push_center < 39.0: # maximum displacement at center
		push_error("Gaussian push at center must be ~max displacement, got %f" % push_center)
		ok = false

	var push_far: float = SpringSolver2D.gaussian_push(300.0, 100.0, 40.0, 40.0)
	if absf(push_far) > 0.1: # decays to zero far away
		push_error("Gaussian push far away must be near zero, got %f" % push_far)
		ok = false

	return ok
