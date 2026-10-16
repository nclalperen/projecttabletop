## Procedural 3D Vector Tile for Okey 101 & Tabletop Hub.
## Combines physical 3D PBR ivory geometry with 6-DOF mathematical spring kinematics and velocity tilt.
class_name VectorTile3D
extends Node3D

signal tile_clicked(tile: VectorTile3D)
signal tile_double_clicked(tile: VectorTile3D)
signal tile_drag_started(tile: VectorTile3D)
signal tile_drag_ended(tile: VectorTile3D)

const SPRING3D = preload("res://ui/vector_table/math/SpringSolver3D.gd")
const TABLE_ART = preload("res://ui/game_table/OkeyTableArt.gd")

# Tile Dimensions (meters)
const TILE_WIDTH: float = 0.045
const TILE_HEIGHT: float = 0.065
const TILE_DEPTH: float = 0.009

# Suit Colors
const SUIT_COLORS: Array[Color] = [
	Color(0.85, 0.16, 0.12, 1.0), # 0: Red
	Color(0.88, 0.58, 0.06, 1.0), # 1: Yellow
	Color(0.14, 0.14, 0.16, 1.0), # 2: Black
	Color(0.08, 0.44, 0.84, 1.0), # 3: Blue
]

# Tile Data
var unique_id: int = -1
var number: int = 1
var color_index: int = 0
var is_fake_okey: bool = false
var is_face_up: bool = true
var is_standing: bool = true
var is_valid_meld: bool = false

# 3D Kinematics & Springs
var target_pos: Vector3 = Vector3.ZERO
var spring_pos: Vector3 = Vector3.ZERO
var spring_vel: Vector3 = Vector3.ZERO

var base_rot_deg: Vector3 = Vector3(-28.0, 0.0, 0.0)
var target_rot_deg: Vector3 = Vector3(-28.0, 0.0, 0.0)
var spring_rot_deg: Vector3 = Vector3(-28.0, 0.0, 0.0)
var spring_rot_vel: Vector3 = Vector3.ZERO

var lift_y: float = 0.0 # Dynamic lift in meters when dragged
var target_lift_y: float = 0.0
var lift_vel: float = 0.0

var is_dragging: bool = false

# Visual nodes
var _visual_body: Node3D = null
var _number_label: Label3D = null
var _pip_label: Label3D = null
var _meld_bar: MeshInstance3D = null


func _init() -> void:
	pass


func _ready() -> void:
	spring_pos = position
	target_pos = position
	spring_rot_deg = rotation_degrees
	target_rot_deg = rotation_degrees


func setup_tile(uid: int, num: int, col_idx: int, fake_okey: bool = false, standing: bool = true, face_up: bool = true) -> void:
	unique_id = uid
	number = num
	color_index = posmod(col_idx, SUIT_COLORS.size())
	is_fake_okey = fake_okey
	is_standing = standing
	is_face_up = face_up

	_rebuild_visuals()


func set_target_position_3d(pos: Vector3, snap_immediate: bool = false) -> void:
	target_pos = pos
	if snap_immediate:
		spring_pos = pos
		spring_vel = Vector3.ZERO
		position = pos


func set_target_rotation_3d(rot_deg: Vector3, snap_immediate: bool = false) -> void:
	base_rot_deg = rot_deg
	target_rot_deg = rot_deg
	if snap_immediate:
		spring_rot_deg = rot_deg
		spring_rot_vel = Vector3.ZERO
		rotation_degrees = rot_deg


func set_drag_lift(lift_meters: float) -> void:
	target_lift_y = lift_meters


