## Unified 3D Vector Game Table for Okey 101.
## Combines real 3D depth, PBR lighting, and materials with 6-DOF mathematical spring physics,
## camera-attached hand rig, and crisp texture-atlas tile faces.
class_name VectorGameTable3D
extends Node3D

const OKEY_SESSION = preload("res://ui/game_table/OkeySession.gd")
const TABLE_ART = preload("res://ui/game_table/OkeyTableArt.gd")
const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")
const SPRING3D = preload("res://ui/vector_table/math/SpringSolver3D.gd")
const HandRig3D = preload("res://ui/vector_table/hand/HandRig3D.gd")
const TileFaceAtlas = preload("res://ui/vector_table/render/TileFaceAtlas.gd")
const VectorTile3D = preload("res://ui/vector_table/render/VectorTile3D.gd")

# Scene references
var _world: Node3D = self
var _world_env: WorldEnvironment
var _camera: Camera3D
var _light: DirectionalLight3D
var _fill_light: OmniLight3D
var _table_mesh: Node3D
var _hand_rig: HandRig3D
var _deck_container: Node3D
var _indicator_tile: VectorTile3D
var _melds_container: Node3D
var _tiles_container: Node3D
var _discard_tiles: Dictionary = {} # seat -> VectorTile3D
var _vignette_layer: CanvasLayer

# Hand tiles tracking
var _hand_tiles: Dictionary = {} # slot -> VectorTile3D

# Backward-compat property for tests checking table._rack
var _rack: Node:
	get: return _hand_rig

# HUD Overlay
var _hud_layer: CanvasLayer
var _status_label: Label
var _action_dock: HBoxContainer
var _btn_sort_runs: Button
var _btn_sort_pairs: Button
var _btn_open_melds: Button

# Authoritative Session
var _session: Node = null
var _is_my_turn: bool = false
var _current_phase: int = 1


func _init() -> void:
	_build_3d_environment()
	_build_vignette()
	_build_hud_overlay()


func _ready() -> void:
	# Ensure tile face atlas is built once
	if get_tree() != null:
		await TileFaceAtlas.ensure_atlas(get_tree())

	if _session == null:
		_init_session()


func _build_3d_environment() -> void:
	# 1. WorldEnvironment with warm tone, HDRI ambient, AgX tonemapping, SSAO, and subtle glow
	_world_env = WorldEnvironment.new()
	_world_env.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#0d0b0a") # Warm dark room, never grey
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.35
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	var sky := Sky.new()
	var sky_mat := PanoramaSkyMaterial.new()
	var hdr_tex := AssetRegistry.texture(AssetIds.GAMEPLAY_HDRI_STUDIO_SMALL_03)
	if hdr_tex != null:
		sky_mat.panorama = hdr_tex
		sky.sky_material = sky_mat
		env.sky = sky

	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0

	env.ssao_enabled = true
	env.ssao_radius = 0.08
	env.ssao_intensity = 1.6

	env.glow_enabled = true
	env.glow_intensity = 0.15
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 2.0

	env.adjustment_enabled = true
	env.adjustment_contrast = 1.05
	env.adjustment_saturation = 1.05

	_world_env.environment = env
	add_child(_world_env)

	# 2. KeyLight: Warm Directional Key Light with Soft Shadows
	_light = DirectionalLight3D.new()
	_light.name = "KeyLight"
	_light.rotation_degrees = Vector3(-52.0, 28.0, 0.0)
	_light.light_color = Color("#fff1dc")
	_light.light_energy = 1.6
	_light.shadow_enabled = true
	_light.shadow_blur = 1.5
	_light.directional_shadow_max_distance = 2.5
	add_child(_light)

	# 3. FillLight: Cool Omni Fill Light (no shadows)
	_fill_light = OmniLight3D.new()
	_fill_light.name = "FillLight"
	_fill_light.position = Vector3(-0.6, 0.9, 0.5)
	_fill_light.light_color = Color("#9fb8ff")
	_fill_light.light_energy = 0.25
	_fill_light.omni_range = 3.0
	_fill_light.shadow_enabled = false
	add_child(_fill_light)

	# 4. Camera: Locked 40° FOV Framing (per D6, no jumping!)
	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.fov = TUNING.CAMERA_FOV
	_camera.look_at_from_position(TUNING.CAMERA_POS, TUNING.CAMERA_LOOK_AT, Vector3.UP)
	add_child(_camera)

	# 5. Hand Rig: Camera-attached 2-tier walnut rack (D1, D7)
	_hand_rig = HandRig3D.new()
	_camera.add_child(_hand_rig)

	# 6. Procedural Walnut & Emerald Felt Table (1.26m x 1.04m widescreen)
	_table_mesh = TABLE_ART.build_table(self, TUNING.TABLE_SURFACE_Y)
	_table_mesh.name = "Table"

	# 7. Persistent World-space Tiles Container (D3)
	_tiles_container = Node3D.new()
	_tiles_container.name = "Tiles"
	add_child(_tiles_container)

	# 8. Center Deck & Discard Containers
	_deck_container = Node3D.new()
	_deck_container.name = "StockAndIndicator"
	add_child(_deck_container)

	_melds_container = Node3D.new()
	_melds_container.name = "TableMelds"
	add_child(_melds_container)

	_build_3d_deck_stack()


