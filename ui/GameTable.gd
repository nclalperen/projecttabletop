extends Control

const OKEY_TILE_SCENE: PackedScene = preload("res://ui/widgets/OkeyTile.tscn")
const RACK_SLOT_COUNT: int = 30
const RACK_ROW_SLOTS: int = 15
const STAGE_SLOT_COUNT: int = 24
const STAGE_ROW_SLOTS: int = 12
const MELD_LANE_Y: Array[float] = [4.0, 50.0, 96.0, 142.0]
const DISCARD_ZONE_SIZE: Vector2 = Vector2(62, 84)
const TOP_BAR_HEIGHT: float = 44.0
const OUTER_MARGIN: float = 16.0
const RACK_MIN_HEIGHT: float = 170.0
const RACK_MAX_HEIGHT: float = 290.0
const TABLE_MIN_HEIGHT: float = 360.0
const TABLE_MAX_HEIGHT: float = 560.0

const OPP_COLORS: Array[Color] = [
	Color(0.65, 0.22, 0.18),  # P1 - reddish
	Color(0.18, 0.42, 0.65),  # P2 - blue
	Color(0.55, 0.45, 0.18),  # P3 - amber
]

# ─── Scene node references ───
@onready var _instructions: Label = $TopBar/TopHBox/Instructions
@onready var _turn_label: Label = $TopBar/TopHBox/TurnLabel
@onready var _phase_label: Label = $TopBar/TopHBox/PhaseLabel
@onready var _deck_count_top: Label = $TopBar/TopHBox/DeckCount
@onready var _okey_info_top: Label = $TopBar/TopHBox/OkeyInfo

@onready var _table_area: Control = $TableArea
@onready var _center_zone: HBoxContainer = $TableArea/CenterZone
@onready var _draw_deck: PanelContainer = $TableArea/CenterZone/DrawDeck
@onready var _deck_num: Label = $TableArea/CenterZone/DrawDeck/DeckVBox/DeckNum
@onready var _ind_value: Label = $TableArea/CenterZone/IndicatorPanel/IndVBox/IndValue
@onready var _okey_value: Label = $TableArea/CenterZone/IndicatorPanel/IndVBox/OkeyValue

@onready var _melds_panel: Panel = $TableArea/MeldsPanel
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
var _controller: LocalGameController = LocalGameController.new()
var _bot: BotHeuristic = BotHeuristic.new()
var _bot_fallback: BotRandom = BotRandom.new(7007)
var _rule_config: RuleConfig = null
var _game_seed: int = 2001
var _player_count: int = 4

# ─── Rack state ───
var _slot_controls: Array[Control] = []
var _rack_slots: Array[int] = []
var _stage_panel: PanelContainer = null
var _stage_row1: HBoxContainer = null
var _stage_row2: HBoxContainer = null
var _stage_slot_controls: Array[Control] = []
var _stage_slots: Array[int] = []
var _tile_controls: Dictionary = {}
var _selected_tile_ids: Dictionary = {}
var _last_tile_id: int = -1
var _hand_zoom: float = 0.94
var _slot_size: Vector2 = Vector2(52, 72)

# ─── UI state ───
var _action_in_flight: bool = false
var _bot_loop_running: bool = false
var _round_dialog: AcceptDialog = null
var _meld_clusters: Array[Control] = []
var _last_stage_error: String = ""

# ─── Opponent UI (built in code) ───
var _opp_rack_panels: Array[PanelContainer] = []
var _opp_count_labels: Array[Label] = []
var _opp_discard_panels: Array[PanelContainer] = []
var _opp_discard_stacks: Array[Control] = []
var _opp_discard_counts: Array[Label] = []
var _opp_discard_glows: Array[Panel] = []
var _my_discard_glow: Panel = null

# ─── Discard tracking (visual, per player index) ───
var _discard_tiles: Array = [[], [], [], []]

# ═══════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════

func _ready() -> void:
	_create_opponent_areas()
	_create_my_discard_glow()
	_init_rack_slots()
	_init_stage_slots()
	_create_stage_area()

	_controller.state_changed.connect(_on_state_changed)
	_controller.action_rejected.connect(_on_action_rejected)
	_controller.action_applied.connect(_on_action_applied)

	_btn_new_round.pressed.connect(_start_round)
	_btn_menu.pressed.connect(_return_to_main_menu)
	_btn_end_play.pressed.connect(_on_end_play_pressed)

	_draw_deck.gui_input.connect(_on_deck_input)
	_my_discard.gui_input.connect(_on_my_discard_input)

	_table_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	_start_round()

func configure_game(rule_config: RuleConfig, game_seed: int, player_count: int) -> void:
	_rule_config = rule_config
	_game_seed = game_seed
	_player_count = player_count

# ═══════════════════════════════════════════
# OPPONENT AREAS (dynamic, positioned in TableArea)
# ═══════════════════════════════════════════

func _create_opponent_areas() -> void:
	var opp_names: Array[String] = ["Bot 1", "Bot 2", "Bot 3"]

	for i in range(3):
		var player_index: int = i + 1

		# Opponent badge
		var rack := PanelContainer.new()
		rack.name = "OppRack%d" % player_index
		_apply_opp_rack_style(rack, i)
		_set_anchors(rack, [0.0, 0.0, 0.0, 0.0])
		rack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_table_area.add_child(rack)

		var rack_vbox := VBoxContainer.new()
		rack_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		rack_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rack_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rack.add_child(rack_vbox)

		var name_lbl := Label.new()
		name_lbl.text = opp_names[i]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_color_override("font_color", Color(0.86, 0.9, 0.95, 0.82))
		name_lbl.add_theme_font_size_override("font_size", 11)
		rack_vbox.add_child(name_lbl)

		var count_lbl := Label.new()
		count_lbl.text = "21 tiles"
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98, 0.9))
		count_lbl.add_theme_font_size_override("font_size", 15)
		rack_vbox.add_child(count_lbl)

		_opp_rack_panels.append(rack)
		_opp_count_labels.append(count_lbl)

		# Corner discard placeholder
		var discard := PanelContainer.new()
		discard.name = "OppDiscard%d" % player_index
		_apply_discard_zone_style(discard)
		_set_anchors(discard, [0.0, 0.0, 0.0, 0.0])
		discard.mouse_filter = Control.MOUSE_FILTER_STOP
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
		disc_hint.add_theme_color_override("font_color", Color(0.55, 0.75, 0.85, 0.55))
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
		gs.bg_color = Color(0.9, 0.7, 0.2, 0.15)
		gs.border_width_left = 2; gs.border_width_top = 2
		gs.border_width_right = 2; gs.border_width_bottom = 2
		gs.border_color = Color(0.95, 0.78, 0.25, 0.85)
		gs.corner_radius_top_left = 8; gs.corner_radius_top_right = 8
		gs.corner_radius_bottom_left = 8; gs.corner_radius_bottom_right = 8
		glow.add_theme_stylebox_override("panel", gs)
		discard.add_child(glow)

		_opp_discard_panels.append(discard)
		_opp_discard_stacks.append(disc_stack)
		_opp_discard_counts.append(disc_count)
		_opp_discard_glows.append(glow)

