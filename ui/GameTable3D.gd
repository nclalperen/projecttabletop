extends Node

const GAME_TABLE_SCENE: PackedScene = preload("res://ui/GameTable.tscn")
const INVALID_TABLE_POS: Vector2 = Vector2(-99999.0, -99999.0)

# Asset paths
const CLOTH_TEX_PATH: String = "res://ai agent docs/assets/cloth-texture.png"
const WOOD_TEX_PATH: String = "res://ai agent docs/assets/rack-basecolor.png"
const RACK_MODEL_PATH: String = "res://ai agent docs/assets/rack.glb"
const TILE_MODEL_PATH: String = "res://ai agent docs/assets/tile.glb"

# Real-world dimensions (meters)
const TABLE_SIDE: float = 1.0
const TABLE_HEIGHT: float = 0.075
const FELT_SIDE: float = 0.80
const TILE_W: float = 0.025
const TILE_H: float = 0.040
const TILE_D: float = 0.004
const RACK_LEN: float = 0.45
const RACK_DEPTH: float = 0.11
const RACK_HEIGHT: float = 0.08
const RACK_MODEL_SIZE: Vector3 = Vector3(RACK_LEN, RACK_DEPTH, RACK_HEIGHT)
const RACK_MODEL_DEPTH_AXIS: float = RACK_HEIGHT
const RACK_MODEL_HEIGHT_AXIS: float = RACK_DEPTH
const RACK_MODEL_PRE_ROT_DEFAULT: Vector3 = Vector3(0.0, 56.4681, 0.0)
const USE_AUTO_RACK_MODEL_PRE_ROT: bool = false
const USE_AUTO_RACK_ROW_ANCHORS: bool = false
const FORCE_RACK_MODEL_WOOD_MATERIAL: bool = false
const RACK_ROW0_TILE_Y: float = 0.103
const RACK_ROW0_TILE_Z: float = -0.023
const RACK_ROW1_TILE_Y: float = 0.061
const RACK_ROW1_TILE_Z: float = 0.010
const RACK_ROW0_TILE_LIFT: float = 0.0006
const RACK_ROW1_TILE_LIFT: float = 0.0005
const RACK_ROW_TOP_TILT_DEG: float = -9.0
const RACK_ROW_BOTTOM_TILT_DEG: float = -7.0

# Placement
const RACK_GAP_TO_FELT: float = 0.005
const DISCARD_EDGE_INSET: float = 0.06
const DISCARD_HIT_RADIUS: float = 0.105
const DISCARD_SCREEN_PICK_RADIUS_PX: float = 96.0
const DISCARD_GUIDE_RADIUS: float = 0.038
const DRAW_HIT_RADIUS: float = 0.065
const MELD_LANE_DEPTH: float = 0.090
const MELD_LANE_LENGTH: float = 0.44
const MELD_LANE_INSET_FROM_EDGE: float = 0.040
const INDICATOR_GAP: float = 0.012

# Camera spec
const CAMERA_FOV: float = 70.0
const CAMERA_POS: Vector3 = Vector3(0.0, 0.92, 0.70)
const CAMERA_FOCUS: Vector3 = Vector3(0.0, 0.015, 0.02)

# Interaction tuning
const PICK_RADIUS_PX: float = 42.0
const SHOW_DEBUG_GUIDES: bool = false
const DRAG_PICK_RADIUS_PX: float = 84.0
const SLOT_PICK_RADIUS_PX: float = 180.0
const DRAG_START_DISTANCE_PX: float = 2.0
const INTERACT_COLLISION_LAYER: int = 1
const INTERACT_RAY_LENGTH: float = 5.0
const RACK_TILE_PICK_SIZE: Vector3 = Vector3(TILE_W * 0.86, TILE_H * 0.90, TILE_D * 3.8)
const STAGE_TILE_PICK_SIZE: Vector3 = Vector3(TILE_W * 0.94, TILE_H * 0.92, TILE_D * 4.8)
const RACK_SLOT_PICK_SIZE: Vector3 = Vector3(TILE_W * 0.95, TILE_H * 1.02, TILE_D * 8.0)
const DRAW_PICK_SIZE: Vector3 = Vector3(0.11, 0.035, 0.11)
const DISCARD_PICK_SIZE: Vector3 = Vector3(0.11, 0.032, 0.11)
const MELD_PICK_HEIGHT: float = 0.028

# Tile colors
const TILE_COLOR_MAP: Dictionary = {
	0: Color(0.85, 0.12, 0.10), # Red
	1: Color(0.10, 0.40, 0.75), # Blue
	2: Color(0.12, 0.12, 0.15), # Black
	3: Color(0.85, 0.65, 0.05), # Yellow
}

@onready var _camera: Camera3D = $World/Camera3D
@onready var _world_root: Node3D = $World
@onready var _backdrop: MeshInstance3D = $World/Backdrop
@onready var _table_body: MeshInstance3D = $World/TableBody
@onready var _table_surface: MeshInstance3D = $World/TableSurface
@onready var _key_light: DirectionalLight3D = $World/KeyLight
@onready var _rim_light: DirectionalLight3D = $World/RimLight
@onready var _fill_light: OmniLight3D = $World/FillLight
@onready var _game_viewport: SubViewport = $GameViewport

# Hidden gameplay table (logic host)
var _game_table: Node = null
var _pending_rule_config: RuleConfig = null
var _pending_seed: int = 0
var _pending_player_count: int = 4
var _has_pending_config: bool = false

# Top HUD
var _hud_layer: CanvasLayer = null
var _hud_bar: PanelContainer = null
var _hud_instructions: Label = null
var _hud_turn: Label = null
var _hud_phase: Label = null
var _hud_deck: Label = null
var _hud_okey: Label = null
var _src_instructions: Label = null
var _src_turn: Label = null
var _src_phase: Label = null
var _src_deck: Label = null
var _src_okey: Label = null
var _src_top_bar: Control = null

# 3D world objects
var _dynamic_root: Node3D = null
var _world_racks: Array[Node3D] = []
var _world_rack_tile_containers: Array[Node3D] = []
var _world_rack_labels: Array[Label3D] = []
var _deck_pile_container: Node3D = null
var _indicator_3d: Node3D = null
var _discard_pile_containers: Array[Node3D] = []
var _world_stage_container: Node3D = null
var _draw_guide: Node3D = null
var _discard_guides: Array[Node3D] = []
var _meld_guides: Array[Node3D] = []
var _draw_pick_area: Area3D = null
var _discard_pick_areas: Array[Area3D] = []
var _meld_pick_areas: Array[Area3D] = []

# Local interaction geometry
var _table_local_discard_points: Array[Vector2] = []
var _table_local_meld_lanes: Array[Rect2] = []
var _draw_hotspot_center: Vector2 = Vector2.ZERO

# Interaction pick records
var _local_rack_tile_hits: Array[Dictionary] = []
var _stage_tile_hits: Array[Dictionary] = []
var _local_rack_slot_hits: Array[Dictionary] = []

# Drag state
var _drag_candidate_tile_id: int = -1
var _drag_candidate_slot: int = -1
var _drag_candidate_stage_slot: int = -1
var _drag_press_screen: Vector2 = Vector2.ZERO
var _drag_preview: Node3D = null
var _drag_active: bool = false

# Imported model scenes
var _rack_model_scene: PackedScene = null
var _tile_model_scene: PackedScene = null
var _rack_model_pre_rot_deg: Vector3 = Vector3.ZERO
var _rack_row0_anchor: Vector3 = Vector3(0.0, RACK_ROW0_TILE_Y, RACK_ROW0_TILE_Z)
var _rack_row1_anchor: Vector3 = Vector3(0.0, RACK_ROW1_TILE_Y, RACK_ROW1_TILE_Z)
var _rack_row_anchors_calibrated: bool = false

# Sync hashes
var _last_selected_tile_id: int = -1
var _last_world_rack_hashes: Array[int] = [-1, -1, -1, -1]
var _last_world_stage_hash: int = -1
var _last_world_deck_hash: int = -1
var _last_world_discard_hashes: Array[int] = [-1, -1, -1, -1]
var _last_world_label_hash: int = -1

# Materials
var _rack_wood_material: StandardMaterial3D = null
var _table_wood_material: StandardMaterial3D = null
var _tile_face_material: StandardMaterial3D = null
var _tile_back_material: StandardMaterial3D = null


func _ready() -> void:
	_configure_environment()
	_configure_world()
	_configure_materials()
	_load_model_assets()
	_create_world_elements()
	_create_hud_overlay()
	_resize_subviewport()
	_spawn_game_table()
	get_viewport().size_changed.connect(_resize_subviewport)
	get_viewport().size_changed.connect(_layout_hud)
	set_process(true)


func configure_game(rule_config: RuleConfig, game_seed: int, player_count: int) -> void:
	_pending_rule_config = rule_config
	_pending_seed = game_seed
	_pending_player_count = player_count
	_has_pending_config = true
	_apply_pending_config_if_ready()


