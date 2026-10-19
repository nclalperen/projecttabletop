extends RefCounted
## Regression guard for the approved Layout Studio composition, without a live round.
## Headless startup skips user:// overrides in BoardLayoutTuner3D, so this checks
## the portable default against an independent source-controlled reference.

const TABLE = preload("res://ui/vector_table/VectorGameTable3D.gd")
const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")
const REFERENCE := "res://tests/fixtures/vector3d_approved_layout.json"
const POSITION_EPSILON := 0.0000002
const ANGLE_EPSILON := 0.00002

class InactiveSession extends Node:
	func get_controller():
		return null

var _ok := true

func run() -> bool:
	_ok = true
	if DisplayServer.get_name() != "headless":
		push_error("Approved layout test requires headless startup (no user layout overrides)")
		return false
	var reference = JSON.parse_string(FileAccess.get_file_as_string(REFERENCE))
	if not reference is Dictionary:
		push_error("Cannot read approved Vector layout reference")
		return false
	var tree := Engine.get_main_loop() as SceneTree
	var table := TABLE.new()
	# Allow the real board's ready/setup path while preventing round creation/bots.
	var inactive := InactiveSession.new()
	table._session = inactive
	table.add_child(inactive)
	tree.root.add_child(table)
	await tree.process_frame
	_check(table._layout_tuner != null, "board completed ready/setup")
	var camera: Camera3D = table._camera
	_vector(camera.position, reference.camera_pos, "camera position")
	_rotation(camera.rotation_degrees, reference.camera_rot_deg, "camera rotation")
	_scalar(camera.fov, reference.camera_fov, ANGLE_EPSILON, "camera FOV")
	_scalar(camera.near, reference.camera_near, POSITION_EPSILON, "camera near")
	_scalar(camera.far, reference.camera_far, POSITION_EPSILON, "camera far")
	_vector(table._layout_tuner._cam_look_at, reference.camera_look_at, "camera target")
	_vector(table._hand_rig.position, reference.hand_rig_origin, "hand rack position")
	_rotation(table._hand_rig.rotation_degrees, reference.hand_rig_rot_deg, "hand rack rotation")
	_check(table._hand_rig.get_parent() == camera, "hand remains camera attached")
	_check(table._hand_rig.scale.is_equal_approx(Vector3.ONE), "hand rack scale")
	for seat in range(1, 4):
		var rack: Node3D = table._opponent_racks[seat]
		_vector(rack.position, reference.opponent_rack_pos[str(seat)], "opponent %d position" % seat)
		_rotation(rack.rotation_degrees, reference.opponent_rack_rot[str(seat)], "opponent %d rotation" % seat)
		_vector(rack.scale, [reference.opponent_rack_scale, reference.opponent_rack_scale, reference.opponent_rack_scale], "opponent %d scale" % seat)
	for seat in range(4):
		var key := str(seat)
		_vector(table._discard_piles_view.get_pile_position(seat), reference.discard_pos[key], "discard %d position" % seat)
		_rotation(table._discard_piles_view.get_pile_rotation_deg(seat), reference.discard_rot[key], "discard %d rotation" % seat)
		_vector(table._discard_piles_view._anchors[seat].scale, [1, 1, 1], "discard %d scale" % seat)
		_vector(table._meld_layout.get_seat_area_position(seat), reference.meld_area_pos[key], "meld %d position" % seat)
		_rotation(table._meld_layout.get_seat_area_rotation_deg(seat), reference.meld_area_rot[key], "meld %d rotation" % seat)
		var size: Vector2 = table._meld_layout.get_seat_area_size(seat)
		_scalar(size.x, reference.meld_area_size[key][0], POSITION_EPSILON, "meld %d width" % seat)
		_scalar(size.y, reference.meld_area_size[key][1], POSITION_EPSILON, "meld %d depth" % seat)
		_scalar(table._meld_layout.get_seat_area_scale(seat), 1.0, POSITION_EPSILON, "meld %d scale" % seat)
	_check(table._meld_layout.independent_seat_areas, "independent meld areas enabled")
	_scalar(table._meld_layout.row_pitch_scale, 1.0, POSITION_EPSILON, "meld row spacing")
	_scalar(table._meld_layout.tile_pitch_scale, 1.0, POSITION_EPSILON, "meld tile spacing")
	_scalar(table._meld_layout.group_gap_scale, 1.0, POSITION_EPSILON, "meld group spacing")
	_vector(table._stock_view.position, reference.stock_pos, "stock position")
	_rotation(table._stock_view.rotation_degrees, reference.stock_rot, "stock rotation")
	# Exercise the actual indicator presentation path, with no gameplay controller.
	table._on_session_state_updated({"deck_count": 20, "indicator_tile": Tile.new(0, 1, Tile.Kind.NORMAL, 999)})
	var indicator = table._registry.get_node_for(999)
	_check(indicator != null, "indicator instantiated")
	if indicator != null:
		_vector(indicator.position, reference.indicator_pos, "indicator position")
		_rotation(indicator.rotation_degrees, [-90.0, reference.indicator_rot[1], 0.0], "indicator flat rotation")
	var slots: Dictionary = reference.hand_slots
	_check(TUNING.ROW_COUNT == int(slots.row_count), "hand row count")
	_check(TUNING.SLOTS_PER_ROW == int(slots.slots_per_row), "hand slots per row")
	_check(TUNING.TOTAL_HAND_SLOTS == int(slots.total), "total hand slots")
	for slot in range(int(slots.total)):
		var row := int(slot / int(slots.slots_per_row))
		var column := slot % int(slots.slots_per_row)
		var xf: Transform3D = table._hand_rig.slot_local_transform(slot)
		_vector(xf.origin, [(column - 7) * float(slots.tile_pitch), slots.row_local_y[row], slots.row_local_z[row]], "hand slot %d position" % slot)
		_rotation(xf.basis.get_euler() * (180.0 / PI), [slots.row_tilt_deg[row], 0.0, 0.0], "hand slot %d tilt" % slot)
	table.free()
	await tree.process_frame
	if _ok:
		print("  PASS  test_vector3d_approved_layout")
	return _ok

func _check(condition: bool, label: String) -> void:
	if not condition:
		push_error("Approved Vector layout changed: " + label)
		_ok = false

func _scalar(actual: float, expected: float, epsilon: float, label: String) -> void:
	_check(absf(actual - expected) <= epsilon, "%s (%.10f vs %.10f)" % [label, actual, expected])

func _vector(actual: Vector3, expected: Array, label: String) -> void:
	var wanted := Vector3(float(expected[0]), float(expected[1]), float(expected[2]))
	_check(actual.distance_to(wanted) <= POSITION_EPSILON, "%s (%s vs %s)" % [label, actual, wanted])

func _rotation(actual: Vector3, expected: Array, label: String) -> void:
	for axis in range(3):
		# Equivalent Euler representations at +/-180 degrees are the same transform.
		var difference := wrapf(actual[axis] - float(expected[axis]), -180.0, 180.0)
		_scalar(difference, 0.0, ANGLE_EPSILON, "%s axis %d" % [label, axis])