func _create_my_discard_glow() -> void:
	_my_discard_glow = Panel.new()
	_my_discard_glow.name = "MyGlow"
	_my_discard_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_my_discard_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_my_discard_glow.visible = false
	var gs := StyleBoxFlat.new()
	gs.bg_color = Color(0.9, 0.7, 0.2, 0.15)
	gs.border_width_left = 2; gs.border_width_top = 2
	gs.border_width_right = 2; gs.border_width_bottom = 2
	gs.border_color = Color(0.95, 0.78, 0.25, 0.85)
	gs.corner_radius_top_left = 8; gs.corner_radius_top_right = 8
	gs.corner_radius_bottom_left = 8; gs.corner_radius_bottom_right = 8
	_my_discard_glow.add_theme_stylebox_override("panel", gs)
	_my_discard.add_child(_my_discard_glow)

func _apply_opp_rack_style(panel: PanelContainer, opp_idx: int) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = OPP_COLORS[opp_idx].darkened(0.45)
	s.bg_color.a = 0.78
	s.border_width_left = 1; s.border_width_top = 1
	s.border_width_right = 1; s.border_width_bottom = 1
	s.border_color = OPP_COLORS[opp_idx]
	s.border_color.a = 0.58
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", s)

func _apply_discard_zone_style(panel: PanelContainer) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.16, 0.26, 0.18)
	s.border_width_left = 2; s.border_width_top = 2
	s.border_width_right = 2; s.border_width_bottom = 2
	s.border_color = Color(0.32, 0.62, 0.78, 0.52)
	s.border_blend = true
	s.shadow_color = Color(0, 0, 0, 0.08)
	s.shadow_size = 2
	s.corner_radius_top_left = 8; s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8; s.corner_radius_bottom_right = 8
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
	_controller.start_new_round(cfg, _game_seed, _player_count)
	_discard_tiles = [[], [], [], []]
	_selected_tile_ids.clear()
	_last_tile_id = -1
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

func _on_action_applied(player_index: int, action_type: int) -> void:
	_update_discard_from_action(player_index, action_type)
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

	var pts: int = _selected_points()
	_open_meter.text = "Open: %d/101" % pts
	_open_meter_bottom.text = "Open: %d/101" % pts
	_meld_hint.visible = _controller.state.table_melds.is_empty()
	_instructions.text = _instruction_for_state()

func _render_opponents() -> void:
	if _controller.state == null:
		return
	for i in range(min(3, _opp_count_labels.size())):
		var pi: int = i + 1
		if pi < _controller.state.players.size():
			_opp_count_labels[i].text = "%d tiles" % _controller.state.players[pi].hand.size()
		else:
			_opp_count_labels[i].text = "-"

func _render_discard_piles() -> void:
	# My discard
	_render_discard_stack(_my_discard_stack, _discard_tiles[0])
	_my_discard_count.text = "" if _discard_tiles[0].is_empty() else str(_discard_tiles[0].size())
	# Opponent discards
	for i in range(min(3, _opp_discard_stacks.size())):
		var pi: int = i + 1
		if pi < _discard_tiles.size():
			_render_discard_stack(_opp_discard_stacks[i], _discard_tiles[pi])
			_opp_discard_counts[i].text = "" if _discard_tiles[pi].is_empty() else str(_discard_tiles[pi].size())

func _render_discard_stack(stack_root: Control, tiles: Array) -> void:
	for child in stack_root.get_children():
		stack_root.remove_child(child)
		child.queue_free()
	if tiles.is_empty():
		return
	var start_idx: int = max(0, tiles.size() - 4)
	var vis_count: int = tiles.size() - start_idx
	for i in range(vis_count):
		var tile = tiles[start_idx + i]
		var chip := Panel.new()
		chip.custom_minimum_size = Vector2(38, 52)
		chip.size = Vector2(38, 52)
		chip.position = Vector2(4 + float(i * 2), float((vis_count - i - 1) * 3))
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(0.99, 0.97, 0.92, 1)
		cs.border_width_left = 1; cs.border_width_top = 1
		cs.border_width_right = 1; cs.border_width_bottom = 2
		cs.border_color = Color(0.76, 0.67, 0.52, 1)
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
			lbl.add_theme_font_size_override("font_size", 16)
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

func _update_discard_from_action(player_index: int, action_type: int) -> void:
	if _controller.state == null:
		return
	if action_type == Action.ActionType.STARTER_DISCARD or action_type == Action.ActionType.DISCARD:
		if _controller.state.discard_pile.is_empty():
			return
		var top_tile = _controller.state.discard_pile[_controller.state.discard_pile.size() - 1]
		if player_index >= 0 and player_index < _discard_tiles.size():
			_discard_tiles[player_index].append(top_tile)
	elif action_type == Action.ActionType.TAKE_DISCARD:
		var prev_p: int = _prev_player(player_index)
		if prev_p >= 0 and prev_p < _discard_tiles.size() and not _discard_tiles[prev_p].is_empty():
			_discard_tiles[prev_p].pop_back()

# ═══════════════════════════════════════════
# RACK
# ═══════════════════════════════════════════

