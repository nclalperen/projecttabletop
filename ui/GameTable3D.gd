extends Node

const GAME_TABLE_SCENE: PackedScene = preload("res://ui/GameTable.tscn")
const INVALID_TABLE_POS: Vector2 = Vector2(-99999.0, -99999.0)
const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")

# Asset IDs
const CLOTH_TEX_ID: StringName = ASSET_IDS.GAMEPLAY_TEXTURE_CLOTH
const WOOD_TEX_ID: StringName = ASSET_IDS.GAMEPLAY_TEXTURE_RACK_BASECOLOR
const TILE_FACE_TEX_ID: StringName = ASSET_IDS.GAMEPLAY_TEXTURE_TILE_FACE
const CC0_HDRI_PRIMARY_ID: StringName = ASSET_IDS.GAMEPLAY_HDRI_STUDIO_SMALL_01
const CC0_HDRI_SECONDARY_ID: StringName = ASSET_IDS.GAMEPLAY_HDRI_STUDIO_SMALL_03
const CC0_FELT_COLOR_ID: StringName = ASSET_IDS.GAMEPLAY_TEXTURE_FELT_COLOR
const CC0_FELT_ROUGHNESS_ID: StringName = ASSET_IDS.GAMEPLAY_TEXTURE_FELT_ROUGHNESS
const CC0_TABLE_WOOD_DIFFUSE_ID: StringName = ASSET_IDS.GAMEPLAY_TEXTURE_TABLE_WOOD_DIFFUSE
const CC0_TABLE_WOOD_NORMAL_ID: StringName = ASSET_IDS.GAMEPLAY_TEXTURE_TABLE_WOOD_NORMAL
const CC0_TABLE_WOOD_ROUGHNESS_ID: StringName = ASSET_IDS.GAMEPLAY_TEXTURE_TABLE_WOOD_ROUGHNESS
const CC0_RACK_WOOD_DIFFUSE_ID: StringName = ASSET_IDS.GAMEPLAY_TEXTURE_RACK_WOOD_DIFFUSE
const CC0_RACK_WOOD_NORMAL_ID: StringName = ASSET_IDS.GAMEPLAY_TEXTURE_RACK_WOOD_NORMAL
const CC0_RACK_WOOD_ROUGHNESS_ID: StringName = ASSET_IDS.GAMEPLAY_TEXTURE_RACK_WOOD_ROUGHNESS
const RACK_MODEL_ID: StringName = ASSET_IDS.GAMEPLAY_MODEL_RACK
const TILE_MODEL_ID: StringName = ASSET_IDS.GAMEPLAY_MODEL_TILE
const TILES_LIBRARY_ID: StringName = ASSET_IDS.GAMEPLAY_MODEL_TILES_LIBRARY
const TILESET_RED_ID: StringName = ASSET_IDS.GAMEPLAY_MODEL_TILESET_RED
const TILESET_BLUE_ID: StringName = ASSET_IDS.GAMEPLAY_MODEL_TILESET_BLUE
const TILESET_YELLOW_ID: StringName = ASSET_IDS.GAMEPLAY_MODEL_TILESET_YELLOW
const TILESET_GREEN_ID: StringName = ASSET_IDS.GAMEPLAY_MODEL_TILESET_GREEN
const TILESET_FAKE_OKEY_ID: StringName = ASSET_IDS.GAMEPLAY_MODEL_TILESET_FAKE_OKEY
const USE_LEGACY_TILESET_FALLBACK: bool = false
const AUDIO_SERVICE_SCRIPT: Script = preload("res://ui/services/AudioService.gd")
const UI_SETTINGS_SCRIPT: Script = preload("res://ui/services/UISettings.gd")
const VISUAL_QUALITY_SCRIPT: Script = preload("res://ui/services/VisualQualityService.gd")
const SFX_DRAW_FROM_DECK: StringName = &"draw_from_deck"
const SFX_TAKE_DISCARD: StringName = &"take_discard"
const SFX_RACK_MOVE: StringName = &"rack_move"
const SFX_STAGE_MOVE: StringName = &"stage_move"
const SFX_ADD_TO_MELD: StringName = &"add_to_meld"
const SFX_DISCARD: StringName = &"discard"
const SFX_INVALID_ACTION: StringName = &"invalid_action"
const SFX_ROUND_END: StringName = &"round_end"
const SFX_NEW_ROUND: StringName = &"new_round"

# Real-world dimensions (meters)
const TABLE_SIDE: float = 1.0
const TABLE_HEIGHT: float = 0.075
const FELT_SIDE: float = 0.80
const TILE_W: float = 0.0270
const TILE_H: float = 0.047
const TILE_D: float = 0.0050
const RACK_LEN: float = 0.45
# Reduced from legacy depth to better match rack.glb helper seating without hiding row 2.
const RACK_DEPTH: float = 0.082
const RACK_HEIGHT: float = 0.08
const RACK_MODEL_SIZE: Vector3 = Vector3(RACK_LEN, RACK_HEIGHT, RACK_DEPTH)
const RACK_MODEL_DEPTH_AXIS: float = RACK_DEPTH
const RACK_MODEL_HEIGHT_AXIS: float = RACK_HEIGHT
const RACK_MODEL_PRE_ROT_DEFAULT: Vector3 = Vector3.ZERO
const USE_AUTO_RACK_MODEL_PRE_ROT: bool = false
const USE_AUTO_RACK_ROW_ANCHORS: bool = true
const FORCE_RACK_MODEL_WOOD_MATERIAL: bool = false
const USE_TILE_FACE_TEXTURE: bool = false
const RACK_ROW0_TILE_Y: float = 0.062
const RACK_ROW0_TILE_Z: float = -0.031
const RACK_ROW1_TILE_Y: float = 0.030
const RACK_ROW1_TILE_Z: float = 0.013
const RACK_ROW0_TILE_LIFT: float = 0.0024
const RACK_ROW1_TILE_LIFT: float = 0.0030
const RACK_ROW_TOP_TILT_DEG: float = -13.0
const RACK_ROW_BOTTOM_TILT_DEG: float = -11.0
const RACK_ROW_TILT_MIN_DEG: float = -65.0
const RACK_ROW_TILT_MAX_DEG: float = -2.0

# Placement
const RACK_GAP_TO_FELT: float = 0.005
const DISCARD_EDGE_INSET: float = 0.06
const DISCARD_HIT_RADIUS: float = 0.105
const DISCARD_DRAG_HIT_MARGIN: float = 0.022
const DISCARD_TAP_HIT_MARGIN: float = 0.020
const DISCARD_TAP_SCREEN_MARGIN_PX: float = 28.0
const DISCARD_GUIDE_RADIUS: float = 0.038
const DRAW_HIT_RADIUS: float = 0.065
const DRAW_TAP_HIT_MARGIN: float = 0.020
const DRAW_TAP_SCREEN_MARGIN_PX: float = 26.0
const MELD_LANE_DEPTH: float = 0.090
const MELD_LANE_LENGTH: float = 0.44
const MELD_LANE_INSET_FROM_EDGE: float = 0.040
const LOCAL_MELD_AREA_WIDTH: float = 0.31
const LOCAL_MELD_AREA_DEPTH: float = 0.125
const STAGE_GRID_TARGET_ROWS: int = 3
const INDICATOR_GAP: float = 0.012
const DECK_TILE_SCALE: float = 1.30
const INDICATOR_TILE_SCALE: float = 1.32
const OPPONENT_RACK_HEIGHT_SCALE: float = 1.45
const OPPONENT_RACK_DEPTH_SCALE: float = 0.52
const LOCAL_RACK_TILE_BASE_SCALE: float = 1.06
const LOCAL_RACK_TILE_SELECTED_SCALE: float = 1.10
const LOCAL_RACK_TILE_REQUIRED_SCALE: float = 1.08
const LOCAL_RACK_SELF_VIEW_TILT_DEG: float = -30.0

# Camera spec
const CAMERA_PRESET_DEFAULT_INDEX: int = 0
const CAMERA_PRESET_TOGGLE_KEY: Key = KEY_F6
const CAMERA_PRESET_TOGGLE_ENABLED: bool = true
const AUTO_CAPTURE_TOGGLE_KEY: Key = KEY_F7
const TILE_DIAGNOSTIC_TOGGLE_KEY: Key = KEY_F8
const TILE_TUNE_RELOAD_KEY: Key = KEY_F9
const TILE_TUNE_DUMP_KEY: Key = KEY_F10
const TILE_TUNE_HELP_KEY: Key = KEY_F11
const MANUAL_CAPTURE_KEY: Key = KEY_F12
const TILE_TUNE_WATCH_INTERVAL_SEC: float = 0.5
const AUTO_CAPTURE_DEFAULT_ENABLED: bool = true
const AUTO_CAPTURE_INTERVAL_SEC: float = 20.0
const AUTO_CAPTURE_MAX_PER_SESSION: int = 120
const AUTO_CAPTURE_PROJECT_PATH: String = "res://ai agent docs/screenshots/auto"
const AUTO_CAPTURE_USER_DESKTOP_PATH: String = "user://captures/desktop"
const AUTO_CAPTURE_USER_ANDROID_PATH: String = "user://captures/android"
const TILE_TUNING_CONFIG_PATH: String = "res://dev/tile_tuning.cfg"
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
const MELD_GUIDE_IDLE_ALPHA: float = 0.24
const MELD_GUIDE_DRAG_ALPHA: float = 0.82
const SNAP_FEEDBACK_DURATION: float = 0.20
const INVALID_FEEDBACK_DURATION: float = 0.20
const DEBUG_TELEMETRY_UPDATE_SEC: float = 0.6
const DRAG_FOLLOW_MODE_NONE: int = 0
const DRAG_FOLLOW_MODE_RACK: int = 1
const DRAG_FOLLOW_MODE_TABLE: int = 2
const DRAG_PREVIEW_POSITION_LERP_SPEED: float = 28.0
const DRAG_PREVIEW_ROTATION_LERP_SPEED: float = 20.0
const DRAG_PREVIEW_SNAP_DISTANCE: float = 0.055

# Interaction tuning
const PICK_RADIUS_PX: float = 42.0
const SHOW_DEBUG_GUIDES: bool = false
const DRAG_PICK_RADIUS_PX: float = 84.0
const SLOT_PICK_RADIUS_PX: float = 180.0
const RACK_ROW_STICKY_PICK_RADIUS_PX: float = 4096.0
const RACK_VISUAL_FOLLOW_RADIUS_PX: float = 64.0
const RACK_BAND_RELEASE_MARGIN_PX: float = 8.0
const RACK_BAND_REENTER_MARGIN_PX: float = -6.0
const MELD_DRAG_LANE_MARGIN: float = 0.040
const DRAG_START_DISTANCE_PX: float = 2.0
const INTERACT_COLLISION_LAYER: int = 1
const INTERACT_RAY_LENGTH: float = 5.0
const RACK_TILE_PICK_SIZE: Vector3 = Vector3(TILE_W * 0.98, TILE_H * 1.00, TILE_D * 3.8)
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
	3: Color(0.28, 0.17, 0.02), # Yellow (higher contrast)
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
var _pending_controller = null
var _has_pending_controller: bool = false

# Top HUD
var _hud_layer: CanvasLayer = null
var _hud_bar: PanelContainer = null
var _hud_instructions: Label = null
var _hud_turn: Label = null
var _hud_phase: Label = null
var _hud_deck: Label = null
var _hud_okey: Label = null
var _hud_debug_telemetry: Label = null
var _src_instructions: Label = null
var _src_turn: Label = null
var _src_phase: Label = null
var _src_deck: Label = null
var _src_okey: Label = null
var _src_top_bar: Control = null
var _telemetry_time_accum: float = 0.0
var _telemetry_frame_accum: int = 0
var _telemetry_renderer_method: String = ""
var _telemetry_platform: String = ""
var _telemetry_driver: String = ""
var _auto_capture_enabled: bool = false
var _auto_capture_elapsed: float = 0.0
var _auto_capture_count: int = 0
var _auto_capture_in_flight: bool = false
var _auto_capture_dir: String = ""
var _auto_capture_device_tag: String = "desktop"
var _auto_capture_last_file: String = ""

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
var _table_meld_tile_hits: Array[Dictionary] = []
var _local_rack_slot_hits: Array[Dictionary] = []
var _table_meld_base_centers: Dictionary = {}
var _table_meld_drag_offsets: Dictionary = {}

# Drag state
var _drag_candidate_tile_id: int = -1
var _drag_candidate_slot: int = -1
var _drag_candidate_stage_slot: int = -1
var _drag_candidate_meld_index: int = -1
var _drag_candidate_meld_owner: int = -1
var _drag_press_screen: Vector2 = Vector2.ZERO
var _drag_preview: Node3D = null
var _drag_active: bool = false
var _drag_preview_standing: bool = false
var _drag_preview_target_position: Vector3 = Vector3.ZERO
var _drag_preview_target_rotation: Vector3 = Vector3.ZERO
var _drag_preview_has_target: bool = false
var _drag_rack_row_lock: int = -1
var _drag_follow_mode: int = DRAG_FOLLOW_MODE_NONE
var _drag_started_from_rack: bool = false
var _local_rack_face_down_by_id: Dictionary = {}
var _required_tile_hue_id: int = -1

# Imported model scenes
var _rack_model_scene: PackedScene = null
var _tile_model_scene: PackedScene = null
var _tiles_library_scene: PackedScene = null
var _tileset_scene_by_color: Dictionary = {}
var _tileset_fake_scene: PackedScene = null
var _tile_template_nodes: Dictionary = {}
var _rack_model_pre_rot_deg: Vector3 = Vector3.ZERO
var _rack_row0_anchor: Vector3 = Vector3(0.0, RACK_ROW0_TILE_Y, RACK_ROW0_TILE_Z)
var _rack_row1_anchor: Vector3 = Vector3(0.0, RACK_ROW1_TILE_Y, RACK_ROW1_TILE_Z)
var _rack_row0_normal: Vector3 = Vector3(0.0, 0.26, 0.97).normalized()
var _rack_row1_normal: Vector3 = Vector3(0.0, 0.24, 0.97).normalized()
var _rack_row0_tilt_deg: float = RACK_ROW_TOP_TILT_DEG
var _rack_row1_tilt_deg: float = RACK_ROW_BOTTOM_TILT_DEG
var _rack_row_anchors_calibrated: bool = false
var _rack_helper_rows_active: bool = false
var _tune_row0_offset: Vector3 = Vector3.ZERO
var _tune_row1_offset: Vector3 = Vector3.ZERO
var _tune_row0_tilt_offset_deg: float = 0.0
var _tune_row1_tilt_offset_deg: float = 0.0
var _tune_row0_lift: float = RACK_ROW0_TILE_LIFT
var _tune_row1_lift: float = RACK_ROW1_TILE_LIFT
var _tune_base_scale: float = LOCAL_RACK_TILE_BASE_SCALE
var _tune_selected_scale: float = LOCAL_RACK_TILE_SELECTED_SCALE
var _tune_required_scale: float = LOCAL_RACK_TILE_REQUIRED_SCALE
var _tune_table_wood_color: Color = Color(0.31, 0.19, 0.12)
var _tune_felt_color: Color = Color(0.16, 0.34, 0.28)
var _tune_rack_color: Color = Color(0.52, 0.39, 0.28)
var _tune_opponent_rack_color: Color = Color(0.56, 0.42, 0.31)
var _tune_tile_face_color: Color = Color(0.95, 0.93, 0.88)
var _tune_tile_back_color: Color = Color(0.84, 0.80, 0.72)
var _tune_tile_face_roughness: float = 0.70
var _tune_tile_face_specular: float = 0.18
var _tune_table_wood_albedo_path: String = ""
var _tune_rack_wood_albedo_path: String = ""
var _tune_felt_albedo_path: String = ""
var _tune_number_tints: Dictionary = {}
var _tune_number_value_mul: float = 1.00
var _tune_number_saturation_mul: float = 1.00
var _tune_number_roughness: float = 0.62
var _tune_number_specular: float = 0.14
var _tune_number_unshaded: bool = false
var _tune_number_mesh_scale: float = 1.0
var _tune_use_embedded_number_materials: bool = true
var _tune_raw_library_tiles: bool = true
var _tune_safe_raw_material_clamp: bool = true
var _tune_raw_body_roughness_min: float = 0.66
var _tune_raw_body_specular_max: float = 0.18
var _tune_raw_numeric_roughness_min: float = 0.78
var _tune_raw_numeric_specular_max: float = 0.08
var _tune_tile_finish_filter_enabled: bool = true
var _tune_tile_finish_filter_strength: float = 0.44
var _tune_tile_finish_warm_tint: Color = Color(0.96, 0.93, 0.87, 1.0)
var _tune_tile_finish_roughness_boost: float = 0.18
var _tune_tile_finish_specular_scale: float = 0.28
var _tune_tile_finish_numeric_saturation_mul: float = 0.96
var _tune_tile_finish_numeric_value_mul: float = 0.95
var _tune_tile_finish_strip_aux_maps: bool = false
var _tune_tile_authoritative_surface: bool = true
var _tune_tile_authoritative_keep_albedo_texture: bool = false
var _tune_tile_authoritative_body_roughness: float = 0.74
var _tune_tile_authoritative_body_specular: float = 0.05
var _tune_tile_authoritative_numeric_roughness: float = 0.68
var _tune_tile_authoritative_numeric_specular: float = 0.03
var _tune_tile_authoritative_body_value_mul: float = 0.94
var _tune_readability_panel_enabled: bool = false
var _tune_readability_panel_alpha_standing: float = 0.00
var _tune_readability_panel_alpha_flat: float = 0.00
var _tune_readability_panel_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var _tune_force_number_labels: bool = false
var _tune_label_text_alpha: float = 0.96
var _tune_label_outline_alpha: float = 0.78
var _tune_label_font_size_standing: int = 12
var _tune_label_pixel_size_standing: float = 0.00024
var _tune_label_outline_size_standing: int = 1
var _tune_label_font_size_flat: int = 26
var _tune_label_pixel_size_flat: float = 0.00100
var _tune_label_outline_size_flat: int = 2
var _tune_readability_preset: String = "balanced"
var _tile_tune_loaded_path: String = ""
var _tile_tune_watch_mtime: int = -1
var _tile_tune_watch_elapsed: float = 0.0

# Sync hashes
var _last_selected_tile_id: int = -1
var _last_world_rack_hashes: Array[int] = [-1, -1, -1, -1]
var _last_world_stage_hash: int = -1
var _last_world_deck_hash: int = -1
var _last_world_discard_hashes: Array[int] = [-1, -1, -1, -1]
var _last_world_label_hash: int = -1

# Materials
var _rack_wood_material: StandardMaterial3D = null
var _opponent_rack_material: StandardMaterial3D = null
var _table_wood_material: StandardMaterial3D = null
var _tile_face_material: StandardMaterial3D = null
var _tile_back_material: StandardMaterial3D = null
var _tile_face_texture: Texture2D = null
var _local_meld_guide: Node3D = null
var _local_meld_guide_alpha: float = MELD_GUIDE_IDLE_ALPHA
var _hovered_rack_tile_id: int = -1
var _snap_feedback_tile_id: int = -1
var _snap_feedback_until: float = -1.0
var _invalid_feedback_tile_id: int = -1
var _invalid_feedback_until: float = -1.0
var _runtime_time: float = 0.0
var _last_phase_audio: int = -1
var _camera_preset_index: int = CAMERA_PRESET_DEFAULT_INDEX
var _audio_service: Node = null
var _ui_settings = null
var _visual_settings: Dictionary = {}
var _opponent_side_rim_lights: Array[OmniLight3D] = []
var _reflection_probes: Array[ReflectionProbe] = []
var _world_environment: Environment = null
var _tile_diagnostic_mode: bool = false
var _safe_raw_material_surface_count: int = 0


func _ready() -> void:
	_ui_settings = UI_SETTINGS_SCRIPT.load_from_disk()
	_visual_settings = UI_SETTINGS_SCRIPT.sanitize_visual_settings(_ui_settings)
	VISUAL_QUALITY_SCRIPT.apply_to_viewport(get_viewport(), _visual_settings)
	_load_tile_tuning_config()
	_configure_environment()
	_configure_world()
	_configure_materials()
	_create_audio_service()
	_load_model_assets()
	_create_world_elements()
	_create_hud_overlay()
	_init_debug_telemetry()
	_init_auto_capture()
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

func inject_controller(controller) -> void:
	if controller == null:
		return
	_pending_controller = controller
	_has_pending_controller = true
	_apply_pending_controller_if_ready()


func _process(delta: float) -> void:
	_runtime_time += delta
	_update_tile_tuning_watch(delta)
	_update_debug_telemetry(delta)
	_update_auto_capture(delta)
	_update_hover_candidate()
	if _drag_active and _drag_candidate_tile_id != -1:
		_update_drag_preview(get_viewport().get_mouse_position())
	_update_drag_preview_motion(delta)
	_update_feedback_animation_state()
	_sync_hud_from_table()
	_sync_world_racks()
	_sync_world_stage_tiles()
	_sync_world_deck()
	_sync_world_discards()
	_sync_world_labels()
	_update_opponent_rim_lights()
	_update_discard_guide_pulse()
	_sync_audio_from_state()
	_update_meld_guide_alpha()


func _input(event: InputEvent) -> void:
	# SubViewport/Control layers can consume clicks before _unhandled_input runs.
	# Handle round-end restart here so new-round trigger is always reachable.
	if event is not InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and mb.double_click and not _is_round_end_phase():
		if _hud_bar != null and _hud_bar.visible and _hud_bar.get_global_rect().has_point(mb.position):
			return
		var pick_dbl: Dictionary = _raycast_pick(mb.position)
		if str(pick_dbl.get("kind", "")) == "local_tile":
			_toggle_local_tile_face_down(int(pick_dbl.get("tile_id", -1)))
			get_viewport().set_input_as_handled()
			return
	if not _is_round_end_phase():
		return
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
		return
	if _hud_bar != null and _hud_bar.visible and _hud_bar.get_global_rect().has_point(mb.position):
		return
	if _game_table != null and is_instance_valid(_game_table) and _game_table.has_method("overlay_new_round"):
		_game_table.overlay_new_round()
		_force_sync()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_evt := event as InputEventKey
		if _handle_debug_key_shortcuts(key_evt):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		if _handle_drag_mouse_motion(event as InputEventMouseMotion):
			get_viewport().set_input_as_handled()
		return
	if event is not InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if mb.pressed:
		if _handle_mouse_press(mb):
			get_viewport().set_input_as_handled()
		return
	if _handle_mouse_release(mb):
		get_viewport().set_input_as_handled()


func _handle_debug_key_shortcuts(key_evt: InputEventKey) -> bool:
	if key_evt == null or not key_evt.pressed or key_evt.echo:
		return false
	if key_evt.keycode == TILE_TUNE_RELOAD_KEY:
		_load_tile_tuning_config()
		_apply_tile_tuning_runtime(true)
		if _hud_instructions != null:
			var src: String = _tile_tune_loaded_path if _tile_tune_loaded_path != "" else "defaults"
			_hud_instructions.text = "Tile tune reloaded (%s)" % src
		return true
	if key_evt.keycode == TILE_TUNE_DUMP_KEY:
		_dump_tile_tuning_state()
		if _hud_instructions != null:
			_hud_instructions.text = "Tile tune dumped to console"
		return true
	if key_evt.keycode == TILE_TUNE_HELP_KEY:
		_print_tile_tuning_help()
		if _hud_instructions != null:
			_hud_instructions.text = "Tile tune help printed to console"
		return true
	if not OS.is_debug_build():
		return false
	if CAMERA_PRESET_TOGGLE_ENABLED and key_evt.keycode == CAMERA_PRESET_TOGGLE_KEY:
		_camera_preset_index = (_camera_preset_index + 1) % maxi(1, CAMERA_PRESETS.size())
		_apply_camera_preset()
		if _hud_instructions != null:
			var preset_name: String = str(CAMERA_PRESETS[_camera_preset_index].get("name", "camera"))
			_hud_instructions.text = "Camera preset: %s" % preset_name
		return true
	if key_evt.keycode == AUTO_CAPTURE_TOGGLE_KEY:
		_auto_capture_enabled = not _auto_capture_enabled
		_auto_capture_elapsed = 0.0
		if _hud_instructions != null:
			_hud_instructions.text = "Auto capture: %s (%ds)" % [
				"ON" if _auto_capture_enabled else "OFF",
				int(AUTO_CAPTURE_INTERVAL_SEC)
			]
		return true
	if key_evt.keycode == TILE_DIAGNOSTIC_TOGGLE_KEY:
		_tile_diagnostic_mode = not _tile_diagnostic_mode
		_apply_runtime_visual_toggles()
		if _hud_instructions != null:
			_hud_instructions.text = "Tile diagnostic: %s" % ("ON" if _tile_diagnostic_mode else "OFF")
		return true
	if key_evt.keycode == MANUAL_CAPTURE_KEY:
		_capture_viewport_png("manual")
		return true
	return false


func _handle_drag_mouse_motion(mm: InputEventMouseMotion) -> bool:
	if _drag_candidate_tile_id != -1 and not _drag_active:
		if mm.position.distance_to(_drag_press_screen) >= DRAG_START_DISTANCE_PX:
			_start_drag_preview()
	elif _drag_candidate_meld_index != -1 and not _drag_active:
		if mm.position.distance_to(_drag_press_screen) >= DRAG_START_DISTANCE_PX:
			_drag_active = true
	if not _drag_active:
		return false
	if _drag_candidate_tile_id != -1:
		_update_drag_preview(mm.position)
	return true


