extends Control

const OKEY_TILE_SCENE: PackedScene = preload("res://ui/widgets/OkeyTile.tscn")
const LOCAL_CONTROLLER_SCRIPT: Script = preload("res://core/controller/LocalGameController.gd")
const GEO = preload("res://ui/game_table/TableGeometry.gd")
const TILE_HELPERS = preload("res://ui/game_table/TileHelpers.gd")
const RACK_SLOT_MANAGER = preload("res://ui/game_table/RackSlotManager.gd")
const STAGE_MELD_LOGIC = preload("res://ui/game_table/StageMeldLogic.gd")
const BOARD_RENDERER = preload("res://ui/game_table/BoardRenderer.gd")
const DRAFT_GRID = preload("res://ui/game_table/DraftGrid.gd")
const INTERACTION_RESOLVER = preload("res://ui/game_table/InteractionResolver.gd")
const INTERACTION_TUNING = preload("res://ui/game_table/InteractionTuning.gd")
const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")

# ─── Scene node references ───
@onready var _top_bar: PanelContainer = $TopBar
@onready var _top_hbox: HBoxContainer = $TopBar/TopHBox
@onready var _instructions: Label = $TopBar/TopHBox/Instructions
@onready var _turn_label: Label = $TopBar/TopHBox/TurnLabel
@onready var _phase_label: Label = $TopBar/TopHBox/PhaseLabel
@onready var _deck_count_top: Label = $TopBar/TopHBox/DeckCount
@onready var _okey_info_top: Label = $TopBar/TopHBox/OkeyInfo

@onready var _table_area: Control = $TableArea
@onready var _felt_frame: Panel = $TableArea/FeltFrame
@onready var _center_zone: HBoxContainer = $TableArea/CenterZone
@onready var _draw_deck: PanelContainer = $TableArea/CenterZone/DrawDeck
@onready var _indicator_panel: PanelContainer = $TableArea/CenterZone/IndicatorPanel
@onready var _deck_title: Label = $TableArea/CenterZone/DrawDeck/DeckVBox/DeckTitle
@onready var _deck_num: Label = $TableArea/CenterZone/DrawDeck/DeckVBox/DeckNum
@onready var _ind_title: Label = $TableArea/CenterZone/IndicatorPanel/IndVBox/IndTitle
@onready var _ind_value: Label = $TableArea/CenterZone/IndicatorPanel/IndVBox/IndValue
@onready var _okey_value: Label = $TableArea/CenterZone/IndicatorPanel/IndVBox/OkeyValue

@onready var _melds_panel: Control = $TableArea/MeldsPanel
@onready var _meld_island: Control = $TableArea/MeldsPanel/MeldIsland
@onready var _open_meter: Label = $TableArea/MeldsPanel/OpenMeter
@onready var _meld_hint: Label = $TableArea/MeldsPanel/MeldHint

@onready var _rack_panel: PanelContainer = $RackPanel
@onready var _row1: HBoxContainer = $RackPanel/RackContent/Row1
@onready var _row2: HBoxContainer = $RackPanel/RackContent/Row2

@onready var _my_discard: PanelContainer = $MyDiscard
@onready var _my_discard_stack: Control = $MyDiscard/DiscardContent/DiscardStack
@onready var _my_discard_count: Label = $MyDiscard/DiscardContent/DiscardCount
@onready var _my_discard_title: Label = $MyDiscard/DiscardContent/DiscardTitle

@onready var _action_bar: HBoxContainer = $ActionBar
@onready var _open_meter_bottom: Label = $ActionBar/OpenMeterBottom
@onready var _btn_end_play: Button = $ActionBar/EndPlayBtn
@onready var _btn_new_round: Button = $ActionBar/NewRoundBtn
@onready var _btn_menu: Button = $ActionBar/MenuBtn

# ─── Game logic ───
var _controller = LOCAL_CONTROLLER_SCRIPT.new()
var _controller_injected_external: bool = false
var _bot: BotHeuristic = BotHeuristic.new()
var _bot_fallback: BotRandom = BotRandom.new(7007)
var _rule_config: RuleConfig = null
var _game_seed: int = -1
var _player_count: int = 4
var _slots = RACK_SLOT_MANAGER.new()
var _draft_logic = STAGE_MELD_LOGIC.new()

# ─── Rack state ───
var _slot_controls: Array[Control] = []
var _draft_panel: Control = null
var _draft_row1: HBoxContainer = null
var _draft_row2: HBoxContainer = null
var _draft_slot_controls: Array[Control] = []
var _tile_controls: Dictionary = {}
var _hand_zoom: float = 0.94
var _slot_size: Vector2 = Vector2(52, 72)
var _round_index: int = 0

# ─── UI state ───
var _action_in_flight: bool = false
var _bot_loop_running: bool = false
var _round_dialog: AcceptDialog = null
var _round_controls: HBoxContainer = null
var _round_new_btn: Button = null
var _round_menu_btn: Button = null
var _meld_clusters: Array[Control] = []
var _last_draft_error: String = ""
var _rail_top: Panel = null
var _rail_left: Panel = null
var _rail_right: Panel = null
var _rail_bottom: Panel = null
var _board = null
var _ambient_time: float = 0.0
var _draw_card_style: StyleBoxFlat = null
var _indicator_card_style: StyleBoxFlat = null
var _rack_depth_shell: Panel = null
var _rack_depth_shell_style: StyleBoxFlat = null
var _rack_contact_shadow: Panel = null
var _rack_contact_shadow_style: StyleBoxFlat = null
var _discard_prompt: PanelContainer = null
var _discard_prompt_style: StyleBoxFlat = null
var _discard_prompt_base_pos: Vector2 = Vector2.ZERO
var _felt_cloth_texture: Texture2D = null
var _center_zone_base_position: Vector2 = Vector2.ZERO
var _opp_rack_base_positions: Array[Vector2] = []
var _opp_discard_base_positions: Array[Vector2] = []

# ─── Opponent UI (built in code) ───
var _opp_rack_panels: Array[PanelContainer] = []
var _opp_count_labels: Array[Label] = []
var _opp_discard_panels: Array[PanelContainer] = []
var _opp_discard_stacks: Array[Control] = []
var _opp_discard_counts: Array[Label] = []
var _opp_discard_glows: Array[Panel] = []
var _my_discard_glow: Panel = null
var _draw_stack_layers: Array[Panel] = []
var _indicator_stack_layers: Array[Panel] = []
var _draw_stack_visible_layers: int = 5
var _indicator_stack_visible_layers: int = 2
var _presentation_mode: String = "2d"
var _compat_stage_api_warned: Dictionary = {}

# ═══════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════

func _ready() -> void:
	# Fallback: when hosted inside GameTable3D's SubViewport, force 3D presentation
	# before any geometry/UI creation so rack construction path is correct.
	if _presentation_mode != "3d" and get_parent() is SubViewport:
		_presentation_mode = "3d"

	if GEO.SHOW_TABLE_RAILS:
		_create_table_rails()
	_board = BOARD_RENDERER.new()
	_board.name = "BoardRenderer"
	add_child(_board)
	_board.configure(_table_area)
	_board.create_board_geometry(GEO.SHOW_TABLE_RAILS, GEO.SHOW_WALL_RING)
	_apply_felt_style()
	_apply_art_direction()
	_create_center_stack_layers()
	_create_opponent_areas()
	_create_my_discard_glow()
	_create_rack_depth_shell()
	_create_rack_contact_shadow()
	_create_discard_prompt()
	_init_rack_slots()
	_init_draft_slots()
	_create_draft_area()
	_create_round_controls()

	_bind_controller_signals()

	_btn_new_round.pressed.connect(_start_round)
	_btn_menu.pressed.connect(_return_to_main_menu)
	_btn_end_play.pressed.connect(_on_end_play_pressed)

	_draw_deck.gui_input.connect(_on_deck_input)
	_my_discard.gui_input.connect(_on_my_discard_input)

	$TopBar.z_index = 20
	_table_area.z_index = 1
	_rack_panel.z_index = 12
	_my_discard.z_index = 13
	_action_bar.z_index = 14

	_table_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _felt_frame != null:
		# Legacy frame is disabled; board/felt are rendered by board geometry only.
		_felt_frame.visible = false
	_melds_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meld_island.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rack_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_row1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row2.visible = true
	_open_meter_bottom.visible = false
	_btn_end_play.visible = false
	# Keep gameplay interactions drag/tap only; hide the button bar to avoid overlap/hitbox conflicts.
	_action_bar.visible = false
	_action_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_my_discard_title.visible = false
	_my_discard_count.visible = false
	_apply_discard_zone_style(_my_discard)
	_apply_presentation_mode()
	set_process(true)

	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	if not _controller_injected_external:
		_start_round()
	else:
		_render_all()

func set_presentation_mode(mode: String) -> void:
	_presentation_mode = mode.to_lower()
	if is_inside_tree():
		_apply_presentation_mode()

func _apply_presentation_mode() -> void:
	var is_3d: bool = _presentation_mode == "3d"
	if _top_bar != null:
		_top_bar.visible = not is_3d
		_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE if is_3d else Control.MOUSE_FILTER_PASS
	for rack_panel in _opp_rack_panels:
		if rack_panel != null:
			rack_panel.visible = not is_3d
	# In 3D mode, hide player UI elements — GameTable3D renders these as 2D overlays.
	if is_3d:
		if _rack_panel != null:
			_rack_panel.visible = false
			_rack_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _action_bar != null:
			_action_bar.visible = false
			_action_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _draft_panel != null:
			_draft_panel.visible = false
		if _rack_depth_shell != null:
			_rack_depth_shell.visible = false
		if _rack_contact_shadow != null:
			_rack_contact_shadow.visible = false
		if _discard_prompt != null:
			_discard_prompt.visible = false
		if _my_discard != null:
			_my_discard.visible = false
		for dp in _opp_discard_panels:
			if dp != null:
				dp.visible = false
		if _my_discard_glow != null:
			_my_discard_glow.visible = false
		for g in _opp_discard_glows:
			if g != null:
				g.visible = false
		# Hide center zone — 3D mode renders deck/indicator as 3D objects
		if _center_zone != null:
			_center_zone.visible = false
	_style_center_cards()
	_style_rack_shell()
	for i in range(min(3, _opp_rack_panels.size())):
		if _opp_rack_panels[i] != null:
			_apply_opp_rack_style(_opp_rack_panels[i], i)
	_update_center_stack_visibility()
	call_deferred("_apply_responsive_layout")

# ═══════════════════════════════════════════
# OVERLAY API (used by GameTable3D for 2D overlay rendering)
# ═══════════════════════════════════════════

func inject_controller(controller) -> void:
	if controller == null:
		return
	_unbind_controller_signals()
	_controller = controller
	_controller_injected_external = true
	_bind_controller_signals()
	_action_in_flight = false
	if is_inside_tree():
		_render_all()

func get_controller():
	return _controller

func get_hand_tiles() -> Array:
	return _rack_hand()

func get_rack_slots() -> Array[int]:
	return _slots.rack_slots

func get_draft_slots() -> Array[int]:
	return _slots.draft_slots

func get_stage_slots() -> Array[int]:
	_warn_stage_api_once("get_stage_slots()", "get_draft_slots()")
	return get_draft_slots()

func _warn_stage_api_once(stage_api: String, draft_api: String) -> void:
	if _compat_stage_api_warned.has(stage_api):
		return
	_compat_stage_api_warned[stage_api] = true
	push_warning("%s is deprecated; use %s instead." % [stage_api, draft_api])

func get_draft_row_slots() -> int:
	return GEO.STAGE_ROW_SLOTS

func overlay_draw_from_deck() -> Dictionary:
	if not _is_my_turn() or _action_in_flight:
		return {"ok": false, "reason": "not_my_turn"}
	if _controller.state == null or _controller.state.phase != GameState.Phase.TURN_DRAW:
		return {"ok": false, "reason": "wrong_phase"}
	_action_in_flight = true
	var res: Dictionary = _controller.draw_from_deck(0)
	if not bool(res.get("ok", false)):
		_action_in_flight = false
	return res

func overlay_take_discard() -> Dictionary:
	if not _is_my_turn() or _action_in_flight:
		return {"ok": false, "reason": "not_my_turn"}
	if _controller.state == null or _controller.state.phase != GameState.Phase.TURN_DRAW:
		return {"ok": false, "reason": "wrong_phase"}
	if _controller.state.discard_pile.is_empty():
		return {"ok": false, "reason": "discard_empty"}
	_action_in_flight = true
	var res: Dictionary = _controller.take_discard(0)
	if not bool(res.get("ok", false)):
		_action_in_flight = false
	return res

func overlay_discard_tile(tile_id: int) -> Dictionary:
	if _action_in_flight or _controller.state == null:
		return {"ok": false, "reason": "busy"}
	if not _is_tile_in_my_hand(tile_id):
		return {"ok": false, "reason": "not_in_hand"}
	var phase: int = _controller.state.phase
	if phase != GameState.Phase.STARTER_DISCARD and phase != GameState.Phase.TURN_DISCARD:
		return {"ok": false, "reason": "wrong_phase"}
	_action_in_flight = true
	var result: Dictionary
	if phase == GameState.Phase.STARTER_DISCARD:
		result = _controller.starter_discard(0, tile_id)
	else:
		result = _controller.discard_tile(0, tile_id)
	if not bool(result.get("ok", false)):
		_action_in_flight = false
	return result

func overlay_end_play_then_discard(tile_id: int) -> Dictionary:
	if _action_in_flight or _controller.state == null:
		return {"ok": false, "reason": "busy"}
	if _controller.state.phase != GameState.Phase.TURN_PLAY:
		return {"ok": false, "reason": "wrong_phase"}
	# Submit any draft melds first
	if _has_draft_tiles():
		if not _submit_draft_melds():
			_restore_draft_to_rack()
			return {"ok": false, "reason": _last_draft_error}
	_action_in_flight = true
	var end_res: Dictionary = _controller.end_play_turn(0)
	if not bool(end_res.get("ok", false)):
		_action_in_flight = false
		return end_res
	_action_in_flight = true
	var discard_res: Dictionary = _controller.discard_tile(0, tile_id)
	if not bool(discard_res.get("ok", false)):
		_action_in_flight = false
	return discard_res

# Deprecated compatibility shim; retained for external/dynamic callers.
func overlay_end_play() -> Dictionary:
	if not _is_my_turn() or _action_in_flight:
		return {"ok": false, "reason": "not_my_turn"}
	if _controller.state == null or _controller.state.phase != GameState.Phase.TURN_PLAY:
		return {"ok": false, "reason": "wrong_phase"}
	_action_in_flight = true
	var res: Dictionary = _controller.end_play_turn(0)
	if not bool(res.get("ok", false)):
		_action_in_flight = false
	return res

