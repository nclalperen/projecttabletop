extends Control
class_name RoundEndPanel

signal new_round_requested
signal forfeit_requested
signal return_to_menu_requested

const MENU_STYLE: Script = preload("res://ui/services/MenuStyleRegistry.gd")
const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")
const PLAYER_PROFILE: Script = preload("res://ui/services/PlayerProfile.gd")

const AVATAR_IDS: Array[StringName] = [
	ASSET_IDS.UI_AVATAR_FACE_1,
	ASSET_IDS.UI_AVATAR_FACE_2,
	ASSET_IDS.UI_AVATAR_FACE_3,
	ASSET_IDS.UI_AVATAR_FACE_4,
]

var _player_count: int = 4
var _round_index: int = 1
var _max_rounds: int = 7
var _match_end_mode: String = "rounds"
var _players_data: Array = []  # Array of Dictionaries: {name, score_round, score_total, is_bot, is_winner, is_you, penalty}
var _forfeited_seats: Array[bool] = []
var _ready_states: Array[bool] = []
var _ready_icons: Array[TextureRect] = []
var _ready_labels: Array[Label] = []
var _ready_button: Button = null
var _forfeit_button: Button = null
var _overlay: ColorRect = null
var _auto_ready_timer: float = 0.0
var _all_ready: bool = false


func configure(state, round_index: int, rule_config: RuleConfig, forfeited_seats: Array[bool]) -> void:
	_round_index = round_index
	_forfeited_seats = forfeited_seats
	if rule_config != null:
		_match_end_mode = str(rule_config.match_end_mode)
		_max_rounds = int(rule_config.match_end_value) if rule_config.match_end_value > 0 else 7

	if state == null:
		return
	_player_count = state.players.size()

	# Find winner (lowest total score)
	var winner_idx: int = -1
	var lowest_total: float = INF
	for i in range(_player_count):
		var total: float = float(state.players[i].score_total)
		if total < lowest_total:
			lowest_total = total
			winner_idx = i

	_players_data.clear()
	_ready_states.clear()
	for i in range(_player_count):
		var p = state.players[i]
		var is_you: bool = (i == 0)
		var is_bot: bool = (i != 0)
		var forfeited: bool = i < _forfeited_seats.size() and _forfeited_seats[i]
		var name_text: String
		if is_you:
			name_text = PLAYER_PROFILE.display_name
			if forfeited:
				name_text += " (BOT)"
		else:
			name_text = "Bot %d" % i
		_players_data.append({
			"name": name_text,
			"score_round": int(p.score_round),
			"score_total": int(p.score_total),
			"penalty": int(p.deal_penalty_points),
			"is_bot": is_bot or forfeited,
			"is_winner": (i == winner_idx),
			"is_you": is_you and not forfeited,
			"seat": i,
		})
		_ready_states.append(is_bot or forfeited)

	# Sort by score_total ascending (lowest = best)
	_players_data.sort_custom(func(a, b): return int(a["score_total"]) < int(b["score_total"]))


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Dark overlay
	_overlay = ColorRect.new()
	_overlay.name = "DarkOverlay"
	_overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Round header
	var header_row := HBoxContainer.new()
	header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := Label.new()
	title.text = "Round Complete"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", _color(&"title_text"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)
	var round_label := Label.new()
	if _match_end_mode == "rounds":
		round_label.text = "Round %d/%d" % [_round_index, _max_rounds]
	else:
		round_label.text = "Round %d" % _round_index
	round_label.add_theme_font_size_override("font_size", 18)
	round_label.add_theme_color_override("font_color", _color(&"muted_text"))
	header_row.add_child(round_label)
	vbox.add_child(header_row)

	_add_separator(vbox)

	# Character portrait row
	var portrait_row := HBoxContainer.new()
	portrait_row.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_row.add_theme_constant_override("separation", 16)
	for i in range(_player_count):
		var avatar := TextureRect.new()
		avatar.custom_minimum_size = Vector2(42, 42)
		avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var avatar_idx: int = i % AVATAR_IDS.size()
		if i == 0:
			avatar_idx = PLAYER_PROFILE.avatar_index if PLAYER_PROFILE.avatar_index < AVATAR_IDS.size() else 0
		avatar.texture = ASSET_REGISTRY.texture(AVATAR_IDS[avatar_idx])
		portrait_row.add_child(avatar)
	vbox.add_child(portrait_row)

	_add_separator(vbox)

	# Score table header
	var col_header := HBoxContainer.new()
	col_header.add_theme_constant_override("separation", 6)
	_add_header_label(col_header, "#", 30)
	_add_header_label(col_header, "Player", 0, true)
	_add_header_label(col_header, "Penalty", 70)
	_add_header_label(col_header, "Round", 70)
	_add_header_label(col_header, "Total", 70)
	_add_header_label(col_header, "", 28)  # ready column
	vbox.add_child(col_header)

	# Player rows (sorted by total ascending)
	_ready_icons.clear()
	_ready_labels.clear()
	for rank in range(_players_data.size()):
		var pd: Dictionary = _players_data[rank]
		var row_panel := _build_score_row(rank + 1, pd)
		vbox.add_child(row_panel)

	_add_separator(vbox)

	# Action buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)

	_ready_button = Button.new()
	_ready_button.text = "Ready"
	_ready_button.custom_minimum_size = Vector2(120, 40)
	_ready_button.pressed.connect(_on_ready_pressed)
	btn_row.add_child(_ready_button)

	_forfeit_button = Button.new()
	_forfeit_button.text = "Forfeit"
	_forfeit_button.custom_minimum_size = Vector2(120, 40)
	_forfeit_button.pressed.connect(_on_forfeit_pressed)
	# Hide forfeit if player already forfeited
	if _forfeited_seats.size() > 0 and _forfeited_seats[0]:
		_forfeit_button.visible = false
		_ready_button.visible = false
	btn_row.add_child(_forfeit_button)

	var menu_btn := Button.new()
	menu_btn.text = "Return to Menu"
	menu_btn.custom_minimum_size = Vector2(150, 40)
	menu_btn.pressed.connect(func() -> void: return_to_menu_requested.emit())
	btn_row.add_child(menu_btn)

	vbox.add_child(btn_row)

	# Start bot auto-ready timer
	_auto_ready_timer = 1.5
	set_process(true)


