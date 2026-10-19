## Procedural 3D Vector Tile for Okey 101 & Tabletop Hub.
## Combines physical 3D PBR ivory geometry with 6-DOF mathematical spring kinematics,
## velocity tilt, and crisp texture-atlas face rendering (no Label3D runtime overhead).
class_name VectorTile3D
extends Node3D

signal tile_clicked(tile: VectorTile3D)
signal tile_double_clicked(tile: VectorTile3D)
signal tile_drag_started(tile: VectorTile3D)
signal tile_drag_ended(tile: VectorTile3D)

const SPRING3D = preload("res://ui/vector_table/math/SpringSolver3D.gd")
const TABLE_ART = preload("res://ui/game_table/OkeyTableArt.gd")
const TileFaceAtlas = preload("res://ui/vector_table/render/TileFaceAtlas.gd")

# Tile Dimensions (meters)
const TILE_WIDTH: float = 0.045
const TILE_HEIGHT: float = 0.065
const TILE_DEPTH: float = 0.009
const FACE_WIDTH: float = 0.0394
const FACE_HEIGHT: float = 0.0594
const FACE_LOCAL_Z: float = 0.00452

# Shared Face Shader
static var _face_shader: Shader = null

# Suit Colors (physical Okey set)
const SUIT_COLORS: Array[Color] = [
	Color("#c8231b"), # 0: Red
	Color("#e09a12"), # 1: Yellow
	Color("#1d1d22"), # 2: Black
	Color("#1563c9"), # 3: Blue
]

# Tile Data
var unique_id: int = -1
var number: int = 1
var color_index: int = 0
var is_fake_okey: bool = false
var is_face_up: bool = true
var is_standing: bool = true
var is_flying: bool = false
var is_dragging: bool = false
var is_valid_meld: bool = false:
	set(val):
		is_valid_meld = val
		set_highlight(&"valid_meld" if val else &"none")
var current_highlight: StringName = &"none"

# 3D Kinematics & Springs
var target_pos: Vector3 = Vector3.ZERO
var spring_pos: Vector3 = Vector3.ZERO
var spring_vel: Vector3 = Vector3.ZERO

var base_rot_deg: Vector3 = Vector3.ZERO
var target_rot_deg: Vector3 = Vector3.ZERO
var spring_rot_deg: Vector3 = Vector3.ZERO
var spring_rot_vel: Vector3 = Vector3.ZERO

var lift_y: float = 0.0 # Dynamic lift in meters when hovered/dragged
var target_lift_y: float = 0.0
var lift_vel: float = 0.0

# Visual nodes
var _visual_body: Node3D = null
var _face_mesh: MeshInstance3D = null
var _highlight_mesh: MeshInstance3D = null
var _pick_area: Area3D = null

# Backward-compat aliases for test assertions
var _number_label: Node:
	get: return _face_mesh
var _pip_label: Node:
	get: return _face_mesh


func _init() -> void:
	if _face_shader == null:
		_init_face_shader()


static func _init_face_shader() -> void:
	_face_shader = Shader.new()
	_face_shader.code = """shader_type spatial;
render_mode specular_schlick_ggx, diffuse_burley;

uniform sampler2D face_atlas : source_color, filter_linear_mipmap_anisotropic;
uniform vec2 uv_offset = vec2(0.0, 0.0);
uniform vec2 uv_scale = vec2(0.0714285, 0.25);

void fragment() {
	vec2 uv = clamp(UV, vec2(0.008), vec2(0.992));
	vec2 atlas_uv = uv_offset + uv * uv_scale;
	ALBEDO = texture(face_atlas, atlas_uv).rgb * 0.88;
	ROUGHNESS = 0.34;
	SPECULAR = 0.24;
}
"""


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


func refresh_face_texture() -> void:
	if _face_mesh != null and _face_mesh.material_override is ShaderMaterial:
		var sm := _face_mesh.material_override as ShaderMaterial
		sm.set_shader_parameter("face_atlas", TileFaceAtlas.get_texture())
		var rect: Rect2 = TileFaceAtlas.uv_rect(number, color_index, is_fake_okey)
		sm.set_shader_parameter("uv_offset", rect.position)
		sm.set_shader_parameter("uv_scale", rect.size)


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


func set_highlight(kind: StringName) -> void:
	current_highlight = kind
	if _highlight_mesh == null:
		return
	if kind == &"none":
		_highlight_mesh.visible = false
		return

	_highlight_mesh.visible = true
	var color := Color(1.0, 1.0, 1.0, 0.8)
	match kind:
		&"hover":
			color = Color(0.3, 0.75, 1.0, 0.85) # Cyan glow
		&"selected":
			color = Color(1.0, 0.80, 0.15, 0.95) # Amber gold
		&"valid_meld":
			color = Color(0.18, 0.90, 0.45, 0.95) # Emerald green
		&"invalid":
			color = Color(0.95, 0.22, 0.20, 0.95) # Ruby red

	var mat: StandardMaterial3D = _highlight_mesh.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = color
		mat.emission = color