# Deprecated compatibility shim; retained for external/dynamic callers.
func overlay_submit_staged() -> Dictionary:
	_warn_stage_api_once("overlay_submit_staged()", "_submit_draft_melds()")
	if not _is_my_turn() or _action_in_flight:
		return {"ok": false, "reason": "not_my_turn"}
	if not _submit_draft_melds():
		return {"ok": false, "reason": _last_draft_error}
	return {"ok": true}

func overlay_move_rack_to_draft(from_slot: int, to_draft_slot: int) -> Dictionary:
	if _action_in_flight:
		return {"ok": false, "reason": "busy"}
	if _controller.state == null:
		return {"ok": false, "reason": "no_state"}
	if not _is_my_turn():
		return {"ok": false, "reason": "not_my_turn"}
	if _controller.state.phase != GameState.Phase.TURN_PLAY:
		return {"ok": false, "reason": "wrong_phase"}
	if from_slot < 0 or from_slot >= _slots.rack_slots.size() or to_draft_slot < 0 or to_draft_slot >= _slots.draft_slots.size():
		return {"ok": false, "reason": "invalid_slot"}
	var tile_id: int = int(_slots.rack_slots[from_slot])
	if tile_id == -1:
		return {"ok": false, "reason": "empty_source"}
	var rack_before: Array = _slots.rack_slots.duplicate()
	var draft_before: Array = _slots.draft_slots.duplicate()
	_move_rack_to_draft(from_slot, to_draft_slot)
	if _slots.rack_slots == rack_before and _slots.draft_slots == draft_before:
		return {"ok": false, "reason": "no_change"}
	if _slots.draft_slots.find(tile_id) == -1:
		return {"ok": false, "reason": "move_failed"}
	return {"ok": true}

func overlay_move_rack_to_stage(from_slot: int, to_stage_slot: int) -> Dictionary:
	_warn_stage_api_once("overlay_move_rack_to_stage()", "overlay_move_rack_to_draft()")
	return overlay_move_rack_to_draft(from_slot, to_stage_slot)

func overlay_move_draft_to_rack(from_draft_slot: int, to_rack_slot: int) -> Dictionary:
	if _action_in_flight:
		return {"ok": false, "reason": "busy"}
	if _controller.state == null:
		return {"ok": false, "reason": "no_state"}
	if not _is_my_turn():
		return {"ok": false, "reason": "not_my_turn"}
	if _controller.state.phase != GameState.Phase.TURN_PLAY:
		return {"ok": false, "reason": "wrong_phase"}
	if from_draft_slot < 0 or from_draft_slot >= _slots.draft_slots.size() or to_rack_slot < 0 or to_rack_slot >= _slots.rack_slots.size():
		return {"ok": false, "reason": "invalid_slot"}
	var tile_id: int = int(_slots.draft_slots[from_draft_slot])
	if tile_id == -1:
		return {"ok": false, "reason": "empty_source"}
	var rack_before: Array = _slots.rack_slots.duplicate()
	var draft_before: Array = _slots.draft_slots.duplicate()
	_move_draft_to_rack(from_draft_slot, to_rack_slot)
	if _slots.rack_slots == rack_before and _slots.draft_slots == draft_before:
		return {"ok": false, "reason": "no_change"}
	if _slots.rack_slots.find(tile_id) == -1:
		return {"ok": false, "reason": "move_failed"}
	return {"ok": true}

func overlay_move_stage_to_rack(from_stage_slot: int, to_rack_slot: int) -> Dictionary:
	_warn_stage_api_once("overlay_move_stage_to_rack()", "overlay_move_draft_to_rack()")
	return overlay_move_draft_to_rack(from_stage_slot, to_rack_slot)

func overlay_move_slot(from_slot: int, to_slot: int) -> Dictionary:
	if _action_in_flight:
		return {"ok": false, "reason": "busy"}
	if _controller.state == null:
		return {"ok": false, "reason": "no_state"}
	if not _is_my_turn():
		return {"ok": false, "reason": "not_my_turn"}
	if not _can_overlay_rack_reorder_phase(int(_controller.state.phase)):
		return {"ok": false, "reason": "wrong_phase"}
	if from_slot < 0 or from_slot >= _slots.rack_slots.size() or to_slot < 0 or to_slot >= _slots.rack_slots.size():
		return {"ok": false, "reason": "invalid_slot"}
	if from_slot == to_slot:
		return {"ok": false, "reason": "no_change"}
	var tile_id: int = int(_slots.rack_slots[from_slot])
	if tile_id == -1:
		return {"ok": false, "reason": "empty_source"}
	var rack_before: Array = _slots.rack_slots.duplicate()
	_move_slot(from_slot, to_slot)
	if _slots.rack_slots == rack_before:
		return {"ok": false, "reason": "no_change"}
	if int(_slots.rack_slots[to_slot]) != tile_id:
		return {"ok": false, "reason": "move_failed"}
	return {"ok": true}

func overlay_move_draft_slot(from_draft_slot: int, to_draft_slot: int) -> Dictionary:
	if _action_in_flight:
		return {"ok": false, "reason": "busy"}
	if _controller.state == null:
		return {"ok": false, "reason": "no_state"}
	if not _is_my_turn():
		return {"ok": false, "reason": "not_my_turn"}
	if _controller.state.phase != GameState.Phase.TURN_PLAY:
		return {"ok": false, "reason": "wrong_phase"}
	if from_draft_slot < 0 or from_draft_slot >= _slots.draft_slots.size() or to_draft_slot < 0 or to_draft_slot >= _slots.draft_slots.size():
		return {"ok": false, "reason": "invalid_slot"}
	if from_draft_slot == to_draft_slot:
		return {"ok": false, "reason": "no_change"}
	var tile_id: int = int(_slots.draft_slots[from_draft_slot])
	if tile_id == -1:
		return {"ok": false, "reason": "empty_source"}
	var draft_before: Array = _slots.draft_slots.duplicate()
	_move_draft_slot(from_draft_slot, to_draft_slot)
	if _slots.draft_slots == draft_before:
		return {"ok": false, "reason": "no_change"}
	if int(_slots.draft_slots[to_draft_slot]) != tile_id:
		return {"ok": false, "reason": "move_failed"}
	return {"ok": true}

func overlay_move_stage_slot(from_stage_slot: int, to_stage_slot: int) -> Dictionary:
	_warn_stage_api_once("overlay_move_stage_slot()", "overlay_move_draft_slot()")
	return overlay_move_draft_slot(from_stage_slot, to_stage_slot)

func _can_overlay_rack_reorder_phase(phase: int) -> bool:
	return phase == GameState.Phase.STARTER_DISCARD \
		or phase == GameState.Phase.TURN_DRAW \
		or phase == GameState.Phase.TURN_PLAY \
		or phase == GameState.Phase.TURN_DISCARD

func overlay_add_to_meld(tile_ids: Array, meld_index: int) -> Dictionary:
	if _action_in_flight:
		return {"ok": false, "reason": "busy"}
	_action_in_flight = true
	var action: Action = Action.new(Action.ActionType.ADD_TO_MELD, {"target_meld_index": meld_index, "tile_ids": tile_ids})
	var result: Dictionary = _controller.apply_action_if_valid(0, action)
	if not bool(result.get("ok", false)):
		_action_in_flight = false
	return result

func overlay_new_round() -> void:
	if _controller_injected_external:
		var res: Dictionary = _controller.request_new_round()
		if not bool(res.get("ok", false)):
			_instructions.text = "Rejected: %s" % str(res.get("reason", "round restart unavailable"))
		return
	_start_round()

# Deprecated compatibility shim; retained for external/dynamic callers.
func overlay_return_to_menu() -> void:
	_return_to_main_menu()

# Deprecated compatibility shim; retained for external/dynamic callers.
func get_my_discard_global_rect() -> Rect2:
	if _my_discard == null:
		return Rect2()
	return _my_discard.get_global_rect()

# Deprecated compatibility shim; retained for external/dynamic callers.
func get_meld_island_global_rect() -> Rect2:
	if _meld_island == null:
		return Rect2()
	return _meld_island.get_global_rect()

func is_action_in_flight() -> bool:
	return _action_in_flight

# Deprecated compatibility shim; retained for external/dynamic callers.
func get_instruction_text() -> String:
	return _instructions.text if _instructions != null else ""


func _create_table_rails() -> void:
	_rail_top = Panel.new()
	_rail_left = Panel.new()
	_rail_right = Panel.new()
	_rail_bottom = Panel.new()
	_rail_top.name = "RailTop"
	_rail_left.name = "RailLeft"
	_rail_right.name = "RailRight"
	_rail_bottom.name = "RailBottom"
	_rail_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rail_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rail_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rail_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_rail_style(_rail_top, 0)
	_apply_rail_style(_rail_left, 1)
	_apply_rail_style(_rail_right, 1)
	_apply_rail_style(_rail_bottom, 2)
	_table_area.add_child(_rail_top)
	_table_area.add_child(_rail_left)
	_table_area.add_child(_rail_right)
	_table_area.add_child(_rail_bottom)
	# Keep rails behind interactive table content.
	_table_area.move_child(_rail_top, 0)
	_table_area.move_child(_rail_left, 0)
	_table_area.move_child(_rail_right, 0)
	_table_area.move_child(_rail_bottom, 0)

func _apply_rail_style(rail: Panel, strength: int) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.41, 0.24, 0.12, 0.64)
	if strength == 1:
		s.bg_color = Color(0.37, 0.22, 0.11, 0.52)
	elif strength == 2:
		s.bg_color = Color(0.45, 0.27, 0.14, 0.70)
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.23, 0.14, 0.08, 0.82)
	s.shadow_color = Color(0, 0, 0, 0.10)
	s.shadow_size = 1
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	rail.add_theme_stylebox_override("panel", s)

func _apply_felt_style() -> void:
	# Felt/table visuals are fully drawn by board polygons.
	# MeldsPanel is kept as a non-drawing layout container.
	if _melds_panel is Panel:
		var fs := StyleBoxEmpty.new()
		(_melds_panel as Panel).add_theme_stylebox_override("panel", fs)
	if _felt_cloth_texture == null:
		_felt_cloth_texture = ASSET_REGISTRY.texture(GEO.CLOTH_TEXTURE_ID)
	if _board != null and _felt_cloth_texture != null:
		_board.apply_felt_texture(_felt_cloth_texture)

func _apply_art_direction() -> void:
	_style_top_bar()
	_style_center_cards()
	_style_rack_shell()
	_open_meter.add_theme_color_override("font_color", Color(0.74, 0.90, 0.82, 0.86))
	_open_meter.add_theme_font_size_override("font_size", 13)
	_meld_hint.add_theme_color_override("font_color", Color(0.66, 0.86, 0.78, 0.26))
	_meld_hint.add_theme_font_size_override("font_size", 11)

func _style_top_bar() -> void:
	if _top_bar == null:
		return
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.28, 0.17, 0.10, 0.94)
	s.border_width_left = 0
	s.border_width_top = 0
	s.border_width_right = 0
	s.border_width_bottom = 2
	s.border_color = Color(0.58, 0.37, 0.20, 0.72)
	s.shadow_color = Color(0, 0, 0, 0.22)
	s.shadow_size = 2
	_top_bar.add_theme_stylebox_override("panel", s)
	if _top_hbox != null:
		_top_hbox.add_theme_constant_override("separation", 24)
	_instructions.add_theme_color_override("font_color", Color(1.0, 0.95, 0.84, 1.0))
	_instructions.add_theme_font_size_override("font_size", 24)
	_instructions.add_theme_color_override("font_outline_color", Color(0.18, 0.11, 0.07, 0.65))
	_instructions.add_theme_constant_override("outline_size", 2)
	_turn_label.add_theme_color_override("font_color", Color(0.93, 0.84, 0.66, 0.90))
	_turn_label.add_theme_font_size_override("font_size", 20)
	_turn_label.custom_minimum_size = Vector2(146, 0)
	_phase_label.add_theme_color_override("font_color", Color(0.90, 0.82, 0.62, 0.90))
	_phase_label.add_theme_font_size_override("font_size", 20)
	_phase_label.custom_minimum_size = Vector2(90, 0)
	_deck_count_top.add_theme_color_override("font_color", Color(0.90, 0.82, 0.62, 0.88))
	_deck_count_top.add_theme_font_size_override("font_size", 20)
	_deck_count_top.custom_minimum_size = Vector2(108, 0)
	_okey_info_top.add_theme_color_override("font_color", Color(0.98, 0.75, 0.34, 1.0))
	_okey_info_top.add_theme_font_size_override("font_size", 20)
	_okey_info_top.custom_minimum_size = Vector2(128, 0)

func _style_center_cards() -> void:
	var is_3d: bool = _presentation_mode == "3d"
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.96, 0.93, 0.86, 0.98)
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 2 if is_3d else 3
	card_style.border_color = Color(0.56, 0.44, 0.28, 0.92)
	card_style.corner_radius_top_left = 8 if is_3d else 10
	card_style.corner_radius_top_right = 8 if is_3d else 10
	card_style.corner_radius_bottom_left = 8 if is_3d else 10
	card_style.corner_radius_bottom_right = 8 if is_3d else 10
	card_style.shadow_color = Color(0, 0, 0, 0.30) if is_3d else Color(0, 0, 0, 0.27)
	card_style.shadow_size = 4 if is_3d else 5
	card_style.content_margin_left = 5.0 if is_3d else 7.0
	card_style.content_margin_right = 5.0 if is_3d else 7.0
	card_style.content_margin_top = 5.0 if is_3d else 7.0
	card_style.content_margin_bottom = 5.0 if is_3d else 7.0
	_center_zone.add_theme_constant_override("separation", 12 if is_3d else 18)
	_draw_deck.custom_minimum_size = Vector2(64, 86) if is_3d else Vector2(96, 122)
	_indicator_panel.custom_minimum_size = Vector2(60, 82) if is_3d else Vector2(96, 122)
	_draw_card_style = card_style
	_indicator_card_style = card_style.duplicate()
	_draw_deck.z_index = 10 if is_3d else 0
	_indicator_panel.z_index = 10 if is_3d else 0
	_draw_deck.add_theme_stylebox_override("panel", _draw_card_style)
	_indicator_panel.add_theme_stylebox_override("panel", _indicator_card_style)
	_deck_title.add_theme_color_override("font_color", Color(0.33, 0.26, 0.19, 0.70))
	_ind_title.add_theme_color_override("font_color", Color(0.33, 0.26, 0.19, 0.70))
	_deck_title.add_theme_font_size_override("font_size", 9 if is_3d else 12)
	_ind_title.add_theme_font_size_override("font_size", 9 if is_3d else 11)
	_deck_num.add_theme_color_override("font_color", Color(0.21, 0.16, 0.12, 0.95))
	_ind_value.add_theme_color_override("font_color", Color(0.21, 0.16, 0.12, 0.95))
	_okey_value.add_theme_color_override("font_color", Color(0.78, 0.31, 0.12, 0.95))
	_deck_num.add_theme_font_size_override("font_size", 18 if is_3d else 32)
	_ind_value.add_theme_font_size_override("font_size", 16 if is_3d else 28)
	_okey_value.add_theme_font_size_override("font_size", 9 if is_3d else 14)