func _render_rack() -> void:
	if _controller.state == null:
		return
	_ensure_slot_controls()
	_ensure_stage_slot_controls()
	var hand: Array = _rack_hand()
	_sync_slots_with_hand(hand)

	for slot in _slot_controls:
		for child in slot.get_children():
			if child.name == "SlotBg":
				continue
			slot.remove_child(child)
			child.queue_free()
	for slot in _stage_slot_controls:
		for child in slot.get_children():
			if child.name == "SlotBg":
				continue
			slot.remove_child(child)
			child.queue_free()
	_tile_controls.clear()

	var by_id: Dictionary = {}
	for tile in hand:
		by_id[tile.unique_id] = tile

	for slot_index in range(_rack_slots.size()):
		var tile_id: int = _rack_slots[slot_index]
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
	for slot_index in range(_stage_slots.size()):
		var tile_id: int = _stage_slots[slot_index]
		if tile_id == -1 or not by_id.has(tile_id):
			continue
		var tile_ctrl: OkeyTile = OKEY_TILE_SCENE.instantiate()
		tile_ctrl.setup(by_id[tile_id], 1000 + slot_index)
		tile_ctrl.set_zoom(_hand_zoom)
		tile_ctrl.clicked.connect(func(ctrl): _on_tile_clicked(ctrl))
		tile_ctrl.double_clicked.connect(func(ctrl): _on_tile_clicked(ctrl))
		tile_ctrl.drag_started.connect(func(ctrl): _on_tile_drag_started(ctrl))
		tile_ctrl.drag_ended.connect(func(ctrl, pos: Vector2): _on_tile_drag_ended(ctrl, pos))
		_stage_slot_controls[slot_index].add_child(tile_ctrl)
		_tile_controls[tile_id] = tile_ctrl

	if _last_tile_id == -1 and hand.size() > 0:
		_last_tile_id = hand[0].unique_id
	_prune_selected_ids()
	_apply_selection_and_required()

func _on_tile_clicked(tile_ctrl: OkeyTile) -> void:
	var tile_id: int = int(tile_ctrl.tile_data.unique_id)
	_last_tile_id = tile_id
	_selected_tile_ids.clear()
	_apply_selection_and_required()

func _on_tile_drag_started(tile_ctrl: OkeyTile) -> void:
	_last_tile_id = int(tile_ctrl.tile_data.unique_id)

func _on_tile_drag_ended(tile_ctrl: OkeyTile, global_pos: Vector2) -> void:
	if _controller.state == null:
		return
	if _action_in_flight:
		_render_rack()
		return

	var tile_id: int = int(tile_ctrl.tile_data.unique_id)
	var from_slot: int = _rack_slots.find(tile_id)
	var from_stage_slot: int = _stage_slots.find(tile_id)
	var phase: int = _controller.state.phase

	# Discard: drag to my discard zone
	if _is_my_turn() and (phase == GameState.Phase.STARTER_DISCARD or phase == GameState.Phase.TURN_DISCARD):
		if _my_discard.get_global_rect().has_point(global_pos):
			_discard_tile(tile_id)
			return
	# Fast path: during TURN_PLAY dropping to discard implicitly ends play then discards.
	if _is_my_turn() and phase == GameState.Phase.TURN_PLAY and _my_discard.get_global_rect().has_point(global_pos):
		_try_end_play_then_discard(tile_id)
		return

	# Meld: drag to existing meld cluster or melds panel
	if _is_my_turn() and phase == GameState.Phase.TURN_PLAY:
		var meld_index: int = _find_meld_cluster(global_pos)
		if meld_index != -1:
			_add_to_meld([tile_id], meld_index)
			return
		if _stage_panel != null and _stage_panel.get_global_rect().has_point(global_pos):
			var to_stage_slot: int = _find_stage_drop_slot(global_pos)
			if to_stage_slot != -1:
				if from_slot != -1:
					_move_rack_to_stage(from_slot, to_stage_slot)
					return
				if from_stage_slot != -1 and from_stage_slot != to_stage_slot:
					_move_stage_slot(from_stage_slot, to_stage_slot)
					return
			return

	# Rack reorder
	if _rack_panel.get_global_rect().has_point(global_pos):
		var to_slot: int = _find_drop_slot(global_pos)
		if from_slot != -1 and to_slot != -1 and to_slot != from_slot:
			_move_slot(from_slot, to_slot)
			return
		if from_stage_slot != -1 and to_slot != -1:
			_move_stage_to_rack(from_stage_slot, to_slot)
			return

	_render_rack()

func _try_end_play_then_discard(tile_id: int) -> void:
	if _action_in_flight:
		return
	if not _is_tile_in_my_hand(tile_id):
		_render_rack()
		return
	if _controller.state != null and _controller.state.phase == GameState.Phase.TURN_PLAY and _has_staged_tiles():
		var opened_before: bool = bool(_controller.state.players[0].has_opened)
		if not _submit_staged_melds():
			_restore_staged_to_rack()
			if not opened_before:
				_controller.apply_manual_penalty(0, 101)
				if _last_stage_error == "":
					_last_stage_error = "Invalid open"
				_instructions.text = "%s. Staged tiles returned, +101 penalty" % _last_stage_error
			else:
				if _last_stage_error == "":
					_last_stage_error = "Invalid staged melds"
				_instructions.text = "%s. Tiles returned to rack" % _last_stage_error
	_action_in_flight = true
	var end_res: Dictionary = _controller.end_play_turn(0)
	if not bool(end_res.get("ok", false)):
		_action_in_flight = false
		_instructions.text = "Rejected: %s" % str(end_res.get("reason", ""))
		return
	# state_changed from END_PLAY may clear this; force it for the follow-up discard action.
	_action_in_flight = true
	var discard_res: Dictionary = _controller.discard_tile(0, tile_id)
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
		for tid in tile_ids:
			_selected_tile_ids.erase(int(tid))

func _open_selected() -> void:
	if _action_in_flight:
		return
	var melds: Array = _build_melds_from_selected_slots()
	if melds.is_empty():
		_instructions.text = "Selected tiles do not form valid melds"
		return

	var open_by_pairs: bool = true
	for meld_dict in melds:
		if int(meld_dict.get("kind", -1)) != Meld.Kind.PAIRS:
			open_by_pairs = false
			break

	_action_in_flight = true
	var action: Action = Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds, "open_by_pairs": open_by_pairs})
	var result: Dictionary = _controller.apply_action_if_valid(0, action)
	if not bool(result.get("ok", false)):
		_action_in_flight = false
		_instructions.text = "Rejected: %s" % str(result.get("reason", ""))
	else:
		_selected_tile_ids.clear()