func _process(_delta: float) -> void:
	_sync_hud_from_table()
	_sync_world_racks()
	_sync_world_stage_tiles()
	_sync_world_deck()
	_sync_world_discards()
	_sync_world_labels()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _drag_candidate_tile_id != -1 and not _drag_active:
			if mm.position.distance_to(_drag_press_screen) >= DRAG_START_DISTANCE_PX:
				_start_drag_preview()
		if _drag_active:
			_update_drag_preview(mm.position)
			get_viewport().set_input_as_handled()
		return

	if event is not InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return

	if mb.pressed:
		if _hud_bar != null and _hud_bar.visible and _hud_bar.get_global_rect().has_point(mb.position):
			return
		_begin_drag_candidate_from_pick(mb.position)
		if _drag_candidate_tile_id != -1:
			get_viewport().set_input_as_handled()
			return
		var pick: Dictionary = _raycast_pick(mb.position)
		var table_pos: Vector2 = _screen_to_table_local(mb.position)
		_handle_world_tap(pick, table_pos)
		get_viewport().set_input_as_handled()
		return

	# Mouse release
	if _drag_candidate_tile_id != -1 or _drag_active:
		_finish_drag(mb.position)
		get_viewport().set_input_as_handled()


func _configure_environment() -> void:
	RenderingServer.set_default_clear_color(Color(0.09, 0.05, 0.035, 1.0))
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.07, 0.045, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.92, 0.85, 0.78, 1.0)
	env.ambient_light_energy = 0.55
	world_env.environment = env
	_world_root.add_child(world_env)
	_world_root.move_child(world_env, 0)


func _configure_world() -> void:
	_backdrop.position = Vector3(0.0, 2.2, -5.8)
	_backdrop.rotation_degrees = Vector3(0.0, 0.0, 0.0)

	var body_mesh := _table_body.mesh as BoxMesh
	if body_mesh != null:
		body_mesh.size = Vector3(TABLE_SIDE, TABLE_HEIGHT, TABLE_SIDE)
	_table_body.position = Vector3(0.0, -TABLE_HEIGHT * 0.5, 0.0)

	var surface_mesh := _table_surface.mesh as QuadMesh
	if surface_mesh != null:
		surface_mesh.size = Vector2(FELT_SIDE, FELT_SIDE)
	_table_surface.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_table_surface.position = Vector3(0.0, 0.0015, 0.0)

	_camera.current = true
	_camera.fov = CAMERA_FOV
	_camera.position = CAMERA_POS
	_camera.look_at(CAMERA_FOCUS, Vector3.UP)

	_key_light.position = Vector3(1.5, 2.0, 1.3)
	_key_light.rotation_degrees = Vector3(-58.0, 28.0, 0.0)
	_key_light.light_energy = 1.35

	_rim_light.position = Vector3(-1.7, 1.8, -1.2)
	_rim_light.rotation_degrees = Vector3(-42.0, -145.0, 0.0)
	_rim_light.light_energy = 0.50

	_fill_light.position = Vector3(0.0, 0.80, 0.65)
	_fill_light.light_energy = 0.34
	_fill_light.omni_range = 3.4


func _configure_materials() -> void:
	var backdrop_mat := StandardMaterial3D.new()
	backdrop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	backdrop_mat.albedo_color = Color(0.20, 0.12, 0.08, 0.94)
	backdrop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	backdrop_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_backdrop.set_surface_override_material(0, backdrop_mat)

	_table_wood_material = StandardMaterial3D.new()
	_table_wood_material.albedo_color = Color(0.34, 0.20, 0.12)
	_table_wood_material.roughness = 0.90
	_table_wood_material.metallic = 0.0
	var wood_tex: Texture2D = load(WOOD_TEX_PATH) as Texture2D
	if wood_tex != null:
		_table_wood_material.albedo_texture = wood_tex
		_table_wood_material.uv1_triplanar = true
		_table_wood_material.uv1_scale = Vector3(2.0, 2.0, 2.0)
	_table_body.set_surface_override_material(0, _table_wood_material)

	var felt_mat := StandardMaterial3D.new()
	felt_mat.albedo_color = Color(0.12, 0.45, 0.32)
	felt_mat.roughness = 0.98
	felt_mat.metallic = 0.0
	felt_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cloth_tex: Texture2D = load(CLOTH_TEX_PATH) as Texture2D
	if cloth_tex != null:
		felt_mat.albedo_texture = cloth_tex
		felt_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		felt_mat.uv1_scale = Vector3(3.6, 3.6, 1.0)
	_table_surface.set_surface_override_material(0, felt_mat)

	_rack_wood_material = StandardMaterial3D.new()
	_rack_wood_material.albedo_color = Color(0.55, 0.36, 0.22)
	_rack_wood_material.roughness = 0.82
	_rack_wood_material.metallic = 0.0
	if wood_tex != null:
		_rack_wood_material.albedo_texture = wood_tex
		_rack_wood_material.uv1_triplanar = true
		_rack_wood_material.uv1_scale = Vector3(2.7, 2.7, 2.7)

	_tile_face_material = StandardMaterial3D.new()
	_tile_face_material.albedo_color = Color(0.95, 0.93, 0.86)
	_tile_face_material.roughness = 0.68
	_tile_face_material.metallic = 0.0

	_tile_back_material = StandardMaterial3D.new()
	_tile_back_material.albedo_color = Color(0.89, 0.86, 0.78)
	_tile_back_material.roughness = 0.78
	_tile_back_material.metallic = 0.0


func _load_model_assets() -> void:
	_rack_model_scene = load(RACK_MODEL_PATH) as PackedScene
	_tile_model_scene = load(TILE_MODEL_PATH) as PackedScene
	if USE_AUTO_RACK_MODEL_PRE_ROT:
		_rack_model_pre_rot_deg = _estimate_rack_model_pre_rotation(_rack_model_scene)
	else:
		_rack_model_pre_rot_deg = RACK_MODEL_PRE_ROT_DEFAULT


func _create_world_elements() -> void:
	if _dynamic_root != null and is_instance_valid(_dynamic_root):
		_dynamic_root.queue_free()

	_dynamic_root = Node3D.new()
	_dynamic_root.name = "DynamicWorld"
	_world_root.add_child(_dynamic_root)

	_world_racks.clear()
	_world_rack_tile_containers.clear()
	_world_rack_labels.clear()
	_discard_pile_containers.clear()
	_discard_guides.clear()
	_meld_guides.clear()
	_discard_pick_areas.clear()
	_meld_pick_areas.clear()
	_draw_pick_area = null
	_local_rack_tile_hits.clear()
	_stage_tile_hits.clear()
	_last_world_rack_hashes = [-1, -1, -1, -1]
	_last_world_stage_hash = -1
	_last_world_deck_hash = -1
	_last_world_discard_hashes = [-1, -1, -1, -1]
	_last_world_label_hash = -1

	var felt_half: float = FELT_SIDE * 0.5
	var rack_center: float = TABLE_SIDE * 0.5 - RACK_DEPTH * 0.5 - RACK_GAP_TO_FELT
	var rack_defs: Array[Dictionary] = [
		{"player": 0, "pos": Vector2(0.0, rack_center), "rot_y": 0.0, "name": "P0"},
		{"player": 1, "pos": Vector2(rack_center, 0.0), "rot_y": 90.0, "name": "P1"},
		{"player": 2, "pos": Vector2(0.0, -rack_center), "rot_y": 180.0, "name": "P2"},
		{"player": 3, "pos": Vector2(-rack_center, 0.0), "rot_y": -90.0, "name": "P3"},
	]

	for cfg in rack_defs:
		var rack: Node3D = _create_3d_rack()
		rack.name = "Rack%d" % int(cfg["player"])
		_dynamic_root.add_child(rack)
		rack.position = _table_local_to_world(cfg["pos"] as Vector2, 0.0)
		rack.rotation_degrees.y = cfg["rot_y"] as float
		_world_racks.append(rack)

		var tile_container := Node3D.new()
		tile_container.name = "TileContainer"
		rack.add_child(tile_container)
		_world_rack_tile_containers.append(tile_container)

		var label := _create_rack_back_label(str(cfg["name"]))
		if int(cfg["player"]) == 0:
			label.visible = false
		rack.add_child(label)
		_world_rack_labels.append(label)

	# Deck + indicator
	_draw_hotspot_center = Vector2.ZERO
	_deck_pile_container = Node3D.new()
	_deck_pile_container.name = "DeckPile"
	_deck_pile_container.position = _table_local_to_world(_draw_hotspot_center, 0.0015)
	_dynamic_root.add_child(_deck_pile_container)
	_draw_pick_area = _create_pick_box(
		_dynamic_root,
		"DrawPickArea",
		DRAW_PICK_SIZE,
		_table_local_to_world(_draw_hotspot_center, 0.018),
		Vector3.ZERO,
		{"kind": "draw_stack"}
	)
	_indicator_3d = null

	# Discard piles (player right corners)
	var corner: float = felt_half - DISCARD_EDGE_INSET
	_table_local_discard_points = [
		Vector2(corner, corner),     # P0 -> southeast
		Vector2(corner, -corner),    # P1 -> northeast
		Vector2(-corner, -corner),   # P2 -> northwest
		Vector2(-corner, corner),    # P3 -> southwest
	]

	for p in range(4):
		var pile := Node3D.new()
		pile.name = "Discard%d" % p
		pile.position = _table_local_to_world(_table_local_discard_points[p], 0.002)
		_dynamic_root.add_child(pile)
		_discard_pile_containers.append(pile)
		var guide_color: Color = Color(0.92, 0.78, 0.26, 0.72) if p == 0 else Color(0.78, 0.84, 0.90, 0.42)
		var guide := _create_dotted_discard_guide(DISCARD_GUIDE_RADIUS, 18, guide_color)
		guide.name = "DiscardGuide%d" % p
		guide.position = _table_local_to_world(_table_local_discard_points[p], 0.003)
		_dynamic_root.add_child(guide)
		_discard_guides.append(guide)
		var d_pick: Area3D = _create_pick_box(
			_dynamic_root,
			"DiscardPick%d" % p,
			DISCARD_PICK_SIZE,
			_table_local_to_world(_table_local_discard_points[p], 0.016),
			Vector3.ZERO,
			{"kind": "discard_zone", "player": p}
		)
		_discard_pick_areas.append(d_pick)

	# Meld lanes (front of each rack, on felt)
	_table_local_meld_lanes = []
	var lane_h: float = MELD_LANE_DEPTH
	var lane_w: float = MELD_LANE_LENGTH
	_table_local_meld_lanes.append(Rect2(
		Vector2(-lane_w * 0.5, felt_half - MELD_LANE_INSET_FROM_EDGE - lane_h),
		Vector2(lane_w, lane_h)
	)) # P0
	_table_local_meld_lanes.append(Rect2(
		Vector2(felt_half - MELD_LANE_INSET_FROM_EDGE - lane_h, -lane_w * 0.5),
		Vector2(lane_h, lane_w)
	)) # P1
	_table_local_meld_lanes.append(Rect2(
		Vector2(-lane_w * 0.5, -felt_half + MELD_LANE_INSET_FROM_EDGE),
		Vector2(lane_w, lane_h)
	)) # P2
	_table_local_meld_lanes.append(Rect2(
		Vector2(-felt_half + MELD_LANE_INSET_FROM_EDGE, -lane_w * 0.5),
		Vector2(lane_h, lane_w)
	)) # P3

	for i in range(_table_local_meld_lanes.size()):
		var lane_rect: Rect2 = _table_local_meld_lanes[i]
		var pick_size := Vector3(lane_rect.size.x, MELD_PICK_HEIGHT, lane_rect.size.y)
		var m_pick := _create_pick_box(
			_dynamic_root,
			"MeldPick%d" % i,
			pick_size,
			_table_local_to_world(lane_rect.get_center(), 0.015),
			Vector3.ZERO,
			{"kind": "meld_lane", "player": i}
		)
		_meld_pick_areas.append(m_pick)

	if SHOW_DEBUG_GUIDES:
		for i in range(_table_local_meld_lanes.size()):
			var lane_rect: Rect2 = _table_local_meld_lanes[i]
			var lane_guide := _create_surface_guide(lane_rect.size, Color(0.2, 0.7, 0.4, 0.12))
			lane_guide.position = _table_local_to_world(lane_rect.get_center(), 0.003)
			lane_guide.rotation_degrees.y = 90.0 if i == 1 or i == 3 else 0.0
			_dynamic_root.add_child(lane_guide)
			_meld_guides.append(lane_guide)

	if SHOW_DEBUG_GUIDES:
		_draw_guide = _create_surface_guide(Vector2(0.12, 0.16), Color(0.8, 0.7, 0.25, 0.14))
		_draw_guide.position = _table_local_to_world(_draw_hotspot_center, 0.003)
		_dynamic_root.add_child(_draw_guide)

	_world_stage_container = Node3D.new()
	_world_stage_container.name = "StageTiles"
	_dynamic_root.add_child(_world_stage_container)