func _process(delta: float) -> void:
	if _all_ready:
		return
	if _auto_ready_timer > 0.0:
		_auto_ready_timer -= delta
		if _auto_ready_timer <= 0.0:
			# Auto-ready all bots with staggered timing
			for i in range(_ready_states.size()):
				if _players_data[i]["is_bot"]:
					_set_ready(i, true)
			_check_all_ready()


func _on_ready_pressed() -> void:
	# Find player's index in sorted data
	for i in range(_players_data.size()):
		if _players_data[i]["is_you"]:
			_set_ready(i, true)
			break
	if _ready_button != null:
		_ready_button.disabled = true
		_ready_button.text = "Ready!"
	_check_all_ready()


func _on_forfeit_pressed() -> void:
	forfeit_requested.emit()
	# Mark player as forfeited visually
	for i in range(_players_data.size()):
		if _players_data[i]["is_you"]:
			_players_data[i]["is_bot"] = true
			_players_data[i]["is_you"] = false
			_players_data[i]["name"] += " (BOT)"
			_set_ready(i, true)
			break
	if _ready_button != null:
		_ready_button.visible = false
	if _forfeit_button != null:
		_forfeit_button.visible = false
	_check_all_ready()


func _set_ready(sorted_index: int, ready: bool) -> void:
	if sorted_index >= _ready_states.size():
		return
	_ready_states[sorted_index] = ready
	if sorted_index < _ready_icons.size() and _ready_icons[sorted_index] != null:
		_ready_icons[sorted_index].modulate = _color(&"lobby_ready_on") if ready else _color(&"lobby_ready_off")
	if sorted_index < _ready_labels.size() and _ready_labels[sorted_index] != null:
		_ready_labels[sorted_index].text = "Ready" if ready else ""


func _check_all_ready() -> void:
	for r in _ready_states:
		if not r:
			return
	_all_ready = true
	# Brief delay then advance
	var timer := get_tree().create_timer(0.5)
	timer.timeout.connect(func() -> void: new_round_requested.emit())


