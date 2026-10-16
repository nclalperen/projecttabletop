## Unified Vector Game Table for Okey 101.
## Pure 2D / 2.5D vector tabletop architecture replacing 3D meshes and rigid grids.
## Driven by mathematical spring dynamics, fluid continuous rack layout, and OkeySession logic.
class_name VectorGameTable
extends Control

const OKEY_SESSION = preload("res://ui/game_table/OkeySession.gd")
const VectorTableFelt2D = preload("res://ui/vector_table/table/VectorTableFelt2D.gd")
const FluidRack2D = preload("res://ui/vector_table/rack/FluidRack2D.gd")
const VectorTile2D = preload("res://ui/vector_table/render/VectorTile2D.gd")

# Scene components
var _felt: VectorTableFelt2D
var _rack: FluidRack2D
var _melds_container: Control
var _top_bar: PanelContainer
var _status_label: Label
var _deck_info_label: Label
var _action_dock: HBoxContainer
var _btn_sort_runs: Button
var _btn_sort_pairs: Button
var _btn_open_melds: Button

# Authoritative Session
var _session: Node = null
var _is_my_turn: bool = false
var _current_phase: int = 1


func _init() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_ui_tree()


func _ready() -> void:
	if _session == null:
		_init_session()


func _build_ui_tree() -> void:
	# 1. Procedural Felt Table Background
	_felt = VectorTableFelt2D.new()
	_felt.anchor_right = 1.0
	_felt.anchor_bottom = 1.0
	_felt.deck_clicked.connect(_on_deck_clicked)
	_felt.discard_left_clicked.connect(_on_discard_left_clicked)
	add_child(_felt)

	# 2. Center Melds Area
	_melds_container = Control.new()
	_melds_container.name = "MeldsArea"
	_melds_container.anchor_right = 1.0
	_melds_container.anchor_bottom = 1.0
	_melds_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_melds_container)

	# 3. Continuous Fluid Rack (Anchored at bottom center)
	_rack = FluidRack2D.new()
	_rack.name = "FluidRack"
	_rack.anchor_left = 0.5
	_rack.anchor_right = 0.5
	_rack.anchor_top = 1.0
	_rack.anchor_bottom = 1.0
	_rack.offset_left = -FluidRack2D.RACK_WIDTH * 0.5
	_rack.offset_right = FluidRack2D.RACK_WIDTH * 0.5
	_rack.offset_top = -FluidRack2D.RACK_HEIGHT - 48.0
	_rack.offset_bottom = -48.0
	_rack.tile_action_requested.connect(_on_rack_tile_action)
	add_child(_rack)

	# 4. Top Status Bar
	_top_bar = PanelContainer.new()
	_top_bar.anchor_left = 0.5
	_top_bar.anchor_right = 0.5
	_top_bar.offset_left = -320.0
	_top_bar.offset_right = 320.0
	_top_bar.offset_top = 16.0
	_top_bar.offset_bottom = 54.0

	var top_hbox := HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_top_bar.add_child(top_hbox)

	_status_label = Label.new()
	_status_label.text = "Vector Tabletop Ready"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_hbox.add_child(_status_label)

	add_child(_top_bar)

	# 5. Bottom Action Dock (Smart Sort & Open Melds)
	_action_dock = HBoxContainer.new()
	_action_dock.anchor_left = 0.5
	_action_dock.anchor_right = 0.5
	_action_dock.anchor_top = 1.0
	_action_dock.anchor_bottom = 1.0
	_action_dock.offset_left = -260.0
	_action_dock.offset_right = 260.0
	_action_dock.offset_top = -42.0
	_action_dock.offset_bottom = -10.0
	_action_dock.alignment = BoxContainer.ALIGNMENT_CENTER

	_btn_sort_runs = Button.new()
	_btn_sort_runs.text = "Seri Diz (Runs)"
	_btn_sort_runs.pressed.connect(func(): _session.overlay_sort_rack(&"runs"))
	_action_dock.add_child(_btn_sort_runs)

	_btn_sort_pairs = Button.new()
	_btn_sort_pairs.text = "Çift Diz (Pairs)"
	_btn_sort_pairs.pressed.connect(func(): _session.overlay_sort_rack(&"pairs"))
	_action_dock.add_child(_btn_sort_pairs)

	_btn_open_melds = Button.new()
	_btn_open_melds.text = "Melds Aç (Open)"
	_btn_open_melds.pressed.connect(func(): _session.action_open_melds())
	_action_dock.add_child(_btn_open_melds)

	add_child(_action_dock)


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

	# Update felt deck & indicator
	var deck_count: int = int(snapshot.get("deck_count", 0))
	var ind_tile = snapshot.get("indicator_tile")
	var ind_dict: Dictionary = {}
	if ind_tile != null:
		ind_dict = {
			"unique_id": ind_tile.unique_id,
			"number": ind_tile.number,
			"color": ind_tile.color,
			"kind": ind_tile.kind
		}
	_felt.update_deck(deck_count, ind_dict)


func _get_tile_by_id(tile_id: int):
	var controller = _session.get_controller() if _session != null else null
	if controller == null or controller.state == null or controller.state.players.is_empty():
		return null
	for t in controller.state.players[0].hand:
		if int(t.unique_id) == tile_id:
			return t
	return null


func _on_rack_and_draft_changed(rack_slots: Array, _draft_slots: Array, validation: Dictionary) -> void:
	var tiles_data: Array = []
	for tile_id in rack_slots:
		if tile_id == -1:
			continue
		var tile = _get_tile_by_id(tile_id)
		if tile != null:
			tiles_data.append({
				"unique_id": tile.unique_id,
				"number": tile.number,
				"color": tile.color,
				"kind": tile.kind,
				"is_valid": (validation.get("valid_tile_ids", []) as Array).has(tile.unique_id)
			})
	_rack.set_tiles(tiles_data)


func _on_melds_updated(melds: Array) -> void:
	# Clear existing vector meld displays
	for child in _melds_container.get_children():
		child.queue_free()

	if melds.is_empty():
		return

	# Layout table melds in organic horizontal clusters
	var center := size * 0.5
	var start_y := center.y - 40.0
	var group_x := center.x - 280.0

	for meld in melds:
		var tiles: Array = meld.get("tiles", [])
		for i in range(tiles.size()):
			var data: Dictionary = tiles[i]
			var t := VectorTile2D.new()
			t.setup_tile(
				data.get("unique_id", -1),
				data.get("number", 1),
				data.get("color", 0),
				data.get("kind", 0) != 0,
				true
			)
			t.set_target_position(Vector2(group_x + (i * 38.0), start_y), true)
			_melds_container.add_child(t)
		group_x += (tiles.size() * 38.0) + 32.0


func _on_discard_updated(seat_idx: int, tile_data: Dictionary) -> void:
	_felt.update_discard(seat_idx, tile_data)


func _on_deck_clicked() -> void:
	if _is_my_turn and _current_phase == 1:
		_session.action_draw_tile()


func _on_discard_left_clicked() -> void:
	if _is_my_turn and _current_phase == 1:
		_session.action_take_discard()


func _on_rack_tile_action(tile: VectorTile2D, action: StringName) -> void:
	if action == &"discard":
		if _is_my_turn and (_current_phase == 2 or _current_phase == 3):
			_session.action_discard(tile.unique_id)
