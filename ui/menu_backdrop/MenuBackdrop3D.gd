extends Node3D
class_name MenuBackdrop3D

## Live 3D table scene rendered behind the main menu HUD.
## Composition is pushed to the center-right so the left action zone stays clear.

const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")
const OKEY_TABLE_CONFIG: Script = preload("res://core/config/Okey101TableConfig.gd")
const TABLE_ENVIRONMENT_SCRIPT: Script = preload("res://ui/common_tabletop/TableEnvironment3D.gd")
const VISUAL_QUALITY: Script = preload("res://ui/services/VisualQualityService.gd")
const PLAYER_PROFILE: Script = preload("res://ui/services/PlayerProfile.gd")
const MENU_STYLE: Script = preload("res://ui/services/MenuStyleRegistry.gd")

const TABLE_TOP_Y: float = 0.76
const CHARACTER_Z: float = -0.86
const SHIRT_TOKENS: Array[StringName] = [&"party_teal", &"party_amber", &"party_lime", &"party_danger"]
const TILE_COLORS: Array[Color] = [
	Color(0.82, 0.16, 0.14),
	Color(0.1, 0.32, 0.72),
	Color(0.12, 0.12, 0.12),
	Color(0.92, 0.66, 0.08),
]

@export var camera_h_offset: float = -0.55
@export var orbit_degrees: float = 6.0
@export var orbit_period: float = 22.0

var visual_settings: Dictionary = {}

var _camera_pivot: Node3D = null
var _camera: Camera3D = null
var _character: Node3D = null
var _body_root: Node3D = null
var _head: Node3D = null
var _left_arm: Node3D = null
var _right_arm: Node3D = null
var _emote_anchor: Marker3D = null
var _reaction_anchor: Marker3D = null
var _gesture_tween: Tween = null
var _gesturing: bool = false
var _time: float = 0.0


func _ready() -> void:
	if visual_settings.is_empty():
		visual_settings = VISUAL_QUALITY.default_settings()
	PLAYER_PROFILE.ensure_loaded()
	_build_environment()
	_build_room()
	_build_table()
	_build_character()
	_build_camera()


func get_camera() -> Camera3D:
	return _camera


func get_emote_anchors() -> Array[Node3D]:
	var anchors: Array[Node3D] = []
	if _emote_anchor != null:
		anchors.append(_emote_anchor)
	if _reaction_anchor != null:
		anchors.append(_reaction_anchor)
	return anchors


func set_paused(paused: bool) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT


func _process(delta: float) -> void:
	_time += delta
	if _camera_pivot != null:
		var orbit: float = sin(_time * TAU / orbit_period) * deg_to_rad(orbit_degrees)
		_camera_pivot.rotation.y = orbit
	if _body_root != null and not _gesturing:
		_body_root.position.y = sin(_time * 2.2) * 0.008
		_body_root.rotation.y = sin(_time * 0.7) * 0.12
	if _head != null:
		_head.rotation.z = sin(_time * 1.3) * 0.06
		_head.rotation.x = sin(_time * 0.9) * 0.04
	if not _gesturing:
		if _left_arm != null:
			_left_arm.rotation.z = -0.14 - sin(_time * 2.2) * 0.04
		if _right_arm != null:
			_right_arm.rotation.z = 0.14 + sin(_time * 2.2) * 0.04


# ── Gestures (driven by HUD signals) ────────────────────────────

func play_wave() -> void:
	if _right_arm == null or _gesturing:
		return
	_begin_gesture()
	_gesture_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gesture_tween.tween_property(_right_arm, "rotation:z", 2.6, 0.22)
	for i in range(3):
		_gesture_tween.tween_property(_right_arm, "rotation:x", 0.45, 0.14)
		_gesture_tween.tween_property(_right_arm, "rotation:x", -0.45, 0.14)
	_gesture_tween.tween_property(_right_arm, "rotation:x", 0.0, 0.1)
	_gesture_tween.tween_property(_right_arm, "rotation:z", 0.14, 0.3)
	_gesture_tween.tween_callback(_end_gesture)


