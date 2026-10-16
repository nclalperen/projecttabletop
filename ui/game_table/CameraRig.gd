## Manages the 3D tabletop camera setup, presets, viewport adaptation, and inspection mode.
##
## Extracted from GameTable3D to isolate camera projection, aspect-ratio fitting,
## and seat-based configuration while operating on a target Camera3D node.
class_name CameraRig
extends RefCounted

# ─── Default Camera Parameters ───
const DEFAULT_FOV: float = 44.0
const DEFAULT_NEAR: float = 0.015
const DEFAULT_FAR: float = 20.0
const DEFAULT_FOCUS: Vector3 = Vector3(0.0, 0.015, 0.06)

# ─── Viewport Fitting Constants ───
const BASE_ASPECT_RATIO: float = 1.65
const MIN_ASPECT_RATIO: float = 0.6
const DEFAULT_POSITION_OFFSET: Vector3 = Vector3(0.0, 0.69, 0.96)
const INSPECTION_POSITION_OFFSET: Vector3 = Vector3(0.0, 1.35, 0.001)

# ─── Fixed Camera Presets (Competitive / Cinematic / QA) ───
const CAMERA_PRESETS: Array[Dictionary] = [
	{
		"name": "competitive",
		"fov": 58.0,
		"pos": Vector3(0.0, 0.81, 0.57),
		"focus": Vector3(0.0, 0.018, 0.010),
		"near": 0.025,
		"far": 20.0,
	},
	{
		"name": "cinematic",
		"fov": 53.0,
		"pos": Vector3(0.0, 0.84, 0.58),
		"focus": Vector3(0.0, 0.030, -0.020),
		"near": 0.030,
		"far": 24.0,
	},
	{
		"name": "qa_reference",
		"fov": 56.0,
		"pos": Vector3(0.0, 0.80, 0.52),
		"focus": Vector3(0.0, 0.020, 0.020),
		"near": 0.025,
		"far": 20.0,
	},
]

## The Camera3D instance being manipulated.
var camera: Camera3D = null

## Active camera parameter state.
var current_fov: float = DEFAULT_FOV
var current_near: float = DEFAULT_NEAR
var current_far: float = DEFAULT_FAR
var current_focus: Vector3 = DEFAULT_FOCUS

## Index of last selected fixed preset.
var current_preset_index: int = 0

## Internal inspection mode toggle state (false = seated adaptive view, true = top-down view).
var _inspection: bool = false


func _init(p_camera: Camera3D = null) -> void:
	camera = p_camera


## Returns true if inspection (top-down) mode is currently active.
func is_inspection() -> bool:
	return _inspection


## Sets camera to default seated perspective and applies viewport adaptation.
func apply_default(viewport_size: Vector2) -> void:
	_inspection = false
	_apply_adaptive(viewport_size)


## Sets camera to top-down inspection view and applies viewport adaptation.
func apply_inspection(viewport_size: Vector2) -> void:
	_inspection = true
	_apply_adaptive(viewport_size)


## Toggles between default seated view and top-down inspection view.
func toggle_inspection(viewport_size: Vector2) -> void:
	_inspection = not _inspection
	_apply_adaptive(viewport_size)


## Explicitly sets inspection mode flag and updates camera if viewport_size is valid (> 0).
func set_inspection(inspection: bool, viewport_size: Vector2 = Vector2.ZERO) -> void:
	_inspection = inspection
	if viewport_size.x > 0.0 and viewport_size.y > 0.0:
		_apply_adaptive(viewport_size)


var _camera_tween: Tween = null

## Smoothly tweens camera transform towards inspection view (default 0.26s cubic).
func tween_to_inspection(viewport_size: Vector2, duration: float = 0.26) -> Tween:
	_inspection = true
	return _tween_adaptive(viewport_size, duration)


## Smoothly tweens camera transform towards default seated view (default 0.26s cubic).
func tween_to_default(viewport_size: Vector2, duration: float = 0.26) -> Tween:
	_inspection = false
	return _tween_adaptive(viewport_size, duration)


func _tween_adaptive(viewport_size: Vector2, duration: float = 0.26) -> Tween:
	if camera == null or not is_instance_valid(camera):
		return null
	if not camera.is_inside_tree():
		_apply_adaptive(viewport_size)
		return null

	if _camera_tween != null and _camera_tween.is_running():
		_camera_tween.kill()

	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.fov = current_fov
	camera.near = current_near
	camera.far = current_far

	var pos: Vector3 = calculate_position(viewport_size, _inspection)
	var temp := Transform3D()
	temp.origin = pos
	var forward: Vector3 = (current_focus - pos).normalized()
	var up: Vector3 = Vector3.UP
	if absf(forward.dot(up)) > 0.999:
		up = Vector3.FORWARD
	var right: Vector3 = forward.cross(up).normalized()
	up = right.cross(forward).normalized()
	temp.basis = Basis(right, up, -forward)

	_camera_tween = camera.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_camera_tween.tween_property(camera, ^"transform", temp, duration)
	return _camera_tween



