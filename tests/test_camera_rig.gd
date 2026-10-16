extends RefCounted
## Validates CameraRig camera extraction from GameTable3D.

const CAMERA_RIG = preload("res://ui/game_table/CameraRig.gd")
const SEAT_CONFIG = preload("res://core/config/SeatConfig.gd")


func run() -> bool:
	var ok: bool = true
	ok = _test_constants_and_presets() and ok
	ok = _test_math_helpers() and ok
	ok = _test_camera_operations() and ok
	ok = _test_seat_config_integration() and ok
	ok = _test_presets_application() and ok
	if ok:
		print("  PASS  test_camera_rig")
	else:
		print("  FAIL  test_camera_rig")
	return ok


func _test_constants_and_presets() -> bool:
	var ok: bool = true
	var rig = CAMERA_RIG.new()

	ok = _check(is_equal_approx(CAMERA_RIG.DEFAULT_FOV, 44.0), "DEFAULT_FOV is 44.0") and ok
	ok = _check(is_equal_approx(CAMERA_RIG.DEFAULT_NEAR, 0.015), "DEFAULT_NEAR is 0.015") and ok
	ok = _check(is_equal_approx(CAMERA_RIG.DEFAULT_FAR, 20.0), "DEFAULT_FAR is 20.0") and ok
	ok = _check(CAMERA_RIG.DEFAULT_FOCUS.is_equal_approx(Vector3(0.0, 0.015, 0.06)), "DEFAULT_FOCUS matches") and ok

	var presets: Array[Dictionary] = rig.get_presets()
	ok = _check(presets.size() == 3, "presets size is 3") and ok
	ok = _check(presets[0].get("name") == "competitive", "preset 0 is competitive") and ok
	ok = _check(is_equal_approx(float(presets[0].get("fov")), 58.0), "preset 0 fov is 58.0") and ok
	ok = _check(presets[1].get("name") == "cinematic", "preset 1 is cinematic") and ok
	ok = _check(is_equal_approx(float(presets[1].get("fov")), 53.0), "preset 1 fov is 53.0") and ok
	ok = _check(presets[2].get("name") == "qa_reference", "preset 2 is qa_reference") and ok
	ok = _check(is_equal_approx(float(presets[2].get("fov")), 56.0), "preset 2 fov is 56.0") and ok

	return ok


func _test_math_helpers() -> bool:
	var ok: bool = true

	# Aspect ratio
	var aspect_16_9: float = CAMERA_RIG.calculate_aspect(Vector2(1920, 1080))
	ok = _check(is_equal_approx(aspect_16_9, 1920.0 / 1080.0), "aspect 16:9") and ok

	var aspect_zero: float = CAMERA_RIG.calculate_aspect(Vector2(100, 0))
	ok = _check(is_equal_approx(aspect_zero, 100.0), "aspect zero height protected") and ok

	# Fit scale factor
	# 16:9 aspect ~1.777 > 1.65 => fit is 1.0
	var fit_wide: float = CAMERA_RIG.calculate_fit(Vector2(1920, 1080))
	ok = _check(is_equal_approx(fit_wide, 1.0), "wide aspect fit is 1.0") and ok

	# 1:1 aspect = 1.0 => fit = 1.65 / 1.0 = 1.65
	var fit_square: float = CAMERA_RIG.calculate_fit(Vector2(1000, 1000))
	ok = _check(is_equal_approx(fit_square, 1.65), "square aspect fit is 1.65") and ok

	# Positions
	var pos_default: Vector3 = CAMERA_RIG.calculate_position(Vector2(1920, 1080), false)
	ok = _check(pos_default.is_equal_approx(Vector3(0.0, 0.69, 0.96)), "default pos wide") and ok

	var pos_insp: Vector3 = CAMERA_RIG.calculate_position(Vector2(1920, 1080), true)
	ok = _check(pos_insp.is_equal_approx(Vector3(0.0, 1.35, 0.001)), "inspection pos wide") and ok

	return ok


func _test_camera_operations() -> bool:
	var ok: bool = true
	var cam := Camera3D.new()
	var rig = CAMERA_RIG.new(cam)

	ok = _check(rig.camera == cam, "rig.camera set from constructor") and ok
	ok = _check(not rig.is_inspection(), "initially not inspection") and ok

	var view_size := Vector2(1920, 1080)
	rig.apply_default(view_size)
	ok = _check(cam.projection == Camera3D.PROJECTION_PERSPECTIVE, "cam projection perspective") and ok
	ok = _check(cam.keep_aspect == Camera3D.KEEP_HEIGHT, "cam keep aspect height") and ok
	ok = _check(is_equal_approx(cam.fov, 44.0), "cam default fov is 44") and ok
	ok = _check(is_equal_approx(cam.near, 0.015), "cam default near is 0.015") and ok
	ok = _check(is_equal_approx(cam.far, 20.0), "cam default far is 20") and ok
	ok = _check(cam.position.is_equal_approx(Vector3(0.0, 0.69, 0.96)), "cam default position") and ok

	# Toggle to inspection
	rig.toggle_inspection(view_size)
	ok = _check(rig.is_inspection(), "rig is inspection after toggle") and ok
	ok = _check(cam.position.is_equal_approx(Vector3(0.0, 1.35, 0.001)), "cam inspection position") and ok

	# Toggle back to default
	rig.toggle_inspection(view_size)
	ok = _check(not rig.is_inspection(), "rig not inspection after second toggle") and ok
	ok = _check(cam.position.is_equal_approx(Vector3(0.0, 0.69, 0.96)), "cam returned to default position") and ok

	# Explicit apply_inspection
	rig.apply_inspection(view_size)
	ok = _check(rig.is_inspection(), "rig is inspection after apply_inspection") and ok
	ok = _check(cam.position.is_equal_approx(Vector3(0.0, 1.35, 0.001)), "cam inspection pos") and ok

	cam.free()
	return ok


func _test_seat_config_integration() -> bool:
	var ok: bool = true
	var cam := Camera3D.new()
	var rig = CAMERA_RIG.new(cam)

	var seat := SeatConfig.new()
	seat.camera_fov = 50.0
	seat.camera_near = 0.02
	seat.camera_far = 25.0
	seat.camera_focus = Vector3(0.0, 0.02, 0.08)

	rig.apply_from_seat_config(seat, Vector2(1920, 1080))
	ok = _check(is_equal_approx(cam.fov, 50.0), "seat fov applied") and ok
	ok = _check(is_equal_approx(cam.near, 0.02), "seat near applied") and ok
	ok = _check(is_equal_approx(cam.far, 25.0), "seat far applied") and ok
	ok = _check(rig.current_focus.is_equal_approx(Vector3(0.0, 0.02, 0.08)), "seat focus applied") and ok

	cam.free()
	return ok


func _test_presets_application() -> bool:
	var ok: bool = true
	var cam := Camera3D.new()
	var rig = CAMERA_RIG.new(cam)

	ok = _check(rig.apply_preset_by_name("competitive"), "apply competitive preset") and ok
	ok = _check(is_equal_approx(cam.fov, 58.0), "competitive fov 58") and ok
	ok = _check(cam.position.is_equal_approx(Vector3(0.0, 0.81, 0.57)), "competitive pos") and ok

	ok = _check(rig.apply_preset_by_name("cinematic"), "apply cinematic preset") and ok
	ok = _check(is_equal_approx(cam.fov, 53.0), "cinematic fov 53") and ok
	ok = _check(cam.position.is_equal_approx(Vector3(0.0, 0.84, 0.58)), "cinematic pos") and ok

	cam.free()
	return ok


func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("test_camera_rig: " + message)
	return condition