func _create_center_stack_layers() -> void:
	_draw_stack_layers = _make_center_stack_layers("DrawDeckStack", 8)
	_indicator_stack_layers = _make_center_stack_layers("IndicatorStack", 5)
	_update_center_stack_visibility()
	_refresh_center_stack_positions()

func _make_center_stack_layers(prefix: String, layer_count: int) -> Array[Panel]:
	var out: Array[Panel] = []
	if _table_area == null:
		return out
	var stale: Array[Node] = []
	for child in _table_area.get_children():
		if child is Panel and String(child.name).begins_with(prefix):
			stale.append(child)
	for node in stale:
		_table_area.remove_child(node)
		node.queue_free()
	for i in range(layer_count):
		var layer := Panel.new()
		layer.name = "%s%d" % [prefix, i]
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.z_index = 8
		var depth: float = float(layer_count - i)
		var tint: float = clamp(0.02 * depth, 0.0, 0.12)
		var ss := StyleBoxFlat.new()
		ss.bg_color = Color(0.86 - tint, 0.76 - tint, 0.60 - tint * 0.85, 0.94 - depth * 0.035)
		ss.border_width_left = 1
		ss.border_width_top = 1
		ss.border_width_right = 1
		ss.border_width_bottom = 2
		ss.border_color = Color(0.41, 0.29, 0.18, 0.92)
		ss.corner_radius_top_left = 8
		ss.corner_radius_top_right = 8
		ss.corner_radius_bottom_left = 8
		ss.corner_radius_bottom_right = 8
		ss.shadow_color = Color(0, 0, 0, 0.20)
		ss.shadow_size = 2
		layer.add_theme_stylebox_override("panel", ss)
		_table_area.add_child(layer)
		_table_area.move_child(layer, 1)
		out.append(layer)
	return out

func _update_center_stack_visibility() -> void:
	var is_3d: bool = _presentation_mode == "3d"
	for i in range(_draw_stack_layers.size()):
		var layer: Panel = _draw_stack_layers[i]
		if layer != null and is_instance_valid(layer):
			layer.visible = is_3d and i < _draw_stack_visible_layers
	for i in range(_indicator_stack_layers.size()):
		var layer: Panel = _indicator_stack_layers[i]
		if layer != null and is_instance_valid(layer):
			layer.visible = is_3d and i < _indicator_stack_visible_layers

func _refresh_center_stack_positions() -> void:
	if _table_area == null:
		return
	if _draw_deck != null and is_instance_valid(_draw_deck):
		_position_stack_layers(_draw_stack_layers, _draw_deck, _draw_stack_visible_layers)
	if _indicator_panel != null and is_instance_valid(_indicator_panel):
		_position_stack_layers(_indicator_stack_layers, _indicator_panel, _indicator_stack_visible_layers)

func _position_stack_layers(layers: Array[Panel], card: PanelContainer, depth_count: int) -> void:
	if layers.is_empty() or card == null or _table_area == null or depth_count <= 0:
		return
	var base_pos: Vector2 = card.global_position - _table_area.global_position
	var base_size: Vector2 = card.size
	var visible_count: int = mini(depth_count, layers.size())
	var is_draw_stack: bool = card == _draw_deck
	var is_3d: bool = _presentation_mode == "3d"
	var width_step: float = 3.4 if (is_3d and is_draw_stack) else (2.2 if is_3d else (3.0 if is_draw_stack else 2.6))
	var height_step: float = 2.3 if (is_3d and is_draw_stack) else (1.6 if is_3d else (2.2 if is_draw_stack else 1.8))
	var x_step: float = 1.4 if (is_3d and is_draw_stack) else (0.9 if is_3d else (1.2 if is_draw_stack else 0.9))
	var y_step: float = 2.4 if (is_3d and is_draw_stack) else (1.6 if is_3d else (2.1 if is_draw_stack else 1.8))
	for i in range(visible_count):
		var layer: Panel = layers[i]
		if layer == null or not is_instance_valid(layer):
			continue
		var depth: float = float(visible_count - i)
		var w: float = base_size.x + depth * width_step
		var h: float = base_size.y + depth * height_step
		layer.custom_minimum_size = Vector2(w, h)
		layer.size = Vector2(w, h)
		var base_shift: Vector2 = Vector2(-1.6, -2.4) if is_3d else Vector2(-1.8, -2.6)
		layer.position = base_pos + base_shift + Vector2(-depth * x_step, -depth * y_step)
		layer.z_index = max(1, card.z_index - (visible_count - i))

func _style_rack_shell() -> void:
	var is_3d: bool = _presentation_mode == "3d"
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color(0.45, 0.31, 0.18, 0.98) if is_3d else Color(0.40, 0.27, 0.16, 0.98)
	rs.border_width_left = 2
	rs.border_width_top = 2 if is_3d else 3
	rs.border_width_right = 2
	rs.border_width_bottom = 9 if is_3d else 5
	rs.border_color = Color(0.23, 0.15, 0.09, 0.96)
	rs.shadow_color = Color(0, 0, 0, 0.46) if is_3d else Color(0, 0, 0, 0.34)
	rs.shadow_size = 10 if is_3d else 4
	rs.corner_radius_top_left = 10
	rs.corner_radius_top_right = 10
	rs.corner_radius_bottom_left = 10
	rs.corner_radius_bottom_right = 10
	rs.content_margin_left = 11 if is_3d else 12
	rs.content_margin_right = 11 if is_3d else 12
	rs.content_margin_top = 9 if is_3d else 9
	rs.content_margin_bottom = 9 if is_3d else 9
	_rack_panel.add_theme_stylebox_override("panel", rs)
	_row1.add_theme_constant_override("separation", 4 if is_3d else 5)
	_row2.add_theme_constant_override("separation", 5)

func _create_rack_depth_shell() -> void:
	_rack_depth_shell = Panel.new()
	_rack_depth_shell.name = "RackDepthShell"
	_rack_depth_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rack_depth_shell.z_index = 10
	_rack_depth_shell.visible = false
	_rack_depth_shell_style = StyleBoxFlat.new()
	_rack_depth_shell_style.bg_color = Color(0.19, 0.12, 0.07, 0.84)
	_rack_depth_shell_style.border_width_left = 1
	_rack_depth_shell_style.border_width_top = 1
	_rack_depth_shell_style.border_width_right = 1
	_rack_depth_shell_style.border_width_bottom = 3
	_rack_depth_shell_style.border_color = Color(0.11, 0.07, 0.04, 0.88)
	_rack_depth_shell_style.corner_radius_top_left = 10
	_rack_depth_shell_style.corner_radius_top_right = 10
	_rack_depth_shell_style.corner_radius_bottom_left = 10
	_rack_depth_shell_style.corner_radius_bottom_right = 10
	_rack_depth_shell_style.shadow_color = Color(0, 0, 0, 0.40)
	_rack_depth_shell_style.shadow_size = 8
	_rack_depth_shell.add_theme_stylebox_override("panel", _rack_depth_shell_style)
	add_child(_rack_depth_shell)

func configure_game(rule_config: RuleConfig, game_seed: int, player_count: int) -> void:
	_rule_config = rule_config
	_game_seed = game_seed
	_player_count = player_count

# ═══════════════════════════════════════════
# OPPONENT AREAS (dynamic, positioned in TableArea)
# ═══════════════════════════════════════════

func _create_opponent_areas() -> void:
	var opp_names: Array[String] = ["Bot 1", "Bot 2", "Bot 3"]
	var is_3d: bool = _presentation_mode == "3d"

	for i in range(3):
		var player_index: int = i + 1

		# Opponent badge
		var rack := PanelContainer.new()
		rack.name = "OppRack%d" % player_index
		_apply_opp_rack_style(rack, i)
		_set_anchors(rack, [0.0, 0.0, 0.0, 0.0])
		rack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rack.z_index = 6 if i != 1 else 5
		_table_area.add_child(rack)

		var count_lbl := Label.new()
		count_lbl.visible = false
		if is_3d:
			var rack_shadow := Panel.new()
			rack_shadow.name = "RackShadow"
			rack_shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
			rack_shadow.offset_left = 5.0
			rack_shadow.offset_top = 7.0
			rack_shadow.offset_right = -5.0
			rack_shadow.offset_bottom = 3.0
			rack_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var shadow_style := StyleBoxFlat.new()
			shadow_style.bg_color = Color(0, 0, 0, 0.32)
			shadow_style.corner_radius_top_left = 8
			shadow_style.corner_radius_top_right = 8
			shadow_style.corner_radius_bottom_left = 8
			shadow_style.corner_radius_bottom_right = 8
			rack_shadow.add_theme_stylebox_override("panel", shadow_style)
			rack.add_child(rack_shadow)

			var rack_body := Panel.new()
			rack_body.name = "RackBody"
			rack_body.set_anchors_preset(Control.PRESET_FULL_RECT)
			rack_body.offset_left = 8.0
			rack_body.offset_top = 2.0
			rack_body.offset_right = -8.0
			rack_body.offset_bottom = -11.0
			rack_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var body_style := StyleBoxFlat.new()
			body_style.bg_color = Color(0.50, 0.33, 0.18, 0.96)
			body_style.border_width_left = 1
			body_style.border_width_top = 1
			body_style.border_width_right = 1
			body_style.border_width_bottom = 2
			body_style.border_color = Color(0.24, 0.15, 0.09, 0.84)
			body_style.corner_radius_top_left = 7
			body_style.corner_radius_top_right = 7
			body_style.corner_radius_bottom_left = 4
			body_style.corner_radius_bottom_right = 4
			body_style.shadow_color = Color(0, 0, 0, 0.20)
			body_style.shadow_size = 2
			rack_body.add_theme_stylebox_override("panel", body_style)
			rack.add_child(rack_body)

			var rack_groove := Panel.new()
			rack_groove.name = "RackGroove"
			rack_groove.anchor_left = 0.0
			rack_groove.anchor_top = 0.5
			rack_groove.anchor_right = 1.0
			rack_groove.anchor_bottom = 0.5
			rack_groove.offset_left = 14.0
			rack_groove.offset_top = -2.0
			rack_groove.offset_right = -14.0
			rack_groove.offset_bottom = 2.0
			rack_groove.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var groove_style := StyleBoxFlat.new()
			groove_style.bg_color = Color(0.18, 0.10, 0.05, 0.56)
			groove_style.corner_radius_top_left = 2
			groove_style.corner_radius_top_right = 2
			groove_style.corner_radius_bottom_left = 2
			groove_style.corner_radius_bottom_right = 2
			rack_groove.add_theme_stylebox_override("panel", groove_style)
			rack.add_child(rack_groove)

			var rack_lip := Panel.new()
			rack_lip.name = "RackLip"
			rack_lip.anchor_left = 0.0
			rack_lip.anchor_top = 1.0
			rack_lip.anchor_right = 1.0
			rack_lip.anchor_bottom = 1.0
			rack_lip.offset_left = 7.0
			rack_lip.offset_top = -11.0
			rack_lip.offset_right = -7.0
			rack_lip.offset_bottom = -3.0
			rack_lip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var lip_style := StyleBoxFlat.new()
			lip_style.bg_color = Color(0.30, 0.18, 0.10, 0.98)
			lip_style.border_width_top = 1
			lip_style.border_color = Color(0.56, 0.36, 0.22, 0.72)
			lip_style.corner_radius_top_left = 4
			lip_style.corner_radius_top_right = 4
			lip_style.corner_radius_bottom_left = 4
			lip_style.corner_radius_bottom_right = 4
			rack_lip.add_theme_stylebox_override("panel", lip_style)
			rack.add_child(rack_lip)
		else:
			var rack_vbox := VBoxContainer.new()
			rack_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			rack_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rack_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			rack_vbox.add_theme_constant_override("separation", 3)
			rack.add_child(rack_vbox)

			var name_lbl := Label.new()
			name_lbl.text = opp_names[i]
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_lbl.add_theme_color_override("font_color", Color(0.91, 0.92, 0.95, 0.70))
			name_lbl.add_theme_font_size_override("font_size", 11)
			rack_vbox.add_child(name_lbl)

			var rack_face := PanelContainer.new()
			rack_face.custom_minimum_size = Vector2(0, 36)
			rack_face.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rack_face.size_flags_vertical = Control.SIZE_FILL
			rack_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var face_style := StyleBoxFlat.new()
			face_style.bg_color = GEO.OPP_COLORS[i].darkened(0.84)
			face_style.bg_color.a = 0.42
			face_style.border_width_left = 1
			face_style.border_width_top = 1
			face_style.border_width_right = 1
			face_style.border_width_bottom = 2
			face_style.border_color = GEO.OPP_COLORS[i].lightened(0.16)
			face_style.border_color.a = 0.45
			face_style.corner_radius_top_left = 6
			face_style.corner_radius_top_right = 6
			face_style.corner_radius_bottom_left = 6
			face_style.corner_radius_bottom_right = 6
			face_style.content_margin_left = 4
			face_style.content_margin_right = 4
			face_style.content_margin_top = 3
			face_style.content_margin_bottom = 4
			rack_face.add_theme_stylebox_override("panel", face_style)
			rack_vbox.add_child(rack_face)

			var face_rows := VBoxContainer.new()
			face_rows.alignment = BoxContainer.ALIGNMENT_CENTER
			face_rows.add_theme_constant_override("separation", 1)
			rack_face.add_child(face_rows)

			var back_style := StyleBoxFlat.new()
			back_style.bg_color = Color(0.95, 0.91, 0.83, 0.62)
			back_style.border_width_left = 1
			back_style.border_width_top = 1
			back_style.border_width_right = 1
			back_style.border_width_bottom = 1
			back_style.border_color = Color(0.57, 0.47, 0.30, 0.52)
			back_style.corner_radius_top_left = 2
			back_style.corner_radius_top_right = 2
			back_style.corner_radius_bottom_left = 2
			back_style.corner_radius_bottom_right = 2

			for row_idx in range(2):
				var rack_backs := HBoxContainer.new()
				rack_backs.alignment = BoxContainer.ALIGNMENT_CENTER
				rack_backs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				rack_backs.add_theme_constant_override("separation", 1)
				face_rows.add_child(rack_backs)
				var tile_count: int = 11 if row_idx == 0 else 10
				for j in range(tile_count):
					var back := Panel.new()
					back.custom_minimum_size = Vector2(10, 13)
					back.mouse_filter = Control.MOUSE_FILTER_IGNORE
					back.add_theme_stylebox_override("panel", back_style.duplicate())
					var center_j: float = (float(tile_count) - 1.0) * 0.5
					var depth_alpha: float = 0.54 + (1.0 - abs(float(j) - center_j) / max(1.0, float(tile_count) * 0.5)) * 0.34
					back.modulate = Color(1, 1, 1, clamp(depth_alpha, 0.46, 0.96))
					rack_backs.add_child(back)

			count_lbl.text = "21 tiles"
			count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			count_lbl.add_theme_color_override("font_color", Color(0.99, 0.97, 0.94, 0.84))
			count_lbl.add_theme_font_size_override("font_size", 14)
			count_lbl.visible = true
			rack_vbox.add_child(count_lbl)

		_opp_rack_panels.append(rack)
		_opp_count_labels.append(count_lbl)

		# Corner discard placeholder
		var discard := PanelContainer.new()
		discard.name = "OppDiscard%d" % player_index
		_apply_discard_zone_style(discard)
		_set_anchors(discard, [0.0, 0.0, 0.0, 0.0])
		discard.mouse_filter = Control.MOUSE_FILTER_STOP
		discard.z_index = 7 if i != 1 else 6
		var pi: int = player_index
		discard.gui_input.connect(func(event: InputEvent): _on_opp_discard_input(pi, event))
		_table_area.add_child(discard)

		var disc_vbox := VBoxContainer.new()
		disc_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		disc_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		disc_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		discard.add_child(disc_vbox)

		var disc_hint := Label.new()
		disc_hint.text = "..."
		disc_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		disc_hint.add_theme_color_override("font_color", Color(0.62, 0.82, 0.90, 0.46))
		disc_hint.add_theme_font_size_override("font_size", 10)
		disc_vbox.add_child(disc_hint)

		var disc_stack := Control.new()
		disc_stack.name = "Stack"
		disc_stack.custom_minimum_size = Vector2(42, 56)
		disc_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		disc_vbox.add_child(disc_stack)

		var disc_count := Label.new()
		disc_count.text = ""
		disc_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		disc_count.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 0.7))
		disc_count.add_theme_font_size_override("font_size", 10)
		disc_count.visible = false
		disc_vbox.add_child(disc_count)

		# Glow overlay
		var glow := Panel.new()
		glow.name = "Glow"
		glow.set_anchors_preset(Control.PRESET_FULL_RECT)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.visible = false
		var gs := StyleBoxFlat.new()
		gs.bg_color = Color(0.95, 0.76, 0.24, 0.16)
		gs.border_width_left = 3; gs.border_width_top = 3
		gs.border_width_right = 3; gs.border_width_bottom = 3
		gs.border_color = Color(0.98, 0.82, 0.31, 0.78)
		gs.corner_radius_top_left = 8; gs.corner_radius_top_right = 8
		gs.corner_radius_bottom_left = 8; gs.corner_radius_bottom_right = 8
		glow.add_theme_stylebox_override("panel", gs)
		discard.add_child(glow)

		_opp_discard_panels.append(discard)
		_opp_discard_stacks.append(disc_stack)
		_opp_discard_counts.append(disc_count)
		_opp_discard_glows.append(glow)
		_opp_rack_base_positions.append(Vector2.ZERO)
		_opp_discard_base_positions.append(Vector2.ZERO)