func play_cheer() -> void:
	if _left_arm == null or _right_arm == null or _body_root == null:
		return
	_begin_gesture()
	_gesture_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gesture_tween.set_parallel(true)
	_gesture_tween.tween_property(_right_arm, "rotation:z", 2.85, 0.18)
	_gesture_tween.tween_property(_left_arm, "rotation:z", -2.85, 0.18)
	_gesture_tween.set_parallel(false)
	for i in range(2):
		_gesture_tween.tween_property(_body_root, "position:y", 0.14, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_gesture_tween.tween_property(_body_root, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_gesture_tween.set_parallel(true)
	_gesture_tween.tween_property(_right_arm, "rotation:z", 0.14, 0.3)
	_gesture_tween.tween_property(_left_arm, "rotation:z", -0.14, 0.3)
	_gesture_tween.set_parallel(false)
	_gesture_tween.tween_callback(_end_gesture)


func _begin_gesture() -> void:
	if _gesture_tween != null and _gesture_tween.is_valid():
		_gesture_tween.kill()
	_gesturing = true
	if _right_arm != null:
		_right_arm.rotation.x = 0.0
	_gesture_tween = create_tween()


func _end_gesture() -> void:
	_gesturing = false


# ── Scene construction ─────────────────────────────────────────

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.06, 0.08)
	var hdri: Texture2D = ASSET_REGISTRY.texture(ASSET_IDS.GAMEPLAY_HDRI_STUDIO_SMALL_03)
	if hdri != null:
		var sky_mat := PanoramaSkyMaterial.new()
		sky_mat.panorama = hdri
		var sky := Sky.new()
		sky.sky_material = sky_mat
		env.sky = sky
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		env.ambient_light_sky_contribution = 0.55
	else:
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.32, 0.3, 0.34)
	env.ambient_light_energy = 0.6
	VISUAL_QUALITY.apply_to_environment(env, visual_settings)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.12, 0.16)
	env.fog_density = 0.035
	env.fog_sky_affect = 0.0

	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)

	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.light_color = Color(1.0, 0.86, 0.68)
	key.light_energy = 1.4
	key.shadow_enabled = true
	key.rotation_degrees = Vector3(-52.0, 28.0, 0.0)
	add_child(key)

	var rim := OmniLight3D.new()
	rim.name = "RimLight"
	rim.light_color = MENU_STYLE.color(&"party_teal")
	rim.light_energy = 2.2
	rim.omni_range = 3.4
	rim.position = Vector3(0.9, 1.6, CHARACTER_Z - 0.9)
	add_child(rim)

	var fill := SpotLight3D.new()
	fill.name = "PendantLight"
	fill.light_color = Color(1.0, 0.76, 0.46)
	fill.light_energy = 3.0
	fill.spot_range = 3.2
	fill.spot_angle = 48.0
	fill.shadow_enabled = true
	fill.position = Vector3(0.0, 2.3, -0.1)
	fill.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	add_child(fill)

	VISUAL_QUALITY.apply_to_lights(key, rim, fill, visual_settings)


func _build_room() -> void:
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(14.0, 14.0)
	var floor := MeshInstance3D.new()
	floor.name = "Floor"
	floor.mesh = floor_mesh
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.16, 0.11, 0.08)
	floor_mat.roughness = 0.7
	var wood: Texture2D = ASSET_REGISTRY.texture(ASSET_IDS.GAMEPLAY_TEXTURE_TABLE_WOOD_DIFFUSE)
	if wood != null:
		floor_mat.albedo_texture = wood
		floor_mat.albedo_color = Color(0.42, 0.32, 0.26)
		floor_mat.uv1_scale = Vector3(6.0, 6.0, 1.0)
	floor.material_override = floor_mat
	add_child(floor)

	var rug_mesh := CylinderMesh.new()
	rug_mesh.top_radius = 1.6
	rug_mesh.bottom_radius = 1.6
	rug_mesh.height = 0.01
	rug_mesh.radial_segments = 64
	var rug := MeshInstance3D.new()
	rug.name = "Rug"
	rug.mesh = rug_mesh
	rug.position = Vector3(0.0, 0.005, -0.2)
	rug.material_override = _mat(Color(0.05, 0.22, 0.24), 0.95)
	add_child(rug)

	var wall_mesh := PlaneMesh.new()
	wall_mesh.size = Vector2(14.0, 6.0)
	var wall := MeshInstance3D.new()
	wall.name = "BackWall"
	wall.mesh = wall_mesh
	wall.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	wall.position = Vector3(0.0, 3.0, -3.2)
	wall.material_override = _mat(Color(0.12, 0.1, 0.12), 0.9)
	add_child(wall)