func _create_3d_rack() -> Node3D:
	var rack := Node3D.new()
	rack.name = "Rack3D"
	var visual_root := Node3D.new()
	visual_root.name = "Visual"
	rack.add_child(visual_root)

	if _rack_model_scene != null:
		var rack_model := _instantiate_scaled_model(
			_rack_model_scene,
			RACK_MODEL_SIZE,
			_rack_wood_material if FORCE_RACK_MODEL_WOOD_MATERIAL else null,
			_rack_model_pre_rot_deg,
			true
		)
		if rack_model != null:
			rack_model.name = "Model"
			visual_root.add_child(rack_model)
			if USE_AUTO_RACK_ROW_ANCHORS:
				_try_capture_rack_row_anchors(rack_model)
			return rack

	# Fallback procedural rack
	var half_len: float = RACK_LEN * 0.5
	var half_depth: float = RACK_DEPTH * 0.5
	_add_rack_piece(visual_root, Vector3(RACK_LEN, 0.010, RACK_DEPTH), Vector3(0.0, 0.005, 0.0), Vector3.ZERO)
	_add_rack_piece(visual_root, Vector3(RACK_LEN, 0.060, 0.012), Vector3(0.0, 0.040, -half_depth + 0.006), Vector3.ZERO)
	_add_rack_piece(visual_root, Vector3(RACK_LEN, 0.018, 0.010), Vector3(0.0, 0.019, half_depth - 0.005), Vector3.ZERO)
	_add_rack_piece(visual_root, Vector3(RACK_LEN - 0.040, 0.012, 0.010), Vector3(0.0, 0.026, -0.010), Vector3.ZERO)
	_add_rack_piece(visual_root, Vector3(RACK_LEN - 0.030, 0.008, RACK_DEPTH * 0.48), Vector3(0.0, 0.020, -0.020), Vector3(-12.0, 0.0, 0.0))
	_add_rack_piece(visual_root, Vector3(RACK_LEN - 0.030, 0.008, RACK_DEPTH * 0.40), Vector3(0.0, 0.014, 0.020), Vector3(-8.0, 0.0, 0.0))
	_add_rack_piece(visual_root, Vector3(0.010, 0.055, RACK_DEPTH), Vector3(-half_len + 0.005, 0.032, 0.0), Vector3.ZERO)
	_add_rack_piece(visual_root, Vector3(0.010, 0.055, RACK_DEPTH), Vector3(half_len - 0.005, 0.032, 0.0), Vector3.ZERO)
	return rack


