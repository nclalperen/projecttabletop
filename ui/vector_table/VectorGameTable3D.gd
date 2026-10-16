## Unified 3D Vector Game Table for Okey 101.
## Combines real 3D depth, PBR lighting, and materials with 6-DOF mathematical spring physics,
## camera-attached hand rig, persistent TileRegistry3D, and TileAnimator3D flight arcs.
class_name VectorGameTable3D
extends Node3D

const OKEY_SESSION = preload("res://ui/game_table/OkeySession.gd")
const TABLE_ART = preload("res://ui/game_table/OkeyTableArt.gd")
const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")
const SPRING3D = preload("res://ui/vector_table/math/SpringSolver3D.gd")
const HandRig3D = preload("res://ui/vector_table/hand/HandRig3D.gd")
const TileFaceAtlas = preload("res://ui/vector_table/render/TileFaceAtlas.gd")
const VectorTile3D = preload("res://ui/vector_table/render/VectorTile3D.gd")
const TileRegistry3D = preload("res://ui/vector_table/TileRegistry3D.gd")
const TileAnimator3D = preload("res://ui/vector_table/TileAnimator3D.gd")
const OpponentRack3D = preload("res://ui/vector_table/opponents/OpponentRack3D.gd")
const StockView3D = preload("res://ui/vector_table/table/StockView3D.gd")
const DiscardPiles3D = preload("res://ui/vector_table/table/DiscardPiles3D.gd")
const VectorInput3D = preload("res://ui/vector_table/input/VectorInput3D.gd")
const MeldLayout3D = preload("res://ui/vector_table/melds/MeldLayout3D.gd")
const MeldInspectionOverlay = preload("res://ui/game_table/MeldInspectionOverlay.gd")

# Scene references
var _world: Node3D = self
var _world_env: WorldEnvironment
var _camera: Camera3D
var _light: DirectionalLight3D
var _fill_light: OmniLight3D
var _table_mesh: Node3D
var _hand_rig: HandRig3D
var _deck_container: Node3D
var _stock_view: StockView3D
var _discard_piles_view: DiscardPiles3D
var _opponent_racks: Dictionary = {} # seat -> OpponentRack3D
var _meld_layout: MeldLayout3D
var _melds_container: Node3D
var _registry: TileRegistry3D
var _animator: TileAnimator3D
var _input_handler: VectorInput3D
var _vignette_layer: CanvasLayer

# Hand state mapping: slot_index -> unique_id
var _hand_slots_map: Dictionary = {} # slot -> tile_id
var _hand_tiles_map: Dictionary = {} # tile_id -> VectorTile3D

# Discard piles tracking: seat -> Array[int] (tile IDs)
var _discard_pile_ids: Dictionary = {0: [], 1: [], 2: [], 3: []}

# Backward-compat property for test assertions checking table._rack
var _rack: Node:
	get: return _hand_rig

# Declarative OkeyPlayHUD (P7)
const OKEY_HUD_SCENE = preload("res://ui/game_table/OkeyPlayHUD.tscn")
var _hud: OkeyPlayHUD = null
var _is_top_down_view: bool = false
var _cam_tween: Tween = null

# Authoritative Session
var _session: Node = null
var _is_my_turn: bool = false
var _current_phase: int = 1
var _last_action_was_take_discard: bool = false


func _init() -> void:
	_build_3d_environment()
	_build_vignette()
	_hud = OKEY_HUD_SCENE.instantiate() as OkeyPlayHUD
	_hud.name = "PlayHUD"
	add_child(_hud)



