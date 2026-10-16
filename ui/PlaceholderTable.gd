extends Control

const GAME_CATALOG: Script = preload("res://gd/config/TabletopGameCatalog.gd")
const MENU_STYLE: Script = preload("res://ui/services/MenuStyleRegistry.gd")
const TABLE_ENV_3D_SCRIPT: Script = preload("res://ui/common_tabletop/TableEnvironment3D.gd")
const SEAT_BADGE_SCENE: PackedScene = preload("res://ui/common_tabletop/PlayerSeatBadge.tscn")

@onready var _eyebrow: Label = $Margin/RootCard/CardMargin/VBox/Eyebrow
@onready var _title: Label = $Margin/RootCard/CardMargin/VBox/Title
@onready var _subtitle: Label = $Margin/RootCard/CardMargin/VBox/Subtitle
@onready var _summary: Label = $Margin/RootCard/CardMargin/VBox/Summary
@onready var _roster_header: Label = $Margin/RootCard/CardMargin/VBox/RosterHeader
@onready var _roster_list: VBoxContainer = $Margin/RootCard/CardMargin/VBox/RosterList
@onready var _match_meta: Label = $Margin/RootCard/CardMargin/VBox/Footer/MatchMeta
@onready var _back_button: Button = $Margin/RootCard/CardMargin/VBox/Footer/BackButton

var _game_id: StringName = GAME_CATALOG.default_game_id()
var _lobby_model: Dictionary = {}
var _local_puid: String = ""
var _seat_by_puid: Dictionary = {}
var _match_id: String = ""
var _match_seed: int = -1
var _table_config = null
var _table_environment_3d: Node3D = null
var _seat_badges: Array[Control] = []


func _ready() -> void:
	_ensure_nodes()
	_apply_theme_overrides()
	if _back_button != null and not _back_button.pressed.is_connected(_on_back_pressed):
		_back_button.pressed.connect(_on_back_pressed)
	if _table_config == null:
		_table_config = GAME_CATALOG.default_table_config(_game_id)
	_ensure_table_environment()
	_refresh_view()


func _ensure_nodes() -> void:
	if _eyebrow == null:
		_eyebrow = get_node_or_null("Margin/RootCard/CardMargin/VBox/Eyebrow") as Label
	if _title == null:
		_title = get_node_or_null("Margin/RootCard/CardMargin/VBox/Title") as Label
	if _subtitle == null:
		_subtitle = get_node_or_null("Margin/RootCard/CardMargin/VBox/Subtitle") as Label
	if _summary == null:
		_summary = get_node_or_null("Margin/RootCard/CardMargin/VBox/Summary") as Label
	if _roster_header == null:
		_roster_header = get_node_or_null("Margin/RootCard/CardMargin/VBox/RosterHeader") as Label
	if _roster_list == null:
		_roster_list = get_node_or_null("Margin/RootCard/CardMargin/VBox/RosterList") as VBoxContainer
	if _match_meta == null:
		_match_meta = get_node_or_null("Margin/RootCard/CardMargin/VBox/Footer/MatchMeta") as Label
	if _back_button == null:
		_back_button = get_node_or_null("Margin/RootCard/CardMargin/VBox/Footer/BackButton") as Button


func _ensure_table_environment() -> void:
	if _table_environment_3d == null or not is_instance_valid(_table_environment_3d):
		_table_environment_3d = TABLE_ENV_3D_SCRIPT.new()
		_table_environment_3d.name = "TableEnvironment3D"
		add_child(_table_environment_3d)
	if _table_config != null and _table_environment_3d.has_method("set_config"):
		_table_environment_3d.call("set_config", _table_config)


func get_table_environment_3d() -> Node3D:
	_ensure_table_environment()
	return _table_environment_3d


func get_seat_badges() -> Array[Control]:
	return _seat_badges


func configure_table(game_id: StringName, lobby_model: Dictionary, local_puid: String, seat_by_puid: Dictionary, match_id: String, match_seed: int) -> void:
	_game_id = game_id
	_lobby_model = lobby_model.duplicate(true)
	_local_puid = local_puid
	_seat_by_puid = seat_by_puid.duplicate(true)
	_match_id = match_id
	_match_seed = match_seed
	_table_config = GAME_CATALOG.default_table_config(_game_id)
	_ensure_nodes()
	_ensure_table_environment()
	if _roster_list != null:
		_refresh_view()


func set_table_config(config) -> void:
	_table_config = config
	_ensure_nodes()
	_ensure_table_environment()
	if _roster_list != null:
		_refresh_view()


func get_table_config():
	if _table_config == null:
		_table_config = GAME_CATALOG.default_table_config(_game_id)
	return _table_config