func _handle_mouse_press(mb: InputEventMouseButton) -> bool:
	if mb.button_index == MOUSE_BUTTON_LEFT and _is_round_end_phase():
		if _game_table != null and is_instance_valid(_game_table) and _game_table.has_method("overlay_new_round"):
			_game_table.overlay_new_round()
			_force_sync()
			return true
		return false
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		if _hud_bar != null and _hud_bar.visible and _hud_bar.get_global_rect().has_point(mb.position):
			return false
		var pick_r: Dictionary = _raycast_pick(mb.position)
		if str(pick_r.get("kind", "")) == "local_tile":
			_toggle_local_tile_face_down(int(pick_r.get("tile_id", -1)))
			return true
		return false
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return false
	if _hud_bar != null and _hud_bar.visible and _hud_bar.get_global_rect().has_point(mb.position):
		return false
	_begin_drag_candidate_from_pick(mb.position)
	var table_pos: Vector2 = _screen_to_table_local_for_tap(mb.position)
	if _drag_candidate_tile_id != -1 or _drag_candidate_meld_index != -1:
		if _is_turn_draw_tap_zone(mb.position, table_pos):
			_clear_drag_state()
		else:
			return true
	var pick: Dictionary = _raycast_pick(mb.position)
	_handle_world_tap(pick, table_pos, mb.position)
	return true


func _handle_mouse_release(mb: InputEventMouseButton) -> bool:
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return false
	if _drag_candidate_tile_id == -1 and _drag_candidate_meld_index == -1 and not _drag_active:
		return false
	_finish_drag(mb.position)
	return true


func _configure_environment() -> void:
	RenderingServer.set_default_clear_color(Color(0.09, 0.05, 0.035, 1.0))
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = _make_tabletop_sky()
	env.background_color = Color(0.12, 0.07, 0.045, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.92, 0.85, 0.78, 1.0)
	env.ambient_light_energy = 0.76
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	VISUAL_QUALITY_SCRIPT.apply_to_environment(env, _visual_settings)
	_world_environment = env
	_apply_runtime_visual_toggles()
	world_env.environment = env
	_world_root.add_child(world_env)
	_world_root.move_child(world_env, 0)


func _apply_gameplay_environment_readability_overrides(env: Environment) -> void:
	if env == null:
		return
	env.set("glow_enabled", false)
	env.set("glow_levels/1", false)
	env.set("glow_levels/2", false)
	env.set("glow_levels/3", false)
	env.set("glow_levels/4", false)
	env.set("glow_levels/5", false)
	env.set("glow_levels/6", false)
	env.set("glow_levels/7", false)
	env.set("glow_intensity", 0.0)
	env.set("glow_strength", 0.0)
	env.set("glow_bloom", 0.0)
	env.set("adjustment_enabled", true)
	env.set("adjustment_brightness", 1.0)
	env.set("adjustment_contrast", 1.0)
	env.set("adjustment_saturation", 1.0)


func _apply_runtime_visual_toggles() -> void:
	if _world_environment == null:
		return
	VISUAL_QUALITY_SCRIPT.apply_to_environment(_world_environment, _visual_settings)
	_apply_gameplay_environment_readability_overrides(_world_environment)
	if _tile_diagnostic_mode:
		_world_environment.set("ssao_enabled", false)
		_world_environment.set("ssil_enabled", false)
		_world_environment.set("ssr_enabled", false)
	for probe in _reflection_probes:
		if probe == null or not is_instance_valid(probe):
			continue
		probe.intensity = 0.0 if _tile_diagnostic_mode else 0.28


func _load_texture_first(paths: Array[String]) -> Texture2D:
	for p in paths:
		if p == "":
			continue
		if not FileAccess.file_exists(p):
			continue
		var tex: Texture2D = load(p) as Texture2D
		if tex != null:
			return tex
	return null


func _asset_path(id: StringName) -> String:
	return ASSET_REGISTRY.path(id)


func _load_packed_scene_if_exists(path: String) -> PackedScene:
	if path == "" or not FileAccess.file_exists(path):
		return null
	return load(path) as PackedScene


func _apply_pbr_textures(mat: StandardMaterial3D, albedo: Texture2D, normal_tex: Texture2D, roughness_tex: Texture2D, uv_scale: Vector3, triplanar: bool = true, normal_strength: float = 1.0) -> void:
	if mat == null:
		return
	if albedo != null:
		mat.albedo_texture = albedo
	if normal_tex != null:
		mat.normal_enabled = true
		mat.normal_texture = normal_tex
		mat.normal_scale = normal_strength
	if roughness_tex != null:
		mat.roughness_texture = roughness_tex
	mat.uv1_triplanar = triplanar
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.uv1_scale = uv_scale


func _make_tabletop_sky() -> Sky:
	var hdri: Texture2D = _load_texture_first([
		_asset_path(CC0_HDRI_PRIMARY_ID),
		_asset_path(CC0_HDRI_SECONDARY_ID),
	])
	if hdri != null:
		var hdri_sky := Sky.new()
		var pan := PanoramaSkyMaterial.new()
		pan.panorama = hdri
		pan.energy_multiplier = 0.58
		hdri_sky.sky_material = pan
		return hdri_sky
	var sky := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	mat.sky_top_color = Color(0.08, 0.05, 0.04, 1.0)
	mat.sky_horizon_color = Color(0.14, 0.09, 0.06, 1.0)
	mat.ground_bottom_color = Color(0.04, 0.025, 0.018, 1.0)
	mat.ground_horizon_color = Color(0.09, 0.06, 0.04, 1.0)
	mat.sun_angle_max = 0.0
	mat.sun_curve = 0.02
	sky.sky_material = mat
	return sky


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
	_apply_camera_preset()

	_key_light.position = Vector3(1.5, 2.0, 1.3)
	_key_light.rotation_degrees = Vector3(-58.0, 28.0, 0.0)
	_key_light.light_color = Color(1.0, 0.95, 0.87, 1.0)
	_key_light.shadow_enabled = true

	_rim_light.position = Vector3(-1.7, 1.8, -1.2)
	_rim_light.rotation_degrees = Vector3(-42.0, -145.0, 0.0)
	_rim_light.light_color = Color(0.52, 0.69, 0.90, 1.0)

	_fill_light.position = Vector3(0.0, 0.80, 0.65)
	_fill_light.light_color = Color(1.0, 0.76, 0.58, 1.0)
	_fill_light.omni_range = 3.4
	VISUAL_QUALITY_SCRIPT.apply_to_lights(_key_light, _rim_light, _fill_light, _visual_settings)
	_create_reflection_probes()


func _create_reflection_probes() -> void:
	for probe in _reflection_probes:
		if probe != null and is_instance_valid(probe):
			probe.queue_free()
	_reflection_probes.clear()

	var centers: Array[Vector3] = [
		Vector3(0.0, 0.28, 0.02),
		Vector3(0.0, 0.18, 0.42),
	]
	for c in centers:
		var probe := ReflectionProbe.new()
		probe.name = "TableReflectionProbe"
		probe.position = c
		probe.size = Vector3(1.2, 0.78, 1.2)
		probe.box_projection = true
		probe.update_mode = ReflectionProbe.UPDATE_ONCE
		probe.intensity = 0.28
		_world_root.add_child(probe)
		_reflection_probes.append(probe)
	_apply_runtime_visual_toggles()


func _apply_camera_preset() -> void:
	if _camera == null:
		return
	if CAMERA_PRESETS.is_empty():
		return
	_camera_preset_index = clampi(_camera_preset_index, 0, CAMERA_PRESETS.size() - 1)
	var preset: Dictionary = CAMERA_PRESETS[_camera_preset_index]
	_camera.fov = float(preset.get("fov", 60.0))
	_camera.near = float(preset.get("near", 0.03))
	_camera.far = float(preset.get("far", 20.0))
	_camera.position = preset.get("pos", Vector3(0.0, 0.80, 0.52)) as Vector3
	_camera.look_at(preset.get("focus", Vector3(0.0, 0.02, -0.02)) as Vector3, Vector3.UP)


func _configure_materials() -> void:
	var backdrop_mat := StandardMaterial3D.new()
	backdrop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	backdrop_mat.albedo_color = Color(0.17, 0.10, 0.07, 0.94)
	backdrop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	backdrop_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_backdrop.set_surface_override_material(0, backdrop_mat)

	var postfx: float = clampf(float(_visual_settings.get("postfx_strength", 0.70)), 0.0, 1.0)
	var table_wood_albedo_paths: Array[String] = []
	if _tune_table_wood_albedo_path != "":
		table_wood_albedo_paths.append(_tune_table_wood_albedo_path)
	table_wood_albedo_paths.append(_asset_path(CC0_TABLE_WOOD_DIFFUSE_ID))
	table_wood_albedo_paths.append(_asset_path(WOOD_TEX_ID))
	var table_wood_albedo: Texture2D = _load_texture_first(table_wood_albedo_paths)
	var table_wood_normal: Texture2D = _load_texture_first([_asset_path(CC0_TABLE_WOOD_NORMAL_ID)])
	var table_wood_roughness: Texture2D = _load_texture_first([_asset_path(CC0_TABLE_WOOD_ROUGHNESS_ID)])
	var rack_wood_albedo_paths: Array[String] = []
	if _tune_rack_wood_albedo_path != "":
		rack_wood_albedo_paths.append(_tune_rack_wood_albedo_path)
	rack_wood_albedo_paths.append(_asset_path(CC0_RACK_WOOD_DIFFUSE_ID))
	rack_wood_albedo_paths.append(_asset_path(WOOD_TEX_ID))
	var rack_wood_albedo: Texture2D = _load_texture_first(rack_wood_albedo_paths)
	var rack_wood_normal: Texture2D = _load_texture_first([_asset_path(CC0_RACK_WOOD_NORMAL_ID)])
	var rack_wood_roughness: Texture2D = _load_texture_first([_asset_path(CC0_RACK_WOOD_ROUGHNESS_ID)])
	var felt_albedo_paths: Array[String] = []
	if _tune_felt_albedo_path != "":
		felt_albedo_paths.append(_tune_felt_albedo_path)
	felt_albedo_paths.append(_asset_path(CLOTH_TEX_ID))
	felt_albedo_paths.append(_asset_path(CC0_FELT_COLOR_ID))
	var felt_albedo: Texture2D = _load_texture_first(felt_albedo_paths)
	var felt_normal: Texture2D = null
	var felt_roughness: Texture2D = _load_texture_first([_asset_path(CC0_FELT_ROUGHNESS_ID)])

	_table_wood_material = StandardMaterial3D.new()
	_table_wood_material.albedo_color = _tune_table_wood_color
	_table_wood_material.roughness = lerpf(0.86, 0.72, postfx)
	_table_wood_material.metallic = 0.0
	_table_wood_material.metallic_specular = 0.46
	_apply_pbr_textures(_table_wood_material, table_wood_albedo, table_wood_normal, table_wood_roughness, Vector3(2.2, 2.2, 2.2), true, 0.52)
	_table_body.set_surface_override_material(0, _table_wood_material)

	var felt_mat := StandardMaterial3D.new()
	felt_mat.albedo_color = _tune_felt_color
	felt_mat.roughness = 0.99
	felt_mat.metallic_specular = 0.09
	felt_mat.metallic = 0.0
	felt_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_apply_pbr_textures(felt_mat, felt_albedo, felt_normal, felt_roughness, Vector3(2.1, 2.1, 1.0), false, 0.0)
	_table_surface.set_surface_override_material(0, felt_mat)

	_rack_wood_material = StandardMaterial3D.new()
	_rack_wood_material.albedo_color = _tune_rack_color
	_rack_wood_material.roughness = lerpf(0.80, 0.68, postfx)
	_rack_wood_material.metallic = 0.0
	_rack_wood_material.metallic_specular = 0.40
	_apply_pbr_textures(_rack_wood_material, rack_wood_albedo, rack_wood_normal, rack_wood_roughness, Vector3(2.8, 2.8, 2.8), true, 0.58)

	_opponent_rack_material = _rack_wood_material.duplicate() as StandardMaterial3D
	if _opponent_rack_material == null:
		_opponent_rack_material = StandardMaterial3D.new()
		_opponent_rack_material.albedo_color = Color(0.48, 0.36, 0.25)
		_opponent_rack_material.roughness = 0.76
		_opponent_rack_material.metallic = 0.0
		_opponent_rack_material.metallic_specular = 0.34
		_apply_pbr_textures(_opponent_rack_material, rack_wood_albedo, rack_wood_normal, rack_wood_roughness, Vector3(2.8, 2.8, 2.8), true, 0.30)
	_opponent_rack_material.roughness = maxf(_opponent_rack_material.roughness, 0.86)
	_opponent_rack_material.metallic_specular = minf(_opponent_rack_material.metallic_specular, 0.16)
	_opponent_rack_material.normal_scale = 0.30
	_opponent_rack_material.albedo_color = _tune_opponent_rack_color

	_tile_face_material = StandardMaterial3D.new()
	_tile_face_material.albedo_color = _tune_tile_face_color
	_tile_face_material.roughness = _tune_tile_face_roughness
	_tile_face_material.metallic = 0.0
	_tile_face_material.metallic_specular = _tune_tile_face_specular
	_tile_face_texture = null
	if USE_TILE_FACE_TEXTURE:
		_tile_face_texture = load(_asset_path(TILE_FACE_TEX_ID)) as Texture2D
	if _tile_face_texture != null:
		_tile_face_material.albedo_texture = _tile_face_texture
		_tile_face_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	_tile_back_material = StandardMaterial3D.new()
	_tile_back_material.albedo_color = _tune_tile_back_color
	_tile_back_material.roughness = 0.82
	_tile_back_material.metallic = 0.0
	_tile_back_material.metallic_specular = 0.20


func _create_audio_service() -> void:
	if _audio_service != null and is_instance_valid(_audio_service):
		_audio_service.queue_free()
	_audio_service = AUDIO_SERVICE_SCRIPT.new()
	_audio_service.name = "AudioService"
	add_child(_audio_service)
	if _audio_service != null and _audio_service.has_method("set_content_pack"):
		_audio_service.set_content_pack(&"cc0")
	if _ui_settings != null:
		_audio_service.set_levels_linear(
			float(_ui_settings.get("sfx_volume", 0.82)),
			float(_ui_settings.get("music_volume", 0.30))
		)


func _load_model_assets() -> void:
	_rack_row0_anchor = Vector3(0.0, RACK_ROW0_TILE_Y, RACK_ROW0_TILE_Z)
	_rack_row1_anchor = Vector3(0.0, RACK_ROW1_TILE_Y, RACK_ROW1_TILE_Z)
	_rack_row0_normal = Vector3(0.0, 0.26, 0.97).normalized()
	_rack_row1_normal = Vector3(0.0, 0.24, 0.97).normalized()
	_rack_row0_tilt_deg = RACK_ROW_TOP_TILT_DEG
	_rack_row1_tilt_deg = RACK_ROW_BOTTOM_TILT_DEG
	_rack_row_anchors_calibrated = false
	_rack_helper_rows_active = false
	_rack_model_scene = _load_packed_scene_if_exists(_asset_path(RACK_MODEL_ID))
	_tile_model_scene = _load_packed_scene_if_exists(_asset_path(TILE_MODEL_ID))
	_tiles_library_scene = _load_packed_scene_if_exists(_asset_path(TILES_LIBRARY_ID))
	_tileset_scene_by_color = {}
	_tileset_fake_scene = null
	if USE_LEGACY_TILESET_FALLBACK:
		_tileset_scene_by_color = {
			Tile.TileColor.RED: _load_packed_scene_if_exists(_asset_path(TILESET_RED_ID)),
			Tile.TileColor.BLUE: _load_packed_scene_if_exists(_asset_path(TILESET_BLUE_ID)),
			Tile.TileColor.BLACK: _load_packed_scene_if_exists(_asset_path(TILESET_GREEN_ID)),
			Tile.TileColor.YELLOW: _load_packed_scene_if_exists(_asset_path(TILESET_YELLOW_ID)),
		}
		_tileset_fake_scene = _load_packed_scene_if_exists(_asset_path(TILESET_FAKE_OKEY_ID))
	_build_tileset_templates()
	if _tiles_library_scene == null:
		push_warning("Tile library scene not found at %s." % _asset_path(TILES_LIBRARY_ID))
	if USE_AUTO_RACK_MODEL_PRE_ROT:
		_rack_model_pre_rot_deg = _estimate_rack_model_pre_rotation(_rack_model_scene)
	else:
		_rack_model_pre_rot_deg = RACK_MODEL_PRE_ROT_DEFAULT


func _load_tile_tuning_config() -> void:
	_tune_row0_offset = Vector3.ZERO
	_tune_row1_offset = Vector3.ZERO
	_tune_row0_tilt_offset_deg = 0.0
	_tune_row1_tilt_offset_deg = 0.0
	_tune_row0_lift = RACK_ROW0_TILE_LIFT
	_tune_row1_lift = RACK_ROW1_TILE_LIFT
	_tune_base_scale = LOCAL_RACK_TILE_BASE_SCALE
	_tune_selected_scale = LOCAL_RACK_TILE_SELECTED_SCALE
	_tune_required_scale = LOCAL_RACK_TILE_REQUIRED_SCALE
	_tune_table_wood_color = Color(0.31, 0.19, 0.12)
	_tune_felt_color = Color(0.16, 0.34, 0.28)
	_tune_rack_color = Color(0.52, 0.39, 0.28)
	_tune_opponent_rack_color = Color(0.56, 0.42, 0.31)
	_tune_tile_face_color = Color(0.95, 0.93, 0.88)
	_tune_tile_back_color = Color(0.84, 0.80, 0.72)
	_tune_tile_face_roughness = 0.70
	_tune_tile_face_specular = 0.18
	_tune_table_wood_albedo_path = ""
	_tune_rack_wood_albedo_path = ""
	_tune_felt_albedo_path = ""
	_tune_number_value_mul = 1.00
	_tune_number_saturation_mul = 1.00
	_tune_number_roughness = 0.62
	_tune_number_specular = 0.14
	_tune_number_unshaded = false
	_tune_number_mesh_scale = 1.0
	_tune_use_embedded_number_materials = true
	_tune_raw_library_tiles = true
	_tune_safe_raw_material_clamp = false
	_tune_raw_body_roughness_min = 0.66
	_tune_raw_body_specular_max = 0.18
	_tune_raw_numeric_roughness_min = 0.78
	_tune_raw_numeric_specular_max = 0.08
	_tune_tile_finish_filter_enabled = false
	_tune_tile_finish_filter_strength = 0.44
	_tune_tile_finish_warm_tint = Color(0.96, 0.93, 0.87, 1.0)
	_tune_tile_finish_roughness_boost = 0.18
	_tune_tile_finish_specular_scale = 0.28
	_tune_tile_finish_numeric_saturation_mul = 0.96
	_tune_tile_finish_numeric_value_mul = 0.95
	_tune_tile_finish_strip_aux_maps = false
	_tune_tile_authoritative_surface = false
	_tune_tile_authoritative_keep_albedo_texture = false
	_tune_tile_authoritative_body_roughness = 0.74
	_tune_tile_authoritative_body_specular = 0.05
	_tune_tile_authoritative_numeric_roughness = 0.68
	_tune_tile_authoritative_numeric_specular = 0.03
	_tune_tile_authoritative_body_value_mul = 0.94
	_tune_readability_panel_enabled = false
	_tune_readability_panel_alpha_standing = 0.00
	_tune_readability_panel_alpha_flat = 0.00
	_tune_readability_panel_color = Color(1.0, 1.0, 1.0, 1.0)
	_tune_force_number_labels = false
	_tune_label_text_alpha = 0.96
	_tune_label_outline_alpha = 0.78
	_tune_label_font_size_standing = 12
	_tune_label_pixel_size_standing = 0.00024
	_tune_label_outline_size_standing = 1
	_tune_label_font_size_flat = 26
	_tune_label_pixel_size_flat = 0.00100
	_tune_label_outline_size_flat = 2
	_tune_readability_preset = "balanced"
	_tune_number_tints = {
		int(Tile.TileColor.RED): Color(0.78, 0.12, 0.10, 1.0),
		int(Tile.TileColor.BLUE): Color(0.11, 0.37, 0.72, 1.0),
		int(Tile.TileColor.BLACK): Color(0.10, 0.10, 0.13, 1.0),
		int(Tile.TileColor.YELLOW): Color(0.22, 0.14, 0.01, 1.0),
	}
	_tile_tune_loaded_path = ""

	if not FileAccess.file_exists(TILE_TUNING_CONFIG_PATH):
		return

	var cfg := ConfigFile.new()
	if cfg.load(TILE_TUNING_CONFIG_PATH) != OK:
		push_warning("Tile tuning config could not be loaded: %s" % TILE_TUNING_CONFIG_PATH)
		return

	_tune_row0_offset = Vector3(
		float(cfg.get_value("rack", "row0_x_offset", 0.0)),
		float(cfg.get_value("rack", "row0_y_offset", 0.0)),
		float(cfg.get_value("rack", "row0_z_offset", 0.0))
	)
	_tune_row1_offset = Vector3(
		float(cfg.get_value("rack", "row1_x_offset", 0.0)),
		float(cfg.get_value("rack", "row1_y_offset", 0.0)),
		float(cfg.get_value("rack", "row1_z_offset", 0.0))
	)
	_tune_row0_tilt_offset_deg = float(cfg.get_value("rack", "row0_tilt_offset_deg", 0.0))
	_tune_row1_tilt_offset_deg = float(cfg.get_value("rack", "row1_tilt_offset_deg", 0.0))
	_tune_row0_lift = maxf(0.0, float(cfg.get_value("rack", "row0_lift", RACK_ROW0_TILE_LIFT)))
	_tune_row1_lift = maxf(0.0, float(cfg.get_value("rack", "row1_lift", RACK_ROW1_TILE_LIFT)))
	_tune_base_scale = clampf(float(cfg.get_value("tiles", "base_scale", LOCAL_RACK_TILE_BASE_SCALE)), 0.85, 1.30)
	_tune_selected_scale = clampf(float(cfg.get_value("tiles", "selected_scale", LOCAL_RACK_TILE_SELECTED_SCALE)), 0.90, 1.40)
	_tune_required_scale = clampf(float(cfg.get_value("tiles", "required_scale", LOCAL_RACK_TILE_REQUIRED_SCALE)), 0.90, 1.35)
	_tune_table_wood_color = _cfg_color(cfg, "colors", "table_wood", _tune_table_wood_color)
	_tune_felt_color = _cfg_color(cfg, "colors", "felt", _tune_felt_color)
	_tune_rack_color = _cfg_color(cfg, "colors", "rack", _tune_rack_color)
	_tune_opponent_rack_color = _cfg_color(cfg, "colors", "opponent_rack", _tune_opponent_rack_color)
	_tune_tile_face_color = _cfg_color(cfg, "colors", "tile_face", _tune_tile_face_color)
	_tune_tile_back_color = _cfg_color(cfg, "colors", "tile_back", _tune_tile_back_color)
	_tune_number_tints[int(Tile.TileColor.RED)] = _cfg_color(cfg, "numbers", "red", _tune_number_tints[int(Tile.TileColor.RED)] as Color)
	_tune_number_tints[int(Tile.TileColor.BLUE)] = _cfg_color(cfg, "numbers", "blue", _tune_number_tints[int(Tile.TileColor.BLUE)] as Color)
	_tune_number_tints[int(Tile.TileColor.BLACK)] = _cfg_color(cfg, "numbers", "black", _tune_number_tints[int(Tile.TileColor.BLACK)] as Color)
	_tune_number_tints[int(Tile.TileColor.YELLOW)] = _cfg_color(cfg, "numbers", "yellow", _tune_number_tints[int(Tile.TileColor.YELLOW)] as Color)
	_tune_tile_face_roughness = clampf(float(cfg.get_value("readability", "tile_face_roughness", _tune_tile_face_roughness)), 0.2, 1.0)
	_tune_tile_face_specular = clampf(float(cfg.get_value("readability", "tile_face_specular", _tune_tile_face_specular)), 0.0, 1.0)
	_tune_number_value_mul = clampf(float(cfg.get_value("readability", "number_value_mul", _tune_number_value_mul)), 0.3, 2.0)
	_tune_number_saturation_mul = clampf(float(cfg.get_value("readability", "number_saturation_mul", _tune_number_saturation_mul)), 0.0, 2.0)
	_tune_number_roughness = clampf(float(cfg.get_value("readability", "number_roughness", _tune_number_roughness)), 0.0, 1.0)
	_tune_number_specular = clampf(float(cfg.get_value("readability", "number_specular", _tune_number_specular)), 0.0, 1.0)
	_tune_number_unshaded = bool(cfg.get_value("readability", "number_unshaded", _tune_number_unshaded))
	_tune_number_mesh_scale = clampf(float(cfg.get_value("readability", "number_mesh_scale", _tune_number_mesh_scale)), 0.80, 1.60)
	_tune_use_embedded_number_materials = bool(cfg.get_value("readability", "use_embedded_number_materials", _tune_use_embedded_number_materials))
	_tune_raw_library_tiles = bool(cfg.get_value("readability", "raw_library_tiles", _tune_raw_library_tiles))
	_tune_safe_raw_material_clamp = bool(cfg.get_value("readability", "safe_raw_material_clamp", _tune_safe_raw_material_clamp))
	_tune_raw_body_roughness_min = clampf(float(cfg.get_value("readability", "raw_body_roughness_min", _tune_raw_body_roughness_min)), 0.0, 1.0)
	_tune_raw_body_specular_max = clampf(float(cfg.get_value("readability", "raw_body_specular_max", _tune_raw_body_specular_max)), 0.0, 1.0)
	_tune_raw_numeric_roughness_min = clampf(float(cfg.get_value("readability", "raw_numeric_roughness_min", _tune_raw_numeric_roughness_min)), 0.0, 1.0)
	_tune_raw_numeric_specular_max = clampf(float(cfg.get_value("readability", "raw_numeric_specular_max", _tune_raw_numeric_specular_max)), 0.0, 1.0)
	_tune_tile_finish_filter_enabled = bool(cfg.get_value("readability", "tile_finish_filter_enabled", _tune_tile_finish_filter_enabled))
	_tune_tile_finish_filter_strength = clampf(float(cfg.get_value("readability", "tile_finish_filter_strength", _tune_tile_finish_filter_strength)), 0.0, 1.0)
	_tune_tile_finish_warm_tint = _cfg_color(cfg, "readability", "tile_finish_warm_tint", _tune_tile_finish_warm_tint)
	_tune_tile_finish_roughness_boost = clampf(float(cfg.get_value("readability", "tile_finish_roughness_boost", _tune_tile_finish_roughness_boost)), 0.0, 0.5)
	_tune_tile_finish_specular_scale = clampf(float(cfg.get_value("readability", "tile_finish_specular_scale", _tune_tile_finish_specular_scale)), 0.05, 1.0)
	_tune_tile_finish_numeric_saturation_mul = clampf(float(cfg.get_value("readability", "tile_finish_numeric_saturation_mul", _tune_tile_finish_numeric_saturation_mul)), 0.5, 1.4)
	_tune_tile_finish_numeric_value_mul = clampf(float(cfg.get_value("readability", "tile_finish_numeric_value_mul", _tune_tile_finish_numeric_value_mul)), 0.5, 1.4)
	_tune_tile_finish_strip_aux_maps = bool(cfg.get_value("readability", "tile_finish_strip_aux_maps", _tune_tile_finish_strip_aux_maps))
	_tune_tile_authoritative_surface = bool(cfg.get_value("readability", "tile_authoritative_surface", _tune_tile_authoritative_surface))
	_tune_tile_authoritative_keep_albedo_texture = bool(cfg.get_value("readability", "tile_authoritative_keep_albedo_texture", _tune_tile_authoritative_keep_albedo_texture))
	_tune_tile_authoritative_body_roughness = clampf(float(cfg.get_value("readability", "tile_authoritative_body_roughness", _tune_tile_authoritative_body_roughness)), 0.0, 1.0)
	_tune_tile_authoritative_body_specular = clampf(float(cfg.get_value("readability", "tile_authoritative_body_specular", _tune_tile_authoritative_body_specular)), 0.0, 1.0)
	_tune_tile_authoritative_numeric_roughness = clampf(float(cfg.get_value("readability", "tile_authoritative_numeric_roughness", _tune_tile_authoritative_numeric_roughness)), 0.0, 1.0)
	_tune_tile_authoritative_numeric_specular = clampf(float(cfg.get_value("readability", "tile_authoritative_numeric_specular", _tune_tile_authoritative_numeric_specular)), 0.0, 1.0)
	_tune_tile_authoritative_body_value_mul = clampf(float(cfg.get_value("readability", "tile_authoritative_body_value_mul", _tune_tile_authoritative_body_value_mul)), 0.65, 1.10)
	_tune_readability_panel_enabled = bool(cfg.get_value("readability", "panel_enabled", _tune_readability_panel_enabled))
	_tune_readability_panel_alpha_standing = clampf(float(cfg.get_value("readability", "panel_alpha_standing", _tune_readability_panel_alpha_standing)), 0.0, 0.8)
	_tune_readability_panel_alpha_flat = clampf(float(cfg.get_value("readability", "panel_alpha_flat", _tune_readability_panel_alpha_flat)), 0.0, 0.8)
	_tune_readability_panel_color = _cfg_color(cfg, "readability", "panel_color", _tune_readability_panel_color)
	_tune_force_number_labels = bool(cfg.get_value("readability", "force_number_labels", _tune_force_number_labels))
	_tune_label_text_alpha = clampf(float(cfg.get_value("readability", "label_text_alpha", _tune_label_text_alpha)), 0.0, 1.0)
	_tune_label_outline_alpha = clampf(float(cfg.get_value("readability", "label_outline_alpha", _tune_label_outline_alpha)), 0.0, 1.0)
	_tune_label_font_size_standing = clampi(int(cfg.get_value("readability", "label_font_size_standing", _tune_label_font_size_standing)), 8, 24)
	_tune_label_pixel_size_standing = clampf(float(cfg.get_value("readability", "label_pixel_size_standing", _tune_label_pixel_size_standing)), 0.00008, 0.0012)
	_tune_label_outline_size_standing = clampi(int(cfg.get_value("readability", "label_outline_size_standing", _tune_label_outline_size_standing)), 0, 8)
	_tune_label_font_size_flat = clampi(int(cfg.get_value("readability", "label_font_size_flat", _tune_label_font_size_flat)), 10, 56)
	_tune_label_pixel_size_flat = clampf(float(cfg.get_value("readability", "label_pixel_size_flat", _tune_label_pixel_size_flat)), 0.0003, 0.0035)
	_tune_label_outline_size_flat = clampi(int(cfg.get_value("readability", "label_outline_size_flat", _tune_label_outline_size_flat)), 0, 8)
	_tune_readability_preset = str(cfg.get_value("readability", "preset", _tune_readability_preset)).to_lower().strip_edges()
	_apply_readability_preset(_tune_readability_preset)
	_tune_table_wood_albedo_path = str(cfg.get_value("textures", "table_wood_albedo_path", "")).strip_edges()
	_tune_rack_wood_albedo_path = str(cfg.get_value("textures", "rack_wood_albedo_path", "")).strip_edges()
	_tune_felt_albedo_path = str(cfg.get_value("textures", "felt_albedo_path", "")).strip_edges()
	_tile_tune_loaded_path = TILE_TUNING_CONFIG_PATH
	_tile_tune_watch_mtime = _tile_tuning_file_mtime()
	_tile_tune_watch_elapsed = 0.0
	print("[TILE-TUNE] loaded: %s" % TILE_TUNING_CONFIG_PATH)