func _ready() -> void:
	if get_tree() != null:
		await TileFaceAtlas.ensure_atlas(get_tree())
		if _registry != null:
			_registry.refresh_all_face_textures()

	if _hud != null:
		_hud.set_camera(_camera)
		_hud.board = self
		if not _hud.commit_melds_requested.is_connected(_on_hud_commit_melds):
			_hud.commit_melds_requested.connect(_on_hud_commit_melds)
		if not _hud.sort_requested.is_connected(_on_hud_sort):
			_hud.sort_requested.connect(_on_hud_sort)
		if not _hud.undo_requested.is_connected(_on_hud_undo):
			_hud.undo_requested.connect(_on_hud_undo)
		if not _hud.return_draft_requested.is_connected(_on_hud_return_draft):
			_hud.return_draft_requested.connect(_on_hud_return_draft)
		if not _hud.camera_toggle_requested.is_connected(_toggle_camera_view):
			_hud.camera_toggle_requested.connect(_toggle_camera_view)
		if not _hud.back_to_hub_requested.is_connected(_on_back_to_hub):
			_hud.back_to_hub_requested.connect(_on_back_to_hub)

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

	# 7. Persistent World-space Tiles Registry (D3)
	_registry = TileRegistry3D.new()
	_registry.name = "Tiles"
	add_child(_registry)

	# 8. Flight Animator (D8)
	_animator = TileAnimator3D.new()
	_animator.name = "Animator"
	add_child(_animator)

	# 9. Center Stock Pile (D5)
	_stock_view = StockView3D.new()
	_stock_view.name = "StockPile"
	_stock_view.setup(106)
	add_child(_stock_view)

	# 10. Discard Piles (Seats 0..3) (D5)
	_discard_piles_view = DiscardPiles3D.new()
	_discard_piles_view.name = "DiscardPiles"
	_discard_piles_view.setup(_registry)
	add_child(_discard_piles_view)

	# 11. Opponent Racks (Seats 1, 2, 3) (D5)
	for seat in [1, 2, 3]:
		var opp := OpponentRack3D.new()
		opp.setup(seat, "Bot %d" % seat)
		add_child(opp)
		_opponent_racks[seat] = opp

	# 12. Center Table Melds Layout (D5, P6)
	_meld_layout = MeldLayout3D.new()
	_meld_layout.name = "MeldLayout"
	add_child(_meld_layout)
	_melds_container = _meld_layout

	# 13. Physics Input System (D5)
	_input_handler = VectorInput3D.new()
	_input_handler.name = "VectorInput"
	add_child(_input_handler)


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


func _on_hud_commit_melds() -> void:
	if _session != null:
		_session.request_open_rack_melds()


func _on_hud_sort(mode: StringName) -> void:
	if _session != null:
		_session.overlay_sort_rack(String(mode))


func _on_hud_undo() -> void:
	if _session != null:
		_session.overlay_undo()


func _on_hud_return_draft() -> void:
	if _session != null:
		_session.overlay_return_draft()


func _toggle_camera_view() -> void:
	_is_top_down_view = not _is_top_down_view
	if _cam_tween != null and _cam_tween.is_running():
		_cam_tween.kill()
	_cam_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _is_top_down_view:
		_cam_tween.tween_property(_camera, ^"position", Vector3(0.0, 0.95, 0.001), 0.35)
		_cam_tween.parallel().tween_property(_camera, ^"rotation_degrees", Vector3(-90.0, 0.0, 0.0), 0.35)
	else:
		_cam_tween.tween_property(_camera, ^"position", TUNING.CAMERA_POS, 0.35)
		_cam_tween.parallel().tween_property(_camera, ^"rotation_degrees", Vector3(-43.0, 0.0, 0.0), 0.35)


func _on_back_to_hub() -> void:
	if get_tree() != null:
		get_tree().change_scene_to_file("res://ui/StarterMenu.tscn")




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

	if _hud != null:
		_hud.bind_to_session(_session)
		_hud.refresh(_session)

	if _input_handler != null:
		_input_handler.setup(self, _camera, _hand_rig, _registry, _session, _stock_view, _discard_piles_view)


func _init_session() -> void:
	configure_game(RuleConfig.new(), 1701, 4)


func _process(_delta: float) -> void:
	# Continuously recompute world target for hand tiles from HandRig (D3)
	for slot_idx in _hand_slots_map.keys():
		var tile_id: int = _hand_slots_map[slot_idx]
		var tile: VectorTile3D = _hand_tiles_map.get(tile_id, null)
		if tile != null and not tile.is_flying and not tile.is_dragging:
			var world_xf: Transform3D = _hand_rig.slot_global_transform(slot_idx)
			tile.set_target_position_3d(world_xf.origin, false)
			var euler_deg := world_xf.basis.get_euler() * (180.0 / PI)
			tile.set_target_rotation_3d(euler_deg, false)

	# Dynamic projection for opponent seat badges to 3D rack positions clamped to screen edges (P7)
	if _camera != null and _hud != null and _hud.seat_badges.size() >= 4:
		var vp_size := get_viewport().get_visible_rect().size if get_viewport() != null else Vector2(1920, 1080)
		# East (Seat 1)
		var p1 := _camera.unproject_position(TUNING.OPPONENT_RACK_POS_3D[1])
		var b1: Control = _hud.seat_badges[1] as Control
		if b1 != null:
			b1.global_position.y = clampf(p1.y - 26.0, 60.0, vp_size.y - 120.0)
		# North (Seat 2)
		var p2 := _camera.unproject_position(TUNING.OPPONENT_RACK_POS_3D[2])
		var b2: Control = _hud.seat_badges[2] as Control
		if b2 != null:
			b2.global_position.x = clampf(p2.x - 90.0, 260.0, vp_size.x - 350.0)
		# West (Seat 3)
		var p3 := _camera.unproject_position(TUNING.OPPONENT_RACK_POS_3D[3])
		var b3: Control = _hud.seat_badges[3] as Control
		if b3 != null:
			b3.global_position.y = clampf(p3.y - 26.0, 60.0, vp_size.y - 120.0)