func _add_rack_piece(parent: Node3D, size: Vector3, pos: Vector3, rot_deg: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.rotation_degrees = rot_deg
	mesh.set_surface_override_material(0, _rack_wood_material)
	parent.add_child(mesh)


func _create_rack_back_label(text: String) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = 14
	lbl.pixel_size = 0.00085
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.modulate = Color(0.95, 0.91, 0.80, 0.88)
	lbl.outline_modulate = Color(0.07, 0.04, 0.03, 0.80)
	lbl.outline_size = 4
	lbl.no_depth_test = false
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.position = Vector3(0.0, RACK_MODEL_HEIGHT_AXIS * 0.52, -RACK_MODEL_DEPTH_AXIS * 0.50 - 0.003)
	lbl.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	return lbl


func _create_tile_face_up(tile_data, standing: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "TileFaceUp"
	var body: Node3D = _create_tile_body_node(standing, true)
	root.add_child(body)

	var col: int = int(tile_data.color) if tile_data != null else 0
	var strip_col: Color = TILE_COLOR_MAP.get(col, Color.WHITE)
	var strip := MeshInstance3D.new()
	var strip_mesh := BoxMesh.new()
	var strip_mat := StandardMaterial3D.new()
	strip_mat.albedo_color = strip_col
	strip_mat.roughness = 0.62
	strip_mat.metallic = 0.0
	if standing:
		strip_mesh.size = Vector3(TILE_W * 0.90, 0.003, TILE_D + 0.001)
		strip.position = Vector3(0.0, -TILE_H * 0.50 + 0.006, 0.0)
	else:
		strip_mesh.size = Vector3(TILE_W * 0.90, TILE_D + 0.001, 0.003)
		strip.position = Vector3(0.0, TILE_D * 0.50 + 0.0005, TILE_H * 0.36)
	strip.mesh = strip_mesh
	strip.set_surface_override_material(0, strip_mat)
	root.add_child(strip)

	if tile_data != null:
		var lbl := Label3D.new()
		lbl.text = str(int(tile_data.number))
		if int(tile_data.kind) != 0:
			lbl.text = "*" + lbl.text
		lbl.font_size = 12 if standing else 30
		lbl.pixel_size = 0.00023 if standing else 0.00120
		lbl.modulate = strip_col
		lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.35)
		lbl.outline_size = 1 if standing else 2
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.no_depth_test = not standing
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.double_sided = true
		if standing:
			lbl.position = Vector3(0.0, TILE_H * 0.23, TILE_D * 0.50 + 0.0012)
		else:
			lbl.position = Vector3(0.0, TILE_D * 0.50 + 0.0042, 0.0)
			lbl.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		root.add_child(lbl)

	return root


func _create_tile_face_down(standing: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "TileFaceDown"
	var body: Node3D = _create_tile_body_node(standing, false)
	root.add_child(body)
	return root


func _create_tile_body_node(standing: bool, face_up: bool) -> Node3D:
	var target: Vector3 = Vector3(TILE_W, TILE_H, TILE_D) if standing else Vector3(TILE_W, TILE_D, TILE_H)
	var pre_rot: Vector3 = Vector3(90.0, 0.0, 0.0) if standing else Vector3.ZERO
	var mat: Material = _tile_face_material if face_up else _tile_back_material
	if _tile_model_scene != null:
		var model := _instantiate_scaled_model(_tile_model_scene, target, mat, pre_rot, false)
		if model != null:
			return model
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = target
	body.mesh = box
	body.set_surface_override_material(0, mat)
	var fallback := Node3D.new()
	fallback.add_child(body)
	return fallback


func _instantiate_scaled_model(scene: PackedScene, target_size: Vector3, override_material: Material, pre_rotation_deg: Vector3 = Vector3.ZERO, floor_align: bool = false) -> Node3D:
	if scene == null:
		return null
	var raw := scene.instantiate() as Node3D
	if raw == null:
		return null
	raw.rotation_degrees = pre_rotation_deg

	var holder := Node3D.new()
	holder.add_child(raw)

	var bounds: AABB = _compute_node_aabb(holder)
	if bounds.size.x <= 0.00001 or bounds.size.y <= 0.00001 or bounds.size.z <= 0.00001:
		raw.queue_free()
		holder.queue_free()
		return null

	var center: Vector3 = bounds.position + bounds.size * 0.5
	if floor_align:
		raw.position = Vector3(-center.x, -bounds.position.y, -center.z)
	else:
		raw.position = -center

	holder.scale = Vector3(
		target_size.x / bounds.size.x,
		target_size.y / bounds.size.y,
		target_size.z / bounds.size.z
	)

	if override_material != null:
		_apply_material_recursive(raw, override_material)
	return holder


func _compute_node_aabb(root: Node3D) -> AABB:
	var acc: Dictionary = {
		"has_any": false,
		"min": Vector3.ZERO,
		"max": Vector3.ZERO,
	}
	_collect_mesh_bounds(root, Transform3D.IDENTITY, acc)
	if not bool(acc.get("has_any", false)):
		return AABB()
	var min_v: Vector3 = acc.get("min", Vector3.ZERO)
	var max_v: Vector3 = acc.get("max", Vector3.ZERO)
	return AABB(min_v, max_v - min_v)


func _collect_mesh_bounds(node: Node, parent_xform: Transform3D, acc: Dictionary) -> void:
	if node is not Node3D:
		return
	var n3d := node as Node3D
	var xform: Transform3D = parent_xform * n3d.transform
	if n3d is MeshInstance3D:
		var mi := n3d as MeshInstance3D
		if mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				var arrays: Array = mi.mesh.surface_get_arrays(s)
				var verts = arrays[Mesh.ARRAY_VERTEX]
				if verts is not PackedVector3Array:
					continue
				for v in verts as PackedVector3Array:
					var p: Vector3 = xform * v
					if not bool(acc.get("has_any", false)):
						acc["has_any"] = true
						acc["min"] = p
						acc["max"] = p
					else:
						var min_v: Vector3 = acc.get("min", p)
						var max_v: Vector3 = acc.get("max", p)
						min_v = Vector3(minf(min_v.x, p.x), minf(min_v.y, p.y), minf(min_v.z, p.z))
						max_v = Vector3(maxf(max_v.x, p.x), maxf(max_v.y, p.y), maxf(max_v.z, p.z))
						acc["min"] = min_v
						acc["max"] = max_v
	for child in n3d.get_children():
		_collect_mesh_bounds(child, xform, acc)


func _estimate_rack_model_pre_rotation(scene: PackedScene) -> Vector3:
	if scene == null:
		return Vector3.ZERO
	var root := scene.instantiate() as Node3D
	if root == null:
		return Vector3.ZERO
	var stats: Array[Dictionary] = []
	_collect_surface_stats(root, Transform3D.IDENTITY, stats)
	root.queue_free()
	if stats.is_empty():
		return Vector3.ZERO

	var best_black: Dictionary = {}
	var best_luma: float = 1000.0
	for st in stats:
		var c: Color = st.get("color", Color(0.5, 0.5, 0.5, 1.0))
		var n: Vector3 = st.get("normal", Vector3.ZERO)
		if n.length() < 0.0001:
			continue
		var luma: float = c.r + c.g + c.b
		if luma < best_luma:
			best_luma = luma
			best_black = st
	if best_black.is_empty():
		return Vector3.ZERO

	var black_n: Vector3 = (best_black.get("normal", Vector3.ZERO) as Vector3).normalized()
	var xz: Vector2 = Vector2(black_n.x, black_n.z)
	if xz.length() < 0.0001:
		return Vector3.ZERO
	xz = xz.normalized()
	var yaw_deg: float = rad_to_deg(atan2(xz.x, -xz.y))
	return Vector3(0.0, yaw_deg, 0.0)


func _try_capture_rack_row_anchors(rack_model_root: Node3D) -> void:
	if _rack_row_anchors_calibrated:
		return
	if rack_model_root == null or not is_instance_valid(rack_model_root):
		return
	var stats: Array[Dictionary] = []
	_collect_surface_stats(rack_model_root, Transform3D.IDENTITY, stats)
	if stats.is_empty():
		return

	var blue_ref := Color(0.3492, 0.3414, 0.9063, 1.0)
	var yellow_ref := Color(0.9063, 0.9051, 0.2432, 1.0)
	var best_blue: Dictionary = {}
	var best_yellow: Dictionary = {}
	var best_blue_d: float = 1000.0
	var best_yellow_d: float = 1000.0
	for st in stats:
		var c: Color = st.get("color", Color(0.5, 0.5, 0.5, 1.0))
		var d_blue: float = _color_distance(c, blue_ref)
		var d_yellow: float = _color_distance(c, yellow_ref)
		if d_blue < best_blue_d:
			best_blue_d = d_blue
			best_blue = st
		if d_yellow < best_yellow_d:
			best_yellow_d = d_yellow
			best_yellow = st

	if best_blue.is_empty() or best_yellow.is_empty():
		return
	if best_blue_d > 0.45 or best_yellow_d > 0.45:
		return

	var blue_c: Vector3 = best_blue.get("center", _rack_row0_anchor)
	var yellow_c: Vector3 = best_yellow.get("center", _rack_row1_anchor)

	# Keep fallback X=0 for symmetric slot placement and clamp to plausible rack volume.
	_rack_row0_anchor = Vector3(
		0.0,
		clampf(blue_c.y, 0.020, RACK_MODEL_HEIGHT_AXIS - 0.006),
		clampf(blue_c.z, -RACK_MODEL_DEPTH_AXIS * 0.5 + 0.003, RACK_MODEL_DEPTH_AXIS * 0.5 - 0.003)
	)
	_rack_row1_anchor = Vector3(
		0.0,
		clampf(yellow_c.y, 0.012, RACK_MODEL_HEIGHT_AXIS - 0.010),
		clampf(yellow_c.z, -RACK_MODEL_DEPTH_AXIS * 0.5 + 0.003, RACK_MODEL_DEPTH_AXIS * 0.5 - 0.003)
	)

	# Enforce top row above bottom row if model colors are swapped.
	if _rack_row0_anchor.y < _rack_row1_anchor.y:
		var tmp: Vector3 = _rack_row0_anchor
		_rack_row0_anchor = _rack_row1_anchor
		_rack_row1_anchor = tmp

	# User requested: top row should be at the greater local Z depth.
	if _rack_row0_anchor.z < _rack_row1_anchor.z:
		var ztmp: float = _rack_row0_anchor.z
		_rack_row0_anchor.z = _rack_row1_anchor.z
		_rack_row1_anchor.z = ztmp

	# Keep visible row separation for reliable seating/picking.
	if absf(_rack_row0_anchor.z - _rack_row1_anchor.z) < 0.010:
		_rack_row0_anchor.z = clampf(_rack_row0_anchor.z + 0.006, -RACK_MODEL_DEPTH_AXIS * 0.5 + 0.003, RACK_MODEL_DEPTH_AXIS * 0.5 - 0.003)
		_rack_row1_anchor.z = clampf(_rack_row1_anchor.z - 0.006, -RACK_MODEL_DEPTH_AXIS * 0.5 + 0.003, RACK_MODEL_DEPTH_AXIS * 0.5 - 0.003)
	_rack_row_anchors_calibrated = true


func _collect_surface_stats(node: Node, parent_xform: Transform3D, out_stats: Array[Dictionary]) -> void:
	if node is not Node3D:
		return
	var n3d := node as Node3D
	var xform: Transform3D = parent_xform * n3d.transform
	if n3d is MeshInstance3D:
		var mi := n3d as MeshInstance3D
		if mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				var arrays: Array = mi.mesh.surface_get_arrays(s)
				var verts = arrays[Mesh.ARRAY_VERTEX]
				if verts is not PackedVector3Array:
					continue
				var count: int = (verts as PackedVector3Array).size()
				if count <= 0:
					continue
				var center: Vector3 = Vector3.ZERO
				for v in verts as PackedVector3Array:
					center += xform * v
				center /= float(count)

				var normal: Vector3 = Vector3.ZERO
				var normals = arrays[Mesh.ARRAY_NORMAL]
				if normals is PackedVector3Array and (normals as PackedVector3Array).size() == count:
					for n in normals as PackedVector3Array:
						normal += (xform.basis * n).normalized()
				if normal.length() > 0.0001:
					normal = normal.normalized()

				out_stats.append({
					"color": _get_surface_color(mi, s),
					"center": center,
					"normal": normal,
				})
	for child in n3d.get_children():
		_collect_surface_stats(child, xform, out_stats)


func _get_surface_color(mi: MeshInstance3D, surface_idx: int) -> Color:
	var mat: Material = mi.get_surface_override_material(surface_idx)
	if mat == null and mi.mesh != null:
		mat = mi.mesh.surface_get_material(surface_idx)
	if mat is BaseMaterial3D:
		return (mat as BaseMaterial3D).albedo_color
	return Color(0.5, 0.5, 0.5, 1.0)


func _color_distance(a: Color, b: Color) -> float:
	var dr: float = a.r - b.r
	var dg: float = a.g - b.g
	var db: float = a.b - b.b
	return sqrt(dr * dr + dg * dg + db * db)


func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				mi.set_surface_override_material(s, mat)
	for child in node.get_children():
		_apply_material_recursive(child, mat)


func _sync_world_racks() -> void:
	if _game_table == null or not is_instance_valid(_game_table):
		return
	if not _game_table.has_method("get_controller"):
		return
	var controller = _game_table.get_controller()
	if controller == null or controller.state == null:
		return
	var state = controller.state
	var hand: Array = _game_table.get_hand_tiles() if _game_table.has_method("get_hand_tiles") else []
	var rack_slots: Array = _game_table.get_rack_slots() if _game_table.has_method("get_rack_slots") else []

	var by_id: Dictionary = {}
	for t in hand:
		by_id[int(t.unique_id)] = t
	if _last_selected_tile_id != -1 and not by_id.has(_last_selected_tile_id):
		_last_selected_tile_id = -1

	# Local player rack (face-up)
	if _world_rack_tile_containers.size() > 0:
		var local_hash: int = _compute_slots_hash(rack_slots) * 31 + (_last_selected_tile_id + 1)
		if local_hash != _last_world_rack_hashes[0]:
			_last_world_rack_hashes[0] = local_hash
			_render_local_rack_tiles(rack_slots, by_id)

	# Opponent racks are placeholders only: no visible tiles.
	for oi in range(3):
		var pi: int = oi + 1
		if pi >= _world_rack_tile_containers.size():
			continue
		var opp_hash: int = 0
		if pi < state.players.size():
			var p = state.players[pi]
			opp_hash = int(p.has_opened) * 17 + int(p.opened_by_pairs) * 31 + (1 if state.current_player_index == pi else 0) * 131
		if opp_hash == _last_world_rack_hashes[pi]:
			continue
		_last_world_rack_hashes[pi] = opp_hash
		var opp_container: Node3D = _world_rack_tile_containers[pi]
		for child in opp_container.get_children():
			child.queue_free()


func _render_local_rack_tiles(rack_slots: Array, by_id: Dictionary) -> void:
	var container: Node3D = _world_rack_tile_containers[0]
	for child in container.get_children():
		child.queue_free()
	_local_rack_tile_hits.clear()
	_local_rack_slot_hits.clear()

	var row0_slots: int = mini(15, rack_slots.size())
	var row1_slots: int = maxi(0, mini(30, rack_slots.size()) - 15)
	var usable_len: float = RACK_LEN - 0.060
	var spacing0: float = usable_len / 15.0
	var start0: float = -usable_len * 0.5 + spacing0 * 0.5

	for i in range(15):
		var x_anchor: float = start0 + float(i) * spacing0
		var world_anchor := container.to_global(Vector3(x_anchor, _rack_row0_anchor.y, _rack_row0_anchor.z))
		_local_rack_slot_hits.append({"slot": i, "world": world_anchor})
		_create_pick_box(
			container,
			"SlotPickTop%d" % i,
			RACK_SLOT_PICK_SIZE,
			Vector3(x_anchor, _rack_row0_anchor.y + RACK_ROW0_TILE_LIFT, _rack_row0_anchor.z),
			Vector3.ZERO,
			{"kind": "local_slot", "slot": i}
		)

	for i in range(row0_slots):
		var tid: int = int(rack_slots[i])
		if tid == -1 or not by_id.has(tid):
			continue
		var tile := _create_tile_face_up(by_id[tid], true)
		var x: float = start0 + float(i) * spacing0
		var y: float = _rack_row0_anchor.y + RACK_ROW0_TILE_LIFT
		var z: float = _rack_row0_anchor.z
		tile.position = Vector3(x, y, z)
		tile.rotation_degrees.x = RACK_ROW_TOP_TILT_DEG
		if tid == _last_selected_tile_id:
			tile.position.y += 0.004
			tile.scale = Vector3(1.07, 1.07, 1.07)
		_create_pick_box(
			tile,
			"TilePick",
			RACK_TILE_PICK_SIZE,
			Vector3(0.0, 0.0, 0.0),
			Vector3.ZERO,
			{"kind": "local_tile", "slot": i, "tile_id": tid}
		)
		container.add_child(tile)
		_local_rack_tile_hits.append({
			"tile_id": tid,
			"slot": i,
			"world": tile.global_position
		})

	if row1_slots <= 0:
		return
	var spacing1: float = usable_len / 15.0
	var start1: float = -usable_len * 0.5 + spacing1 * 0.5
	for i in range(15):
		var x_anchor: float = start1 + float(i) * spacing1
		var world_anchor := container.to_global(Vector3(x_anchor, _rack_row1_anchor.y, _rack_row1_anchor.z))
		_local_rack_slot_hits.append({"slot": i + 15, "world": world_anchor})
		_create_pick_box(
			container,
			"SlotPickBottom%d" % i,
			RACK_SLOT_PICK_SIZE,
			Vector3(x_anchor, _rack_row1_anchor.y + RACK_ROW1_TILE_LIFT, _rack_row1_anchor.z),
			Vector3.ZERO,
			{"kind": "local_slot", "slot": i + 15}
		)
	for i in range(row1_slots):
		var idx: int = i + 15
		var tid: int = int(rack_slots[idx])
		if tid == -1 or not by_id.has(tid):
			continue
		var tile := _create_tile_face_up(by_id[tid], true)
		var x: float = start1 + float(i) * spacing1
		var y: float = _rack_row1_anchor.y + RACK_ROW1_TILE_LIFT
		var z: float = _rack_row1_anchor.z
		tile.position = Vector3(x, y, z)
		tile.rotation_degrees.x = RACK_ROW_BOTTOM_TILT_DEG
		if tid == _last_selected_tile_id:
			tile.position.y += 0.004
			tile.scale = Vector3(1.07, 1.07, 1.07)
		_create_pick_box(
			tile,
			"TilePick",
			RACK_TILE_PICK_SIZE,
			Vector3(0.0, 0.0, 0.0),
			Vector3.ZERO,
			{"kind": "local_tile", "slot": idx, "tile_id": tid}
		)
		container.add_child(tile)
		_local_rack_tile_hits.append({
			"tile_id": tid,
			"slot": idx,
			"world": tile.global_position
		})


func _sync_world_stage_tiles() -> void:
	if _game_table == null or not is_instance_valid(_game_table):
		return
	if not _game_table.has_method("get_controller"):
		return
	var controller = _game_table.get_controller()
	if controller == null or controller.state == null:
		return
	var stage_slots: Array = _game_table.get_stage_slots() if _game_table.has_method("get_stage_slots") else []
	var stage_hash: int = _compute_slots_hash(stage_slots)
	if stage_hash == _last_world_stage_hash:
		return
	_last_world_stage_hash = stage_hash

	_stage_tile_hits.clear()
	for child in _world_stage_container.get_children():
		child.queue_free()

	if _table_local_meld_lanes.is_empty():
		return

	var hand: Array = _game_table.get_hand_tiles() if _game_table.has_method("get_hand_tiles") else []
	var by_id: Dictionary = {}
	for t in hand:
		by_id[int(t.unique_id)] = t

	var lane: Rect2 = _table_local_meld_lanes[0]
	var cols: int = 15
	var rows: int = 2
	var cell_w: float = lane.size.x / float(cols)
	var cell_h: float = lane.size.y / float(rows)

	for i in range(mini(stage_slots.size(), cols * rows)):
		var tid: int = int(stage_slots[i])
		if tid == -1 or not by_id.has(tid):
			continue
		var row: int = i / cols
		var col: int = i % cols
		var x: float = lane.position.x + cell_w * (float(col) + 0.5)
		var z: float = lane.position.y + cell_h * (float(row) + 0.5)
		var tile := _create_tile_face_up(by_id[tid], true)
		tile.position = _table_local_to_world(Vector2(x, z), TILE_H * 0.5)
		_create_pick_box(
			tile,
			"StageTilePick",
			STAGE_TILE_PICK_SIZE,
			Vector3(0.0, 0.0, 0.0),
			Vector3.ZERO,
			{"kind": "stage_tile", "slot": i, "tile_id": tid}
		)
		_world_stage_container.add_child(tile)
		_stage_tile_hits.append({
			"slot": i,
			"tile_id": tid,
			"world": tile.global_position + Vector3(0.0, TILE_H * 0.12, TILE_D * 0.55)
		})

func _sync_world_deck() -> void:
	if _game_table == null or not is_instance_valid(_game_table):
		return
	if not _game_table.has_method("get_controller"):
		return
	var controller = _game_table.get_controller()
	if controller == null or controller.state == null:
		return
	var state = controller.state
	var deck_count: int = state.deck.size()
	var indicator_id: int = -1
	if state.okey_context != null and state.okey_context.indicator_tile != null:
		indicator_id = int(state.okey_context.indicator_tile.unique_id)
	var deck_hash: int = deck_count * 131071 + indicator_id + 7
	if deck_hash == _last_world_deck_hash:
		return
	_last_world_deck_hash = deck_hash

	for child in _deck_pile_container.get_children():
		child.queue_free()

	var vis_count: int = mini(deck_count, 20)
	if vis_count <= 0 and deck_count > 0:
		vis_count = 1
	var rng := RandomNumberGenerator.new()
	rng.seed = int(deck_count) * 91373 + int(indicator_id) * 17
	for i in range(vis_count):
		var tile := _create_tile_face_down(false)
		tile.position = Vector3(
			rng.randf_range(-0.0035, 0.0035),
			float(i) * TILE_D * 0.30,
			rng.randf_range(-0.0035, 0.0035)
		)
		tile.rotation_degrees.y = rng.randf_range(-2.8, 2.8)
		_deck_pile_container.add_child(tile)

	if state.okey_context != null and state.okey_context.indicator_tile != null:
		_indicator_3d = _create_tile_face_up(state.okey_context.indicator_tile, true)
		_indicator_3d.position = Vector3(TILE_W + INDICATOR_GAP, TILE_H * 0.5, 0.0)
		_indicator_3d.rotation_degrees.y = -2.0
		_deck_pile_container.add_child(_indicator_3d)


func _sync_world_discards() -> void:
	if _game_table == null or not is_instance_valid(_game_table):
		return
	if not _game_table.has_method("get_controller"):
		return
	var controller = _game_table.get_controller()
	if controller == null or controller.state == null:
		return
	var state = controller.state

	var base_rot: Array[float] = [0.0, 90.0, 180.0, -90.0]
	for pi in range(mini(4, _discard_pile_containers.size())):
		var stack: Array = []
		if pi < state.player_discard_stacks.size():
			stack = state.player_discard_stacks[pi]
		var last_id: int = 0
		if not stack.is_empty():
			last_id = int(stack.back().unique_id)
		var hash_val: int = stack.size() * 10007 + last_id
		if hash_val == _last_world_discard_hashes[pi]:
			continue
		_last_world_discard_hashes[pi] = hash_val

		var pile: Node3D = _discard_pile_containers[pi]
		for child in pile.get_children():
			child.queue_free()

		var start_idx: int = maxi(0, stack.size() - 14)
		var vis_count: int = stack.size() - start_idx
		if vis_count <= 0:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = int(pi) * 2017 + int(stack.size()) * 97 + int(last_id) * 13
		for i in range(vis_count):
			var td = stack[start_idx + i]
			var tile := _create_tile_face_up(td, false)
			tile.position = Vector3(
				rng.randf_range(-0.006, 0.006),
				float(i) * TILE_D * 0.28,
				rng.randf_range(-0.006, 0.006)
			)
			tile.rotation_degrees.y = base_rot[pi] + rng.randf_range(-8.0, 8.0)
			pile.add_child(tile)


func _sync_world_labels() -> void:
	if _game_table == null or not is_instance_valid(_game_table):
		return
	if not _game_table.has_method("get_controller"):
		return
	var controller = _game_table.get_controller()
	if controller == null or controller.state == null:
		return
	var state = controller.state

	var hash_val: int = 17
	for i in range(mini(4, state.players.size())):
		hash_val = int((hash_val * 131 + int(state.players[i].has_opened) * 7 + int(state.current_player_index == i) * 17) % 2147483647)
	if hash_val == _last_world_label_hash:
		return
	_last_world_label_hash = hash_val

	for pi in range(mini(4, _world_rack_labels.size())):
		var lbl: Label3D = _world_rack_labels[pi]
		var title: String = "P%d" % pi
		if pi == 0:
			title = "YOU"
		var status: String = "Closed"
		if pi < state.players.size() and bool(state.players[pi].has_opened):
			status = "Opened"
			if bool(state.players[pi].opened_by_pairs):
				status = "Opened Pairs"
		lbl.text = "%s\n%s" % [title, status]
		if state.current_player_index == pi:
			lbl.modulate = Color(1.0, 0.92, 0.75, 0.95)
		else:
			lbl.modulate = Color(0.92, 0.86, 0.76, 0.82)


func _screen_to_table_local(screen_pos: Vector2) -> Vector2:
	if _camera == null:
		return INVALID_TABLE_POS
	var ray_origin: Vector3 = _camera.project_ray_origin(screen_pos)
	var ray_dir: Vector3 = _camera.project_ray_normal(screen_pos)
	if absf(ray_dir.y) <= 0.0001:
		return INVALID_TABLE_POS
	var plane_y: float = _table_surface.position.y
	var t: float = (plane_y - ray_origin.y) / ray_dir.y
	if t <= 0.0:
		return INVALID_TABLE_POS
	var hit: Vector3 = ray_origin + ray_dir * t
	var felt_half: float = FELT_SIDE * 0.5
	if hit.x < -felt_half or hit.x > felt_half or hit.z < -felt_half or hit.z > felt_half:
		return INVALID_TABLE_POS
	return Vector2(hit.x, hit.z)


func _table_local_to_world(local_pos: Vector2, y_offset: float = 0.0) -> Vector3:
	return Vector3(local_pos.x, _table_surface.position.y + y_offset, local_pos.y)


func _create_pick_box(parent: Node3D, node_name: String, box_size: Vector3, world_pos: Vector3, rot_deg: Vector3, pick_data: Dictionary) -> Area3D:
	var area := Area3D.new()
	area.name = node_name
	area.position = world_pos
	area.rotation_degrees = rot_deg
	area.collision_layer = INTERACT_COLLISION_LAYER
	area.collision_mask = 0
	area.input_ray_pickable = true
	area.set_meta("pick", pick_data.duplicate(true))
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = box_size
	shape.shape = box
	area.add_child(shape)
	parent.add_child(area)
	return area


func _extract_pick_data(collider: Object) -> Dictionary:
	if collider == null:
		return {}
	var node: Node = collider as Node
	while node != null:
		if node.has_meta("pick"):
			var data: Variant = node.get_meta("pick")
			if data is Dictionary:
				return (data as Dictionary).duplicate(true)
			break
		node = node.get_parent()
	return {}


func _raycast_pick(screen_pos: Vector2) -> Dictionary:
	if _camera == null or not is_instance_valid(_camera):
		return {}
	var world3d: World3D = _camera.get_world_3d()
	if world3d == null:
		return {}
	var from: Vector3 = _camera.project_ray_origin(screen_pos)
	var to: Vector3 = from + _camera.project_ray_normal(screen_pos) * INTERACT_RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to, INTERACT_COLLISION_LAYER)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit: Dictionary = world3d.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {}
	var pick: Dictionary = _extract_pick_data(hit.get("collider"))
	if pick.is_empty():
		return {}
	pick["world_pos"] = hit.get("position", Vector3.ZERO)
	return pick


func _begin_drag_candidate_from_pick(screen_pos: Vector2) -> void:
	_drag_candidate_tile_id = -1
	_drag_candidate_slot = -1
	_drag_candidate_stage_slot = -1
	_drag_active = false
	_drag_press_screen = screen_pos
	var pick: Dictionary = _raycast_pick(screen_pos)
	if pick.is_empty():
		return
	var kind: String = str(pick.get("kind", ""))
	if kind == "stage_tile":
		_drag_candidate_tile_id = int(pick.get("tile_id", -1))
		_drag_candidate_stage_slot = int(pick.get("slot", -1))
		return
	if kind == "local_tile":
		_drag_candidate_tile_id = int(pick.get("tile_id", -1))
		_drag_candidate_slot = int(pick.get("slot", -1))
		return
	if kind == "local_slot":
		var slot_idx: int = int(pick.get("slot", -1))
		var slot_tid: int = _tile_id_in_rack_slot(slot_idx)
		if slot_idx != -1 and slot_tid != -1:
			_drag_candidate_tile_id = slot_tid
			_drag_candidate_slot = slot_idx


func _start_drag_preview() -> void:
	if _drag_candidate_tile_id == -1:
		return
	_drag_active = true
	if _drag_preview != null and is_instance_valid(_drag_preview):
		_drag_preview.queue_free()
		_drag_preview = null
	var tile_data = _find_tile_data_by_id(_drag_candidate_tile_id)
	if tile_data == null:
		return
	_drag_preview = _create_tile_face_up(tile_data, true)
	_drag_preview.scale = Vector3(1.07, 1.07, 1.07)
	_world_root.add_child(_drag_preview)
	_update_drag_preview(_drag_press_screen)


func _update_drag_preview(screen_pos: Vector2) -> void:
	if not _drag_active or _drag_preview == null or not is_instance_valid(_drag_preview):
		return
	var table_pos: Vector2 = _screen_to_table_local(screen_pos)
	if table_pos.x > INVALID_TABLE_POS.x * 0.5:
		_drag_preview.position = _table_local_to_world(table_pos, TILE_H * 0.5 + 0.005)
		return
	var fallback := _screen_to_near_table(screen_pos)
	_drag_preview.position = fallback


func _finish_drag(screen_pos: Vector2) -> void:
	if _drag_candidate_tile_id == -1 and not _drag_active:
		return
	var was_dragging: bool = _drag_active
	var tile_id: int = _drag_candidate_tile_id
	var from_slot: int = _drag_candidate_slot
	var from_stage: int = _drag_candidate_stage_slot
	var table_pos: Vector2 = _screen_to_table_local(screen_pos)
	var pick: Dictionary = _raycast_pick(screen_pos)

	if not was_dragging:
		# Click behavior fallback for quick selection.
		if from_stage != -1:
			_on_stage_tile_clicked({"slot": from_stage, "tile_id": tile_id})
		elif from_slot != -1:
			_on_local_rack_tile_clicked({"slot": from_slot, "tile_id": tile_id})
		_clear_drag_state()
		return

	if _game_table == null or not is_instance_valid(_game_table):
		_clear_drag_state()
		return
	if _game_table.has_method("is_action_in_flight") and _game_table.is_action_in_flight():
		_clear_drag_state()
		return
	var controller = _game_table.get_controller()
	if controller == null or controller.state == null:
		_clear_drag_state()
		return
	var state = controller.state
	if state.current_player_index != 0:
		_clear_drag_state()
		return

	var phase: int = state.phase
	var handled: bool = false
	var pick_kind: String = str(pick.get("kind", ""))
	var pick_player: int = int(pick.get("player", -1))
	var target_slot: int = int(pick.get("slot", -1))

	if table_pos.x > INVALID_TABLE_POS.x * 0.5:
		if from_slot != -1 and phase == GameState.Phase.TURN_PLAY and (
			(pick_kind == "meld_lane" and pick_player == 0) or _is_in_meld_lane(table_pos, 0)
		):
			var to_stage: int = _first_empty(_game_table.get_stage_slots())
			if to_stage != -1:
				_game_table.overlay_move_rack_to_stage(from_slot, to_stage)
				handled = true

	var on_local_discard: bool = (pick_kind == "discard_zone" and pick_player == 0)
	if not on_local_discard and table_pos.x > INVALID_TABLE_POS.x * 0.5:
		on_local_discard = _is_in_discard_hotspot(table_pos, 0)
	if not handled and on_local_discard:
		if from_slot != -1 and (phase == GameState.Phase.STARTER_DISCARD or phase == GameState.Phase.TURN_DISCARD):
			_game_table.overlay_discard_tile(tile_id)
			handled = true
		elif from_slot != -1 and phase == GameState.Phase.TURN_PLAY:
			_game_table.overlay_end_play_then_discard(tile_id)
			handled = true

	if target_slot == -1 and (pick_kind == "local_tile" or pick_kind == "local_slot"):
		target_slot = int(pick.get("slot", -1))
	if target_slot == -1:
		target_slot = _pick_nearest_rack_slot(screen_pos)
	if not handled and target_slot != -1:
		if from_slot != -1 and target_slot != from_slot:
			_game_table.overlay_move_slot(from_slot, target_slot)
			handled = true
		elif from_stage != -1:
			_game_table.overlay_move_stage_to_rack(from_stage, target_slot)
			handled = true

	if handled:
		_last_selected_tile_id = -1
		_force_sync()
	_clear_drag_state()


func _clear_drag_state() -> void:
	_drag_candidate_tile_id = -1
	_drag_candidate_slot = -1
	_drag_candidate_stage_slot = -1
	_drag_active = false
	if _drag_preview != null and is_instance_valid(_drag_preview):
		_drag_preview.queue_free()
	_drag_preview = null


func _pick_nearest_hit(screen_pos: Vector2, hit_list: Array[Dictionary], radius_px: float = PICK_RADIUS_PX) -> Dictionary:
	var best: Dictionary = {}
	var best_d2: float = radius_px * radius_px
	for hit in hit_list:
		var world_pos: Vector3 = hit.get("world", Vector3.ZERO)
		var projected: Vector2 = _camera.unproject_position(world_pos)
		var d2: float = projected.distance_squared_to(screen_pos)
		if d2 <= best_d2:
			best = hit.duplicate()
			best["dist2"] = d2
			best_d2 = d2
	return best


func _pick_nearest_rack_slot(screen_pos: Vector2) -> int:
	var hit: Dictionary = _pick_nearest_hit(screen_pos, _local_rack_slot_hits, SLOT_PICK_RADIUS_PX)
	if hit.is_empty():
		return -1
	return int(hit.get("slot", -1))


func _tile_id_in_rack_slot(slot_idx: int) -> int:
	if _game_table == null or not is_instance_valid(_game_table):
		return -1
	if not _game_table.has_method("get_rack_slots"):
		return -1
	var slots: Array = _game_table.get_rack_slots()
	if slot_idx < 0 or slot_idx >= slots.size():
		return -1
	return int(slots[slot_idx])


func _pick_discard_hotspot_from_screen(screen_pos: Vector2) -> int:
	if _camera == null or _table_local_discard_points.is_empty():
		return -1
	var best_idx: int = -1
	var best_d2: float = DISCARD_SCREEN_PICK_RADIUS_PX * DISCARD_SCREEN_PICK_RADIUS_PX
	for i in range(_table_local_discard_points.size()):
		var world_pos: Vector3 = _table_local_to_world(_table_local_discard_points[i], 0.004)
		if _camera.is_position_behind(world_pos):
			continue
		var projected: Vector2 = _camera.unproject_position(world_pos)
		var d2: float = projected.distance_squared_to(screen_pos)
		if d2 <= best_d2:
			best_d2 = d2
			best_idx = i
	return best_idx


func _find_tile_data_by_id(tile_id: int):
	if _game_table == null or not is_instance_valid(_game_table):
		return null
	var hand: Array = _game_table.get_hand_tiles() if _game_table.has_method("get_hand_tiles") else []
	for t in hand:
		if int(t.unique_id) == tile_id:
			return t
	return null


func _screen_to_near_table(screen_pos: Vector2) -> Vector3:
	var ray_origin: Vector3 = _camera.project_ray_origin(screen_pos)
	var ray_dir: Vector3 = _camera.project_ray_normal(screen_pos)
	var plane_y: float = _table_surface.position.y + 0.01
	var t: float = (plane_y - ray_origin.y) / ray_dir.y
	if t <= 0.0:
		t = 0.2
	return ray_origin + ray_dir * t


func _on_local_rack_tile_clicked(hit: Dictionary) -> void:
	if _game_table == null or not is_instance_valid(_game_table):
		return
	if _game_table.has_method("is_action_in_flight") and _game_table.is_action_in_flight():
		return
	var tid: int = int(hit.get("tile_id", -1))
	var slot: int = int(hit.get("slot", -1))
	if tid == -1 or slot == -1:
		return
	var controller = _game_table.get_controller()
	if controller == null or controller.state == null:
		return
	var state = controller.state
	if state.current_player_index != 0:
		return
	if _last_selected_tile_id == tid:
		_last_selected_tile_id = -1
		_last_world_rack_hashes[0] = -1
		return

	if _last_selected_tile_id != -1 and _can_reorder_in_phase(state.phase):
		var from_slot: int = _find_in_slots(_game_table.get_rack_slots(), _last_selected_tile_id)
		if from_slot != -1 and from_slot != slot:
			_game_table.overlay_move_slot(from_slot, slot)
			_last_selected_tile_id = tid
			_force_sync()
			return

	_last_selected_tile_id = tid
	_last_world_rack_hashes[0] = -1


func _on_stage_tile_clicked(hit: Dictionary) -> void:
	if _game_table == null or not is_instance_valid(_game_table):
		return
	if _game_table.has_method("is_action_in_flight") and _game_table.is_action_in_flight():
		return
	var from_stage: int = int(hit.get("slot", -1))
	if from_stage == -1:
		return
	var controller = _game_table.get_controller()
	if controller == null or controller.state == null:
		return
	var state = controller.state
	if state.current_player_index != 0 or state.phase != GameState.Phase.TURN_PLAY:
		return
	var to_rack: int = _first_empty(_game_table.get_rack_slots())
	if to_rack == -1:
		return
	_game_table.overlay_move_stage_to_rack(from_stage, to_rack)
	_force_sync()


func _handle_world_tap(pick: Dictionary, table_pos: Vector2) -> void:
	if _game_table == null or not is_instance_valid(_game_table):
		return
	if _game_table.has_method("is_action_in_flight") and _game_table.is_action_in_flight():
		return
	var controller = _game_table.get_controller()
	if controller == null or controller.state == null:
		return
	var state = controller.state
	if state.current_player_index != 0:
		return

	var phase: int = state.phase
	var pick_kind: String = str(pick.get("kind", ""))
	var pick_player: int = int(pick.get("player", -1))
	if pick_kind == "local_tile":
		_on_local_rack_tile_clicked(pick)
		return
	if pick_kind == "stage_tile":
		_on_stage_tile_clicked(pick)
		return

	if phase == GameState.Phase.TURN_DRAW:
		if pick_kind == "draw_stack" or _is_in_draw_hotspot(table_pos):
			_game_table.overlay_draw_from_deck()
			_force_sync()
			return
		var prev_idx: int = (state.current_player_index + state.players.size() - 1) % state.players.size()
		if (pick_kind == "discard_zone" and pick_player == prev_idx) or _is_in_discard_hotspot(table_pos, prev_idx):
			_game_table.overlay_take_discard()
			_force_sync()
			return
		return

	if phase == GameState.Phase.TURN_PLAY and _last_selected_tile_id != -1:
		if (pick_kind == "meld_lane" and pick_player == 0) or _is_in_meld_lane(table_pos, 0):
			var from_rack: int = _find_in_slots(_game_table.get_rack_slots(), _last_selected_tile_id)
			var to_stage: int = _first_empty(_game_table.get_stage_slots())
			if from_rack != -1 and to_stage != -1:
				_game_table.overlay_move_rack_to_stage(from_rack, to_stage)
				_force_sync()
			return

	if _last_selected_tile_id == -1:
		return
	if not ((pick_kind == "discard_zone" and pick_player == 0) or _is_in_discard_hotspot(table_pos, 0)):
		return

	if phase == GameState.Phase.STARTER_DISCARD or phase == GameState.Phase.TURN_DISCARD:
		_game_table.overlay_discard_tile(_last_selected_tile_id)
		_last_selected_tile_id = -1
		_force_sync()
		return
	if phase == GameState.Phase.TURN_PLAY:
		_game_table.overlay_end_play_then_discard(_last_selected_tile_id)
		_last_selected_tile_id = -1
		_force_sync()

func _is_in_draw_hotspot(table_pos: Vector2) -> bool:
	return table_pos.distance_to(_draw_hotspot_center) <= DRAW_HIT_RADIUS


func _is_in_discard_hotspot(table_pos: Vector2, player_index: int) -> bool:
	if player_index < 0 or player_index >= _table_local_discard_points.size():
		return false
	return table_pos.distance_to(_table_local_discard_points[player_index]) <= DISCARD_HIT_RADIUS


func _is_in_meld_lane(table_pos: Vector2, player_index: int) -> bool:
	if player_index < 0 or player_index >= _table_local_meld_lanes.size():
		return false
	return _table_local_meld_lanes[player_index].has_point(table_pos)


func _can_reorder_in_phase(phase: int) -> bool:
	return phase == GameState.Phase.STARTER_DISCARD \
		or phase == GameState.Phase.TURN_DRAW \
		or phase == GameState.Phase.TURN_PLAY \
		or phase == GameState.Phase.TURN_DISCARD


func _compute_slots_hash(slots: Array) -> int:
	var h: int = 17
	for v in slots:
		h = int((h * 131 + int(v) + 1) % 2147483647)
	return h


func _find_in_slots(slots: Array, tile_id: int) -> int:
	for i in range(slots.size()):
		if int(slots[i]) == tile_id:
			return i
	return -1


func _first_empty(slots: Array) -> int:
	for i in range(slots.size()):
		if int(slots[i]) == -1:
			return i
	return -1


func _force_sync() -> void:
	_last_world_rack_hashes = [-1, -1, -1, -1]
	_last_world_stage_hash = -1
	_last_world_deck_hash = -1
	_last_world_discard_hashes = [-1, -1, -1, -1]
	_last_world_label_hash = -1
	_clear_drag_state()


func _create_surface_guide(size: Vector2, color: Color) -> Node3D:
	var node := Node3D.new()
	var mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	mesh.mesh = quad
	mesh.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.set_surface_override_material(0, mat)
	node.add_child(mesh)
	return node


func _create_dotted_discard_guide(radius: float, dot_count: int, color: Color) -> Node3D:
	var node := Node3D.new()

	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(color.r, color.g, color.b, color.a * 0.30)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var ring := MeshInstance3D.new()
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = radius * 0.90
	ring_mesh.bottom_radius = radius * 0.90
	ring_mesh.height = 0.0012
	ring_mesh.radial_segments = 28
	ring.mesh = ring_mesh
	ring.position = Vector3(0.0, 0.0006, 0.0)
	ring.set_surface_override_material(0, ring_mat)
	node.add_child(ring)

	var dot_mat := StandardMaterial3D.new()
	dot_mat.albedo_color = color
	dot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dot_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var dot_mesh := SphereMesh.new()
	dot_mesh.radius = 0.0018
	dot_mesh.height = 0.0036
	dot_mesh.radial_segments = 12
	dot_mesh.rings = 8
	for i in range(maxi(dot_count, 6)):
		var dot := MeshInstance3D.new()
		var a: float = TAU * float(i) / float(maxi(dot_count, 6))
		dot.mesh = dot_mesh
		dot.position = Vector3(cos(a) * radius, 0.0018, sin(a) * radius)
		dot.set_surface_override_material(0, dot_mat)
		node.add_child(dot)

	return node


func _create_hud_overlay() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HudLayer"
	add_child(_hud_layer)

	_hud_bar = PanelContainer.new()
	_hud_bar.name = "HudBar"
	_hud_bar.anchor_left = 0.0
	_hud_bar.anchor_top = 0.0
	_hud_bar.anchor_right = 1.0
	_hud_bar.anchor_bottom = 0.0
	_hud_bar.offset_left = 14.0
	_hud_bar.offset_top = 12.0
	_hud_bar.offset_right = -14.0
	_hud_bar.offset_bottom = 62.0
	_hud_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.26, 0.16, 0.10, 0.92)
	style.border_width_bottom = 2
	style.border_color = Color(0.58, 0.39, 0.24, 0.68)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_hud_bar.add_theme_stylebox_override("panel", style)
	_hud_layer.add_child(_hud_bar)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 18)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_bar.add_child(hbox)

	_hud_instructions = Label.new()
	_hud_instructions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hud_instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_instructions.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hud_instructions.add_theme_color_override("font_color", Color(0.99, 0.94, 0.84, 1.0))
	_hud_instructions.add_theme_font_size_override("font_size", 20)
	_hud_instructions.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.05, 0.68))
	_hud_instructions.add_theme_constant_override("outline_size", 2)
	hbox.add_child(_hud_instructions)

	var right_box := HBoxContainer.new()
	right_box.alignment = BoxContainer.ALIGNMENT_END
	right_box.add_theme_constant_override("separation", 14)
	right_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(right_box)

	_hud_turn = _make_hud_stat("Turn: -", 110)
	_hud_phase = _make_hud_stat("Phase", 86)
	_hud_deck = _make_hud_stat("Deck: -", 92)
	_hud_okey = _make_hud_stat("Okey: -", 108, Color(0.98, 0.78, 0.34, 1.0))
	right_box.add_child(_hud_turn)
	right_box.add_child(_hud_phase)
	right_box.add_child(_hud_deck)
	right_box.add_child(_hud_okey)
	_layout_hud()


