class_name BoardLayoutTuner3D
extends CanvasLayer
## Interactive Real-Time 3D Board Layout Studio for VectorGameTable3D.
## Allows live manual adjustment of:
## - Player HandRig3D (position, rotation, scale, row offsets, tile pitch)
## - Opponent Racks (Seats 1..3 position, orientation/yaw, scale)
## - Meld Area (zone offset, orientation/yaw, per-seat orientation, per-seat offsets/yaw, spacing)
## - Discard Areas (Seats 0..3 position, orientation/yaw, scale)
## - Stock Pile, Indicator Tile, and Camera3D framing
## Supports both direct 3D mouse click-and-drag + scroll-wheel rotation on the table
## AND precision sliders, live test scenario spawning, and direct save to VectorTuning3D.gd.

const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")

var board: Node3D = null
var is_open: bool = false
var drag_3d_enabled: bool = true

# Currently selected 3D target for gizmo & 3D dragging:
# e.g. "opp_1", "opp_2", "opp_3", "meld_0", "meld_1", "meld_2", "meld_3", "discard_0", "discard_1", "discard_2", "discard_3", "stock", "indicator"
var selected_target: String = "meld_0"
var _is_dragging_3d: bool = false
var _drag_offset_xz: Vector2 = Vector2.ZERO

# UI references
var _toggle_btn: Button = null
var _panel: PanelContainer = null
var _status_label: Label = null
var _tabs: TabContainer = null
var _slider_Controls: Dictionary = {} # key -> {slider: HSlider, value_label: Label}
var _updating_ui: bool = false

# Selected sub-indices in tabs
var _selected_opp_seat: int = 1
var _selected_discard_seat: int = 0
var _selected_meld_seat: int = 0
var _discard_scales: Dictionary = {0: 1.0, 1: 1.0, 2: 1.0, 3: 1.0}

# 3D Wireframe Gizmo Node
var _gizmo_instance: MeshInstance3D = null
var _gizmo_mesh: ImmediateMesh = null
var _gizmo_mat: StandardMaterial3D = null

# Cached camera look_at target & interaction state
var _cam_look_at: Vector3 = TUNING.CAMERA_LOOK_AT
var _cam_use_look_at: bool = true
var _is_orbiting_cam: bool = false
var _is_panning_cam: bool = false
var _ind_pos: Vector3 = TUNING.INDICATOR_POS_3D
var _ind_yaw: float = TUNING.INDICATOR_ROT_DEG.y


func setup(target_board: Node3D) -> void:
	board = target_board
	layer = 20
	name = "BoardLayoutTuner3D"
	_cam_look_at = TUNING.CAMERA_LOOK_AT
	_ind_pos = TUNING.INDICATOR_POS_3D
	_ind_yaw = TUNING.INDICATOR_ROT_DEG.y

	_build_3d_gizmo()
	_build_ui()
	_load_saved_user_layout_if_exists()
	_sync_ui_from_board()
	_update_gizmo()


func open_tuner() -> void:
	is_open = false
	_toggle_open()


func _build_3d_gizmo() -> void:
	if board == null:
		return
	_gizmo_mesh = ImmediateMesh.new()
	_gizmo_mat = StandardMaterial3D.new()
	_gizmo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_gizmo_mat.vertex_color_use_as_albedo = true
	_gizmo_mat.no_depth_test = true

	_gizmo_instance = MeshInstance3D.new()
	_gizmo_instance.name = "LayoutGizmo3D"
	_gizmo_instance.mesh = _gizmo_mesh
	_gizmo_instance.material_override = _gizmo_mat
	_gizmo_instance.visible = false
	board.add_child(_gizmo_instance)