func _cfg_color(cfg: ConfigFile, section: String, key: String, fallback: Color) -> Color:
	if cfg == null:
		return fallback
	var raw = cfg.get_value(section, key, "")
	if raw is Color:
		return raw as Color
	var s: String = str(raw).strip_edges()
	if s == "":
		return fallback
	return Color.from_string(s, fallback)


func _tile_tuning_file_mtime() -> int:
	if not FileAccess.file_exists(TILE_TUNING_CONFIG_PATH):
		return -1
	return int(FileAccess.get_modified_time(TILE_TUNING_CONFIG_PATH))


func _apply_tile_tuning_runtime(rebuild_templates: bool = false) -> void:
	if rebuild_templates:
		_build_tileset_templates()
	_configure_materials()
	_apply_runtime_visual_toggles()
	# Hot-reload should not tear down world nodes mid-session; that can briefly leave
	# the table empty if sync order/race timing misses a frame.
	if _dynamic_root == null or not is_instance_valid(_dynamic_root):
		_create_world_elements()
	_force_sync()
	# Repaint immediately instead of waiting for next process tick.
	_sync_world_racks()
	_sync_world_stage_tiles()
	_sync_world_deck()
	_sync_world_discards()
	_sync_world_labels()


func _update_tile_tuning_watch(delta: float) -> void:
	if TILE_TUNING_CONFIG_PATH == "":
		return
	_tile_tune_watch_elapsed += maxf(delta, 0.0)
	if _tile_tune_watch_elapsed < TILE_TUNE_WATCH_INTERVAL_SEC:
		return
	_tile_tune_watch_elapsed = 0.0
	var current_mtime: int = _tile_tuning_file_mtime()
	if current_mtime == -1:
		return
	if _tile_tune_watch_mtime == -1:
		_tile_tune_watch_mtime = current_mtime
		return
	if current_mtime == _tile_tune_watch_mtime:
		return
	_load_tile_tuning_config()
	_apply_tile_tuning_runtime(true)
	if _hud_instructions != null:
		_hud_instructions.text = "Tile tune auto-reloaded"


func _apply_readability_preset(preset_name: String) -> void:
	match preset_name:
		"texture_first":
			_tune_number_unshaded = false
			_tune_readability_panel_enabled = false
			_tune_force_number_labels = false
		"high_contrast":
			_tune_number_unshaded = true
			_tune_number_value_mul = maxf(_tune_number_value_mul, 1.18)
			_tune_number_saturation_mul = maxf(_tune_number_saturation_mul, 1.05)
			_tune_readability_panel_enabled = true
			_tune_readability_panel_alpha_standing = maxf(_tune_readability_panel_alpha_standing, 0.11)
			_tune_readability_panel_alpha_flat = maxf(_tune_readability_panel_alpha_flat, 0.08)
			_tune_force_number_labels = true
		_:
			# balanced/default keeps explicit values from config.
			pass


func _apply_number_readability(color: Color) -> Color:
	var h: float = color.h
	var s: float = clampf(color.s * _tune_number_saturation_mul, 0.0, 1.0)
	var v: float = clampf(color.v * _tune_number_value_mul, 0.0, 1.0)
	return Color.from_hsv(h, s, v, color.a)


func _print_tile_tuning_help() -> void:
	print("[TILE-TUNE HELP] Edit: ", TILE_TUNING_CONFIG_PATH)
	print("[TILE-TUNE HELP] Hotkeys: F8=tile diagnostic toggle, F9=reload, F10=dump values, F11=this help, F12=manual capture")
	print("[TILE-TUNE HELP] Auto-reload: ON (checks file changes every %.1fs)" % TILE_TUNE_WATCH_INTERVAL_SEC)
	print("[TILE-TUNE HELP] readability.preset => balanced | texture_first | high_contrast")
	print("[TILE-TUNE HELP] readability.number_value_mul (0.3..2.0), number_saturation_mul (0.0..2.0)")
	print("[TILE-TUNE HELP] readability.number_roughness (0..1), number_specular (0..1), number_unshaded (true/false), number_mesh_scale (0.8..1.6)")
	print("[TILE-TUNE HELP] readability.use_embedded_number_materials (true/false): preserve Text/Torus colors from tiles_library.glb")
	print("[TILE-TUNE HELP] readability.raw_library_tiles (true/false): disable runtime tile material/effect overrides and show bare GLB materials")
	print("[TILE-TUNE HELP] readability.safe_raw_material_clamp (true/false): keep embedded look but clamp metallic/spec extremes")
	print("[TILE-TUNE HELP] readability.raw_body_roughness_min/raw_body_specular_max, raw_numeric_roughness_min/raw_numeric_specular_max")
	print("[TILE-TUNE HELP] readability.tile_finish_filter_enabled/tile_finish_filter_strength")
	print("[TILE-TUNE HELP] readability.tile_finish_warm_tint, tile_finish_roughness_boost, tile_finish_specular_scale")
	print("[TILE-TUNE HELP] readability.tile_finish_numeric_saturation_mul/tile_finish_numeric_value_mul")
	print("[TILE-TUNE HELP] readability.tile_finish_strip_aux_maps (true/false): strips rough/metal/normal/ao/clearcoat maps from tile mats")
	print("[TILE-TUNE HELP] readability.tile_authoritative_surface (true/false): replace raw tile surface BRDF with stable satin values")
	print("[TILE-TUNE HELP] readability.tile_authoritative_keep_albedo_texture (true/false)")
	print("[TILE-TUNE HELP] readability.tile_authoritative_body_roughness/specular, tile_authoritative_numeric_roughness/specular, tile_authoritative_body_value_mul")
	print("[TILE-TUNE HELP] readability.panel_enabled, panel_alpha_standing/panel_alpha_flat (0..0.8), panel_color")
	print("[TILE-TUNE HELP] readability.force_number_labels (true/false)")
	print("[TILE-TUNE HELP] readability.label_font_size_standing, label_pixel_size_standing, label_outline_size_standing")
	print("[TILE-TUNE HELP] readability.label_font_size_flat, label_pixel_size_flat, label_outline_size_flat")
	print("[TILE-TUNE HELP] numbers.red/blue/black/yellow => #RRGGBB for glyph color tuning")


func _rack_row0_anchor_tuned() -> Vector3:
	return _rack_row0_anchor + _tune_row0_offset


func _rack_row1_anchor_tuned() -> Vector3:
	return _rack_row1_anchor + _tune_row1_offset


func _rack_row0_tilt_tuned() -> float:
	return _rack_row0_tilt_deg + _tune_row0_tilt_offset_deg


func _rack_row1_tilt_tuned() -> float:
	return _rack_row1_tilt_deg + _tune_row1_tilt_offset_deg


func _dump_tile_tuning_state() -> void:
	print("[TILE-TUNE] source=", _tile_tune_loaded_path if _tile_tune_loaded_path != "" else "defaults")
	print("[TILE-TUNE] row0_offset=", _tune_row0_offset, " row1_offset=", _tune_row1_offset)
	print("[TILE-TUNE] row0_tilt_offset=", _tune_row0_tilt_offset_deg, " row1_tilt_offset=", _tune_row1_tilt_offset_deg)
	print("[TILE-TUNE] row0_lift=", _tune_row0_lift, " row1_lift=", _tune_row1_lift)
	print("[TILE-TUNE] base_scale=", _tune_base_scale, " selected_scale=", _tune_selected_scale, " required_scale=", _tune_required_scale)
	print("[TILE-TUNE] colors table=", _tune_table_wood_color, " felt=", _tune_felt_color, " rack=", _tune_rack_color, " opp=", _tune_opponent_rack_color)
	print("[TILE-TUNE] tile face=", _tune_tile_face_color, " back=", _tune_tile_back_color, " face_rough=", _tune_tile_face_roughness, " face_spec=", _tune_tile_face_specular)
	print("[TILE-TUNE] textures table=", _tune_table_wood_albedo_path, " rack=", _tune_rack_wood_albedo_path, " felt=", _tune_felt_albedo_path)
	print("[TILE-TUNE] number value_mul=", _tune_number_value_mul, " sat_mul=", _tune_number_saturation_mul, " rough=", _tune_number_roughness, " spec=", _tune_number_specular, " unshaded=", _tune_number_unshaded, " mesh_scale=", _tune_number_mesh_scale, " embedded_mats=", _tune_use_embedded_number_materials, " raw_library_tiles=", _tune_raw_library_tiles)
	print("[TILE-TUNE] safe_raw_clamp=", _tune_safe_raw_material_clamp, " body(rough_min/spec_max)=", _tune_raw_body_roughness_min, "/", _tune_raw_body_specular_max, " numeric(rough_min/spec_max)=", _tune_raw_numeric_roughness_min, "/", _tune_raw_numeric_specular_max)
	print("[TILE-TUNE] finish enabled=", _tune_tile_finish_filter_enabled, " strength=", _tune_tile_finish_filter_strength, " warm_tint=", _tune_tile_finish_warm_tint)
	print("[TILE-TUNE] finish rough_boost/spec_scale=", _tune_tile_finish_roughness_boost, "/", _tune_tile_finish_specular_scale, " num_sat/num_val=", _tune_tile_finish_numeric_saturation_mul, "/", _tune_tile_finish_numeric_value_mul, " strip_aux_maps=", _tune_tile_finish_strip_aux_maps)
	print("[TILE-TUNE] authoritative_surface=", _tune_tile_authoritative_surface, " keep_tex=", _tune_tile_authoritative_keep_albedo_texture, " body(rough/spec/value)=", _tune_tile_authoritative_body_roughness, "/", _tune_tile_authoritative_body_specular, "/", _tune_tile_authoritative_body_value_mul, " numeric(rough/spec)=", _tune_tile_authoritative_numeric_roughness, "/", _tune_tile_authoritative_numeric_specular)
	print("[TILE-TUNE] safe_raw_last_surface_count=", _safe_raw_material_surface_count)
	print("[TILE-TUNE] panel enabled=", _tune_readability_panel_enabled, " alpha_standing=", _tune_readability_panel_alpha_standing, " alpha_flat=", _tune_readability_panel_alpha_flat, " panel_color=", _tune_readability_panel_color)
	print("[TILE-TUNE] labels force=", _tune_force_number_labels, " text_a=", _tune_label_text_alpha, " outline_a=", _tune_label_outline_alpha)
	print("[TILE-TUNE] labels standing font=", _tune_label_font_size_standing, " px=", _tune_label_pixel_size_standing, " outline=", _tune_label_outline_size_standing)
	print("[TILE-TUNE] labels flat font=", _tune_label_font_size_flat, " px=", _tune_label_pixel_size_flat, " outline=", _tune_label_outline_size_flat)
	var phase_fp: String = "n/a"
	if _game_table != null and is_instance_valid(_game_table) and _game_table.has_method("get_controller"):
		var controller = _game_table.get_controller()
		if controller != null and controller.state != null:
			var state = controller.state
			phase_fp = "p%d:ph%d:deck%d:disc%d:req%d" % [
				int(state.current_player_index),
				int(state.phase),
				int(state.deck.size()),
				int(state.discard_pile.size()),
				int(state.turn_required_use_tile_id),
			]
	print("[TILE-TUNE] debug face_down_map_size=", _local_rack_face_down_by_id.size(), " phase_fp=", phase_fp)
	print("[TILE-TUNE] debug drag_state tile/slot/stage/meld/owner/active=",
		_drag_candidate_tile_id, "/", _drag_candidate_slot, "/", _drag_candidate_stage_slot, "/", _drag_candidate_meld_index, "/", _drag_candidate_meld_owner, "/", _drag_active)
	if _table_meld_tile_hits.is_empty():
		print("[TILE-TUNE] debug meld_hit_sample=none")
	else:
		var sample: Dictionary = _table_meld_tile_hits[0]
		print("[TILE-TUNE] debug meld_hit_sample owner=", int(sample.get("owner", -1)), " meld_index=", int(sample.get("meld_index", -1)))
	_dump_live_tile_material_state()


func _dump_live_tile_material_state() -> void:
	if _world_rack_tile_containers.is_empty():
		print("[TILE-TUNE] live-tile: no rack containers yet.")
		return
	var container: Node3D = _world_rack_tile_containers[0] as Node3D
	if container == null or not is_instance_valid(container):
		print("[TILE-TUNE] live-tile: local rack container missing.")
		return
	var mesh: MeshInstance3D = _find_first_mesh_recursive(container)
	if mesh == null:
		print("[TILE-TUNE] live-tile: no mesh instances found under local rack.")
		return
	print("[TILE-TUNE] live-tile mesh=", mesh.name, " numeric=", _is_numeric_mesh_name(mesh.name))
	var surface_count: int = mesh.mesh.get_surface_count() if mesh.mesh != null else 0
	for s in range(surface_count):
		var mat: Material = mesh.get_surface_override_material(s)
		if mat == null and mesh.mesh != null:
			mat = mesh.mesh.surface_get_material(s)
		if mat is StandardMaterial3D:
			var sm: StandardMaterial3D = mat as StandardMaterial3D
			print(
				"[TILE-TUNE] live-tile surf=", s,
				" mat_name=", mat.resource_name,
				" numeric_surface=", _is_numeric_surface_material(mat),
				" albedo=", sm.albedo_color,
				" rough=", sm.roughness,
				" spec=", sm.metallic_specular,
				" metallic=", sm.metallic,
				" emission_en=", sm.emission_enabled
			)
		else:
			print("[TILE-TUNE] live-tile surf=", s, " mat=", mat)


func _find_first_mesh_recursive(node: Node) -> MeshInstance3D:
	if node == null:
		return null
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found: MeshInstance3D = _find_first_mesh_recursive(child)
		if found != null:
			return found
	return null


func _build_tileset_templates() -> void:
	var previous_templates: Dictionary = _tile_template_nodes
	_tile_template_nodes = {}
	_safe_raw_material_surface_count = 0
	_append_tileset_templates_from_library()
	if USE_LEGACY_TILESET_FALLBACK:
		for color_idx in _tileset_scene_by_color.keys():
			var ps: PackedScene = _tileset_scene_by_color[color_idx] as PackedScene
			if ps == null:
				continue
			var rootn: Node3D = ps.instantiate() as Node3D
			if rootn == null:
				continue
			for n in range(1, 14):
				var key: String = "%d:%d" % [int(color_idx), n]
				if _tile_template_nodes.has(key):
					continue
				var body_name: String = "blue%d" % n
				var num_name: String = str(n)
				var body_src: MeshInstance3D = rootn.get_node_or_null(body_name) as MeshInstance3D
				var num_src: MeshInstance3D = rootn.get_node_or_null(num_name) as MeshInstance3D
				if body_src == null:
					body_src = rootn.get_node_or_null(body_name + "_001") as MeshInstance3D
				if num_src == null:
					num_src = rootn.get_node_or_null(num_name + "_001") as MeshInstance3D
				if body_src == null or num_src == null:
					continue
				var tpl := Node3D.new()
				tpl.name = "TileTpl_%d_%d" % [int(color_idx), n]
				var body_clone: MeshInstance3D = _clone_mesh_instance(body_src, false)
				var num_clone: MeshInstance3D = _clone_mesh_instance(num_src, false)
				_apply_number_tint_recursive(num_clone, _number_tint_for_color(int(color_idx)))
				_apply_number_mesh_scale_recursive(num_clone)
				tpl.add_child(body_clone)
				tpl.add_child(num_clone)
				_tile_template_nodes[key] = tpl
			rootn.queue_free()

		if not _tile_template_nodes.has("fake") and _tileset_fake_scene != null:
			var fake_root: Node3D = _tileset_fake_scene.instantiate() as Node3D
			if fake_root != null:
				var fake_body: MeshInstance3D = fake_root.get_node_or_null("part_1_1_1") as MeshInstance3D
				if fake_body == null:
					fake_body = fake_root.get_node_or_null("part_1_1_1_001") as MeshInstance3D
				var fake_text: MeshInstance3D = fake_root.get_node_or_null("Text") as MeshInstance3D
				if fake_text == null:
					fake_text = fake_root.get_node_or_null("Text_001") as MeshInstance3D
				if fake_body != null and fake_text != null:
					var fake_tpl := Node3D.new()
					fake_tpl.name = "TileTpl_fake"
					fake_tpl.add_child(_clone_mesh_instance(fake_body, false))
					fake_tpl.add_child(_clone_mesh_instance(fake_text, false))
					_tile_template_nodes["fake"] = fake_tpl
				fake_root.queue_free()

	if _tile_template_nodes.is_empty():
		push_warning("Tile templates build returned zero templates. Keeping previous templates.")
		_tile_template_nodes = previous_templates
		return

	for tpl in previous_templates.values():
		if tpl is Node:
			var n: Node = tpl as Node
			if n != null and is_instance_valid(n):
				n.queue_free()


func _append_tileset_templates_from_library() -> void:
	if _tiles_library_scene == null:
		return
	var rootn: Node3D = _tiles_library_scene.instantiate() as Node3D
	if rootn == null:
		return
	var color_name_by_idx: Dictionary = {
		int(Tile.TileColor.RED): "red",
		int(Tile.TileColor.BLUE): "blue",
		int(Tile.TileColor.BLACK): "black",
		int(Tile.TileColor.YELLOW): "yellow",
	}
	for color_idx in color_name_by_idx.keys():
		var color_name: String = str(color_name_by_idx.get(color_idx, ""))
		if color_name == "":
			continue
		for n in range(1, 14):
			var key: String = "%d:%d" % [int(color_idx), n]
			if _tile_template_nodes.has(key):
				continue
			var tile_name: String = "%s_%d" % [color_name, n]
			var src_tile: MeshInstance3D = _find_named_mesh_instance(rootn, tile_name)
			if src_tile == null:
				continue
			var preserve_numeric: bool = _tune_use_embedded_number_materials or _tune_raw_library_tiles
			var preserve_all: bool = _tune_use_embedded_number_materials or _tune_raw_library_tiles
			var src_clone: MeshInstance3D = _clone_mesh_hierarchy(src_tile, false, preserve_numeric, preserve_all)
			if src_clone == null:
				continue
			if _tune_raw_library_tiles:
				if _tune_safe_raw_material_clamp:
					_sanitize_raw_tile_materials_recursive(src_clone)
			elif _tune_use_embedded_number_materials:
				_apply_number_mesh_scale_by_name_recursive(src_clone)
			else:
				_apply_library_tile_number_tint(src_clone, int(color_idx))
			var tpl := Node3D.new()
			tpl.name = "TileTpl_%d_%d" % [int(color_idx), n]
			tpl.add_child(src_clone)
			_tile_template_nodes[key] = tpl
	if not _tile_template_nodes.has("fake"):
		var src_fake: MeshInstance3D = _find_named_mesh_instance(rootn, "fake_okey")
		if src_fake != null:
			var preserve_numeric_fake: bool = _tune_use_embedded_number_materials or _tune_raw_library_tiles
			var preserve_all_fake: bool = _tune_use_embedded_number_materials or _tune_raw_library_tiles
			var fake_clone: MeshInstance3D = _clone_mesh_hierarchy(src_fake, false, preserve_numeric_fake, preserve_all_fake)
			if fake_clone != null:
				if _tune_raw_library_tiles:
					if _tune_safe_raw_material_clamp:
						_sanitize_raw_tile_materials_recursive(fake_clone)
				elif _tune_use_embedded_number_materials:
					_apply_number_mesh_scale_by_name_recursive(fake_clone)
				var fake_tpl := Node3D.new()
				fake_tpl.name = "TileTpl_fake"
				fake_tpl.add_child(fake_clone)
				_tile_template_nodes["fake"] = fake_tpl
	rootn.queue_free()