func _build_table() -> void:
	var config = OKEY_TABLE_CONFIG.create()
	var table: Node3D = TABLE_ENVIRONMENT_SCRIPT.new()
	table.name = "TableEnvironment3D"
	table.table_config = config
	table.position = Vector3(0.0, TABLE_TOP_Y, 0.0)
	add_child(table)

	var wood_mat := _mat(config.wood_color, 0.45)
	var wood_tex: Texture2D = ASSET_REGISTRY.texture(ASSET_IDS.GAMEPLAY_TEXTURE_TABLE_WOOD_DIFFUSE)
	if wood_tex != null:
		wood_mat.albedo_texture = wood_tex
		wood_mat.albedo_color = Color(0.85, 0.7, 0.6)
	var body := table.get_node_or_null("TableBody") as MeshInstance3D
	if body != null:
		body.material_override = wood_mat
	var felt := table.get_node_or_null("TableSurface") as MeshInstance3D
	var felt_tex: Texture2D = ASSET_REGISTRY.texture(ASSET_IDS.GAMEPLAY_TEXTURE_FELT_COLOR)
	if felt != null and felt_tex != null and felt.material_override is StandardMaterial3D:
		var felt_mat := felt.material_override as StandardMaterial3D
		felt_mat.albedo_texture = felt_tex
		felt_mat.uv1_scale = Vector3(3.0, 3.0, 1.0)

	var leg_mesh := CylinderMesh.new()
	leg_mesh.top_radius = 0.035
	leg_mesh.bottom_radius = 0.028
	leg_mesh.height = TABLE_TOP_Y - 0.05
	for x in [-0.52, 0.52]:
		for z in [-0.52, 0.52]:
			var leg := MeshInstance3D.new()
			leg.mesh = leg_mesh
			leg.material_override = wood_mat
			leg.position = Vector3(x, (TABLE_TOP_Y - 0.05) * 0.5, z)
			add_child(leg)

	var rack_mesh := BoxMesh.new()
	rack_mesh.size = Vector3(0.62, 0.05, 0.08)
	var rack_mat := _mat(config.rack_color, 0.5)
	var rack_spots: Array = [
		[Vector3(0.0, 0.025, 0.4), 0.0],
		[Vector3(0.0, 0.025, -0.4), 0.0],
		[Vector3(0.4, 0.025, 0.0), 90.0],
		[Vector3(-0.4, 0.025, 0.0), 90.0],
	]
	for spot in rack_spots:
		var rack := MeshInstance3D.new()
		rack.mesh = rack_mesh
		rack.material_override = rack_mat
		rack.position = spot[0]
		rack.rotation_degrees = Vector3(0.0, spot[1], 0.0)
		table.add_child(rack)

	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(0.04, 0.012, 0.058)
	var tile_mat := _mat(config.tile_face_color, 0.35)
	var dot_mesh := BoxMesh.new()
	dot_mesh.size = Vector3(0.018, 0.002, 0.026)
	var rng := RandomNumberGenerator.new()
	rng.seed = 101
	for i in range(14):
		var tile := MeshInstance3D.new()
		tile.mesh = tile_mesh
		tile.material_override = tile_mat
		tile.position = Vector3(rng.randf_range(-0.24, 0.24), 0.008, rng.randf_range(-0.2, 0.22))
		tile.rotation_degrees = Vector3(0.0, rng.randf_range(-40.0, 40.0), 0.0)
		var dot := MeshInstance3D.new()
		dot.mesh = dot_mesh
		dot.material_override = _mat(TILE_COLORS[i % TILE_COLORS.size()], 0.4)
		dot.position = Vector3(0.0, 0.007, 0.0)
		tile.add_child(dot)
		table.add_child(tile)