func _process(delta: float) -> void:
	if is_dragging:
		return

	# 1. Step 3D Position Spring
	var effective_target := target_pos + Vector3(0.0, lift_y, 0.0)
	if not spring_pos.is_equal_approx(effective_target) or spring_vel.length_squared() > 0.0001:
		var pos_res: Dictionary = SPRING3D.step_vector3(spring_pos, spring_vel, effective_target, delta, 26.0, 0.74)
		spring_pos = pos_res["position"]
		spring_vel = pos_res["velocity"]
		position = spring_pos

	# 2. Step 3D Rotation Spring with Velocity Tilt
	var tilt_deg: Vector3 = SPRING3D.calculate_tilt_3d(spring_vel, 6.0, 16.0)
	var effective_target_rot := target_rot_deg + tilt_deg
	if not spring_rot_deg.is_equal_approx(effective_target_rot) or spring_rot_vel.length_squared() > 0.01:
		var rot_res: Dictionary = SPRING3D.step_rotation3d(spring_rot_deg, spring_rot_vel, effective_target_rot, delta, 22.0, 0.70)
		spring_rot_deg = rot_res["rotation_deg"]
		spring_rot_vel = rot_res["velocity"]
		rotation_degrees = spring_rot_deg

	# 3. Step Lift Spring
	if not is_equal_approx(lift_y, target_lift_y) or absf(lift_vel) > 0.0001:
		var dl: float = lift_y - target_lift_y
		var accel: float = -2.0 * 0.72 * 28.0 * lift_vel - (28.0 * 28.0) * dl
		lift_vel += accel * delta
		lift_y += lift_vel * delta
		if absf(lift_y - target_lift_y) < 0.0005 and absf(lift_vel) < 0.002:
			lift_y = target_lift_y
			lift_vel = 0.0


func _rebuild_visuals() -> void:
	for child in get_children():
		child.queue_free()

	# 1. Procedural 3D Ivory Body with Chamfered Edges and Specular Sheen
	_visual_body = TABLE_ART.build_tile(is_standing, is_face_up)
	add_child(_visual_body)

	if not is_face_up:
		return

	# 2. Suit Color & Text
	var suit_color: Color = SUIT_COLORS[color_index]
	var text: String = "★" if is_fake_okey else str(number)
	if is_fake_okey:
		suit_color = Color("#d99b26")

	# 3. Engraved Number Label3D
	_number_label = Label3D.new()
	_number_label.text = text
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Arial"])
	font.font_weight = 700
	_number_label.font = font
	_number_label.font_size = 64
	_number_label.pixel_size = 0.00043
	_number_label.modulate = suit_color
	_number_label.outline_size = 0
	_number_label.shaded = false
	_number_label.double_sided = true
	_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if is_standing:
		_number_label.position = Vector3(0.0, 0.0105, TILE_DEPTH * 0.50 + 0.0007)
	else:
		_number_label.position = Vector3(0.0, TILE_DEPTH * 0.50 + 0.0042, -0.010)
		_number_label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	add_child(_number_label)

	# 4. Circular Colored Pip (●)
	_pip_label = Label3D.new()
	_pip_label.text = "●"
	_pip_label.font = font
	_pip_label.font_size = 38
	_pip_label.pixel_size = 0.00040
	_pip_label.modulate = suit_color
	_pip_label.shaded = false
	_pip_label.double_sided = true
	_pip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if is_standing:
		_pip_label.position = Vector3(0.0, -0.0130, TILE_DEPTH * 0.50 + 0.0007)
	else:
		_pip_label.position = Vector3(0.0, TILE_DEPTH * 0.50 + 0.0042, 0.0135)
		_pip_label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	add_child(_pip_label)

	# 5. Emerald Valid Meld Indicator Bar
	if is_valid_meld:
		_meld_bar = MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(TILE_WIDTH * 0.78, 0.0045)
		_meld_bar.mesh = quad
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.18, 0.85, 0.42)
		mat.emission_enabled = true
		mat.emission = Color(0.18, 0.85, 0.42)
		mat.emission_energy_multiplier = 0.65
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_meld_bar.material_override = mat
		if is_standing:
			_meld_bar.position = Vector3(0.0, -TILE_HEIGHT * 0.45, TILE_DEPTH * 0.50 + 0.0008)
		else:
			_meld_bar.position = Vector3(0.0, TILE_DEPTH * 0.50 + 0.0042, TILE_HEIGHT * 0.45)
			_meld_bar.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		add_child(_meld_bar)