func _sanitize_raw_tile_materials_recursive(node: Node) -> void:
	if node == null:
		return
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var surface_count: int = mi.mesh.get_surface_count() if mi.mesh != null else 0
		var numeric_by_name: bool = _is_numeric_mesh_name(mi.name)
		for s in range(surface_count):
			var base_mat: Material = mi.get_surface_override_material(s)
			if base_mat == null and mi.mesh != null:
				base_mat = mi.mesh.surface_get_material(s)
			if base_mat is StandardMaterial3D:
				var numeric_surface: bool = numeric_by_name or _is_numeric_surface_material(base_mat)
				var tuned: StandardMaterial3D = null
				if _tune_tile_authoritative_surface:
					tuned = _build_authoritative_tile_surface_material(base_mat, numeric_surface)
				else:
					tuned = (base_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				tuned.metallic = 0.0
				tuned.emission_enabled = false
				tuned.emission = Color.BLACK
				if numeric_surface:
					tuned.roughness = maxf(tuned.roughness, _tune_raw_numeric_roughness_min)
					tuned.metallic_specular = minf(tuned.metallic_specular, _tune_raw_numeric_specular_max)
				else:
					tuned.roughness = maxf(tuned.roughness, _tune_raw_body_roughness_min)
					tuned.metallic_specular = minf(tuned.metallic_specular, _tune_raw_body_specular_max)
				_apply_tile_finish_filter(tuned, numeric_surface)
				mi.set_surface_override_material(s, tuned)
				_safe_raw_material_surface_count += 1
	for child in node.get_children():
		_sanitize_raw_tile_materials_recursive(child)


func _build_authoritative_tile_surface_material(base_mat: Material, numeric_surface: bool) -> StandardMaterial3D:
	var tuned := StandardMaterial3D.new()
	tuned.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	tuned.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	tuned.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	tuned.cull_mode = BaseMaterial3D.CULL_BACK
	tuned.vertex_color_use_as_albedo = false
	tuned.metallic = 0.0
	tuned.emission_enabled = false
	tuned.emission = Color.BLACK
	tuned.clearcoat = 0.0
	tuned.clearcoat_roughness = 1.0
	tuned.rim = 0.0
	tuned.rim_tint = 0.0
	tuned.anisotropy = 0.0
	tuned.backlight = Color.BLACK
	tuned.normal_enabled = false
	tuned.normal_texture = null
	tuned.roughness_texture = null
	tuned.metallic_texture = null
	tuned.ao_enabled = false
	tuned.ao_texture = null
	tuned.clearcoat_texture = null
	tuned.emission_texture = null
	if base_mat is BaseMaterial3D:
		var bm: BaseMaterial3D = base_mat as BaseMaterial3D
		var c: Color = bm.albedo_color
		if numeric_surface:
			tuned.albedo_color = c
		else:
			var body_v: float = clampf(c.v * _tune_tile_authoritative_body_value_mul, 0.0, 1.0)
			tuned.albedo_color = Color.from_hsv(c.h, c.s, body_v, c.a)
		if _tune_tile_authoritative_keep_albedo_texture:
			tuned.albedo_texture = bm.albedo_texture
	if tuned.albedo_color == Color(0.0, 0.0, 0.0, 1.0):
		tuned.albedo_color = _tune_tile_face_color if not numeric_surface else Color(0.18, 0.18, 0.18, 1.0)
	tuned.roughness = _tune_tile_authoritative_numeric_roughness if numeric_surface else _tune_tile_authoritative_body_roughness
	tuned.metallic_specular = _tune_tile_authoritative_numeric_specular if numeric_surface else _tune_tile_authoritative_body_specular
	return tuned


func _is_numeric_surface_material(mat: Material) -> bool:
	if mat == null:
		return false
	var rn: String = mat.resource_name.strip_edges().to_lower()
	if rn != "" and (
		rn.contains("num")
		or rn.contains("digit")
		or rn.contains("text")
		or rn.contains("torus")
		or rn.contains("ring")
		or rn.contains("circle")
		or rn.contains("glyph")
	):
		return true
	if mat is BaseMaterial3D:
		var c: Color = (mat as BaseMaterial3D).albedo_color
		var s: float = c.s
		var v: float = c.v
		# Body is bright/low-saturation ivory; numeric/ring is either darker or highly saturated.
		if v <= 0.42:
			return true
		if s >= 0.22 and v <= 0.92:
			return true
	return false


func _apply_tile_finish_filter(mat: StandardMaterial3D, numeric_surface: bool) -> void:
	if mat == null:
		return
	if not _tune_tile_finish_filter_enabled:
		return
	var strength: float = clampf(_tune_tile_finish_filter_strength, 0.0, 1.0)
	if strength <= 0.0001:
		return
	# Keep imported tile shading model intact; only apply subtle finish tuning.
	if _tune_tile_finish_strip_aux_maps:
		mat.normal_enabled = false
		mat.normal_texture = null
		mat.roughness_texture = null
		mat.metallic_texture = null
		mat.ao_enabled = false
		mat.ao_texture = null
	if numeric_surface:
		var nc: Color = mat.albedo_color
		var nh: float = nc.h
		var ns: float = clampf(nc.s * lerpf(1.0, _tune_tile_finish_numeric_saturation_mul, strength), 0.0, 1.0)
		var nv: float = clampf(nc.v * lerpf(1.0, _tune_tile_finish_numeric_value_mul, strength), 0.0, 1.0)
		mat.albedo_color = Color.from_hsv(nh, ns, nv, nc.a)
		mat.roughness = clampf(mat.roughness + (_tune_tile_finish_roughness_boost * 0.30 * strength), 0.0, 1.0)
		mat.metallic_specular = clampf(mat.metallic_specular * lerpf(1.0, _tune_tile_finish_specular_scale * 0.70, strength), 0.0, 1.0)
		return
	var body_c: Color = mat.albedo_color
	mat.albedo_color = body_c.lerp(_tune_tile_finish_warm_tint, strength)
	mat.roughness = clampf(mat.roughness + _tune_tile_finish_roughness_boost * strength, 0.0, 1.0)
	mat.metallic_specular = clampf(mat.metallic_specular * lerpf(1.0, _tune_tile_finish_specular_scale, strength), 0.0, 1.0)


func _find_named_mesh_instance(root: Node, node_name: String) -> MeshInstance3D:
	if root == null:
		return null
	var n: Node = root.find_child(node_name, true, false)
	if n is MeshInstance3D:
		return n as MeshInstance3D
	return null


func _clone_mesh_hierarchy(src: MeshInstance3D, apply_root_face_texture: bool = false, preserve_numeric_materials: bool = false, preserve_all_materials: bool = false) -> MeshInstance3D:
	if src == null:
		return null
	var out: MeshInstance3D = src.duplicate() as MeshInstance3D
	if out == null:
		return null
	if not preserve_all_materials:
		for s in range(out.mesh.get_surface_count() if out.mesh != null else 0):
			var base_mat: Material = src.get_surface_override_material(s)
			if base_mat == null and src.mesh != null:
				base_mat = src.mesh.surface_get_material(s)
			var out_mat: Material = _material_with_tile_face_texture(base_mat) if apply_root_face_texture else _normalized_tile_material(base_mat)
			if out_mat != null:
				out.set_surface_override_material(s, out_mat)
		for child in out.get_children():
			_normalize_tile_materials_recursive(child, preserve_numeric_materials)
	return out


func _apply_library_tile_number_tint(tile_root: MeshInstance3D, color_idx: int) -> void:
	if tile_root == null:
		return
	var tint: Color = _number_tint_for_color(color_idx)
	_apply_number_tint_by_name_recursive(tile_root, tint)


func _apply_number_tint_by_name_recursive(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if _is_numeric_mesh_name(mi.name):
			_apply_number_tint_recursive(mi, tint)
			_apply_number_mesh_scale_recursive(mi)
	for child in node.get_children():
		_apply_number_tint_by_name_recursive(child, tint)


func _apply_number_mesh_scale_by_name_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if _is_numeric_mesh_name(mi.name):
			_apply_number_mesh_scale_recursive(mi)
	for child in node.get_children():
		_apply_number_mesh_scale_by_name_recursive(child)


func _is_numeric_mesh_name(node_name: String) -> bool:
	var n: String = node_name.strip_edges().to_lower()
	if n.is_valid_int():
		return true
	return n.contains("num") \
		or n.contains("digit") \
		or n.contains("glyph") \
		or n.contains("text") \
		or n.contains("torus") \
		or n.contains("ring") \
		or n.contains("circle")


func _number_tint_for_color(color_idx: int) -> Color:
	if _tune_number_tints.has(int(color_idx)):
		return _apply_number_readability(_tune_number_tints[int(color_idx)] as Color)
	match color_idx:
		int(Tile.TileColor.RED):
			return _apply_number_readability(Color(0.78, 0.12, 0.10, 1.0))
		int(Tile.TileColor.BLUE):
			return _apply_number_readability(Color(0.11, 0.37, 0.72, 1.0))
		int(Tile.TileColor.BLACK):
			return _apply_number_readability(Color(0.10, 0.10, 0.13, 1.0))
		int(Tile.TileColor.YELLOW):
			return _apply_number_readability(Color(0.22, 0.14, 0.01, 1.0))
		_:
			return _apply_number_readability(Color(0.20, 0.20, 0.22, 1.0))


func _apply_number_tint_recursive(mi: MeshInstance3D, tint: Color) -> void:
	if mi == null:
		return
	for s in range(mi.mesh.get_surface_count() if mi.mesh != null else 0):
		var base_mat: Material = mi.get_surface_override_material(s)
		if base_mat == null and mi.mesh != null:
			base_mat = mi.mesh.surface_get_material(s)
		var tint_mat: Material = _material_with_number_tint(base_mat, tint)
		if tint_mat != null:
			mi.set_surface_override_material(s, tint_mat)
	for child in mi.get_children():
		if child is MeshInstance3D:
			_apply_number_tint_recursive(child as MeshInstance3D, tint)


func _material_with_number_tint(src_mat: Material, tint: Color) -> Material:
	var mat: StandardMaterial3D = null
	if src_mat is StandardMaterial3D:
		mat = (src_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
	else:
		mat = StandardMaterial3D.new()
		mat.roughness = _tune_number_roughness
		mat.metallic = 0.0
	mat.albedo_color = tint
	mat.roughness = _tune_number_roughness
	mat.metallic_specular = _tune_number_specular
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if _tune_number_unshaded else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.emission_enabled = false
	mat.emission = Color.BLACK
	_apply_tile_finish_filter(mat, true)
	return mat


func _apply_number_mesh_scale_recursive(node: Node) -> void:
	if node == null:
		return
	if node is Node3D and not is_equal_approx(_tune_number_mesh_scale, 1.0):
		var n3d := node as Node3D
		n3d.scale = n3d.scale * _tune_number_mesh_scale
	for child in node.get_children():
		_apply_number_mesh_scale_recursive(child)


func _clone_mesh_instance(src: MeshInstance3D, apply_face_texture: bool = false) -> MeshInstance3D:
	var out := MeshInstance3D.new()
	out.name = src.name
	out.mesh = src.mesh
	out.transform = src.transform
	for s in range(out.mesh.get_surface_count() if out.mesh != null else 0):
		var base_mat: Material = src.get_surface_override_material(s)
		if base_mat == null and src.mesh != null:
			base_mat = src.mesh.surface_get_material(s)
		if apply_face_texture:
			var tex_mat: Material = _material_with_tile_face_texture(base_mat)
			if tex_mat != null:
				out.set_surface_override_material(s, tex_mat)
		else:
			var mat: Material = _normalized_tile_material(base_mat)
			if mat != null:
				out.set_surface_override_material(s, mat)
	for child in out.get_children():
		_normalize_tile_materials_recursive(child, false)
	return out


func _material_with_tile_face_texture(src_mat: Material) -> Material:
	if _tile_face_texture == null:
		return _normalized_tile_material(src_mat)
	var mat: StandardMaterial3D = null
	if src_mat is StandardMaterial3D:
		mat = (src_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
	else:
		mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
		mat.roughness = 0.68
		mat.metallic = 0.0
	mat.albedo_texture = _tile_face_texture
	mat.albedo_color = Color(0.94, 0.94, 0.94, 1.0)
	mat.roughness = maxf(mat.roughness, 0.66)
	mat.metallic = 0.0
	mat.metallic_specular = minf(mat.metallic_specular, 0.24)
	mat.emission_enabled = false
	mat.emission = Color.BLACK
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_apply_tile_finish_filter(mat, false)
	return mat


func _normalized_tile_material(src_mat: Material) -> Material:
	if src_mat is StandardMaterial3D:
		var mat := (src_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
		mat.metallic = 0.0
		mat.metallic_specular = clampf(_tune_tile_face_specular, 0.0, 1.0)
		mat.roughness = clampf(_tune_tile_face_roughness, 0.0, 1.0)
		mat.emission_enabled = false
		mat.emission = Color.BLACK
		var c: Color = mat.albedo_color
		mat.albedo_color = Color(
			c.r * _tune_tile_face_color.r,
			c.g * _tune_tile_face_color.g,
			c.b * _tune_tile_face_color.b,
			c.a
		)
		_apply_tile_finish_filter(mat, _is_numeric_surface_material(src_mat))
		return mat
	return src_mat


func _normalize_tile_materials_recursive(node: Node, preserve_numeric_materials: bool = false) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if not (preserve_numeric_materials and _is_numeric_mesh_name(mi.name)):
			for s in range(mi.mesh.get_surface_count() if mi.mesh != null else 0):
				var base_mat: Material = mi.get_surface_override_material(s)
				if base_mat == null and mi.mesh != null:
					base_mat = mi.mesh.surface_get_material(s)
				var tuned: Material = _normalized_tile_material(base_mat)
				if tuned != null:
					mi.set_surface_override_material(s, tuned)
	for child in node.get_children():
		_normalize_tile_materials_recursive(child, preserve_numeric_materials)


func _create_world_elements() -> void:
	_reset_dynamic_world_state()
	var felt_half: float = FELT_SIDE * 0.5
	var rack_center: float = TABLE_SIDE * 0.5 - RACK_DEPTH * 0.5 - RACK_GAP_TO_FELT
	_create_rack_layout(rack_center)
	_create_deck_and_draw_pick_area()
	_create_discard_layout(felt_half)
	_create_meld_lanes_and_guides(felt_half)
	_create_stage_container()


func _reset_dynamic_world_state() -> void:
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
	_local_meld_guide = null
	_opponent_side_rim_lights.clear()
	_local_rack_tile_hits.clear()
	_stage_tile_hits.clear()
	_table_meld_tile_hits.clear()
	_table_meld_base_centers.clear()
	_table_meld_drag_offsets.clear()
	_last_world_rack_hashes = [-1, -1, -1, -1]
	_last_world_stage_hash = -1
	_last_world_deck_hash = -1
	_last_world_discard_hashes = [-1, -1, -1, -1]
	_last_world_label_hash = -1
	_draw_guide = null


func _create_rack_layout(rack_center: float) -> void:
	var rack_defs: Array[Dictionary] = [
		{"player": 0, "pos": Vector2(0.0, rack_center), "rot_y": 0.0, "name": "P0"},
		{"player": 1, "pos": Vector2(rack_center, 0.0), "rot_y": 90.0, "name": "P1"},
		{"player": 2, "pos": Vector2(0.0, -rack_center), "rot_y": 180.0, "name": "P2"},
		{"player": 3, "pos": Vector2(-rack_center, 0.0), "rot_y": -90.0, "name": "P3"},
	]
	for cfg in rack_defs:
		var player_i: int = int(cfg["player"])
		var rack: Node3D = _create_3d_rack()
		rack.name = "Rack%d" % player_i
		_dynamic_root.add_child(rack)
		rack.position = _table_local_to_world(cfg["pos"] as Vector2, 0.0)
		var rack_rot := Vector3(0.0, cfg["rot_y"] as float, 0.0)
		if player_i == 0:
			# Local-only readability tilt. Opponent racks remain unchanged.
			rack_rot.x = LOCAL_RACK_SELF_VIEW_TILT_DEG
		rack.rotation_degrees = rack_rot
		_world_racks.append(rack)
		var visual := rack.get_node_or_null("Visual") as Node3D
		if player_i == 0 and visual != null and _rack_wood_material != null:
			_apply_material_recursive(visual, _rack_wood_material)
		elif player_i != 0 and _opponent_rack_material != null and visual != null:
			visual.scale = Vector3(1.0, OPPONENT_RACK_HEIGHT_SCALE, OPPONENT_RACK_DEPTH_SCALE)
			_apply_material_recursive(visual, _opponent_rack_material)

		var tile_container := Node3D.new()
		tile_container.name = "TileContainer"
		rack.add_child(tile_container)
		_world_rack_tile_containers.append(tile_container)

		var label := _create_rack_back_label(str(cfg["name"]))
		if player_i == 0:
			label.visible = false
		if visual != null:
			visual.add_child(label)
		else:
			rack.add_child(label)
		_world_rack_labels.append(label)
	_create_opponent_side_rim_lights(rack_center)


func _create_deck_and_draw_pick_area() -> void:
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


func _create_discard_layout(felt_half: float) -> void:
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
		var guide_color: Color = Color(0.92, 0.78, 0.26, 0.64) if p == 0 else Color(0.76, 0.86, 0.96, 0.48)
		var guide := _create_modern_discard_guide(DISCARD_GUIDE_RADIUS, guide_color)
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


func _create_meld_lanes_and_guides(felt_half: float) -> void:
	_table_local_meld_lanes = []
	var lane_h: float = MELD_LANE_DEPTH
	var lane_w: float = MELD_LANE_LENGTH
	var local_w: float = minf(LOCAL_MELD_AREA_WIDTH, FELT_SIDE * 0.42)
	var local_h: float = minf(LOCAL_MELD_AREA_DEPTH, FELT_SIDE * 0.28)
	_table_local_meld_lanes.append(Rect2(
		Vector2(-local_w * 0.5, felt_half - MELD_LANE_INSET_FROM_EDGE - local_h),
		Vector2(local_w, local_h)
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
		# Lane rectangles are used via table-local math; keep these non-colliding so they
		# never steal picks from staged/committed tiles.
		m_pick.collision_layer = 0
		m_pick.collision_mask = 0
		_meld_pick_areas.append(m_pick)

	var local_meld_guide := _create_dotted_meld_area_guide(_table_local_meld_lanes[0].size, Color(0.72, 0.94, 0.92, 0.62))
	local_meld_guide.name = "LocalMeldGuide"
	local_meld_guide.position = _table_local_to_world(_table_local_meld_lanes[0].get_center(), 0.003)
	_local_meld_guide_alpha = MELD_GUIDE_IDLE_ALPHA
	_set_meld_guide_alpha(local_meld_guide, _local_meld_guide_alpha)
	_dynamic_root.add_child(local_meld_guide)
	_meld_guides.append(local_meld_guide)
	_local_meld_guide = local_meld_guide

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


func _create_stage_container() -> void:
	_world_stage_container = Node3D.new()
	_world_stage_container.name = "StageTiles"
	_dynamic_root.add_child(_world_stage_container)


func _create_opponent_side_rim_lights(rack_center: float) -> void:
	if _dynamic_root == null:
		return
	_opponent_side_rim_lights.clear()
	for side in [-1.0, 1.0]:
		var light := OmniLight3D.new()
		light.name = "OpponentSideRim%s" % ("L" if side < 0.0 else "R")
		light.light_color = Color(0.82, 0.73, 0.62, 1.0)
		light.light_energy = 0.56
		light.omni_range = 1.48
		light.position = _table_local_to_world(Vector2(rack_center * side, 0.0), 0.11)
		_dynamic_root.add_child(light)
		_opponent_side_rim_lights.append(light)


func _create_3d_rack() -> Node3D:
	var rack := Node3D.new()
	rack.name = "Rack3D"
	var visual_root := Node3D.new()
	visual_root.name = "Visual"
	rack.add_child(visual_root)

	if _rack_model_scene != null:
		var rack_model := _instantiate_scaled_rack_model(
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
	lbl.pixel_size = 0.00075
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.modulate = Color(0.95, 0.91, 0.80, 0.88)
	lbl.outline_modulate = Color(0.07, 0.04, 0.03, 0.80)
	lbl.outline_size = 3
	lbl.no_depth_test = false
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.position = Vector3(0.0, RACK_MODEL_HEIGHT_AXIS * 0.48, -RACK_MODEL_DEPTH_AXIS * 0.51 - 0.002)
	lbl.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	return lbl


func _create_tile_face_up(tile_data, standing: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "TileFaceUp"
	var body: Node3D = _create_tile_body_node(standing, true, tile_data)
	root.add_child(body)
	if body.get_child_count() > 0 and body.get_child(0).name.begins_with("TileTpl_"):
		if _tune_raw_library_tiles:
			return root
		if _tune_readability_panel_enabled:
			var panel_alpha: float = _tune_readability_panel_alpha_standing if standing else _tune_readability_panel_alpha_flat
			if panel_alpha > 0.0:
				_add_tile_readability_overlay(root, standing, panel_alpha, _tune_readability_panel_color)
		if _tune_force_number_labels and tile_data != null:
			var txt_c: Color = _number_tint_for_color(int(tile_data.color))
			var out_c: Color = Color(0.0, 0.0, 0.0, _tune_label_outline_alpha)
			_attach_tile_number_label(
				root,
				tile_data,
				standing,
				Color(txt_c.r, txt_c.g, txt_c.b, _tune_label_text_alpha),
				out_c
			)
		return root

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
		_attach_tile_number_label(root, tile_data, standing, strip_col, Color(0.0, 0.0, 0.0, 0.35))

	return root


func _create_tile_face_down(standing: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "TileFaceDown"
	var body: Node3D = _create_tile_body_node(standing, false, null)
	root.add_child(body)
	return root


func _attach_tile_number_label(root: Node3D, tile_data, standing: bool, text_color: Color, outline_color: Color) -> void:
	if root == null or tile_data == null:
		return
	var lbl := Label3D.new()
	lbl.text = str(int(tile_data.number))
	if int(tile_data.kind) != 0:
		lbl.text = "*" + lbl.text
	lbl.font_size = _tune_label_font_size_standing if standing else _tune_label_font_size_flat
	lbl.pixel_size = _tune_label_pixel_size_standing if standing else _tune_label_pixel_size_flat
	lbl.modulate = text_color
	lbl.outline_modulate = outline_color
	lbl.outline_size = _tune_label_outline_size_standing if standing else _tune_label_outline_size_flat
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


func _add_tile_readability_overlay(tile_root: Node3D, standing: bool, alpha: float = 0.08, tint: Color = Color(1.0, 1.0, 1.0, 1.0)) -> void:
	if tile_root == null:
		return
	var panel := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(TILE_W * 0.88, TILE_H * 0.84)
	panel.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(tint.r, tint.g, tint.b, clampf(alpha, 0.0, 0.8))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	panel.set_surface_override_material(0, mat)
	if standing:
		panel.position = Vector3(0.0, 0.0, TILE_D * 0.50 + 0.0010)
	else:
		panel.position = Vector3(0.0, TILE_D * 0.50 + 0.0038, 0.0)
		panel.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	tile_root.add_child(panel)


func _add_tile_hue_overlay(tile_root: Node3D, standing: bool, color: Color = Color(0.98, 0.88, 0.36, 0.30)) -> void:
	if tile_root == null:
		return
	var glow := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(TILE_W * 0.92, TILE_H * 0.90)
	glow.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glow.set_surface_override_material(0, mat)
	if standing:
		glow.position = Vector3(0.0, 0.0, TILE_D * 0.55 + 0.0013)
	else:
		glow.position = Vector3(0.0, TILE_D * 0.55 + 0.0012, 0.0)
		glow.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	tile_root.add_child(glow)


func _create_tile_body_node(standing: bool, face_up: bool, tile_data) -> Node3D:
	var target: Vector3 = Vector3(TILE_W, TILE_H, TILE_D) if standing else Vector3(TILE_W, TILE_D, TILE_H)
	var pre_rot: Vector3 = Vector3(90.0, 0.0, 0.0) if standing else Vector3.ZERO
	if face_up:
		var tpl: Node3D = _instantiate_tileset_tile(tile_data, target, pre_rot)
		if tpl != null:
			return tpl
	else:
		var tpl_back: Node3D = _instantiate_tileset_back_tile(target, pre_rot)
		if tpl_back != null:
			return tpl_back
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
	return _finalize_scaled_node(raw, target_size, override_material, pre_rotation_deg, floor_align)


func _instantiate_scaled_rack_model(scene: PackedScene, target_size: Vector3, override_material: Material, pre_rotation_deg: Vector3 = Vector3.ZERO, floor_align: bool = false) -> Node3D:
	if scene == null:
		return null
	var raw := scene.instantiate() as Node3D
	if raw == null:
		return null
	raw.rotation_degrees = pre_rotation_deg
	var helper_samples: Dictionary = _capture_rack_helper_tile_samples(raw)
	_strip_rack_helper_nodes(raw)

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
	var row_tilt_hints: Dictionary = _capture_rack_row_tilt_hints(holder)

	if override_material != null:
		_apply_material_recursive(raw, override_material)

	_try_apply_helper_samples_to_rack_rows(helper_samples, row_tilt_hints, raw.position, holder.scale)
	return holder


func _capture_rack_helper_tile_samples(root: Node3D) -> Dictionary:
	var samples: Dictionary = {}
	if root == null:
		return samples
	var nodes: Array = root.find_children("*", "Node3D", true, false)
	for node in nodes:
		var n3: Node3D = node as Node3D
		if n3 == null:
			continue
		var name_l: String = n3.name.to_lower()
		if name_l.find("tile_top") != -1 or name_l.find("top_tile") != -1:
			samples["top"] = {
				"position": n3.position,
				"rotation": n3.rotation_degrees,
			}
		elif name_l.find("tile_bottom") != -1 or name_l.find("bottom_tile") != -1:
			samples["bottom"] = {
				"position": n3.position,
				"rotation": n3.rotation_degrees,
			}
	return samples


func _try_apply_helper_samples_to_rack_rows(samples: Dictionary, row_tilt_hints: Dictionary, raw_offset: Vector3, holder_scale: Vector3) -> void:
	if not samples.has("top") or not samples.has("bottom"):
		return
	var top_s: Dictionary = samples["top"] as Dictionary
	var bottom_s: Dictionary = samples["bottom"] as Dictionary
	var top_pos: Vector3 = _vector_mul_components((top_s.get("position", Vector3.ZERO) as Vector3) + raw_offset, holder_scale)
	var bottom_pos: Vector3 = _vector_mul_components((bottom_s.get("position", Vector3.ZERO) as Vector3) + raw_offset, holder_scale)
	var top_rot: Vector3 = top_s.get("rotation", Vector3.ZERO) as Vector3
	var bottom_rot: Vector3 = bottom_s.get("rotation", Vector3.ZERO) as Vector3

	# Row0 must be the physically higher row.
	if top_pos.y < bottom_pos.y:
		var p_tmp: Vector3 = top_pos
		top_pos = bottom_pos
		bottom_pos = p_tmp
		var r_tmp: Vector3 = top_rot
		top_rot = bottom_rot
		bottom_rot = r_tmp

	var top_tilt: float = clampf(top_rot.x - 90.0, RACK_ROW_TILT_MIN_DEG, RACK_ROW_TILT_MAX_DEG)
	var bottom_tilt: float = clampf(bottom_rot.x - 90.0, RACK_ROW_TILT_MIN_DEG, RACK_ROW_TILT_MAX_DEG)

	# Helper tiles are exact placement references. Trust their tilt first and only
	# fall back to sampled row-surface hints when helper rotation is effectively absent.
	var top_rot_missing: bool = absf(top_rot.x) < 0.01 and absf(top_rot.y) < 0.01 and absf(top_rot.z) < 0.01
	var bottom_rot_missing: bool = absf(bottom_rot.x) < 0.01 and absf(bottom_rot.y) < 0.01 and absf(bottom_rot.z) < 0.01
	if top_rot_missing and row_tilt_hints.has("top"):
		top_tilt = clampf(float(row_tilt_hints.get("top", top_tilt)), RACK_ROW_TILT_MIN_DEG, RACK_ROW_TILT_MAX_DEG)
	if bottom_rot_missing and row_tilt_hints.has("bottom"):
		bottom_tilt = clampf(float(row_tilt_hints.get("bottom", bottom_tilt)), RACK_ROW_TILT_MIN_DEG, RACK_ROW_TILT_MAX_DEG)

	_rack_row0_anchor = Vector3(
		0.0,
		clampf(top_pos.y, 0.012, RACK_MODEL_HEIGHT_AXIS - 0.005),
		clampf(top_pos.z, -RACK_MODEL_DEPTH_AXIS * 0.5 + 0.003, RACK_MODEL_DEPTH_AXIS * 0.5 - 0.003)
	)
	_rack_row1_anchor = Vector3(
		0.0,
		clampf(bottom_pos.y, 0.010, RACK_MODEL_HEIGHT_AXIS - 0.005),
		clampf(bottom_pos.z, -RACK_MODEL_DEPTH_AXIS * 0.5 + 0.003, RACK_MODEL_DEPTH_AXIS * 0.5 - 0.003)
	)
	_rack_row0_tilt_deg = top_tilt
	_rack_row1_tilt_deg = bottom_tilt
	_rack_row0_normal = _row_normal_from_tilt(_rack_row0_tilt_deg)
	_rack_row1_normal = _row_normal_from_tilt(_rack_row1_tilt_deg)
	_rack_row_anchors_calibrated = true
	_rack_helper_rows_active = true


func _vector_mul_components(a: Vector3, b: Vector3) -> Vector3:
	return Vector3(a.x * b.x, a.y * b.y, a.z * b.z)


func _capture_rack_row_tilt_hints(root: Node3D) -> Dictionary:
	var hints: Dictionary = {}
	if root == null:
		return hints
	var stats: Array[Dictionary] = []
	_collect_surface_stats(root, Transform3D.IDENTITY, stats)
	if stats.is_empty():
		return hints

	var best_top_area: float = -1.0
	var best_bottom_area: float = -1.0
	for st in stats:
		var hint: String = String(st.get("hint", "")).to_lower()
		var n: Vector3 = (st.get("normal", Vector3.ZERO) as Vector3).normalized()
		if n.length() < 0.0001 or n.y <= 0.05:
			continue
		var area: float = float(st.get("area", 0.0))
		if _string_has_any_token(hint, ["toprow", "top_row", "row0", "upper", "upper_row"]):
			if area > best_top_area:
				best_top_area = area
				hints["top"] = _row_tilt_from_normal(n)
		elif _string_has_any_token(hint, ["bottomrow", "bottom_row", "row1", "lower", "lower_row"]):
			if area > best_bottom_area:
				best_bottom_area = area
				hints["bottom"] = _row_tilt_from_normal(n)
	return hints


func _strip_rack_helper_nodes(root: Node) -> void:
	if root == null:
		return
	for child in root.get_children():
		if _is_rack_helper_node_name(child.name):
			root.remove_child(child)
			child.queue_free()
			continue
		_strip_rack_helper_nodes(child)


func _is_rack_helper_node_name(node_name: String) -> bool:
	var n: String = node_name.strip_edges().to_lower()
	if n == "":
		return false
	if n.begins_with("tile") or n.find("_tile") != -1 or n.find("tile_") != -1:
		return true
	if n.find("helper") != -1 or n.find("marker") != -1 or n.find("reference") != -1 or n.find("sample") != -1:
		return true
	return false


func _instantiate_tileset_tile(tile_data, target_size: Vector3, pre_rotation_deg: Vector3) -> Node3D:
	if tile_data == null:
		return null
	var key: String = ""
	var kind: int = int(tile_data.kind)
	if kind != 0 and _tile_template_nodes.has("fake"):
		key = "fake"
	else:
		key = "%d:%d" % [int(tile_data.color), int(tile_data.number)]
	if key == "" or not _tile_template_nodes.has(key):
		return null
	var source: Node3D = _tile_template_nodes[key] as Node3D
	if source == null:
		return null
	var raw := source.duplicate() as Node3D
	if raw == null:
		return null
	raw.name = source.name
	return _finalize_scaled_node(raw, target_size, null, pre_rotation_deg, false)


func _instantiate_tileset_back_tile(target_size: Vector3, pre_rotation_deg: Vector3) -> Node3D:
	var source: Node3D = null
	if _tile_template_nodes.has("1:1"):
		source = _tile_template_nodes["1:1"] as Node3D
	elif _tile_template_nodes.has("0:1"):
		source = _tile_template_nodes["0:1"] as Node3D
	elif _tile_template_nodes.has("2:1"):
		source = _tile_template_nodes["2:1"] as Node3D
	elif _tile_template_nodes.has("3:1"):
		source = _tile_template_nodes["3:1"] as Node3D
	if source == null:
		return null
	var raw := source.duplicate() as Node3D
	if raw == null:
		return null
	if _tune_raw_library_tiles:
		_strip_numeric_children_recursive(raw)
	if _tile_back_material != null:
		_apply_material_recursive(raw, _tile_back_material)
	raw.name = "TileTpl_back"
	return _finalize_scaled_node(raw, target_size, null, pre_rotation_deg, false)


func _strip_numeric_children_recursive(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		if _is_numeric_mesh_name(child.name):
			node.remove_child(child)
			child.free()
			continue
		_strip_numeric_children_recursive(child)


func _finalize_scaled_node(raw: Node3D, target_size: Vector3, override_material: Material, pre_rotation_deg: Vector3, floor_align: bool) -> Node3D:
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

	var best_top_named: Dictionary = {}
	var best_bottom_named: Dictionary = {}
	var best_top_named_area: float = -1.0
	var best_bottom_named_area: float = -1.0
	var row_candidates: Array[Dictionary] = []
	for st in stats:
		var n_named: Vector3 = (st.get("normal", Vector3.ZERO) as Vector3).normalized()
		var c_named: Vector3 = st.get("center", Vector3.ZERO)
		if n_named.length() < 0.0001 or n_named.z < 0.35 or n_named.y < 0.05 or c_named.y < 0.010:
			continue
		row_candidates.append(st)
		var hint: String = String(st.get("hint", "")).to_lower()
		var area: float = float(st.get("area", 0.0))
		if _string_has_any_token(hint, ["toprow", "top_row", "row0", "upper", "upper_row"]):
			if area > best_top_named_area:
				best_top_named_area = area
				best_top_named = st
		if _string_has_any_token(hint, ["bottomrow", "bottom_row", "row1", "lower", "lower_row"]):
			if area > best_bottom_named_area:
				best_bottom_named_area = area
				best_bottom_named = st

	var blue_ref := Color(0.3492, 0.3414, 0.9063, 1.0)
	var yellow_ref := Color(0.9063, 0.9051, 0.2432, 1.0)
	var best_blue: Dictionary = {}
	var best_yellow: Dictionary = {}
	var best_blue_d: float = 1000.0
	var best_yellow_d: float = 1000.0
	var used_named_or_geometry: bool = false

	if not best_top_named.is_empty() and not best_bottom_named.is_empty():
		best_blue = best_top_named
		best_yellow = best_bottom_named
		used_named_or_geometry = true
	elif row_candidates.size() >= 2:
		var sorted_rows: Array[Dictionary] = row_candidates.duplicate()
		sorted_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var ay: float = (a.get("center", Vector3.ZERO) as Vector3).y
			var by: float = (b.get("center", Vector3.ZERO) as Vector3).y
			if absf(ay - by) > 0.0001:
				return ay > by
			return float(a.get("area", 0.0)) > float(b.get("area", 0.0))
		)
		best_blue = sorted_rows[0]
		var top_y: float = (best_blue.get("center", Vector3.ZERO) as Vector3).y
		for i in range(1, sorted_rows.size()):
			var candidate: Dictionary = sorted_rows[i]
			var cy: float = (candidate.get("center", Vector3.ZERO) as Vector3).y
			if top_y - cy > 0.003:
				best_yellow = candidate
				break
		if best_yellow.is_empty():
			best_yellow = sorted_rows[1]
		used_named_or_geometry = true

	if not used_named_or_geometry:
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
	var blue_n: Vector3 = (best_blue.get("normal", _rack_row0_normal) as Vector3).normalized()
	var yellow_n: Vector3 = (best_yellow.get("normal", _rack_row1_normal) as Vector3).normalized()
	if blue_n.length() < 0.0001:
		blue_n = _rack_row0_normal
	if yellow_n.length() < 0.0001:
		yellow_n = _rack_row1_normal
	if blue_n.z < 0.0:
		blue_n = -blue_n
	if yellow_n.z < 0.0:
		yellow_n = -yellow_n

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
		var n_tmp: Vector3 = blue_n
		blue_n = yellow_n
		yellow_n = n_tmp

	_rack_row0_normal = blue_n
	_rack_row1_normal = yellow_n
	_rack_row0_tilt_deg = clampf(_row_tilt_from_normal(_rack_row0_normal), RACK_ROW_TILT_MIN_DEG, RACK_ROW_TILT_MAX_DEG)
	_rack_row1_tilt_deg = clampf(_row_tilt_from_normal(_rack_row1_normal), RACK_ROW_TILT_MIN_DEG, RACK_ROW_TILT_MAX_DEG)

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
					# Normals must be transformed with inverse-transpose under non-uniform scale.
					var normal_basis: Basis = xform.basis
					if absf(normal_basis.determinant()) > 1e-12:
						normal_basis = normal_basis.inverse().transposed()
					else:
						normal_basis = normal_basis.orthonormalized()
					for n in normals as PackedVector3Array:
						normal += (normal_basis * n).normalized()
				if normal.length() > 0.0001:
					normal = normal.normalized()

				var mat_name: String = _get_surface_material_name(mi, s).to_lower()
				var mesh_name: String = mi.mesh.resource_name.to_lower() if mi.mesh != null else ""
				var hint: String = ("%s %s %s" % [n3d.name.to_lower(), mesh_name, mat_name]).strip_edges()
				out_stats.append({
					"color": _get_surface_color(mi, s),
					"center": center,
					"normal": normal,
					"area": _surface_area_world(arrays, xform),
					"hint": hint,
				})
	for child in n3d.get_children():
		_collect_surface_stats(child, xform, out_stats)


func _get_surface_material(mi: MeshInstance3D, surface_idx: int) -> Material:
	var mat: Material = mi.get_surface_override_material(surface_idx)
	if mat == null and mi.mesh != null:
		mat = mi.mesh.surface_get_material(surface_idx)
	return mat


func _get_surface_color(mi: MeshInstance3D, surface_idx: int) -> Color:
	var mat: Material = _get_surface_material(mi, surface_idx)
	if mat is BaseMaterial3D:
		return (mat as BaseMaterial3D).albedo_color
	return Color(0.5, 0.5, 0.5, 1.0)


func _get_surface_material_name(mi: MeshInstance3D, surface_idx: int) -> String:
	var mat: Material = _get_surface_material(mi, surface_idx)
	if mat == null:
		return ""
	return mat.resource_name


func _surface_area_world(arrays: Array, xform: Transform3D) -> float:
	var verts_var = arrays[Mesh.ARRAY_VERTEX]
	if verts_var is not PackedVector3Array:
		return 0.0
	var verts: PackedVector3Array = verts_var as PackedVector3Array
	var area: float = 0.0
	var idx_var = arrays[Mesh.ARRAY_INDEX]
	if idx_var is PackedInt32Array:
		var indices: PackedInt32Array = idx_var as PackedInt32Array
		var tri_count: int = indices.size() / 3
		for ti in range(tri_count):
			var i0: int = int(indices[ti * 3 + 0])
			var i1: int = int(indices[ti * 3 + 1])
			var i2: int = int(indices[ti * 3 + 2])
			if i0 < 0 or i1 < 0 or i2 < 0 or i0 >= verts.size() or i1 >= verts.size() or i2 >= verts.size():
				continue
			var a: Vector3 = xform * verts[i0]
			var b: Vector3 = xform * verts[i1]
			var c: Vector3 = xform * verts[i2]
			area += ((b - a).cross(c - a)).length() * 0.5
	else:
		var tri_count_no_idx: int = verts.size() / 3
		for ti in range(tri_count_no_idx):
			var a_no_idx: Vector3 = xform * verts[ti * 3 + 0]
			var b_no_idx: Vector3 = xform * verts[ti * 3 + 1]
			var c_no_idx: Vector3 = xform * verts[ti * 3 + 2]
			area += ((b_no_idx - a_no_idx).cross(c_no_idx - a_no_idx)).length() * 0.5
	return area


func _string_has_any_token(text: String, tokens: Array[String]) -> bool:
	var haystack: String = text.to_lower()
	for token in tokens:
		if haystack.find(token.to_lower()) != -1:
			return true
	return false


func _color_distance(a: Color, b: Color) -> float:
	var dr: float = a.r - b.r
	var dg: float = a.g - b.g
	var db: float = a.b - b.b
	return sqrt(dr * dr + dg * dg + db * db)


func _row_tilt_from_normal(n: Vector3) -> float:
	var nz: float = n.z
	var ny: float = n.y
	if absf(nz) < 0.0001 and absf(ny) < 0.0001:
		return RACK_ROW_TOP_TILT_DEG
	return -rad_to_deg(atan2(ny, nz))


func _row_normal_from_tilt(tilt_deg: float) -> Vector3:
	var rad: float = deg_to_rad(-tilt_deg)
	return Vector3(0.0, sin(rad), cos(rad)).normalized()


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
	var face_down_pruned: bool = false
	for key in _local_rack_face_down_by_id.keys():
		var tid: int = int(key)
		if not by_id.has(tid):
			_local_rack_face_down_by_id.erase(key)
			face_down_pruned = true
	if face_down_pruned:
		_last_world_rack_hashes[0] = -1
	if _last_selected_tile_id != -1 and not by_id.has(_last_selected_tile_id):
		_last_selected_tile_id = -1
	if _required_tile_hue_id != -1 and not by_id.has(_required_tile_hue_id):
		_required_tile_hue_id = -1
		_last_world_rack_hashes[0] = -1

	# Local player rack (face-up)
	if _world_rack_tile_containers.size() > 0:
		var face_down_hash: int = 0
		var face_down_keys: Array = _local_rack_face_down_by_id.keys()
		face_down_keys.sort()
		for key in face_down_keys:
			if bool(_local_rack_face_down_by_id.get(key, false)):
				face_down_hash = int((face_down_hash * 131 + int(key) + 1) % 2147483647)
		var drag_hidden_tid: int = _drag_candidate_tile_id if _drag_active else -1
		var local_hash: int = _compute_slots_hash(rack_slots) * 31 + (_last_selected_tile_id + 1) + face_down_hash * 17 + (_required_tile_hue_id + 1) * 19 + (drag_hidden_tid + 1) * 23
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
	var hidden_drag_tid: int = _drag_candidate_tile_id if _drag_active else -1

	var row0_slots: int = mini(15, rack_slots.size())
	var row1_slots: int = maxi(0, mini(30, rack_slots.size()) - 15)
	var usable_len: float = RACK_LEN - 0.060
	var spacing0: float = usable_len / 15.0
	var start0: float = -usable_len * 0.5 + spacing0 * 0.5
	var row0_anchor: Vector3 = _rack_row0_anchor_tuned()
	var row1_anchor: Vector3 = _rack_row1_anchor_tuned()
	var row0_tilt: float = _rack_row0_tilt_tuned()
	var row1_tilt: float = _rack_row1_tilt_tuned()
	var row0_seat_offset: Vector3 = Vector3.ZERO if _rack_helper_rows_active else _rack_row0_normal * (TILE_D * 0.5 + _tune_row0_lift)
	var row1_seat_offset: Vector3 = Vector3.ZERO if _rack_helper_rows_active else _rack_row1_normal * (TILE_D * 0.5 + _tune_row1_lift)

	for i in range(15):
		var x_anchor: float = start0 + float(i) * spacing0
		var seat_anchor: Vector3 = Vector3(x_anchor, row0_anchor.y, row0_anchor.z) + row0_seat_offset
		var world_anchor := container.to_global(seat_anchor)
		_local_rack_slot_hits.append({"slot": i, "world": world_anchor})
		_create_pick_box(
			container,
			"SlotPickTop%d" % i,
			RACK_SLOT_PICK_SIZE,
			seat_anchor,
			Vector3.ZERO,
			{"kind": "local_slot", "slot": i}
		)

	for i in range(row0_slots):
		var tid: int = int(rack_slots[i])
		if tid == -1 or not by_id.has(tid) or tid == hidden_drag_tid:
			continue
		var face_down: bool = bool(_local_rack_face_down_by_id.get(tid, false))
		var tile := _create_tile_face_down(true) if face_down else _create_tile_face_up(by_id[tid], true)
		tile.name = "TileFaceUpTop%d" % i
		var is_required_hue: bool = tid == _required_tile_hue_id
		var x: float = start0 + float(i) * spacing0
		tile.position = Vector3(x, row0_anchor.y, row0_anchor.z) + row0_seat_offset
		tile.rotation_degrees.x = row0_tilt
		tile.scale = Vector3(_tune_base_scale, _tune_base_scale, _tune_base_scale)
		if tid == _last_selected_tile_id:
			tile.position.y += 0.004
			tile.scale = Vector3(_tune_selected_scale, _tune_selected_scale, _tune_selected_scale)
		elif is_required_hue:
			tile.position.y += 0.0016
			tile.scale = Vector3(_tune_required_scale, _tune_required_scale, _tune_required_scale)
		if is_required_hue:
			_add_tile_hue_overlay(tile, true)
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
		var seat_anchor: Vector3 = Vector3(x_anchor, row1_anchor.y, row1_anchor.z) + row1_seat_offset
		var world_anchor := container.to_global(seat_anchor)
		_local_rack_slot_hits.append({"slot": i + 15, "world": world_anchor})
		_create_pick_box(
			container,
			"SlotPickBottom%d" % i,
			RACK_SLOT_PICK_SIZE,
			seat_anchor,
			Vector3.ZERO,
			{"kind": "local_slot", "slot": i + 15}
		)
	for i in range(row1_slots):
		var idx: int = i + 15
		var tid: int = int(rack_slots[idx])
		if tid == -1 or not by_id.has(tid) or tid == hidden_drag_tid:
			continue
		var face_down: bool = bool(_local_rack_face_down_by_id.get(tid, false))
		var tile := _create_tile_face_down(true) if face_down else _create_tile_face_up(by_id[tid], true)
		tile.name = "TileFaceUpBottom%d" % i
		var is_required_hue: bool = tid == _required_tile_hue_id
		var x: float = start1 + float(i) * spacing1
		tile.position = Vector3(x, row1_anchor.y, row1_anchor.z) + row1_seat_offset
		tile.rotation_degrees.x = row1_tilt
		tile.scale = Vector3(_tune_base_scale, _tune_base_scale, _tune_base_scale)
		if tid == _last_selected_tile_id:
			tile.position.y += 0.004
			tile.scale = Vector3(_tune_selected_scale, _tune_selected_scale, _tune_selected_scale)
		elif is_required_hue:
			tile.position.y += 0.0016
			tile.scale = Vector3(_tune_required_scale, _tune_required_scale, _tune_required_scale)
		if is_required_hue:
			_add_tile_hue_overlay(tile, true)
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
	var state = controller.state
	var stage_slots: Array = _game_table.get_stage_slots() if _game_table.has_method("get_stage_slots") else []
	var stage_hash: int = _compute_slots_hash(stage_slots)
	var meld_hash: int = _compute_table_melds_hash(state.table_melds)
	var drag_hidden_tid: int = _drag_candidate_tile_id if _drag_active else -1
	var sync_hash: int = int((stage_hash * 65537 + meld_hash + (drag_hidden_tid + 1) * 97) % 2147483647)
	if sync_hash == _last_world_stage_hash:
		return
	_last_world_stage_hash = sync_hash

	_stage_tile_hits.clear()
	_table_meld_tile_hits.clear()
	for child in _world_stage_container.get_children():
		child.queue_free()

	if _table_local_meld_lanes.is_empty():
		return

	_render_committed_table_melds(state.table_melds, false)

	if stage_slots.is_empty():
		return

	var hand: Array = _game_table.get_hand_tiles() if _game_table.has_method("get_hand_tiles") else []
	var by_id: Dictionary = {}
	for t in hand:
		by_id[int(t.unique_id)] = t

	var lane: Rect2 = _table_local_meld_lanes[0]
	var total_slots: int = stage_slots.size()
	if total_slots <= 0:
		return
	var cols: int = _stage_grid_cols(total_slots)
	var rows: int = maxi(1, int(ceil(float(total_slots) / float(cols))))
	var cell_w: float = lane.size.x / float(cols)
	var cell_h: float = lane.size.y / float(rows)

	for i in range(total_slots):
		var tid: int = int(stage_slots[i])
		if tid == -1 or not by_id.has(tid) or (_drag_active and tid == _drag_candidate_tile_id):
			continue
		var row: int = int(floor(float(i) / float(maxi(cols, 1))))
		var col: int = i % cols
		var x: float = lane.position.x + cell_w * (float(col) + 0.5)
		var z: float = lane.position.y + cell_h * (float(row) + 0.5)
		var tile := _create_tile_face_up(by_id[tid], false)
		tile.position = _table_local_to_world(Vector2(x, z), TILE_D * 0.5 + 0.0007)
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
			"world": tile.global_position + Vector3(0.0, TILE_D * 0.65, 0.0)
		})


func _compute_table_melds_hash(table_melds: Array) -> int:
	var h: int = 19
	for meld in table_melds:
		if meld == null:
			continue
		h = int((h * 131 + int(meld.owner_index) + 1) % 2147483647)
		h = int((h * 131 + int(meld.kind) + 1) % 2147483647)
		for tid in meld.tiles:
			h = int((h * 131 + int(tid) + 1) % 2147483647)
	return h


func _render_committed_table_melds(table_melds: Array, hide_local_owner: bool) -> void:
	if table_melds.is_empty() or _table_local_meld_lanes.is_empty():
		_table_meld_base_centers.clear()
		_table_meld_drag_offsets.clear()
		return
	_table_meld_base_centers.clear()
	var seen_melds: Dictionary = {}
	var lane_rot_y: Array[float] = [0.0, 90.0, 180.0, -90.0]
	var tile_pitch_major: float = TILE_W + 0.004
	var meld_gap_major: float = 0.014
	var row_step_minor: float = TILE_H + 0.010
	for owner_idx in range(mini(4, _table_local_meld_lanes.size())):
		if hide_local_owner and owner_idx == 0:
			continue
		var lane: Rect2 = _table_local_meld_lanes[owner_idx]
		var horizontal_lane: bool = lane.size.x >= lane.size.y
		var major_start: float = (lane.position.x if horizontal_lane else lane.position.y) + 0.010
		var major_end: float = (lane.position.x + lane.size.x if horizontal_lane else lane.position.y + lane.size.y) - 0.010
		var minor_start: float = (lane.position.y if horizontal_lane else lane.position.x) + 0.006
		var minor_end: float = (lane.position.y + lane.size.y if horizontal_lane else lane.position.x + lane.size.x) - (TILE_H + 0.004)
		var cursor_major: float = major_start
		var cursor_minor: float = minor_start
		for meld_idx in range(table_melds.size()):
			var meld = table_melds[meld_idx]
			if meld == null or int(meld.owner_index) != owner_idx:
				continue
			seen_melds[meld_idx] = true
			var meld_tiles: Array = meld.tiles_data
			if meld_tiles.is_empty():
				continue
			var meld_span: float = float(meld_tiles.size()) * tile_pitch_major - 0.004
			if cursor_major + meld_span > major_end and cursor_major > major_start + 0.0001:
				cursor_major = major_start
				cursor_minor += row_step_minor
			if cursor_minor > minor_end:
				break
			var base_center: Vector2 = Vector2(
				(cursor_major + meld_span * 0.5) if horizontal_lane else (cursor_minor + TILE_H * 0.5),
				(cursor_minor + TILE_H * 0.5) if horizontal_lane else (cursor_major + meld_span * 0.5)
			)
			_table_meld_base_centers[meld_idx] = base_center
			var meld_offset: Vector2 = _table_meld_drag_offsets.get(meld_idx, Vector2.ZERO) as Vector2
			for i in range(meld_tiles.size()):
				var tile_data = meld_tiles[i]
				var major_center: float = cursor_major + TILE_W * 0.5 + float(i) * tile_pitch_major
				var minor_center: float = cursor_minor + TILE_H * 0.5
				var x: float = major_center if horizontal_lane else minor_center
				var z: float = minor_center if horizontal_lane else major_center
				var tile := _create_tile_face_up(tile_data, false)
				tile.position = _table_local_to_world(Vector2(x, z) + meld_offset, TILE_D * 0.5 + 0.0008)
				tile.rotation_degrees.y = lane_rot_y[owner_idx]
				_create_pick_box(
					tile,
					"MeldTilePick",
					STAGE_TILE_PICK_SIZE,
					Vector3(0.0, 0.0, 0.0),
					Vector3.ZERO,
					{"kind": "table_meld", "meld_index": meld_idx, "owner": owner_idx}
				)
				_world_stage_container.add_child(tile)
				_table_meld_tile_hits.append({
					"meld_index": meld_idx,
					"owner": owner_idx,
					"world": tile.global_position + Vector3(0.0, TILE_D * 0.65, 0.0),
				})
			cursor_major += meld_span + meld_gap_major
	var stale_keys: Array = _table_meld_drag_offsets.keys()
	for key in stale_keys:
		if not seen_melds.has(int(key)):
			_table_meld_drag_offsets.erase(key)

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
	for i in range(vis_count):
		var tile := _create_tile_face_down(false)
		tile.scale = Vector3(DECK_TILE_SCALE, DECK_TILE_SCALE, DECK_TILE_SCALE)
		tile.position = Vector3(
			0.0,
			float(i) * TILE_D * 0.30,
			0.0
		)
		tile.rotation_degrees = Vector3.ZERO
		_deck_pile_container.add_child(tile)

	if state.okey_context != null and state.okey_context.indicator_tile != null:
		_indicator_3d = _create_tile_face_up(state.okey_context.indicator_tile, false)
		_indicator_3d.scale = Vector3(INDICATOR_TILE_SCALE, INDICATOR_TILE_SCALE, INDICATOR_TILE_SCALE)
		_indicator_3d.position = Vector3(TILE_W * INDICATOR_TILE_SCALE + INDICATOR_GAP + 0.003, TILE_D * 0.5 + 0.0010, 0.0)
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
		var rot_pattern: Array[float] = [-5.0, -2.0, 0.0, 2.0, 5.0, -3.5, 3.5]
		for i in range(vis_count):
			var td = stack[start_idx + i]
			var tile := _create_tile_face_up(td, false)
			var spread_col: int = i % rot_pattern.size()
			var spread_row: int = int(floor(float(i) / float(maxi(rot_pattern.size(), 1))))
			var x_off: float = (float(spread_col) - (float(rot_pattern.size()) - 1.0) * 0.5) * 0.0019
			var z_off: float = (float(spread_row) - 1.0) * 0.0016
			tile.position = Vector3(
				x_off,
				float(i) * TILE_D * 0.28,
				z_off
			)
			tile.rotation_degrees.y = base_rot[pi] + rot_pattern[spread_col]
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
		var title: String = "PLAYER %d" % (pi + 1)
		if pi == 0:
			title = "YOU"
		lbl.text = title
		if state.current_player_index == pi:
			lbl.modulate = Color(1.0, 0.92, 0.75, 0.95)
		else:
			lbl.modulate = Color(0.92, 0.86, 0.76, 0.82)


func _update_opponent_rim_lights() -> void:
	if _opponent_side_rim_lights.is_empty():
		return
	var active_player: int = -1
	if _game_table != null and is_instance_valid(_game_table) and _game_table.has_method("get_controller"):
		var controller = _game_table.get_controller()
		if controller != null and controller.state != null:
			active_player = int(controller.state.current_player_index)
	var pulse: float = 0.50 + sin(_runtime_time * 1.42) * 0.05
	for i in range(_opponent_side_rim_lights.size()):
		var light: OmniLight3D = _opponent_side_rim_lights[i]
		if light == null or not is_instance_valid(light):
			continue
		var emphasized: bool = (i == 0 and active_player == 3) or (i == 1 and active_player == 1)
		light.light_energy = pulse + (0.14 if emphasized else 0.0)


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


func _screen_to_table_local_clamped(screen_pos: Vector2) -> Vector2:
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
	return Vector2(
		clampf(hit.x, -felt_half, felt_half),
		clampf(hit.z, -felt_half, felt_half)
	)


func _screen_to_table_local_for_tap(screen_pos: Vector2) -> Vector2:
	var table_pos: Vector2 = _screen_to_table_local(screen_pos)
	if _is_valid_table_local_pos(table_pos):
		return table_pos
	var clamped_pos: Vector2 = _screen_to_table_local_clamped(screen_pos)
	if _is_valid_table_local_pos(clamped_pos):
		return clamped_pos
	return table_pos


func _local_rack_screen_band_rect() -> Rect2:
	if _camera == null or not is_instance_valid(_camera):
		return Rect2()
	if _local_rack_slot_hits.is_empty():
		return Rect2()
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF
	for hit in _local_rack_slot_hits:
		var world_pos: Vector3 = (hit.get("world", Vector3.ZERO) as Vector3)
		var p: Vector2 = _camera.unproject_position(world_pos)
		min_x = minf(min_x, p.x)
		min_y = minf(min_y, p.y)
		max_x = maxf(max_x, p.x)
		max_y = maxf(max_y, p.y)
	if min_x == INF or min_y == INF or max_x == -INF or max_y == -INF:
		return Rect2()
	return Rect2(Vector2(min_x, min_y), Vector2(maxf(1.0, max_x - min_x), maxf(1.0, max_y - min_y)))


func _is_cursor_in_local_rack_band(screen_pos: Vector2, margin_px: float = 0.0) -> bool:
	var rack_rect: Rect2 = _local_rack_screen_band_rect()
	if rack_rect.size.x <= 0.0 or rack_rect.size.y <= 0.0:
		return false
	var test_rect: Rect2 = rack_rect.grow(margin_px)
	if test_rect.size.x <= 0.0 or test_rect.size.y <= 0.0:
		return false
	return test_rect.has_point(screen_pos)


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
	_drag_candidate_meld_index = -1
	_drag_candidate_meld_owner = -1
	_drag_rack_row_lock = -1
	_drag_follow_mode = DRAG_FOLLOW_MODE_NONE
	_drag_started_from_rack = false
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
		if _drag_candidate_slot != -1:
			_drag_rack_row_lock = 0 if _drag_candidate_slot < 15 else 1
		return
	if kind == "table_meld":
		_drag_candidate_meld_index = int(pick.get("meld_index", -1))
		_drag_candidate_meld_owner = int(pick.get("owner", -1))
		return
	if kind == "local_slot":
		var slot_idx: int = int(pick.get("slot", -1))
		var slot_tid: int = _tile_id_in_rack_slot(slot_idx)
		if slot_idx != -1 and slot_tid != -1:
			_drag_candidate_tile_id = slot_tid
			_drag_candidate_slot = slot_idx
			_drag_rack_row_lock = 0 if slot_idx < 15 else 1
			return

	# Fallback when lane/table colliders win the ray: select nearest stage/meld tile by screen distance.
	var stage_hit: Dictionary = _pick_nearest_hit(screen_pos, _stage_tile_hits, DRAG_PICK_RADIUS_PX)
	if not stage_hit.is_empty():
		_drag_candidate_tile_id = int(stage_hit.get("tile_id", -1))
		_drag_candidate_stage_slot = int(stage_hit.get("slot", -1))
		return
	var meld_hit: Dictionary = _pick_nearest_hit(screen_pos, _table_meld_tile_hits, DRAG_PICK_RADIUS_PX)
	if not meld_hit.is_empty():
		_drag_candidate_meld_index = int(meld_hit.get("meld_index", -1))
		_drag_candidate_meld_owner = int(meld_hit.get("owner", -1))


func _start_drag_preview() -> void:
	if _drag_candidate_tile_id == -1:
		return
	_drag_started_from_rack = _drag_candidate_slot != -1
	_drag_follow_mode = DRAG_FOLLOW_MODE_RACK if _drag_started_from_rack else DRAG_FOLLOW_MODE_TABLE
	if _drag_candidate_slot != -1:
		_drag_rack_row_lock = 0 if _drag_candidate_slot < 15 else 1
	_drag_active = true
	_drag_preview_has_target = false
	_rebuild_drag_preview(false)
	if _drag_preview == null or not is_instance_valid(_drag_preview):
		_drag_active = false
		return
	_update_drag_preview(_drag_press_screen)


func _update_drag_preview(screen_pos: Vector2) -> void:
	if not _drag_active or _drag_preview == null or not is_instance_valid(_drag_preview):
		return
	var table_pos_raw: Vector2 = _screen_to_table_local(screen_pos)
	var table_pos_clamped: Vector2 = _screen_to_table_local_clamped(screen_pos)
	var table_pos_clamped_valid: bool = table_pos_clamped.x > INVALID_TABLE_POS.x * 0.5
	var table_pos: Vector2 = table_pos_clamped if table_pos_clamped_valid else table_pos_raw
	if _drag_follow_mode == DRAG_FOLLOW_MODE_NONE:
		_drag_follow_mode = DRAG_FOLLOW_MODE_RACK if _drag_started_from_rack else DRAG_FOLLOW_MODE_TABLE
	var in_rack_release_band: bool = _is_cursor_in_local_rack_band(screen_pos, RACK_BAND_RELEASE_MARGIN_PX)
	var in_rack_reenter_band: bool = _is_cursor_in_local_rack_band(screen_pos, RACK_BAND_REENTER_MARGIN_PX)
	var near_rack_slot: bool = _pick_nearest_rack_slot(screen_pos, RACK_VISUAL_FOLLOW_RADIUS_PX) != -1
	if _drag_follow_mode == DRAG_FOLLOW_MODE_RACK and _drag_started_from_rack and not in_rack_release_band:
		_drag_follow_mode = DRAG_FOLLOW_MODE_TABLE
	elif _drag_follow_mode == DRAG_FOLLOW_MODE_TABLE and _drag_started_from_rack and in_rack_reenter_band and near_rack_slot and table_pos_raw.x <= INVALID_TABLE_POS.x * 0.5:
		_drag_follow_mode = DRAG_FOLLOW_MODE_RACK
	if _drag_follow_mode == DRAG_FOLLOW_MODE_RACK:
		var direct_slot_idx: int = _rack_slot_from_screen_pick(screen_pos)
		var slot_idx: int = direct_slot_idx
		if direct_slot_idx != -1:
			_drag_rack_row_lock = 0 if direct_slot_idx < 15 else 1
		if slot_idx == -1 and _drag_rack_row_lock != -1:
			slot_idx = _pick_nearest_rack_slot_in_row(screen_pos, _drag_rack_row_lock, SLOT_PICK_RADIUS_PX * 1.20)
		if slot_idx == -1 and _drag_rack_row_lock != -1 and _drag_started_from_rack:
			slot_idx = _pick_nearest_rack_slot_in_row(screen_pos, _drag_rack_row_lock, RACK_ROW_STICKY_PICK_RADIUS_PX)
		if slot_idx == -1:
			var rack_radius: float = SLOT_PICK_RADIUS_PX * (1.05 if _drag_started_from_rack else 1.00)
			slot_idx = _pick_nearest_rack_slot(screen_pos, rack_radius)
		if slot_idx != -1 and slot_idx < _local_rack_slot_hits.size():
			if _drag_rack_row_lock == -1:
				_drag_rack_row_lock = 0 if slot_idx < 15 else 1
			if not _drag_preview_standing:
				_rebuild_drag_preview(true)
				if _drag_preview == null or not is_instance_valid(_drag_preview):
					return
			var use_top_row: bool = slot_idx < 15
			var slot_world: Vector3 = (_local_rack_slot_hits[slot_idx].get("world", Vector3.ZERO) as Vector3)
			var row_n: Vector3 = _rack_row_world_normal(use_top_row)
			var row_tilt: float = _rack_row_world_tilt_deg(use_top_row)
			var row_slide_world: Vector3 = _rack_drag_world_point_on_row(screen_pos, use_top_row, slot_world)
			_set_drag_preview_target(row_slide_world + row_n * (TILE_D * 0.62 + 0.0026), Vector3(row_tilt, 0.0, 0.0))
			return
		# If rack follow has no stable slot, force table follow instead of freezing.
		_drag_follow_mode = DRAG_FOLLOW_MODE_TABLE
	if _drag_preview_standing:
		_rebuild_drag_preview(false)
		if _drag_preview == null or not is_instance_valid(_drag_preview):
			return
	if table_pos_clamped_valid:
		_set_drag_preview_target(_table_local_to_world(table_pos, TILE_D * 1.2 + 0.0075), Vector3.ZERO)
		return
	var fallback := _screen_to_near_table(screen_pos)
	_set_drag_preview_target(fallback, Vector3.ZERO)


func _finish_drag(screen_pos: Vector2) -> void:
	if _drag_candidate_tile_id == -1 and _drag_candidate_meld_index == -1 and not _drag_active:
		return
	var drop_ctx: Dictionary = _build_drop_context(screen_pos)
	if _handle_non_drag_click_fallback(drop_ctx):
		return
	if not _populate_drop_context_for_active_drag(drop_ctx):
		_clear_drag_state()
		return
	_try_drop_to_stage(drop_ctx)
	_try_drop_to_committed_meld(drop_ctx)
	_try_reposition_committed_meld(drop_ctx)
	_try_drop_to_discard(drop_ctx)
	_try_drop_to_rack(drop_ctx)
	_finalize_drop_feedback(drop_ctx)


func _build_drop_context(screen_pos: Vector2) -> Dictionary:
	var from_slot: int = _drag_candidate_slot
	var table_pos_raw: Vector2 = _screen_to_table_local(screen_pos)
	var table_pos_clamped: Vector2 = _screen_to_table_local_clamped(screen_pos)
	var table_pos_raw_valid: bool = _is_valid_table_local_pos(table_pos_raw)
	var table_pos_clamped_valid: bool = _is_valid_table_local_pos(table_pos_clamped)
	var follow_mode_for_drop: int = _drag_follow_mode
	if follow_mode_for_drop == DRAG_FOLLOW_MODE_NONE:
		follow_mode_for_drop = DRAG_FOLLOW_MODE_RACK if from_slot != -1 else DRAG_FOLLOW_MODE_TABLE
	if follow_mode_for_drop == DRAG_FOLLOW_MODE_RACK and from_slot != -1 and not _is_cursor_in_local_rack_band(screen_pos, RACK_BAND_RELEASE_MARGIN_PX):
		follow_mode_for_drop = DRAG_FOLLOW_MODE_TABLE
	var table_pos: Vector2 = table_pos_raw
	var table_pick_valid: bool = table_pos_raw_valid
	if follow_mode_for_drop == DRAG_FOLLOW_MODE_TABLE and table_pos_clamped_valid:
		table_pick_valid = true
		table_pos = table_pos_clamped
	elif not table_pick_valid and table_pos_clamped_valid and from_slot != -1 and not _is_cursor_in_local_rack_band(screen_pos, RACK_BAND_RELEASE_MARGIN_PX):
		table_pick_valid = true
		table_pos = table_pos_clamped
	var pick: Dictionary = _raycast_pick(screen_pos)
	var pick_kind: String = str(pick.get("kind", ""))
	var rack_direct_slot: int = -1
	if pick_kind == "local_tile" or pick_kind == "local_slot":
		rack_direct_slot = int(pick.get("slot", -1))
	var rack_nearest_slot: int = -1
	if rack_direct_slot == -1 and _drag_rack_row_lock != -1:
		rack_nearest_slot = _pick_nearest_rack_slot_in_row(screen_pos, _drag_rack_row_lock, SLOT_PICK_RADIUS_PX * 1.40)
	if rack_nearest_slot == -1:
		rack_nearest_slot = _pick_nearest_rack_slot(screen_pos, SLOT_PICK_RADIUS_PX * 1.20)
	var rack_drop_intent: bool = rack_direct_slot != -1 \
		or rack_nearest_slot != -1 \
		or _is_cursor_in_local_rack_band(screen_pos, RACK_BAND_RELEASE_MARGIN_PX)
	return {
		"screen_pos": screen_pos,
		"was_dragging": _drag_active,
		"tile_id": _drag_candidate_tile_id,
		"from_slot": from_slot,
		"from_stage": _drag_candidate_stage_slot,
		"from_meld": int(_drag_candidate_meld_index),
		"from_meld_owner": int(_drag_candidate_meld_owner),
		"follow_mode_for_drop": follow_mode_for_drop,
		"table_pos": table_pos,
		"table_pos_raw": table_pos_raw,
		"table_pos_raw_valid": table_pos_raw_valid,
		"table_pos_clamped": table_pos_clamped,
		"table_pos_clamped_valid": table_pos_clamped_valid,
		"table_pick_valid": table_pick_valid,
		"pick": pick,
		"rack_direct_slot": rack_direct_slot,
		"rack_nearest_slot": rack_nearest_slot,
		"rack_drop_intent": rack_drop_intent,
		"phase": -1,
		"pick_kind": "",
		"pick_player": -1,
		"target_slot": -1,
		"stage_target": -1,
		"handled": false,
		"success_event": &"",
		"snap_world": Vector3.ZERO,
	}


func _handle_non_drag_click_fallback(drop_ctx: Dictionary) -> bool:
	if bool(drop_ctx.get("was_dragging", false)):
		return false
	var tile_id: int = int(drop_ctx.get("tile_id", -1))
	var from_slot: int = int(drop_ctx.get("from_slot", -1))
	var from_stage: int = int(drop_ctx.get("from_stage", -1))
	var from_meld: int = int(drop_ctx.get("from_meld", -1))
	var pick: Dictionary = drop_ctx.get("pick", {})
	var screen_pos: Vector2 = drop_ctx.get("screen_pos", Vector2.ZERO) as Vector2
	var handled: bool = false
	var success_event: StringName = &""
	var snap_world: Vector3 = Vector3.ZERO
	# Click behavior fallback for quick selection.
	if from_meld != -1 and _last_selected_tile_id != -1:
		if _game_table != null and is_instance_valid(_game_table) and _game_table.has_method("get_controller"):
			var c = _game_table.get_controller()
			if c != null and c.state != null and int(c.state.current_player_index) == 0 and int(c.state.phase) == int(GameState.Phase.TURN_PLAY) and _game_table.has_method("overlay_add_to_meld"):
				var add_res: Dictionary = _game_table.overlay_add_to_meld([_last_selected_tile_id], from_meld)
				if bool(add_res.get("ok", false)):
					_last_selected_tile_id = -1
					handled = true
					success_event = SFX_ADD_TO_MELD
					snap_world = (pick.get("world_pos", Vector3.ZERO) as Vector3) + Vector3(0.0, TILE_D * 1.2, 0.0)
					_force_sync()
				else:
					_trigger_invalid_feedback(_last_selected_tile_id, screen_pos)
	elif from_stage != -1:
		_on_stage_tile_clicked({"slot": from_stage, "tile_id": tile_id})
		handled = true
	elif from_slot != -1:
		_on_local_rack_tile_clicked({"slot": from_slot, "tile_id": tile_id})
		handled = true
	if handled and success_event != &"":
		_play_sfx(success_event)
		_trigger_snap_feedback(tile_id, snap_world)
	_clear_drag_state()
	return true


func _populate_drop_context_for_active_drag(drop_ctx: Dictionary) -> bool:
	if _game_table == null or not is_instance_valid(_game_table):
		return false
	if _game_table.has_method("is_action_in_flight") and _game_table.is_action_in_flight():
		return false
	var controller = _game_table.get_controller()
	if controller == null or controller.state == null:
		return false
	var state = controller.state
	if state.current_player_index != 0:
		return false
	var pick: Dictionary = drop_ctx.get("pick", {})
	var table_pos: Vector2 = drop_ctx.get("table_pos", Vector2.ZERO) as Vector2
	var table_pick_valid: bool = bool(drop_ctx.get("table_pick_valid", false))
	var phase: int = int(state.phase)
	var pick_kind: String = str(pick.get("kind", ""))
	var pick_player: int = int(pick.get("player", -1))
	var target_slot: int = int(pick.get("slot", -1))
	var stage_target: int = -1
	if pick_kind == "stage_tile":
		stage_target = int(pick.get("slot", -1))
	if table_pick_valid and stage_target == -1:
		stage_target = _stage_slot_from_table_local(table_pos)
	var on_local_meld_lane: bool = (pick_kind == "meld_lane" and pick_player == 0) \
		or (table_pick_valid and _is_in_meld_lane_expanded(table_pos, 0, MELD_DRAG_LANE_MARGIN))
	if stage_target == -1 and on_local_meld_lane and phase == GameState.Phase.TURN_PLAY and _game_table.has_method("get_stage_slots"):
		stage_target = _first_empty(_game_table.get_stage_slots())
	drop_ctx["phase"] = phase
	drop_ctx["pick_kind"] = pick_kind
	drop_ctx["pick_player"] = pick_player
	drop_ctx["target_slot"] = target_slot
	drop_ctx["stage_target"] = stage_target
	return true


func _try_drop_to_stage(drop_ctx: Dictionary) -> void:
	if bool(drop_ctx.get("handled", false)):
		return
	var phase: int = int(drop_ctx.get("phase", -1))
	var stage_target: int = int(drop_ctx.get("stage_target", -1))
	var pick_kind: String = str(drop_ctx.get("pick_kind", ""))
	if phase != GameState.Phase.TURN_PLAY or stage_target == -1 or pick_kind == "table_meld":
		return
	var from_slot: int = int(drop_ctx.get("from_slot", -1))
	var from_stage: int = int(drop_ctx.get("from_stage", -1))
	if from_stage != -1 and bool(drop_ctx.get("rack_drop_intent", false)):
		return
	var table_pos: Vector2 = drop_ctx.get("table_pos", Vector2.ZERO) as Vector2
	if from_slot != -1:
		var move_to_stage_res: Dictionary = _game_table.overlay_move_rack_to_stage(from_slot, stage_target)
		var handled: bool = bool(move_to_stage_res.get("ok", false))
		if not handled and _game_table.has_method("get_stage_slots"):
			var fallback_stage: int = _first_empty(_game_table.get_stage_slots())
			if fallback_stage != -1 and fallback_stage != stage_target:
				move_to_stage_res = _game_table.overlay_move_rack_to_stage(from_slot, fallback_stage)
				handled = bool(move_to_stage_res.get("ok", false))
		if handled:
			drop_ctx["handled"] = true
			drop_ctx["success_event"] = SFX_STAGE_MOVE
			drop_ctx["snap_world"] = _table_local_to_world(table_pos, TILE_D * 0.9 + 0.006)
	elif from_stage != -1 and from_stage != stage_target and _game_table.has_method("overlay_move_stage_slot"):
		var move_stage_res: Dictionary = _game_table.overlay_move_stage_slot(from_stage, stage_target)
		if bool(move_stage_res.get("ok", false)):
			drop_ctx["handled"] = true
			drop_ctx["success_event"] = SFX_STAGE_MOVE
			drop_ctx["snap_world"] = _table_local_to_world(table_pos, TILE_D * 0.9 + 0.006)


func _try_drop_to_committed_meld(drop_ctx: Dictionary) -> void:
	if bool(drop_ctx.get("handled", false)):
		return
	var tile_id: int = int(drop_ctx.get("tile_id", -1))
	var phase: int = int(drop_ctx.get("phase", -1))
	var pick_kind: String = str(drop_ctx.get("pick_kind", ""))
	if tile_id == -1 or phase != GameState.Phase.TURN_PLAY or pick_kind != "table_meld":
		return
	if not _game_table.has_method("overlay_add_to_meld"):
		return
	var pick: Dictionary = drop_ctx.get("pick", {})
	var meld_index: int = int(pick.get("meld_index", -1))
	if meld_index == -1:
		return
	var add_res: Dictionary = _game_table.overlay_add_to_meld([tile_id], meld_index)
	if bool(add_res.get("ok", false)):
		drop_ctx["handled"] = true
		drop_ctx["success_event"] = SFX_ADD_TO_MELD
		drop_ctx["snap_world"] = (pick.get("world_pos", Vector3.ZERO) as Vector3) + Vector3(0.0, TILE_D * 1.2, 0.0)
	else:
		var screen_pos: Vector2 = drop_ctx.get("screen_pos", Vector2.ZERO) as Vector2
		_trigger_invalid_feedback(tile_id, screen_pos)


func _try_reposition_committed_meld(drop_ctx: Dictionary) -> void:
	if bool(drop_ctx.get("handled", false)):
		return
	var from_meld: int = int(drop_ctx.get("from_meld", -1))
	var from_meld_owner: int = int(drop_ctx.get("from_meld_owner", -1))
	var phase: int = int(drop_ctx.get("phase", -1))
	if from_meld == -1 or from_meld_owner != 0 or phase == GameState.Phase.ROUND_END:
		return
	var table_pos: Vector2 = drop_ctx.get("table_pos", Vector2.ZERO) as Vector2
	if from_meld_owner >= _table_local_meld_lanes.size() or table_pos.x <= INVALID_TABLE_POS.x * 0.5:
		return
	var lane: Rect2 = _table_local_meld_lanes[from_meld_owner]
	if not lane.grow(0.020).has_point(table_pos):
		return
	var clamped_pos := Vector2(
		clampf(table_pos.x, lane.position.x + TILE_W * 0.5, lane.position.x + lane.size.x - TILE_W * 0.5),
		clampf(table_pos.y, lane.position.y + TILE_H * 0.5, lane.position.y + lane.size.y - TILE_H * 0.5)
	)
	var base_center: Vector2 = _table_meld_base_centers.get(from_meld, clamped_pos) as Vector2
	_table_meld_drag_offsets[from_meld] = clamped_pos - base_center
	_last_world_stage_hash = -1
	drop_ctx["handled"] = true
	drop_ctx["success_event"] = SFX_STAGE_MOVE
	drop_ctx["snap_world"] = _table_local_to_world(clamped_pos, TILE_D * 0.9 + 0.006)


func _is_local_discard_drop_intent(drop_ctx: Dictionary, margin: float = DISCARD_DRAG_HIT_MARGIN) -> bool:
	var pick_kind: String = str(drop_ctx.get("pick_kind", ""))
	var pick_player: int = int(drop_ctx.get("pick_player", -1))
	if pick_kind == "discard_zone" and pick_player == 0:
		return true
	var table_pos: Vector2 = drop_ctx.get("table_pos", INVALID_TABLE_POS) as Vector2
	if _is_in_discard_hotspot(table_pos, 0):
		return true
	if margin <= 0.0:
		return false
	var table_pos_raw: Vector2 = drop_ctx.get("table_pos_raw", INVALID_TABLE_POS) as Vector2
	var table_pos_clamped: Vector2 = drop_ctx.get("table_pos_clamped", INVALID_TABLE_POS) as Vector2
	return _is_in_discard_hotspot_expanded(table_pos_raw, 0, margin) \
		or _is_in_discard_hotspot_expanded(table_pos_clamped, 0, margin)


func _try_drop_to_discard(drop_ctx: Dictionary) -> void:
	if bool(drop_ctx.get("handled", false)):
		return
	var from_slot: int = int(drop_ctx.get("from_slot", -1))
	if from_slot == -1:
		return
	var phase: int = int(drop_ctx.get("phase", -1))
	var tile_id: int = int(drop_ctx.get("tile_id", -1))
	if not _is_local_discard_drop_intent(drop_ctx):
		return
	if phase == GameState.Phase.STARTER_DISCARD or phase == GameState.Phase.TURN_DISCARD:
		var discard_res: Dictionary = _game_table.overlay_discard_tile(tile_id)
		if bool(discard_res.get("ok", false)):
			drop_ctx["handled"] = true
			drop_ctx["success_event"] = SFX_DISCARD
			drop_ctx["snap_world"] = _table_local_to_world(_table_local_discard_points[0], TILE_D * 0.9 + 0.005)
		else:
			var screen_pos: Vector2 = drop_ctx.get("screen_pos", Vector2.ZERO) as Vector2
			_trigger_invalid_feedback(tile_id, screen_pos)
	elif phase == GameState.Phase.TURN_PLAY:
		var end_discard_res: Dictionary = _game_table.overlay_end_play_then_discard(tile_id)
		if bool(end_discard_res.get("ok", false)):
			drop_ctx["handled"] = true
			drop_ctx["success_event"] = SFX_DISCARD
			drop_ctx["snap_world"] = _table_local_to_world(_table_local_discard_points[0], TILE_D * 0.9 + 0.005)
		else:
			var screen_pos_end: Vector2 = drop_ctx.get("screen_pos", Vector2.ZERO) as Vector2
			_trigger_invalid_feedback(tile_id, screen_pos_end)


func _try_drop_to_rack(drop_ctx: Dictionary) -> void:
	var handled: bool = bool(drop_ctx.get("handled", false))
	var from_slot: int = int(drop_ctx.get("from_slot", -1))
	var from_stage: int = int(drop_ctx.get("from_stage", -1))
	var follow_mode_for_drop: int = int(drop_ctx.get("follow_mode_for_drop", DRAG_FOLLOW_MODE_NONE))
	var table_pick_valid: bool = bool(drop_ctx.get("table_pick_valid", false))
	var target_slot: int = -1
	var screen_pos: Vector2 = drop_ctx.get("screen_pos", Vector2.ZERO) as Vector2
	var rack_direct_slot: int = int(drop_ctx.get("rack_direct_slot", -1))
	var rack_nearest_slot: int = int(drop_ctx.get("rack_nearest_slot", -1))
	var rack_drop_intent: bool = bool(drop_ctx.get("rack_drop_intent", false))
	var rack_pick_intent: bool = rack_drop_intent
	if from_slot != -1 and (follow_mode_for_drop == DRAG_FOLLOW_MODE_TABLE or table_pick_valid):
		rack_pick_intent = false
	if from_stage != -1 and rack_drop_intent:
		rack_pick_intent = true
	if target_slot == -1:
		target_slot = rack_direct_slot
	if target_slot == -1 and _drag_rack_row_lock != -1:
		target_slot = _pick_nearest_rack_slot_in_row(screen_pos, _drag_rack_row_lock, SLOT_PICK_RADIUS_PX * 1.40)
	if target_slot == -1:
		target_slot = rack_nearest_slot
	if target_slot == -1 and rack_pick_intent:
		target_slot = _pick_nearest_rack_slot(screen_pos, SLOT_PICK_RADIUS_PX * 1.20)
	drop_ctx["target_slot"] = target_slot
	if handled or target_slot == -1 or not rack_pick_intent:
		return
	if from_slot != -1 and target_slot != from_slot:
		var move_rack_res: Dictionary = _game_table.overlay_move_slot(from_slot, target_slot)
		if bool(move_rack_res.get("ok", false)):
			drop_ctx["handled"] = true
			drop_ctx["success_event"] = SFX_RACK_MOVE
			drop_ctx["snap_world"] = _rack_slot_world_snap(target_slot, TILE_D * 0.8)
	elif from_stage != -1:
		var move_to_rack_res: Dictionary = _game_table.overlay_move_stage_to_rack(from_stage, target_slot)
		if bool(move_to_rack_res.get("ok", false)):
			drop_ctx["handled"] = true
			drop_ctx["success_event"] = SFX_RACK_MOVE
			drop_ctx["snap_world"] = _rack_slot_world_snap(target_slot, TILE_D * 0.8)


func _finalize_drop_feedback(drop_ctx: Dictionary) -> void:
	var handled: bool = bool(drop_ctx.get("handled", false))
	var tile_id: int = int(drop_ctx.get("tile_id", -1))
	var success_event: StringName = drop_ctx.get("success_event", &"") as StringName
	var snap_world: Vector3 = drop_ctx.get("snap_world", Vector3.ZERO) as Vector3
	if handled:
		_last_selected_tile_id = -1
		if success_event != &"":
			_play_sfx(success_event)
		_trigger_snap_feedback(tile_id, snap_world)
		_force_sync()
	elif bool(drop_ctx.get("was_dragging", false)):
		var screen_pos: Vector2 = drop_ctx.get("screen_pos", Vector2.ZERO) as Vector2
		_trigger_invalid_feedback(tile_id, screen_pos)
	_clear_drag_state()


func _clear_drag_state() -> void:
	_drag_candidate_tile_id = -1
	_drag_candidate_slot = -1
	_drag_candidate_stage_slot = -1
	_drag_candidate_meld_index = -1
	_drag_candidate_meld_owner = -1
	_drag_rack_row_lock = -1
	_drag_follow_mode = DRAG_FOLLOW_MODE_NONE
	_drag_started_from_rack = false
	_drag_active = false
	_drag_preview_standing = false
	_drag_preview_has_target = false
	if _drag_preview != null and is_instance_valid(_drag_preview):
		_drag_preview.queue_free()
	_drag_preview = null


func _set_drag_preview_target(pos: Vector3, rot_deg: Vector3) -> void:
	var had_target: bool = _drag_preview_has_target
	_drag_preview_target_position = pos
	_drag_preview_target_rotation = rot_deg
	_drag_preview_has_target = true
	if _drag_preview != null and is_instance_valid(_drag_preview):
		# Seed initial preview transform instantly so it doesn't appear to "fly in" from world origin/deck.
		var force_snap: bool = false
		if _drag_active and had_target:
			force_snap = _drag_preview.position.distance_to(_drag_preview_target_position) > DRAG_PREVIEW_SNAP_DISTANCE
		if not _drag_active or not had_target or force_snap:
			_drag_preview.position = _drag_preview_target_position
			_drag_preview.rotation_degrees = _drag_preview_target_rotation


func _update_drag_preview_motion(delta: float) -> void:
	if _drag_preview == null or not is_instance_valid(_drag_preview):
		return
	if not _drag_preview_has_target:
		return
	if _drag_active:
		# During active drag, prioritize direct cursor-follow over smoothing.
		_drag_preview.position = _drag_preview_target_position
		_drag_preview.rotation_degrees = _drag_preview_target_rotation
		return
	var pos_w: float = clampf(delta * DRAG_PREVIEW_POSITION_LERP_SPEED, 0.0, 1.0)
	var rot_w: float = clampf(delta * DRAG_PREVIEW_ROTATION_LERP_SPEED, 0.0, 1.0)
	_drag_preview.position = _drag_preview.position.lerp(_drag_preview_target_position, pos_w)
	_drag_preview.rotation_degrees = _drag_preview.rotation_degrees.lerp(_drag_preview_target_rotation, rot_w)


func _update_hover_candidate() -> void:
	var next_hovered: int = -1
	if not _drag_active and _camera != null and is_instance_valid(_camera):
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		var hit: Dictionary = _pick_nearest_hit(mouse_pos, _local_rack_tile_hits, PICK_RADIUS_PX * 1.55)
		next_hovered = int(hit.get("tile_id", -1))
		if next_hovered != -1 and not _is_local_tile_currently_draggable(next_hovered):
			next_hovered = -1
	if next_hovered != _hovered_rack_tile_id:
		_hovered_rack_tile_id = next_hovered


func _update_feedback_animation_state() -> void:
	if _snap_feedback_until <= _runtime_time and _snap_feedback_tile_id != -1:
		_snap_feedback_tile_id = -1
	if _invalid_feedback_until <= _runtime_time and _invalid_feedback_tile_id != -1:
		_invalid_feedback_tile_id = -1


func _is_local_tile_currently_draggable(tile_id: int) -> bool:
	if tile_id == -1:
		return false
	if _game_table == null or not is_instance_valid(_game_table):
		return false
	if not _game_table.has_method("get_controller"):
		return false
	var controller = _game_table.get_controller()
	if controller == null or controller.state == null:
		return false
	var state = controller.state
	if int(state.current_player_index) != 0:
		return false
	if not _can_reorder_in_phase(int(state.phase)):
		return false
	return _find_tile_data_by_id(tile_id) != null


func _trigger_snap_feedback(tile_id: int, world_pos: Vector3) -> void:
	if tile_id != -1:
		_snap_feedback_tile_id = tile_id
		_snap_feedback_until = _runtime_time + SNAP_FEEDBACK_DURATION
	if world_pos != Vector3.ZERO:
		_spawn_feedback_pulse(world_pos, Color(0.74, 0.96, 0.84, 0.30), 0.014, 0.048, 0.18)


func _trigger_invalid_feedback(tile_id: int, screen_pos: Vector2) -> void:
	if tile_id != -1:
		_invalid_feedback_tile_id = tile_id
		_invalid_feedback_until = _runtime_time + INVALID_FEEDBACK_DURATION
	var world_pos: Vector3 = _screen_to_near_table(screen_pos)
	_spawn_feedback_pulse(world_pos, Color(0.98, 0.34, 0.29, 0.36), 0.016, 0.054, 0.16)
	_play_sfx(SFX_INVALID_ACTION)


func _spawn_feedback_pulse(world_pos: Vector3, color: Color, start_size: float, end_size: float, duration: float) -> void:
	if _world_root == null:
		return
	var pulse := Node3D.new()
	pulse.name = "FeedbackPulse"
	pulse.position = world_pos
	var mesh := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(start_size, start_size)
	mesh.mesh = quad
	mesh.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.set_surface_override_material(0, mat)
	pulse.add_child(mesh)
	_world_root.add_child(pulse)
	var tween: Tween = create_tween()
	tween.tween_property(quad, "size", Vector2(end_size, end_size), duration)
	tween.parallel().tween_property(mat, "albedo_color", Color(color.r, color.g, color.b, 0.0), duration)
	tween.tween_callback(func(): pulse.queue_free())


func _play_sfx(event_id: StringName) -> void:
	if _audio_service != null and is_instance_valid(_audio_service):
		_audio_service.play_sfx(event_id)


func _sync_audio_from_state() -> void:
	if _game_table == null or not is_instance_valid(_game_table) or not _game_table.has_method("get_controller"):
		return
	var controller = _game_table.get_controller()
	if controller == null or controller.state == null:
		return
	var state = controller.state
	var phase: int = int(state.phase)
	if _last_phase_audio == -1:
		_last_phase_audio = phase
		_play_sfx(SFX_NEW_ROUND)
	elif phase != _last_phase_audio:
		if phase == int(GameState.Phase.ROUND_END):
			_play_sfx(SFX_ROUND_END)
		elif _last_phase_audio == int(GameState.Phase.ROUND_END) and phase == int(GameState.Phase.STARTER_DISCARD):
			_reset_local_flip_state()
			_play_sfx(SFX_NEW_ROUND)
		_last_phase_audio = phase


func _update_discard_guide_pulse() -> void:
	if _discard_guides.is_empty():
		return
	var pulse: float = 0.92 + sin(_runtime_time * 2.0) * 0.08
	for guide in _discard_guides:
		if guide == null or not is_instance_valid(guide):
			continue
		var ring_mat: StandardMaterial3D = guide.get_meta("guide_ring_mat", null) as StandardMaterial3D
		if ring_mat == null:
			continue
		var base_ring_a: float = float(guide.get_meta("guide_ring_base_alpha", 0.24))
		var rgb: Color = guide.get_meta("guide_color_rgb", Color(0.80, 0.88, 0.95, 1.0)) as Color
		ring_mat.albedo_color = Color(rgb.r, rgb.g, rgb.b, clampf(base_ring_a * pulse, 0.0, 1.0))


func _update_meld_guide_alpha() -> void:
	if _local_meld_guide == null or not is_instance_valid(_local_meld_guide):
		return
	var target: float = MELD_GUIDE_DRAG_ALPHA if _drag_active and _drag_candidate_tile_id != -1 else MELD_GUIDE_IDLE_ALPHA
	_local_meld_guide_alpha = lerpf(_local_meld_guide_alpha, target, 0.22)
	_set_meld_guide_alpha(_local_meld_guide, _local_meld_guide_alpha)


func _set_meld_guide_alpha(guide: Node3D, alpha: float) -> void:
	if guide == null:
		return
	var clamped_alpha: float = clampf(alpha, 0.0, 1.0)
	var rgb: Color = guide.get_meta("guide_color_rgb", Color(0.70, 0.92, 0.82, 1.0)) as Color
	var fill_base: float = float(guide.get_meta("guide_fill_base_alpha", 0.12))
	var dot_base: float = float(guide.get_meta("guide_dot_base_alpha", 0.60))
	var fill_mat: StandardMaterial3D = guide.get_meta("guide_fill_mat", null) as StandardMaterial3D
	if fill_mat != null:
		fill_mat.albedo_color = Color(rgb.r, rgb.g, rgb.b, clampf(fill_base * clamped_alpha, 0.0, 1.0))
	var dot_mat: StandardMaterial3D = guide.get_meta("guide_dot_mat", null) as StandardMaterial3D
	if dot_mat != null:
		dot_mat.albedo_color = Color(rgb.r, rgb.g, rgb.b, clampf(dot_base * clamped_alpha, 0.0, 1.0))


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


func _pick_nearest_rack_slot(screen_pos: Vector2, radius_px: float = SLOT_PICK_RADIUS_PX) -> int:
	var hit: Dictionary = _pick_nearest_hit(screen_pos, _local_rack_slot_hits, radius_px)
	if hit.is_empty():
		return -1
	return int(hit.get("slot", -1))


func _pick_nearest_rack_slot_in_row(screen_pos: Vector2, row_idx: int, radius_px: float = SLOT_PICK_RADIUS_PX) -> int:
	if _camera == null or not is_instance_valid(_camera):
		return -1
	if row_idx < 0:
		return -1
	var start_idx: int = 0 if row_idx == 0 else 15
	var end_idx: int = mini(start_idx + 15, _local_rack_slot_hits.size())
	if start_idx >= end_idx:
		return -1
	var best_idx: int = -1
	var best_d2: float = radius_px * radius_px
	for i in range(start_idx, end_idx):
		var world_pos: Vector3 = (_local_rack_slot_hits[i].get("world", Vector3.ZERO) as Vector3)
		var projected: Vector2 = _camera.unproject_position(world_pos)
		var d2: float = projected.distance_squared_to(screen_pos)
		if d2 <= best_d2:
			best_idx = i
			best_d2 = d2
	return best_idx


func _rack_row_axis_world_info(use_top_row: bool) -> Dictionary:
	var start_idx: int = 0 if use_top_row else 15
	var end_idx: int = mini(start_idx + 15, _local_rack_slot_hits.size())
	if end_idx - start_idx < 2:
		return {}
	var first_world: Vector3 = (_local_rack_slot_hits[start_idx].get("world", Vector3.ZERO) as Vector3)
	var last_world: Vector3 = (_local_rack_slot_hits[end_idx - 1].get("world", Vector3.ZERO) as Vector3)
	var axis: Vector3 = last_world - first_world
	var length_axis: float = axis.length()
	if length_axis < 0.0001:
		return {}
	axis /= length_axis
	return {
		"origin": first_world,
		"axis": axis,
		"t_min": 0.0,
		"t_max": length_axis,
	}


func _ray_world_from_screen_on_plane(screen_pos: Vector2, plane_point: Vector3, plane_normal: Vector3, fallback: Vector3) -> Vector3:
	if _camera == null or not is_instance_valid(_camera):
		return fallback
	var ro: Vector3 = _camera.project_ray_origin(screen_pos)
	var rd: Vector3 = _camera.project_ray_normal(screen_pos)
	var n: Vector3 = plane_normal.normalized()
	var denom: float = rd.dot(n)
	if absf(denom) < 0.0001:
		return fallback
	var t: float = (plane_point - ro).dot(n) / denom
	if t <= 0.0:
		return fallback
	return ro + rd * t


func _rack_drag_world_point_on_row(screen_pos: Vector2, use_top_row: bool, fallback_slot_world: Vector3) -> Vector3:
	var info: Dictionary = _rack_row_axis_world_info(use_top_row)
	if info.is_empty():
		return fallback_slot_world
	var origin: Vector3 = info.get("origin", fallback_slot_world) as Vector3
	var axis: Vector3 = info.get("axis", Vector3.RIGHT) as Vector3
	var t_min: float = float(info.get("t_min", 0.0))
	var t_max: float = float(info.get("t_max", 0.0))
	if _camera != null and is_instance_valid(_camera):
		var p0_screen: Vector2 = _camera.unproject_position(origin + axis * t_min)
		var p1_screen: Vector2 = _camera.unproject_position(origin + axis * t_max)
		var seg: Vector2 = p1_screen - p0_screen
		var seg_len2: float = seg.length_squared()
		if seg_len2 > 1.0:
			var t_screen: float = clampf((screen_pos - p0_screen).dot(seg) / seg_len2, 0.0, 1.0)
			return origin + axis * lerpf(t_min, t_max, t_screen)
	var row_n: Vector3 = _rack_row_world_normal(use_top_row)
	var plane_hit: Vector3 = _ray_world_from_screen_on_plane(screen_pos, origin, row_n, fallback_slot_world)
	var t: float = clampf((plane_hit - origin).dot(axis), t_min, t_max)
	return origin + axis * t


func _rack_slot_from_screen_pick(screen_pos: Vector2) -> int:
	var pick: Dictionary = _raycast_pick(screen_pos)
	var kind: String = str(pick.get("kind", ""))
	if kind == "local_tile" or kind == "local_slot":
		return int(pick.get("slot", -1))
	return -1


func _rebuild_drag_preview(standing: bool) -> void:
	if _drag_preview != null and is_instance_valid(_drag_preview):
		_drag_preview.queue_free()
	_drag_preview = null
	var tile_data = _find_tile_data_by_id(_drag_candidate_tile_id)
	if tile_data == null:
		_drag_preview_standing = standing
		return
	_drag_preview = _create_tile_face_up(tile_data, standing)
	_drag_preview.scale = Vector3(1.10, 1.10, 1.10)
	_world_root.add_child(_drag_preview)
	if _drag_preview_has_target:
		_drag_preview.position = _drag_preview_target_position
		_drag_preview.rotation_degrees = _drag_preview_target_rotation
	_drag_preview_standing = standing


func _tile_id_in_rack_slot(slot_idx: int) -> int:
	if _game_table == null or not is_instance_valid(_game_table):
		return -1
	if not _game_table.has_method("get_rack_slots"):
		return -1
	var slots: Array = _game_table.get_rack_slots()
	if slot_idx < 0 or slot_idx >= slots.size():
		return -1
	return int(slots[slot_idx])


func _find_tile_data_by_id(tile_id: int):
	if _game_table == null or not is_instance_valid(_game_table):
		return null
	var hand: Array = _game_table.get_hand_tiles() if _game_table.has_method("get_hand_tiles") else []
	for t in hand:
		if int(t.unique_id) == tile_id:
			return t
	return null


func _snapshot_hand_id_set() -> Dictionary:
	var ids: Dictionary = {}
	if _game_table == null or not is_instance_valid(_game_table):
		return ids
	var hand: Array = _game_table.get_hand_tiles() if _game_table.has_method("get_hand_tiles") else []
	for t in hand:
		ids[int(t.unique_id)] = true
	return ids


func _find_new_hand_tile_id(before_ids: Dictionary) -> int:
	if _game_table == null or not is_instance_valid(_game_table):
		return -1
	var hand: Array = _game_table.get_hand_tiles() if _game_table.has_method("get_hand_tiles") else []
	for t in hand:
		var tid: int = int(t.unique_id)
		if not before_ids.has(tid):
			return tid
	return -1


func _local_rack_container() -> Node3D:
	if _world_rack_tile_containers.is_empty():
		return null
	return _world_rack_tile_containers[0] as Node3D


func _rack_row_world_normal(use_top_row: bool) -> Vector3:
	var local_n: Vector3 = (_rack_row0_normal if use_top_row else _rack_row1_normal).normalized()
	var container: Node3D = _local_rack_container()
	if container == null or not is_instance_valid(container):
		return local_n
	var world_n: Vector3 = (container.global_transform.basis * local_n).normalized()
	if world_n.length() < 0.0001:
		return local_n
	if world_n.y < 0.0:
		world_n = -world_n
	return world_n


func _rack_row_world_tilt_deg(use_top_row: bool) -> float:
	return clampf(_row_tilt_from_normal(_rack_row_world_normal(use_top_row)), RACK_ROW_TILT_MIN_DEG, RACK_ROW_TILT_MAX_DEG)


func _rack_slot_world_snap(slot_idx: int, offset_dist: float = TILE_D * 0.8) -> Vector3:
	if slot_idx < 0 or slot_idx >= _local_rack_slot_hits.size():
		return Vector3.ZERO
	var slot_world: Vector3 = (_local_rack_slot_hits[slot_idx].get("world", Vector3.ZERO) as Vector3)
	var use_top_row: bool = slot_idx < 15
	var row_world_n: Vector3 = _rack_row_world_normal(use_top_row)
	return slot_world + row_world_n * maxf(0.0, offset_dist)


func _rack_snap_world_for_tile(tile_id: int) -> Vector3:
	if tile_id == -1:
		return Vector3.ZERO
	if _game_table == null or not is_instance_valid(_game_table) or not _game_table.has_method("get_rack_slots"):
		return Vector3.ZERO
	var slot_idx: int = _find_in_slots(_game_table.get_rack_slots(), tile_id)
	if slot_idx >= 0:
		return _rack_slot_world_snap(slot_idx, TILE_D * 0.8)
	return Vector3.ZERO


func _spawn_tile_transfer_ghost(tile_id: int, from_world: Vector3, to_world: Vector3, duration: float = 0.16) -> void:
	if _world_root == null or tile_id == -1:
		return
	if from_world == Vector3.ZERO or to_world == Vector3.ZERO:
		return
	var tile_data = _find_tile_data_by_id(tile_id)
	if tile_data == null:
		return
	var ghost: Node3D = _create_tile_face_up(tile_data, false)
	ghost.scale = Vector3(1.04, 1.04, 1.04)
	ghost.position = from_world
	ghost.rotation_degrees = Vector3.ZERO
	_world_root.add_child(ghost)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "position", to_world, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "scale", Vector3(0.98, 0.98, 0.98), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(func(): ghost.queue_free())


func _toggle_local_tile_face_down(tile_id: int) -> void:
	if tile_id == -1:
		return
	if bool(_local_rack_face_down_by_id.get(tile_id, false)):
		_local_rack_face_down_by_id.erase(tile_id)
	else:
		_local_rack_face_down_by_id[tile_id] = true
	# Keep selection predictable while flipping state.
	if _last_selected_tile_id == tile_id:
		_last_selected_tile_id = -1
	_last_world_rack_hashes[0] = -1
	_force_sync()


func _reset_local_flip_state() -> void:
	_local_rack_face_down_by_id.clear()
	_last_selected_tile_id = -1
	_last_world_rack_hashes[0] = -1


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

	if _last_selected_tile_id != -1 and _can_reorder_in_phase(state.phase):
		var from_slot: int = _find_in_slots(_game_table.get_rack_slots(), _last_selected_tile_id)
		if from_slot != -1 and from_slot != slot:
			_game_table.overlay_move_slot(from_slot, slot)
			_last_selected_tile_id = tid
			_play_sfx(SFX_RACK_MOVE)
			var snap_world: Vector3 = _rack_slot_world_snap(slot, TILE_D * 0.8)
			if snap_world != Vector3.ZERO:
				_trigger_snap_feedback(tid, snap_world)
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
	_play_sfx(SFX_RACK_MOVE)
	var snap_world: Vector3 = _rack_slot_world_snap(to_rack, TILE_D * 0.8)
	if snap_world != Vector3.ZERO:
		_trigger_snap_feedback(int(hit.get("tile_id", -1)), snap_world)
	_force_sync()


func _is_turn_draw_tap_zone(screen_pos: Vector2, table_pos: Vector2) -> bool:
	if _game_table == null or not is_instance_valid(_game_table):
		return false
	if _game_table.has_method("is_action_in_flight") and _game_table.is_action_in_flight():
		return false
	var controller = _game_table.get_controller()
	if controller == null or controller.state == null:
		return false
	var state = controller.state
	if int(state.current_player_index) != 0 or int(state.phase) != GameState.Phase.TURN_DRAW:
		return false
	if _is_in_draw_hotspot_expanded(table_pos, DRAW_TAP_HIT_MARGIN) \
		or _is_in_draw_pick_screen_hotspot(screen_pos, DRAW_TAP_SCREEN_MARGIN_PX):
		return true
	var prev_idx: int = (int(state.current_player_index) + state.players.size() - 1) % state.players.size()
	return _is_in_discard_hotspot_expanded(table_pos, prev_idx, DISCARD_TAP_HIT_MARGIN) \
		or _is_in_discard_pick_screen_hotspot(screen_pos, prev_idx, DISCARD_TAP_SCREEN_MARGIN_PX)


func _handle_world_tap(pick: Dictionary, table_pos: Vector2, screen_pos: Vector2 = INVALID_TABLE_POS) -> void:
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
	if pick_kind == "local_tile":
		_on_local_rack_tile_clicked(pick)
		return
	if pick_kind == "local_slot":
		return
	if pick_kind == "stage_tile":
		_on_stage_tile_clicked(pick)
		return
	if _handle_turn_draw_tap(pick, table_pos, screen_pos, state):
		return
	if _handle_turn_play_tap_with_selected_tile(pick, table_pos, phase):
		return
	_handle_discard_tap_with_selected_tile(pick, table_pos, phase)


func _handle_turn_draw_tap(pick: Dictionary, table_pos: Vector2, screen_pos: Vector2, state) -> bool:
	if int(state.phase) != GameState.Phase.TURN_DRAW:
		return false
	var pick_kind: String = str(pick.get("kind", ""))
	var pick_player: int = int(pick.get("player", -1))
	var draw_pick_hit: bool = pick_kind == "draw_stack"
	var draw_hotspot_hit: bool = false
	if not draw_pick_hit:
		draw_hotspot_hit = _is_in_draw_hotspot_expanded(table_pos, DRAW_TAP_HIT_MARGIN)
		if not draw_hotspot_hit:
			draw_hotspot_hit = _is_in_draw_pick_screen_hotspot(screen_pos, DRAW_TAP_SCREEN_MARGIN_PX)
	var draw_intent: bool = draw_pick_hit or draw_hotspot_hit
	if draw_intent:
		var before_ids: Dictionary = _snapshot_hand_id_set()
		var draw_source_world: Vector3 = _table_local_to_world(_draw_hotspot_center, TILE_D * 1.1 + 0.006)
		var draw_res: Dictionary = _game_table.overlay_draw_from_deck()
		if bool(draw_res.get("ok", false)):
			_play_sfx(SFX_DRAW_FROM_DECK)
			var new_tile_id: int = _find_new_hand_tile_id(before_ids)
			var arrival_world: Vector3 = _rack_snap_world_for_tile(new_tile_id)
			if arrival_world == Vector3.ZERO:
				arrival_world = draw_source_world + Vector3(0.0, 0.05, 0.0)
			_spawn_tile_transfer_ghost(new_tile_id, draw_source_world, arrival_world)
			_trigger_snap_feedback(new_tile_id, arrival_world)
			_force_sync()
		else:
			_trigger_invalid_feedback(_last_selected_tile_id, get_viewport().get_mouse_position())
		return true
	var prev_idx: int = (int(state.current_player_index) + state.players.size() - 1) % state.players.size()
	var take_discard_pick_hit: bool = pick_kind == "discard_zone" and pick_player == prev_idx
	var take_discard_hotspot_hit: bool = false
	if not take_discard_pick_hit:
		take_discard_hotspot_hit = _is_in_discard_hotspot_expanded(table_pos, prev_idx, DISCARD_TAP_HIT_MARGIN)
		if not take_discard_hotspot_hit:
			take_discard_hotspot_hit = _is_in_discard_pick_screen_hotspot(screen_pos, prev_idx, DISCARD_TAP_SCREEN_MARGIN_PX)
	var take_discard_intent: bool = take_discard_pick_hit or take_discard_hotspot_hit
	if take_discard_intent:
		var before_ids_discard: Dictionary = _snapshot_hand_id_set()
		var discard_source_world: Vector3 = _table_local_to_world(_table_local_discard_points[prev_idx], TILE_D * 1.0 + 0.006)
		var take_res: Dictionary = _game_table.overlay_take_discard()
		if bool(take_res.get("ok", false)):
			_play_sfx(SFX_TAKE_DISCARD)
			var new_tile_id_discard: int = _find_new_hand_tile_id(before_ids_discard)
			var arrival_world_discard: Vector3 = _rack_snap_world_for_tile(new_tile_id_discard)
			if arrival_world_discard == Vector3.ZERO:
				arrival_world_discard = discard_source_world + Vector3(0.0, 0.05, 0.0)
			_spawn_tile_transfer_ghost(new_tile_id_discard, discard_source_world, arrival_world_discard)
			_trigger_snap_feedback(new_tile_id_discard, arrival_world_discard)
			_force_sync()
		else:
			_trigger_invalid_feedback(_last_selected_tile_id, get_viewport().get_mouse_position())
		return true
	return false


func _handle_turn_play_tap_with_selected_tile(pick: Dictionary, table_pos: Vector2, phase: int) -> bool:
	if phase != GameState.Phase.TURN_PLAY or _last_selected_tile_id == -1:
		return false
	var pick_kind: String = str(pick.get("kind", ""))
	var pick_player: int = int(pick.get("player", -1))
	if pick_kind == "table_meld" and _game_table.has_method("overlay_add_to_meld"):
		var meld_index: int = int(pick.get("meld_index", -1))
		if meld_index != -1:
			var add_res: Dictionary = _game_table.overlay_add_to_meld([_last_selected_tile_id], meld_index)
			if bool(add_res.get("ok", false)):
				_play_sfx(SFX_ADD_TO_MELD)
				var meld_snap: Vector3 = (pick.get("world_pos", Vector3.ZERO) as Vector3) + Vector3(0.0, TILE_D * 1.2, 0.0)
				_trigger_snap_feedback(_last_selected_tile_id, meld_snap)
				_last_selected_tile_id = -1
				_force_sync()
			else:
				_trigger_invalid_feedback(_last_selected_tile_id, get_viewport().get_mouse_position())
			return true
	if (pick_kind == "meld_lane" and pick_player == 0) or _is_in_meld_lane(table_pos, 0):
		var from_rack: int = _find_in_slots(_game_table.get_rack_slots(), _last_selected_tile_id)
		var to_stage: int = _stage_slot_from_table_local(table_pos)
		if to_stage == -1:
			to_stage = _first_empty(_game_table.get_stage_slots())
		if from_rack != -1 and to_stage != -1:
			_game_table.overlay_move_rack_to_stage(from_rack, to_stage)
			_play_sfx(SFX_STAGE_MOVE)
			_trigger_snap_feedback(_last_selected_tile_id, _table_local_to_world(table_pos, TILE_D * 1.0 + 0.006))
			_force_sync()
		return true
	return false


func _handle_discard_tap_with_selected_tile(pick: Dictionary, table_pos: Vector2, phase: int) -> bool:
	if _last_selected_tile_id == -1:
		return false
	var pick_kind: String = str(pick.get("kind", ""))
	var pick_player: int = int(pick.get("player", -1))
	if not ((pick_kind == "discard_zone" and pick_player == 0) or _is_in_discard_hotspot(table_pos, 0)):
		return false
	if phase == GameState.Phase.STARTER_DISCARD or phase == GameState.Phase.TURN_DISCARD:
		var discard_res: Dictionary = _game_table.overlay_discard_tile(_last_selected_tile_id)
		if bool(discard_res.get("ok", false)):
			_play_sfx(SFX_DISCARD)
			_trigger_snap_feedback(_last_selected_tile_id, _table_local_to_world(_table_local_discard_points[0], TILE_D * 1.0 + 0.006))
			_last_selected_tile_id = -1
			_force_sync()
		else:
			_trigger_invalid_feedback(_last_selected_tile_id, get_viewport().get_mouse_position())
		return true
	if phase == GameState.Phase.TURN_PLAY:
		var end_discard_res: Dictionary = _game_table.overlay_end_play_then_discard(_last_selected_tile_id)
		if bool(end_discard_res.get("ok", false)):
			_play_sfx(SFX_DISCARD)
			_trigger_snap_feedback(_last_selected_tile_id, _table_local_to_world(_table_local_discard_points[0], TILE_D * 1.0 + 0.006))
			_last_selected_tile_id = -1
			_force_sync()
		else:
			_trigger_invalid_feedback(_last_selected_tile_id, get_viewport().get_mouse_position())
	return true

func _is_valid_table_local_pos(table_pos: Vector2) -> bool:
	return table_pos.x > INVALID_TABLE_POS.x * 0.5


func _is_valid_screen_pos(screen_pos: Vector2) -> bool:
	return screen_pos.x > INVALID_TABLE_POS.x * 0.5 and screen_pos.y > INVALID_TABLE_POS.y * 0.5


func _is_in_draw_hotspot(table_pos: Vector2) -> bool:
	return _is_in_draw_hotspot_expanded(table_pos, 0.0)


func _is_in_draw_hotspot_expanded(table_pos: Vector2, margin: float) -> bool:
	if not _is_valid_table_local_pos(table_pos):
		return false
	return table_pos.distance_to(_draw_hotspot_center) <= DRAW_HIT_RADIUS + maxf(0.0, margin)


func _is_in_draw_pick_screen_hotspot(screen_pos: Vector2, margin_px: float = 0.0) -> bool:
	if not _is_valid_screen_pos(screen_pos):
		return false
	if _camera == null or not is_instance_valid(_camera):
		return false
	if _draw_pick_area == null or not is_instance_valid(_draw_pick_area):
		return false
	return screen_pos.distance_to(_camera.unproject_position(_draw_pick_area.global_position)) <= maxf(0.0, margin_px)


func _is_in_discard_hotspot(table_pos: Vector2, player_index: int) -> bool:
	return _is_in_discard_hotspot_expanded(table_pos, player_index, 0.0)


func _is_in_discard_pick_screen_hotspot(screen_pos: Vector2, player_index: int, margin_px: float = 0.0) -> bool:
	if not _is_valid_screen_pos(screen_pos):
		return false
	if _camera == null or not is_instance_valid(_camera):
		return false
	if player_index < 0 or player_index >= _discard_pick_areas.size():
		return false
	var pick_area: Area3D = _discard_pick_areas[player_index]
	if pick_area == null or not is_instance_valid(pick_area):
		return false
	return screen_pos.distance_to(_camera.unproject_position(pick_area.global_position)) <= maxf(0.0, margin_px)


func _is_in_discard_hotspot_expanded(table_pos: Vector2, player_index: int, margin: float) -> bool:
	if not _is_valid_table_local_pos(table_pos):
		return false
	if player_index < 0 or player_index >= _table_local_discard_points.size():
		return false
	return table_pos.distance_to(_table_local_discard_points[player_index]) <= DISCARD_HIT_RADIUS + maxf(0.0, margin)


func _is_in_meld_lane(table_pos: Vector2, player_index: int) -> bool:
	if player_index < 0 or player_index >= _table_local_meld_lanes.size():
		return false
	return _table_local_meld_lanes[player_index].has_point(table_pos)


func _is_in_meld_lane_expanded(table_pos: Vector2, player_index: int, margin: float) -> bool:
	if player_index < 0 or player_index >= _table_local_meld_lanes.size():
		return false
	return _table_local_meld_lanes[player_index].grow(maxf(0.0, margin)).has_point(table_pos)


func _stage_slot_from_table_local(table_pos: Vector2) -> int:
	if _table_local_meld_lanes.is_empty():
		return -1
	var slot_count: int = _stage_slot_count()
	if slot_count <= 0:
		return -1
	var lane: Rect2 = _table_local_meld_lanes[0]
	if not lane.grow(MELD_DRAG_LANE_MARGIN).has_point(table_pos):
		return -1
	var cols: int = _stage_grid_cols(slot_count)
	var rows: int = maxi(1, int(ceil(float(slot_count) / float(cols))))
	if cols <= 0 or rows <= 0:
		return -1
	var rel_x: float = (table_pos.x - lane.position.x) / maxf(0.0001, lane.size.x)
	var rel_y: float = (table_pos.y - lane.position.y) / maxf(0.0001, lane.size.y)
	var col: int = clampi(int(floor(clampf(rel_x, 0.0, 0.9999) * float(cols))), 0, cols - 1)
	var row: int = clampi(int(floor(clampf(rel_y, 0.0, 0.9999) * float(rows))), 0, rows - 1)
	var idx: int = row * cols + col
	if idx >= slot_count:
		idx = slot_count - 1
	return idx


func _stage_slot_count() -> int:
	if _game_table != null and is_instance_valid(_game_table) and _game_table.has_method("get_stage_slots"):
		var slots: Array = _game_table.get_stage_slots()
		return slots.size()
	return 24


func _stage_grid_cols(slot_count: int) -> int:
	var safe_count: int = maxi(1, slot_count)
	var rows: int = maxi(1, STAGE_GRID_TARGET_ROWS)
	return maxi(1, int(ceil(float(safe_count) / float(rows))))


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


func _create_dotted_meld_area_guide(size: Vector2, color: Color) -> Node3D:
	var node := Node3D.new()

	var fill := MeshInstance3D.new()
	var fill_quad := QuadMesh.new()
	fill_quad.size = size
	fill.mesh = fill_quad
	fill.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	var fill_mat := StandardMaterial3D.new()
	fill_mat.albedo_color = Color(color.r, color.g, color.b, 0.11)
	fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	fill.set_surface_override_material(0, fill_mat)
	node.add_child(fill)

	var sheen := MeshInstance3D.new()
	var sheen_quad := QuadMesh.new()
	sheen_quad.size = size * 0.92
	sheen.mesh = sheen_quad
	sheen.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	sheen.position = Vector3(0.0, 0.0008, 0.0)
	var sheen_mat := StandardMaterial3D.new()
	sheen_mat.albedo_color = Color(color.r * 0.92, color.g * 1.02, color.b * 1.05, 0.05)
	sheen_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sheen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sheen_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sheen.set_surface_override_material(0, sheen_mat)
	node.add_child(sheen)

	var border_mat := StandardMaterial3D.new()
	border_mat.albedo_color = Color(color.r * 0.90, color.g, color.b * 1.06, 0.30)
	border_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	border_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	border_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var border_thickness: float = 0.0026
	var half_w: float = size.x * 0.5
	var half_h: float = size.y * 0.5
	var border_defs: Array[Dictionary] = [
		{"size": Vector2(size.x, border_thickness), "pos": Vector3(0.0, 0.0014, -half_h + border_thickness * 0.5)},
		{"size": Vector2(size.x, border_thickness), "pos": Vector3(0.0, 0.0014, half_h - border_thickness * 0.5)},
		{"size": Vector2(border_thickness, size.y), "pos": Vector3(-half_w + border_thickness * 0.5, 0.0014, 0.0)},
		{"size": Vector2(border_thickness, size.y), "pos": Vector3(half_w - border_thickness * 0.5, 0.0014, 0.0)},
	]
	for b in border_defs:
		var edge := MeshInstance3D.new()
		var edge_quad := QuadMesh.new()
		edge_quad.size = b.get("size", Vector2.ZERO) as Vector2
		edge.mesh = edge_quad
		edge.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		edge.position = b.get("pos", Vector3.ZERO) as Vector3
		edge.set_surface_override_material(0, border_mat)
		node.add_child(edge)

	var corner_mat := StandardMaterial3D.new()
	corner_mat.albedo_color = Color(color.r, color.g * 1.03, color.b * 1.08, 0.42)
	corner_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	corner_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	corner_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var corner_mesh := SphereMesh.new()
	corner_mesh.radius = 0.0019
	corner_mesh.height = 0.0038
	corner_mesh.radial_segments = 10
	corner_mesh.rings = 6
	for cx in [-1.0, 1.0]:
		for cz in [-1.0, 1.0]:
			var dot := MeshInstance3D.new()
			dot.mesh = corner_mesh
			dot.position = Vector3(cx * (half_w - 0.0038), 0.0018, cz * (half_h - 0.0038))
			dot.set_surface_override_material(0, corner_mat)
			node.add_child(dot)

	node.set_meta("guide_fill_mat", fill_mat)
	node.set_meta("guide_dot_mat", border_mat)
	node.set_meta("guide_fill_base_alpha", fill_mat.albedo_color.a)
	node.set_meta("guide_dot_base_alpha", border_mat.albedo_color.a)
	node.set_meta("guide_color_rgb", Color(color.r, color.g, color.b, 1.0))

	return node


func _create_modern_discard_guide(radius: float, color: Color) -> Node3D:
	var node := Node3D.new()

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = radius * 0.84
	ring_mesh.outer_radius = radius
	ring_mesh.rings = 36
	ring_mesh.ring_segments = 20
	ring.mesh = ring_mesh
	ring.position = Vector3(0.0, 0.0016, 0.0)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(color.r, color.g, color.b, clampf(color.a * 0.24, 0.0, 1.0))
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.set_surface_override_material(0, ring_mat)
	node.add_child(ring)

	var inner := MeshInstance3D.new()
	var inner_mesh := CylinderMesh.new()
	inner_mesh.top_radius = radius * 0.72
	inner_mesh.bottom_radius = radius * 0.72
	inner_mesh.height = 0.0006
	inner_mesh.radial_segments = 30
	inner.mesh = inner_mesh
	inner.position = Vector3(0.0, 0.0009, 0.0)
	var inner_mat := StandardMaterial3D.new()
	inner_mat.albedo_color = Color(color.r * 0.98, color.g * 1.02, color.b * 1.06, clampf(color.a * 0.10, 0.0, 1.0))
	inner_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	inner_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	inner_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	inner.set_surface_override_material(0, inner_mat)
	node.add_child(inner)

	node.set_meta("guide_ring_mat", ring_mat)
	node.set_meta("guide_ring_base_alpha", ring_mat.albedo_color.a)
	node.set_meta("guide_color_rgb", Color(color.r, color.g, color.b, 1.0))

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
	if OS.is_debug_build():
		_hud_debug_telemetry = Label.new()
		_hud_debug_telemetry.name = "DebugTelemetry"
		_hud_debug_telemetry.visible = true
		_hud_debug_telemetry.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hud_debug_telemetry.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_hud_debug_telemetry.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		_hud_debug_telemetry.add_theme_font_size_override("font_size", 12)
		_hud_debug_telemetry.add_theme_color_override("font_color", Color(0.88, 0.90, 0.94, 0.82))
		_hud_debug_telemetry.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.03, 0.74))
		_hud_debug_telemetry.add_theme_constant_override("outline_size", 1)
		_hud_layer.add_child(_hud_debug_telemetry)
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
	if _hud_debug_telemetry != null:
		_hud_debug_telemetry.anchor_left = 0.0
		_hud_debug_telemetry.anchor_top = 1.0
		_hud_debug_telemetry.anchor_right = 0.0
		_hud_debug_telemetry.anchor_bottom = 1.0
		_hud_debug_telemetry.offset_left = 16.0
		_hud_debug_telemetry.offset_top = -30.0
		_hud_debug_telemetry.offset_right = 700.0
		_hud_debug_telemetry.offset_bottom = -10.0


func _init_debug_telemetry() -> void:
	if not OS.is_debug_build():
		return
	_telemetry_renderer_method = str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"))
	_telemetry_platform = OS.get_name()
	var driver_key: String = "rendering/rendering_device/driver.%s" % _telemetry_platform.to_lower()
	_telemetry_driver = str(ProjectSettings.get_setting(driver_key, "default"))
	print("[RENDER-DEBUG] renderer=%s driver=%s platform=%s" % [_telemetry_renderer_method, _telemetry_driver, _telemetry_platform])


func _update_debug_telemetry(delta: float) -> void:
	if _hud_debug_telemetry == null or not OS.is_debug_build():
		return
	_telemetry_time_accum += maxf(delta, 0.0001)
	_telemetry_frame_accum += 1
	if _telemetry_time_accum < DEBUG_TELEMETRY_UPDATE_SEC:
		return
	var fps_sample: float = float(_telemetry_frame_accum) / maxf(_telemetry_time_accum, 0.0001)
	_hud_debug_telemetry.text = "DBG Render: %s (%s) | %s | %s | FPS: %d" % [
		_telemetry_renderer_method,
		_telemetry_driver,
		_telemetry_platform,
		str(_visual_settings.get("graphics_profile", "high")).capitalize(),
		int(round(fps_sample))
	]
	_hud_debug_telemetry.text += " | CAP:%s %d/%d" % [
		"ON" if _auto_capture_enabled else "OFF",
		_auto_capture_count,
		AUTO_CAPTURE_MAX_PER_SESSION
	]
	_telemetry_time_accum = 0.0
	_telemetry_frame_accum = 0


func _init_auto_capture() -> void:
	_auto_capture_enabled = false
	_auto_capture_elapsed = 0.0
	_auto_capture_count = 0
	_auto_capture_in_flight = false
	_auto_capture_last_file = ""
	var display_name: String = DisplayServer.get_name().to_lower()
	if display_name.find("headless") != -1:
		return
	_auto_capture_device_tag = _sanitize_filename_component(OS.get_model_name() if OS.get_name() == "Android" else OS.get_name())
	_auto_capture_dir = _resolve_capture_dir()
	_auto_capture_enabled = OS.is_debug_build() and AUTO_CAPTURE_DEFAULT_ENABLED and _auto_capture_dir != ""
	if _auto_capture_enabled:
		print("[CAPTURE] auto enabled -> %s (every %ss)" % [_auto_capture_dir, str(int(AUTO_CAPTURE_INTERVAL_SEC))])


func _update_auto_capture(delta: float) -> void:
	if not _auto_capture_enabled:
		return
	if _auto_capture_in_flight:
		return
	if _auto_capture_count >= AUTO_CAPTURE_MAX_PER_SESSION:
		_auto_capture_enabled = false
		print("[CAPTURE] auto disabled after %d captures (session cap reached)." % AUTO_CAPTURE_MAX_PER_SESSION)
		return
	_auto_capture_elapsed += maxf(delta, 0.0)
	if _auto_capture_elapsed < AUTO_CAPTURE_INTERVAL_SEC:
		return
	_auto_capture_elapsed = 0.0
	_capture_viewport_png("auto")


func _resolve_capture_dir() -> String:
	var candidates: Array[String] = []
	if OS.is_debug_build():
		candidates.append(AUTO_CAPTURE_PROJECT_PATH)
	if OS.get_name() == "Android":
		candidates.append("%s/%s" % [AUTO_CAPTURE_USER_ANDROID_PATH, _auto_capture_device_tag])
	else:
		candidates.append(AUTO_CAPTURE_USER_DESKTOP_PATH)
	for path in candidates:
		if _ensure_capture_dir(path):
			return path
	return ""


func _ensure_capture_dir(path: String) -> bool:
	if path == "":
		return false
	var abs_path: String = ProjectSettings.globalize_path(path)
	var err: int = DirAccess.make_dir_recursive_absolute(abs_path)
	return err == OK or err == ERR_ALREADY_EXISTS


func _capture_viewport_png(label: String) -> void:
	if _auto_capture_in_flight:
		return
	if _auto_capture_dir == "":
		_auto_capture_dir = _resolve_capture_dir()
	if _auto_capture_dir == "":
		print("[CAPTURE] no writable capture directory found.")
		return
	_auto_capture_in_flight = true
	call_deferred("_capture_viewport_png_deferred", label)


func _capture_viewport_png_deferred(label: String) -> void:
	await RenderingServer.frame_post_draw
	var vp: Viewport = get_viewport()
	var tex: ViewportTexture = vp.get_texture() if vp != null else null
	var img: Image = tex.get_image() if tex != null else null
	if img == null or img.is_empty():
		_auto_capture_in_flight = false
		print("[CAPTURE] failed: empty viewport image.")
		return
	var stamp: String = _capture_timestamp()
	var idx: int = _auto_capture_count + 1
	var file_name: String = "%s_%s_%03d.png" % [label, stamp, idx]
	var out_path: String = "%s/%s" % [_auto_capture_dir, file_name]
	var err: int = img.save_png(out_path)
	if err != OK and _auto_capture_dir != AUTO_CAPTURE_USER_DESKTOP_PATH:
		if _ensure_capture_dir(AUTO_CAPTURE_USER_DESKTOP_PATH):
			out_path = "%s/%s" % [AUTO_CAPTURE_USER_DESKTOP_PATH, file_name]
			err = img.save_png(out_path)
	if err == OK:
		_auto_capture_count = idx
		_auto_capture_last_file = out_path
		print("[CAPTURE] saved: %s" % ProjectSettings.globalize_path(out_path))
		if label == "manual" and _hud_instructions != null:
			_hud_instructions.text = "Saved capture: %s" % file_name
	else:
		print("[CAPTURE] save failed (%d): %s" % [err, out_path])
	_auto_capture_in_flight = false


func _capture_timestamp() -> String:
	var d: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d%02d%02d-%02d%02d%02d" % [
		int(d.get("year", 0)),
		int(d.get("month", 0)),
		int(d.get("day", 0)),
		int(d.get("hour", 0)),
		int(d.get("minute", 0)),
		int(d.get("second", 0)),
	]


func _sanitize_filename_component(v: String) -> String:
	var out: String = v.strip_edges().to_lower()
	if out == "":
		return "device"
	for c in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|", " "]:
		out = out.replace(c, "_")
	while out.find("__") != -1:
		out = out.replace("__", "_")
	return out


func _spawn_game_table() -> void:
	if _game_table != null and is_instance_valid(_game_table):
		_game_table.queue_free()
	_reset_local_flip_state()
	_game_table = GAME_TABLE_SCENE.instantiate()
	if _game_table.has_method("set_presentation_mode"):
		_game_table.call("set_presentation_mode", "3d")
	_apply_pending_controller_if_ready()
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
	if _is_round_end_phase():
		_hud_instructions.text = "Round ended. Left click anywhere to start next round."

	var next_required_hue_id: int = -1
	if _game_table != null and is_instance_valid(_game_table) and _game_table.has_method("get_controller"):
		var controller = _game_table.get_controller()
		if controller != null and controller.state != null:
			var required_id: int = int(controller.state.turn_required_use_tile_id)
			if required_id != -1 and _hud_instructions.text.to_lower().begins_with("rejected:") and _hud_instructions.text.to_lower().find("taken discard") != -1:
				next_required_hue_id = required_id
	if next_required_hue_id != _required_tile_hue_id:
		_required_tile_hue_id = next_required_hue_id
		_last_world_rack_hashes[0] = -1


func _is_round_end_phase() -> bool:
	if _game_table == null or not is_instance_valid(_game_table):
		return false
	if not _game_table.has_method("get_controller"):
		return false
	var controller = _game_table.get_controller()
	if controller == null or controller.state == null:
		return false
	return int(controller.state.phase) == int(GameState.Phase.ROUND_END)


func _apply_pending_config_if_ready() -> void:
	if not _has_pending_config:
		return
	if _game_table == null or not is_instance_valid(_game_table):
		return
	_apply_pending_controller_if_ready()
	if _game_table.has_method("configure_game"):
		_game_table.call("configure_game", _pending_rule_config, _pending_seed, _pending_player_count)
	_has_pending_config = false
	_force_sync()

func _apply_pending_controller_if_ready() -> void:
	if not _has_pending_controller:
		return
	if _game_table == null or not is_instance_valid(_game_table):
		return
	if _game_table.has_method("inject_controller"):
		_game_table.call("inject_controller", _pending_controller)
		_has_pending_controller = false


func _resize_subviewport() -> void:
	if _game_viewport == null:
		return
	var visible: Vector2 = get_viewport().get_visible_rect().size
	var width: int = maxi(1280, int(round(visible.x)))
	var height: int = maxi(720, int(round(visible.y)))
	_game_viewport.size = Vector2i(width, height)