func _refresh_view() -> void:
	_ensure_nodes()
	if _eyebrow == null or _roster_list == null:
		return
	var game_meta: Dictionary = GAME_CATALOG.game(_game_id)
	_eyebrow.text = "%s Multiplayer Table" % GAME_CATALOG.legacy_label(_game_id)
	_title.text = String(game_meta.get("name", "Tabletop"))
	_subtitle.text = String(game_meta.get("subtitle", "Tabletop session"))
	_summary.text = String(game_meta.get("description", ""))
	_roster_header.text = "Table Seats"
	var seats_val = _table_config.seat_count if _table_config != null else _lobby_model.get("attrs", {}).get("seat_count", GAME_CATALOG.default_player_count(_game_id))
	_match_meta.text = "Match: %s  |  Seed: %s  |  Seats: %s" % [
		_match_id if _match_id != "" else "pending",
		"random" if _match_seed < 0 else str(_match_seed),
		str(seats_val),
	]
	_rebuild_roster()


func _rebuild_roster() -> void:
	for child in _roster_list.get_children():
		_roster_list.remove_child(child)
		child.free()
	_seat_badges.clear()

	var seat_total: int = int(_table_config.seat_count) if _table_config != null else int(GAME_CATALOG.default_player_count(_game_id))
	if _table_config != null and "seats" in _table_config and (_table_config.seats as Array).size() > seat_total:
		seat_total = (_table_config.seats as Array).size()
	var badge_flow := HFlowContainer.new()
	badge_flow.name = "SeatBadgeFlow"
	badge_flow.add_theme_constant_override("h_separation", 10)
	badge_flow.add_theme_constant_override("v_separation", 8)
	_roster_list.add_child(badge_flow)
	for s_idx in range(maxi(0, seat_total)):
		var badge := SEAT_BADGE_SCENE.instantiate() as Control
		if badge != null:
			badge_flow.add_child(badge)
			if badge.has_method("configure_seat"):
				badge.call("configure_seat", s_idx, "You" if s_idx == 0 else ("Seat %d" % (s_idx + 1)), s_idx == 0)
			if badge.has_method("set_turn_active"):
				badge.call("set_turn_active", s_idx == 0)
			_seat_badges.append(badge)

	var members: Array = (_lobby_model.get("members", []) as Array).duplicate(true)
	members.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("attrs", {}).get("seat", 999)) < int(b.get("attrs", {}).get("seat", 999))
	)

	if members.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Waiting for roster data from the lobby."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_color_override("font_color", MENU_STYLE.color(&"body_text"))
		_roster_list.add_child(empty_label)
		return

	for member in members:
		var row := Label.new()
		var attrs: Dictionary = member.get("attrs", {})
		var seat_index: int = int(attrs.get("seat", _seat_by_puid.get(String(member.get("puid", "")), 0)))
		var display_name: String = String(attrs.get("display_name", member.get("puid", "Player")))
		var local_suffix: String = "  |  You" if String(member.get("puid", "")) == _local_puid else ""
		var host_suffix: String = "  |  Host" if String(member.get("puid", "")) == String(_lobby_model.get("owner_puid", "")) else ""
		var ready_suffix: String = "  |  Ready" if bool(attrs.get("ready", false)) else "  |  Waiting"
		row.text = "Seat %d  |  %s%s%s%s" % [seat_index + 1, display_name, local_suffix, host_suffix, ready_suffix]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_font_size_override("font_size", 17)
		row.add_theme_color_override("font_color", MENU_STYLE.color(&"body_text"))
		_roster_list.add_child(row)
		if seat_index >= 0 and seat_index < _seat_badges.size():
			var b: Control = _seat_badges[seat_index]
			if b != null and b.has_method("configure_seat"):
				b.call("configure_seat", seat_index, display_name, String(member.get("puid", "")) == _local_puid)

	_update_gameplay_controls()


var _gameplay_bar: HBoxContainer = null
var _gameplay_action_btn: Button = null
var _gameplay_status_lbl: Label = null
var _simulated_turn_seat: int = 0
var _simulated_scores: Array[int] = []