func _create_my_discard_glow() -> void:
	_my_discard_glow = Panel.new()
	_my_discard_glow.name = "MyGlow"
	_my_discard_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_my_discard_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_my_discard_glow.visible = false
	var gs := StyleBoxFlat.new()
	gs.bg_color = Color(0.95, 0.76, 0.24, 0.16)
	gs.border_width_left = 3; gs.border_width_top = 3
	gs.border_width_right = 3; gs.border_width_bottom = 3
	gs.border_color = Color(0.98, 0.82, 0.31, 0.78)
	gs.corner_radius_top_left = 8; gs.corner_radius_top_right = 8
	gs.corner_radius_bottom_left = 8; gs.corner_radius_bottom_right = 8
	_my_discard_glow.add_theme_stylebox_override("panel", gs)
	_my_discard.add_child(_my_discard_glow)

func _create_rack_contact_shadow() -> void:
	_rack_contact_shadow = Panel.new()
	_rack_contact_shadow.name = "RackContactShadow"
	_rack_contact_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rack_contact_shadow.z_index = 11
	_rack_contact_shadow_style = StyleBoxFlat.new()
	_rack_contact_shadow_style.bg_color = Color(0, 0, 0, 0.24)
	_rack_contact_shadow_style.shadow_color = Color(0, 0, 0, 0.22)
	_rack_contact_shadow_style.shadow_size = 14
	_rack_contact_shadow_style.corner_radius_top_left = 22
	_rack_contact_shadow_style.corner_radius_top_right = 22
	_rack_contact_shadow_style.corner_radius_bottom_left = 22
	_rack_contact_shadow_style.corner_radius_bottom_right = 22
	_rack_contact_shadow.add_theme_stylebox_override("panel", _rack_contact_shadow_style)
	add_child(_rack_contact_shadow)

func _create_discard_prompt() -> void:
	_discard_prompt = PanelContainer.new()
	_discard_prompt.name = "DiscardPrompt"
	_discard_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_discard_prompt.visible = false
	_discard_prompt.z_index = 18
	_discard_prompt_style = StyleBoxFlat.new()
	_discard_prompt_style.bg_color = Color(0.95, 0.74, 0.24, 0.18)
	_discard_prompt_style.border_width_left = 1
	_discard_prompt_style.border_width_top = 1
	_discard_prompt_style.border_width_right = 1
	_discard_prompt_style.border_width_bottom = 2
	_discard_prompt_style.border_color = Color(0.99, 0.84, 0.34, 0.92)
	_discard_prompt_style.corner_radius_top_left = 9
	_discard_prompt_style.corner_radius_top_right = 9
	_discard_prompt_style.corner_radius_bottom_left = 9
	_discard_prompt_style.corner_radius_bottom_right = 9
	_discard_prompt_style.shadow_color = Color(0, 0, 0, 0.20)
	_discard_prompt_style.shadow_size = 3
	_discard_prompt_style.content_margin_left = 8
	_discard_prompt_style.content_margin_right = 8
	_discard_prompt_style.content_margin_top = 2
	_discard_prompt_style.content_margin_bottom = 2
	_discard_prompt.add_theme_stylebox_override("panel", _discard_prompt_style)

	var prompt_label := Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	prompt_label.text = "Drop To Discard"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 12)
	prompt_label.add_theme_color_override("font_color", Color(0.22, 0.15, 0.08, 0.95))
	_discard_prompt.add_child(prompt_label)
	add_child(_discard_prompt)

func _apply_opp_rack_style(panel: PanelContainer, opp_idx: int) -> void:
	var s := StyleBoxFlat.new()
	var is_3d: bool = _presentation_mode == "3d"
	s.bg_color = Color(0, 0, 0, 0) if is_3d else GEO.OPP_COLORS[opp_idx].darkened(0.72)
	s.border_width_left = 0 if is_3d else 2
	s.border_width_top = 0 if is_3d else 2
	s.border_width_right = 0 if is_3d else 2
	s.border_width_bottom = 0 if is_3d else 4
	s.border_color = GEO.OPP_COLORS[opp_idx].darkened(0.08) if is_3d else GEO.OPP_COLORS[opp_idx].lightened(0.14)
	s.border_color.a = 0.0 if is_3d else 0.64
	s.shadow_color = Color(0, 0, 0, 0.0) if is_3d else Color(0, 0, 0, 0.24)
	s.shadow_size = 0 if is_3d else 5
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.content_margin_left = 0 if is_3d else 8
	s.content_margin_right = 0 if is_3d else 8
	s.content_margin_top = 0 if is_3d else 5
	s.content_margin_bottom = 0 if is_3d else 6
	panel.add_theme_stylebox_override("panel", s)

func _apply_discard_zone_style(panel: PanelContainer) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.14, 0.10, 0.12)
	s.border_width_left = 2; s.border_width_top = 2
	s.border_width_right = 2; s.border_width_bottom = 2
	s.border_color = Color(0.58, 0.82, 0.64, 0.52)
	s.border_blend = true
	s.shadow_color = Color(0, 0, 0, 0.22)
	s.shadow_size = 3
	s.corner_radius_top_left = 10; s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10; s.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", s)

func _set_anchors(node: Control, a: Array) -> void:
	node.anchor_left = a[0]
	node.anchor_top = a[1]
	node.anchor_right = a[2]
	node.anchor_bottom = a[3]

# ═══════════════════════════════════════════
# ROUND MANAGEMENT
# ═══════════════════════════════════════════

func _start_round() -> void:
	var cfg: RuleConfig = _rule_config if _rule_config != null else RuleConfig.new()
	var round_seed: int = GEO.compute_round_seed(_game_seed, _round_index)
	if _controller_injected_external:
		return
	_controller.start_new_round(cfg, round_seed, _player_count)
	_round_index += 1
	_slots.last_tile_id = -1
	_clear_draft_slots()
	_action_in_flight = false
	_render_all()
	_maybe_auto_bot_turn()

func _on_state_changed(_new_state) -> void:
	_action_in_flight = false
	_render_all()
	if _controller.state == null:
		return
	if _controller.state.phase == GameState.Phase.ROUND_END:
		_show_round_end_dialog()
		return
	call_deferred("_maybe_auto_bot_turn")

func _on_action_rejected(reason: String) -> void:
	_action_in_flight = false
	_instructions.text = "Rejected: %s" % reason

func _on_action_applied(_player_index: int, _action_type: int) -> void:
	_render_all()

# ═══════════════════════════════════════════
# INPUT HANDLING
# ═══════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if not mb.pressed:
			return
		var ctrl_down: bool = mb.ctrl_pressed or Input.is_key_pressed(KEY_CTRL)
		if not ctrl_down:
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_hand_zoom = clamp(_hand_zoom + 0.06, 0.75, 1.3)
			_render_rack()
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_hand_zoom = clamp(_hand_zoom - 0.06, 0.75, 1.3)
			_render_rack()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_update_ambient_fx(delta)

func _update_ambient_fx(delta: float) -> void:
	_ambient_time += delta
	if _board != null:
		_board.tick_ambient(delta)
	var pulse_fast: float = 0.5 + 0.5 * sin(_ambient_time * GEO.AMBIENT_PULSE_SPEED)
	var pulse_slow: float = 0.5 + 0.5 * sin(_ambient_time * GEO.AMBIENT_DRIFT_SPEED + 0.9)
	if _rack_contact_shadow != null:
		_rack_contact_shadow.modulate = Color(1, 1, 1, 0.86 + pulse_slow * 0.12)

	if _center_zone != null:
		var center_drift := Vector2(sin(_ambient_time * 0.72) * 1.5, cos(_ambient_time * 0.83 + 0.3) * 0.9)
		_center_zone.position = _center_zone_base_position + center_drift
		if _presentation_mode == "3d":
			_refresh_center_stack_positions()

	for i in range(min(_opp_rack_panels.size(), _opp_rack_base_positions.size())):
		var rack_panel: PanelContainer = _opp_rack_panels[i]
		if rack_panel == null or not is_instance_valid(rack_panel) or rack_panel.size.x <= 0.0:
			continue
		var base_rack: Vector2 = _opp_rack_base_positions[i]
		var p: float = _ambient_time * (0.60 + float(i) * 0.07) + float(i) * 1.4
		var drift: Vector2 = Vector2(0.0, sin(p) * 0.55)
		if i == 0:
			drift.x = -0.35 + cos(p * 1.22) * 0.30
		elif i == 2:
			drift.x = 0.35 + cos(p * 1.18) * 0.30
		rack_panel.position = base_rack + drift

	for i in range(min(_opp_discard_panels.size(), _opp_discard_base_positions.size())):
		var discard_panel: PanelContainer = _opp_discard_panels[i]
		if discard_panel == null or not is_instance_valid(discard_panel) or discard_panel.size.x <= 0.0:
			continue
		var base_disc: Vector2 = _opp_discard_base_positions[i]
		var q: float = _ambient_time * (0.72 + float(i) * 0.09) + float(i) * 1.1
		var drift_disc := Vector2(cos(q) * 0.35, sin(q * 0.92) * 0.45)
		discard_panel.position = base_disc + drift_disc

	if _controller.state == null:
		if _discard_prompt != null:
			_discard_prompt.visible = false
		return

	var my_turn: bool = _is_my_turn()
	var phase: int = _controller.state.phase
	var draw_focus: bool = my_turn and phase == GameState.Phase.TURN_DRAW
	var play_focus: bool = my_turn and phase == GameState.Phase.TURN_PLAY
	var discard_focus: bool = my_turn and (phase == GameState.Phase.STARTER_DISCARD or phase == GameState.Phase.TURN_DISCARD)
	var prev_discard_idx: int = -1
	if draw_focus and not _controller.state.discard_pile.is_empty():
		prev_discard_idx = _prev_player(0) - 1

	# Keep phase cues strictly truthful every frame.
	if _my_discard_glow != null:
		_my_discard_glow.visible = discard_focus
	for i in range(_opp_discard_glows.size()):
		var g: Panel = _opp_discard_glows[i]
		if g == null:
			continue
		g.visible = draw_focus and i == prev_discard_idx
	for i in range(_opp_discard_panels.size()):
		var pdis: PanelContainer = _opp_discard_panels[i]
		if pdis == null:
			continue
		if draw_focus:
			pdis.modulate = Color(1, 1, 1, 1.0) if i == prev_discard_idx else Color(1, 1, 1, 0.86)
		else:
			pdis.modulate = Color(1, 1, 1, 1.0)

	if _draw_card_style != null:
		var draw_border_idle: Color = Color(0.56, 0.44, 0.28, 0.92)
		var draw_border_hot: Color = Color(0.86, 0.66, 0.36, 0.97)
		_draw_card_style.border_color = draw_border_hot.lerp(draw_border_idle, 0.72 - pulse_fast * 0.32) if draw_focus else draw_border_idle
		_draw_card_style.shadow_color = Color(0, 0, 0, 0.24 + pulse_fast * 0.10) if draw_focus else Color(0, 0, 0, 0.23)
	if _indicator_card_style != null:
		var ind_border_idle: Color = Color(0.56, 0.44, 0.28, 0.92)
		var ind_border_hot: Color = Color(0.94, 0.74, 0.41, 0.98)
		_indicator_card_style.border_color = ind_border_hot.lerp(ind_border_idle, 0.76 - pulse_slow * 0.28) if draw_focus else ind_border_idle
		_indicator_card_style.shadow_color = Color(0, 0, 0, 0.23 + pulse_slow * 0.10) if draw_focus else Color(0, 0, 0, 0.23)

	_center_zone.modulate = Color(1, 1, 1, 0.97 + pulse_slow * 0.03) if play_focus else Color(1, 1, 1, 1)
	_okey_info_top.modulate = Color(1, 1, 1, 0.92 + pulse_slow * 0.08)
	_instructions.modulate = Color(1, 1, 1, 0.98 + pulse_fast * 0.02)
	if _discard_prompt != null:
		_discard_prompt.visible = discard_focus
		if discard_focus:
			var bob: float = sin(_ambient_time * 4.20) * 1.9
			_discard_prompt.position = _discard_prompt_base_pos + Vector2(0, bob)
			_discard_prompt.modulate = Color(1, 1, 1, 0.80 + pulse_fast * 0.20)
			if _discard_prompt_style != null:
				_discard_prompt_style.bg_color = Color(0.95, 0.74, 0.24, 0.16 + pulse_fast * 0.10)
				_discard_prompt_style.border_color = Color(0.99, 0.84, 0.34, 0.80 + pulse_fast * 0.20)
	if _my_discard != null:
		if discard_focus:
			_my_discard.modulate = Color(1, 1, 1, 0.97 + pulse_fast * 0.03)
		elif draw_focus:
			_my_discard.modulate = Color(1, 1, 1, 0.86)
		else:
			_my_discard.modulate = Color(1, 1, 1, 1)

	if _my_discard_glow != null and _my_discard_glow.visible:
		_my_discard_glow.modulate = Color(1, 1, 1, 0.82 + pulse_fast * 0.34)
	for glow in _opp_discard_glows:
		if glow != null and glow.visible:
			glow.modulate = Color(1, 1, 1, 0.66 + pulse_fast * 0.30)