func _on_session_state_updated(snapshot: Dictionary) -> void:
	_is_my_turn = bool(snapshot.get("is_local_turn", false))

	# 1. Update Stock Count
	var deck_count: int = int(snapshot.get("deck_count", 0))
	if _stock_view != null:
		_stock_view.update_count(deck_count)

	# 2. Update Indicator Tile in 3D (flat on table per D5)
	var ind_tile = snapshot.get("indicator_tile")
	if ind_tile != null:
		var tile_node: VectorTile3D = _registry.ensure(ind_tile.unique_id, ind_tile.number, ind_tile.color, ind_tile.kind != 0, false, true)
		tile_node.set_target_position_3d(TUNING.INDICATOR_POS_3D, true)
		tile_node.set_target_rotation_3d(Vector3(-90.0, TUNING.INDICATOR_ROT_DEG.y, 0.0), true)
		_registry.set_zone(ind_tile.unique_id, &"indicator")

	# 3. Update Opponent Racks tile counts
	var controller = _session.get_controller() if _session != null else null
	if controller != null and controller.state != null:
		for seat in [1, 2, 3]:
			if seat < controller.state.players.size():
				var p = controller.state.players[seat]
				var count: int = p.hand.size()
				if _opponent_racks.has(seat) and _opponent_racks[seat] != null:
					_opponent_racks[seat].set_tile_count(count)

	# 4. Update discard stacks diffing
	_sync_discards()


func _sync_discards() -> void:
	var controller = _session.get_controller() if _session != null else null
	if controller == null or controller.state == null:
		return
	var state = controller.state
	var stacks: Array = state.player_discard_stacks if ("player_discard_stacks" in state) else []
	if stacks.is_empty():
		return

	if _discard_piles_view != null:
		_discard_piles_view.sync_stacks(stacks, _animator, _opponent_racks)


func _get_tile_by_id(tile_id: int):
	var controller = _session.get_controller() if _session != null else null
	if controller == null or controller.state == null or controller.state.players.is_empty():
		return null
	for t in controller.state.players[0].hand:
		if int(t.unique_id) == tile_id:
			return t
	return null


