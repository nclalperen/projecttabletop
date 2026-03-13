extends Control

signal game_started(player_count: int, seed_value: int, bot_difficulties: Array, practice_mode: bool)
signal back_pressed

const MENU_STYLE: Script = preload("res://ui/services/MenuStyleRegistry.gd")
const PLAYER_PROFILE: Script = preload("res://ui/services/PlayerProfile.gd")
const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")

const AVATAR_IDS: Array[StringName] = [
	ASSET_IDS.UI_AVATAR_FACE_1,
	ASSET_IDS.UI_AVATAR_FACE_2,
	ASSET_IDS.UI_AVATAR_FACE_3,
	ASSET_IDS.UI_AVATAR_FACE_4,
]

const BOT_NAMES: Array[String] = ["Ahmet", "Elif", "Mehmet", "Zeynep", "Burak", "Aylin"]
const DIFFICULTY_OPTIONS: Array[String] = ["Easy", "Normal", "Hard"]
const SEAT_COLORS: Array[Color] = [
	Color(0.95, 0.85, 0.55, 1.0),  # gold
	Color(0.55, 0.78, 0.95, 1.0),  # blue
	Color(0.68, 0.92, 0.62, 1.0),  # green
	Color(0.92, 0.62, 0.72, 1.0),  # pink
]

var _player_count: int = 4
var _seed_value: int = -1
var _practice_mode: bool = false
var _bot_difficulty_buttons: Array = []  # Array of Arrays of Buttons per slot
var _bot_difficulties: Array[String] = ["Normal", "Normal", "Normal"]
var _player_count_buttons: Array[Button] = []
var _slots_container: VBoxContainer = null
var _slot_panels: Array[PanelContainer] = []
var _practice_check: CheckButton = null
var _match_info_label: Label = null
var _rule_config: RuleConfig = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Dark backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.12, 0.09, 0.97)
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_width_left = 2; style.border_width_right = 2
	style.border_color = MENU_STYLE.color(&"panel_border")
	style.corner_radius_top_left = 10; style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10; style.corner_radius_bottom_right = 10
	style.content_margin_left = 28; style.content_margin_right = 28
	style.content_margin_top = 24; style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Game Lobby"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", MENU_STYLE.color(&"title_text"))
	vbox.add_child(title)

	_add_separator(vbox)

	# Player count selector
	var pc_label := Label.new()
	pc_label.text = "Players"
	pc_label.add_theme_font_size_override("font_size", 18)
	pc_label.add_theme_color_override("font_color", MENU_STYLE.color(&"subtitle_text"))
	vbox.add_child(pc_label)

	var pc_row := HBoxContainer.new()
	pc_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pc_row.add_theme_constant_override("separation", 10)
	for count in [4]:
		var btn := Button.new()
		btn.text = str(count)
		btn.custom_minimum_size = Vector2(56, 38)
		btn.toggle_mode = true
		btn.button_pressed = (count == _player_count)
		btn.pressed.connect(_on_player_count_selected.bind(count))
		pc_row.add_child(btn)
		_player_count_buttons.append(btn)
	vbox.add_child(pc_row)

	_add_separator(vbox)

	# Player slots
	_slots_container = VBoxContainer.new()
	_slots_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_slots_container)
	_rebuild_slots()

	_add_separator(vbox)

	# Match info
	_match_info_label = Label.new()
	_match_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_match_info_label.add_theme_font_size_override("font_size", 15)
	_match_info_label.add_theme_color_override("font_color", MENU_STYLE.color(&"muted_text"))
	vbox.add_child(_match_info_label)
	_update_match_info()

	# Practice mode checkbox
	var practice_row := HBoxContainer.new()
	practice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	practice_row.add_theme_constant_override("separation", 8)
	_practice_check = CheckButton.new()
	_practice_check.text = "Practice Mode"
	_practice_check.button_pressed = _practice_mode
	_practice_check.toggled.connect(func(on: bool) -> void: _practice_mode = on)
	practice_row.add_child(_practice_check)
	vbox.add_child(practice_row)

	_add_separator(vbox)

	# Action buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(110, 42)
	back_btn.pressed.connect(func() -> void: back_pressed.emit())
	btn_row.add_child(back_btn)

	var start_btn := Button.new()
	start_btn.text = "Start Game"
	start_btn.custom_minimum_size = Vector2(160, 42)
	start_btn.pressed.connect(_on_start_pressed)
	btn_row.add_child(start_btn)

	vbox.add_child(btn_row)


func set_defaults(_player_count_unused: int, seed_value: int) -> void:
	_player_count = 4
	_seed_value = seed_value


func set_rule_config(config: RuleConfig) -> void:
	_rule_config = config
	if _match_info_label != null:
		_update_match_info()


func _on_player_count_selected(count: int) -> void:
	_player_count = count
	for btn in _player_count_buttons:
		btn.button_pressed = (int(btn.text) == count)
	_rebuild_slots()


func _rebuild_slots() -> void:
	if _slots_container == null:
		return
	for child in _slots_container.get_children():
		child.queue_free()
	_slot_panels.clear()
	_bot_difficulty_buttons.clear()

	# Slot 0: Player
	_slots_container.add_child(_build_player_slot())

	# Slots 1..N-1: Bots
	for i in range(1, _player_count):
		var bot_index: int = i - 1
		var bot_name: String = BOT_NAMES[bot_index % BOT_NAMES.size()]
		_slots_container.add_child(_build_bot_slot(i, bot_name, bot_index))