func _on_deck_input(event: InputEvent) -> void:
	if not _is_primary_tap(event):
		return
	if not _is_my_turn() or _action_in_flight:
		return
	if _controller.state.phase != GameState.Phase.TURN_DRAW:
		return
	_action_in_flight = true
	var res: Dictionary = _controller.draw_from_deck(0)
	if not bool(res.get("ok", false)):
		_action_in_flight = false
		_instructions.text = "Rejected: %s" % str(res.get("reason", ""))

func _on_opp_discard_input(player_index: int, event: InputEvent) -> void:
	if not _is_primary_tap(event):
		return
	if not _is_my_turn() or _action_in_flight:
		return
	if _controller.state == null:
		return
	if _controller.state.phase == GameState.Phase.TURN_DRAW:
		var prev: int = _prev_player(0)
		if player_index == prev and not _controller.state.discard_pile.is_empty():
			_action_in_flight = true
			var res: Dictionary = _controller.take_discard(0)
			if not bool(res.get("ok", false)):
				_action_in_flight = false
				_instructions.text = "Rejected: %s" % str(res.get("reason", ""))

func _on_my_discard_input(event: InputEvent) -> void:
	if not _is_primary_tap(event):
		return
	# Intentional no-op: discard is drag/drop only to avoid accidental taps.

func _on_end_play_pressed() -> void:
	if not _is_my_turn() or _action_in_flight:
		return
	if _controller.state == null:
		return
	if _controller.state.phase != GameState.Phase.TURN_PLAY:
		return
	_action_in_flight = true
	var res: Dictionary = _controller.end_play_turn(0)
	if not bool(res.get("ok", false)):
		_action_in_flight = false
		_instructions.text = "Rejected: %s" % str(res.get("reason", ""))

# ═══════════════════════════════════════════
# RENDERING
# ═══════════════════════════════════════════

func _render_all() -> void:
	if _controller.state == null:
		return
	_render_hud()
	_render_rack()
	_render_opponents()
	_render_discard_piles()
	_render_melds()
	_render_phase_glow()
	_render_round_controls()

func _render_hud() -> void:
	var state: GameState = _controller.state
	var okey_text: String = "-"
	if state.okey_context != null:
		okey_text = "%s-%d" % [_color_letter(int(state.okey_context.okey_color)), int(state.okey_context.okey_number)]

	_turn_label.text = "Turn: P%d" % state.current_player_index
	_phase_label.text = _phase_name(state.phase)
	_deck_count_top.text = "Deck: %d" % state.deck.size()
	_okey_info_top.text = "Okey: %s" % okey_text
	_deck_num.text = str(state.deck.size())

	if state.okey_context != null and state.okey_context.indicator_tile != null:
		_ind_value.text = _tile_label(state.okey_context.indicator_tile)
	else:
		_ind_value.text = "-"
	_okey_value.text = "Okey: %s" % okey_text
	_sync_center_stack_depths(state)

	var pts: int = _selected_points()
	_open_meter.text = "Open: %d/101" % pts
	_open_meter_bottom.text = "Open: %d/101" % pts
	_open_meter.visible = _is_my_turn() and state.phase == GameState.Phase.TURN_PLAY
	_meld_hint.visible = _is_my_turn() and state.phase == GameState.Phase.TURN_PLAY and _controller.state.table_melds.is_empty() and not _has_draft_tiles()
	if _board != null:
		var ring_alpha: float = 0.82 if state.table_melds.is_empty() else 0.22
		_board.set_wall_ring_state(GEO.SHOW_WALL_RING, ring_alpha)
	if _draft_panel != null:
		# No explicit draft panel UI: draft tiles are rendered directly on felt.
		# Keep it visible only while interactive or when it already contains tiles.
		_draft_panel.visible = (_is_my_turn() and state.phase == GameState.Phase.TURN_PLAY) or _has_draft_tiles()
	_update_draft_slot_visuals()
	_instructions.text = _instruction_for_state()

func _sync_center_stack_depths(state: GameState) -> void:
	if _presentation_mode != "3d":
		_draw_stack_visible_layers = 0
		_indicator_stack_visible_layers = 0
		_update_center_stack_visibility()
		return
	var deck_size: int = 0 if state == null else state.deck.size()
	if deck_size <= 0:
		_draw_stack_visible_layers = 0
	else:
		var max_layers: int = max(2, _draw_stack_layers.size())
		_draw_stack_visible_layers = clampi(int(ceil(float(deck_size) / 3.5)), 1, max_layers)
	var has_indicator: bool = state != null and state.okey_context != null and state.okey_context.indicator_tile != null
	_indicator_stack_visible_layers = 3 if has_indicator else 0
	_update_center_stack_visibility()
	_refresh_center_stack_positions()

func _render_opponents() -> void:
	if _controller.state == null:
		return
	var hide_counts: bool = _presentation_mode == "3d"
	for i in range(min(3, _opp_count_labels.size())):
		var pi: int = i + 1
		if hide_counts:
			_opp_count_labels[i].text = ""
			_opp_count_labels[i].visible = false
		elif pi < _controller.state.players.size():
			_opp_count_labels[i].text = "%d tiles" % _controller.state.players[pi].hand.size()
			_opp_count_labels[i].visible = true
		else:
			_opp_count_labels[i].text = "-"
			_opp_count_labels[i].visible = true

func _render_discard_piles() -> void:
	var my_stack: Array = _state_discard_stack(0)
	_render_discard_stack(_my_discard_stack, my_stack)
	_my_discard_count.text = "" if my_stack.is_empty() else str(my_stack.size())
	_my_discard_count.visible = not my_stack.is_empty() and _presentation_mode != "3d"
	for i in range(min(3, _opp_discard_stacks.size())):
		var pi: int = i + 1
		var stack: Array = _state_discard_stack(pi)
		_render_discard_stack(_opp_discard_stacks[i], stack)
		_opp_discard_counts[i].text = "" if stack.is_empty() else str(stack.size())
		_opp_discard_counts[i].visible = not stack.is_empty() and _presentation_mode != "3d"

func _render_discard_stack(stack_root: Control, tiles: Array) -> void:
	for child in stack_root.get_children():
		stack_root.remove_child(child)
		child.queue_free()
	if tiles.is_empty():
		return
	var is_3d: bool = _presentation_mode == "3d"
	var chip_size: Vector2 = Vector2(36, 50) if is_3d else Vector2(48, 66)
	var x_step: float = 1.2 if is_3d else 2.0
	var y_step: float = 1.8 if is_3d else 3.0
	var font_size: int = 15 if is_3d else 20
	var start_idx: int = max(0, tiles.size() - 4)
	var vis_count: int = tiles.size() - start_idx
	for i in range(vis_count):
		var tile = tiles[start_idx + i]
		var chip := Panel.new()
		chip.custom_minimum_size = chip_size
		chip.size = chip_size
		var base_x: float = max(2.0, (stack_root.size.x - chip_size.x) * 0.5 - float(vis_count - 1) * x_step * 0.5)
		chip.position = Vector2(base_x + float(i) * x_step, float(vis_count - i - 1) * y_step)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(0.98, 0.95, 0.88, 0.98)
		cs.border_width_left = 1; cs.border_width_top = 1
		cs.border_width_right = 1; cs.border_width_bottom = 3
		cs.border_color = Color(0.62, 0.50, 0.32, 0.98)
		cs.shadow_color = Color(0, 0, 0, 0.24)
		cs.shadow_size = 3
		cs.corner_radius_top_left = 4; cs.corner_radius_top_right = 4
		cs.corner_radius_bottom_left = 4; cs.corner_radius_bottom_right = 4
		chip.add_theme_stylebox_override("panel", cs)
		# Show number on top tile only
		if i == vis_count - 1:
			var lbl := Label.new()
			lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			lbl.text = str(int(tile.number))
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lbl.add_theme_color_override("font_color", _tile_color(tile))
			lbl.add_theme_font_size_override("font_size", font_size)
			lbl.add_theme_color_override("font_outline_color", Color(0.15, 0.12, 0.09, 0.22))
			lbl.add_theme_constant_override("outline_size", 1)
			chip.add_child(lbl)
		stack_root.add_child(chip)

func _render_phase_glow() -> void:
	if _my_discard_glow != null:
		_my_discard_glow.visible = false
	for glow in _opp_discard_glows:
		glow.visible = false
	if _controller.state == null or not _is_my_turn():
		return
	var phase: int = _controller.state.phase
	if phase == GameState.Phase.STARTER_DISCARD or phase == GameState.Phase.TURN_DISCARD:
		if _my_discard_glow != null:
			_my_discard_glow.visible = true
	elif phase == GameState.Phase.TURN_DRAW and not _controller.state.discard_pile.is_empty():
		var prev: int = _prev_player(0)
		var opp_idx: int = prev - 1
		if opp_idx >= 0 and opp_idx < _opp_discard_glows.size():
			_opp_discard_glows[opp_idx].visible = true

func _state_discard_stack(player_index: int) -> Array:
	if _controller.state == null:
		return []
	if player_index < 0 or player_index >= _controller.state.player_discard_stacks.size():
		return []
	return _controller.state.player_discard_stacks[player_index]

# ═══════════════════════════════════════════
# RACK
# ═══════════════════════════════════════════

func _render_rack() -> void:
	if _controller.state == null:
		return
	_ensure_slot_controls()
	_ensure_draft_slot_controls()
	var hand: Array = _rack_hand()
	_sync_slots_with_hand(hand)

	for slot in _slot_controls:
		for child in slot.get_children():
			if child.name == "SlotBg":
				continue
			slot.remove_child(child)
			child.queue_free()
	for slot in _draft_slot_controls:
		for child in slot.get_children():
			if child.name == "SlotBg":
				continue
			slot.remove_child(child)
			child.queue_free()
	_tile_controls.clear()

	var by_id: Dictionary = {}
	for tile in hand:
		by_id[tile.unique_id] = tile

	for slot_index in range(_slots.rack_slots.size()):
		var tile_id: int = _slots.rack_slots[slot_index]
		if tile_id == -1 or not by_id.has(tile_id):
			continue
		var tile_ctrl: OkeyTile = OKEY_TILE_SCENE.instantiate()
		tile_ctrl.setup(by_id[tile_id], slot_index)
		tile_ctrl.set_zoom(_hand_zoom)
		tile_ctrl.clicked.connect(func(ctrl): _on_tile_clicked(ctrl))
		tile_ctrl.double_clicked.connect(func(ctrl): _on_tile_clicked(ctrl))
		tile_ctrl.drag_started.connect(func(ctrl): _on_tile_drag_started(ctrl))
		tile_ctrl.drag_ended.connect(func(ctrl, pos: Vector2): _on_tile_drag_ended(ctrl, pos))
		_slot_controls[slot_index].add_child(tile_ctrl)
		_tile_controls[tile_id] = tile_ctrl
	for slot_index in range(_slots.draft_slots.size()):
		var tile_id: int = _slots.draft_slots[slot_index]
		if tile_id == -1 or not by_id.has(tile_id):
			continue
		var tile_ctrl: OkeyTile = OKEY_TILE_SCENE.instantiate()
		tile_ctrl.setup(by_id[tile_id], 1000 + slot_index)
		tile_ctrl.set_zoom(_hand_zoom * 1.04)
		tile_ctrl.clicked.connect(func(ctrl): _on_tile_clicked(ctrl))
		tile_ctrl.double_clicked.connect(func(ctrl): _on_tile_clicked(ctrl))
		tile_ctrl.drag_started.connect(func(ctrl): _on_tile_drag_started(ctrl))
		tile_ctrl.drag_ended.connect(func(ctrl, pos: Vector2): _on_tile_drag_ended(ctrl, pos))
		_draft_slot_controls[slot_index].add_child(tile_ctrl)
		_tile_controls[tile_id] = tile_ctrl

	if _slots.last_tile_id == -1 and hand.size() > 0:
		_slots.last_tile_id = hand[0].unique_id
	_apply_selection_and_required()

func _on_tile_clicked(tile_ctrl: OkeyTile) -> void:
	var tile_id: int = int(tile_ctrl.tile_data.unique_id)
	_slots.last_tile_id = tile_id
	_apply_selection_and_required()

func _on_tile_drag_started(tile_ctrl: OkeyTile) -> void:
	_slots.last_tile_id = int(tile_ctrl.tile_data.unique_id)

func _on_tile_drag_ended(tile_ctrl: OkeyTile, global_pos: Vector2) -> void:
	if _controller.state == null:
		return
	if _action_in_flight:
		_render_rack()
		return

	var tile_id: int = int(tile_ctrl.tile_data.unique_id)
	var from_slot: int = _slots.rack_slots.find(tile_id)
	var from_draft_slot: int = _slots.draft_slots.find(tile_id)
	var phase: int = _controller.state.phase
	var on_discard_zone: bool = _my_discard.get_global_rect().has_point(global_pos)
	var on_rack_zone: bool = _rack_panel.get_global_rect().has_point(global_pos)
	var on_draft_lane: bool = _is_on_felt_interaction_zone(global_pos)
	var committed_meld_index: int = _find_meld_cluster(global_pos) if _is_my_turn() and phase == GameState.Phase.TURN_PLAY else -1
	var draft_target_slot: int = _find_draft_drop_slot(global_pos) if on_draft_lane else -1
	var rack_target_slot: int = _find_drop_slot(global_pos) if on_rack_zone else -1

	var decision: Dictionary = INTERACTION_RESOLVER.resolve_drop({
		"is_my_turn": _is_my_turn(),
		"phase": phase,
		"tile_id": tile_id,
		"from_rack_slot": from_slot,
		"from_draft_slot": from_draft_slot,
		"discard_intent": on_discard_zone,
		"committed_meld_hit": committed_meld_index != -1,
		"committed_meld_index": committed_meld_index,
		"draft_lane_intent": on_draft_lane,
		"draft_target_slot": draft_target_slot,
		"rack_intent": on_rack_zone,
		"rack_target_slot": rack_target_slot,
		"allow_rack_reorder": _can_overlay_rack_reorder_phase(phase),
		"allow_end_play_then_discard": true,
	})
	if not _apply_drop_decision_2d(decision):
		_render_rack()