func _submit_staged_melds() -> bool:
	_last_stage_error = ""
	if _controller.state == null:
		_last_stage_error = "No game state"
		return false
	var player = _controller.state.players[0]
	var staged_ids: Array = _all_staged_tile_ids()
	if staged_ids.is_empty():
		_last_stage_error = "No staged tiles"
		return false

	# Opening turn: staged groups must form opening melds.
	if not bool(player.has_opened):
		var open_melds: Array = _build_melds_from_stage_slots()
		if open_melds.is_empty():
			_last_stage_error = "Staged groups are invalid (check color/sequence/group gaps)"
			return false
		var open_by_pairs: bool = true
		for meld_dict in open_melds:
			if int(meld_dict.get("kind", -1)) != Meld.Kind.PAIRS:
				open_by_pairs = false
				break
		_action_in_flight = true
		var open_action: Action = Action.new(Action.ActionType.OPEN_MELDS, {"melds": open_melds, "open_by_pairs": open_by_pairs})
		var open_result: Dictionary = _controller.apply_action_if_valid(0, open_action)
		if not bool(open_result.get("ok", false)):
			_action_in_flight = false
			_last_stage_error = str(open_result.get("reason", "Staged melds rejected"))
			return false
		_clear_stage_slots()
		return true

	# Already opened:
	# - opened_by_pairs: only layoff (ADD_TO_MELD)
	# - opened_by_melds: allow new meld creation + layoff.
	var used_ids: Dictionary = {}
	if not bool(player.opened_by_pairs):
		var new_melds: Array = _build_new_melds_from_stage_slots_opened()
		if not new_melds.is_empty():
			_action_in_flight = true
			var new_action: Action = Action.new(Action.ActionType.OPEN_MELDS, {"melds": new_melds, "open_by_pairs": false})
			var new_result: Dictionary = _controller.apply_action_if_valid(0, new_action)
			if not bool(new_result.get("ok", false)):
				_action_in_flight = false
				_last_stage_error = str(new_result.get("reason", "New melds rejected"))
				return false
			for m in new_melds:
				for tid in m.get("tile_ids", []):
					used_ids[int(tid)] = true

	var leftover_ids: Array = []
	for tid in staged_ids:
		if not used_ids.has(int(tid)):
			leftover_ids.append(int(tid))
	if not leftover_ids.is_empty():
		if not _apply_layoffs_for_tile_ids(leftover_ids):
			return false

	_clear_stage_slots()
	return true

func _all_staged_tile_ids() -> Array:
	var out: Array = []
	for tid in _stage_slots:
		var tile_id: int = int(tid)
		if tile_id != -1:
			out.append(tile_id)
	return out

func _build_new_melds_from_stage_slots_opened() -> Array:
	# For opened players, only contiguous groups of 3+ can become NEW table melds.
	# Singles and pairs are handled as layoffs via ADD_TO_MELD.
	if _controller.state == null:
		return []
	var hand_by_id: Dictionary = {}
	for tile in _rack_hand():
		hand_by_id[int(tile.unique_id)] = tile
	var validator: MeldValidator = MeldValidator.new()
	var out: Array = []
	for row_idx in range(2):
		var start_idx: int = row_idx * STAGE_ROW_SLOTS
		var end_idx: int = start_idx + STAGE_ROW_SLOTS
		var current: Array[int] = []
		for i in range(start_idx, end_idx):
			var tid: int = int(_stage_slots[i])
			if tid == -1:
				if current.size() >= 3:
					var meld_dict: Dictionary = _validate_new_meld_candidate(current, hand_by_id, validator)
					if not meld_dict.is_empty():
						out.append(meld_dict)
				current = []
				continue
			current.append(tid)
		if current.size() >= 3:
			var tail_meld: Dictionary = _validate_new_meld_candidate(current, hand_by_id, validator)
			if not tail_meld.is_empty():
				out.append(tail_meld)
	return out

func _validate_new_meld_candidate(ids: Array, hand_by_id: Dictionary, validator: MeldValidator) -> Dictionary:
	var tiles: Array = []
	for tid in ids:
		if not hand_by_id.has(int(tid)):
			return {}
		tiles.append(hand_by_id[int(tid)])
	var run_res: Dictionary = validator.validate_run(tiles, _controller.state.okey_context)
	if bool(run_res.get("ok", false)):
		return {"kind": Meld.Kind.RUN, "tile_ids": ids.duplicate()}
	var set_res: Dictionary = validator.validate_set(tiles, _controller.state.okey_context)
	if bool(set_res.get("ok", false)):
		return {"kind": Meld.Kind.SET, "tile_ids": ids.duplicate()}
	return {}

func _apply_layoffs_for_tile_ids(tile_ids: Array) -> bool:
	for tid in tile_ids:
		var placed: bool = false
		for meld_index in range(_controller.state.table_melds.size()):
			var action: Action = Action.new(Action.ActionType.ADD_TO_MELD, {"target_meld_index": meld_index, "tile_ids": [int(tid)]})
			_action_in_flight = true
			var result: Dictionary = _controller.apply_action_if_valid(0, action)
			if bool(result.get("ok", false)):
				placed = true
				break
			_action_in_flight = false
		if not placed:
			_last_stage_error = "Could not add staged tile %d to any meld" % int(tid)
			return false
	return true

func _build_melds_from_stage_slots() -> Array:
	if _controller.state == null:
		return []
	var hand_by_id: Dictionary = {}
	for tile in _rack_hand():
		hand_by_id[int(tile.unique_id)] = tile
	var groups: Array = []
	for row_idx in range(2):
		var start_idx: int = row_idx * STAGE_ROW_SLOTS
		var end_idx: int = start_idx + STAGE_ROW_SLOTS
		var current: Array[int] = []
		for i in range(start_idx, end_idx):
			var tid: int = int(_stage_slots[i])
			if tid == -1:
				if not current.is_empty():
					groups.append(current)
					current = []
				continue
			current.append(tid)
		if not current.is_empty():
			groups.append(current)
	if groups.is_empty():
		return []

	var validator: MeldValidator = MeldValidator.new()
	var out: Array = []
	for g in groups:
		var ids: Array = g
		var tiles: Array = []
		for tid in ids:
			if not hand_by_id.has(int(tid)):
				return []
			tiles.append(hand_by_id[int(tid)])
		if ids.size() < 2:
			return []
		if ids.size() == 2:
			var pair_chunks: Array = _pair_melds(ids, tiles)
			if pair_chunks.is_empty():
				return []
			for pair_meld in pair_chunks:
				out.append(pair_meld)
			continue
		var run_res: Dictionary = validator.validate_run(tiles, _controller.state.okey_context)
		if bool(run_res.get("ok", false)):
			out.append({"kind": Meld.Kind.RUN, "tile_ids": ids})
			continue
		var set_res: Dictionary = validator.validate_set(tiles, _controller.state.okey_context)
		if bool(set_res.get("ok", false)):
			out.append({"kind": Meld.Kind.SET, "tile_ids": ids})
			continue
		if ids.size() % 2 == 0:
			var pair_melds: Array = _pair_melds(ids, tiles)
			if not pair_melds.is_empty():
				for m in pair_melds:
					out.append(m)
				continue
		return []
	return out