func _build_vignette() -> void:
	_vignette_layer = CanvasLayer.new()
	_vignette_layer.name = "VignetteLayer"
	_vignette_layer.layer = 0
	var vignette_rect := ColorRect.new()
	vignette_rect.name = "VignetteRect"
	vignette_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vig_mat := ShaderMaterial.new()
	var vig_shader := Shader.new()
	vig_shader.code = """shader_type canvas_item;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);
	float vig = smoothstep(0.40, 0.85, dist);
	COLOR = vec4(0.0, 0.0, 0.0, vig * 0.35);
}
"""
	vig_mat.shader = vig_shader
	vignette_rect.material = vig_mat
	_vignette_layer.add_child(vignette_rect)
	add_child(_vignette_layer)


func _build_3d_deck_stack() -> void:
	# Build 3D deck stack of physical ivory tiles
	for i in range(4):
		var tile := TABLE_ART.build_tile(true, false)
		tile.position = TUNING.STOCK_POS_3D + Vector3(0.0, float(i) * 0.0092 + 0.0045, 0.0)
		tile.rotation_degrees = Vector3(-90.0, 8.0, 0.0)
		_deck_container.add_child(tile)


func _build_hud_overlay() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HUDLayer"
	_hud_layer.layer = 1
	add_child(_hud_layer)

	# Top Status Bar
	var top_panel := PanelContainer.new()
	top_panel.anchor_left = 0.5
	top_panel.anchor_right = 0.5
	top_panel.offset_left = -340.0
	top_panel.offset_right = 340.0
	top_panel.offset_top = 16.0
	top_panel.offset_bottom = 54.0

	var top_hbox := HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_panel.add_child(top_hbox)

	_status_label = Label.new()
	_status_label.text = "Okey 101: 3D Vector Table"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_hbox.add_child(_status_label)
	_hud_layer.add_child(top_panel)

	# Bottom Action Dock
	_action_dock = HBoxContainer.new()
	_action_dock.anchor_left = 0.5
	_action_dock.anchor_right = 0.5
	_action_dock.anchor_top = 1.0
	_action_dock.anchor_bottom = 1.0
	_action_dock.offset_left = -260.0
	_action_dock.offset_right = 260.0
	_action_dock.offset_top = -48.0
	_action_dock.offset_bottom = -14.0
	_action_dock.alignment = BoxContainer.ALIGNMENT_CENTER

	_btn_sort_runs = Button.new()
	_btn_sort_runs.text = "Seri Diz (Runs)"
	_btn_sort_runs.pressed.connect(func(): if _session != null: _session.overlay_sort_rack(&"runs"))
	_action_dock.add_child(_btn_sort_runs)

	_btn_sort_pairs = Button.new()
	_btn_sort_pairs.text = "Çift Diz (Pairs)"
	_btn_sort_pairs.pressed.connect(func(): if _session != null: _session.overlay_sort_rack(&"pairs"))
	_action_dock.add_child(_btn_sort_pairs)

	_btn_open_melds = Button.new()
	_btn_open_melds.text = "Melds Aç (Open)"
	_btn_open_melds.pressed.connect(func(): if _session != null: _session.action_open_melds())
	_action_dock.add_child(_btn_open_melds)

	_hud_layer.add_child(_action_dock)