func _apply_drop_decision_2d(decision: Dictionary) -> bool:
	var kind: StringName = decision.get("kind", &"") as StringName
	var tile_id: int = int(decision.get("tile_id", -1))
	match kind:
		INTERACTION_RESOLVER.DECISION_DISCARD:
			_discard_tile(tile_id)
			return true
		INTERACTION_RESOLVER.DECISION_END_PLAY_THEN_DISCARD:
			_try_end_play_then_discard(tile_id)
			return true
		INTERACTION_RESOLVER.DECISION_ADD_TO_COMMITTED_MELD:
			var meld_index: int = int(decision.get("meld_index", -1))
			if meld_index == -1:
				return false
			_add_to_meld([tile_id], meld_index)
			return true
		INTERACTION_RESOLVER.DECISION_MOVE_RACK_TO_DRAFT:
			_move_rack_to_draft(int(decision.get("from_slot", -1)), int(decision.get("to_draft_slot", -1)))
			return true
		INTERACTION_RESOLVER.DECISION_MOVE_DRAFT_SLOT:
			_move_draft_slot(int(decision.get("from_draft_slot", -1)), int(decision.get("to_draft_slot", -1)))
			return true
		INTERACTION_RESOLVER.DECISION_MOVE_RACK_SLOT:
			_move_slot(int(decision.get("from_slot", -1)), int(decision.get("to_slot", -1)))
			return true
		INTERACTION_RESOLVER.DECISION_MOVE_DRAFT_TO_RACK:
			_move_draft_to_rack(int(decision.get("from_draft_slot", -1)), int(decision.get("to_slot", -1)))
			return true
		_:
			return false

func _try_end_play_then_discard(tile_id: int) -> void:
	if _action_in_flight:
		return
	if not _is_tile_in_my_hand(tile_id):
		_render_rack()
		return
	var discard_tile_id: int = tile_id
	if _controller.state != null and _controller.state.phase == GameState.Phase.TURN_PLAY and _has_draft_tiles():
		if not _submit_draft_melds():
			_restore_draft_to_rack()
			_controller.apply_manual_penalty(0, 101)
			if _last_draft_error == "":
				_last_draft_error = "Invalid draft melds"
			_instructions.text = "%s. Tiles returned to rack, +101 penalty" % _last_draft_error
		# If the intended discard tile got consumed by draft meld submission,
		# choose a fallback tile before ending play to avoid confusing TURN_DISCARD failure.
		if not _is_tile_in_my_hand(discard_tile_id):
			var hand_after_submit: Array = _rack_hand()
			if hand_after_submit.is_empty():
				_instructions.text = "No tile left to discard"
				_render_rack()
				return
			discard_tile_id = int(hand_after_submit[0].unique_id)
			_instructions.text = "Selected discard was used in melds; discarding %s" % _tile_label(hand_after_submit[0])
	_action_in_flight = true
	var end_res: Dictionary = _controller.end_play_turn(0)
	if not bool(end_res.get("ok", false)):
		_action_in_flight = false
		_instructions.text = "Rejected: %s" % str(end_res.get("reason", ""))
		return
	# state_changed from END_PLAY may clear this; force it for the follow-up discard action.
	_action_in_flight = true
	var discard_res: Dictionary = _controller.discard_tile(0, discard_tile_id)
	if not bool(discard_res.get("ok", false)):
		_action_in_flight = false
		_instructions.text = "Rejected: %s" % str(discard_res.get("reason", ""))

func _discard_tile(tile_id: int) -> void:
	if _action_in_flight or _controller.state == null:
		return
	if not _is_tile_in_my_hand(tile_id):
		_render_rack()
		return
	var phase: int = _controller.state.phase
	if phase != GameState.Phase.STARTER_DISCARD and phase != GameState.Phase.TURN_DISCARD:
		return
	_action_in_flight = true
	var result: Dictionary
	if phase == GameState.Phase.STARTER_DISCARD:
		result = _controller.starter_discard(0, tile_id)
	else:
		result = _controller.discard_tile(0, tile_id)
	if not bool(result.get("ok", false)):
		_action_in_flight = false
		_instructions.text = "Rejected: %s" % str(result.get("reason", ""))

func _add_to_meld(tile_ids: Array, meld_index: int) -> void:
	if _action_in_flight:
		return
	if tile_ids.is_empty():
		return
	_action_in_flight = true
	var action: Action = Action.new(Action.ActionType.ADD_TO_MELD, {"target_meld_index": meld_index, "tile_ids": tile_ids})
	var result: Dictionary = _controller.apply_action_if_valid(0, action)
	if not bool(result.get("ok", false)):
		_action_in_flight = false
		_instructions.text = "Rejected: %s" % str(result.get("reason", ""))
	else:
		pass

func _submit_draft_melds() -> bool:
	_last_draft_error = ""
	_action_in_flight = true
	var result: Dictionary = _draft_logic.submit_draft_melds(
		_controller,
		_controller.state,
		_rack_hand(),
		_slots,
		GEO.STAGE_ROW_SLOTS,
		Callable(self, "_pair_key_for_tile")
	)
	if not bool(result.get("ok", false)):
		_action_in_flight = false
		_last_draft_error = str(result.get("reason", "Draft melds rejected"))
		return false
	return true

# Compatibility wrapper. Remove after stage API deprecation window.
func _submit_staged_melds() -> bool:
	_warn_stage_api_once("_submit_staged_melds()", "_submit_draft_melds()")
	return _submit_draft_melds()

func _all_staged_tile_ids() -> Array:
	_warn_stage_api_once("_all_staged_tile_ids()", "_all_draft_tile_ids()")
	return _slots.all_draft_tile_ids()

func _all_draft_tile_ids() -> Array:
	return _slots.all_draft_tile_ids()

func _build_new_melds_from_stage_slots_opened() -> Array:
	_warn_stage_api_once(
		"_build_new_melds_from_stage_slots_opened()",
		"_build_new_melds_from_draft_slots_opened()"
	)
	return _build_new_melds_from_draft_slots_opened()

func _build_new_melds_from_draft_slots_opened() -> Array:
	return _draft_logic.build_new_melds_from_draft_slots_opened(
		_controller.state,
		_rack_hand(),
		_slots.draft_slots,
		GEO.STAGE_ROW_SLOTS
	)

func _build_melds_from_stage_slots() -> Array:
	_warn_stage_api_once("_build_melds_from_stage_slots()", "_build_melds_from_draft_slots()")
	return _build_melds_from_draft_slots()

func _build_melds_from_draft_slots() -> Array:
	return _draft_logic.build_melds_from_draft_slots(
		_controller.state,
		_rack_hand(),
		_slots.draft_slots,
		GEO.STAGE_ROW_SLOTS,
		Callable(self, "_pair_key_for_tile")
	)

func _has_staged_tiles() -> bool:
	_warn_stage_api_once("_has_staged_tiles()", "_has_draft_tiles()")
	return _has_draft_tiles()

func _has_draft_tiles() -> bool:
	return _slots.has_draft_tiles()

func _restore_staged_to_rack() -> void:
	_warn_stage_api_once("_restore_staged_to_rack()", "_restore_draft_to_rack()")
	_restore_draft_to_rack()

func _restore_draft_to_rack() -> void:
	_slots.restore_draft_to_rack()
	_render_rack()

func _clear_stage_slots() -> void:
	_warn_stage_api_once("_clear_stage_slots()", "_clear_draft_slots()")
	_clear_draft_slots()

func _clear_draft_slots() -> void:
	_slots.clear_draft_slots()

# ═══════════════════════════════════════════
# MELD BUILDING & DISPLAY
# ═══════════════════════════════════════════

func _render_melds() -> void:
	for node in _meld_clusters:
		if node != null and is_instance_valid(node):
			if node.get_parent() == _meld_island:
				_meld_island.remove_child(node)
			node.queue_free()
	_meld_clusters.clear()

	if _controller.state == null:
		return

	var max_w: float = max(200.0, _meld_island.size.x - 16.0)
	var max_h: float = max(120.0, _meld_island.size.y - _draft_band_height() - 10.0)
	var zones: Dictionary = GEO.build_meld_owner_zones(max_w, max_h, _draft_band_height())
	var base_chip_w: float = clamp(_slot_size.x * 0.70, 30.0, 44.0)
	var base_chip_h: float = clamp(_slot_size.y * 0.70, 42.0, 58.0)
	var by_owner := {0: [], 1: [], 2: [], 3: []}
	for i in range(_controller.state.table_melds.size()):
		var meld = _controller.state.table_melds[i]
		var meld_owner: int = _meld_owner_for_render(meld)
		if not by_owner.has(meld_owner):
			by_owner[meld_owner] = []
		by_owner[meld_owner].append(i)

	var render_order: Array = [2, 3, 1, 0] # top, left, right, bottom(front of rack)
	for owner_idx in render_order:
		var zone: Rect2 = zones.get(owner_idx, Rect2(4.0, 4.0, max_w - 8.0, max_h - 8.0))
		var owner_scale: float = 1.0 if owner_idx == 0 else 0.85
		var chip_w: float = base_chip_w * owner_scale
		var chip_h: float = base_chip_h * owner_scale
		var tile_zoom: float = 0.88 * owner_scale
		var panel_h: float = chip_h + 8.0 * owner_scale
		var panel_pad: float = 16.0 * owner_scale
		var tile_sep: float = 2.0 * owner_scale
		var meld_sep: float = 8.0 * owner_scale
		var row_sep: float = 6.0 * owner_scale
		var meld_indices: Array = by_owner.get(owner_idx, [])
		if meld_indices.is_empty():
			continue

		# Build wrapped rows first so we can center each row in the owner's lane.
		var rows: Array = []
		var cur_row: Array = []
		var cur_w: float = 0.0
		for meld_index in meld_indices:
			var meld_obj = _controller.state.table_melds[int(meld_index)]
			var tile_count: int = int(meld_obj.tiles.size())
			var width: float = panel_pad + float(max(1, tile_count)) * (chip_w + tile_sep)
			var add_w: float = width if cur_row.is_empty() else width + meld_sep
			if not cur_row.is_empty() and cur_w + add_w > zone.size.x:
				rows.append({"items": cur_row, "width": cur_w})
				cur_row = []
				cur_w = 0.0
				add_w = width
			cur_row.append({"meld_index": int(meld_index), "width": width})
			cur_w += add_w
		if not cur_row.is_empty():
			rows.append({"items": cur_row, "width": cur_w})

		var y: float = zone.position.y
		for row_data in rows:
			if y + panel_h > zone.position.y + zone.size.y:
				break
			var row_w: float = float(row_data.get("width", 0.0))
			var x: float = zone.position.x + max(0.0, (zone.size.x - row_w) * 0.5)
			var row_items: Array = row_data.get("items", [])
			for item in row_items:
				var meld_index: int = int(item.get("meld_index", -1))
				var width: float = float(item.get("width", 0.0))
				var meld = _controller.state.table_melds[meld_index]

				var panel := PanelContainer.new()
				panel.custom_minimum_size = Vector2(width, panel_h)
				panel.position = Vector2(x, y)
				panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
				panel.set_meta("meld_index", meld_index)
				var ps := StyleBoxFlat.new()
				ps.bg_color = Color(0.96, 0.94, 0.88, 0.97)
				ps.border_width_left = 1
				ps.border_width_top = 1
				ps.border_width_right = 1
				ps.border_width_bottom = 2
				ps.border_color = Color(0.63, 0.50, 0.32, 0.90)
				ps.shadow_color = Color(0, 0, 0, 0.16)
				ps.shadow_size = 2
				ps.corner_radius_top_left = 6
				ps.corner_radius_top_right = 6
				ps.corner_radius_bottom_left = 6
				ps.corner_radius_bottom_right = 6
				panel.add_theme_stylebox_override("panel", ps)

				var row := HBoxContainer.new()
				row.alignment = BoxContainer.ALIGNMENT_CENTER
				row.add_theme_constant_override("separation", 2)
				row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.size_flags_vertical = Control.SIZE_EXPAND_FILL
				panel.add_child(row)

				for tile_obj in meld.tiles_data:
					var tile_chip: OkeyTile = OKEY_TILE_SCENE.instantiate()
					tile_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
					tile_chip.setup(tile_obj, -1)
					tile_chip.set_zoom(tile_zoom)
					tile_chip.set_selected(false)
					row.add_child(tile_chip)

				_meld_island.add_child(panel)
				_meld_clusters.append(panel)
				x += width + meld_sep
			y += panel_h + row_sep

func _find_meld_cluster(global_pos: Vector2) -> int:
	for cluster in _meld_clusters:
		if cluster == null or not is_instance_valid(cluster):
			continue
		if cluster.get_global_rect().has_point(global_pos):
			return int(cluster.get_meta("meld_index", -1))
	return -1

func _meld_owner_for_render(meld: Meld) -> int:
	var fallback_owner: int = 2
	if meld == null:
		return fallback_owner
	var meld_owner: int = int(meld.owner_index)
	var player_count: int = 4
	if _controller != null and _controller.state != null:
		player_count = maxi(1, _controller.state.players.size())
	if meld_owner < 0 or meld_owner >= player_count:
		return fallback_owner
	# StateCodec snapshots already project owners into local view space.
	# Keep this value as-is and only normalize to a render lane index.
	return meld_owner % 4


# ═══════════════════════════════════════════
# RACK SLOT MANAGEMENT
# ═══════════════════════════════════════════

func _init_rack_slots() -> void:
	_slots.init_rack_slots(GEO.RACK_SLOT_COUNT)

func _init_draft_slots() -> void:
	_slots.init_draft_slots(GEO.STAGE_SLOT_COUNT)

func _create_draft_area() -> void:
	_draft_panel = Control.new()
	_draft_panel.name = "DraftSlots"
	_draft_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draft_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draft_panel.z_index = 30
	_meld_island.add_child(_draft_panel)

	_draft_row1 = HBoxContainer.new()
	_draft_row1.alignment = BoxContainer.ALIGNMENT_CENTER
	_draft_row1.add_theme_constant_override("separation", 4)
	_draft_row1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draft_row1.z_index = 31
	_draft_panel.add_child(_draft_row1)

	_draft_row2 = HBoxContainer.new()
	_draft_row2.alignment = BoxContainer.ALIGNMENT_CENTER
	_draft_row2.add_theme_constant_override("separation", 4)
	_draft_row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draft_row2.z_index = 31
	_draft_panel.add_child(_draft_row2)