func _build_ui() -> void:
	# 1. Top-bar floating toggle button ("Layout Studio (F2)")
	_toggle_btn = Button.new()
	_toggle_btn.name = "ToggleLayoutToolBtn"
	_toggle_btn.text = "Layout Studio (F2)"
	_toggle_btn.custom_minimum_size = Vector2(150, 34)
	_toggle_btn.position = Vector2(1920 - 490, 14)
	_toggle_btn.pressed.connect(_toggle_open)
	add_child(_toggle_btn)

	# 2. Main Studio Dock Panel on the left side
	_panel = PanelContainer.new()
	_panel.name = "LayoutStudioPanel"
	_panel.visible = false
	_panel.custom_minimum_size = Vector2(445, 790)
	_panel.position = Vector2(16, 58)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.09, 0.09, 0.94)
	style.border_color = Color(0.83, 0.68, 0.22, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(root_vbox)

	# Header row
	var header_hbox := HBoxContainer.new()
	root_vbox.add_child(header_hbox)

	var title := Label.new()
	title.text = "3D BOARD & CAMERA STUDIO"
	title.add_theme_color_override("font_color", Color("#f0c869"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)

	var drag_chk := CheckBox.new()
	drag_chk.text = "3D Drag & Orbit"
	drag_chk.button_pressed = drag_3d_enabled
	drag_chk.toggled.connect(func(v: bool):
		drag_3d_enabled = v
		_set_board_input_enabled(not (is_open and drag_3d_enabled))
	)
	header_hbox.add_child(drag_chk)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.pressed.connect(_toggle_open)
	header_hbox.add_child(close_btn)

	# Hint bar
	var hint := Label.new()
	hint.text = "LMB Drag: Move Element | Scroll/Q/E: Rotate Element | RMB Drag: Orbit Camera | MMB Drag: Pan Camera"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.75, 0.85, 0.80))
	root_vbox.add_child(hint)

	# Live Scenario Spawner Bar
	var scen_hbox := HBoxContainer.new()
	scen_hbox.add_theme_constant_override("separation", 6)
	root_vbox.add_child(scen_hbox)

	var scen_lbl := Label.new()
	scen_lbl.text = "Preview:"
	scen_lbl.add_theme_font_size_override("font_size", 13)
	scen_hbox.add_child(scen_lbl)

	for preset in [
		{"id": "opening", "label": "Opening"},
		{"id": "midgame", "label": "Midgame (Melds)"},
		{"id": "crowded", "label": "Crowded (32 Melds)"},
	]:
		var b := Button.new()
		b.text = preset["label"]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pid: String = preset["id"]
		b.pressed.connect(func(): _apply_test_scenario(pid))
		scen_hbox.add_child(b)

	# Tabs
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(_tabs)

	_build_tab_racks()
	_build_tab_melds()
	_build_tab_discards()
	_build_tab_camera()

	# Bottom Action Bar (Save / Copy / Reset)
	var bottom_hbox := HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 6)
	root_vbox.add_child(bottom_hbox)

	var save_btn := Button.new()
	save_btn.text = "Save to VectorTuning3D.gd"
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.pressed.connect(_save_to_project_and_user)
	bottom_hbox.add_child(save_btn)

	var copy_btn := Button.new()
	copy_btn.text = "Copy Code"
	copy_btn.pressed.connect(_copy_tuning_to_clipboard)
	bottom_hbox.add_child(copy_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Reset"
	reset_btn.pressed.connect(_reset_to_defaults)
	bottom_hbox.add_child(reset_btn)

	_status_label = Label.new()
	_status_label.text = "Ready — Select any tab or drag objects in 3D."
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", Color("#8ae6a8"))
	root_vbox.add_child(_status_label)


func _build_tab_racks() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Racks"
	_tabs.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	_add_section_header(vbox, "Player Hand Rack (Camera-Local)")
	_add_slider(vbox, "hand_x", "Pos X (Left/Right)", -0.35, 0.35, 0.002, _on_hand_slider_changed)
	_add_slider(vbox, "hand_y", "Pos Y (Up/Down)", -0.30, 0.10, 0.002, _on_hand_slider_changed)
	_add_slider(vbox, "hand_z", "Pos Z (Depth)", -1.10, -0.35, 0.005, _on_hand_slider_changed)
	_add_slider(vbox, "hand_rot_x", "Tilt Pitch X°", -35.0, 55.0, 0.5, _on_hand_slider_changed)
	_add_slider(vbox, "hand_rot_y", "Yaw Y°", -45.0, 45.0, 0.5, _on_hand_slider_changed)
	_add_slider(vbox, "hand_rot_z", "Roll Z°", -30.0, 30.0, 0.5, _on_hand_slider_changed)
	_add_slider(vbox, "hand_scale", "Rack Scale", 0.50, 1.40, 0.01, _on_hand_slider_changed)

	_add_section_header(vbox, "Opponent Racks (World Table Space)")
	var seat_hbox := HBoxContainer.new()
	vbox.add_child(seat_hbox)
	for s in [1, 2, 3]:
		var names := {1: "Seat 1 (East)", 2: "Seat 2 (North)", 3: "Seat 3 (West)"}
		var b := Button.new()
		b.text = names[s]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var seat_idx: int = s
		b.pressed.connect(func():
			_selected_opp_seat = seat_idx
			selected_target = "opp_%d" % seat_idx
			_sync_ui_from_board()
			_update_gizmo()
		)
		seat_hbox.add_child(b)

	_add_slider(vbox, "opp_x", "Opponent X", -0.68, 0.68, 0.005, _on_opp_slider_changed)
	_add_slider(vbox, "opp_y", "Opponent Y", 0.03, 0.20, 0.002, _on_opp_slider_changed)
	_add_slider(vbox, "opp_z", "Opponent Z", -0.58, 0.58, 0.005, _on_opp_slider_changed)
	_add_slider(vbox, "opp_yaw", "Orientation Yaw°", -180.0, 180.0, 1.0, _on_opp_slider_changed)
	_add_slider(vbox, "opp_scale", "Opponent Scale", 0.25, 1.10, 0.01, _on_opp_slider_changed)


func _build_tab_melds() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Melds"
	_tabs.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	_add_section_header(vbox, "Independent Meld Areas (1 Per Player / Rack)")
	var m_seat_hbox := HBoxContainer.new()
	vbox.add_child(m_seat_hbox)
	for s in [0, 1, 2, 3]:
		var names := {0: "0: You (S)", 1: "1: East", 2: "2: North", 3: "3: West"}
		var b := Button.new()
		b.text = names[s]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var seat_idx: int = s
		b.pressed.connect(func():
			_selected_meld_seat = seat_idx
			selected_target = "meld_%d" % seat_idx
			_sync_ui_from_board()
			_update_gizmo()
		)
		m_seat_hbox.add_child(b)

	_add_slider(vbox, "meld_area_x", "Meld Area Pos X", -0.60, 0.60, 0.005, _on_meld_area_slider_changed)
	_add_slider(vbox, "meld_area_z", "Meld Area Pos Z", -0.50, 0.50, 0.005, _on_meld_area_slider_changed)
	_add_slider(vbox, "meld_area_yaw", "Meld Orientation Yaw°", -180.0, 180.0, 1.0, _on_meld_area_slider_changed)
	_add_slider(vbox, "meld_area_w", "Area Width (X)", 0.20, 0.90, 0.01, _on_meld_area_slider_changed)
	_add_slider(vbox, "meld_area_d", "Area Depth (Z)", 0.06, 0.45, 0.005, _on_meld_area_slider_changed)
	_add_slider(vbox, "meld_area_scale", "Meld Tile Scale", 0.50, 1.40, 0.02, _on_meld_area_slider_changed)

	_add_section_header(vbox, "Global Meld Tile Spacing")
	_add_slider(vbox, "meld_row_scale", "Row Spacing Scale", 0.50, 1.80, 0.02, _on_meld_spacing_slider_changed)
	_add_slider(vbox, "meld_tile_scale", "Tile Pitch Scale", 0.70, 1.50, 0.02, _on_meld_spacing_slider_changed)
	_add_slider(vbox, "meld_gap_scale", "Group Gap Scale", 0.40, 2.20, 0.05, _on_meld_spacing_slider_changed)


func _build_tab_discards() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Discards"
	_tabs.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	_add_section_header(vbox, "Discard Areas (4 Corners)")
	var d_hbox := HBoxContainer.new()
	vbox.add_child(d_hbox)
	for s in [0, 1, 2, 3]:
		var names := {0: "0: SE (Out)", 1: "1: NE", 2: "2: NW", 3: "3: SW (Draw)"}
		var b := Button.new()
		b.text = names[s]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var seat_idx: int = s
		b.pressed.connect(func():
			_selected_discard_seat = seat_idx
			selected_target = "discard_%d" % seat_idx
			_sync_ui_from_board()
			_update_gizmo()
		)
		d_hbox.add_child(b)

	_add_slider(vbox, "disc_x", "Discard Pos X", -0.58, 0.58, 0.005, _on_discard_slider_changed)
	_add_slider(vbox, "disc_z", "Discard Pos Z", -0.48, 0.48, 0.005, _on_discard_slider_changed)
	_add_slider(vbox, "disc_yaw", "Discard Orientation Yaw°", -180.0, 180.0, 1.0, _on_discard_slider_changed)
	_add_slider(vbox, "disc_scale", "Discard Tray Scale", 0.50, 1.50, 0.02, _on_discard_slider_changed)

	_add_section_header(vbox, "Center Stock Pile")
	_add_slider(vbox, "stock_x", "Stock Pos X", -0.45, 0.45, 0.005, _on_stock_slider_changed)
	_add_slider(vbox, "stock_z", "Stock Pos Z", -0.40, 0.40, 0.005, _on_stock_slider_changed)
	_add_slider(vbox, "stock_yaw", "Stock Orientation Yaw°", -180.0, 180.0, 1.0, _on_stock_slider_changed)

	_add_section_header(vbox, "Indicator Tile")
	_add_slider(vbox, "ind_x", "Indicator Pos X", -0.45, 0.45, 0.005, _on_indicator_slider_changed)
	_add_slider(vbox, "ind_z", "Indicator Pos Z", -0.40, 0.40, 0.005, _on_indicator_slider_changed)
	_add_slider(vbox, "ind_yaw", "Indicator Yaw°", -180.0, 180.0, 1.0, _on_indicator_slider_changed)


func _build_tab_camera() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Camera"
	_tabs.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	var cam_hint := Label.new()
	cam_hint.text = "Hold Right-Click + Drag on table to Orbit Camera.\nHold Middle-Click (or Shift+RMB) + Drag to Pan Camera."
	cam_hint.add_theme_font_size_override("font_size", 11)
	cam_hint.add_theme_color_override("font_color", Color(0.75, 0.88, 0.95))
	vbox.add_child(cam_hint)

	_add_section_header(vbox, "Camera Position (World Space)")
	_add_slider(vbox, "cam_x", "Camera Pos X", -0.80, 0.80, 0.005, _on_camera_pos_or_look_changed)
	_add_slider(vbox, "cam_y", "Camera Height Y", 0.20, 1.80, 0.005, _on_camera_pos_or_look_changed)
	_add_slider(vbox, "cam_z", "Camera Distance Z", 0.01, 1.80, 0.005, _on_camera_pos_or_look_changed)

	_add_section_header(vbox, "Camera Look-At Target")
	_add_slider(vbox, "look_x", "Look-At X", -0.60, 0.60, 0.005, _on_camera_pos_or_look_changed)
	_add_slider(vbox, "look_y", "Look-At Y", -0.40, 0.40, 0.005, _on_camera_pos_or_look_changed)
	_add_slider(vbox, "look_z", "Look-At Z", -0.60, 0.60, 0.005, _on_camera_pos_or_look_changed)

	_add_section_header(vbox, "Direct Camera Angles (Pitch / Yaw / Roll)")
	_add_slider(vbox, "cam_pitch", "Pitch X° (Tilt)", -89.5, 10.0, 0.2, _on_camera_euler_changed)
	_add_slider(vbox, "cam_yaw", "Yaw Y° (Turn)", -180.0, 180.0, 0.5, _on_camera_euler_changed)
	_add_slider(vbox, "cam_roll", "Roll Z° (Bank)", -45.0, 45.0, 0.5, _on_camera_euler_changed)

	_add_section_header(vbox, "Lens, Optics & Clipping")
	_add_slider(vbox, "cam_fov", "Field of View (FOV°)", 15.0, 95.0, 0.5, _on_camera_optics_changed)
	_add_slider(vbox, "cam_near", "Near Clip (m)", 0.01, 0.50, 0.005, _on_camera_optics_changed)
	_add_slider(vbox, "cam_far", "Far Clip (m)", 2.0, 25.0, 0.5, _on_camera_optics_changed)
	_add_slider(vbox, "cam_h_off", "Lens H-Offset", -0.30, 0.30, 0.005, _on_camera_optics_changed)
	_add_slider(vbox, "cam_v_off", "Lens V-Offset", -0.30, 0.30, 0.005, _on_camera_optics_changed)


func _add_section_header(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = "── %s ──" % text
	lbl.add_theme_color_override("font_color", Color("#f0c869"))
	lbl.add_theme_font_size_override("font_size", 13)
	parent.add_child(lbl)


func _add_slider(parent: Control, key: String, label_text: String, min_v: float, max_v: float, step_v: float, callback: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.custom_minimum_size = Vector2(150, 0)
	name_lbl.add_theme_font_size_override("font_size", 12)
	row.add_child(name_lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.custom_minimum_size = Vector2(58, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 12)
	row.add_child(val_lbl)

	_slider_Controls[key] = {"slider": slider, "label": val_lbl}
	slider.value_changed.connect(func(v: float):
		val_lbl.text = "%.3f" % v if step_v < 0.1 else "%.1f" % v
		if not _updating_ui:
			callback.call()
	)


func _set_slider_val(key: String, val: float) -> void:
	if not _slider_Controls.has(key):
		return
	var entry: Dictionary = _slider_Controls[key]
	var s: HSlider = entry["slider"]
	var l: Label = entry["label"]
	s.value = val
	l.text = "%.3f" % val if s.step < 0.1 else "%.1f" % val


func _get_slider_val(key: String) -> float:
	if not _slider_Controls.has(key):
		return 0.0
	return (_slider_Controls[key]["slider"] as HSlider).value


func _toggle_open() -> void:
	is_open = not is_open
	if _panel != null:
		_panel.visible = is_open
	if _gizmo_instance != null:
		_gizmo_instance.visible = is_open
	_set_board_input_enabled(not (is_open and drag_3d_enabled))
	if is_open:
		_sync_ui_from_board()
		_update_gizmo()


func _set_board_input_enabled(enabled: bool) -> void:
	if board != null and board._input_handler != null:
		board._input_handler.set_process_input(enabled)
		board._input_handler.set_process(enabled)


func _sync_ui_from_board() -> void:
	if board == null:
		return
	_updating_ui = true

	# 1. HandRig
	if board._hand_rig != null:
		_set_slider_val("hand_x", board._hand_rig.position.x)
		_set_slider_val("hand_y", board._hand_rig.position.y)
		_set_slider_val("hand_z", board._hand_rig.position.z)
		_set_slider_val("hand_rot_x", board._hand_rig.rotation_degrees.x)
		_set_slider_val("hand_rot_y", board._hand_rig.rotation_degrees.y)
		_set_slider_val("hand_rot_z", board._hand_rig.rotation_degrees.z)
		_set_slider_val("hand_scale", board._hand_rig.scale.x)

	# 2. Opponent Rack
	if board._opponent_racks.has(_selected_opp_seat):
		var opp: Node3D = board._opponent_racks[_selected_opp_seat]
		_set_slider_val("opp_x", opp.position.x)
		_set_slider_val("opp_y", opp.position.y)
		_set_slider_val("opp_z", opp.position.z)
		_set_slider_val("opp_yaw", opp.rotation_degrees.y)
		_set_slider_val("opp_scale", opp.scale.x)

	# 3. Independent Per-Seat Melds
	if board._meld_layout != null:
		var ml = board._meld_layout
		var apos: Vector3 = ml.get_seat_area_position(_selected_meld_seat)
		var arot: Vector3 = ml.get_seat_area_rotation_deg(_selected_meld_seat)
		var asz: Vector2 = ml.get_seat_area_size(_selected_meld_seat)
		var asc: float = ml.get_seat_area_scale(_selected_meld_seat)
		_set_slider_val("meld_area_x", apos.x)
		_set_slider_val("meld_area_z", apos.z)
		_set_slider_val("meld_area_yaw", arot.y)
		_set_slider_val("meld_area_w", asz.x)
		_set_slider_val("meld_area_d", asz.y)
		_set_slider_val("meld_area_scale", asc)

		_set_slider_val("meld_row_scale", ml.row_pitch_scale)
		_set_slider_val("meld_tile_scale", ml.tile_pitch_scale)
		_set_slider_val("meld_gap_scale", ml.group_gap_scale)

	# 4. Discards, Stock & Indicator
	if board._discard_piles_view != null:
		var dp = board._discard_piles_view
		var dpos: Vector3 = dp.get_pile_position(_selected_discard_seat)
		var drot: Vector3 = dp.get_pile_rotation_deg(_selected_discard_seat)
		_set_slider_val("disc_x", dpos.x)
		_set_slider_val("disc_z", dpos.z)
		_set_slider_val("disc_yaw", drot.y)
		_set_slider_val("disc_scale", float(_discard_scales.get(_selected_discard_seat, 1.0)))

	if board._stock_view != null:
		_set_slider_val("stock_x", board._stock_view.position.x)
		_set_slider_val("stock_z", board._stock_view.position.z)
		_set_slider_val("stock_yaw", board._stock_view.rotation_degrees.y)

	_set_slider_val("ind_x", _ind_pos.x)
	_set_slider_val("ind_z", _ind_pos.z)
	_set_slider_val("ind_yaw", _ind_yaw)

	# 5. Camera
	if board._camera != null:
		_set_slider_val("cam_x", board._camera.position.x)
		_set_slider_val("cam_y", board._camera.position.y)
		_set_slider_val("cam_z", board._camera.position.z)
		_set_slider_val("look_x", _cam_look_at.x)
		_set_slider_val("look_y", _cam_look_at.y)
		_set_slider_val("look_z", _cam_look_at.z)
		_set_slider_val("cam_pitch", board._camera.rotation_degrees.x)
		_set_slider_val("cam_yaw", board._camera.rotation_degrees.y)
		_set_slider_val("cam_roll", board._camera.rotation_degrees.z)
		_set_slider_val("cam_fov", board._camera.fov)
		_set_slider_val("cam_near", board._camera.near)
		_set_slider_val("cam_far", board._camera.far)
		_set_slider_val("cam_h_off", board._camera.h_offset)
		_set_slider_val("cam_v_off", board._camera.v_offset)

	_updating_ui = false


func _on_hand_slider_changed() -> void:
	if board == null or board._hand_rig == null:
		return
	board._hand_rig.position = Vector3(_get_slider_val("hand_x"), _get_slider_val("hand_y"), _get_slider_val("hand_z"))
	board._hand_rig.rotation_degrees = Vector3(_get_slider_val("hand_rot_x"), _get_slider_val("hand_rot_y"), _get_slider_val("hand_rot_z"))
	var sc: float = _get_slider_val("hand_scale")
	board._hand_rig.scale = Vector3.ONE * sc


func _on_opp_slider_changed() -> void:
	if board == null or not board._opponent_racks.has(_selected_opp_seat):
		return
	var opp: Node3D = board._opponent_racks[_selected_opp_seat]
	opp.position = Vector3(_get_slider_val("opp_x"), _get_slider_val("opp_y"), _get_slider_val("opp_z"))
	opp.rotation_degrees = Vector3(0.0, _get_slider_val("opp_yaw"), 0.0)
	opp.scale = Vector3.ONE * _get_slider_val("opp_scale")
	_update_gizmo()


func _on_meld_area_slider_changed() -> void:
	if board == null or board._meld_layout == null:
		return
	var ml = board._meld_layout
	ml.independent_seat_areas = true
	var pos := Vector3(_get_slider_val("meld_area_x"), TUNING.TABLE_SURFACE_Y, _get_slider_val("meld_area_z"))
	var rot := Vector3(0.0, _get_slider_val("meld_area_yaw"), 0.0)
	var sz := Vector2(_get_slider_val("meld_area_w"), _get_slider_val("meld_area_d"))
	var sc: float = _get_slider_val("meld_area_scale")
	ml.set_seat_area_transform(_selected_meld_seat, pos, rot, sz, sc)
	_refresh_board_melds()
	_update_gizmo()


func _on_meld_spacing_slider_changed() -> void:
	if board == null or board._meld_layout == null:
		return
	var ml = board._meld_layout
	ml.row_pitch_scale = _get_slider_val("meld_row_scale")
	ml.tile_pitch_scale = _get_slider_val("meld_tile_scale")
	ml.group_gap_scale = _get_slider_val("meld_gap_scale")
	_refresh_board_melds()
	_update_gizmo()


func _on_discard_slider_changed() -> void:
	if board == null or board._discard_piles_view == null:
		return
	var dp = board._discard_piles_view
	var pos := Vector3(_get_slider_val("disc_x"), TUNING.TABLE_SURFACE_Y, _get_slider_val("disc_z"))
	var rot := Vector3(0.0, _get_slider_val("disc_yaw"), 0.0)
	var sc: float = _get_slider_val("disc_scale")
	_discard_scales[_selected_discard_seat] = sc
	dp.set_pile_transform(_selected_discard_seat, pos, rot, sc)
	board._sync_discards()
	_update_gizmo()


func _on_stock_slider_changed() -> void:
	if board == null or board._stock_view == null:
		return
	var sx: float = _get_slider_val("stock_x")
	var sz: float = _get_slider_val("stock_z")
	var syaw: float = _get_slider_val("stock_yaw")
	board._stock_view.position = Vector3(sx, TUNING.TABLE_SURFACE_Y, sz)
	board._stock_view.rotation_degrees = Vector3(0.0, syaw, 0.0)
	if board._table_mesh != null:
		var med := board._table_mesh.get_node_or_null("CenterTournamentMedallion") as Node3D
		if med != null:
			med.position = Vector3(sx + 0.035, 0.0, sz)
			med.rotation_degrees = Vector3(0.0, syaw - 8.0, 0.0)
	_update_gizmo()


func _on_indicator_slider_changed() -> void:
	if board == null:
		return
	_ind_pos = Vector3(_get_slider_val("ind_x"), TUNING.TABLE_SURFACE_Y + 0.0045, _get_slider_val("ind_z"))
	_ind_yaw = _get_slider_val("ind_yaw")
	_apply_indicator_transform()
	_update_gizmo()


func _apply_indicator_transform() -> void:
	if board == null or board._registry == null or board._session == null:
		return
	var ctrl = board._session.get_controller()
	if ctrl != null and ctrl.state != null and ctrl.state.indicator_tile != null:
		var ind = ctrl.state.indicator_tile
		var tile_node = board._registry.get_tile(ind.unique_id)
		if tile_node != null:
			tile_node.set_target_position_3d(_ind_pos, true)
			tile_node.set_target_rotation_3d(Vector3(-90.0, _ind_yaw, 0.0), true)


func _on_camera_pos_or_look_changed() -> void:
	if board == null or board._camera == null:
		return
	var cpos := Vector3(_get_slider_val("cam_x"), _get_slider_val("cam_y"), _get_slider_val("cam_z"))
	_cam_look_at = Vector3(_get_slider_val("look_x"), _get_slider_val("look_y"), _get_slider_val("look_z"))
	if cpos.distance_to(_cam_look_at) > 0.005:
		board._camera.look_at_from_position(cpos, _cam_look_at, Vector3.UP)
	else:
		board._camera.position = cpos
	_updating_ui = true
	_set_slider_val("cam_pitch", board._camera.rotation_degrees.x)
	_set_slider_val("cam_yaw", board._camera.rotation_degrees.y)
	_set_slider_val("cam_roll", board._camera.rotation_degrees.z)
	_updating_ui = false


func _on_camera_euler_changed() -> void:
	if board == null or board._camera == null:
		return
	var dist: float = maxf(0.15, board._camera.position.distance_to(_cam_look_at))
	board._camera.rotation_degrees = Vector3(
		_get_slider_val("cam_pitch"),
		_get_slider_val("cam_yaw"),
		_get_slider_val("cam_roll")
	)
	var forward: Vector3 = -board._camera.global_transform.basis.z
	_cam_look_at = board._camera.position + forward * dist
	_updating_ui = true
	_set_slider_val("look_x", _cam_look_at.x)
	_set_slider_val("look_y", _cam_look_at.y)
	_set_slider_val("look_z", _cam_look_at.z)
	_updating_ui = false


func _on_camera_optics_changed() -> void:
	if board == null or board._camera == null:
		return
	board._camera.fov = _get_slider_val("cam_fov")
	board._camera.near = _get_slider_val("cam_near")
	board._camera.far = _get_slider_val("cam_far")
	board._camera.h_offset = _get_slider_val("cam_h_off")
	board._camera.v_offset = _get_slider_val("cam_v_off")


func _refresh_board_melds() -> void:
	if board == null or board._session == null:
		return
	var ctrl = board._session.get_controller()
	if ctrl != null and ctrl.state != null:
		board._on_melds_updated(ctrl.state.table_melds)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			_toggle_open()
			get_viewport().set_input_as_handled()
			return
		if is_open and (event.keycode == KEY_Q or event.keycode == KEY_E):
			var delta_deg: float = -5.0 if event.keycode == KEY_Q else 5.0
			if event.shift_pressed:
				delta_deg *= 0.2
			_rotate_selected_target(delta_deg)
			get_viewport().set_input_as_handled()
			return

	if not is_open or not drag_3d_enabled or board == null or board._camera == null:
		return

	# Ignore 3D clicks when mouse is over the UI panel or toggle button
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	if _panel != null and _panel.visible and _panel.get_global_rect().has_point(mouse_pos) and not _is_dragging_3d and not _is_orbiting_cam and not _is_panning_cam:
		return
	if _toggle_btn != null and _toggle_btn.get_global_rect().has_point(mouse_pos):
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			var step_deg: float = 1.0 if event.shift_pressed else 5.0
			_rotate_selected_target(step_deg)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			var step_deg: float = -1.0 if event.shift_pressed else -5.0
			_rotate_selected_target(step_deg)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if event.shift_pressed:
					_is_panning_cam = true
					_status_label.text = "Panning Camera Target..."
				else:
					_is_orbiting_cam = true
					_status_label.text = "Orbiting Camera around Look-At Target..."
				get_viewport().set_input_as_handled()
			else:
				_is_orbiting_cam = false
				_is_panning_cam = false
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_panning_cam = event.pressed
			if event.pressed:
				_status_label.text = "Panning Camera Target..."
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var hit := _project_mouse_to_table(mouse_pos)
				if hit.is_finite():
					var picked := _pick_nearest_table_element(Vector2(hit.x, hit.z))
					if not picked.is_empty():
						selected_target = picked
						var center_xz := _get_target_xz(selected_target)
						_drag_offset_xz = center_xz - Vector2(hit.x, hit.z)
						_is_dragging_3d = true
						_focus_tab_for_target(selected_target)
						_sync_ui_from_board()
						_update_gizmo()
						_status_label.text = "Dragging [%s] — Scroll wheel or Q/E to rotate" % selected_target
			else:
				_is_dragging_3d = false

	elif event is InputEventMouseMotion:
		if _is_orbiting_cam:
			var rel: Vector2 = event.relative
			var offset: Vector3 = board._camera.position - _cam_look_at
			var radius: float = maxf(0.20, offset.length())
			var yaw: float = atan2(offset.x, offset.z) - rel.x * 0.005
			var pitch: float = clampf(asin(clampf(offset.y / radius, -0.99, 0.99)) + rel.y * 0.005, deg_to_rad(10.0), deg_to_rad(88.0))
			var new_pos := _cam_look_at + Vector3(
				radius * cos(pitch) * sin(yaw),
				radius * sin(pitch),
				radius * cos(pitch) * cos(yaw)
			)
			board._camera.look_at_from_position(new_pos, _cam_look_at, Vector3.UP)
			_sync_ui_from_board()
			get_viewport().set_input_as_handled()
		elif _is_panning_cam:
			var rel: Vector2 = event.relative
			var right: Vector3 = board._camera.global_transform.basis.x
			var up_xz := Vector3(board._camera.global_transform.basis.y.x, 0.0, board._camera.global_transform.basis.y.z).normalized()
			var delta_pan: Vector3 = (-right * rel.x + up_xz * rel.y) * 0.0012
			board._camera.position += delta_pan
			_cam_look_at += delta_pan
			board._camera.look_at_from_position(board._camera.position, _cam_look_at, Vector3.UP)
			_sync_ui_from_board()
			get_viewport().set_input_as_handled()
		elif _is_dragging_3d:
			var hit := _project_mouse_to_table(mouse_pos)
			if hit.is_finite():
				var new_xz := Vector2(hit.x, hit.z) + _drag_offset_xz
				_set_target_xz(selected_target, new_xz)
				_sync_ui_from_board()
				_update_gizmo()


func _project_mouse_to_table(screen_pos: Vector2) -> Vector3:
	if board == null or board._camera == null:
		return Vector3.INF
	var origin: Vector3 = board._camera.project_ray_origin(screen_pos)
	var dir: Vector3 = board._camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.0001:
		return Vector3.INF
	var t: float = (TUNING.TABLE_SURFACE_Y - origin.y) / dir.y
	if t <= 0.0:
		return Vector3.INF
	return origin + dir * t


func _pick_nearest_table_element(pt_xz: Vector2) -> String:
	var best_id: String = "meld_0"
	var best_dist: float = 0.22

	if pt_xz.distance_to(Vector2(_ind_pos.x, _ind_pos.z)) < 0.055:
		return "indicator"

	if board._stock_view != null:
		var sp: Vector3 = board._stock_view.position
		if pt_xz.distance_to(Vector2(sp.x, sp.z)) < 0.08:
			return "stock"

	for seat in [1, 2, 3]:
		if board._opponent_racks.has(seat):
			var p: Vector3 = board._opponent_racks[seat].position
			var d: float = pt_xz.distance_to(Vector2(p.x, p.z))
			if d < best_dist:
				best_dist = d
				best_id = "opp_%d" % seat

	if board._discard_piles_view != null:
		for seat in range(4):
			var p: Vector3 = board._discard_piles_view.get_pile_position(seat)
			var d: float = pt_xz.distance_to(Vector2(p.x, p.z))
			if d < best_dist:
				best_dist = d
				best_id = "discard_%d" % seat

	if board._meld_layout != null:
		for seat in range(4):
			var mp: Vector3 = board._meld_layout.get_seat_area_position(seat)
			var d: float = pt_xz.distance_to(Vector2(mp.x, mp.z))
			if d < best_dist:
				best_dist = d
				best_id = "meld_%d" % seat

	return best_id


func _focus_tab_for_target(target_id: String) -> void:
	if target_id.begins_with("opp_"):
		_selected_opp_seat = int(target_id.trim_prefix("opp_"))
		_tabs.current_tab = 0
	elif target_id.begins_with("meld_"):
		_selected_meld_seat = int(target_id.trim_prefix("meld_"))
		_tabs.current_tab = 1
	elif target_id.begins_with("discard_"):
		_selected_discard_seat = int(target_id.trim_prefix("discard_"))
		_tabs.current_tab = 2
	elif target_id == "stock" or target_id == "indicator":
		_tabs.current_tab = 2


func _get_target_xz(target_id: String) -> Vector2:
	if target_id.begins_with("opp_"):
		var s := int(target_id.trim_prefix("opp_"))
		var p: Vector3 = board._opponent_racks[s].position
		return Vector2(p.x, p.z)
	elif target_id.begins_with("meld_"):
		var s := int(target_id.trim_prefix("meld_"))
		var p: Vector3 = board._meld_layout.get_seat_area_position(s)
		return Vector2(p.x, p.z)
	elif target_id.begins_with("discard_"):
		var s := int(target_id.trim_prefix("discard_"))
		var p: Vector3 = board._discard_piles_view.get_pile_position(s)
		return Vector2(p.x, p.z)
	elif target_id == "stock":
		var p: Vector3 = board._stock_view.position
		return Vector2(p.x, p.z)
	elif target_id == "indicator":
		return Vector2(_ind_pos.x, _ind_pos.z)
	return Vector2.ZERO


func _set_target_xz(target_id: String, xz: Vector2) -> void:
	if target_id.begins_with("opp_"):
		var s := int(target_id.trim_prefix("opp_"))
		var opp: Node3D = board._opponent_racks[s]
		opp.position.x = clampf(xz.x, -0.65, 0.65)
		opp.position.z = clampf(xz.y, -0.55, 0.55)
	elif target_id.begins_with("meld_"):
		var s := int(target_id.trim_prefix("meld_"))
		var ml = board._meld_layout
		ml.independent_seat_areas = true
		var rot: Vector3 = ml.get_seat_area_rotation_deg(s)
		var sz: Vector2 = ml.get_seat_area_size(s)
		var sc: float = ml.get_seat_area_scale(s)
		ml.set_seat_area_transform(s, Vector3(clampf(xz.x, -0.58, 0.58), TUNING.TABLE_SURFACE_Y, clampf(xz.y, -0.48, 0.48)), rot, sz, sc)
		_refresh_board_melds()
	elif target_id.begins_with("discard_"):
		var s := int(target_id.trim_prefix("discard_"))
		var dp = board._discard_piles_view
		var rot: Vector3 = dp.get_pile_rotation_deg(s)
		var sc: float = float(_discard_scales.get(s, 1.0))
		dp.set_pile_transform(s, Vector3(clampf(xz.x, -0.58, 0.58), TUNING.TABLE_SURFACE_Y, clampf(xz.y, -0.48, 0.48)), rot, sc)
		board._sync_discards()
	elif target_id == "stock":
		board._stock_view.position.x = clampf(xz.x, -0.45, 0.45)
		board._stock_view.position.z = clampf(xz.y, -0.40, 0.40)
	elif target_id == "indicator":
		_ind_pos.x = clampf(xz.x, -0.45, 0.45)
		_ind_pos.z = clampf(xz.y, -0.40, 0.40)
		_apply_indicator_transform()


func _rotate_selected_target(delta_deg: float) -> void:
	if selected_target.begins_with("opp_"):
		var s := int(selected_target.trim_prefix("opp_"))
		var opp: Node3D = board._opponent_racks[s]
		opp.rotation_degrees.y = wrapf(opp.rotation_degrees.y + delta_deg, -180.0, 180.0)
	elif selected_target.begins_with("meld_"):
		var s := int(selected_target.trim_prefix("meld_"))
		var ml = board._meld_layout
		ml.independent_seat_areas = true
		var pos: Vector3 = ml.get_seat_area_position(s)
		var rot: Vector3 = ml.get_seat_area_rotation_deg(s)
		rot.y = wrapf(rot.y + delta_deg, -180.0, 180.0)
		var sz: Vector2 = ml.get_seat_area_size(s)
		var sc: float = ml.get_seat_area_scale(s)
		ml.set_seat_area_transform(s, pos, rot, sz, sc)
		_refresh_board_melds()
	elif selected_target.begins_with("discard_"):
		var s := int(selected_target.trim_prefix("discard_"))
		var dp = board._discard_piles_view
		var pos: Vector3 = dp.get_pile_position(s)
		var rot: Vector3 = dp.get_pile_rotation_deg(s)
		rot.y = wrapf(rot.y + delta_deg, -180.0, 180.0)
		var sc: float = float(_discard_scales.get(s, 1.0))
		dp.set_pile_transform(s, pos, rot, sc)
		board._sync_discards()
	elif selected_target == "stock":
		board._stock_view.rotation_degrees.y = wrapf(board._stock_view.rotation_degrees.y + delta_deg, -180.0, 180.0)
	elif selected_target == "indicator":
		_ind_yaw = wrapf(_ind_yaw + delta_deg, -180.0, 180.0)
		_apply_indicator_transform()
	_sync_ui_from_board()
	_update_gizmo()


func _update_gizmo() -> void:
	if _gizmo_mesh == null or board == null:
		return
	_gizmo_mesh.clear_surfaces()
	_gizmo_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var y: float = TUNING.TABLE_SURFACE_Y + 0.008

	# 1. Independent Per-Seat Meld Area Wireframe Boxes + Orientation Arrows
	if board._meld_layout != null:
		var ml = board._meld_layout
		for seat in range(4):
			var mp: Vector3 = ml.get_seat_area_position(seat)
			var mr: Vector3 = ml.get_seat_area_rotation_deg(seat)
			var msz: Vector2 = ml.get_seat_area_size(seat) * ml.get_seat_area_scale(seat)
			var is_sel: bool = (selected_target == "meld_%d" % seat)
			var col := Color(0.2, 0.98, 1.0) if is_sel else Color(0.2, 0.72, 0.88, 0.68)
			_draw_oriented_rect(Vector3(mp.x, y, mp.z), msz, mr.y, col)

	# 2. Discard Pile Wireframe Boxes + Orientation Arrows
	if board._discard_piles_view != null:
		for seat in range(4):
			var p: Vector3 = board._discard_piles_view.get_pile_position(seat)
			var r: Vector3 = board._discard_piles_view.get_pile_rotation_deg(seat)
			var is_sel: bool = (selected_target == "discard_%d" % seat)
			var col := Color(1.0, 0.85, 0.2) if is_sel else Color(0.95, 0.65, 0.15, 0.65)
			_draw_oriented_rect(Vector3(p.x, y, p.z), Vector2(0.12, 0.16), r.y, col)

	# 3. Opponent Rack Wireframe Boxes + Orientation Arrows
	for seat in [1, 2, 3]:
		if board._opponent_racks.has(seat):
			var opp: Node3D = board._opponent_racks[seat]
			var is_sel: bool = (selected_target == "opp_%d" % seat)
			var col := Color(0.3, 1.0, 0.45) if is_sel else Color(0.3, 0.85, 0.4, 0.65)
			var sc: float = opp.scale.x
			_draw_oriented_rect(Vector3(opp.position.x, y, opp.position.z), Vector2(0.80 * sc, 0.09 * sc), opp.rotation_degrees.y, col)

	# 4. Stock & Indicator Wireframe
	if board._stock_view != null:
		var sp: Vector3 = board._stock_view.position
		var sr: Vector3 = board._stock_view.rotation_degrees
		var col := Color(1.0, 0.45, 0.85) if selected_target == "stock" else Color(0.85, 0.35, 0.70, 0.65)
		_draw_oriented_rect(Vector3(sp.x, y, sp.z), Vector2(0.06, 0.08), sr.y, col)

	var icol := Color(1.0, 0.55, 0.25) if selected_target == "indicator" else Color(0.85, 0.45, 0.20, 0.65)
	_draw_oriented_rect(Vector3(_ind_pos.x, y, _ind_pos.z), Vector2(0.05, 0.07), _ind_yaw, icol)

	_gizmo_mesh.surface_end()


func _draw_oriented_rect(center: Vector3, size: Vector2, yaw_deg: float, color: Color) -> void:
	var hx: float = size.x * 0.5
	var hz: float = size.y * 0.5
	var basis := Basis.from_euler(Vector3(0.0, deg_to_rad(yaw_deg), 0.0))
	var corners := [
		center + basis * Vector3(-hx, 0, -hz),
		center + basis * Vector3( hx, 0, -hz),
		center + basis * Vector3( hx, 0,  hz),
		center + basis * Vector3(-hx, 0,  hz),
	]
	for i in range(4):
		_gizmo_mesh.surface_set_color(color)
		_gizmo_mesh.surface_add_vertex(corners[i])
		_gizmo_mesh.surface_set_color(color)
		_gizmo_mesh.surface_add_vertex(corners[(i + 1) % 4])

	# Forward orientation arrow (+Z in local space)
	var tip := center + basis * Vector3(0, 0, hz + 0.035)
	var left := center + basis * Vector3(-0.018, 0, hz + 0.012)
	var right := center + basis * Vector3(0.018, 0, hz + 0.012)
	_gizmo_mesh.surface_set_color(color)
	_gizmo_mesh.surface_add_vertex(center)
	_gizmo_mesh.surface_set_color(color)
	_gizmo_mesh.surface_add_vertex(tip)
	_gizmo_mesh.surface_set_color(color)
	_gizmo_mesh.surface_add_vertex(tip)
	_gizmo_mesh.surface_set_color(color)
	_gizmo_mesh.surface_add_vertex(left)
	_gizmo_mesh.surface_set_color(color)
	_gizmo_mesh.surface_add_vertex(tip)
	_gizmo_mesh.surface_set_color(color)
	_gizmo_mesh.surface_add_vertex(right)


func _apply_test_scenario(scenario_id: String) -> void:
	if board == null or board._session == null:
		return
	var ctrl = board._session.get_controller()
	if ctrl == null or ctrl.state == null:
		return

	if scenario_id == "opening":
		board.configure_game(RuleConfig.new(), 1701, 4)
		_apply_indicator_transform()
		if _status_label != null:
			_status_label.text = "Loaded Opening scenario."
		return

	var count_melds: int = 8 if scenario_id == "midgame" else 32
	var state = ctrl.state
	state.table_melds.clear()
	for m_idx in range(count_melds):
		var col: int = m_idx % 4
		var t_objs: Array = []
		var t_ids: Array = []
		for k in range(4):
			var uid: int = 80000 + m_idx * 10 + k
			t_ids.append(uid)
			t_objs.append(Tile.new(col, 3 + k, Tile.Kind.NORMAL, uid))
		var m := Meld.new(Meld.Kind.RUN, t_ids, t_objs, m_idx % 4)
		state.table_melds.append(m)

	# Populate sample discard piles on all 4 corners
	state.player_discard_stacks = [
		[Tile.new(0, 11, Tile.Kind.NORMAL, 91001)],
		[Tile.new(1, 8, Tile.Kind.NORMAL, 91002)],
		[Tile.new(3, 13, Tile.Kind.NORMAL, 91003)],
		[Tile.new(2, 6, Tile.Kind.NORMAL, 91004)],
	]
	board._on_melds_updated(state.table_melds)
	board._sync_discards()
	if _status_label != null:
		_status_label.text = "Loaded %s preview (%d melds across 4 player areas + 4 discards)." % [scenario_id, count_melds]


func _serialize_layout_dict() -> Dictionary:
	var opp_pos := {}
	var opp_rot := {}
	var opp_scale: float = TUNING.OPPONENT_RACK_SCALE
	for s in [1, 2, 3]:
		if board._opponent_racks.has(s):
			var o: Node3D = board._opponent_racks[s]
			opp_pos[s] = [o.position.x, o.position.y, o.position.z]
			opp_rot[s] = [o.rotation_degrees.x, o.rotation_degrees.y, o.rotation_degrees.z]
			opp_scale = o.scale.x

	var disc_pos := {}
	var disc_rot := {}
	for s in range(4):
		var p: Vector3 = board._discard_piles_view.get_pile_position(s)
		var r: Vector3 = board._discard_piles_view.get_pile_rotation_deg(s)
		disc_pos[s] = [p.x, p.y, p.z]
		disc_rot[s] = [r.x, r.y, r.z]

	var ml = board._meld_layout
	var meld_pos := {}
	var meld_rot := {}
	var meld_sz := {}
	for s in range(4):
		var mp: Vector3 = ml.get_seat_area_position(s)
		var mr: Vector3 = ml.get_seat_area_rotation_deg(s)
		var msz: Vector2 = ml.get_seat_area_size(s)
		meld_pos[s] = [mp.x, mp.y, mp.z]
		meld_rot[s] = [mr.x, mr.y, mr.z]
		meld_sz[s] = [msz.x, msz.y]

	return {
		"camera_pos": [board._camera.position.x, board._camera.position.y, board._camera.position.z],
		"camera_look_at": [_cam_look_at.x, _cam_look_at.y, _cam_look_at.z],
		"camera_rot_deg": [board._camera.rotation_degrees.x, board._camera.rotation_degrees.y, board._camera.rotation_degrees.z],
		"camera_fov": board._camera.fov,
		"camera_near": board._camera.near,
		"camera_far": board._camera.far,
		"hand_rig_origin": [board._hand_rig.position.x, board._hand_rig.position.y, board._hand_rig.position.z],
		"hand_rig_rot_deg": [board._hand_rig.rotation_degrees.x, board._hand_rig.rotation_degrees.y, board._hand_rig.rotation_degrees.z],
		"opponent_rack_pos": opp_pos,
		"opponent_rack_rot": opp_rot,
		"opponent_rack_scale": opp_scale,
		"discard_pos": disc_pos,
		"discard_rot": disc_rot,
		"stock_pos": [board._stock_view.position.x, board._stock_view.position.y, board._stock_view.position.z],
		"stock_rot": [board._stock_view.rotation_degrees.x, board._stock_view.rotation_degrees.y, board._stock_view.rotation_degrees.z],
		"indicator_pos": [_ind_pos.x, _ind_pos.y, _ind_pos.z],
		"indicator_rot": [0.0, _ind_yaw, 0.0],
		"meld_area_pos": meld_pos,
		"meld_area_rot": meld_rot,
		"meld_area_size": meld_sz,
	}


func _generate_tuning_gdscript_snippet() -> String:
	var d := _serialize_layout_dict()
	var lines: PackedStringArray = []
	var sp: Array = d["stock_pos"]
	var sr: Array = d["stock_rot"]
	var ip: Array = d["indicator_pos"]
	var ir: Array = d["indicator_rot"]
	lines.append("const STOCK_POS_3D: Vector3 = Vector3(%.3f, TABLE_SURFACE_Y, %.3f)" % [sp[0], sp[2]])
	lines.append("const STOCK_ROT_DEG: Vector3 = Vector3(%.1f, %.1f, %.1f)" % [sr[0], sr[1], sr[2]])
	lines.append("")
	lines.append("const INDICATOR_POS_3D: Vector3 = Vector3(%.3f, TABLE_SURFACE_Y + 0.0045, %.3f)" % [ip[0], ip[2]])
	lines.append("const INDICATOR_ROT_DEG: Vector3 = Vector3(%.1f, %.1f, %.1f)" % [ir[0], ir[1], ir[2]])
	lines.append("")
	lines.append("const OPPONENT_RACK_POS_3D: Dictionary = {")
	for s in [1, 2, 3]:
		var p: Array = d["opponent_rack_pos"][s]
		lines.append("\t%d: Vector3(%.3f, TABLE_SURFACE_Y, %.3f)," % [s, p[0], p[2]])
	lines.append("}")
	lines.append("")
	lines.append("const OPPONENT_RACK_ROT_DEG: Dictionary = {")
	for s in [1, 2, 3]:
		var r: Array = d["opponent_rack_rot"][s]
		lines.append("\t%d: Vector3(%.1f, %.1f, %.1f)," % [s, r[0], r[1], r[2]])
	lines.append("}")
	lines.append("const OPPONENT_RACK_SCALE: float = %.3f" % float(d["opponent_rack_scale"]))
	lines.append("")
	lines.append("const DISCARD_POS_3D: Dictionary = {")
	for s in range(4):
		var p: Array = d["discard_pos"][s]
		lines.append("\t%d: Vector3(%.3f, TABLE_SURFACE_Y, %.3f)," % [s, p[0], p[2]])
	lines.append("}")
	lines.append("")
	lines.append("const DISCARD_ROT_DEG: Dictionary = {")
	for s in range(4):
		var r: Array = d["discard_rot"][s]
		lines.append("\t%d: Vector3(%.1f, %.1f, %.1f)," % [s, r[0], r[1], r[2]])
	lines.append("}")
	lines.append("")
	lines.append("const MELD_ZONE_MIN: Vector2 = Vector2(-0.44, -0.30)")
	lines.append("const MELD_ZONE_MAX: Vector2 = Vector2(0.44, 0.20)")
	lines.append("")
	lines.append("const MELD_AREA_POS_3D: Dictionary = {")
	for s in range(4):
		var mp: Array = d["meld_area_pos"][s]
		lines.append("\t%d: Vector3(%.3f, TABLE_SURFACE_Y, %.3f)," % [s, mp[0], mp[2]])
	lines.append("}")
	lines.append("")
	lines.append("const MELD_AREA_ROT_DEG: Dictionary = {")
	for s in range(4):
		var mr: Array = d["meld_area_rot"][s]
		lines.append("\t%d: Vector3(%.1f, %.1f, %.1f)," % [s, mr[0], mr[1], mr[2]])
	lines.append("}")
	lines.append("")
	lines.append("const MELD_AREA_SIZE: Dictionary = {")
	for s in range(4):
		var msz: Array = d["meld_area_size"][s]
		lines.append("\t%d: Vector2(%.3f, %.3f)," % [s, msz[0], msz[1]])
	lines.append("}")
	lines.append("")
	var cp: Array = d["camera_pos"]
	var cl: Array = d["camera_look_at"]
	var ho: Array = d["hand_rig_origin"]
	var hr: Array = d["hand_rig_rot_deg"]
	lines.append("# ─── Camera Framing (D6) ───")
	lines.append("const CAMERA_FOV: float = %.1f" % float(d["camera_fov"]))
	lines.append("const CAMERA_POS: Vector3 = Vector3(%.3f, %.3f, %.3f)" % [cp[0], cp[1], cp[2]])
	lines.append("const CAMERA_LOOK_AT: Vector3 = Vector3(%.3f, %.3f, %.3f)" % [cl[0], cl[1], cl[2]])
	lines.append("")
	lines.append("# ─── Hand Rig (Camera-Local Space, D7) ───")
	lines.append("const HAND_RIG_ORIGIN: Vector3 = Vector3(%.3f, %.3f, %.3f)" % [ho[0], ho[1], ho[2]])
	lines.append("const HAND_RIG_ROT_DEG: Vector3 = Vector3(%.1f, %.1f, %.1f)" % [hr[0], hr[1], hr[2]])
	return "\n".join(lines)


func _copy_tuning_to_clipboard() -> void:
	var code := _generate_tuning_gdscript_snippet()
	DisplayServer.clipboard_set(code)
	_status_label.text = "Copied GDScript constants to clipboard!"


func _save_to_project_and_user() -> void:
	var data := _serialize_layout_dict()
	var json_str := JSON.stringify(data, "\t")
	var f_user := FileAccess.open("user://board_layout.json", FileAccess.WRITE)
	if f_user != null:
		f_user.store_string(json_str)
		f_user.close()

	# Also write directly to res://ui/vector_table/VectorTuning3D.gd when running from project folder
	var tuning_path := ProjectSettings.globalize_path("res://ui/vector_table/VectorTuning3D.gd")
	var existing := FileAccess.get_file_as_string(tuning_path)
	if not existing.is_empty():
		var start_idx := existing.find("const STOCK_POS_3D:")
		var end_idx := existing.find("const HAND_RACK_LENGTH:")
		if start_idx >= 0 and end_idx > start_idx:
			var updated := existing.substr(0, start_idx) + _generate_tuning_gdscript_snippet() + "\n\n" + existing.substr(end_idx)
			var fw := FileAccess.open(tuning_path, FileAccess.WRITE)
			if fw != null:
				fw.store_string(updated)
				fw.close()
				_status_label.text = "Saved directly to ui/vector_table/VectorTuning3D.gd & user://board_layout.json!"
				return
	_status_label.text = "Saved layout to user://board_layout.json!"


func _load_saved_user_layout_if_exists() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not FileAccess.file_exists("user://board_layout.json"):
		return
	var raw := FileAccess.get_file_as_string("user://board_layout.json")
	var parsed = JSON.parse_string(raw)
	if not (parsed is Dictionary) or board == null:
		return
	var d: Dictionary = parsed
	if board._meld_layout != null and d.has("meld_area_pos"):
		var mp_dict: Dictionary = d["meld_area_pos"]
		var mr_dict: Dictionary = d.get("meld_area_rot", {})
		var ms_dict: Dictionary = d.get("meld_area_size", {})
		for s in range(4):
			var key_str := str(s)
			var k = s if mp_dict.has(s) else (key_str if mp_dict.has(key_str) else null)
			if k != null:
				var mp: Array = mp_dict[k]
				var mr: Array = mr_dict.get(k, [0.0, 0.0, 0.0])
				var ms: Array = ms_dict.get(k, [0.50, 0.145])
				board._meld_layout.set_seat_area_transform(
					s,
					Vector3(float(mp[0]), float(mp[1]), float(mp[2])),
					Vector3(float(mr[0]), float(mr[1]), float(mr[2])),
					Vector2(float(ms[0]), float(ms[1])),
					1.0
				)


func _reset_to_defaults() -> void:
	if FileAccess.file_exists("user://board_layout.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://board_layout.json"))
	if board == null:
		return
	if board._hand_rig != null:
		board._hand_rig.position = TUNING.HAND_RIG_ORIGIN
		board._hand_rig.rotation_degrees = TUNING.HAND_RIG_ROT_DEG
		board._hand_rig.scale = Vector3.ONE
	for s in [1, 2, 3]:
		if board._opponent_racks.has(s):
			var opp: Node3D = board._opponent_racks[s]
			opp.position = TUNING.OPPONENT_RACK_POS_3D[s]
			opp.rotation_degrees = TUNING.OPPONENT_RACK_ROT_DEG[s]
			opp.scale = Vector3.ONE * TUNING.OPPONENT_RACK_SCALE
	if board._discard_piles_view != null:
		for s in range(4):
			board._discard_piles_view.set_pile_transform(s, TUNING.DISCARD_POS_3D[s], TUNING.DISCARD_ROT_DEG[s], 1.0)
			_discard_scales[s] = 1.0
		board._sync_discards()
	if board._stock_view != null:
		board._stock_view.position = TUNING.STOCK_POS_3D
		board._stock_view.rotation_degrees = TUNING.STOCK_ROT_DEG
	_ind_pos = TUNING.INDICATOR_POS_3D
	_ind_yaw = TUNING.INDICATOR_ROT_DEG.y
	_apply_indicator_transform()
	if board._meld_layout != null:
		board._meld_layout.independent_seat_areas = true
		board._meld_layout.row_pitch_scale = 1.0
		board._meld_layout.tile_pitch_scale = 1.0
		board._meld_layout.group_gap_scale = 1.0
		for s in range(4):
			board._meld_layout.set_seat_area_transform(s, TUNING.MELD_AREA_POS_3D[s], TUNING.MELD_AREA_ROT_DEG[s], TUNING.MELD_AREA_SIZE[s], 1.0)
		_refresh_board_melds()
	if board._camera != null:
		_cam_look_at = TUNING.CAMERA_LOOK_AT
		board._camera.fov = TUNING.CAMERA_FOV
		board._camera.near = 0.05
		board._camera.far = 4000.0
		board._camera.h_offset = 0.0
		board._camera.v_offset = 0.0
		board._camera.look_at_from_position(TUNING.CAMERA_POS, _cam_look_at, Vector3.UP)
	_sync_ui_from_board()
	_update_gizmo()
	_status_label.text = "Reset all layout & camera parameters to VectorTuning3D.gd defaults."