func _process(delta: float) -> void:
	if is_dragging or is_flying:
		return

	# 1. Step 3D Position Spring
	var effective_target := target_pos + Vector3(0.0, lift_y, 0.0)
	if not spring_pos.is_equal_approx(effective_target) or spring_vel.length_squared() > 0.0001:
		var pos_res: Dictionary = SPRING3D.step_vector3(spring_pos, spring_vel, effective_target, delta, 26.0, 0.78)
		spring_pos = pos_res["position"]
		spring_vel = pos_res["velocity"]
		position = spring_pos

	# 2. Step 3D Rotation Spring with Velocity Tilt
	var tilt_deg: Vector3 = SPRING3D.calculate_tilt_3d(spring_vel, 6.0, 14.0)
	var effective_target_rot := target_rot_deg + tilt_deg
	if not spring_rot_deg.is_equal_approx(effective_target_rot) or spring_rot_vel.length_squared() > 0.01:
		var rot_res: Dictionary = SPRING3D.step_rotation3d(spring_rot_deg, spring_rot_vel, effective_target_rot, delta, 22.0, 0.74)
		spring_rot_deg = rot_res["rotation_deg"]
		spring_rot_vel = rot_res["velocity"]
		rotation_degrees = spring_rot_deg

	# 3. Step Lift Spring
	if not is_equal_approx(lift_y, target_lift_y) or absf(lift_vel) > 0.0001:
		var dl: float = lift_y - target_lift_y
		var accel: float = -2.0 * 0.70 * 30.0 * lift_vel - (30.0 * 30.0) * dl
		lift_vel += accel * delta
		lift_y += lift_vel * delta
		if absf(lift_y - target_lift_y) < 0.0005 and absf(lift_vel) < 0.002:
			lift_y = target_lift_y
			lift_vel = 0.0


func _rebuild_visuals() -> void:
	for child in get_children():
		child.queue_free()

	# 1. Physical 3D Ivory Body with Chamfered Edges (always built standing; orientation is root-controlled)
	_visual_body = TABLE_ART.build_tile(true, is_face_up)
	add_child(_visual_body)

	# 2. Texture Atlas Face Quad (0.040m x 0.0598m at local z = +0.00455m)
	if is_face_up:
		_face_mesh = MeshInstance3D.new()
		_face_mesh.name = "FaceAtlasQuad"
		var quad := QuadMesh.new()
		quad.size = Vector2(FACE_WIDTH, FACE_HEIGHT)
		_face_mesh.mesh = quad
		_face_mesh.position = Vector3(0.0, 0.0, FACE_LOCAL_Z)

		var mat := ShaderMaterial.new()
		mat.shader = _face_shader
		mat.set_shader_parameter("face_atlas", TileFaceAtlas.get_texture())
		var rect: Rect2 = TileFaceAtlas.uv_rect(number, color_index, is_fake_okey)
		mat.set_shader_parameter("uv_offset", rect.position)
		mat.set_shader_parameter("uv_scale", rect.size)
		_face_mesh.material_override = mat
		add_child(_face_mesh)

	# 3. Emissive Highlight Rim Mesh (slightly larger back quad)
	_highlight_mesh = MeshInstance3D.new()
	_highlight_mesh.name = "HighlightRim"
	var hl_quad := QuadMesh.new()
	hl_quad.size = Vector2(FACE_WIDTH + 0.003, FACE_HEIGHT + 0.003)
	_highlight_mesh.mesh = hl_quad
	_highlight_mesh.position = Vector3(0.0, 0.0, FACE_LOCAL_Z - 0.0001)
	var hl_mat := StandardMaterial3D.new()
	hl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hl_mat.emission_enabled = true
	_highlight_mesh.material_override = hl_mat
	_highlight_mesh.visible = false
	add_child(_highlight_mesh)

	# 4. Collision Pick Area (Layer 2 for 3D physics input picking in P5)
	_pick_area = Area3D.new()
	_pick_area.name = "PickArea"
	_pick_area.collision_layer = 2
	_pick_area.collision_mask = 0
	_pick_area.set_meta("tile_id", unique_id)
	var col_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(TILE_WIDTH, TILE_HEIGHT, TILE_DEPTH)
	col_shape.shape = box
	_pick_area.add_child(col_shape)
	add_child(_pick_area)