func _ensure_draft_slot_controls() -> void:
	if _draft_panel == null or _draft_row1 == null or _draft_row2 == null:
		return
	if _draft_slot_controls.size() == GEO.STAGE_SLOT_COUNT:
		for slot in _draft_slot_controls:
			slot.custom_minimum_size = _slot_size
		return
	for child in _draft_row1.get_children():
		child.queue_free()
	for child in _draft_row2.get_children():
		child.queue_free()
	_draft_slot_controls.clear()
	for i in range(GEO.STAGE_SLOT_COUNT):
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = _slot_size
		slot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var ss := StyleBoxFlat.new()
		ss.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		ss.border_width_left = 0
		ss.border_width_top = 0
		ss.border_width_right = 0
		ss.border_width_bottom = 0
		ss.border_color = Color(0.0, 0.0, 0.0, 0.0)
		ss.corner_radius_top_left = 5
		ss.corner_radius_top_right = 5
		ss.corner_radius_bottom_left = 5
		ss.corner_radius_bottom_right = 5
		slot_panel.add_theme_stylebox_override("panel", ss)

		var slot_bg := Panel.new()
		slot_bg.name = "SlotBg"
		slot_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_bg.modulate = Color(1, 1, 1, 0.0)
		slot_panel.add_child(slot_bg)
		if i < GEO.STAGE_ROW_SLOTS:
			_draft_row1.add_child(slot_panel)
		else:
			_draft_row2.add_child(slot_panel)
		_draft_slot_controls.append(slot_panel)
	_layout_draft_rows()

func _ensure_slot_controls() -> void:
	if _slot_controls.size() == GEO.RACK_SLOT_COUNT:
		for slot in _slot_controls:
			slot.custom_minimum_size = _slot_size
		return

	for child in _row1.get_children():
		child.queue_free()
	for child in _row2.get_children():
		child.queue_free()
	_slot_controls.clear()

	for i in range(GEO.RACK_SLOT_COUNT):
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = _slot_size
		slot_panel.mouse_filter = Control.MOUSE_FILTER_PASS

		var ss := StyleBoxFlat.new()
		ss.bg_color = Color(0.24, 0.17, 0.11, 0.38)
		ss.border_width_left = 1; ss.border_width_top = 1
		ss.border_width_right = 1; ss.border_width_bottom = 2
		ss.border_color = Color(0.70, 0.56, 0.39, 0.34)
		ss.corner_radius_top_left = 5; ss.corner_radius_top_right = 5
		ss.corner_radius_bottom_left = 5; ss.corner_radius_bottom_right = 5
		slot_panel.add_theme_stylebox_override("panel", ss)

		var slot_bg := Panel.new()
		slot_bg.name = "SlotBg"
		slot_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_bg.modulate = Color(1, 1, 1, 0.04)
		slot_panel.add_child(slot_bg)

		if i < GEO.RACK_ROW_SLOTS:
			_row1.add_child(slot_panel)
		else:
			_row2.add_child(slot_panel)
		_slot_controls.append(slot_panel)

func _rack_hand() -> Array:
	if _controller.state == null:
		return []
	if _controller.state.players.is_empty():
		return []
	return _controller.state.players[0].hand

func _sync_slots_with_hand(hand: Array) -> void:
	_slots.sync_slots_with_hand(hand)

func _apply_selection_and_required() -> void:
	var required_id: int = -1
	if _controller.state != null:
		required_id = _controller.state.turn_required_use_tile_id
	for tile_id in _tile_controls.keys():
		var tile_ctrl: OkeyTile = _tile_controls[tile_id]
		var selected: bool = int(tile_id) == _slots.last_tile_id
		if required_id != -1 and int(tile_id) == required_id:
			selected = true
		tile_ctrl.set_selected(selected)

func _selected_points() -> int:
	if _controller.state == null:
		return 0
	var melds: Array = _build_melds_from_draft_slots()
	if melds.is_empty():
		return 0
	var hand_by_id: Dictionary = {}
	for tile in _rack_hand():
		hand_by_id[tile.unique_id] = tile
	var validator: MeldValidator = MeldValidator.new()
	var total: int = 0
	for meld_dict in melds:
		var kind: int = int(meld_dict.get("kind", -1))
		var ids: Array = meld_dict.get("tile_ids", [])
		var tiles: Array = []
		for tile_id in ids:
			if hand_by_id.has(tile_id):
				tiles.append(hand_by_id[tile_id])
		if kind == Meld.Kind.RUN:
			var r: Dictionary = validator.validate_run(tiles, _controller.state.okey_context)
			if bool(r.get("ok", false)):
				total += int(r.get("points_value", 0))
		elif kind == Meld.Kind.SET:
			var r: Dictionary = validator.validate_set(tiles, _controller.state.okey_context)
			if bool(r.get("ok", false)):
				total += int(r.get("points_value", 0))
	return total

func _find_drop_slot(global_pos: Vector2) -> int:
	for i in range(_slot_controls.size()):
		if _slot_controls[i].get_global_rect().grow(10.0).has_point(global_pos):
			return i
	var row1_rect: Rect2 = _row1.get_global_rect()
	var row2_rect: Rect2 = _row2.get_global_rect()
	if row1_rect.grow(10.0).has_point(global_pos):
		return _rack_slot_index_from_row_point(global_pos, row1_rect, 0)
	if row2_rect.grow(10.0).has_point(global_pos):
		return _rack_slot_index_from_row_point(global_pos, row2_rect, GEO.RACK_ROW_SLOTS)
	var row1_cy: float = _row1.get_global_rect().get_center().y
	var row2_cy: float = _row2.get_global_rect().get_center().y
	var use_row2: bool = absf(global_pos.y - row2_cy) < absf(global_pos.y - row1_cy)
	var start_i: int = GEO.RACK_ROW_SLOTS if use_row2 else 0
	var stop_i: int = GEO.RACK_SLOT_COUNT if use_row2 else GEO.RACK_ROW_SLOTS
	var best_i: int = start_i
	var best_d: float = INF
	for i in range(start_i, stop_i):
		var d: float = _slot_controls[i].get_global_rect().get_center().distance_squared_to(global_pos)
		if d < best_d:
			best_d = d
			best_i = i
	return best_i

func _rack_slot_index_from_row_point(global_pos: Vector2, row_rect: Rect2, row_start: int) -> int:
	var sep: float = 4.0
	var cell_w: float = _slot_size.x + sep
	var local_x: float = clamp(global_pos.x - row_rect.position.x, 0.0, row_rect.size.x)
	var col: int = int(floor(local_x / max(1.0, cell_w)))
	col = clamp(col, 0, GEO.RACK_ROW_SLOTS - 1)
	return row_start + col

func _find_draft_drop_slot(global_pos: Vector2) -> int:
	if _meld_island == null or not is_instance_valid(_meld_island):
		return -1
	var lane_rect: Rect2 = _meld_island.get_global_rect()
	var slot_count: int = _slots.draft_slots.size()
	return DRAFT_GRID.point_to_slot(
		global_pos,
		lane_rect,
		slot_count,
		GEO.STAGE_ROW_SLOTS,
		INTERACTION_TUNING.DRAFT_LANE_MARGIN_2D_PX
	)

func _find_stage_drop_slot(global_pos: Vector2) -> int:
	_warn_stage_api_once("_find_stage_drop_slot()", "_find_draft_drop_slot()")
	return _find_draft_drop_slot(global_pos)

func _move_slot(from_slot: int, to_slot: int) -> void:
	if _slots.move_slot(from_slot, to_slot):
		_render_rack()

func _move_rack_to_draft(from_slot: int, to_draft_slot: int) -> void:
	if _slots.move_rack_to_draft(from_slot, to_draft_slot, GEO.STAGE_ROW_SLOTS, GEO.STAGE_SLOT_COUNT):
		_render_rack()

func _move_draft_to_rack(from_draft_slot: int, to_slot: int) -> void:
	if _slots.move_draft_to_rack(from_draft_slot, to_slot):
		_render_rack()

func _move_draft_slot(from_slot: int, to_slot: int) -> void:
	if _slots.move_draft_slot(from_slot, to_slot):
		_render_rack()

# ═══════════════════════════════════════════
# BOT TURNS
# ═══════════════════════════════════════════

func _maybe_auto_bot_turn() -> void:
	if _controller_injected_external:
		return
	if _bot_loop_running:
		return
	if _controller.state == null:
		return
	_bot_loop_running = true
	var safety: int = 0
	while _controller.state != null and _controller.state.phase != GameState.Phase.ROUND_END and _controller.state.current_player_index != 0 and safety < 96:
		safety += 1
		var bot_index: int = int(_controller.state.current_player_index)
		var action = _bot.choose_action(_controller.state, bot_index)
		if action == null:
			action = _bot_fallback.choose_action(_controller.state, bot_index)
		if action == null and _controller.state.phase == GameState.Phase.TURN_DRAW and _controller.state.deck.is_empty() and not _controller.state.discard_pile.is_empty():
			action = Action.new(Action.ActionType.TAKE_DISCARD, {})
		if action == null:
			_instructions.text = "Bot stalled (no legal action)"
			break
		var result: Dictionary = _controller.apply_action_if_valid(bot_index, action)
		if not bool(result.get("ok", false)):
			if _controller.state == null or _controller.state.phase == GameState.Phase.ROUND_END:
				break
			var fallback_try = _bot_fallback.choose_action(_controller.state, bot_index)
			if fallback_try != null:
				var fallback_try_res: Dictionary = _controller.apply_action_if_valid(bot_index, fallback_try)
				if bool(fallback_try_res.get("ok", false)):
					continue
				if _controller.state == null or _controller.state.phase == GameState.Phase.ROUND_END:
					break
			var fallback: Action = null
			if _controller.state.phase == GameState.Phase.TURN_DRAW:
				if _controller.state.deck.is_empty() and not _controller.state.discard_pile.is_empty():
					fallback = Action.new(Action.ActionType.TAKE_DISCARD, {})
				else:
					fallback = Action.new(Action.ActionType.DRAW_FROM_DECK, {})
			elif _controller.state.phase == GameState.Phase.TURN_PLAY:
				fallback = Action.new(Action.ActionType.END_PLAY, {})
			elif _controller.state.phase == GameState.Phase.STARTER_DISCARD or _controller.state.phase == GameState.Phase.TURN_DISCARD:
				var hand: Array = _controller.state.players[bot_index].hand
				if not hand.is_empty():
					var tid: int = int(hand[0].unique_id)
					if _controller.state.phase == GameState.Phase.STARTER_DISCARD:
						fallback = Action.new(Action.ActionType.STARTER_DISCARD, {"tile_id": tid})
					else:
						fallback = Action.new(Action.ActionType.DISCARD, {"tile_id": tid})
			if fallback == null:
				_instructions.text = "Bot stalled (no fallback action)"
				break
			var fb_res: Dictionary = _controller.apply_action_if_valid(bot_index, fallback)
			if not bool(fb_res.get("ok", false)):
				if _controller.state == null or _controller.state.phase == GameState.Phase.ROUND_END:
					break
				_instructions.text = "Bot stalled (%s)" % str(fb_res.get("reason", "unknown"))
				break
	_bot_loop_running = false

func _bind_controller_signals() -> void:
	if _controller == null:
		return
	if not _controller.state_changed.is_connected(_on_state_changed):
		_controller.state_changed.connect(_on_state_changed)
	if not _controller.action_rejected.is_connected(_on_action_rejected):
		_controller.action_rejected.connect(_on_action_rejected)
	if not _controller.action_applied.is_connected(_on_action_applied):
		_controller.action_applied.connect(_on_action_applied)

func _unbind_controller_signals() -> void:
	if _controller == null:
		return
	if _controller.state_changed.is_connected(_on_state_changed):
		_controller.state_changed.disconnect(_on_state_changed)
	if _controller.action_rejected.is_connected(_on_action_rejected):
		_controller.action_rejected.disconnect(_on_action_rejected)
	if _controller.action_applied.is_connected(_on_action_applied):
		_controller.action_applied.disconnect(_on_action_applied)

# ═══════════════════════════════════════════
# ROUND END DIALOG
# ═══════════════════════════════════════════

func _show_round_end_dialog() -> void:
	if _controller.state == null:
		return
	# Headless test/probe runs have no real window; avoid popup warnings there.
	if DisplayServer.get_name() == "headless":
		return
	if _round_dialog == null:
		_round_dialog = AcceptDialog.new()
		_round_dialog.title = "Round End"
		add_child(_round_dialog)
	var lines: Array[String] = []
	lines.append("Round complete")
	for i in range(_controller.state.players.size()):
		var p = _controller.state.players[i]
		var label: String = "You" if i == 0 else "P%d" % i
		lines.append("%s: round=%d total=%d" % [label, int(p.score_round), int(p.score_total)])
	_round_dialog.dialog_text = "\n".join(lines)
	if not _round_dialog.visible:
		_round_dialog.popup_centered(Vector2i(420, 260))

func _return_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://ui/Main.tscn")

func _create_round_controls() -> void:
	_round_controls = HBoxContainer.new()
	_round_controls.name = "RoundControls"
	_round_controls.visible = false
	_round_controls.alignment = BoxContainer.ALIGNMENT_END
	_round_controls.add_theme_constant_override("separation", 8)
	_round_controls.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_round_controls)

	_round_new_btn = Button.new()
	_round_new_btn.text = "New Round"
	_round_new_btn.custom_minimum_size = Vector2(116, 34)
	_round_new_btn.pressed.connect(_start_round)
	_round_controls.add_child(_round_new_btn)

	_round_menu_btn = Button.new()
	_round_menu_btn.text = "Return to Menu"
	_round_menu_btn.custom_minimum_size = Vector2(132, 34)
	_round_menu_btn.pressed.connect(_return_to_main_menu)
	_round_controls.add_child(_round_menu_btn)

func _render_round_controls() -> void:
	if _round_controls == null or _controller.state == null:
		return
	_round_controls.visible = _controller.state.phase == GameState.Phase.ROUND_END

# ═══════════════════════════════════════════
# RESPONSIVE LAYOUT
# ═══════════════════════════════════════════