func _has_staged_tiles() -> bool:
	for tid in _stage_slots:
		if int(tid) != -1:
			return true
	return false

func _restore_staged_to_rack() -> void:
	for i in range(_stage_slots.size()):
		var tid: int = int(_stage_slots[i])
		if tid == -1:
			continue
		var empty_idx: int = _rack_slots.find(-1)
		if empty_idx != -1:
			_rack_slots[empty_idx] = tid
		_stage_slots[i] = -1
	_render_rack()

func _clear_stage_slots() -> void:
	for i in range(_stage_slots.size()):
		_stage_slots[i] = -1

# ═══════════════════════════════════════════
# MELD BUILDING & DISPLAY
# ═══════════════════════════════════════════

func _build_melds_from_selected_slots() -> Array:
	if _controller.state == null:
		return []
	var hand: Array = _rack_hand()
	if hand.is_empty():
		return []

	var selected_slots: Array[int] = []
	for i in range(_rack_slots.size()):
		var tile_id: int = _rack_slots[i]
		if tile_id != -1 and _selected_tile_ids.has(tile_id):
			selected_slots.append(i)
	if selected_slots.is_empty():
		return []
	selected_slots.sort()

	var by_id: Dictionary = {}
	for tile in hand:
		by_id[tile.unique_id] = tile

	var validator: MeldValidator = MeldValidator.new()
	var selected_ids: Array = []
	var selected_tiles: Array = []
	for slot_idx in selected_slots:
		var selected_id: int = _rack_slots[int(slot_idx)]
		if selected_id == -1 or not by_id.has(selected_id):
			return []
		selected_ids.append(selected_id)
		selected_tiles.append(by_id[selected_id])

	# First try: all selected tiles as a single meld (most intuitive drag behavior).
	if selected_ids.size() >= 3:
		var one_run: Dictionary = validator.validate_run(selected_tiles, _controller.state.okey_context)
		if bool(one_run.get("ok", false)):
			return [{"kind": Meld.Kind.RUN, "tile_ids": selected_ids}]
		var one_set: Dictionary = validator.validate_set(selected_tiles, _controller.state.okey_context)
		if bool(one_set.get("ok", false)):
			return [{"kind": Meld.Kind.SET, "tile_ids": selected_ids}]
	if selected_ids.size() >= 2 and selected_ids.size() % 2 == 0:
		var one_pairs: Array = _pair_melds(selected_ids, selected_tiles)
		if not one_pairs.is_empty():
			return one_pairs

	# Fallback: split by rack row + non-adjacent slots.
	var groups: Array = []
	var current_group: Array[int] = []
	var prev_slot: int = -1000
	for slot_idx in selected_slots:
		var row_changed: bool = (prev_slot < RACK_ROW_SLOTS and slot_idx >= RACK_ROW_SLOTS) or (prev_slot >= RACK_ROW_SLOTS and slot_idx < RACK_ROW_SLOTS)
		if current_group.is_empty() or (slot_idx == prev_slot + 1 and not row_changed):
			current_group.append(slot_idx)
		else:
			groups.append(current_group)
			current_group = [slot_idx]
		prev_slot = slot_idx
	if not current_group.is_empty():
		groups.append(current_group)

	var out: Array = []
	for slot_group in groups:
		var ids: Array = []
		var tiles: Array = []
		for slot_group_idx in slot_group:
			var tile_id: int = _rack_slots[int(slot_group_idx)]
			if tile_id == -1 or not by_id.has(tile_id):
				return []
			ids.append(tile_id)
			tiles.append(by_id[tile_id])
		if ids.size() < 2:
			return []

		var run_res: Dictionary = validator.validate_run(tiles, _controller.state.okey_context)
		if bool(run_res.get("ok", false)):
			out.append({"kind": Meld.Kind.RUN, "tile_ids": ids})
			continue

		var set_res: Dictionary = validator.validate_set(tiles, _controller.state.okey_context)
		if bool(set_res.get("ok", false)):
			out.append({"kind": Meld.Kind.SET, "tile_ids": ids})
			continue

		var pair_chunks: Array = _pair_melds(ids, tiles)
		if pair_chunks.is_empty():
			return []
		for pair_meld in pair_chunks:
			out.append(pair_meld)
	return out

func _pair_melds(ids: Array, tiles: Array) -> Array:
	if ids.size() < 2 or ids.size() % 2 != 0:
		return []
	var out: Array = []
	for i in range(0, ids.size(), 2):
		var a = tiles[i]
		var b = tiles[i + 1]
		if int(a.color) != int(b.color) or int(a.number) != int(b.number):
			return []
		out.append({"kind": Meld.Kind.PAIRS, "tile_ids": [ids[i], ids[i + 1]]})
	return out

func _render_melds() -> void:
	for node in _meld_clusters:
		if node != null and is_instance_valid(node):
			if node.get_parent() == _meld_island:
				_meld_island.remove_child(node)
			node.queue_free()
	_meld_clusters.clear()

	if _controller.state == null:
		return

	var x: float = 4.0
	var lane: int = 0
	var max_w: float = max(200.0, _meld_island.size.x - 16.0)
	for i in range(_controller.state.table_melds.size()):
		var meld = _controller.state.table_melds[i]
		var tile_count: int = int(meld.tiles.size())
		var width: float = 80.0 + float(tile_count) * 20.0
		if x + width > max_w:
			x = 4.0
			lane = min(MELD_LANE_Y.size() - 1, lane + 1)

		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(width, 40)
		panel.position = Vector2(x, MELD_LANE_Y[lane])
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.set_meta("meld_index", i)

		var label := Label.new()
		label.text = _meld_text(meld)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(label)

		_meld_island.add_child(panel)
		_meld_clusters.append(panel)
		x += width + 8.0

func _meld_text(meld) -> String:
	var kind_text: String = "MELD"
	match int(meld.kind):
		Meld.Kind.RUN:
			kind_text = "RUN"
		Meld.Kind.SET:
			kind_text = "SET"
		Meld.Kind.PAIRS:
			kind_text = "PAIRS"
	return "%s (%d)" % [kind_text, int(meld.tiles.size())]