func configure_game(rule_config: RuleConfig, game_seed: int = 1701, player_count: int = 4, bot_difficulties: Array = []) -> void:
	if _session == null:
		_session = OKEY_SESSION.new()
		add_child(_session)
		_session.session_state_updated.connect(_on_session_state_updated)
		_session.rack_and_draft_changed.connect(_on_rack_and_draft_changed)
		_session.table_melds_updated.connect(_on_melds_updated)
	_session.configure_game(rule_config if rule_config != null else RuleConfig.new(), game_seed, player_count, bot_difficulties)
	_session._bind_controller_signals()
	_session._start_round()
	_session._sync_state()


func _init_session() -> void:
	configure_game(RuleConfig.new(), 1701, 4)


func _on_session_state_updated(snapshot: Dictionary) -> void:
	_is_my_turn = bool(snapshot.get("is_local_turn", false))
	_status_label.text = str(snapshot.get("instruction", "Okey 101 Tabletop"))

	# Update Indicator Tile in 3D (flat on table per D5)
	var ind_tile = snapshot.get("indicator_tile")
	if ind_tile != null:
		if _indicator_tile == null:
			_indicator_tile = VectorTile3D.new()
			add_child(_indicator_tile)
		_indicator_tile.setup_tile(ind_tile.unique_id, ind_tile.number, ind_tile.color, ind_tile.kind != 0, true, true)
		_indicator_tile.set_target_position_3d(TUNING.INDICATOR_POS_3D, true)
		# Flat on felt, tilted back -90° on X, -6° yaw jitter
		_indicator_tile.set_target_rotation_3d(Vector3(-90.0, TUNING.INDICATOR_ROT_DEG.y, 0.0), true)


func _get_tile_by_id(tile_id: int):
	var controller = _session.get_controller() if _session != null else null
	if controller == null or controller.state == null or controller.state.players.is_empty():
		return null
	for t in controller.state.players[0].hand:
		if int(t.unique_id) == tile_id:
			return t
	return null


func _on_rack_and_draft_changed(rack_slots: Array, _draft_slots: Array, validation: Dictionary) -> void:
	# Clean up previous hand tiles
	for tile in _hand_tiles.values():
		tile.queue_free()
	_hand_tiles.clear()

	_hand_rig._row_tiles = [[], []]

	var valid_ids: Array = validation.get("valid_tile_ids", []) as Array

	for slot_idx in range(mini(rack_slots.size(), TUNING.TOTAL_HAND_SLOTS)):
		var tile_id: int = int(rack_slots[slot_idx])
		if tile_id == -1:
			continue
		var tile_data = _get_tile_by_id(tile_id)
		if tile_data == null:
			continue

		var v_tile := VectorTile3D.new()
		v_tile.setup_tile(tile_data.unique_id, tile_data.number, tile_data.color, tile_data.kind != 0, true, true)
		_tiles_container.add_child(v_tile)

		var world_xf: Transform3D = _hand_rig.slot_global_transform(slot_idx)
		v_tile.set_target_position_3d(world_xf.origin, true)
		var euler_deg := world_xf.basis.get_euler() * (180.0 / PI)
		v_tile.set_target_rotation_3d(euler_deg, true)

		var is_valid: bool = valid_ids.has(tile_data.unique_id)
		v_tile.set_highlight(&"valid_meld" if is_valid else &"none")

		_hand_tiles[slot_idx] = v_tile

		var row_idx: int = 0 if slot_idx < TUNING.SLOTS_PER_ROW else 1
		_hand_rig._row_tiles[row_idx].append(v_tile)


func _on_melds_updated(melds: Array) -> void:
	for child in _melds_container.get_children():
		child.queue_free()

	if melds.is_empty():
		return

	# Place 3D melds onto the center felt in organic horizontal groups
	var start_z: float = -0.06
	var group_x: float = -0.28
	for meld in melds:
		var tiles: Array = meld.get("tiles", [])
		for i in range(tiles.size()):
			var data: Dictionary = tiles[i]
			var t := VectorTile3D.new()
			t.setup_tile(data.get("unique_id", -1), data.get("number", 1), data.get("color", 0), data.get("kind", 0) != 0, true, true)
			var target_pos := Vector3(group_x + (float(i) * 0.046), TUNING.TABLE_SURFACE_Y + 0.005, start_z)
			t.set_target_position_3d(target_pos, true)
			t.set_target_rotation_3d(Vector3(-90.0, 0.0, 0.0), true)
			_melds_container.add_child(t)
		group_x += (float(tiles.size()) * 0.046) + 0.035