func _on_rack_and_draft_changed(rack_slots: Array, _draft_slots: Array, validation: Dictionary) -> void:
	var new_slots_map: Dictionary = {}
	var new_tiles_map: Dictionary = {}
	_hand_rig._row_tiles = [[], []]

	var valid_ids: Array = validation.get("valid_tile_ids", []) as Array

	for slot_idx in range(mini(rack_slots.size(), TUNING.TOTAL_HAND_SLOTS)):
		var tile_id: int = int(rack_slots[slot_idx])
		if tile_id == -1:
			continue
		var tile_data = _get_tile_by_id(tile_id)
		if tile_data == null:
			continue

		var prev_zone := _registry.zone_of(tile_id)
		var v_tile: VectorTile3D = _registry.ensure(tile_data.unique_id, tile_data.number, tile_data.color, tile_data.kind != 0, true, true)
		var world_xf: Transform3D = _hand_rig.slot_global_transform(slot_idx)

		var is_valid: bool = valid_ids.has(tile_data.unique_id)
		v_tile.set_highlight(&"valid_meld" if is_valid else &"none")

		if prev_zone == &"none":
			# Initial deal
			v_tile.set_target_position_3d(world_xf.origin, true)
			var euler_deg := world_xf.basis.get_euler() * (180.0 / PI)
			v_tile.set_target_rotation_3d(euler_deg, true)
		elif prev_zone == &"stock":
			# Drawn from stock
			var from_xf := Transform3D(Basis.from_euler(Vector3(deg_to_rad(-90.0), deg_to_rad(TUNING.STOCK_ROT_DEG.y), 0.0)), TUNING.STOCK_POS_3D)
			_animator.fly_draw(v_tile, from_xf, world_xf)
		elif prev_zone.begins_with("discard_"):
			# Drawn from discard
			var seat_idx := int(prev_zone.trim_prefix("discard_"))
			var pile_pos: Vector3 = TUNING.DISCARD_POS_3D.get(seat_idx, TUNING.DISCARD_POS_3D[3])
			var pile_rot: Vector3 = TUNING.DISCARD_ROT_DEG.get(seat_idx, TUNING.DISCARD_ROT_DEG[3])
			var from_xf := Transform3D(Basis.from_euler(Vector3(deg_to_rad(-90.0), deg_to_rad(pile_rot.y), 0.0)), pile_pos)
			_animator.fly_draw(v_tile, from_xf, world_xf)
		else:
			# Internal hand reorder / spring update
			if not v_tile.is_flying and not v_tile.is_dragging:
				v_tile.set_target_position_3d(world_xf.origin, false)
				var euler_deg := world_xf.basis.get_euler() * (180.0 / PI)
				v_tile.set_target_rotation_3d(euler_deg, false)

		_registry.set_zone(tile_id, &"hand")
		new_slots_map[slot_idx] = tile_id
		new_tiles_map[tile_id] = v_tile

		var row_idx: int = 0 if slot_idx < TUNING.SLOTS_PER_ROW else 1
		_hand_rig._row_tiles[row_idx].append(v_tile)

	_hand_slots_map = new_slots_map
	_hand_tiles_map = new_tiles_map


func _on_melds_updated(melds: Array) -> void:
	if _meld_layout == null:
		return

	var okey_ctx = null
	if _session != null and _session.get_controller() != null and _session.get_controller().state != null:
		okey_ctx = _session.get_controller().state.okey_context

	_meld_layout.sync_melds(melds, okey_ctx)

	if _hud != null and _hud.meld_inspection_overlay != null:
		_hud.meld_inspection_overlay.sync_meld_groups(_meld_layout.get_all_meld_data())


	var tile_delay_sec: float = 0.0
	for m_idx in range(_meld_layout.get_meld_count()):
		var m_data: Dictionary = _meld_layout.get_meld_data(m_idx)
		var ids: Array = m_data.get("tile_ids", [])
		var tiles_arr: Array = m_data.get("tiles", [])
		for k in range(ids.size()):
			var tid: int = ids[k]
			var num: int = 1
			var col: int = 0
			var is_fake: bool = false
			if k < tiles_arr.size():
				var t = tiles_arr[k]
				if t is Tile:
					num = t.number
					col = t.color
					is_fake = (t.kind != 0)
				elif t is Dictionary:
					num = int(t.get("number", 1))
					col = int(t.get("color", 0))
					is_fake = (int(t.get("kind", 0)) != 0)
			else:
				var t_data = _get_tile_by_id(tid)
				if t_data != null:
					num = t_data.number
					col = t_data.color
					is_fake = (t_data.kind != 0)

			var prev_zone := _registry.zone_of(tid)
			var v_tile: VectorTile3D = _registry.ensure(tid, num, col, is_fake, false, true)
			var target_xf: Transform3D = _meld_layout.get_tile_transform(tid)

			if prev_zone == &"hand":
				# Staggered Bezier flight from hand to meld (D8: 0.05s per tile, 0.32s each)
				var from_xf := v_tile.global_transform
				_animator.fly_meld(v_tile, from_xf, target_xf, tile_delay_sec)
				tile_delay_sec += 0.05
			elif prev_zone == &"none":
				v_tile.position = target_xf.origin
				v_tile.rotation_degrees = target_xf.basis.get_euler() * (180.0 / PI)
				v_tile.set_target_position_3d(target_xf.origin, true)
				v_tile.set_target_rotation_3d(Vector3(-90.0, 0.0, 0.0), true)
			else:
				if not v_tile.is_flying and not v_tile.is_dragging:
					v_tile.set_target_position_3d(target_xf.origin, false)
					v_tile.set_target_rotation_3d(Vector3(-90.0, 0.0, 0.0), false)

			_registry.set_zone(tid, &"meld_%d" % m_idx)