func _find_meld_cluster(global_pos: Vector2) -> int:
	for cluster in _meld_clusters:
		if cluster == null or not is_instance_valid(cluster):
			continue
		if cluster.get_global_rect().has_point(global_pos):
			return int(cluster.get_meta("meld_index", -1))
	return -1

# ═══════════════════════════════════════════
# RACK SLOT MANAGEMENT
# ═══════════════════════════════════════════

func _init_rack_slots() -> void:
	_rack_slots.clear()
	for _i in range(RACK_SLOT_COUNT):
		_rack_slots.append(-1)

func _init_stage_slots() -> void:
	_stage_slots.clear()
	for _i in range(STAGE_SLOT_COUNT):
		_stage_slots.append(-1)

func _create_stage_area() -> void:
	_stage_panel = PanelContainer.new()
	_stage_panel.name = "StagePanel"
	_stage_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.11, 0.17, 0.35)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.20, 0.50, 0.66, 0.35)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	_stage_panel.add_theme_stylebox_override("panel", panel_style)
	_melds_panel.add_child(_stage_panel)

	var stage_vbox := VBoxContainer.new()
	stage_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_vbox.add_theme_constant_override("separation", 4)
	_stage_panel.add_child(stage_vbox)

	var stage_title := Label.new()
	stage_title.text = "Staging: place tiles here before ending turn"
	stage_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_title.add_theme_color_override("font_color", Color(0.70, 0.86, 0.92, 0.75))
	stage_title.add_theme_font_size_override("font_size", 11)
	stage_vbox.add_child(stage_title)

	_stage_row1 = HBoxContainer.new()
	_stage_row1.alignment = BoxContainer.ALIGNMENT_CENTER
	_stage_row1.add_theme_constant_override("separation", 4)
	_stage_row1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_vbox.add_child(_stage_row1)

	_stage_row2 = HBoxContainer.new()
	_stage_row2.alignment = BoxContainer.ALIGNMENT_CENTER
	_stage_row2.add_theme_constant_override("separation", 4)
	_stage_row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_vbox.add_child(_stage_row2)

func _ensure_stage_slot_controls() -> void:
	if _stage_panel == null or _stage_row1 == null or _stage_row2 == null:
		return
	if _stage_slot_controls.size() == STAGE_SLOT_COUNT:
		for slot in _stage_slot_controls:
			slot.custom_minimum_size = _slot_size
		return
	for child in _stage_row1.get_children():
		child.queue_free()
	for child in _stage_row2.get_children():
		child.queue_free()
	_stage_slot_controls.clear()
	for i in range(STAGE_SLOT_COUNT):
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = _slot_size
		slot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var ss := StyleBoxFlat.new()
		ss.bg_color = Color(0.95, 0.85, 0.72, 0.14)
		ss.border_width_left = 1
		ss.border_width_top = 1
		ss.border_width_right = 1
		ss.border_width_bottom = 1
		ss.border_color = Color(0.33, 0.23, 0.14, 0.35)
		ss.corner_radius_top_left = 5
		ss.corner_radius_top_right = 5
		ss.corner_radius_bottom_left = 5
		ss.corner_radius_bottom_right = 5
		slot_panel.add_theme_stylebox_override("panel", ss)

		var slot_bg := Panel.new()
		slot_bg.name = "SlotBg"
		slot_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_bg.modulate = Color(1, 1, 1, 0.06)
		slot_panel.add_child(slot_bg)

		if i < STAGE_ROW_SLOTS:
			_stage_row1.add_child(slot_panel)
		else:
			_stage_row2.add_child(slot_panel)
		_stage_slot_controls.append(slot_panel)

func _ensure_slot_controls() -> void:
	if _slot_controls.size() == RACK_SLOT_COUNT:
		for slot in _slot_controls:
			slot.custom_minimum_size = _slot_size
		return

	for child in _row1.get_children():
		child.queue_free()
	for child in _row2.get_children():
		child.queue_free()
	_slot_controls.clear()

	for i in range(RACK_SLOT_COUNT):
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = _slot_size
		slot_panel.mouse_filter = Control.MOUSE_FILTER_PASS

		var ss := StyleBoxFlat.new()
		ss.bg_color = Color(0.95, 0.85, 0.72, 0.22)
		ss.border_width_left = 1; ss.border_width_top = 1
		ss.border_width_right = 1; ss.border_width_bottom = 2
		ss.border_color = Color(0.33, 0.23, 0.14, 0.5)
		ss.corner_radius_top_left = 5; ss.corner_radius_top_right = 5
		ss.corner_radius_bottom_left = 5; ss.corner_radius_bottom_right = 5
		slot_panel.add_theme_stylebox_override("panel", ss)

		var slot_bg := Panel.new()
		slot_bg.name = "SlotBg"
		slot_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_bg.modulate = Color(1, 1, 1, 0.08)
		slot_panel.add_child(slot_bg)

		if i < RACK_ROW_SLOTS:
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
	var in_hand: Dictionary = {}
	for tile in hand:
		in_hand[tile.unique_id] = true
	for i in range(_rack_slots.size()):
		var tile_id: int = _rack_slots[i]
		if tile_id != -1 and not in_hand.has(tile_id):
			_rack_slots[i] = -1
	for i in range(_stage_slots.size()):
		var tile_id: int = _stage_slots[i]
		if tile_id != -1 and not in_hand.has(tile_id):
			_stage_slots[i] = -1
	for tile in hand:
		if _rack_slots.has(tile.unique_id) or _stage_slots.has(tile.unique_id):
			continue
		var empty_idx: int = _rack_slots.find(-1)
		if empty_idx == -1:
			empty_idx = _stage_slots.find(-1)
			if empty_idx != -1:
				_stage_slots[empty_idx] = tile.unique_id
			continue
		if empty_idx == -1:
			break
		_rack_slots[empty_idx] = tile.unique_id

func _prune_selected_ids() -> void:
	var valid: Dictionary = {}
	for tile in _rack_hand():
		valid[tile.unique_id] = true
	var keys: Array = _selected_tile_ids.keys()
	for key in keys:
		if not valid.has(key):
			_selected_tile_ids.erase(key)