func _make_hud_stat(text: String, min_w: float, color: Color = Color(0.92, 0.85, 0.66, 1.0)) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(min_w, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 18)
	return lbl


func _layout_hud() -> void:
	if _hud_bar == null:
		return
	_hud_bar.offset_left = 14.0
	_hud_bar.offset_right = -14.0
	_hud_bar.offset_top = 12.0
	_hud_bar.offset_bottom = 62.0


func _spawn_game_table() -> void:
	if _game_table != null and is_instance_valid(_game_table):
		_game_table.queue_free()
	_game_table = GAME_TABLE_SCENE.instantiate()
	if _game_table.has_method("set_presentation_mode"):
		_game_table.call("set_presentation_mode", "3d")
	if _game_table is Control:
		var table_control := _game_table as Control
		table_control.set_anchors_preset(Control.PRESET_FULL_RECT)
		table_control.offset_left = 0.0
		table_control.offset_top = 0.0
		table_control.offset_right = 0.0
		table_control.offset_bottom = 0.0
		table_control.visible = false
		table_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game_viewport.add_child(_game_table)
	_apply_pending_config_if_ready()
	call_deferred("_cache_source_hud_nodes")


func _cache_source_hud_nodes() -> void:
	if _game_table == null or not is_instance_valid(_game_table):
		return
	_src_top_bar = _game_table.get_node_or_null("TopBar") as Control
	if _src_top_bar != null:
		_src_top_bar.visible = false
		_src_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_src_instructions = _game_table.get_node_or_null("TopBar/TopHBox/Instructions") as Label
	_src_turn = _game_table.get_node_or_null("TopBar/TopHBox/TurnLabel") as Label
	_src_phase = _game_table.get_node_or_null("TopBar/TopHBox/PhaseLabel") as Label
	_src_deck = _game_table.get_node_or_null("TopBar/TopHBox/DeckCount") as Label
	_src_okey = _game_table.get_node_or_null("TopBar/TopHBox/OkeyInfo") as Label


func _sync_hud_from_table() -> void:
	if _hud_instructions == null:
		return
	if _src_instructions == null:
		_cache_source_hud_nodes()
	if _src_instructions != null:
		_hud_instructions.text = _src_instructions.text
	if _src_turn != null:
		_hud_turn.text = _src_turn.text
	if _src_phase != null:
		_hud_phase.text = _src_phase.text
	if _src_deck != null:
		_hud_deck.text = _src_deck.text
	if _src_okey != null:
		_hud_okey.text = _src_okey.text


func _apply_pending_config_if_ready() -> void:
	if not _has_pending_config:
		return
	if _game_table == null or not is_instance_valid(_game_table):
		return
	if _game_table.has_method("configure_game"):
		_game_table.call("configure_game", _pending_rule_config, _pending_seed, _pending_player_count)
	_has_pending_config = false
	_force_sync()


func _resize_subviewport() -> void:
	if _game_viewport == null:
		return
	var visible: Vector2 = get_viewport().get_visible_rect().size
	var width: int = maxi(1280, int(round(visible.x)))
	var height: int = maxi(720, int(round(visible.y)))
	_game_viewport.size = Vector2i(width, height)