## Configures and positions camera based on a SeatConfig resource and viewport size.
func apply_from_seat_config(seat: SeatConfig, viewport_size: Vector2) -> void:
	if seat != null:
		current_fov = seat.camera_fov
		current_near = seat.camera_near
		current_far = seat.camera_far
		current_focus = seat.camera_focus
	_apply_adaptive(viewport_size)


## Applies camera configuration using direct parameters.
func apply_direct(
	viewport_size: Vector2,
	fov: float = DEFAULT_FOV,
	focus: Vector3 = DEFAULT_FOCUS,
	near: float = DEFAULT_NEAR,
	far: float = DEFAULT_FAR,
	inspection: bool = false
) -> void:
	_inspection = inspection
	current_fov = fov
	current_focus = focus
	current_near = near
	current_far = far
	_apply_adaptive(viewport_size)


## Applies one of the predefined fixed camera presets by index (competitive, cinematic, qa_reference).
func apply_preset(index: int) -> bool:
	if camera == null or not is_instance_valid(camera):
		return false
	if index < 0 or index >= CAMERA_PRESETS.size():
		return false
	current_preset_index = index
	var preset: Dictionary = CAMERA_PRESETS[index]
	current_fov = float(preset.get("fov", DEFAULT_FOV))
	current_near = float(preset.get("near", DEFAULT_NEAR))
	current_far = float(preset.get("far", DEFAULT_FAR))
	current_focus = preset.get("focus", DEFAULT_FOCUS) as Vector3
	var pos: Vector3 = preset.get("pos", DEFAULT_POSITION_OFFSET) as Vector3

	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.fov = current_fov
	camera.near = current_near
	camera.far = current_far
	_orient_camera(pos, current_focus)
	return true


## Applies one of the predefined fixed camera presets by name.
func apply_preset_by_name(preset_name: String) -> bool:
	for i in range(CAMERA_PRESETS.size()):
		if str(CAMERA_PRESETS[i].get("name", "")) == preset_name:
			return apply_preset(i)
	return false


## Cycles to the next fixed camera preset and returns its name.
func cycle_preset() -> String:
	if CAMERA_PRESETS.is_empty():
		return ""
	current_preset_index = (current_preset_index + 1) % CAMERA_PRESETS.size()
	apply_preset(current_preset_index)
	return str(CAMERA_PRESETS[current_preset_index].get("name", ""))


## Returns the preset dictionary at the given index, or an empty dictionary if out of bounds.
func get_preset(index: int) -> Dictionary:
	if index >= 0 and index < CAMERA_PRESETS.size():
		return CAMERA_PRESETS[index].duplicate()
	return {}


## Returns a duplicate list of all defined camera presets.
func get_presets() -> Array[Dictionary]:
	return CAMERA_PRESETS.duplicate(true)


# ─── Static Math Helpers ───

## Calculates the aspect ratio for a given viewport size, protecting against zero heights.
static func calculate_aspect(viewport_size: Vector2) -> float:
	return viewport_size.x / maxf(viewport_size.y, 1.0)


## Calculates the adaptive fit scale factor for a given viewport size.
static func calculate_fit(viewport_size: Vector2) -> float:
	var aspect: float = calculate_aspect(viewport_size)
	return maxf(1.0, BASE_ASPECT_RATIO / maxf(aspect, MIN_ASPECT_RATIO))


## Calculates the 3D position of the camera given viewport size and inspection mode flag.
static func calculate_position(viewport_size: Vector2, inspection_mode: bool) -> Vector3:
	var fit: float = calculate_fit(viewport_size)
	if inspection_mode:
		return Vector3(0.0, 1.35 * fit, 0.001)
	return Vector3(0.0, 0.69 * fit, 0.96 * fit)


# ─── Internal Application ───

func _apply_adaptive(viewport_size: Vector2) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.fov = current_fov
	camera.near = current_near
	camera.far = current_far
	var pos: Vector3 = calculate_position(viewport_size, _inspection)
	_orient_camera(pos, current_focus)


func _orient_camera(pos: Vector3, focus: Vector3) -> void:
	camera.position = pos
	if camera.is_inside_tree():
		camera.look_at(focus, Vector3.UP)
	else:
		camera.look_at_from_position(pos, focus, Vector3.UP)