func _build_character() -> void:
	var skin := _mat(Color(1.0, 0.8, 0.64), 0.6)
	var shirt_token: StringName = SHIRT_TOKENS[posmod(PLAYER_PROFILE.avatar_index, SHIRT_TOKENS.size())]
	var shirt := _mat(MENU_STYLE.color(shirt_token), 0.55)
	var pants := _mat(Color(0.14, 0.16, 0.24), 0.7)
	var hair := _mat(Color(0.22, 0.13, 0.07), 0.5)
	var ink := _mat(Color(0.05, 0.04, 0.04), 0.3)

	_character = Node3D.new()
	_character.name = "PlayerCharacter"
	_character.position = Vector3(0.12, 0.0, CHARACTER_Z)
	add_child(_character)

	_body_root = Node3D.new()
	_body_root.name = "BodyRoot"
	_character.add_child(_body_root)

	for side in [-1.0, 1.0]:
		var leg := _capsule(0.07, 0.5, pants)
		leg.position = Vector3(0.08 * side, 0.25, 0.0)
		_body_root.add_child(leg)
		var shoe := _sphere(0.08, ink)
		shoe.scale = Vector3(1.0, 0.55, 1.35)
		shoe.position = Vector3(0.08 * side, 0.03, 0.03)
		_body_root.add_child(shoe)

	var torso := _capsule(0.19, 0.5, shirt)
	torso.position = Vector3(0.0, 0.7, 0.0)
	torso.scale = Vector3(1.0, 1.0, 0.82)
	_body_root.add_child(torso)

	_left_arm = _make_arm(-1.0, shirt, skin)
	_right_arm = _make_arm(1.0, shirt, skin)

	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0.0, 1.13, 0.0)
	_body_root.add_child(_head)
	var skull := _sphere(0.2, skin)
	_head.add_child(skull)
	var hair_cap := MeshInstance3D.new()
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 0.212
	cap_mesh.height = 0.212
	cap_mesh.is_hemisphere = true
	hair_cap.mesh = cap_mesh
	hair_cap.material_override = hair
	hair_cap.position = Vector3(0.0, 0.02, -0.01)
	hair_cap.rotation_degrees = Vector3(-28.0, 0.0, 0.0)
	_head.add_child(hair_cap)
	for side in [-1.0, 1.0]:
		var eye := _sphere(0.026, ink)
		eye.scale = Vector3(1.0, 1.55, 0.6)
		eye.position = Vector3(0.068 * side, 0.0, 0.185)
		_head.add_child(eye)
		var cheek := _sphere(0.03, _mat(Color(1.0, 0.55, 0.5), 0.7))
		cheek.scale = Vector3(1.2, 0.7, 0.4)
		cheek.position = Vector3(0.11 * side, -0.06, 0.16)
		_head.add_child(cheek)
	var mouth := _sphere(0.035, _mat(Color(0.55, 0.12, 0.12), 0.5))
	mouth.scale = Vector3(1.4, 0.45, 0.4)
	mouth.position = Vector3(0.0, -0.085, 0.178)
	_head.add_child(mouth)

	_emote_anchor = Marker3D.new()
	_emote_anchor.name = "EmoteAnchor"
	_emote_anchor.position = Vector3(0.0, 0.34, 0.0)
	_head.add_child(_emote_anchor)

	_reaction_anchor = Marker3D.new()
	_reaction_anchor.name = "ReactionAnchor"
	_reaction_anchor.position = Vector3(-0.62, 1.32, 0.4)
	add_child(_reaction_anchor)


func _make_arm(side: float, sleeve: Material, skin: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "RightArm" if side > 0.0 else "LeftArm"
	pivot.position = Vector3(0.2 * side, 0.86, 0.0)
	pivot.rotation.z = 0.14 * side
	_body_root.add_child(pivot)
	var arm := _capsule(0.055, 0.38, sleeve)
	arm.position = Vector3(0.0, -0.17, 0.0)
	pivot.add_child(arm)
	var hand := _sphere(0.065, skin)
	hand.position = Vector3(0.0, -0.38, 0.0)
	pivot.add_child(hand)
	return pivot


func _build_camera() -> void:
	_camera_pivot = Node3D.new()
	_camera_pivot.name = "CameraPivot"
	_camera_pivot.position = Vector3(0.0, 0.82, -0.25)
	add_child(_camera_pivot)
	_camera = Camera3D.new()
	_camera.name = "MenuCamera3D"
	_camera.fov = 38.0
	_camera.position = Vector3(0.0, 0.62, 2.7)
	_camera.h_offset = camera_h_offset
	_camera_pivot.add_child(_camera)
	_camera.look_at_from_position(_camera.global_position, _camera_pivot.global_position + Vector3(0.0, 0.08, 0.0), Vector3.UP)
	_camera.current = true


func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


func _sphere(radius: float, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = material
	return inst


func _capsule(radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = material
	return inst