func _build_score_row(rank: int, pd: Dictionary) -> PanelContainer:
	var is_winner: bool = bool(pd["is_winner"])
	var is_you: bool = bool(pd["is_you"])
	var row_panel := PanelContainer.new()
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bg := StyleBoxFlat.new()
	if is_winner:
		bg.bg_color = Color(0.30, 0.24, 0.08, 0.6)
	elif is_you:
		bg.bg_color = Color(0.12, 0.16, 0.24, 0.5)
	else:
		bg.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	bg.content_margin_left = 8; bg.content_margin_right = 8
	bg.content_margin_top = 5; bg.content_margin_bottom = 5
	bg.corner_radius_top_left = 4; bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4; bg.corner_radius_bottom_right = 4
	row_panel.add_theme_stylebox_override("panel", bg)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)

	# Rank
	var rank_label := Label.new()
	rank_label.text = str(rank)
	rank_label.custom_minimum_size = Vector2(30, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_font_size_override("font_size", 18)
	if is_winner:
		rank_label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.55))
	else:
		rank_label.add_theme_color_override("font_color", _color(&"muted_text"))
	hbox.add_child(rank_label)

	# Name
	var name_label := Label.new()
	var display_name: String = str(pd["name"])
	if is_winner:
		display_name += " ★"
	name_label.text = display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 19)
	if is_winner:
		name_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.68))
	elif is_you:
		name_label.add_theme_color_override("font_color", _color(&"lobby_player_local"))
	else:
		name_label.add_theme_color_override("font_color", _color(&"body_text"))
	hbox.add_child(name_label)

	# Penalty
	var penalty_label := Label.new()
	var penalty_val: int = int(pd["penalty"])
	penalty_label.text = str(penalty_val) if penalty_val > 0 else "-"
	penalty_label.custom_minimum_size = Vector2(70, 0)
	penalty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	penalty_label.add_theme_font_size_override("font_size", 18)
	penalty_label.add_theme_color_override("font_color", Color(0.85, 0.55, 0.45) if penalty_val > 0 else _color(&"muted_text"))
	hbox.add_child(penalty_label)

	# Round score
	var round_label := Label.new()
	var round_val: int = int(pd["score_round"])
	round_label.text = str(round_val)
	round_label.custom_minimum_size = Vector2(70, 0)
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	round_label.add_theme_font_size_override("font_size", 18)
	var round_color: Color = Color(0.55, 0.82, 0.50) if round_val <= 0 else Color(0.95, 0.60, 0.50)
	round_label.add_theme_color_override("font_color", round_color)
	hbox.add_child(round_label)

	# Total score
	var total_label := Label.new()
	total_label.text = str(int(pd["score_total"]))
	total_label.custom_minimum_size = Vector2(70, 0)
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total_label.add_theme_font_size_override("font_size", 18)
	total_label.add_theme_color_override("font_color", _color(&"title_text"))
	hbox.add_child(total_label)

	# Ready icon
	var ready_icon := TextureRect.new()
	ready_icon.custom_minimum_size = Vector2(22, 22)
	ready_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	ready_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ready_icon.texture = ASSET_REGISTRY.texture(ASSET_IDS.UI_ICON_CHECKMARK)
	ready_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Find sorted index for this player
	var sorted_idx: int = _players_data.find(pd)
	var is_ready: bool = sorted_idx >= 0 and sorted_idx < _ready_states.size() and _ready_states[sorted_idx]
	ready_icon.modulate = _color(&"lobby_ready_on") if is_ready else Color(1, 1, 1, 0.15)
	_ready_icons.append(ready_icon)
	hbox.add_child(ready_icon)

	# Ready label (hidden for now, used for updates)
	var ready_label := Label.new()
	ready_label.text = "Ready" if is_ready else ""
	ready_label.visible = false  # icons are enough
	_ready_labels.append(ready_label)

	row_panel.add_child(hbox)
	return row_panel


func _panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.14, 0.12, 0.09, 0.97)
	s.border_width_top = 2; s.border_width_bottom = 2
	s.border_width_left = 2; s.border_width_right = 2
	s.border_color = _color(&"panel_border")
	s.corner_radius_top_left = 10; s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10; s.corner_radius_bottom_right = 10
	s.content_margin_left = 24; s.content_margin_right = 24
	s.content_margin_top = 20; s.content_margin_bottom = 20
	return s


func _add_header_label(parent: HBoxContainer, text: String, min_width: int, expand: bool = false) -> void:
	var label := Label.new()
	label.text = text
	if min_width > 0:
		label.custom_minimum_size = Vector2(min_width, 0)
	if expand:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if min_width > 0 and text != "#" else HORIZONTAL_ALIGNMENT_LEFT
	if text == "#":
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(30, 0)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", _color(&"muted_text"))
	parent.add_child(label)


func _add_separator(parent: Control) -> void:
	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", _color(&"panel_border").darkened(0.3))
	parent.add_child(sep)


func _color(id: StringName) -> Color:
	return MENU_STYLE.color(id)