func _apply_responsive_layout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var margin: float = GEO.OUTER_MARGIN
	var content_top: float = 8.0 if _presentation_mode == "3d" else GEO.TOP_BAR_HEIGHT + 8.0
	var tile_gap: float = 4.0
	var usable_w: float = max(960.0, vp.x - margin * 2.0)
	# Keep rack readable on desktop while preserving two-row capacity.
	var tile_w: float = clamp((usable_w * 0.54 - 30.0 - float(GEO.RACK_ROW_SLOTS - 1) * tile_gap) / float(GEO.RACK_ROW_SLOTS), 36.0, 56.0)
	var tile_h: float = clamp(tile_w * 1.34, 58.0, 86.0)
	_slot_size = Vector2(tile_w, tile_h)

	var rack_w: float = float(GEO.RACK_ROW_SLOTS) * tile_w + float(GEO.RACK_ROW_SLOTS - 1) * tile_gap + 34.0
	rack_w = min(rack_w, vp.x - margin * 2.0)
	var rack_h: float = clamp(tile_h * 2.0 + 14.0, GEO.RACK_MIN_HEIGHT, GEO.RACK_MAX_HEIGHT)
	var rack_x: float = (vp.x - rack_w) * 0.5
	var rack_y: float = vp.y - rack_h - GEO.BOTTOM_PADDING
	if _presentation_mode == "3d":
		rack_y -= 82.0
	_set_rect_pixels(_rack_panel, rack_x, rack_y, rack_w, rack_h)
	if _presentation_mode == "3d":
		_rack_panel.pivot_offset = Vector2(rack_w * 0.5, rack_h)
		_rack_panel.rotation_degrees = -0.65
		_rack_panel.scale = Vector2(1.01, 0.96)
		if _row1 != null:
			_row1.scale = Vector2(0.975, 0.935)
		if _row2 != null:
			_row2.scale = Vector2(1.0, 1.0)
	else:
		_rack_panel.rotation_degrees = 0.0
		_rack_panel.scale = Vector2.ONE
		_rack_panel.pivot_offset = Vector2.ZERO
		if _row1 != null:
			_row1.scale = Vector2.ONE
		if _row2 != null:
			_row2.scale = Vector2.ONE
	if _rack_depth_shell != null:
		_rack_depth_shell.visible = _presentation_mode == "3d"
		if _presentation_mode == "3d":
			_set_rect_pixels(
				_rack_depth_shell,
				rack_x + 12.0,
				rack_y + 9.0,
				rack_w - 24.0,
				rack_h * 0.88
			)
			_rack_depth_shell.pivot_offset = Vector2((rack_w - 24.0) * 0.5, rack_h * 0.88)
			_rack_depth_shell.rotation_degrees = -0.65
			_rack_depth_shell.scale = Vector2(1.01, 0.96)
		else:
			_rack_depth_shell.rotation_degrees = 0.0
			_rack_depth_shell.scale = Vector2.ONE
			_rack_depth_shell.pivot_offset = Vector2.ZERO
	if _rack_contact_shadow != null:
		var shadow_w: float = rack_w * 0.94
		var shadow_h: float = clamp(tile_h * 0.58, 26.0, 46.0)
		var shadow_x: float = rack_x + (rack_w - shadow_w) * 0.5
		var shadow_y: float = rack_y - shadow_h * 0.34
		_set_rect_pixels(_rack_contact_shadow, shadow_x, shadow_y, shadow_w, shadow_h)

	var table_x: float = margin
	var table_y: float = content_top
	var table_w: float = vp.x - margin * 2.0
	var table_h: float
	if _presentation_mode == "3d":
		# In 3D mode, rack is in the overlay — table fills the full viewport
		table_h = clamp(vp.y - content_top - 8.0, GEO.TABLE_MIN_HEIGHT, GEO.TABLE_MAX_HEIGHT)
	else:
		table_h = clamp(rack_y - content_top - GEO.BOTTOM_RACK_GAP, GEO.TABLE_MIN_HEIGHT, GEO.TABLE_MAX_HEIGHT)
	_set_rect_pixels(_table_area, table_x, table_y, table_w, table_h)
	if _board != null:
		_board.layout_table_backdrop(table_w, table_h)

	# Pseudo-3D board geometry: all anchors derive from this felt frame.
	var felt_w: float = clamp(table_w * GEO.FELT_WIDTH_RATIO, GEO.FELT_MIN_WIDTH, table_w - GEO.FELT_SIDE_INSET_MAX)
	var felt_h: float = clamp(table_h * GEO.FELT_HEIGHT_RATIO, GEO.FELT_MIN_HEIGHT, table_h - GEO.FELT_BOTTOM_INSET_MAX)
	# Keep felt square in both 2D and 3D presentations.
	var felt_side_max_w: float = max(320.0, table_w - GEO.FELT_SIDE_INSET_MAX)
	var felt_side_max_h: float = max(320.0, table_h - GEO.FELT_BOTTOM_INSET_MAX)
	var felt_side: float = clamp(
		min(table_w * GEO.FELT_WIDTH_RATIO, table_h * GEO.FELT_HEIGHT_RATIO),
		GEO.FELT_MIN_SIDE,
		min(felt_side_max_w, felt_side_max_h)
	)
	felt_w = felt_side
	felt_h = felt_side
	var felt_x: float = (table_w - felt_w) * 0.5
	var felt_y_span: float = max(GEO.FELT_TOP_MARGIN_MIN, table_h - felt_h - GEO.FELT_BOTTOM_MARGIN_MIN)
	var felt_y: float = lerpf(GEO.FELT_TOP_MARGIN_MIN, felt_y_span, GEO.FELT_VERTICAL_BIAS)
	_set_rect_pixels(_melds_panel, felt_x, felt_y, felt_w, felt_h)
	_set_rect_pixels(
		_meld_island,
		GEO.MELD_ISLAND_INSET_X,
		GEO.MELD_ISLAND_INSET_TOP,
		felt_w - GEO.MELD_ISLAND_INSET_X * 2.0,
		felt_h - GEO.MELD_ISLAND_INSET_TOP - GEO.MELD_ISLAND_INSET_BOTTOM
	)

	# Projected board footprint used for all table-space anchors.
	var board_proj: Dictionary = GEO.project_board_footprint(felt_x, felt_y, felt_w, felt_h)
	var top_left: Vector2 = board_proj.get("top_left", Vector2())
	var top_right: Vector2 = board_proj.get("top_right", Vector2())
	var bottom_left: Vector2 = board_proj.get("bottom_left", Vector2())
	var bottom_right: Vector2 = board_proj.get("bottom_right", Vector2())
	var proj_top_w: float = float(board_proj.get("top_width", 0.0))
	var proj_bottom_w: float = float(board_proj.get("bottom_width", 0.0))
	if _board != null:
		_board.layout_board_geometry(top_left, top_right, bottom_right, bottom_left)

	if _board != null:
		_board.set_slot_size(_slot_size)
		_board.layout_wall_ring()
	if _draft_panel != null:
		_draft_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		_layout_draft_rows()

	# Pseudo-3D table rails around the felt (camera-tilt illusion).
	if GEO.SHOW_TABLE_RAILS and _rail_top != null and _rail_left != null and _rail_right != null and _rail_bottom != null:
		var side_w: float = clamp(felt_w * 0.016, 8.0, 14.0)
		var top_h: float = clamp(felt_h * 0.018, 8.0, 14.0)
		var bottom_h: float = clamp(felt_h * 0.016, 6.0, 12.0)
		var top_inset: float = clamp(felt_w * 0.12, 88.0, 170.0)
		# Keep rails fully inside TableArea so they never overlap the top HUD bar.
		var top_y: float = max(2.0, felt_y - top_h * 0.10)
		_set_rect_pixels(_rail_top, top_left.x + top_inset * 0.5, top_y, proj_top_w - top_inset, top_h)
		_set_rect_pixels(_rail_left, bottom_left.x - side_w - 1.0, top_left.y + top_h * 0.55, side_w, (bottom_left.y - top_left.y) + top_h * 0.40)
		_set_rect_pixels(_rail_right, bottom_right.x + 1.0, top_right.y + top_h * 0.55, side_w, (bottom_right.y - top_right.y) + top_h * 0.40)
		_set_rect_pixels(_rail_bottom, bottom_left.x - side_w * 0.08, bottom_left.y + 2.0, proj_bottom_w + side_w * 0.16, bottom_h)
		# Side rails can visually look like giant overlays at some scales; keep only a subtle bottom lip.
		_rail_left.visible = false
		_rail_right.visible = false
		_rail_top.visible = false
		_rail_bottom.visible = true

	var anchors: Dictionary = GEO.build_table_anchor_contract(top_left, top_right, bottom_left, bottom_right, felt_w, felt_h, _presentation_mode)
	var center_size: Vector2 = anchors.get("center_size", Vector2())
	var center_anchor: Vector2 = anchors.get("center_anchor", Vector2())
	_set_rect_pixels(
		_center_zone,
		center_anchor.x - center_size.x * 0.5,
		center_anchor.y - center_size.y * 0.5,
		center_size.x,
		center_size.y
	)
	_center_zone_base_position = _center_zone.position

	var opp_rack_rects: Array = anchors.get("opp_rack_rects", [])
	for i in range(min(_opp_rack_panels.size(), opp_rack_rects.size())):
		var rr: Rect2 = opp_rack_rects[i]
		var rack_panel: PanelContainer = _opp_rack_panels[i]
		_set_rect_pixels(rack_panel, rr.position.x, rr.position.y, rr.size.x, rr.size.y)
		if _presentation_mode == "3d":
			rack_panel.pivot_offset = rack_panel.size * 0.5
			if i == 0:
				rack_panel.rotation_degrees = GEO.OPP_3D_SIDE_RACK_ROTATION_DEG # east player
			elif i == 2:
				rack_panel.rotation_degrees = -GEO.OPP_3D_SIDE_RACK_ROTATION_DEG # west player
			else:
				rack_panel.rotation_degrees = 0.0 # north player
		else:
			rack_panel.rotation_degrees = 0.0
			rack_panel.pivot_offset = Vector2.ZERO
		if i < _opp_rack_base_positions.size():
			_opp_rack_base_positions[i] = rack_panel.position

	var opp_disc_rects: Array = anchors.get("opp_discard_rects", [])
	for i in range(min(_opp_discard_panels.size(), opp_disc_rects.size())):
		var r: Rect2 = opp_disc_rects[i]
		_set_rect_pixels(_opp_discard_panels[i], r.position.x, r.position.y, r.size.x, r.size.y)
		if i < _opp_discard_base_positions.size():
			_opp_discard_base_positions[i] = r.position

	var my_discard_local: Rect2 = anchors.get("my_discard_local", Rect2())
	var my_discard_x: float = table_x + my_discard_local.position.x
	var my_discard_y: float = table_y + my_discard_local.position.y
	_set_rect_pixels(_my_discard, my_discard_x, my_discard_y, my_discard_local.size.x, my_discard_local.size.y)
	if _discard_prompt != null:
		var prompt_w: float = my_discard_local.size.x + 34.0
		var prompt_h: float = 26.0
		var prompt_x: float = my_discard_x - (prompt_w - my_discard_local.size.x) * 0.5
		var prompt_y: float = my_discard_y - prompt_h - 10.0
		_set_rect_pixels(_discard_prompt, prompt_x, prompt_y, prompt_w, prompt_h)
		_discard_prompt_base_pos = _discard_prompt.position

	_ensure_slot_controls()
	_ensure_draft_slot_controls()
	if _round_controls != null:
		var controls_w: float = 264.0
		var controls_h: float = 38.0
		_set_rect_pixels(_round_controls, vp.x - controls_w - margin, margin + 4.0, controls_w, controls_h)
	if _controller.state != null:
		_render_all()


func _draft_band_height() -> float:
	return _slot_size.y * 2.0 + 18.0

func _layout_draft_rows() -> void:
	if _draft_panel == null or _draft_row1 == null or _draft_row2 == null:
		return
	var row_w: float = float(GEO.STAGE_ROW_SLOTS) * _slot_size.x + float(GEO.STAGE_ROW_SLOTS - 1) * 4.0
	var x: float = (_meld_island.size.x - row_w) * 0.5
	var total_h: float = _slot_size.y * 2.0 + 4.0
	# Keep draft rows near the lower felt half (closer to player's rack), without a visible panel.
	var y1: float = _meld_island.size.y * 0.58
	y1 = clamp(y1, 10.0, max(10.0, _meld_island.size.y - total_h - 10.0))
	var y2: float = y1 + _slot_size.y + 4.0
	_set_rect_pixels(_draft_row1, x, y1, row_w, _slot_size.y)
	_set_rect_pixels(_draft_row2, x, y2, row_w, _slot_size.y)
	_update_draft_slot_visuals()

func _is_on_felt_interaction_zone(global_pos: Vector2) -> bool:
	var margin: float = INTERACTION_TUNING.DRAFT_LANE_MARGIN_2D_PX
	if _melds_panel != null and is_instance_valid(_melds_panel):
		return _melds_panel.get_global_rect().grow(margin).has_point(global_pos)
	if _meld_island != null and is_instance_valid(_meld_island):
		return _meld_island.get_global_rect().grow(margin).has_point(global_pos)
	return false

func _update_draft_slot_visuals() -> void:
	if _draft_slot_controls.is_empty():
		return
	for i in range(_draft_slot_controls.size()):
		var slot_ctrl: Control = _draft_slot_controls[i]
		if slot_ctrl == null or not is_instance_valid(slot_ctrl):
			continue
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_width_left = 0
		style.border_width_top = 0
		style.border_width_right = 0
		style.border_width_bottom = 0
		slot_ctrl.add_theme_stylebox_override("panel", style)
		var bg: Panel = slot_ctrl.get_node_or_null("SlotBg")
		if bg != null:
			bg.modulate = Color(1, 1, 1, 0.0)

func _set_rect_pixels(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0
	node.offset_left = x
	node.offset_top = y
	node.offset_right = x + max(1.0, w)
	node.offset_bottom = y + max(1.0, h)

# ═══════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════

func _instruction_for_state() -> String:
	return TILE_HELPERS.instruction_for_state(_controller.state, _is_my_turn())

func _phase_name(phase: int) -> String:
	return TILE_HELPERS.phase_name(phase)

func _tile_label(tile) -> String:
	return TILE_HELPERS.tile_label(tile)

func _tile_color(tile) -> Color:
	return TILE_HELPERS.tile_color(tile)

func _color_letter(color_value: int) -> String:
	return TILE_HELPERS.color_letter(color_value)

func _pair_key_for_tile(tile) -> String:
	var ctx = _controller.state.okey_context if _controller.state != null else null
	return TILE_HELPERS.pair_key_for_tile(tile, ctx)

func _is_primary_tap(event: InputEvent) -> bool:
	return TILE_HELPERS.is_primary_tap(event)

func _is_my_turn() -> bool:
	return TILE_HELPERS.is_my_turn(_controller.state)

func _is_tile_in_my_hand(tile_id: int) -> bool:
	return TILE_HELPERS.is_tile_in_hand(_rack_hand(), tile_id)

func _prev_player(player_index: int) -> int:
	return TILE_HELPERS.prev_player(_controller.state, player_index)