func _update_gameplay_controls() -> void:
	if _gameplay_bar == null:
		_gameplay_bar = HBoxContainer.new()
		_gameplay_bar.name = "GameplayBar"
		_gameplay_bar.add_theme_constant_override("separation", 14)

		_gameplay_action_btn = Button.new()
		_gameplay_action_btn.name = "PlayActionBtn"
		_gameplay_action_btn.custom_minimum_size = Vector2(180, 42)
		_gameplay_action_btn.pressed.connect(_on_gameplay_action_pressed)
		_gameplay_bar.add_child(_gameplay_action_btn)

		_gameplay_status_lbl = Label.new()
		_gameplay_status_lbl.name = "GameplayStatus"
		_gameplay_status_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_gameplay_status_lbl.add_theme_font_size_override("font_size", 16)
		_gameplay_status_lbl.add_theme_color_override("font_color", MENU_STYLE.color(&"body_text"))
		_gameplay_bar.add_child(_gameplay_status_lbl)

		var vbox = get_node_or_null("Margin/RootCard/CardMargin/VBox")
		if vbox != null:
			var footer = vbox.get_node_or_null("Footer")
			if footer != null:
				vbox.add_child(_gameplay_bar)
				vbox.move_child(_gameplay_bar, footer.get_index())
			else:
				vbox.add_child(_gameplay_bar)

	var seat_count: int = _seat_badges.size()
	if _simulated_scores.size() != seat_count:
		_simulated_scores.clear()
		for _i in range(seat_count):
			_simulated_scores.append(0)

	match _game_id:
		GAME_CATALOG.GAME_BACKGAMMON:
			_gameplay_action_btn.text = "Roll Dice (Tavla)"
			_gameplay_status_lbl.text = "Seat %d's turn to roll." % (_simulated_turn_seat + 1)
		GAME_CATALOG.GAME_BLACKJACK:
			_gameplay_action_btn.text = "Deal Hand"
			_gameplay_status_lbl.text = "Dealer waiting for Seat %d." % (_simulated_turn_seat + 1)
		GAME_CATALOG.GAME_POKER:
			_gameplay_action_btn.text = "Deal Street"
			_gameplay_status_lbl.text = "Seat %d holds the action." % (_simulated_turn_seat + 1)
		GAME_CATALOG.GAME_CHESS:
			_gameplay_action_btn.text = "Play Move"
			_gameplay_status_lbl.text = "Turn: %s" % ("White (Seat 1)" if _simulated_turn_seat == 0 else "Black (Seat 2)")
		_:
			_gameplay_action_btn.text = "Next Turn"
			_gameplay_status_lbl.text = "Active Seat: %d" % (_simulated_turn_seat + 1)


func simulate_game_action() -> Dictionary:
	var total_seats: int = maxi(1, _seat_badges.size())
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var result := {}
	match _game_id:
		GAME_CATALOG.GAME_BACKGAMMON:
			var d1: int = rng.randi_range(1, 6)
			var d2: int = rng.randi_range(1, 6)
			result = {"action": "roll_dice", "dice": [d1, d2], "points": d1 + d2}
			if _gameplay_status_lbl != null:
				_gameplay_status_lbl.text = "Seat %d rolled [%d, %d]!" % [_simulated_turn_seat + 1, d1, d2]
		GAME_CATALOG.GAME_BLACKJACK:
			var card_val: int = rng.randi_range(2, 11)
			result = {"action": "deal_card", "card": card_val, "points": card_val}
			if _gameplay_status_lbl != null:
				_gameplay_status_lbl.text = "Seat %d dealt card value %d!" % [_simulated_turn_seat + 1, card_val]
		_:
			var pts: int = rng.randi_range(5, 25)
			result = {"action": "step_turn", "points": pts}
			if _gameplay_status_lbl != null:
				_gameplay_status_lbl.text = "Seat %d took action (+%d pts)!" % [_simulated_turn_seat + 1, pts]

	if _simulated_turn_seat < _simulated_scores.size():
		_simulated_scores[_simulated_turn_seat] += int(result.get("points", 10))
		if _simulated_turn_seat < _seat_badges.size():
			var b = _seat_badges[_simulated_turn_seat]
			if b != null and b.has_method("set_score"):
				b.call("set_score", _simulated_scores[_simulated_turn_seat])

	# Advance turn to next seat
	_simulated_turn_seat = (_simulated_turn_seat + 1) % total_seats
	for i in range(_seat_badges.size()):
		var badge = _seat_badges[i]
		if badge != null and badge.has_method("set_turn_active"):
			badge.call("set_turn_active", i == _simulated_turn_seat)

	return result


func get_active_seat_index() -> int:
	return _simulated_turn_seat


func _on_gameplay_action_pressed() -> void:
	simulate_game_action()


func _apply_theme_overrides() -> void:
	_eyebrow.add_theme_font_size_override("font_size", 18)
	_eyebrow.add_theme_color_override("font_color", MENU_STYLE.color(&"subtitle_text"))
	_title.add_theme_font_size_override("font_size", 46)
	_title.add_theme_color_override("font_color", MENU_STYLE.color(&"title_text"))
	_subtitle.add_theme_font_size_override("font_size", 24)
	_subtitle.add_theme_color_override("font_color", MENU_STYLE.color(&"subtitle_text"))
	_summary.add_theme_font_size_override("font_size", 18)
	_summary.add_theme_color_override("font_color", MENU_STYLE.color(&"body_text"))
	_roster_header.add_theme_font_size_override("font_size", 22)
	_roster_header.add_theme_color_override("font_color", MENU_STYLE.color(&"title_text"))
	_match_meta.add_theme_font_size_override("font_size", 16)
	_match_meta.add_theme_color_override("font_color", MENU_STYLE.color(&"muted_text"))


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/Main.tscn")