func _build_player_slot() -> PanelContainer:
	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", _slot_style(0))
	_slot_panels.append(slot)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_child(hbox)
	slot.add_child(margin)

	# Avatar
	var avatar := TextureRect.new()
	avatar.custom_minimum_size = Vector2(36, 36)
	avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var avatar_idx: int = PLAYER_PROFILE.avatar_index if PLAYER_PROFILE.avatar_index < AVATAR_IDS.size() else 0
	avatar.texture = ASSET_REGISTRY.texture(AVATAR_IDS[avatar_idx])
	hbox.add_child(avatar)

	# Name + ready
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = PLAYER_PROFILE.display_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", MENU_STYLE.color(&"lobby_player_local"))
	info.add_child(name_label)
	var meta := Label.new()
	meta.text = "You"
	meta.add_theme_font_size_override("font_size", 13)
	meta.add_theme_color_override("font_color", MENU_STYLE.color(&"muted_text"))
	info.add_child(meta)
	hbox.add_child(info)

	# Ready checkmark
	var ready_icon := TextureRect.new()
	ready_icon.custom_minimum_size = Vector2(24, 24)
	ready_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	ready_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ready_icon.texture = ASSET_REGISTRY.texture(ASSET_IDS.UI_ICON_CHECKMARK)
	ready_icon.modulate = MENU_STYLE.color(&"lobby_ready_on")
	ready_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(ready_icon)

	return slot


func _build_bot_slot(seat_index: int, bot_name: String, bot_index: int) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", _slot_style(seat_index))
	_slot_panels.append(slot)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_child(hbox)
	slot.add_child(margin)

	# Avatar
	var avatar := TextureRect.new()
	avatar.custom_minimum_size = Vector2(36, 36)
	avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.texture = ASSET_REGISTRY.texture(AVATAR_IDS[seat_index % AVATAR_IDS.size()])
	hbox.add_child(avatar)

	# Name
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = bot_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", MENU_STYLE.color(&"lobby_player_remote"))
	info.add_child(name_label)
	var meta := Label.new()
	meta.text = "Bot"
	meta.add_theme_font_size_override("font_size", 13)
	meta.add_theme_color_override("font_color", MENU_STYLE.color(&"muted_text"))
	info.add_child(meta)
	hbox.add_child(info)

	# Difficulty buttons
	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 4)
	diff_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var slot_buttons: Array[Button] = []
	for diff in DIFFICULTY_OPTIONS:
		var btn := Button.new()
		btn.text = diff
		btn.custom_minimum_size = Vector2(60, 30)
		btn.add_theme_font_size_override("font_size", 13)
		btn.toggle_mode = true
		btn.button_pressed = (diff == _bot_difficulties[bot_index] if bot_index < _bot_difficulties.size() else diff == "Normal")
		btn.pressed.connect(_on_difficulty_selected.bind(bot_index, diff))
		diff_row.add_child(btn)
		slot_buttons.append(btn)
	_bot_difficulty_buttons.append(slot_buttons)
	hbox.add_child(diff_row)

	# Ready checkmark (bots auto-ready)
	var ready_icon := TextureRect.new()
	ready_icon.custom_minimum_size = Vector2(24, 24)
	ready_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	ready_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ready_icon.texture = ASSET_REGISTRY.texture(ASSET_IDS.UI_ICON_CHECKMARK)
	ready_icon.modulate = MENU_STYLE.color(&"lobby_ready_on")
	ready_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(ready_icon)

	return slot


func _on_difficulty_selected(bot_index: int, difficulty: String) -> void:
	# Grow array if needed
	while _bot_difficulties.size() <= bot_index:
		_bot_difficulties.append("Normal")
	_bot_difficulties[bot_index] = difficulty
	# Update toggle states for this bot's buttons
	if bot_index < _bot_difficulty_buttons.size():
		for btn in _bot_difficulty_buttons[bot_index]:
			btn.button_pressed = (btn.text == difficulty)


func _on_start_pressed() -> void:
	# Build difficulties array for active bots only
	var difficulties: Array[String] = []
	for i in range(_player_count - 1):
		if i < _bot_difficulties.size():
			difficulties.append(_bot_difficulties[i])
		else:
			difficulties.append("Normal")
	game_started.emit(_player_count, _seed_value, difficulties, _practice_mode)


func _update_match_info() -> void:
	if _match_info_label == null:
		return
	var rounds_text: String = "Best of 5 rounds"
	if _rule_config != null:
		var mode: String = str(_rule_config.match_end_mode) if _rule_config.match_end_mode != null else "rounds"
		var value: int = int(_rule_config.match_end_value) if _rule_config.match_end_value > 0 else 5
		if mode == "rounds":
			rounds_text = "Best of %d rounds" % value
		else:
			rounds_text = "Target score: %d" % value
	_match_info_label.text = rounds_text


func _slot_style(seat_index: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	var color: Color = SEAT_COLORS[seat_index % SEAT_COLORS.size()]
	s.bg_color = Color(color.r * 0.15, color.g * 0.15, color.b * 0.15, 0.85)
	s.border_width_left = 3
	s.border_color = color.darkened(0.2)
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	return s


func _add_separator(parent: Control) -> void:
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", MENU_STYLE.color(&"panel_border").darkened(0.3))
	parent.add_child(sep)