func _apply_selection_and_required() -> void:
	var required_id: int = -1
	if _controller.state != null:
		required_id = _controller.state.turn_required_use_tile_id
	for tile_id in _tile_controls.keys():
		var tile_ctrl: OkeyTile = _tile_controls[tile_id]
		var selected: bool = _selected_tile_ids.has(tile_id) or int(tile_id) == _last_tile_id
		if required_id != -1 and int(tile_id) == required_id:
			selected = true
		tile_ctrl.set_selected(selected)

func _selected_points() -> int:
	if _controller.state == null:
		return 0
	var melds: Array = _build_melds_from_stage_slots()
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
	var row1_cy: float = _row1.get_global_rect().get_center().y
	var row2_cy: float = _row2.get_global_rect().get_center().y
	var use_row2: bool = absf(global_pos.y - row2_cy) < absf(global_pos.y - row1_cy)
	var start_i: int = RACK_ROW_SLOTS if use_row2 else 0
	var stop_i: int = RACK_SLOT_COUNT if use_row2 else RACK_ROW_SLOTS
	var best_i: int = start_i
	var best_d: float = INF
	for i in range(start_i, stop_i):
		var d: float = _slot_controls[i].get_global_rect().get_center().distance_squared_to(global_pos)
		if d < best_d:
			best_d = d
			best_i = i
	return best_i

func _find_stage_drop_slot(global_pos: Vector2) -> int:
	for i in range(_stage_slot_controls.size()):
		if _stage_slot_controls[i].get_global_rect().grow(10.0).has_point(global_pos):
			return i
	if _stage_slot_controls.is_empty():
		return -1
	var row1_cy: float = _stage_row1.get_global_rect().get_center().y
	var row2_cy: float = _stage_row2.get_global_rect().get_center().y
	var use_row2: bool = absf(global_pos.y - row2_cy) < absf(global_pos.y - row1_cy)
	var start_i: int = STAGE_ROW_SLOTS if use_row2 else 0
	var stop_i: int = STAGE_SLOT_COUNT if use_row2 else STAGE_ROW_SLOTS
	var best_i: int = start_i
	var best_d: float = INF
	for i in range(start_i, stop_i):
		var d: float = _stage_slot_controls[i].get_global_rect().get_center().distance_squared_to(global_pos)
		if d < best_d:
			best_d = d
			best_i = i
	return best_i

func _move_slot(from_slot: int, to_slot: int) -> void:
	if from_slot < 0 or from_slot >= _rack_slots.size():
		return
	if to_slot < 0 or to_slot >= _rack_slots.size():
		return
	var tile_id: int = _rack_slots[from_slot]
	if tile_id == -1:
		return
	# Swap behavior prevents row cascade/overflow while still allowing free placement.
	var other_id: int = _rack_slots[to_slot]
	_rack_slots[to_slot] = tile_id
	_rack_slots[from_slot] = other_id
	_last_tile_id = tile_id
	_render_rack()

func _move_rack_to_stage(from_slot: int, to_stage_slot: int) -> void:
	if from_slot < 0 or from_slot >= _rack_slots.size():
		return
	if to_stage_slot < 0 or to_stage_slot >= _stage_slots.size():
		return
	var tile_id: int = _rack_slots[from_slot]
	if tile_id == -1:
		return
	var other_id: int = _stage_slots[to_stage_slot]
	_stage_slots[to_stage_slot] = tile_id
	_rack_slots[from_slot] = other_id
	_last_tile_id = tile_id
	_render_rack()

func _move_stage_to_rack(from_stage_slot: int, to_slot: int) -> void:
	if from_stage_slot < 0 or from_stage_slot >= _stage_slots.size():
		return
	if to_slot < 0 or to_slot >= _rack_slots.size():
		return
	var tile_id: int = _stage_slots[from_stage_slot]
	if tile_id == -1:
		return
	var other_id: int = _rack_slots[to_slot]
	_rack_slots[to_slot] = tile_id
	_stage_slots[from_stage_slot] = other_id
	_last_tile_id = tile_id
	_render_rack()

func _move_stage_slot(from_slot: int, to_slot: int) -> void:
	if from_slot < 0 or from_slot >= _stage_slots.size():
		return
	if to_slot < 0 or to_slot >= _stage_slots.size():
		return
	var tile_id: int = _stage_slots[from_slot]
	if tile_id == -1:
		return
	var other_id: int = _stage_slots[to_slot]
	_stage_slots[to_slot] = tile_id
	_stage_slots[from_slot] = other_id
	_last_tile_id = tile_id
	_render_rack()

# ═══════════════════════════════════════════
# BOT TURNS
# ═══════════════════════════════════════════

func _maybe_auto_bot_turn() -> void:
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
		if action == null:
			_instructions.text = "Bot stalled (no legal action)"
			break
		var result: Dictionary = _controller.apply_action_if_valid(bot_index, action)
		if not bool(result.get("ok", false)):
			var fallback_try = _bot_fallback.choose_action(_controller.state, bot_index)
			if fallback_try != null:
				var fallback_try_res: Dictionary = _controller.apply_action_if_valid(bot_index, fallback_try)
				if bool(fallback_try_res.get("ok", false)):
					continue
			var fallback: Action = null
			if _controller.state.phase == GameState.Phase.TURN_DRAW:
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
				_instructions.text = "Bot stalled (%s)" % str(fb_res.get("reason", "unknown"))
				break
	_bot_loop_running = false

# ═══════════════════════════════════════════
# ROUND END DIALOG
# ═══════════════════════════════════════════

func _show_round_end_dialog() -> void:
	if _controller.state == null:
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

# ═══════════════════════════════════════════
# RESPONSIVE LAYOUT
# ═══════════════════════════════════════════

func _apply_responsive_layout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var margin: float = OUTER_MARGIN
	var top_h: float = TOP_BAR_HEIGHT
	var table_top: float = top_h + 10.0
	var table_h: float = clamp(vp.y * 0.47, TABLE_MIN_HEIGHT, TABLE_MAX_HEIGHT)
	_set_rect_pixels(_table_area, margin, table_top, vp.x - margin * 2.0, table_h)

	var center_w: float = clamp(_table_area.size.x * 0.30, 340.0, 460.0)
	_set_rect_pixels(_center_zone, (_table_area.size.x - center_w) * 0.5, 8.0, center_w, 90.0)
	_set_rect_pixels(_melds_panel, 18.0, 96.0, _table_area.size.x - 36.0, _table_area.size.y - 112.0)
	if _stage_panel != null:
		var stage_h: float = 154.0
		_set_rect_pixels(_stage_panel, 8.0, _melds_panel.size.y - stage_h - 8.0, _melds_panel.size.x - 16.0, stage_h)
		_set_rect_pixels(_meld_island, 8.0, 24.0, _melds_panel.size.x - 16.0, _melds_panel.size.y - stage_h - 32.0)

	var tile_w: float = clamp((vp.x - margin * 2.0 - 24.0 - float(RACK_ROW_SLOTS - 1) * 4.0) / float(RACK_ROW_SLOTS), 36.0, 56.0)
	var tile_h: float = clamp(tile_w * 1.38, 58.0, 84.0)
	_slot_size = Vector2(tile_w, tile_h)
	var rack_w: float = float(RACK_ROW_SLOTS) * tile_w + float(RACK_ROW_SLOTS - 1) * 4.0 + 24.0
	rack_w = min(rack_w, vp.x - margin * 2.0)
	var rack_y: float = table_top + table_h + 12.0
	var rack_h: float = clamp(vp.y - rack_y - 12.0, RACK_MIN_HEIGHT, RACK_MAX_HEIGHT)
	_set_rect_pixels(_rack_panel, (vp.x - rack_w) * 0.5, rack_y, rack_w, rack_h)

	var meld_local_pos: Vector2 = _melds_panel.position
	var meld_size: Vector2 = _melds_panel.size
	var zone_margin: float = 10.0
	var opp_disc_rects: Array[Rect2] = [
		Rect2(meld_local_pos.x + zone_margin, meld_local_pos.y + zone_margin, DISCARD_ZONE_SIZE.x, DISCARD_ZONE_SIZE.y), # P2 top-left
		Rect2(meld_local_pos.x + meld_size.x - DISCARD_ZONE_SIZE.x - zone_margin, meld_local_pos.y + zone_margin, DISCARD_ZONE_SIZE.x, DISCARD_ZONE_SIZE.y), # P1 top-right
		Rect2(meld_local_pos.x + zone_margin, meld_local_pos.y + meld_size.y - DISCARD_ZONE_SIZE.y - zone_margin, DISCARD_ZONE_SIZE.x, DISCARD_ZONE_SIZE.y), # P3 bottom-left
	]
	for i in range(min(_opp_discard_panels.size(), opp_disc_rects.size())):
		var r: Rect2 = opp_disc_rects[i]
		_set_rect_pixels(_opp_discard_panels[i], r.position.x, r.position.y, r.size.x, r.size.y)

	var badge_w: float = 100.0
	var badge_h: float = 56.0
	var opp_rack_rects: Array[Rect2] = [
		Rect2(_table_area.size.x - badge_w - 4.0, _table_area.size.y * 0.50 - badge_h * 0.5, badge_w, badge_h), # right
		Rect2((_table_area.size.x - badge_w) * 0.5, 2.0, badge_w, badge_h), # top
		Rect2(4.0, _table_area.size.y * 0.50 - badge_h * 0.5, badge_w, badge_h), # left
	]
	for i in range(min(_opp_rack_panels.size(), opp_rack_rects.size())):
		var rr: Rect2 = opp_rack_rects[i]
		_set_rect_pixels(_opp_rack_panels[i], rr.position.x, rr.position.y, rr.size.x, rr.size.y)

	var my_discard_x: float = _table_area.position.x + meld_local_pos.x + meld_size.x - DISCARD_ZONE_SIZE.x - zone_margin
	var my_discard_y: float = _table_area.position.y + meld_local_pos.y + meld_size.y - DISCARD_ZONE_SIZE.y - zone_margin
	_set_rect_pixels(_my_discard, my_discard_x, my_discard_y, DISCARD_ZONE_SIZE.x, DISCARD_ZONE_SIZE.y)

	_ensure_slot_controls()
	if _controller.state != null:
		_render_all()

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
	if _controller.state == null:
		return "Starting round..."
	if not _is_my_turn():
		return "Waiting for bots..."
	match _controller.state.phase:
		GameState.Phase.STARTER_DISCARD:
			return "Starter: drag one tile to your corner discard slot"
		GameState.Phase.TURN_DRAW:
			return "Tap deck to draw, or previous player's corner discard if you can use it"
		GameState.Phase.TURN_PLAY:
			return "Drag tiles to staging slots. Drag to discard corner to end turn."
		GameState.Phase.TURN_DISCARD:
			return "Drag one tile to your corner discard slot"
		GameState.Phase.ROUND_END:
			return "Round ended"
		_:
			return "Play"

func _phase_name(phase: int) -> String:
	match phase:
		GameState.Phase.SETUP: return "Setup"
		GameState.Phase.STARTER_DISCARD: return "Start"
		GameState.Phase.TURN_DRAW: return "Draw"
		GameState.Phase.TURN_PLAY: return "Play"
		GameState.Phase.TURN_DISCARD: return "Discard"
		GameState.Phase.ROUND_END: return "End"
		_: return "-"

func _tile_label(tile) -> String:
	if tile == null:
		return "-"
	if int(tile.kind) != int(Tile.Kind.NORMAL):
		return "F-%d" % int(tile.number)
	return "%s-%d" % [_color_letter(int(tile.color)), int(tile.number)]

func _tile_color(tile) -> Color:
	if tile == null:
		return Color(0.95, 0.95, 0.95)
	match int(tile.color):
		Tile.TileColor.RED: return Color(0.85, 0.12, 0.1)
		Tile.TileColor.BLUE: return Color(0.1, 0.4, 0.75)
		Tile.TileColor.BLACK: return Color(0.12, 0.12, 0.15)
		Tile.TileColor.YELLOW: return Color(0.8, 0.6, 0.05)
		_: return Color(0.95, 0.95, 0.95)

func _color_letter(color_value: int) -> String:
	match color_value:
		Tile.TileColor.RED: return "R"
		Tile.TileColor.BLUE: return "B"
		Tile.TileColor.BLACK: return "K"
		Tile.TileColor.YELLOW: return "Y"
		_: return "?"

func _is_primary_tap(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		return mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		return st.pressed
	return false

func _is_my_turn() -> bool:
	return _controller.state != null and int(_controller.state.current_player_index) == 0

func _is_tile_in_my_hand(tile_id: int) -> bool:
	for tile in _rack_hand():
		if int(tile.unique_id) == tile_id:
			return true
	return false

func _prev_player(player_index: int) -> int:
	if _controller.state == null:
		return 0
	var count: int = _controller.state.players.size()
	if count <= 0:
		return 0
	return (player_index - 1 + count) % count
